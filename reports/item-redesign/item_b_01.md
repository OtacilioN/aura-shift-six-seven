# ITEM-B-01 — Despertador das 6:70

## Conceito

Despertador híbrido clássico/digital, reconhecível pela caixa arredondada, dois sinos superiores, alça, botão de alarme e dois pés largos. O visor escuro mostra `6:70` exclusivamente com retângulos e círculos vetoriais no padrão de sete segmentos; não há elemento SVG `<text>`. Magenta e coral preservam a identidade do ramo B, enquanto segmentos claros garantem contraste imediato.

## Colocação

O item deixa o `HIP` e passa para o slot world-space `GROUND_PROP`, ancorado em `GROUND_PROP_R` e composto atrás do Mascote. Ele já nasce no palco lógico à direita do personagem, centrado aproximadamente em `(790, 800)`, com os pés apoiados perto de `y=918`. Assim, funciona como prop de chão e não acompanha a inclinação, o balanço ou o quadril do mascote. Sua massa principal ocupa aproximadamente `x=640–940`, `y=618–918`, sem cobrir rosto, boné ou os textos `SIX`/`SEVEN`.

## Leitura em 48 px

- A silhueta combina dois sinos bem separados, caixa arredondada e pés triangulares largos.
- O visor escuro cria uma janela de alto contraste dentro do corpo magenta/escuro.
- Os quatro algarismos e os dois pontos usam segmentos grossos e espaçados; a leitura pretendida é `6:70`, inclusive sem fonte instalada.
- O thumbnail foi recentrado em `(790, 790)` e ampliado para `2.25×`, preservando sinos, pés, vibração e brilho dentro do recorte.
- Mesmo se os detalhes internos se comprimirem, a silhueta continua sendo lida como despertador antes de qualquer efeito.

## Efeito animado recomendado

Alternar discretamente os dois arcos externos de vibração a cada 90 ms por três batidas, enquanto os sinos fazem rotações opostas de no máximo `±3°`. O contorno magenta pode pulsar de 24% a 34% de opacidade e a elipse no chão pode expandir uma única vez ao disparar. O display permanece imóvel para que `6:70` nunca dependa de animação. Em movimento reduzido, manter corpo, sinos, pés e segmentos estáticos, omitindo apenas vibração e pulso.

## Critérios de verificação

- [ ] Em tamanho de cena, o item fica no chão à direita, próximo de `(790, 800)`, e não no quadril nem no centro do personagem.
- [ ] O manifesto declara `slot: GROUND_PROP`, `zLayer: SLOT-GROUND-PROP-BACK` e `subslot: GROUND_PROP_R`.
- [ ] A silhueta é reconhecida como despertador por corpo, dois sinos e dois pés, mesmo sem cor e sem glow.
- [ ] O visor lê `6:70` por segmentos vetoriais e nenhum `<text>` é emitido pelo desenho do item.
- [ ] O thumbnail de 48 px mantém o relógio inteiro, sem cortar sinos, pés ou arcos de vibração.
- [ ] A variante `base` já contém silhueta, visor e horário; `accent` e `glow` apenas reforçam acabamento e efeito.
- [ ] Em movimento reduzido, o relógio preserva a mesma leitura e posição world-space.
- [ ] Nenhuma camada invade rosto, boné ou os textos `SIX`/`SEVEN`.
