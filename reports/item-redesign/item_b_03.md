# ITEM-B-03 — Anel de Resto

## Conceito

Anel físico ampliado, com aro vertical espesso, vazado central inequívoco, encaixe superior e uma única gema pequena. A assimetria do ponto remanescente e a inclinação suave comunicam “resto” sem números, texto ou uma segunda órbita desenhada. A massa escura, o contorno `ink_900` e os acentos magenta/coral preservam a identidade do ramo B e impedem que o objeto pareça um halo de chão.

## Colocação

O item sai de `GROUND_BACK` e passa para o slot frontal `HAND_PROP`, no subslot genérico `HAND_PROP_HIGH_R`, com offset `(0.14, -0.16)`. O aro fica centrado aproximadamente em `(790, 260)` no palco lógico de 1024 px, pairando acima e um pouco à direita da mão elevada. Incluindo contorno e brilho, ocupa cerca de `x=650–920`, `y=80–420`: permanece fora dos olhos e da boca, não cruza o eixo central do rosto e deixa livre a região dos pés. Sprite e ponto orbital usam a mesma transformação vestível de bob, lean e rotação; por isso o ponto permanece registrado no aro sem saltar para outro referencial durante a pose.

## Leitura em 48 px

- A silhueta vertical fechada e o vazio central sobrevivem como sinais principais de um anel.
- O encaixe superior e a gema única continuam separados do aro, evitando leitura de pulseira ou halo.
- Os dois pequenos acentos laterais reforçam volume sem formar um segundo anel.
- O thumbnail é centrado em `(790, 252)` e ampliado para `2.2×`, enquadrando aro, gema e brilho local sem incluir o chão ou o corpo inteiro.

## Efeito animado recomendado

O runtime move um único ponto pequeno em órbita elíptica ao redor do aro, usando a mesma âncora authored e a mesma transformação vestível de `remainderOrbit`. O sprite do anel permanece estável; apenas o ponto completa uma volta lenta, com leve variação de opacidade ao passar atrás do aro. Em movimento reduzido, o ponto permanece junto da gema e aro, encaixe e reflexos ficam totalmente estáticos.

## Critérios de verificação

- [ ] Sem consultar o nome, o item é reconhecido como anel/aro físico com uma gema pequena.
- [ ] Não existem elipses achatadas no chão, anéis ao redor dos pés ou um halo de escala cenográfica.
- [ ] O centro visual permanece próximo de `(790, 260)` e o objeto paira no território alto lateral de `HAND_PROP`.
- [ ] O aro e seus glows não cobrem olhos, boca ou o centro do rosto nas poses Six, Seven e neutra.
- [ ] A gema é o único ponto remanescente incorporado ao sprite; qualquer ponto orbital adicional vem do runtime.
- [ ] O ponto orbital herda exatamente bob, lean e rotação do `HAND_PROP` e não desliza em relação ao aro.
- [ ] Em 48 px, contorno externo, vazio central e gema continuam distinguíveis.
- [ ] Em escala de cinza, aro, vazado, encaixe e gema permanecem separados por massa e contorno.
- [ ] A variante `base` já comunica o anel; `accent` acrescenta reflexos e `glow` fica restrito a arcos locais e à gema.
- [ ] A variante `reduced` mantém aro, encaixe, gema e reflexos sem depender de movimento.
- [ ] O thumbnail contém o objeto completo e nenhum glow toca o recorte arredondado.
