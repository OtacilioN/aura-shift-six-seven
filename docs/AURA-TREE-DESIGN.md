# Aura Shift: Six Seven — Topologia da Árvore de Aura

> Status: grafo, Pré-requisitos, Patamares e parâmetros econômicos aprovados em `balance-v0.1`; identidades culturais fechadas em P04.

## Visão geral

A Árvore de Aura possui três ramos simétricos de cinco itens e três Itens de Convergência opcionais. A simetria controla complexidade e garante que nenhum ramo comece com uma armadilha estrutural. Tema e aparência diferenciam as rotas sem alterar o grafo ou a eficiência econômica.

No MVP, a simetria também é econômica: itens A, B e C de mesma profundidade possuem parâmetros idênticos. Tema e aparência diferenciam a experiência colecionável, mas não criam um ramo numericamente superior. Somente as Convergências possuem parâmetros próprios fora desse espelho.

Os territórios finais são **Poise** (A), **Motion** (B) e **Signal** (C). Eles descrevem apenas identidade, aparência e áudio; não são classes, afinidades ou multiplicadores. As Convergências formam o território **Spectrum** e continuam opcionais.

```mermaid
flowchart TD
    T["Switch Stance nível 1"] --> A1["A-01 Quiet Flex"]
    T --> B1["B-01 Pocket Pulse"]
    T --> C1["C-01 Glitch Pin"]

    A1 -- "nível 10" --> A2["A-02 Clean Line"]
    A2 -- "nível 25" --> A3["A-03 Mirror Glint"]
    A3 -- "nível 50" --> A4["A-04 Gravity Coat"]
    A4 -- "nível 100" --> A5["A-05 Crownless Halo"]

    B1 -- "nível 10" --> B2["B-02 Step Spark"]
    B2 -- "nível 25" --> B3["B-03 Floor Echo"]
    B3 -- "nível 50" --> B4["B-04 Night Current"]
    B4 -- "nível 100" --> B5["B-05 City Tremor"]

    C1 -- "nível 10" --> C2["C-02 Loop Lens"]
    C2 -- "nível 25" --> C3["C-03 Static Cape"]
    C3 -- "nível 50" --> C4["C-04 Signal Crown"]
    C4 -- "nível 100" --> C5["C-05 Horizon Frame"]

    A1 -. "todos no nível 10" .-> V1["CONV-01 Triple Sync"]
    B1 -. "todos no nível 10" .-> V1
    C1 -. "todos no nível 10" .-> V1

    A3 -. "todos no nível 25" .-> V2["CONV-02 Full Spectrum"]
    B3 -. "todos no nível 25" .-> V2
    C3 -. "todos no nível 25" .-> V2

    A5 -. "todos no nível 50" .-> V3["CONV-03 Worldline"]
    B5 -. "todos no nível 50" .-> V3
    C5 -. "todos no nível 50" .-> V3
```

Todas as setas de uma Convergência são conjuntivas. Além das dependências mostradas, cada nó exige o Patamar de Aura correspondente.

## Regras dos ramos

| Nó | Custo-base | Contribuição-base por nível | Pré-requisito de Item | Patamar |
| --- | ---: | ---: | --- | --- |
| `A/B/C-01` | `270` | `0,75 Aura/s` | `TECH-01` no nível `1` | acesso inicial, sem limiar adicional |
| `A/B/C-02` | `2.350` | `6,7 Aura/s` | respectivo `01` no nível `10` | `1K` Aura Total |
| `A/B/C-03` | `67.000` | `67 Aura/s` | respectivo `02` no nível `25` | `1M` Aura Total |
| `A/B/C-04` | `67.000` | `6.700 Aura/s` | respectivo `03` no nível `50` | `1B` Aura Total |
| `A/B/C-05` | `67.000.000.000` | `67.000.000 Aura/s` | respectivo `04` no nível `100` | `1T` Aura Total |

Atender o nível sem possuir o Patamar mantém o item bloqueado. Possuir o Patamar sem atender o nível também mantém o item bloqueado. A interface deve mostrar separadamente qual condição falta.

Os Orçamentos de Gate exatos do predecessor são `5.487`, `500.078`, `483.587.018` e `524.526.228.030 Aura`, respectivamente. Para a última transição do gate de nível `100`, `99→100` custa `68.416.522.780`; `100→101`, que já ocorre depois do gate, custa `78.679.001.197`. Essa distinção deve existir nas fixtures para impedir um erro de índice.

## Regras das Convergências

| Item | Requisitos simultâneos | Custo-base | Contribuição-base por nível | Papel |
| --- | --- | ---: | ---: | --- |
| `ITEM-CONV-01` | `A-01`, `B-01`, `C-01` no nível `10` e `1K` Aura Total | `6.700 Aura` | `7,5 Aura/s` | recompensa de amplitude inicial |
| `ITEM-CONV-02` | `A-03`, `B-03`, `C-03` no nível `25` e `1B` Aura Total | `26.800.000 Aura` | `3.350 Aura/s` | recompensa de amplitude intermediária |
| `ITEM-CONV-03` | `A-05`, `B-05`, `C-05` no nível `50` e `1Qa` Aura Total | `670.000.000.000.000 Aura` | `13.400.000.000 Aura/s` | objetivo amplo tardio |

Os respectivos Orçamentos de Amplitude são `16.461`, `44.288.124` e `1.452.336.002.684.412 Aura`. O primeiro nível de cada Convergência acrescenta `1/6` da produção somada dos três nós diretamente exigidos. O custo adicional permanece fora desse orçamento e precisa ser pago normalmente.

Convergências:

- possuem aquisição e níveis como outros Itens de Aura;
- aumentam Produção Passiva;
- não desbloqueiam nós de ramo;
- não liberam Patamares;
- não são condição de Ascensão;
- são reiniciadas pela Ascensão;
- podem ser ignoradas por uma estratégia especialista.

## Ascensão

Na Ascensão, aquisições e níveis retornam ao estado inicial, portanto todos os Pré-requisitos precisam ser reconstruídos. Os Patamares já liberados por Aura Total permanecem abertos. O Multiplicador de Ascensão torna a reconstrução progressivamente mais rápida sem entregar automaticamente os itens.

## Estados de interface

Cada nó bloqueado deve distinguir:

- Patamar de Aura ainda fechado;
- item predecessor ainda não adquirido;
- nível do predecessor insuficiente;
- múltiplos requisitos de Convergência parcialmente atendidos.

Convergências devem mostrar o progresso de cada um dos três requisitos, sem uma porcentagem que esconda qual ramo falta.

## Cenários obrigatórios de simulação

1. especialista em A, B ou C;
2. investimento dividido em dois ramos;
3. investimento amplo buscando `CONV-01`;
4. investimento amplo buscando `CONV-02`;
5. investimento amplo tardio buscando `CONV-03`;
6. reconstrução de cada rota após a primeira Ascensão;
7. Compra em Lote que satisfaz um ou vários Pré-requisitos.

Especialista A, B e C devem produzir saídas idênticas sob o mesmo Perfil de Simulação e heurística. Qualquer diferença é defeito, não variação aceita.

## Identidade e apresentação fechadas

- Poise ocupa a coluna esquerda, Motion a central e Signal a direita no LTR; em RTL, a composição espelha visualmente, mas IDs, requisitos e ordem semântica permanecem estáveis.
- Convergências ficam no eixo entre as três colunas e exibem individualmente os três requisitos, nunca uma porcentagem agregada.
- Em desbloqueios simultâneos: persistir todos; destacar primeiro o nó de ramo de menor profundidade e depois a Convergência; empates seguem ordem estável A, B, C e Convergência. A ordem não implica recomendação econômica.
- Nomes e aparências completos estão em `CONTENT-CATALOG.md`; nenhum label localizado substitui o ID em save, analytics ou fixtures.
