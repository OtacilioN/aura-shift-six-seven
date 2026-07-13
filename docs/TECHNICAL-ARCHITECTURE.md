# Aura Shift: Six Seven — Arquitetura Técnica Planejada

> Status: tecnologia e limites de alto nível aprovados; nenhum código ou estrutura de pastas foi definido.

## Objetivo

Usar uma única base capaz de entregar rapidamente o jogo no Android, preservar futura publicação no iOS e combinar uma cena 2D responsiva com interfaces, localização e integrações típicas de aplicativo.

## Stack

- **Linguagem:** Dart.
- **Aplicativo e interface:** Flutter.
- **Cena jogável 2D:** Flame.
- **Áudio candidato:** `flame_audio`.
- **Anúncios:** Google Mobile Ads para Flutter.
- **Telemetria opcional:** Firebase Analytics para Flutter, com coleta desativada até Consentimento de Analytics, retenção detalhada de dois meses e nenhuma exportação externa.
- **Diagnóstico autorizado:** Firebase Crashlytics para Flutter, com transmissão automática desativada e envio por ocorrência.
- **Comparação externa de falhas:** Crash Insights desativado no lançamento.
- **Rive:** excluído do MVP Android v1.0.

## Limite entre Flutter e Flame

### Flutter possui

- navegação inferior;
- Loja e Árvore de Aura;
- Coleção e personalização;
- Ajustes e acessibilidade;
- localização, RTL e escala textual;
- diálogos, painéis e tutorial textual;
- anúncios recompensados e consentimento;
- Consentimento de Analytics e ativação ou desativação da coleta;
- detecção local, apresentação, envio autorizado ou exclusão de Relatórios de Diagnóstico;
- tratamento `TEEN` e isolamento da Play Age Signals;
- salvamento, exportação e importação;
- política de privacidade, créditos e licenças.

### Flame possui

- Área de Aura;
- Mascote e mãos em camadas;
- entrada de contato único e limite de eventos em janela móvel;
- animações Six e Seven;
- partículas, rastros e fundos;
- Transformações de Aura;
- celebrações de Marcos 67;
- intensidade visual vinculada à cadência;
- elementos de áudio diretamente associados à cena.

O estado econômico e as regras do jogo não devem depender da renderização. Flutter e Flame observam o mesmo estado canônico, sem duplicar saldos, temporizadores ou decisões de compra.

## Mascote

O baseline usa um pseudo-rig procedural em Canvas dentro de `AuraScene`: corpo, mãos e rosto são desenhados por código; Aparências de Item, Aura e efeitos permanecem camadas independentes. O movimento Six-Seven inicial não requer sprites de personagem nem animação esquelética externa.

Pivôs, ordem de camadas, envelopes dos slots, dimensões, formatos, atlases e variantes reduzidas das skins seguem o contrato `asset-manifest-v1` de `ASSET-MANIFEST.md`. A cena escala o palco lógico uniformemente e usa esses metadados para sobrepor as skins; a geometria do personagem procedural permanece em `aura_scene.dart`.

Rive não será avaliado nem integrado durante o MVP. O pseudo-rig Canvas precisa cumprir o escopo usando Flame; qualquer reconsideração pertence a uma atualização futura e exige nova decisão documentada.

## Áudio

O runtime usa `flame_audio`, com efeitos de ciclo pré-carregados e sete mixes
completos sem markers de loop. Na abertura, uma shuffle bag sorteia a sequência
da sessão e sua primeira faixa. Uma voz musical permanece em loop enquanto o
jogador continua no mesmo menu; duas coexistem somente no crossfade equal-power
de `1 s` disparado por uma troca entre Jogar, Loja, Coleção e Ajustes. Posição e
conclusão do player não avançam a sequência, e as sete faixas são consumidas
antes de novo embaralhamento sem repetição imediata.

O pacote de integração segue `audio-manifest-v2`: fontes musicais preservadas em
WAV `44,1 kHz/24-bit`, masters em WAV `48 kHz/24-bit`, música runtime em Ogg e
35 SFX curtos em WAV. Somente IDs com fonte, master, hashes, proveniência e
decisão humana entram no build. Termos comerciais, similaridade/fadiga e
playback Android continuam gates de publicação explícitos.

## Android

O baseline planejado é:

- Android App Bundle;
- API 36;
- compatibilidade com páginas de memória de 16 KB;
- validação de toda biblioteca nativa trazida por plugins;
- comportamento adaptável em telas grandes, apesar da composição principal em retrato;
- testes em aparelho físico modesto e em perfil de desempenho.

## iOS futuro

A mesma base deve preservar domínio, interface, cena, localização e assets. A etapa iOS ainda exigirá trabalho específico para assinatura, privacidade, anúncios, consentimento, haptics, compartilhamento de arquivos, safe areas e QA em hardware Apple.

## Domínio econômico determinístico

O domínio econômico segue o contrato documental `arith-v1` de `ECONOMIC-ARITHMETIC.md`. Estado canônico, custos, produção, Ascensão e restos usam inteiros de precisão arbitrária; nenhum resultado depende de ponto flutuante, frame rate ou texto localizado.

O relógio de jogo fornece milissegundos monotônicos enquanto o app está aberto. Ciclo de vida, anúncios, armazenamento e relógio de parede entram por adaptadores. Antes de qualquer mutação econômica, o domínio integra o intervalo pendente com o estado anterior, executa o comando e produz uma transação persistível. Caches de Potência e Produção Passiva nunca substituem níveis e parâmetros como fonte de verdade.

## Apresentação numérica compartilhada

Uma única camada pura de apresentação implementa `number-format-v1` para todas as superfícies Flutter e Flame. Ela recebe inteiros ou racionais canônicos, locale e contexto de unidade, e devolve representação visual, detalhe completo, cópia ASCII e semântica assistiva coerentes. Essa camada não decide compras, elegibilidade, desbloqueios ou produção; o domínio econômico nunca recebe de volta texto formatado como entrada.

## Prova técnica futura

Antes da produção extensa de conteúdo, o milestone de fatia vertical deverá validar:

1. Mascote em camadas e movimento Six-Seven;
2. um contato físico por vez e até oito toques por janela móvel de um segundo;
3. partículas e redução de movimento;
4. árabe RTL e escala textual;
5. áudio base, groove e hype;
6. anúncio recompensado de teste com cancelamento e retorno;
7. save local e Backup Manual;
8. AAB API 36 com páginas de 16 KB;
9. retomada após segundo plano;
10. ausência de analytics antes do opt-in e depois do opt-out;
11. armazenamento local, autorização única, envio e exclusão de relatório de falha;
12. ausência de envio automático do Crashlytics em instalação limpa e após nova falha;
13. Crash Insights desativado no console sem impedir relatórios próprios autorizados;
14. retenção GA4 de dois meses, sem renovação por atividade e sem BigQuery;
15. desempenho em aparelho Android modesto.

Para isolar causas de falha, o milestone é executado em duas fatias coordenadas sob um único gate: primeiro a fatia de gameplay valida interação, domínio, save, apresentação, áudio, RTL, acessibilidade e desempenho; depois a fatia de plataforma valida anúncios, backup, Analytics, diagnóstico, configurações de console e empacotamento. Nenhuma delas autoriza produção integral isoladamente.

Essa prova pertence à fase de implementação, não à sessão atual de documentação.

## Licenças e dependências

Toda dependência deve ter:

- versão fixada;
- licença compatível registrada;
- origem oficial ou reputação avaliada;
- justificativa de uso;
- verificação de manutenção;
- teste Android e, quando aplicável, iOS;
- auditoria de bibliotecas nativas no pacote final.

## Referências atuais

- [Flutter — plataformas suportadas](https://docs.flutter.dev/reference/supported-platforms)
- [Flame — documentação](https://docs.flame-engine.org/latest/)
- [Google Mobile Ads — rewarded para Flutter](https://developers.google.com/admob/flutter/rewarded)
- [Firebase Analytics — início no Flutter](https://firebase.google.com/docs/analytics/flutter/get-started)
- [Firebase Analytics — controle de coleta](https://firebase.google.com/docs/analytics/android/configure-data-collection)
- [Firebase Crashlytics — relatórios para Flutter](https://firebase.google.com/docs/crashlytics/flutter/customize-crash-reports)
- [Android — páginas de memória de 16 KB](https://developer.android.com/guide/practices/page-sizes)
- [Android — configuração da API 36](https://developer.android.com/about/versions/16/setup-sdk)

Essas referências devem ser verificadas novamente antes da implementação e publicação.
