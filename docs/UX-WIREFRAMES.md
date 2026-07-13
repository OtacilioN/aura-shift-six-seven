# Aura Shift: Six Seven — Arquitetura de UX e Wireframes

> Status: `ux-flow-v1` aprovado para planejamento e reconciliado com marca, catálogo e copy-fonte congelados; implementação e QA de tela permanecem no desenvolvimento.

## Escopo e convenções

Este documento fecha a arquitetura das quatro áreas do MVP, os wireframes textuais em retrato e os estados transitórios que atravessam essas áreas. Ele não cria uma quinta área, uma conta, nuvem, slots de save ou funcionalidades fora do escopo.

Nos wireframes:

- `[ação]` representa controle acionável;
- `(estado)` representa informação não acionável;
- `…` representa conteúdo rolável;
- `↑ folha` representa uma folha modal que nasce da borda inferior;
- códigos como `A-01` em diagramas são anotações técnicas de rastreabilidade; a UI renderiza sempre o nome localizado de `CONTENT-CATALOG.md`, nunca o ID;
- ações primárias recorrentes ficam na metade inferior e ao alcance do polegar;
- ações destrutivas ou irreversíveis nunca dependem somente de posição, cor ou gesto.

Referências normativas: `UX-DESIGN.md`, `ONBOARDING.md`, `ACCESSIBILITY.md`, `UI-DESIGN-SYSTEM.md`, `NUMBER-FORMATTING.md`, `SAVE-DATA-DESIGN.md`, `MONETIZATION-DESIGN.md` e `AURA-TREE-DESIGN.md`.

## Mapa das quatro áreas

```text
Aplicativo
├── Jogar
│   ├── indicadores: Aura Disponível, Potência de Ciclo, Produção Passiva
│   ├── [Detalhes de Aura] — folha, não área
│   ├── Mascote + Área de Aura
│   ├── progresso do próximo Patamar
│   └── [Ascensão] — folha quando descoberta
├── Loja
│   └── Árvore de Aura única
│       ├── Técnicas Six-Seven no tronco central por Patamar
│       ├── Poise, Motion e Signal como os três Ramos de Aura
│       ├── Convergências em camada compartilhada
│       ├── detalhe de Técnica ou Item
│       ├── requisitos reais de Patamar e predecessor
│       ├── compra ×1 / ×10 / MÁX
│       └── Complemento de Aura elegível em ×1
├── Coleção
│   ├── personalização do Mascote
│   ├── Aparências e variações
│   ├── Transformações de Aura
│   ├── Conquistas: 6 visíveis + 7 secretas
│   └── Selos 67
└── Ajustes
    ├── idioma
    ├── música / efeitos / vibração
    ├── acessibilidade
    ├── Backup Manual: exportar / importar
    ├── privacidade e consentimentos
    ├── política de privacidade
    ├── rever tutorial
    └── créditos e licenças
```

Folhas de retorno offline, consentimento, diagnóstico, anúncio, confirmação, erro e celebração pertencem ao contexto que as abriu. Fechá-las devolve foco ao controle de origem ou ao próximo estado persistente válido.

## Modelo de navegação e uma mão

- A barra inferior é persistente nas quatro raízes e mede no mínimo `64dp` mais a safe area. Cada destino possui ícone, rótulo e alvo mínimo `48×48dp`.
- A Área de Aura começa abaixo dos indicadores e se estende até a zona de proteção acima da barra. O Mascote não é um alvo obrigatório.
- Em telas de conteúdo, ações primárias usam barra inferior fixa acima da navegação ou folha inferior. O conteúdo pode rolar atrás dela, com padding que impede ocultação.
- Voltar do sistema fecha, nesta ordem: diálogo, folha, detalhe de nó, subtela da área e aplicativo. Nunca descarta uma escolha irreversível já confirmada.
- Trocar de área preserva rolagem, filtro, nó selecionado e Fase Six/Seven. Reabrir o app restaura a raiz ou o fluxo persistente prioritário, não uma tela intermediária inválida.
- O layout de referência é `360×800dp`. Deve permanecer operável a partir de `320×568dp`, com safe areas, teclado e escala textual de `200%`.
- Em RTL, ordem espacial, setas, listas e navegação são espelhadas; tokens econômicos continuam isolados como LTR. A ordem lógica de leitura acompanha a composição espelhada.

## Wireframe — Jogar

```text
┌──────────────────────────────┐
│ Aura Disponível      [ⓘ]     │
│ (1,23M)                      │
│ +6,7K/ciclo   +3,35K/s       │
│ próximo Patamar   67%        │
│ ━━━━━━━━━━━━━░░░░░░░         │
├──────────────────────────────┤
│                              │
│          MASCOTE             │
│                              │
│      ÁREA DE AURA AMPLA      │
│  toque em qualquer ponto     │
│                              │
│    (Six pronto / Seven)      │
│                              │
│ [Ascensão disponível]        │
├──────────────────────────────┤
│ Jogar  Loja  Coleção Ajustes │
└──────────────────────────────┘
```

Regras:

- `[ⓘ]` abre Detalhes de Aura com Aura Disponível, Aura Total, Aura da Jornada, Potência de Ciclo e Produção Passiva; cada valor oferece representação completa e cópia canônica.
- A faixa de Ascensão só aparece depois de descoberta. Antes da Aura da Jornada mínima, informa a falta exata e abre a prévia desabilitada.
- Coach marks e banners de estado nunca cobrem toda a Área de Aura. Um toque em controles não avança o Ciclo.
- Com TalkBack, a Área de Aura é um único controle com rótulo, fase vigente e ação. Um duplo toque avança exatamente uma fase; o anúncio de Aura ocorre somente na Fase Seven.

### Folha — Detalhes de Aura

```text
┌──────── Detalhes de Aura ────┐
│ Aura Disponível              │
│ 1.234.567                    │
│ [Copiar valor]               │
│ Aura Total …                 │
│ Aura da Jornada …            │
│ Potência de Ciclo …          │
│ Produção Passiva …           │
│ (contagem de dígitos, se útil)│
│                    [Fechar]  │
└──────────────────────────────┘
```

Inteiros arbitrariamente longos usam segmentos quebráveis ou virtualizados; não forçam rolagem horizontal da tela inteira.

## Wireframe — Loja

```text
┌────────────── Loja ──────────┐
│ Árvore de Aura               │
├──────────────────────────────┤
│ ───── Patamar inicial ────── │
│       [Switch Stance]       │
│ A-01      B-01       C-01   │
│ ─────────── 1K ──────────── │
│          CONV-01            │
│         [TECH-02]           │
│ A-02      B-02       C-02   │
│ …                            │
├──────────────────────────────┤
│ Jogar  Loja  Coleção Ajustes │
└──────────────────────────────┘
```

- Selecionar qualquer nó abre sua folha de detalhe. As ações `×1`, `×10` e `MÁX` ficam nessa folha e repetem quantidade e custo para evitar compra ambígua.
- `×10` fica indisponível se os dez níveis não puderem ser pagos. `MÁX` informa a quantidade calculada; se for zero, mostra a falta para `×1`.
- Ao atravessar Marcos de Nível, a compra conclui uma vez e abre uma celebração consolidada com nível final, efeito final e lista dos marcos atravessados.
- A Loja não oferece alternância `[Técnicas] [Árvore de Aura]`: Técnicas e Itens compartilham a mesma composição e o mesmo padrão de seleção, detalhe e compra.

### Composição da Árvore de Aura

```text
┌────────── Árvore de Aura ────┐
│ Patamar atual: 1M             │
│                               │
│ ───────── inicial ──────────  │
│          [TECH-01]            │
│ A-01       B-01        C-01   │
│ ─────────── 1K ─────────────  │
│          CONV-01              │
│          [TECH-02]            │
│ A-02       B-02        C-02   │
│ ─────────── 1M ─────────────  │
│          [TECH-03]            │
│ A-03       B-03        C-03   │
│                               │
├───────────────────────────────┤
│ Jogar  Loja  Coleção  Ajustes │
└───────────────────────────────┘
```

- A Árvore rola verticalmente dentro de uma viewport própria; a barra inferior e o título permanecem fixos. A rota visual não é a única forma de alcançar nós: a ordem semântica por Patamar e o “próximo bloqueio” oferecem rotas equivalentes. Técnicas aparecem nessa mesma rota linear, nunca em uma lista paralela.
- As Técnicas ocupam o tronco central na ordem visual `TECH-01` a `TECH-06`. Não há conectores entre elas: a sequência espacial comunica escalada de Patamares, não aquisição obrigatória.
- Faixas, halos ou fundos de Patamar associam visualmente a Técnica e os Itens de Aura liberados pelo mesmo limiar de Aura Total. Esses recursos não usam a linguagem gráfica reservada a um Pré-requisito. Transformações e Ascensão permanecem fora da superfície da Árvore.
- Ramos A/B/C usam forma, ícone e rótulo além de cor. Poise ocupa a trilha esquerda, Motion a central e Signal a direita no LTR; as Técnicas intercalam o eixo central em estágios próprios, sem se conectar a Motion. A simetria econômica é dita no primeiro contato com os Itens-raiz.
- Convergências ocupam uma camada compartilhada e têm contorno/ícone próprio; não aparecem como continuação obrigatória de um ramo.
- Cada nó de Técnica ou Item tem estados `oculto por progressão`, `visível bloqueado`, `comprável`, `adquirido`, `marco próximo`, `selecionado`. Conteúdo oculto nunca impede anunciar o próximo objetivo conhecido.

### Folha — Nó e bloqueios

```text
┌───────────── QA Goggles ──────┐
│ nível 0 · Produção Passiva    │
│ atual 0 → +67 Aura/s          │
│ Próximo Marco: nível 10       │
│                               │
│ Requisitos                    │
│ ✓ Patamar 1M                  │
│ ! Glow Receipt nível 18 de 25 │
│                               │
│ Faltam 7 níveis no predecessor│
│ [×1 indisponível]             │
│ [×10 indisponível] [MÁX ×0]   │
└───────────────────────────────┘
```

Convergências listam os três requisitos separadamente, nunca apenas uma porcentagem. Um nó com Patamar e predecessor pendentes mostra ambos. A ação desabilitada permanece descritível por tecnologia assistiva e aponta a correção disponível.

### Folha — Complemento de Aura

```text
┌──────── Complemento de Aura ──┐
│ Preço             1.999 Aura  │
│ Seu saldo         1.990 Aura  │
│ Falta                 9 Aura  │
│ Você gasta 1.990; o anúncio   │
│ cobre somente 9.               │
│ 2 de 3 complementos restantes │
│ [Agora não · action_not_now]   │
│ [Assistir · shop_ad_topup_watch]│
└───────────────────────────────┘
```

`action_not_now` fecha a oferta e mantém a compra pendente; não compra nem agenda anúncio. `shop_ad_topup_watch` inicia o anúncio e só conclui a compra após callback válido. O Complemento só aparece em `×1`, depois da habilitação e com todos os requisitos não econômicos atendidos.

## Wireframe — Coleção

```text
┌──────────── Coleção ──────────┐
│ [Aparências] [Transformações] │
│ [Conquistas] [Selos 67]       │
├───────────────────────────────┤
│       prévia do Mascote       │
│                               │
│ [visual 1] [ligado]           │
│ [visual 2] [ligado]           │
│                               │
│ Efeito: ativo / reiniciado    │
│ [Ativar/ocultar independente] │
├───────────────────────────────┤
│ Jogar  Loja  Coleção  Ajustes │
└───────────────────────────────┘
```

- Aparência preservada e Efeito de Item ativo são apresentados em linhas e ícones diferentes. Após Ascensão, uma aparência pode continuar `Em uso`, enquanto a linha nomeada “Efeito de Item” mostra `Bloqueado` até a readquisição; esses estados reutilizam `collection_equipped` e `collection_locked` sem sugerir perda da aparência.
- Conquistas secretas bloqueadas exibem placeholder sem revelar nome/condição. Selos 67 têm contagem e grade distintas.
- Ativar ou ocultar uma Aparência não desativa as demais e não abre confirmação porque não afeta economia; o resultado é reversível e recebe feedback imediato. A prévia suporta as 18 Aparências simultâneas e usa o mesmo relayout sem sobreposição da Área de Aura.

## Wireframe — Ajustes

```text
┌──────────── Ajustes ──────────┐
│ Idioma                [›]     │
│ Música             [slider]   │
│ Efeitos sonoros    [slider]   │
│ Vibração            [on/off]  │
│ Acessibilidade         [›]    │
│ Backup Manual          [›]    │
│ Privacidade            [›]    │
│ Rever tutorial         [›]    │
│ Créditos e licenças    [›]    │
├───────────────────────────────┤
│ Jogar  Loja  Coleção  Ajustes │
└───────────────────────────────┘
```

- Idioma mostra o nome nativo vigente e aplica a troca imediatamente.
- Acessibilidade reúne: Movimento (`Seguir sistema`, `Completo` ou `Reduzido`), Reduzir flashes e partículas, Aumentar contraste, dicas extras para leitor de tela e as substituições documentadas em `ACCESSIBILITY.md`.
- Privacidade separa Analytics, preferências publicitárias geridas pela CMP quando aplicável, política de privacidade e explicações de diagnóstico. Um consentimento não altera outro.

## Ordem de interrupções e retomada

Somente uma superfície modal recebe foco por vez. Na abertura ou retorno ao primeiro plano, a fila usa esta prioridade:

1. recuperação de gravação/transação interrompida e erro fatal de integridade;
2. Recompensa de Retorno persistente, aguardando escolha de resgate;
3. anúncio de Bônus de Retorno já escolhido e ainda pendente de conclusão;
4. oferta de Relatórios de Diagnóstico da execução anterior;
5. etapa ativa do Tutorial Contextual ou Consentimento de Analytics disparado por ele;
6. confirmação de Ascensão iniciada, somente se ainda for válida;
7. celebrações persistentes de Transformações, Conquistas e Marcos 67, na ordem do evento;
8. banners não bloqueantes e novidades da Loja.

Consentimentos ou erros abertos pausam apresentações; celebrações são enfileiradas e podem ser dispensadas sem apagar o registro. A Fase Six/Seven, rolagem e controle de origem permanecem preservados.

## Máquina de estados — Tutorial Contextual

| Estado | Entrada e ação | Cancelamento/falha | Fechar e reabrir |
| --- | --- | --- | --- |
| idioma inicial | locale detectado; seletor acessível | fallback `en-US`; troca pode ser desfeita | reaplica preferência salva |
| pedir dois toques | destaque não bloqueante sobre Área de Aura | dispensar remove o destaque, não desativa a interação | retoma a fase econômica real |
| primeira Aura | Fase Seven credita e exibe Aura | persistência falhou: não abre consentimento; recupera transação | nunca duplica o crédito |
| Analytics | folha de peso igual após a Aura | fechar = Agora não; coleta continua desligada | escolha salva no aparelho; convite não reaparece após decisão |
| primeira Técnica | Loja recebe destaque quando pagável | pode ignorar e continuar jogando | destaque contextual volta sem modal repetitivo |
| primeiro Item | três Itens-raiz equivalentes aparecem juntos | nenhum ramo é pré-selecionado ou comprado | seleção e compra persistidas normalmente |
| Produção Passiva | explicação após a compra real | dispensar conclui o tutorial do mesmo modo | tutorial permanece concluído |

Rever tutorial usa demonstrações textuais/visuais sobre o estado atual, sem repetir crédito, compra, consentimento ou habilitação de anúncio.

## Máquina de estados — Retorno offline

| Caso | Apresentação | Ação e persistência | Falha/retomada |
| --- | --- | --- | --- |
| ausência válida até 10 min | sem folha de retorno | segue para o jogo | não cria Recompensa de Retorno pendente |
| ausência válida >10 min antes de monetização | folha com duração, taxa registrada e base proporcional até 4h | `[Resgatar]` credita base uma vez | reabre a mesma recompensa se não concluída |
| ausência válida >10 min com monetização | base proporcional até 4h + opção de 20% | escolher base a credita; anúncio concluído credita base + bônus | falha/cancelamento mantém a recompensa pendente |
| intervalo incoerente | mensagem discreta de zero para a ausência e nova referência | `[Continuar]`; sem bônus | não bane, não apaga e não repete o aviso |

Escolher somente a base encerra a oportunidade. Escolher anúncio permite `[Tentar novamente]` ou `[Continuar com a base]`. Fechar o app preserva a decisão pendente sem duplicar crédito.

## Máquina de estados — Anúncios Recompensados

| Estado | UI | Resultado |
| --- | --- | --- |
| disponível | benefício, alternativa e ação explícita | inicia SDK somente após ação |
| sem consentimento publicitário aplicável | oferta inativa + alternativa-base | não solicita anúncio |
| offline/sem inventário | rótulo “indisponível agora”, sem modal recorrente | mantém base/compra normal |
| carregando | progresso cancelável; ação de origem bloqueada contra duplo toque | nenhuma recompensa ainda |
| exibindo | UI do provedor | ciclo e timers de UI não disparam nova ação |
| cancelado/erro | mensagem curta e ações de tentar/continuar | não consome cota, Aura ou bônus |
| conclusão validada | transação idempotente e recibo do benefício | concede exatamente uma vez |
| retorno do app sem callback conclusivo | `system_loading` durante reconciliação breve local/SDK | nunca presume sucesso nem repete compra; demora ou falha sai para erro literal |

A primeira oferta publicitária inclui explicação adicional; as seguintes usam o componente compacto. Anúncio nunca abre automaticamente.

## Máquina de estados — Ascensão

```text
[Jogar: Ascensão]
  → prévia rolável
  → pendência de retorno? resolver base e aceitar/recusar bônus
  → elegibilidade J >= 1Qa?
      não: informar falta exata, confirmar desabilitado
      sim: [Continuar]
  → confirmação final com verbo explícito
  → transação atômica
      sucesso: resumo + Jogar na nova jornada
      falha: estado anterior intacto + [Tentar novamente]
```

A prévia agrupa, sem esconder itens:

- `Você recebe`: parcela e Multiplicador atual → resultante;
- `Será reiniciado`: Aura Disponível, Aura da Jornada, níveis de Técnicas, aquisições/níveis/efeitos de Itens e Pré-requisitos;
- `Permanece`: Aura Total, Resto de Produção, Patamares, Transformações, Conquistas, Selos e Coleção Visual.

Voltar antes da confirmação final cancela sem mutação. Fechar durante a gravação executa recuperação atômica: estado inteiro anterior ou inteiro posterior, nunca combinação.

## Máquina de estados — Backup Manual

### Exportar

1. Ajustes → Backup Manual → `[Exportar]`.
2. O jogo cria snapshot consistente sem pausar ou alterar progresso econômico.
3. Abre compartilhamento/arquivos do sistema.
4. Cancelar retorna silenciosamente a Ajustes, sem confirmação de sucesso e sem tratar como erro.
5. Falha de escrita mantém save ativo e oferece tentar novamente.
6. Retorno do sistema confirma apenas quando houver resultado verificável; não promete onde um app externo guardou o arquivo.

### Importar

1. `[Escolher arquivo]` abre picker do sistema.
2. Cancelar retorna sem mensagem de erro.
3. O arquivo é lido em área temporária e validado sem tocar no save ativo.
4. Inválido/corrompido/incompatível: explica a categoria, preserva o progresso e oferece escolher outro.
5. Válido: prévia mostra data, versão, Aura Total, jornada/Ascensões e resumo de coleção.
6. Confirmação avisa que o único progresso ativo será substituído; exige ação final explícita.
7. Falha de gravação restaura o estado anterior; sucesso reinicia as superfícies a partir do save importado.

Consentimento de Analytics, relatórios pendentes e autorizações de diagnóstico não aparecem na prévia porque não integram o Backup Manual.

## Máquina de estados — Consentimentos e diagnóstico

| Fluxo | Momento | Escolhas equivalentes | Persistência e retomada |
| --- | --- | --- | --- |
| Analytics | uma vez, após primeira Aura | Permitir / Agora não; fechar = não | preferência local; sem eventos retroativos; recusa só revista em Ajustes |
| publicidade/CMP | antes da primeira solicitação aplicável | opções e detalhes fornecidos pelo fluxo certificado | não altera Analytics; impossibilidade deixa anúncio inativo |
| diagnóstico | abertura após falha/ANR local | Enviar / Não enviar; fechar = não | vale só para o lote mostrado; recusa apaga; envio pode aguardar conexão |

O diagnóstico informa quantidade, finalidade e categorias de dados em linguagem simples, com `[Ver detalhes]`. Enviar não habilita Analytics, não concede recompensa e não autoriza falhas futuras. Se o envio autorizado ficar offline, Ajustes mostra estado “aguardando conexão” sem bloquear o jogo.

## Erros, vazios e retomadas comuns

| Situação | Mensagem/estado | Ação segura |
| --- | --- | --- |
| save temporariamente indisponível | bloqueio curto antes de mutações; Jogar não promete crédito não persistido | tentar novamente; recuperar último snapshot válido |
| compra ficou obsoleta | preço/nível mudou antes da confirmação | atualizar cotação; não debitar |
| nó bloqueado | listar cada requisito ausente | ir ao predecessor ou Jogar para Patamar |
| coleção vazia em categoria | explicar como desbloquear sem vender atalho | ir à Loja/Jogar |
| anúncio indisponível | estado inline, sem erro recorrente | continuar sem anúncio |
| arquivo incompatível | versão de origem e compatibilidade quando legíveis | escolher outro; progresso intacto |
| sem espaço para exportar | erro do sistema resumido | liberar espaço/tentar outro destino |
| troca de idioma interrompida | manter o último catálogo completo | tentar novamente; nunca misturar locales na mesma tela |
| conteúdo excedeu layout | permitir quebra/rolagem; registrar defeito de QA | nunca truncar ação ou significado essencial |
| retorno após processo morto | reconstruir a fila persistente pela prioridade | não repetir recompensa, consentimento ou compra |

## Critérios de aceite de `ux-flow-v1`

1. Todos os destinos são alcançáveis a partir de uma das quatro áreas em no máximo três ativações, exceto percorrer nós por escolha do jogador.
2. Jogar, compra recorrente, equipar aparência e alterar canal sensorial são operáveis com uma mão em `360×800dp`.
3. Cada fluxo transitório acima possui sucesso, bloqueio, falha, cancelamento e reabertura definidos.
4. Nenhuma falha de anúncio, arquivo, rede ou SDK remove Aura, bloqueia a experiência-base ou duplica uma transação.
5. A Árvore única possui rota visual e rota linear semântica equivalentes, ambas incluindo Técnicas, Ramos e Convergências; Convergências mostram três requisitos explícitos.
6. Escala textual `200%`, pseudo-localização `+35%`, japonês e árabe RTL não escondem ação essencial.
7. Todos os controles têm destino de foco determinístico e retorno ao controle de origem.
8. Valores extremos seguem `number-format-v1`; comparação, compra e leitura assistiva usam o valor canônico.
9. Com som, vibração, movimento e flashes reduzidos/desativados, todo estado e resultado permanece compreensível.
10. Tutorial revisto, retomada offline, anúncio, Ascensão e importação nunca simulam ou repetem efeitos econômicos.
