# Aura Shift: Six Seven — Plano de Simulação da Economia

> Status: perfis, estratégias, parâmetros, `arith-v1` e `balance-gate-v1` aprovados; execuções e resultados ainda serão produzidos.

## Objetivo

Validar custos, contribuições, Pré-requisitos, Patamares, produção offline e Ascensão sem depender de impressões isoladas. Cada resultado precisa ser reproduzível a partir de um Perfil de Simulação, uma estratégia econômica e um cenário publicitário declarados.

## Perfis comportamentais

| Perfil | Agenda diária | Cadência ativa | Regra offline |
| --- | --- | ---: | --- |
| Muito ativo | 4 sessões de 30 min, uniformes | `3 ciclos/s` | intervalos reais, máximo 8h |
| Referência | 3 sessões de 15 min, uniformes | `1,5 ciclo/s` | intervalos reais, máximo 8h |
| Casual | 2 sessões de 10 min, uniformes | `0,75 ciclo/s` | cada intervalo de `12h` limitado a 8h |
| Passivo | 2 aberturas de `60s`, exatamente 12h entre elas | `0` depois de cada Bootstrap de Jornada | cada intervalo limitado a 8h |

Todos concluem o onboarding inicial em Cadência de Referência até o primeiro Item-raiz. Depois de cada Ascensão, somente o perfil Passivo repete um Bootstrap de Jornada na mesma cadência até `TECH-01` L1 e um Item-raiz L1; a abertura pode ultrapassar `60s` apenas até concluir esse mínimo. Produção Passiva também funciona enquanto o jogo está aberto. Essa metodologia não representa automação do produto.

### Agenda racional de Ciclos

A Cadência representa Ciclos concluídos, não toques isolados. Para uma cadência racional `r = numerador/denominador` Ciclos por segundo, o Ciclo `k ≥ 1` da sessão ocorre no timestamp relativo:

`tₖ = ceil(1.000 × k × denominador ÷ numerador) ms`

Assim, `3`, `1,5` e `0,75 ciclo/s` usam, respectivamente, `3/1`, `3/2` e `3/4`. Não existe Ciclo em `t=0`; um Ciclo coincidente integra primeiro a produção passiva até `tₖ`, depois credita a Potência de Ciclo e então abre o ponto decisório de compra.

O simulador econômico emite somente Ciclos completos e não modela contatos órfãos ou reinicia a fase do produto. A persistência real de Fase Six/Fase Seven permanece uma regra separada da experiência.

## Estratégias econômicas

- **Especialista A, B ou C:** concentra investimento em um ramo e ignora Convergências.
- **Dual:** divide investimento entre dois ramos.
- **Ampla:** distribui entre os três ramos e busca Convergências.

### Heurística-base

Para cada próximo nível desbloqueado:

`pontuação = Aura adicional projetada nas próximas 24h ÷ custo exato`

- Técnicas usam o aumento de Potência de Ciclo multiplicado pelos ciclos previstos na agenda do perfil.
- Itens usam o aumento de Produção Passiva multiplicado pelos segundos abertos e offline creditáveis.
- Marcos de Nível usam a diferença completa entre contribuição anterior e posterior.
- Quando a melhor compra ainda não é pagável, o perfil guarda Aura até alcançá-la.
- Compras ocorrem somente com o jogo aberto; não há evolução automática durante ausência.

### Pontos decisórios canônicos

O robô não espera o próximo tick arbitrário. Durante uma sessão, a próxima compra ocorre no primeiro timestamp econômico exato em que Aura Disponível inteira alcança o preço da candidata vigente:

- imediatamente depois do Ciclo, milissegundo passivo, crédito de retorno ou desbloqueio que torne a compra pagável;
- na abertura, depois de créditos e Ascensão aplicáveis, compras já pagáveis são executadas sequencialmente no mesmo timestamp;
- depois de cada compra, Marco ou novo desbloqueio, a heurística é recalculada;
- empates no mesmo timestamp usam a ordem determinística já aprovada;
- durante ausência não existe ponto decisório nem compra.

Quando a produção passiva contínua completa o saldo entre checkpoints de execução, o simulador resolve matematicamente o primeiro milissegundo inteiro elegível. Assim, passos de `100ms`, `1.000ms` ou partições aleatórias produzem a mesma agenda de compras.

O conjunto candidato respeita a estratégia:

- Especialista: Técnicas e um ramo;
- Dual: Técnicas e dois ramos;
- Ampla: Técnicas, três ramos e Convergências desbloqueadas.

Quando duas pontuações diferirem no máximo 1%, o desempate prioriza o próximo Pré-requisito ou Marco de Nível, depois a entrada de menor nível e finalmente o ID estável.

### Sensibilidades de compra

Além do baseline, toda versão executa:

1. **Mais barata:** guarda e compra a entrada desbloqueada de menor custo.
2. **Caçadora de meta:** escolhe a entrada com menor ETA até seu próximo Marco de Nível ou nível de Pré-requisito relevante à estratégia. Para cada candidata, parte da Aura Disponível e do Resto de Produção `R` vigentes, congela `P20`, `T20` e `A`, calcula o custo cumulativo exato restante e integra a agenda real do perfil — Ciclos, tempo aberto e offline creditado — sem compras ou mutações intermediárias de produção. A ETA termina no primeiro timestamp de abertura em que o custo estaria pagável; produção obtida enquanto fechado só fica disponível no retorno seguinte.

ETAs iguais desempatam por alvo de Pré-requisito antes de Marco isolado, menor custo cumulativo restante, menor nível atual e ID estável, nessa ordem.

Essas sensibilidades representam decisões compreensíveis, mas não perfeitamente eficientes. Uma curva que somente funciona com a heurística-base não está pronta para aprovação.

Compras são decididas nível a nível. `×10` e `MÁX` são validados separadamente como formas de executar conjuntos de níveis pelo mesmo custo, não como heurísticas econômicas diferentes.

## Cenários publicitários

1. **Baseline:** nenhum anúncio assistido.
2. **Retorno:** todos os Bônus de Retorno elegíveis são concluídos.
3. **Complemento:** até três Complementos de Aura em janela móvel de 24 horas quando elegíveis.
4. **Máximo voluntário:** Retorno e Complemento usados dentro das regras.

Os alvos canônicos são avaliados no Baseline. Os demais cenários medem aceleração e risco de dependência, não redefinem a progressão normal.

No cenário Complemento, a oferta é usada na candidata vigente da heurística declarada assim que `70% ≤ saldo/preço < 100%`, respeitando a cotação exata, a compra `×1` e a cota móvel. Ela não troca a política de compra nem é guardada para uma entrada futura escolhida com conhecimento perfeito.

## Políticas de Ascensão

| Política | Aura da Jornada antes de Ascender |
| --- | ---: |
| baseline | `1Qa` |
| espera curta | `2Qa` |
| espera média | `4Qa` |
| espera longa | `9Qa` |

Cada política executa pelo menos três Ascensões consecutivas e registra:

- duração da jornada;
- tempo de reconstrução da Loja;
- parcela e multiplicador total;
- Aura produzida por tempo de calendário, sessão e interação;
- checkpoints de Aura da Jornada, Cadeia de Reconstrução e Convergências readquiridas;
- diferença entre benefício de esperar e eficiência de Ascender cedo.

Essas políticas são cenários matemáticos. O produto não realiza Ascensão automática nem apresenta uma delas como escolha correta.

No baseline em `1Qa`, a Política de Ascensão é processada antes das compras disponíveis naquele mesmo checkpoint. Assim, `TECH-06` é desbloqueada, mas sua primeira compra ocorre somente em uma jornada posterior. Políticas de espera podem comprá-la antes de Ascender.

## Matriz mínima

Cada versão segue as camadas ortogonais de `BALANCE-ACCEPTANCE-CRITERIA.md`, cobrindo:

- quatro perfis comportamentais;
- estratégias especialista, dual e ampla quando aplicáveis, com provas de simetria separadas;
- heurísticas, anúncios, Políticas de Ascensão e perturbações em camadas próprias, sem produto cartesiano indiscriminado;
- primeira jornada e ao menos três Ascensões completas;
- equivalência de `×1`, `×10` e `MÁX` como fixtures ortogonais;
- retornos abaixo, iguais e acima de oito horas.

Antes de medir qualquer janela, a simulação deve carregar explicitamente o conjunto `balance-v0.1` e validar estas fixtures da curva `23/20`: `270→L10 = 5.487`, `2.350→L25 = 500.078`, `67.000→L50 = 483.587.018` e `67.000→L100 = 524.526.228.030`. Para `C₀ = 67.000`, deve também distinguir `99→100 = 68.416.522.780` de `100→101 = 78.679.001.197`.

A mesma validação deve conferir a escada de Contribuição-base `Bᵢ`, expressa em `Aura/s por nível`: `0,75`, `6,7`, `67`, `6.700` e `67.000.000`. Nos gates das profundidades `01` a `04`, os resultados de `Bᵢ × n × M(n)` devem ser exatamente `15 Aura/s`, `670 Aura/s`, `26.800 Aura/s` e `10.720.000 Aura/s`. Para a profundidade `05`, os níveis `1`, `10`, `25`, `50` e `100` devem produzir `67.000.000 Aura/s`, `1.340.000.000 Aura/s`, `6.700.000.000 Aura/s`, `26.800.000.000 Aura/s` e `107.200.000.000 Aura/s` antes da Ascensão.

Os custos-base das Técnicas devem ser carregados exatamente como `45`, `67`, `67.000`, `67.000.000`, `67.000.000.000` e `67.000.000.000.000 Aura`. A validação deve confirmar que `TECH-02` a `TECH-06` custam `6,7%` do respectivo limiar e que seu desbloqueio permanente não concede níveis gratuitos depois da Ascensão.

As Contribuições-base ativas devem ser carregadas como `1`, `6,7`, `6.700`, `6.700.000`, `6.700.000.000` e `6.700.000.000.000 Aura/ciclo por nível`. No nível `10`, depois do Marco `2×`, as fixtures são `20`, `134`, `134.000`, `134.000.000`, `134.000.000.000` e `134.000.000.000.000 Aura/ciclo`. A simulação deve reportar separadamente produção ativa e passiva por perfil, impedindo que a eficiência constante das Técnicas esconda uma economia offline sem utilidade.

As Convergências devem carregar custos-base `6.700`, `26.800.000` e `670.000.000.000.000 Aura`, com Contribuições-base `7,5`, `3.350` e `13.400.000.000 Aura/s`. Seus Orçamentos de Amplitude exatos são `16.461`, `44.288.124` e `1.452.336.002.684.412 Aura`; seus custos cumulativos até L10 são `136.039`, `544.139.651` e `13.603.491.219.495.333 Aura`. Toda execução Ampla deve reportar separadamente o ganho e o atraso atribuíveis a cada Convergência.

Uma execução com fixture divergente é inválida e não pode fundamentar ajuste de balanceamento. Se os custos confirmados impedirem as Janelas de Patamar, o relatório deve propor uma nova versão identificada, explicar quais métricas falharam e listar todos os parâmetros alterados; não se sobrescreve silenciosamente `balance-v0.1`.

Toda execução deve declarar `arith-v1`, usar inteiros exatos e passar as fixtures de `ECONOMIC-ARITHMETIC.md` antes de medir pacing. Rodar a mesma agenda com atualizações de `1.000ms`, `100ms` e partições aleatórias sem mudança de taxa deve produzir contadores, resto, compras, desbloqueios e limiares idênticos. Uma diferença de um único quantum, Aura ou preço reprova o simulador; agrupamento visual e timestamp de telemetria ficam fora dessa igualdade.

## Saídas obrigatórias

- tempo de calendário e tempo em sessão até cada Patamar;
- tempo até primeira Ascensão;
- níveis e itens adquiridos em cada marco;
- Potência de Ciclo e Produção Passiva;
- relação ativa/passiva;
- Aura Disponível, Total e da Jornada;
- Resto de Produção e versões `balance`, `arith` e `balance-gate`;
- tempo aguardando a próxima compra útil;
- Marcos de Nível e Convergências alcançados;
- aceleração causada por cada placement de anúncio;
- reconstrução depois da Ascensão;
- compra dominante e itens nunca escolhidos.

## Critérios temporais de aprovação

| Patamar | Muito ativo | Referência | Casual |
| --- | ---: | ---: | ---: |
| `1K` | `5–7min` | `5–7min` | `5–8min` |
| `1M` | `20–30min` | `6–10h` | `10–14h` |
| `1B` | `6–12h` | `24–36h` | `36–60h` |
| `1T` | `24–36h` | `72–96h` | `84–120h` |
| `1Qa` | `48–72h` | `96–120h` | `120–168h` |

Esses valores são tempo de calendário no Baseline. O relatório registra também tempo em sessão e interação ativa. O perfil Passivo passa pelo critério de progresso monotônico, não por prazo.

## Critérios qualitativos

- nenhum perfil fica permanentemente sem compra alcançável;
- nenhuma estratégia é uma armadilha irreversível;
- anúncios aceleram, mas não corrigem economia quebrada;
- a rota Passiva progride, ainda que fora da janela de Ascensão principal;
- o perfil Muito ativo não esgota o conteúdo antes de o sistema de Ascensão fazer sentido;
- o Casual encontra uma melhoria relevante em cada retorno típico;
- valores próximos de Marcos de Nível não criam longas esperas desproporcionais.

Os critérios quantitativos, tolerâncias, diagnósticos e formato de decisão canônicos estão em `BALANCE-ACCEPTANCE-CRITERIA.md`. Esta lista qualitativa complementa o gate e não substitui nenhum critério binário.

## Próxima entrega

- executar a matriz completa e produzir o primeiro relatório `APROVADO` ou `REPROVADO` sem alterar silenciosamente `balance-v0.1`.
