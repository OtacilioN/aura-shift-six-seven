# ITEM-B-02 — Sapato de Lag

## Conceito

Par completo de tênis de cano curto vestido sobre os pés do Mascote. Cada calçado tem silhueta opaca orientada para fora, abertura do cano, língua, painel lateral, biqueira, cadarços e sola clara. As massas principais ficam em torno de `(438, 838)` e `(586, 838)`, substituindo visualmente os calçados originais sem parecer dois módulos presos aos tornozelos.

## Colocação

O item permanece no slot canônico `ANKLES`, com `side=both`, subslot genérico `ANKLES_PAIR` e offset reduzido para `(0.00, 0.01)`. O calcanhar de cada tênis se sobrepõe ao pé correspondente, enquanto as biqueiras apontam para as laterais e se afastam do eixo central. O contorno escuro e os preenchimentos opacos escondem a forma-base na área calçada; nenhuma chave ou slot específico novo é necessário.

## Leitura em 48 px

- A silhueta de cada tênis reúne cano, biqueira externa e sola contínua.
- Aberturas escuras e línguas magenta separam claramente o calçado do tornozelo.
- Três cadarços grossos por pé sobrevivem à redução sem virar ruído.
- A sola clara cria uma base inequívoca de sapato, em vez da antiga leitura de caixa.
- O thumbnail foi recentrado em `(512, 850)` e ampliado para `1.75×`, enquadrando o par inteiro e os ecos curtos.

## Efeito animado recomendado

Usar apenas os arcos parciais atrás das biqueiras e os pequenos ecos de sola como afterimages atrasados por poucos quadros. Eles podem aparecer em sequência curta e desaparecer antes do próximo Ciclo, sem deslocar os tênis, sugerir ganho de velocidade ou formar uma segunda silhueta completa. Em movimento reduzido, manter tênis, cadarços e acabamento estáticos e omitir a alternância dos ecos.

## Critérios de verificação

- [ ] Os centros visuais permanecem próximos de `(438, 838)` e `(586, 838)` no palco lógico.
- [ ] O par fica exatamente sobre os pés e funciona como troca visual dos calçados originais.
- [ ] Cada pé é reconhecido como tênis completo por silhueta, cano, língua, biqueira, cadarços e sola.
- [ ] Nenhuma forma principal é retangular ou pode ser confundida com caixa/módulo de tornozelo.
- [ ] As biqueiras apontam para fora e os calcanhares continuam alinhados aos pés do Mascote.
- [ ] O lag é comunicado por contornos parciais e curtos, nunca por uma segunda cópia completa do par.
- [ ] Em 48 px, os dois tênis, as solas e ao menos duas faixas de cadarço por pé continuam distinguíveis.
- [ ] A variante `base` comunica o par de tênis sem depender de `accent` ou `glow`.
- [ ] A variante `reduced` mantém toda a estrutura do calçado sem depender de animação.
