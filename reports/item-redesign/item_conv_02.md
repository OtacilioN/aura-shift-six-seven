# ITEM-CONV-02 — Convergência por Cansaço

## Conceito

Três fluxos independentes — ciano, magenta e dourado — chegam ao mesmo núcleo depois de trajetórias cansadas. Cada percurso alterna curvas de amplitudes diferentes, pequenos hiatos e retomadas desalinhadas; perto do encontro, as curvas encurtam e se tornam progressivamente suaves. O destino é um único núcleo menta, circular e concêntrico, acompanhado por dois sinais simétricos de estabilização. A silhueta é aberta e ramificada, sem contorno triangular ou prisma.

## Colocação

O item permanece atrás do personagem no slot `AURA_BACK`, z-layer `SLOT-AURA-BACK`, lado `center` e subslot `AURA_BACK_CENTER`. O attachment passa ao offset `(0.00, -0.02)`, elevando discretamente o núcleo para que a convergência seja percebida ao redor do torso sem deslocar a aura de sua origem canônica. Os fluxos ocupam principalmente as laterais e a base; no centro existem somente o núcleo compacto e três terminações finas, preservando a leitura do corpo sobre a camada traseira.

## Leitura em 48 px

- As três cores e três origens espaciais continuam separadas antes do encontro.
- Os hiatos grandes e as curvas irregulares comunicam desgaste sem depender de animação.
- O círculo menta perfeito contrasta com as aproximações instáveis e funciona como destino comum.
- Os arcos simétricos acima e abaixo do núcleo são o sinal imediato de estabilização.
- O thumbnail usa centro `(512, 520)` e escala `1.04x`, preenchendo o recorte com os três fluxos sem cortar suas origens.

## Efeito animado recomendado

Fazer pulsos curtos avançarem de modo hesitante pelos trechos externos, pausando nos hiatos e perdendo velocidade a cada curva. Ao alcançar os segmentos finais, os três pulsos adotam a mesma cadência e entram juntos no núcleo. O núcleo responde com uma única expansão circular menta e os dois arcos simétricos acendem simultaneamente. Em movimento reduzido, manter toda a geometria estática e alternar apenas uma variação leve de opacidade no anel externo.

## Critérios de verificação

- [ ] Existem exatamente três fluxos principais, nas cores ciano, magenta e dourado.
- [ ] Cada fluxo possui percurso próprio, irregular e interrompido antes da aproximação final.
- [ ] Os três fluxos terminam no mesmo núcleo circular menta.
- [ ] As aproximações finais são mais curtas e suaves que os trechos externos.
- [ ] Dois arcos simétricos e anéis concêntricos comunicam estabilização.
- [ ] A composição não forma triângulo fechado, prisma ou outro polígono dominante.
- [ ] O manifesto conserva `slot: AURA_BACK`, `zLayer: SLOT-AURA-BACK`, `side: center` e `subslot: AURA_BACK_CENTER`.
- [ ] O attachment usa offset `(0.00, -0.02)` e todo o item permanece atrás do personagem.
- [ ] O corredor central não recebe faixas largas nem preenchimento opaco além do núcleo compacto.
- [ ] Em 48 px, as três origens, os hiatos e o núcleo comum permanecem distinguíveis.
- [ ] O thumbnail em `(512, 520, 1.04)` mantém os três extremos dentro do recorte.
- [ ] A variante de movimento reduzido preserva cansaço, convergência e estabilização sem animação essencial.
