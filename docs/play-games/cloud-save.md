# Salvamento em nuvem com Google Play Games

## Estado da entrega

O aplicativo contém a arquitetura e o bridge Android para Google Play Games
Services Saved Games (Snapshots API), mas a funcionalidade **não deve ser
considerada ativa em produção** até que Saved Games seja habilitado e publicado
manualmente no projeto do Play Games Services no Play Console. Até essa
configuração propagar, o jogo continua usando o save local e apresenta a
sincronização como indisponível ou pendente, sem bloquear a partida.

O sistema usa Google Play Games Services v2 e não usa `GoogleApiClient`.
`play-services-games-v2` permanece fixado em `21.0.0`; não há dependência com
versão dinâmica.

## Arquitetura

O estado em memória e o save local continuam sendo a fonte imediata durante a
sessão. A nuvem é uma réplica reconciliada e agrupada:

```text
GameController
  └─ estado econômico em memória
      └─ LocalGameSaveRepository
          ├─ save local atual
          ├─ último envelope local válido
          ├─ instalação, proprietário e migração
          └─ dirty flag / última sincronização
              └─ CloudSaveCoordinator
                  ├─ autenticação Play Games v2
                  ├─ GameSaveCodec + migrações
                  ├─ CloudConflictResolver
                  └─ CloudGameSaveRepository
                      └─ MethodChannel
                          └─ SnapshotsClient (Kotlin)
```

Responsabilidades:

- `GameController`: aplica ações, persiste imediatamente, congela o snapshot de
  produção offline e substitui o estado autoritativo já validado. Não chama a
  API Google.
- `LocalGameSaveRepository`: encapsula o envelope local, fila de escrita,
  última versão válida, installation ID, Player ID proprietário, dirty flag e
  marcador de migração.
- `GameSaveCodec`: normaliza o estado, produz JSON canônico, calcula/verifica
  SHA-256, valida invariantes e recusa payload acima de 3 MB.
- `GameSaveMigrationService`: converte de forma idempotente o `save-v1` e os
  balances anteriores para o schema atual.
- `CloudConflictResolver`: escolhe somente saves completos; nunca soma recursos
  nem faz merge campo a campo.
- `CloudSaveCoordinator`: serializa operações, autentica, abre o snapshot,
  reconcilia local/remoto, agenda uploads e publica estados observáveis para a
  interface.
- `CloudGameSaveRepository`: abstração mockável. No Android, usa o bridge nativo
  para `open`, `commitAndClose` e `resolveConflict`.

## Slot canônico

Existe exatamente um slot:

```text
aura_shift_primary
```

O nome é constante tanto no Dart quanto no Kotlin. Não há seletor nativo, lista
de slots, criação de saves adicionais ou exclusão individual exposta ao
jogador. A descrição enviada ao snapshot é derivada apenas para exibição, no
formato aproximado `Nível de Aura N • X aura/s`; ela nunca reconstrói o
progresso.

## Envelope e conteúdo

O schema atual é `1`:

```json
{
  "schemaVersion": 1,
  "saveId": "save-...",
  "revision": 4,
  "installationId": "install-...",
  "parentPayloadHash": "...",
  "payloadHash": "...",
  "savedAtUtc": "2026-07-27T12:00:00.000Z",
  "lastActiveAtUtc": "2026-07-27T11:59:55.000Z",
  "totalPlayTimeMillis": 123456,
  "gameState": {}
}
```

`gameState` contém os dados necessários para reconstruir a jornada:

- Aura disponível, total, da jornada, resto exato, multiplicador e Aura de
  Ascensão, serializados como texto decimal;
- ciclos, Ascensões, maior Aura por movimento e tempo total;
- níveis de Técnicas/Itens, Aparências possuídas e equipadas, Transformações,
  Conquistas e Selos 67;
- fase econômica, progressão do tutorial e gates permanentes de monetização;
- cooldown e sequência persistente de rewarded upgrade;
- `offlineAt` + `offlineRate` congelada ou a Recompensa de Retorno pendente.

Produção ativa/passiva e preços são derivados das regras e dos níveis, portanto
não são duplicados como fonte autoritativa.

Ficam fora do payload: consentimento de Analytics, preferências de lembrete,
store review, autorização/tokens Google, nome/e-mail, logs, filas de placar,
cotação de anúncio em andamento, estado temporário de UI e o timestamp
monotônico `sixStartedAt`. Idioma e acessibilidade acompanham o progresso; os
consentimentos vinculados ao aparelho não acompanham.

Mapas têm chaves ordenadas e coleções persistentes são deduplicadas e ordenadas
antes do hash. O codec valida IDs conhecidos, inteiros não negativos, relações
`available <= journey <= total`, resto menor que 10.000.000, estados de retorno
e versões aceitas.

## Migração de jogadores existentes

O save legado continua sendo lido da chave `save-v1`. No primeiro uso:

1. as migrações econômicas e de coleção já existentes são aplicadas;
2. o estado é normalizado para o schema cloud atual;
3. cria-se um `saveId`, installation ID e revisão local;
4. o envelope é persistido localmente como pendente;
5. a migração só é marcada em `cloudSaveMigrationVersion` depois de um commit
   remoto confirmado.

O processo é idempotente. Interromper antes do commit deixa o envelope pendente
e provoca nova tentativa, sem apagar ou duplicar a jornada.

Cenários:

- local existente e remoto ausente: o local é enviado;
- local sem progresso significativo e remoto existente: o remoto é restaurado;
- ambos existentes: hashes, ancestralidade e dominância são avaliados;
- save local antigo: migra localmente e entra no mesmo fluxo;
- envelope local corrompido: tenta-se a última versão local válida antes de
  desistir.

## Startup e ganho offline

A ordem é deliberada para impedir crédito duplicado:

1. carregar e migrar o save local com o ganho offline adiado;
2. inicializar silenciosamente Play Games;
3. abrir `aura_shift_primary` com timeout de 5 segundos;
4. escolher ou solicitar escolha do estado autoritativo;
5. aplicar e persistir esse estado localmente;
6. somente então executar `completeDeferredStartup()` e materializar o
   intervalo offline;
7. marcar o estado resultante como alterado e agendar upload.

Timeout, falta de rede, usuário não autenticado ou recurso ainda não configurado
não bloqueiam indefinidamente a abertura. O jogo conclui a inicialização com o
save local e tenta novamente depois.

Ao pausar, o controller primeiro integra o último intervalo foreground, acumula
o tempo jogado, grava `offlineAt` e a taxa exata congelada e aguarda o flush
local antes da tentativa cloud. Ao retomar, a reconciliação cloud ocorre antes
de `resume()`. A recompensa offline continua limitada a quatro horas e uma
recompensa já pendente não é recriada.

## Agendamento e concorrência

- alterações locais apenas marcam o estado dirty;
- atividade contínua gera, no máximo, uma tentativa a cada 45 segundos;
- inicialização, autenticação, retomada, pausa, restauração, resolução de
  conflito e ações prioritárias solicitam sincronização imediata;
- o botão **Sincronizar agora** chama o mesmo coordinator;
- existe apenas uma sincronização em andamento;
- mudança ocorrida durante uma operação seta `resyncRequested` e agenda uma
  rodada posterior;
- não há chamada cloud por frame, integração passiva, movimento ou gravação de
  `SharedPreferences`.

Falhas mantêm o save local e a dirty flag. Retomar conexão ou usar
**Sincronizar agora** repete a operação.

## Perfil Gamer e troca de conta

O proprietário local é identificado pelo Player ID fornecido pelo Play Games,
nunca pelo nome Gamer. O Player ID não é incluído dentro do payload econômico.

No primeiro vínculo, o save local sem proprietário é associado ao perfil após a
reconciliação. Quando o Player ID muda:

- um remoto existente da nova conta é carregado, sem enviar o progresso da
  conta anterior;
- se a nova conta não possui remoto e o aparelho tem progresso significativo,
  a associação fica pendente de decisão explícita;
- o remoto anterior não é apagado;
- nomes Gamer são usados apenas como texto da interface.

## Resolução de conflitos

Cada candidato é desserializado, migrado, validado e conferido pelo hash. Se
somente um for válido, ele vence. Se nenhum for válido, o handle nativo é
abandonado, o save local é preservado e um erro recuperável é exibido.

Ordem automática:

1. hashes iguais: equivalentes;
2. `parentPayloadHash` aponta para o outro e a revisão é maior: descendente;
3. dominância em todas as métricas monotônicas, com pelo menos uma
   estritamente maior: estado dominante;
4. caso contrário: conflito ambíguo.

As métricas monotônicas são Ascensões, Aura Total vitalícia, nível de Aura,
ciclos, itens permanentemente desbloqueados e tempo total jogado. Aura
disponível, níveis atuais e Aura da jornada não são usados isoladamente porque
podem cair após compras ou Ascensão.

O conflito ambíguo mostra dois resumos completos: origem, data, nível, Aura
Total, produção/s, Ascensões, itens, tempo jogado e, quando disponível,
dispositivo. A opção mais recente pode aparecer como recomendada, mas nenhuma é
aplicada sem escolha. **Decidir depois** preserva ambos e não permite upload até
a resolução. O candidato escolhido inteiro recebe nova revisão e é enviado por
`resolveConflict`; nunca se usa:

```text
aura = auraLocal + auraRemota
maior valor de cada campo
```

## Estados da interface

A área de sincronização em Ajustes deve representar:

- **sincronizando**: operação em andamento, ações duplicadas desabilitadas;
- **sincronizado**: última confirmação e perfil Gamer;
- **alterações pendentes**: save local seguro aguardando upload;
- **offline**: progresso local seguro e retry futuro;
- **não autenticado**: instrução para conectar ao Play Games;
- **indisponível/não configurado**: recurso ainda não habilitado ou plataforma
  sem suporte;
- **falha recuperável**: botão de tentar novamente;
- **schema/tamanho inválido**: erro não destrutivo, sem sobrescrever remoto;
- **conflito pendente/troca de perfil**: comparação e decisão explícita.

O estado cloud nunca substitui o feedback de que o save local continua seguro.
Datas são exibidas no locale atual, mas permanecem UTC no envelope. Botões e
opções de conflito precisam de semântica TalkBack com origem, estado e ação.

## Segurança e limites

- O limite validado antes de qualquer chamada nativa é 3 MB e também é
  consultado no `SnapshotsClient`.
- SHA-256 detecta corrupção acidental e garante comparação determinística; não
  é proteção contra adulteração, pois o cliente não contém segredo capaz de
  autenticar o payload.
- Conteúdo completo do save não deve aparecer em logs, Analytics ou
  Crashlytics.
- Saved Games não é autoridade competitiva. Placares e outras superfícies
  competitivas mantêm seus próprios controles.
- Operação offline, timeout e falha Google nunca apagam o último estado válido.
- Relógio de parede ainda é uma limitação do ganho offline; o teto de quatro
  horas contém o impacto, mas não prova honestidade do relógio.

## Dependências

O bridge nativo foi escolhido em vez do pacote `games_services` porque a
resolução precisa acessar as duas versões de um conflito e o token nativo.

Com a remoção da exportação/importação por arquivo, deixam de ser dependências
diretas:

- `file_selector`;
- `share_plus`;
- `path_provider`, desde que nenhum outro fluxo passe a utilizá-lo.

`crypto` permanece para SHA-256. No Android, a integração reutiliza
`com.google.android.gms:play-services-games-v2:21.0.0`.

## Configuração manual pendente no Play Console

Este passo ainda precisa ser executado e verificado no console; a presença do
código não o conclui:

1. abrir o aplicativo correto no Google Play Console;
2. entrar em **Serviços do Google Play Games → Configuração e gerenciamento**;
3. editar as propriedades/configuração do projeto Play Games Services;
4. habilitar **Saved Games / Jogos salvos**;
5. salvar e publicar a configuração do Play Games Services;
6. confirmar que a credencial Android publicada corresponde ao package
   `com.otaciliomaia.aurashiftsixseven` e ao SHA-1 do Play App Signing;
7. aguardar a propagação;
8. publicar um novo AAB contendo esta implementação em faixa interna ou
   fechada;
9. instalar pela Play Store com uma conta incluída e aderida à faixa.

Não marcar esta integração como ativa antes de abrir, gravar e restaurar
`aura_shift_primary` em uma instalação real da faixa.

## Matriz de validação real

### Um dispositivo

1. instalar da Play Store e autenticar;
2. avançar, pausar, esperar a confirmação de sincronização;
3. fechar e reabrir;
4. verificar um único ganho offline e os mesmos totais/itens;
5. jogar sem rede, fechar/reabrir e confirmar save local;
6. recuperar a rede, usar **Sincronizar agora** e confirmar o upload pendente.

### Reinstalação

1. sincronizar e registrar um resumo exato do progresso;
2. desinstalar e reinstalar pela mesma faixa;
3. autenticar no mesmo perfil Gamer;
4. confirmar restauração antes do cálculo offline;
5. verificar Aura, níveis, coleções, Ascensões, conquistas e ausência de crédito
   duplicado.

### Dois dispositivos

1. instalar pela faixa em A e B com o mesmo perfil;
2. avançar em A, sincronizar e restaurar em B;
3. avançar B offline e depois sincronizar;
4. retomar A, reconciliar e confirmar o estado completo de B;
5. repetir com troca de perfil e confirmar que o save anterior não é enviado à
   nova conta.

### Conflito

1. sincronizar uma base comum em A e B;
2. colocar ambos offline e criar progressos divergentes;
3. sincronizar A e depois B;
4. confirmar que um descendente/dominante é escolhido automaticamente apenas
   quando as regras permitem;
5. produzir um caso ambíguo e conferir os dois resumos;
6. escolher cada candidato em execuções separadas;
7. verificar nova revisão, resolução nativa, ausência de soma campo a campo e
   restauração idêntica em terceiro dispositivo.

### Corrupção e indisponibilidade

1. testar hash inválido, schema futuro, payload truncado e acima de 3 MB;
2. simular timeout, ausência de rede e perda de autenticação;
3. confirmar que o último save local válido permanece jogável;
4. confirmar que nenhum payload completo é registrado;
5. repetir pausa/resume durante upload e validar ausência de operações
   paralelas ou loops.
