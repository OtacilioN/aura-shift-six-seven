# ITEM-C-03 — Capa de Cache

## Conceito

Capa tecnológica realmente vestida atrás do mascote. Uma gola curva abraça os ombros e conecta duas caudas independentes de tecido, separadas por uma fenda central que se alarga até a bainha. Costuras digitais pontilhadas acompanham as curvas do pano, enquanto pequenos blocos dourados e menta sugerem fragmentos de cache incorporados à peça. A silhueta assimétrica e flexível elimina a leitura anterior de painel trapezoidal estático.

## Colocação

O item permanece em `BODY_BACK`, no `SLOT-BODY-BACK`, centralizado em `BODY_BACK_CENTER`. O offset passa a `(0.00, -0.02)` para assentar a gola na linha dos ombros. A geometria ocupa aproximadamente `x=272–752`, `y=378–832` no palco lógico de 1024 px: começa abaixo da cabeça, acompanha as laterais do corpo e termina antes dos pés. Como camada traseira, a gola e as caudas contornam o mascote sem encobrir rosto, mãos ou calçados.

## Leitura em 48 px

- A curva larga da gola e os dois volumes laterais comunicam uma capa vestida antes dos detalhes.
- A fenda central cresce em direção à bainha e mantém as duas caudas distinguíveis na redução.
- Costuras espessas e pontilhadas preservam o caráter digital; os blocos de cache aparecem como pequenos agrupamentos contrastantes.
- A bainha curva em duas partes evita qualquer silhueta de placa ou painel único.
- O thumbnail usa centro `(512, 600)` e escala `1.45×`, destacando gola, ombros, fenda e caudas sem cortar o glow.

## Efeito animado recomendado

Aplicar um balanço curto e alternado nas duas caudas, com pivô próximo aos ombros e amplitude máxima de 3°. Os blocos de cache podem acender em sequência da gola para a bainha, seguidos por um único pulso que percorre as costuras digitais. Em movimento reduzido, manter toda a capa estática e usar apenas uma variação discreta de opacidade no glow.

## Critérios de verificação

- [ ] Em tamanho de cena e em 48 px, o item é reconhecido como capa vestida, nunca como painel trapezoidal.
- [ ] A gola acompanha os ombros e permanece abaixo da cabeça.
- [ ] Duas caudas de tecido independentes e uma fenda central crescente permanecem visíveis.
- [ ] A bainha termina antes dos pés e não altera a leitura dos calçados.
- [ ] O manifesto mantém `slot: BODY_BACK`, `zLayer: SLOT-BODY-BACK`, `side: center` e `subslot: BODY_BACK_CENTER`.
- [ ] Há pequenos blocos de cache dourados e menta em ambas as caudas.
- [ ] As costuras digitais seguem curvas de tecido e não formam linhas horizontais de painel.
- [ ] A variante `base` já comunica gola, ombros e caudas; `accent` e `glow` apenas reforçam tecnologia e movimento.
- [ ] O thumbnail enquadra a peça inteira, incluindo gola, fenda, bainha e brilho externo.
- [ ] Em movimento reduzido, a silhueta e todos os sinais essenciais permanecem estáticos e legíveis.
