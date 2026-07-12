# ITEM-C-01 — Glitch Homologado

## Conceito

Crachá físico de homologação preso à camiseta por uma presilha curta. O cartão claro, a moldura escura e o cabeçalho dourado formam uma silhueta administrativa reconhecível; no centro, um selo circular completo com marca de aprovação comunica que o glitch foi oficialmente carimbado. Pequenas franjas ciano/magenta e duas faixas horizontais deslocadas introduzem a falha de canais sem transformar o objeto em um quadrado abstrato.

## Colocação

O item permanece no slot `CHEST`, mas passa a usar a âncora lateral `CHEST_L` com offset `(-0.12, -0.01)`. Seu centro visual fica próximo de `x=385`, `y=535`, levemente inclinado como um crachá realmente preso ao peito. A composição completa ocupa aproximadamente `x=315–455`, `y=445–624` no palco lógico de 1024 px e deixa livre o corredor central das chamadas `SIX`/`SEVEN`. Essa região pode se aproximar da usada pelo `ITEM-A-01` em `x≈400`, `y=548`, pois os dois pertencem ao mesmo slot e apenas um item de peito é equipado por vez.

## Leitura em 48 px

- Presilha, corpo vertical claro e contorno escuro criam uma silhueta imediata de crachá.
- O selo circular grande e o check central sobrevivem como a informação dominante.
- Cabeçalho e duas linhas inferiores sugerem credencial oficial sem depender de texto minúsculo.
- Os ecos ciano/magenta têm apenas 6 px de deslocamento lógico; na redução, viram franjas controladas e não duplicam a marca por inteiro.
- O thumbnail é recentrado em `(385, 535)` e ampliado para `4.2×`, preservando presilha, selo, glow e margens no recorte.

## Efeito animado recomendado

Aplicar um único desvio horizontal curto nas duas faixas de canal: `0 → 6 px → -4 px → 0`, em cerca de 180 ms, somente ao equipar ou homologar o item. As franjas do check podem separar ciano e magenta por no máximo 2 px de tela e recompor imediatamente; o check branco permanece fixo no centro durante todo o efeito. O halo do selo pode respirar entre 20% e 24% de opacidade em 1,6 s. Em movimento reduzido, manter os deslocamentos estáticos já desenhados e remover qualquer pulso.

## Critérios de verificação

- [ ] Em tamanho de cena, o item é reconhecido como crachá/selo de homologação preso à camiseta, não como tile, janela ou quadrado abstrato.
- [ ] Presilha, ponte e cartão formam uma conexão física contínua com o peito.
- [ ] A marca de aprovação permanece completa, centralizada e legível com ou sem as camadas de accent/glow.
- [ ] Nenhuma camada, incluindo glow e faixas deslocadas, cobre as chamadas `SIX`/`SEVEN`.
- [ ] O item permanece dentro da faixa aproximada `x=315–455`, `y=445–624` nas poses Six, Seven e neutra.
- [ ] Em 48 px, ainda são distinguíveis a presilha, o cartão, o selo circular e o check.
- [ ] Em escala de cinza, cartão, moldura, selo e check mantêm contraste suficiente.
- [ ] O glitch aparece como deslocamento controlado de canais em áreas limitadas, sem jitter contínuo da silhueta inteira.
- [ ] A variante `base` já comunica crachá e aprovação; `accent` acrescenta as franjas de canal, e `glow` apenas reforça o selo.
- [ ] A variante `reduced` preserva presilha, cartão e check sem depender de animação.
- [ ] O thumbnail mantém o crachá inteiro e não corta a presilha nem o halo externo.
