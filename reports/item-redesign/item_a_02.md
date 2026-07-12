# ITEM-A-02 — Nota Fiscal do Brilho

## Conceito

Recibo térmico luminoso, alto e estreito, com papel claro, contorno escuro espesso e bordas picotadas. As linhas de compra, a faixa de cabeçalho e o selo circular com marca de conferência comunicam “nota/recibo” sem depender de texto incorporado ou de um símbolo monetário específico de região. O brilho ciano/azul preserva a identidade do ramo A.

## Colocação

O item sai do `SHOULDER` e passa para `HIP`, ancorado em `HIP_R`. A nota aparece inclinada e parcialmente encaixada no bolso direito do short; uma aba escura cobre sua parte inferior e cria a oclusão necessária para a leitura de objeto guardado. A área ocupada fica aproximadamente em `x=570–790`, `y=540–780` no palco lógico de 1024 px, distante do rosto e dos textos `SIX`/`SEVEN`. Como a posição é presa ao quadril, ela continua plausível enquanto as mãos alternam entre alta e baixa.

## Leitura em 48 px

- Silhueta vertical simples, com proporção de recibo e picote ampliado no topo.
- Papel quase branco contra contorno `ink_900`, mantendo contraste mesmo sem cor.
- Uma faixa grossa, três linhas e um selo circular sobrevivem à redução; detalhes menores foram evitados.
- O enquadramento do thumbnail foi recentrado em `(668, 654)` e ampliado para `3.1×`, deixando margem para o brilho e a estrela sem cortar o recibo.

## Efeito animado recomendado

No nível de brilho, pulsar somente o contorno ciano entre 24% e 34% de opacidade em um ciclo suave de 1,4 s. A estrela à direita pode fazer um único “twinkle” de escala `0.82 → 1.08 → 0.82`, defasado do pulso. O selo azul pode receber uma varredura curta de luz de cima para baixo. Em movimento reduzido, manter papel, linhas, selo e encaixe estáticos; nenhum detalhe necessário à identificação depende da animação.

## Critérios de verificação

- [ ] Em tamanho de cena, nenhuma parte do item cobre rosto, boné ou os textos `SIX`/`SEVEN`.
- [ ] Nas poses Six, Seven e neutra, a nota permanece visualmente encaixada no quadril direito e não parece flutuar no centro do personagem.
- [ ] O thumbnail de 48 px é identificado como recibo/nota sem consultar o nome do item.
- [ ] Em escala de cinza, papel, contorno, linhas e selo continuam separáveis.
- [ ] A variante `base` já comunica o recibo; `accent` e `glow` apenas reforçam a leitura.
- [ ] A variante `reduced` mantém picote, linhas, selo e aba do bolso sem brilho animado.
- [ ] O asset não contém texto, moeda ou marca regional incorporada.
- [ ] O glow e a estrela não ultrapassam o recorte arredondado do thumbnail.
