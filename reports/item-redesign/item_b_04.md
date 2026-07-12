# ITEM-B-04 — Sindicato dos Dois Toques

## Conceito

Par cooperativo de interfaces táteis vestido nas duas mãos: cada lado combina um botão circular sobre a palma, um conector local e um bracelete curto no pulso. Os dois botões repetem o mesmo símbolo de toque e usam as cores complementares da ramificação B; os braceletes terminam em soquetes na face externa/inferior, de onde o cabo pode descer sem cruzar cabeça ou orelhas. A união é entendida como dois dispositivos equivalentes trabalhando em par, sem faixa ou órbita atrás do corpo.

## Colocação

O item sai de `BODY_BACK` e passa para o slot frontal `HANDS_WEAR`, com `side=both`, subslot `HANDS_LINK_PAIR` e offset `(0.00, 0.00)`. Na pose neutra, os botões ficam centrados aproximadamente em `(238, 500)` e `(786, 506)`, sobre as palmas, enquanto os braceletes se alinham aos pulsos canônicos próximos de `(350, 575)` e `(674, 575)`. O SVG preserva essa composição para thumbnail e Coleção. Na cena articulada, o runtime substitui o desenho neutro pelo par completo de botões, braceletes e soquetes calculado a partir dos centros e pulsos atuais das mãos.

## Leitura em 48 px

- Dois discos grandes e separados formam a silhueta principal, um em cada mão.
- O ponto claro e o arco curto dentro de cada disco preservam a leitura de botão tátil.
- As cores magenta e coral diferenciam os lados sem quebrar a simetria funcional do par.
- Braceletes grossos, setas voltadas para fora e soquetes claros reforçam a rota segura sem depender de uma linha estática.
- O thumbnail foi recentrado em `(512, 525)` e ampliado para `1.15×`, enquadrando simultaneamente os dois botões, os dois pulsos e os glows locais.

## Efeito animado recomendado

O runtime traça uma ligação segmentada entre os dois soquetes, recalculada a partir dos pulsos atuais. Cada ponta sai para fora da silhueta, desce verticalmente ao lado do Mascote e só então cruza por uma curva segura abaixo da faixa facial, mesmo quando uma mão está alta e a outra baixa. Ao registrar um toque, os pulsos se encontram nessa rota e desaparecem. Em movimento reduzido, botões, braceletes, soquetes e ligação permanecem estáticos, sem trânsito de luz.

## Critérios de verificação

- [ ] Existem exatamente dois botões táteis principais, um sobre cada palma da pose neutra.
- [ ] Existem exatamente dois braceletes, alinhados aos pulsos neutros próximos de `(350, 575)` e `(674, 575)`.
- [ ] O slot é `HANDS_WEAR`, a camada é frontal e o subslot é `HANDS_LINK_PAIR` com `side=both`.
- [ ] A variante `base` já comunica dois dispositivos vestíveis e dois símbolos de toque sem depender de `accent`, `glow` ou animação.
- [ ] Os soquetes externos/inferiores permanecem separados e permitem que o cabo desça fora da silhueta antes de convergir.
- [ ] A arte estática não contém faixa, órbita, arco amplo ou linha rígida cruzando o corpo.
- [ ] Em 48 px, os dois discos, os dois pontos centrais e os dois braceletes continuam distinguíveis.
- [ ] Em escala de cinza, contornos, superfícies dos botões e centros claros permanecem separados por contraste.
- [ ] A variante `reduced` preserva botões, braceletes, símbolos de toque e soquetes sem depender de movimento.
- [ ] A linha dinâmica acompanha as mãos fora da pose neutra e termina nos soquetes, sem overshoot nem leitura de chicote.
- [ ] Nas poses Six, Seven e neutra, a rota e seu stroke ficam fora de cabeça/orelhas e só cruzam abaixo da faixa facial.
