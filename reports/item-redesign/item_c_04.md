# ITEM-C-04 — Roteador Desempregado

## Conceito

Roteador Wi-Fi físico e imediatamente reconhecível: caixa baixa com volume, dois pés, duas antenas laterais, LEDs frontais e símbolo de Wi-Fi construído apenas com curvas e círculos vetoriais. O estado “desempregado” aparece como um aparelho ligado que procura sinal, sem virar coroa, halo ou acessório da cabeça.

## Colocação

O item deixa `HEAD_BACK` e passa para o slot world-space `GROUND_PROP`, no subslot `GROUND_PROP_R`, composto atrás do Mascote e sem acompanhar bob ou inclinação. Fica apoiado no chão à direita, centrado aproximadamente em `(790, 750)` e com base próxima de `y=910`. Reutiliza a mesma área do despertador porque apenas um deles pode ser equipado por vez; assim, ambos formam uma família coerente de props de chão sem cobrir o personagem.

## Leitura em 48 px

- Caixa larga, duas antenas bem separadas e pés escuros sustentam a silhueta.
- LEDs frontais e símbolo de Wi-Fi em alto contraste diferenciam o objeto de uma caixa genérica.
- O thumbnail foi recentrado em `(790, 750)` e ampliado para `2.15×`, preservando antenas, corpo e apoio no chão.
- A variante `base` já contém toda a leitura física; `accent` e `glow` só reforçam estado e sinal.

## Efeito animado recomendado

Fazer os dois arcos de busca surgirem de dentro para fora em ciclo lento, com um pulso curto nos LEDs. As antenas podem inclinar no máximo `±2°`, sem se aproximar da cabeça. Em movimento reduzido, manter roteador, antenas, LEDs e símbolo totalmente estáticos, omitindo apenas pulso e ondas externas.

## Critérios de verificação

- [ ] O manifesto declara `slot: GROUND_PROP`, `zLayer: SLOT-GROUND-PROP-BACK`, `side: right` e `subslot: GROUND_PROP_R`.
- [ ] O item repousa no chão à direita e não nasce da cabeça, boné ou corpo do personagem.
- [ ] A silhueta mostra caixa, duas antenas e pés mesmo sem cor e sem glow.
- [ ] LEDs e símbolo/ondas de Wi-Fi são formas vetoriais, sem SVG `<text>`.
- [ ] Em 48 px, corpo e antenas permanecem inteiros e reconhecíveis.
- [ ] O roteador não cobre rosto, tronco nem os textos `SIX`/`SEVEN`.
- [ ] O slot compartilhado com o despertador não causa colisão porque somente um prop é equipado por vez.
- [ ] A variante reduzida preserva posição, silhueta e leitura física sem depender de animação.
