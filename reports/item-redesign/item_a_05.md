# ITEM-A-05 — Coroa de Hotfix

## Conceito

Coroa tecnológica vestível com três pontas inequívocas, corpo escuro facetado e uma faixa frontal dividida em placas de reparo ciano e azul. Os segmentos sobrepostos, contornos espessos e rebites claros fazem o “hotfix” parecer uma correção aplicada às pressas, mas já incorporada ao objeto. A leitura depende da silhueta de coroa e dos patches aparafusados; não existe arco, anel ou halo abstrato atrás da cabeça.

## Colocação

O item sai de `HEAD_BACK` e passa para `HEAD_WEAR`, no encaixe frontal `HEAD_WEAR_CENTER`, com offset vertical `-0.06`. A coroa fica centralizada em `x=512`, ocupa aproximadamente `x=320–704` e `y=42–250` incluindo contorno, e apoia sua faixa curva imediatamente acima do boné/cabeça. A base acompanha a largura do topo do Mascote sem descer sobre os olhos; por estar em camada vestível frontal, a faixa parece apoiada no personagem em vez de formar uma aura ao fundo.

## Leitura em 48 px

- A ponta central alta e as duas pontas laterais formam primeiro a silhueta clássica de coroa.
- A faixa curva grossa ancora o objeto sobre a cabeça e separa a coroa do contorno do Mascote.
- Três placas alternadas permanecem como blocos de cor distintos; rebites são reforço secundário, não requisito de identificação.
- O thumbnail foi recentrado em `(512, 158)` e ampliado para `1.9×`, mantendo pontas, contorno e patches dentro do recorte.

## Efeito animado recomendado

Acender brevemente a borda de cada patch em sequência, da esquerda para a direita, como três correções aplicadas em cadeia. Cada pulso pode durar cerca de 120 ms, com uma pausa longa entre ciclos; a coroa, as pontas e a faixa permanecem imóveis. O brilho fica restrito ao perímetro das placas e nunca se expande para um arco ao redor da cabeça. Em movimento reduzido, manter placas e rebites estáticos, sem pulso.

## Critérios de verificação

- [ ] Sem consultar o nome, a silhueta é reconhecida como coroa, com ponta central e duas pontas laterais.
- [ ] A faixa inferior fica alinhada e apoiada acima do boné/cabeça, sem cobrir olhos ou expressão.
- [ ] O slot é `HEAD_WEAR`, o subslot é `HEAD_WEAR_CENTER` e o item acompanha bob e inclinação do Mascote.
- [ ] Os três patches frontais continuam separados em 48 px e comunicam reparo/segmentação.
- [ ] Em escala de cinza, contorno, faixa e placas continuam separáveis por massa e borda.
- [ ] A variante `base` já comunica uma coroa; `accent` adiciona patches e rebites, e `glow` ilumina somente as placas.
- [ ] A variante `reduced` preserva coroa, faixa, patches e rebites sem depender de animação.
- [ ] Não existe halo, arco aberto, órbita ou anel abstrato atrás da cabeça.
- [ ] O thumbnail enquadra todas as pontas e os glows locais sem tocar o recorte arredondado.
