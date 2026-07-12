# ITEM-B-05 — Extrato Astral Criativo

## Conceito

Extrato financeiro astral representado por uma folha vertical com canto dobrado, quadro de tendências, três linhas de lançamento e uma totalização destacada. O gráfico contrapõe duas séries inequívocas: a linha coral despenca enquanto a linha magenta cresce. Os lançamentos usam divisórias, marcadores de adição/subtração e blocos alinhados como valores, porém sem texto, numerais ou símbolo monetário. A silhueta única de documento impede a leitura anterior como barras de cidade ou skyline.

## Colocação

O item permanece no slot world-space `SCENE_FRAME`, atrás do personagem e fora da UI, mas passa ao subslot lateral `SCENE_FRAME_R`, com lado `right` e offset normalizado `(0.27, -0.11)`. A folha ocupa aproximadamente `x=714–974`, `y=154–742` no palco lógico de 1024 px, posicionando-se no alto/meio à direita. Assim, o painel acompanha a composição da cena sem cobrir rosto, tronco, mãos ou pernas do personagem.

## Leitura em 48 px

- O contorno alto de folha e o canto dobrado preservam a leitura de relatório antes dos detalhes internos.
- O quadro de gráfico mantém duas diagonais grossas e opostas, com pontos de dados redondos.
- Três lançamentos horizontais formam um ritmo de extrato; a dupla régua separa visualmente o total.
- A faixa inferior espessa funciona como totalização mesmo quando os sinais menores deixam de ser distinguíveis.
- O thumbnail é recentrado em `(845, 446)` e ampliado para `1.35×`, mantendo folha e glow dentro do recorte arredondado.

## Efeito animado recomendado

Revelar os três lançamentos de cima para baixo em intervalos de 80 ms. Em seguida, animar as duas séries do gráfico simultaneamente: a coral desce e a magenta sobe, ambas com os pontos surgindo no trajeto. A faixa de totalização recebe um único pulso magenta/coral ao concluir, sem deslocar a folha. Em movimento reduzido, manter todo o relatório estático e exibir apenas o pulso final com opacidade baixa.

## Critérios de verificação

- [ ] Em tamanho de cena, o item é reconhecido como folha/painel financeiro lateral, nunca como skyline.
- [ ] O manifesto declara `slot: SCENE_FRAME`, `zLayer: SLOT-SCENE-FRAME`, `side: right` e `subslot: SCENE_FRAME_R`.
- [ ] A massa visual permanece no alto/meio à direita e não cobre o personagem.
- [ ] Há três linhas de lançamento separadas e uma totalização isolada por régua dupla.
- [ ] O gráfico contém uma série descendente e outra ascendente, com pontos de dados visíveis.
- [ ] Nenhum elemento SVG `<text>`, numeral ou símbolo monetário é usado no item.
- [ ] A variante `base` já comunica documento, gráfico, lançamentos e total; `accent` e `glow` apenas reforçam hierarquia e efeito.
- [ ] O thumbnail de 48 px preserva folha, canto dobrado, gráfico e faixa de totalização sem cortar o glow.
- [ ] Em movimento reduzido, a posição lateral e a leitura financeira permanecem inalteradas.
