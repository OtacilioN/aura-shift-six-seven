# ITEM-CONV-01 — Nó de Reunião

## Conceito

Três participantes distintos enviam rotas coloridas para um mesmo encontro. As fitas violeta, ciano e dourada não fecham um perímetro: elas avançam de três direções, curvam-se uma dentro da outra e alternam passagens por cima e por baixo no centro, formando um nó compacto e reconhecível. Cada origem possui um marcador circular com cabeça e ombros, deixando explícito que a Convergência representa pessoas reunidas, não um triângulo abstrato.

## Colocação

O item permanece em `AURA_BACK`, no `SLOT-AURA-BACK`, com `side=center` e subslot `AURA_BACK_CENTER`. O offset passa a `(0.00, -0.02)` para equilibrar os dois participantes superiores e manter o marcador inferior junto à base da aura. Os marcadores ficam aproximadamente em `(160, 270)`, `(864, 270)` e `(512, 872)`; as rotas ocupam o espaço radial atrás do rig e deixam grandes intervalos transparentes. A oclusão do Mascote acontece naturalmente pela camada traseira: fitas e nó podem aparecer ao redor da silhueta, mas nunca são desenhados sobre rosto, mãos ou corpo.

## Leitura em 48 px

- Três discos periféricos grandes sobrevivem como marcadores de participantes, cada um associado à cor de sua rota.
- As três fitas têm contorno escuro e largura suficiente para permanecerem separadas da aura e do fundo.
- O miolo usa trechos redesenhados com contorno próprio para preservar a alternância por cima/por baixo mesmo na redução.
- A ausência de arestas fechando os três marcadores impede a leitura de triângulo vazio.
- O thumbnail usa centro `(512, 535)` e escala `0.84x`, enquadrando os três participantes, todas as entradas e o nó sem cortar os glows locais.

## Efeito animado recomendado

Enviar um único pulso curto de cada marcador em direção ao centro, com partidas levemente defasadas e encontro simultâneo no nó. Ao se encontrarem, as três fitas podem ganhar um brilho local breve nos cruzamentos, sem girar, trocar de posição ou formar halo contínuo. Em movimento reduzido, manter rotas e marcadores totalmente estáticos e usar somente uma mudança discreta de opacidade no miolo.

## Critérios de verificação

- [ ] Existem exatamente três marcadores de participantes, cada um com cabeça, ombros e cor própria.
- [ ] Existem exatamente três rotas principais — violeta, ciano e dourada — ligando os participantes ao encontro central.
- [ ] As rotas alternam visualmente passagens por cima e por baixo no centro e são percebidas como fitas entrelaçadas.
- [ ] Nenhuma linha fecha um triângulo entre os três marcadores; o espaço exterior permanece aberto.
- [ ] Em tamanho de cena e em 48 px, a leitura primária é de três participantes reunidos em um nó, não de moldura triangular.
- [ ] O manifesto mantém `slot: AURA_BACK`, `zLayer: SLOT-AURA-BACK`, `side: center` e `subslot: AURA_BACK_CENTER`.
- [ ] O item permanece atrás do Mascote e não cobre sua silhueta, rosto, mãos ou corpo.
- [ ] A variante `base` já comunica três participantes e três rotas; `accent` explicita a trama e `glow` apenas reforça fluxo.
- [ ] O thumbnail enquadra os três marcadores e o nó completo, sem cortar os glows periféricos.
- [ ] Em movimento reduzido, todos os sinais essenciais permanecem estáticos, legíveis e independentes de cor animada.
