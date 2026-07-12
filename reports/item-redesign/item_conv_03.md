# ITEM-CONV-03 — Parafuso de Convergência

## Conceito

Um parafuso físico superdimensionado representa a convergência como fixação concreta. A cabeça circular possui fenda em cruz, a haste longa exibe rosca helicoidal e três linhas independentes — ciano, magenta e dourada — terminam em pontos presos diretamente à borda da cabeça.

## Colocação

O item permanece em `AURA_BACK`, no `SLOT-AURA-BACK`, mas passa ao lado `right`, subslot `AURA_BACK_R` e offset `(0.18, -0.02)`. Cabeça, haste e linhas ficam na lateral direita e atrás do personagem. O corredor central do Mascote permanece livre; nenhuma parte essencial atravessa rosto, mãos ou torso.

## Leitura em 48 px

- A cabeça circular grande e a fenda em cruz formam a silhueta primária.
- A haste longa e quase vertical termina em ponta e mantém seis sulcos diagonais de rosca.
- As três linhas possuem contorno escuro, cores distintas e âncoras circulares na cabeça.
- O thumbnail usa centro `(820, 515)` e escala `0.94x` para enquadrar o parafuso lateral completo.

## Efeito animado recomendado

Enviar um pulso curto por cada linha até a respectiva âncora. Depois do encontro simultâneo, a cabeça pode girar poucos graus e a rosca receber um brilho descendente breve. Em movimento reduzido, manter toda a geometria estática e variar apenas a opacidade das três âncoras.

## Critérios de verificação

- [ ] A leitura principal é de um parafuso físico grande, não de halo, horizonte ou moldura.
- [ ] A cabeça é circular e contém uma fenda em cruz claramente legível.
- [ ] A haste é longa, quase vertical, levemente diagonal e termina em ponta.
- [ ] Seis sulcos diagonais comunicam rosca helicoidal.
- [ ] Existem exatamente três linhas presas à cabeça: ciano, magenta e dourada.
- [ ] Cada linha termina em uma âncora circular da mesma cor.
- [ ] O manifesto mantém `slot: AURA_BACK` e `zLayer: SLOT-AURA-BACK`.
- [ ] O attachment usa `side: right`, `subslot: AURA_BACK_R` e offset `(0.18, -0.02)`.
- [ ] Cabeça, haste e linhas permanecem na lateral direita e atrás do Mascote.
- [ ] O corredor central do Mascote fica livre em todas as variantes.
- [ ] O thumbnail enquadra cabeça, haste, ponta e as três linhas sem cortes essenciais.
- [ ] A variante reduzida preserva parafuso, rosca e três conexões sem depender de animação.
