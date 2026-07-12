# Aura Shift: Six Seven — Cadência e Plano de Balanceamento

> Status: marcos, perfis, curvas, parâmetros e tolerâncias `balance-gate-v1` aprovados; resultados ainda serão simulados.

## Objetivo

Entregar recompensas cedo o suficiente para ensinar o ciclo e demonstrar crescimento, sem esgotar imediatamente a Loja ou tornar a Produção Passiva irrelevante.

## Marcos aprovados

| Marco | Tempo pretendido |
| --- | ---: |
| Primeira Técnica Six-Seven adquirida | ~30 segundos |
| Primeiro Item de Aura adquirido | ~2 minutos |
| Primeira Transformação de Aura | ~5 minutos |
| Saída natural da primeira sessão | 8–12 minutos |
| Primeira Ascensão — jogador muito ativo | 2–3 dias |
| Primeira Ascensão — jogador casual | 5–7 dias |

“Adquirido” significa conseguir pagar e concluir a compra por progressão normal, sem depender de Anúncio Recompensado. Os tempos são alvos de experiência e podem variar conforme a cadência do jogador.

## Estado esperado ao fim da primeira sessão

- o Ciclo Six-Seven já foi compreendido;
- ao menos uma Técnica Six-Seven e um Item de Aura foram adquiridos;
- a primeira Transformação de Aura foi vista;
- a Produção Passiva está ativa;
- um novo Item, Técnica, marco visual ou Patamar de Aura aparece como objetivo próximo;
- anúncios não foram necessários para entender ou sustentar a progressão.

O Tutorial Contextual termina após o primeiro Item e não força compras. As simulações devem verificar que um jogador que ignora os destaques continua capaz de progredir e reencontrar as orientações.

## Caminho-base calculado

Na Cadência de Referência, a Potência de Ciclo inicial de `1` produz as `45 Aura` necessárias para `TECH-01` em 30 segundos. Seu primeiro nível eleva a potência para `2`, ou `3 Aura/s`. Guardar por mais 90 segundos paga qualquer um dos três Itens-raiz de `270 Aura` aos dois minutos.

O Item-raiz produz `0,75 Aura/s`, estabelecendo a relação ativa/passiva `3 ÷ 0,75 = 4`. Nesse momento a Aura Total acumulada é `315`. A produção aberta combinada de `3,75 Aura/s` alcança o marco de `1.000 Aura Total` de `FORM-01` aproximadamente em `5min02,7s` desde o início da interação econômica.

Esse caminho é a referência, não uma sequência obrigatória. Compra de níveis adicionais, escolha de outro ritmo, pausa e retorno precisam ser avaliados como cenários alternativos.

## Escada de magnitude

Os cinco Patamares e Transformações usam `1K`, `1M`, `1B`, `1T` e `1Qa` de Aura Total. Os itens de profundidade `02`, `03`, `04` e `05` abrem seus Patamares em `1K`, `1M`, `1B` e `1T`; as Convergências usam `1K`, `1B` e `1Qa`. A primeira Ascensão fica disponível em `1Qa`.

Cada estágio é aproximadamente mil vezes o anterior. As entradas econômicas de cada fase devem criar crescimento suficiente para que esses saltos pareçam expansão de poder, não espera passiva. A simulação precisa preservar a chegada a `1Qa` em 2–3 dias ativos ou 5–7 dias casuais.

## Janelas de Patamar

As metas abaixo medem tempo de calendário desde a primeira abertura no cenário-base sem anúncios:

| Patamar | Muito ativo | Referência | Casual |
| --- | ---: | ---: | ---: |
| `1K` | `5–7min` | `5–7min` | `5–8min` |
| `1M` | `20–30min` | `6–10h` | `10–14h` |
| `1B` | `6–12h` | `24–36h` | `36–60h` |
| `1T` | `24–36h` | `72–96h` | `84–120h` |
| `1Qa` | `48–72h` | `96–120h` | `120–168h` |

O perfil Passivo não possui prazo obrigatório, mas precisa manter crescimento monotônico e uma próxima compra alcançável. Cada relatório também apresenta tempo em sessão e tempo de interação ativa, impedindo que uma métrica substitua outra.

As janelas são critérios de aceite. Elas não aparecem como promessas, cooldowns ou bloqueios. O uso de anúncios pertence às análises de sensibilidade e não pode ser necessário para aprovar o baseline.

## Heurística-base de compra

A simulação escolhe o próximo nível com maior Retorno Projetado de 24 Horas. O ganho marginal usa a agenda do perfil, incluindo ciclos previstos, produção aberta, offline creditável e saltos de Marco de Nível. Se a melhor candidata ainda não for pagável, o perfil guarda Aura.

Especialista, Dual e Ampla limitam quais ramos podem entrar no conjunto de candidatas. Empates de até 1% avançam primeiro o próximo Pré-requisito ou Marco, depois a entrada de menor nível e então o ID estável.

Duas sensibilidades adicionais usam “Mais barata” e “Caçadora de meta”. A segunda minimiza a ETA até o próximo Marco de Nível ou Pré-requisito relevante, usando custo cumulativo e produção vigente sem antecipar ganhos intermediários. O balanceamento precisa observar as três, pois eficiência perfeita não representa todos os jogadores.

## Perfis de simulação

| Perfil | Sessões/dia | Duração/sessão | Ciclos/s | Toques/s | Tempo ativo/dia |
| --- | ---: | ---: | ---: | ---: | ---: |
| Muito ativo | 4 | 30 min | 3 | 6 | 120 min |
| Referência | 3 | 15 min | 1,5 | 3 | 45 min |
| Casual | 2 | 10 min | 0,75 | 1,5 | 20 min |
| Passivo | 2 aberturas | `60s` depois do Bootstrap | 0 depois do Bootstrap | 0 | `2 min` em dia regular; Bootstrap adiciona tempo variável |

As sessões são distribuídas uniformemente em 24 horas. Muito ativo e Referência permanecem dentro do limite offline entre sessões; o Casual possui intervalos exatos de 12 horas, dos quais somente oito são creditados por ausência. O perfil Passivo também abre a cada 12 horas, conclui o onboarding em Cadência de Referência até adquirir um Item-raiz e repete esse Bootstrap de Jornada depois de cada Ascensão; fora dele, depende exclusivamente da produção passiva.

A abertura de Bootstrap pode ultrapassar `60s` somente até `TECH-01` L1 e um Item-raiz L1. Isso corrige a estagnação pós-Ascensão do cenário matemático e não implica autoclick, compra automática ou tratamento especial no jogo real.

Os marcos iniciais usam Cadência de Referência para todos os perfis. Depois do onboarding, cada agenda assume sua própria cadência. Esses cenários não representam cap, combo, dificuldade nem classificação de jogadores reais.

O cenário-base não usa anúncios. Bônus de Retorno e Complementos são adicionados somente em análises de sensibilidade, impedindo que a progressão planejada dependa de monetização.

Um limite de oito toques em qualquer janela móvel de um segundo restringe a entrada a quatro Ciclos/s, ainda acima do perfil máximo de `3 ciclos/s`. O jogo não é calibrado para depender do teto nem tenta detectar autoclickers abaixo dele.

## Relação entre produção ativa e passiva

Os alvos abaixo consideram a Cadência de Referência e investimento aproximadamente equilibrado:

| Estágio | Produção Ativa ÷ Produção Passiva |
| --- | ---: |
| âncora da primeira sessão | `4×` exatos |
| cruzamento de `1B` no Referência-Ampla | `1,5×–2,5×` |
| `0,9Qa` no Referência-Ampla | `0,75×–1,25×` |

Ambas as fontes continuam ativas simultaneamente. Portanto, em paridade, tocar dobra a produção total em relação a apenas esperar. Escolhas de ramos podem favorecer um estilo, mas as simulações devem impedir que uma das duas famílias deixe de ter valor.

## Produção Offline

A ausência usa a Produção Passiva final registrada na saída, já modificada pela Ascensão, multiplicada pelo tempo válido de até oito horas. Não há simulação de progressão ou composição durante o período. Perfis de retorno devem validar ausências curtas, oito horas, períodos superiores ao limite e alterações incoerentes de relógio.

## Acúmulo de Ascensão

O multiplicador começa em `1×` e é derivado da Aura sacrificada acumulada `L`: `A(L)=100+floor(√(L÷10¹¹))` em centésimos. Cada jornada exige ao menos `1Qa` e acrescenta toda a Aura da Jornada a `L`. A primeira Ascensão mínima leva o total a `2×`; quatro Ascensões mínimas e uma jornada de `4Qa` resultam igualmente em `3×`, removendo o bônus oculto por resetar com mais frequência.

As simulações devem comparar Ascender imediatamente em `1Qa` com esperar `2Qa`, `4Qa` e `9Qa`, medindo tempo de reconstrução, ganho por hora e risco de uma estratégia dominar todas as demais.

O baseline usa Ascensão imediata em `1Qa`. Cada política é executada até concluir pelo menos três Ascensões e observar a terceira Reconstrução na quarta jornada. Essa regra não é exibida nem aplicada automaticamente ao jogador.

## Estrutura das curvas

O preço do próximo nível cresce pela razão universal exata `23/20`. A produção cresce de forma aditiva por nível e recebe saltos em Marcos de Nível predeterminados. Técnicas compõem a Potência de Ciclo e Itens compõem a Produção Passiva; a Ascensão multiplica cada soma uma única vez.

Todas as entradas duplicam cumulativamente sua própria contribuição nos níveis `10`, `25`, `50`, `100` e depois a cada `100` níveis. As simulações devem verificar especialmente as janelas imediatamente anteriores e posteriores a esses saltos para evitar espera morta, compra dominante ou aceleração incompatível com a Ascensão.

As simulações devem avaliar o retorno marginal antes, no momento e depois de cada Marco de Nível, além de compras `×1`, `×10` e `MÁX`. Nenhum lote pode usar aproximação que cobre valor diferente da soma dos níveis individuais.

## Processo de balanceamento

1. carregar os Perfis de Simulação e frequências de retorno aprovados;
2. carregar as âncoras ativas e passivas já confirmadas;
3. carregar todos os custos e contribuições versionados em `balance-v0.2`;
4. simular cada perfil por minutos, horas e dias;
5. procurar esperas mortas, crescimento explosivo e caminhos dominantes;
6. revisar com agentes independentes de economia e UX;
7. ajustar parâmetros sem alterar as regras canônicas;
8. repetir após qualquer mudança relevante de catálogo ou Ascensão.

As simulações da Árvore de Aura devem cobrir pelo menos três estratégias:

- **especialista:** concentra compras em um único ramo e ignora Convergências;
- **dual:** divide investimento entre dois ramos;
- **ampla:** investe nos três ramos e busca todas as Convergências.

Nenhuma delas pode ser uma armadilha irreversível. A rota ampla pode ter ganhos exclusivos dos Itens de Convergência, mas não pode ser o único caminho para novos Patamares ou Ascensão.

Especialista A, B e C formam um teste de invariância: com perfil e compras equivalentes, seus tempos, produção e níveis precisam coincidir exatamente. A comparação estratégica relevante é especialização versus divisão ou amplitude, não A versus B versus C.

### Orçamentos de Gate do `balance-v0.2`

O balanceamento ancora os custos-base espelhados por profundidade em `270`, `2.350`, `67.000`, `67.000` e `67.000.000.000 Aura`. Com a curva `23/20`, elevar o predecessor aos níveis `10`, `25`, `50` e `100` custa, respectivamente, `5.487`, `500.078`, `483.587.018` e `524.526.228.030 Aura`.

Esses valores aproximam o investimento do caminho aos Patamares seguintes sem substituir os limiares de Aura Total. A igualdade entre os custos-base das profundidades `03` e `04` é compensada pelo gate muito mais longo. O preço `99→100` do quarto item é `68.416.522.780`; o custo-base de `67 bilhões` do quinto item cria o handoff econômico tardio.

As contribuições-base espelhadas, expressas em `Aura/s por nível`, são `0,75`, `6,7`, `67`, `6.700` e `67.000.000`. Nos quatro gates de continuação, os Marcos elevam a contribuição de uma entrada para `15 Aura/s`, `670 Aura/s`, `26.800 Aura/s` e `10.720.000 Aura/s`. O salto da profundidade `05` é a hipótese mais sensível e deve ser testado especificamente contra a duração de `1T→1Qa`.

As Técnicas usam custos-base de `45`, `67`, `67K`, `67M`, `67B` e `67T Aura`. Depois de `TECH-01`, cada entrada custa `6,7%` do Patamar que a desbloqueia. A simulação deve verificar tanto a compra próxima ao primeiro desbloqueio quanto a recompra em jornadas posteriores, quando o desbloqueio já é permanente mas o nível voltou a zero.

Suas Contribuições-base são `1`, `5`, `5K`, `5M`, `5B` e `5T Aura/ciclo por nível`. De `TECH-02` em diante, custo e ganho crescem juntos em `1.000×`, mantendo `Contribuição-base ÷ custo-base = 5/67`. A redução de aproximadamente `25,37%` em `balance-v0.2` deve ser medida contra a utilidade passiva e as Janelas de Patamar.

As três Convergências custam `6.700`, `26,8M` e `670T Aura` e acrescentam `7,5`, `3.350` e `13,4B Aura/s` por nível. Em L1, cada uma entrega somente `1/6` da produção dos três nós exigidos, depois de um custo equivalente a aproximadamente `40–61%` do Orçamento de Amplitude já investido. A rota ampla recebe uma recompensa real, mas não gratuita nem necessária para Ascender.

## Validações pendentes

- confirmar a distribuição econômica resultante entre os Patamares aprovados;
- confirmar que os parâmetros cumprem as Janelas de Patamar em toda a matriz.

As duas validações usam o gate binário e o relatório definidos em `BALANCE-ACCEPTANCE-CRITERIA.md`; nenhuma média ou aceleração publicitária pode compensar uma falha.
