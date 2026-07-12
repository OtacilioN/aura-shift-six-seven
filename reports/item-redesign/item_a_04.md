# ITEM-A-04 — Casaco de Gate

## Conceito

Jaqueta curta e aberta, vestida sobre o torso do mascote. Dois painéis escuros separados formam a abertura central; lapelas largas em tom intermediário, trilhos de zíper bipartidos, puxador circular e dois bolsos geométricos deixam a peça reconhecível como casaco mesmo sem animação. O ciano e o azul do ramo A aparecem como acabamento de lapela, dentes do zíper, costuras e brilho, sem substituir a silhueta da roupa.

## Colocação

O item passa de `BODY_BACK` para o slot frontal `BODY_WEAR`, ancorado em `BODY_WEAR_CENTER`. A peça ocupa aproximadamente `x=350–675`, `y=438–825` no palco lógico de 1024 px: começa abaixo da maior parte do rosto, acompanha o volume central do corpo e termina antes dos pés. Os painéis laterais ficam estreitos junto às zonas das mãos, e a camada `SLOT-BODY-WEAR` deve ser composta sobre o corpo e sob `CHR-HANDS`, preservando os gestos Six, Seven e neutro.

## Leitura em 48 px

- A abertura vertical separa os dois painéis e evita a leitura de capa ou cauda flutuante.
- As lapelas claras criam um V largo e reconhecível na parte superior.
- Os dois bolsos têm massas fechadas e aberturas diagonais espessas, legíveis sem detalhes finos.
- Os trilhos paralelos e o puxador circular comunicam zíper aberto; os dentes ampliados sobrevivem à redução.
- O thumbnail foi recentrado em `(512, 630)` e ampliado para `1.65×`, enquadrando ombros, bolsos e bainha sem cortar o glow.

## Efeito animado recomendado

No nível de brilho, percorrer os dentes do zíper de cima para baixo com um pulso ciano curto, seguido por uma resposta azul discreta nas aberturas dos bolsos. O contorno dos ombros pode respirar entre 18% e 26% de opacidade em 1,6 s. Em movimento reduzido, manter painéis, lapelas, bolsos, trilhos, puxador e costuras totalmente estáticos; nenhum traço necessário à identificação depende da animação.

## Critérios de verificação

- [ ] Em tamanho de cena, o item é identificado como jaqueta/casaco aberto, não como capa traseira.
- [ ] Lapelas, zíper bipartido com puxador e dois bolsos continuam distinguíveis em 48 px.
- [ ] O rosto permanece visível e nenhum painel invade a região dos olhos ou da boca.
- [ ] Nas poses Six, Seven e neutra, `CHR-HANDS` permanece integralmente acima da peça e sem oclusão.
- [ ] A bainha não cobre os pés nem altera a leitura da silhueta inferior do mascote.
- [ ] Em escala de cinza, painéis, lapelas, bolsos e abertura central continuam separáveis.
- [ ] A variante `base` já comunica uma jaqueta aberta; `accent` e `glow` apenas reforçam zíper, bolsos e acabamento.
- [ ] A variante `reduced` mantém todos os elementos estruturais sem pulso, varredura ou parallax.
