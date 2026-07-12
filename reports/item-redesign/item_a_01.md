# ITEM-A-01 — Botão Suspeito

## Conceito

Botão físico circular de quatro furos, com aro espesso, rebaixo interno e costuras cruzadas visíveis. O contorno `ink_900` separa a silhueta da camiseta; o miolo escuro, o aro ciano e a linha azul preservam a identidade do ramo A sem transformar o objeto em joia, broche ou interface digital.

## Colocação

O botão permanece no slot `CHEST`, mas passa para o lado esquerdo, ancorado em `CHEST_L` com offset `(-0.11, -0.04)`. Seu centro fica em `x=400`, `y=548` no palco lógico de 1024 px. A área completa ocupa aproximadamente `x=339–461`, `y=487–609`; assim, ele parece costurado à camiseta e fica fora da região central reservada às chamadas `SIX`/`SEVEN`.

## Leitura em 48 px

- Silhueta circular simples e contorno escuro forte.
- Quatro furos grandes em arranjo 2 × 2, unidos por duas costuras diagonais.
- Aro ciano, rebaixo escuro e linha azul continuam separados quando reduzidos.
- O thumbnail é centrado em `(400, 548)` e ampliado para `5.0×`, mantendo o botão inteiro dentro do recorte.

## Efeito animado recomendado

Pulsar apenas o halo externo entre 20% e 30% de opacidade em um ciclo suave de 1,4 s. As duas costuras podem receber um brilho curto e alternado, como se a Aura percorresse a linha, sem girar ou deslocar o botão. Em movimento reduzido, manter botão, furos e costuras totalmente estáticos; a identificação não depende do efeito.

## Critérios de verificação

- [ ] Em tamanho de cena, o item é reconhecido como botão físico circular, não como losango, broche ou ícone de interface.
- [ ] O centro visual permanece próximo de `x=400`, `y=548` e o botão parece preso à camiseta.
- [ ] Nenhuma parte do botão ou de seu halo cobre as chamadas `SIX`/`SEVEN`.
- [ ] Os quatro furos são distinguíveis e as duas costuras diagonais chegam visualmente até eles.
- [ ] Em 48 px, círculo, contorno, quatro furos e costuras continuam legíveis.
- [ ] Em escala de cinza, aro, rebaixo, furos e linha mantêm contraste suficiente.
- [ ] A variante `base` comunica um botão circular; `accent` acrescenta furos e costura, e `glow` apenas reforça o efeito.
- [ ] A variante `reduced` mantém todos os elementos necessários sem depender de animação.
- [ ] O halo não ultrapassa o recorte arredondado do thumbnail.
