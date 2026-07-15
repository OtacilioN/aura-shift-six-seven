# ITEM-A-03 — Óculos de QA

## Conceito

Par de óculos escuros de QA vestido sobre os olhos do Mascote. Duas lentes opacas, angulares e levemente envolventes, unidas por uma ponte curta e sustentadas por hastes neon, criam uma silhueta confiante de sunglasses. A massa quase preta domina a leitura; ciano e azul aparecem na sobrancelha da armação, nos reflexos diagonais e no glow inferior sem transformar o item num visor tecnológico genérico.

## Colocação

O item permanece em `FACE_WEAR`, centralizado no encaixe `FACE_EYES`. As lentes têm centros em aproximadamente `(446, 374)` e `(578, 374)` no palco lógico de 1024 px: o afastamento externo cria a leitura envolvente sem perder o alinhamento com os olhos. A ponte ocupa apenas o intervalo entre elas, e as hastes terminam nas laterais do rosto. A construção é frontal e restrita à faixa dos olhos; não há placa contínua, extensão para um único lado ou qualquer elemento que possa ser lido como visor lateral.

## Leitura em 48 px

- Duas lentes escuras separadas permanecem como as maiores massas visuais.
- Ponte curta, hastes grossas e cantos externos elevados fecham a silhueta de óculos escuros mesmo sem brilho.
- O preenchimento quase preto sustenta a atitude do item; a expressão continua legível pela pose e pela boca do Mascote.
- O thumbnail foi recentrado em `(512, 374)` e ampliado para `2.8×`, com as duas hastes e os glows dentro do recorte.

## Efeito animado recomendado

Aplicar um brilho curto e independente nos reflexos diagonais, da esquerda para a direita, com pequena defasagem entre as lentes. O glow inferior pode respirar entre 22% e 30% de opacidade, sempre mantendo os dois volumes separados. Em movimento reduzido, conservar somente os reflexos diagonais e a armação neon estática. Nenhum reflexo deve atravessar a ponte ou unir as lentes em uma faixa contínua.

## Critérios de verificação

- [ ] Os centros das lentes permanecem próximos de `(446, 374)` e `(578, 374)` na composição de cena.
- [ ] Ponte e duas hastes são visíveis, e o conjunto é reconhecido como óculos/goggles sem consultar o nome do item.
- [ ] O item está frontalmente vestido sobre os olhos, sem deslocamento para `FACE_SIDE`.
- [ ] As lentes são visualmente escuras e opacas; pose, boca e silhueta corporal mantêm a expressão legível.
- [ ] Não existe visor lateral, placa única ou glow contínuo ligando as duas lentes.
- [ ] Em 48 px e em escala de cinza, as duas lentes continuam separadas pelo contorno e pela ponte.
- [ ] A variante `base` já comunica os óculos; `accent` e `glow` apenas reforçam reflexão e inspeção.
- [ ] A variante `reduced` mantém lentes, ponte, hastes e reflexos estáticos sem depender de animação.
