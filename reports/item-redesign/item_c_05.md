# ITEM-C-05 — Moldura 404

## Conceito

Moldura de cena quebrada que materializa um cenário não encontrado. Quatro trilhos de canto têm lacunas visíveis, lascas angulares e terminações abruptas. No alto, os numerais `404` são desenhados exclusivamente por segmentos vetoriais de `<path>`, sem `<text>`. Um horizonte existe apenas nas laterais: suas partes avançam em direção ao centro, quebram em pontas deslocadas e deixam uma ausência ampla e inequívoca onde o mundo deveria continuar.

## Colocação

O item permanece atrás do personagem no slot `SCENE_FRAME`, z-layer `SLOT-SCENE-FRAME`, lado `center` e subslot `SCENE_FRAME_CENTER`. O offset passa a `(0.00, -0.04)` para acomodar o `404` acima da cabeça. A moldura ocupa as bordas de `x=76–948`, enquanto todos os trilhos, lascas e trechos de horizonte terminam antes do corredor central aproximado de `x=388–636`. O centro da cena fica livre; assim, o item enquadra a silhueta sem cobrir rosto, tronco, mãos ou pernas.

## Leitura em 48 px

- Os dois pares de cantos grossos formam primeiro a leitura de moldura, mesmo com as interrupções.
- As lacunas laterais e inferiores, acompanhadas por lascas angulares, preservam a leitura de objeto quebrado.
- O `404` usa três grupos compactos de segmentos retos, com contorno escuro e núcleo dourado, legíveis sem fonte ou elemento textual.
- Os dois trechos menta do horizonte apontam para o vazio central e nunca atravessam o personagem.
- O thumbnail passa a usar centro `(512, 468)` e escala `0.92×`, mantendo moldura, numerais, horizonte e glow dentro do recorte.

## Efeito animado recomendado

Acender os segmentos do `404` em três pulsos curtos, da esquerda para a direita. Em seguida, fazer os trechos laterais do horizonte avançarem por poucos pixels e falharem antes de alcançar o centro; as lascas recebem um deslocamento seco de 2 px e retornam. Em movimento reduzido, manter toda a geometria estática e aplicar somente um pulso leve de opacidade ao glow dos numerais.

## Critérios de verificação

- [ ] Em tamanho de cena e em 48 px, o item é reconhecido como moldura de cena quebrada com mensagem visual `404`.
- [ ] O manifesto mantém `slot: SCENE_FRAME`, `zLayer: SLOT-SCENE-FRAME`, `side: center` e `subslot: SCENE_FRAME_CENTER`.
- [ ] O attachment usa offset `(0.00, -0.04)` e mantém o item atrás do personagem.
- [ ] Os numerais `404` são construídos por segmentos vetoriais e o item não contém elemento SVG `<text>`.
- [ ] Quatro cantos, lacunas laterais e inferiores e lascas angulares tornam a quebra inequívoca.
- [ ] O horizonte aparece somente em trechos laterais e possui uma ausência ampla no centro.
- [ ] Nenhum trilho, fragmento ou trecho do horizonte invade o corredor central do personagem.
- [ ] A variante `base` já comunica moldura, `404` e horizonte ausente; `accent` e `glow` apenas reforçam dano e falha.
- [ ] O thumbnail em `(512, 468, 0.92)` preserva os três numerais e as quatro bordas sem corte relevante.
- [ ] Em movimento reduzido, todos os sinais essenciais permanecem estáticos e legíveis.
