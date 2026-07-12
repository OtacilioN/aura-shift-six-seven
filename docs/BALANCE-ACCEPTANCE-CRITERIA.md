# Aura Shift: Six Seven — Critérios de Aceitação do Balanceamento

> Status: gate `balance-gate-v1` aprovado para validar `balance-v0.2` com `arith-v1`.

## Regra de decisão

O gate é binário. Não existe média, nota geral ou compensação entre critérios obrigatórios: qualquer falha reprova a versão de balanceamento testada. O relatório pode recomendar novos parâmetros, mas não pode sobrescrever `balance-v0.2` sem criar uma versão identificada e repetir toda a matriz.

Antes do balanceamento, o simulador precisa passar todas as fixtures e provas de particionamento de `ECONOMIC-ARITHMETIC.md`. Divergência determinística reprova o simulador, não os parâmetros.

## Definições de medição

- **Evento Econômico Relevante:** compra, Marco de Nível, desbloqueio, Transformação, Convergência ou Ascensão que altere produção, acesso ou apresentação de progresso.
- **Compra útil:** próximo nível selecionado pela heurística declarada, já desbloqueado e capaz de aumentar produção ou avançar um requisito. Sua espera começa quando ele se torna a candidata vigente, acumula tempo aberto entre sessões e termina na compra ou quando uma mutação econômica seleciona outra candidata.
- **Compra dominante:** entrada que concentra parcela desproporcional da Aura gasta entre dois checkpoints canônicos, sejam Patamares da primeira jornada ou marcos de Aura da Jornada após Ascensão.
- **Cadeia de Reconstrução:** para cada ramo elegível, o item mais profundo possuído antes do reset e o conjunto mínimo de ancestrais e níveis exigidos para readquiri-lo; na Ampla, inclui cada Convergência possuída e seus requisitos. Técnicas não pertencem à cadeia estrutural.
- **Reconstrução Econômica:** primeiro timestamp após o commit da Ascensão em que a Cadeia de Reconstrução foi readquirida e Potência de Ciclo e Produção Passiva igualam ou superam, separadamente, os valores imediatamente anteriores ao reset.
- **Aceleração publicitária:** `1 − tempo_com_anúncio ÷ tempo_baseline` para o mesmo checkpoint, perfil, estratégia e heurística.
- **Relação ativa/passiva:** Produção Ativa instantânea na Cadência de Referência dividida pela Produção Passiva instantânea, usando o estado econômico do checkpoint.
- **Tempo contrafactual de Convergência:** `t_habilitada` ou `t_desabilitada` é o tempo de calendário desde o mesmo estado inicial até o checkpoint do par, com a Convergência indicada disponível ou com somente ela desabilitada; não se confunde com a taxa `T20`.

## Perfil Passivo e Bootstrap de Jornada

O perfil Passivo realiza duas Aberturas Curtas de `60s` por dia, espaçadas em exatamente `12h`. Ele executa zero Ciclos depois do Bootstrap de Jornada.

O Bootstrap ocorre no início da primeira jornada e novamente depois de cada Ascensão. Durante ele, o perfil usa a Cadência de Referência somente até comprar `TECH-01` no nível `1` e um Item-raiz no nível `1`. A abertura pode ultrapassar `60s` apenas até concluir esse mínimo; depois disso, as aberturas seguintes voltam a `60s` e zero Ciclos.

Essa regra existe somente no Perfil de Simulação. O produto não automatiza Ciclos, compras ou reconstrução para jogadores reais.

Em cada Abertura Curta, a ordem metodológica é:

1. reconciliar save e relógio;
2. materializar e creditar a Produção Offline base;
3. aplicar o Bônus de Retorno se o cenário publicitário o determinar;
4. processar Patamares e apresentações econômicas sem alterar o estado calculado;
5. executar a Política de Ascensão antes de compras quando seu limiar já tiver sido alcançado;
6. realizar o Bootstrap se a Ascensão acabou de reiniciar a economia;
7. avaliar compras pela heurística declarada durante o tempo aberto restante;
8. integrar o trecho final e registrar a nova Taxa Offline.

No baseline que Ascende em `1Qa`, `TECH-06` é desbloqueada ao cruzar o Patamar, mas não é comprada antes da Ascensão imediata. Ela permanece desbloqueada e passa a ser candidata nas jornadas seguintes. Políticas que esperam podem comprá-la normalmente.

## Critérios obrigatórios

| Área | Critério de aprovação |
| --- | --- |
| Reprodutibilidade | Repetições com mesmo cenário e partições temporais diferentes produzem diferença absoluta `0` em contadores, níveis, compras, saldos, restos, desbloqueios e limiares. Agrupamento visual e timestamps de telemetria não integram a comparação. |
| Janelas de Patamar | No Baseline sem anúncios e com a heurística de Retorno Projetado de 24 Horas, todas as combinações dos perfis Muito ativo, Referência e Casual com estratégias Especialista, Dual e Ampla ficam integralmente nas Janelas oficiais. |
| Invariância de ramos | Especialistas A/B/C e duais AB/AC/BC, depois de normalizar IDs, possuem diferença absoluta `0` em todas as saídas econômicas. |
| Dispersão estratégica | Para o mesmo perfil, em `1M`, `1B`, `1T` e `1Qa`, `maior tempo ÷ menor tempo ≤ 1,25` entre Especialista, Dual e Ampla. |
| Ausência de dominância | Na primeira jornada, comparar `1M/1B/1T/1Qa`; depois de cada Ascensão, comparar Reconstrução e Aura da Jornada em `1M/1B/1T/limiar da política`. Nenhuma estratégia pode ser igual ou melhor em tempo, Potência e produção passiva em todos os checkpoints, com ao menos uma vantagem estrita. |
| Ativa/passiva inicial | Depois de `TECH-01` L1 e um Item-raiz L1, a relação na Cadência de Referência é exatamente `4×`. |
| Ativa/passiva intermediária | Na primeira jornada do perfil Referência-Ampla, ao cruzar `1B`, a relação fica entre `1,5×` e `2,5×`. |
| Ativa/passiva tardia | Na primeira jornada do perfil Referência-Ampla, em `0,9Qa` de Aura da Jornada, a relação fica entre `0,75×` e `1,25×`. |
| Convergências | Nos três perfis ativos, para cada `CONV-n`, comparar pares Ampla idênticos com a entrada habilitada e com somente ela desabilitada. A razão `t_habilitada ÷ t_desabilitada` fica em `[0,80;1,30]` até `1M` para `CONV-01`, `1T` para `CONV-02` e Ascensão em `4Qa` para `CONV-03`. Se qualquer par não alcançar o checkpoint em `30d`, o critério falha. Em todo Ponto decisório canônico no qual a Convergência esteja elegível até esse checkpoint, seu Retorno Projetado do nível atual ao próximo Marco sobre custo cumulativo não excede `1,25×` a melhor entrada comum elegível no mesmo timestamp; vale a maior razão observada. |
| Baseline publicitário | Toda a matriz passa sem anúncios. Anúncios nunca corrigem uma falha do Baseline. |
| Aceleração por Retorno | O cenário apenas com Bônus de Retorno reduz o tempo de qualquer checkpoint em no máximo `20%`. |
| Aceleração por Complemento | O cenário apenas com Complemento reduz o tempo em no máximo `25%`. |
| Aceleração máxima | O cenário voluntário combinado reduz o tempo em no máximo `35%`. |
| Neutralidade do Complemento | Complemento altera Aura Total e Aura da Jornada em exatamente `0`, não atravessa gates e nunca deixa o cenário mais lento que o Baseline equivalente. |
| Progresso Passivo | Depois do Bootstrap, todo retorno com taxa positiva aumenta Aura Total e nenhuma Ascensão cria estagnação permanente. |
| Cadência Passiva | O Passivo encontra ao menos um Evento Econômico Relevante em qualquer sequência de três Aberturas Curtas consecutivas. |
| Concentração de gasto | Na primeira jornada, medir entre Patamares; depois, entre checkpoints de Aura da Jornada `0→1M→1B→1T→limiar da política`. Nenhum ID não obrigatório absorve mais de `70%`; o predecessor direto pode chegar a `85%`. |
| Utilidade do catálogo | Com parâmetros nominais e sem anúncios, cada entrada econômica é comprada em ao menos uma execução até o fim da terceira Ascensão. No baseline `1Qa`, `TECH-06` aparece depois da primeira Ascensão; políticas de espera podem comprá-la na primeira jornada. `ITEM-CONV-03` usa a política `4Qa`. |
| Espera inicial | Na primeira sessão não existem mais de `120s` entre Eventos Econômicos Relevantes. |
| Espera aberta | Depois da primeira sessão, o p95 do tempo aberto acumulado entre sessões para a mesma Compra útil não excede uma duração de sessão do perfil; fechar o app não reinicia a medição. |
| Espera de calendário | Nenhuma compra útil exige mais de dois intervalos de retorno programados sem outro Evento Econômico Relevante. |
| Primeira reconstrução | A primeira Reconstrução Econômica leva no máximo `25%` do tempo da jornada pré-reset. |
| Reconstruções seguintes | Cada Reconstrução Econômica posterior leva no máximo `90%` do tempo da reconstrução anterior. |
| Reentrada pós-Ascensão | A primeira compra útil de cada nova jornada ocorre em até `2min` de tempo aberto. |
| Sensibilidades de compra | Nos três perfis ativos, “Mais barata” e “Caçadora de meta” ficam entre `0,8×` o limite inferior e `1,25×` o limite superior das Janelas e não levam mais de `30%` além do Baseline até `1Qa`. O Passivo usa somente seus critérios de cadência e liveness. |
| Robustez paramétrica | Cada custo-base e Contribuição-base é perturbado individualmente em aproximadamente `±10%`, quantizado pela regra válida de `arith-v1` e mantendo A/B/C espelhados. Cada perturbação cruza `3 perfis ativos × 3 estratégias`, sempre contra o nominal correspondente; não muda nenhum tempo de Patamar em mais de `20%`, não estagna e não cria nova dominância. |
| Políticas de Ascensão | Em horizontes de `7` e `30` dias, para cada perfil ativo, a razão entre melhor e pior Aura por hora de calendário entre `1Qa/2Qa/4Qa/9Qa` não excede `1,50`. Nenhuma política supera todas as outras em mais de `20%` nos dois horizontes e em todos os perfis ativos. |
| Saída aos 10 minutos | Muito ativo, Referência e Casual concluíram `TECH-01` L1, adquiriram um Item-raiz, cruzaram `1K`, receberam `FORM-01` e possuem próximo objetivo visível. O Passivo concluiu o Bootstrap e possui próximo objetivo visível, sem obrigação de cruzar `1K`. |

## Diagnósticos obrigatórios sem janela oficial

O perfil Passivo continua sem Janela de Patamar obrigatória. Mesmo assim, o relatório mede seu tempo até `1Qa`; ultrapassar `30 dias` gera alerta e revisão humana/agêntica, mas não reprova isoladamente a versão. Também são diagnósticos:

- adoção de cada Convergência;
- percentual de jornadas que compram `TECH-06`;
- tempo e Aura sacrificados ao esperar `ITEM-CONV-03` em vez de Ascender;
- distribuição de gasto por entrada;
- distância de cada compra até o Marco de Nível seguinte;
- quantidade de Complementos usada por entrada e magnitude.

## Perturbação válida de parâmetros

Stress tests nunca criam um parâmetro inválido. Para numerador `p=9` ou `11`:

- custo-base perturbado: `C₀' = max(1, floor((p × C₀ + 5) ÷ 10))` Aura;
- contribuição perturbada: `B20' = max(1, floor((p × B20 + 5) ÷ 10))` vigésimos na unidade aplicável.

O relatório registra a variação efetiva depois da quantização. O espelho A/B/C inteiro é perturbado como uma unidade; entradas individuais de um mesmo trio nunca recebem arredondamentos diferentes.

## Matriz em camadas

As dimensões não formam um produto cartesiano indiscriminado. Cada versão executa:

1. **Núcleo nominal:** quatro Perfis × Especialista A × Dual AB × Ampla, heurística-base, sem anúncios, Ascensão `1Qa`, até concluir três Ascensões e observar a terceira Reconstrução na quarta jornada.
2. **Prova de simetria:** Especialistas A/B/C e duais AB/AC/BC nos checkpoints canônicos, permitindo deduplicação posterior somente após diferença absoluta zero.
3. **Sensibilidade de compra:** Mais barata e Caçadora de meta sobre o núcleo ativo, mantendo anúncios desligados e Ascensão `1Qa`.
4. **Sensibilidade publicitária:** Retorno, Complemento e Máximo voluntário sobre a heurística-base e Ascensão `1Qa`.
5. **Sensibilidade de Ascensão:** `2Qa`, `4Qa` e `9Qa` sobre heurística-base sem anúncios.
6. **Robustez:** cada perturbação válida, uma por vez, no cruzamento completo `3 perfis ativos × 3 estratégias`, comparada às nove execuções nominais correspondentes.
7. **Contrafactual de Convergência:** nos três perfis ativos, pares Ampla nominais, sem anúncios e com heurística-base, habilitando ou desabilitando somente `CONV-01`, `CONV-02` ou `CONV-03`; a terceira usa Ascensão `4Qa`, e o ROI relativo é amostrado em todos os Pontos decisórios canônicos elegíveis até o checkpoint.
8. **Fixtures ortogonais:** equivalência de `×1`, `×10` e `MÁX`, limites offline e anúncios, sem tratá-los como comportamento adicional do jogador.
9. **Particionamento:** passos de `1.000ms`, `100ms` e ao menos `32` sequências pseudoaleatórias cujas listas ordenadas de intervalos são publicadas integralmente no relatório; uma seed sem a sequência não é evidência suficiente.

O relatório lista a camada de cada execução. Combinações extras são permitidas para investigar uma falha, mas não escondem nem substituem a matriz mínima.

## Relatório obrigatório

Cada relatório registra:

- versões `balance`, `arith` e `balance-gate`;
- conjunto completo de parâmetros ou hash reproduzível;
- Perfil, estratégia, heurística, anúncios e Política de Ascensão;
- checkpoints de Patamar, `7 dias`, `30 dias` e três Ascensões;
- linha do tempo de compras, níveis, anúncios, retornos e reset;
- Aura Disponível, Total, da Jornada e Resto de Produção;
- Potência de Ciclo, Produção Passiva e relação ativa/passiva;
- espera aberta e de calendário;
- concentração de gasto, itens nunca comprados e Convergências;
- resultados nominal, sensibilidades e perturbações;
- tabela binária de cada critério com evidência da aprovação ou falha.

O relatório termina em `APROVADO` somente quando todos os critérios obrigatórios passam. Caso contrário, termina em `REPROVADO`, preserva os resultados e propõe a próxima versão sem alterar os dados da execução.
