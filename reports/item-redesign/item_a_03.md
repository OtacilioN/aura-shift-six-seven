# ITEM-A-03 — Óculos de QA

## Conceito

Par de óculos de QA vestido sobre os olhos do Mascote. Duas lentes arredondadas e transparentes, unidas por uma ponte curta e sustentadas por hastes laterais, formam uma silhueta inequívoca de óculos sem recorrer ao visor lateral facetado anterior. O contorno escuro preserva a leitura, enquanto ciano e azul mantêm a identidade do ramo A sem esconder a expressão.

## Colocação

O item sai de `FACE_SIDE` e passa para `FACE_WEAR`, centralizado no encaixe `FACE_EYES`. Após a correção contra o rig real da cena, as lentes têm centros em aproximadamente `(458, 374)` e `(566, 374)` no palco lógico de 1024 px. A ponte ocupa apenas o intervalo entre elas, e as hastes terminam nas laterais do rosto. A construção é simétrica, frontal e restrita à faixa dos olhos; não há placa contínua, extensão para um único lado ou qualquer elemento que possa ser lido como visor lateral.

## Leitura em 48 px

- Duas lentes separadas permanecem como as maiores massas visuais.
- Ponte curta e hastes grossas fecham a silhueta de óculos mesmo sem cor ou brilho.
- O preenchimento translúcido preserva a leitura dos olhos e da expressão do Mascote.
- O thumbnail foi recentrado em `(512, 374)` e ampliado para `2.8×`, com as duas hastes e os glows dentro do recorte.

## Efeito animado recomendado

Aplicar uma varredura curta e independente em cada lente, da esquerda para a direita, com pequena defasagem entre elas. O glow pode respirar entre 22% e 30% de opacidade, sempre mantendo dois contornos separados. Em movimento reduzido, conservar somente os reflexos diagonais e as linhas de inspeção estáticas. Nenhum reflexo deve atravessar a ponte ou unir as lentes em uma faixa contínua.

## Critérios de verificação

- [ ] Os centros das lentes permanecem próximos de `(458, 374)` e `(566, 374)` na composição de cena.
- [ ] Ponte e duas hastes são visíveis, e o conjunto é reconhecido como óculos/goggles sem consultar o nome do item.
- [ ] O item está frontalmente vestido sobre os olhos, sem deslocamento para `FACE_SIDE`.
- [ ] Olhos e expressão continuam legíveis através das lentes translúcidas.
- [ ] Não existe visor lateral, placa única ou glow contínuo ligando as duas lentes.
- [ ] Em 48 px e em escala de cinza, as duas lentes continuam separadas pelo contorno e pela ponte.
- [ ] A variante `base` já comunica os óculos; `accent` e `glow` apenas reforçam reflexão e inspeção.
- [ ] A variante `reduced` mantém lentes, ponte, hastes e reflexos estáticos sem depender de animação.
