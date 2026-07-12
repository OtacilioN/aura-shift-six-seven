# ITEM-C-02 — Decimal Clandestino

## Conceito

Um pequeno decimal fugitivo corre para dentro de um bolso: o ponto decimal mint, destacado e com um olho desconfiado, vem seguido por um `6` de segmentos completos e pelo topo de um `7` já parcialmente escondido. Pernas dobradas, rastro curto e uma gota de tensão dão humor à fuga. Toda a leitura numérica é construída com círculos e paths; o SVG não usa elemento `<text>`.

## Colocação

O item sai da lateral do rosto e passa para `HIP`, no subslot direito `HIP_R`, com offset normalizado `(0.17, 0.06)`. A composição ocupa aproximadamente `x=611–839`, `y=625–768` no palco de 1024 px. Assim, o decimal permanece pequeno e lateral, junto ao quadril, sem cruzar o texto central, olhos, boca ou silhueta da cabeça e sem possibilidade de leitura como monóculo ou lente.

## Leitura em 48 px

- O ponto mint grande estabelece imediatamente o início decimal.
- O `6` segmentado permanece inteiro; o `7` deixa apenas topo e haste superior visíveis antes de desaparecer no bolso.
- A massa escura do bolso cria uma borda de oclusão inequívoca e uma silhueta diferente de qualquer acessório facial.
- As duas pernas anguladas e a cauda de movimento mantêm a piada de “decimal fugitivo” mesmo quando olho, costura e gota deixam de ser distinguíveis.
- O thumbnail é centrado em `(730, 690)` e ampliado para `3.2×`, enquadrando ponto, segmentos, pernas, bolso e glows locais.

## Efeito animado recomendado

Fazer o decimal avançar dois pequenos passos em direção ao bolso enquanto o último segmento do `7` desaparece sob a borda. O ponto olha uma vez para trás, a cauda oscila e as duas linhas de velocidade surgem brevemente; ao final, o bolso dá um único salto de 2 px. Em movimento reduzido, manter a pose estática de meia-fuga e apenas modular suavemente o brilho mint do ponto.

## Critérios de verificação

- [ ] Sem consultar o nome, a composição é lida como ponto decimal seguido por dígitos segmentados entrando em um bolso.
- [ ] O manifesto declara `slot: HIP`, `zLayer: SLOT-HIP`, `side: right` e `subslot: HIP_R`.
- [ ] O item fica no quadril direito e não cobre rosto, olhos, boca ou cabeça em nenhuma pose.
- [ ] A forma não pode ser confundida com monóculo, lente, óculos ou halo.
- [ ] O ponto decimal é mais destacado que os segmentos e aparece antes deles na direção de leitura.
- [ ] Um dígito segmentado permanece reconhecível e o seguinte está parcialmente ocluso pela borda do bolso.
- [ ] Pernas, rastro e gota comunicam fuga e humor sem depender de texto.
- [ ] Nenhum elemento SVG `<text>` é usado; ponto e dígitos são construídos somente com geometria vetorial.
- [ ] A variante `base` já comunica decimal, corrida e esconderijo; `accent` e `glow` apenas reforçam expressão e movimento.
- [ ] Em 48 px, ponto, `6`, topo do `7` e bolso continuam separados por cor, contorno e oclusão.
- [ ] A variante reduzida preserva a pose de meia-fuga sem depender de animação.
