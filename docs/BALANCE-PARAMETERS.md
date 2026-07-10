# Aura Shift: Six Seven — Parâmetros de Balanceamento

> Status: parâmetros `balance-v0.1`, aritmética `arith-v1` e gate `balance-gate-v1` confirmados; resultados da matriz ainda serão produzidos.

## Constantes globais aprovadas

| Parâmetro | Valor |
| --- | ---: |
| Cadência de Referência | `1,5 ciclo/s` |
| razão de Custo Geométrico | `23/20` (`1,15`) |
| Marcos de Nível iniciais | `10`, `25`, `50`, `100` |
| Marcos de Nível recorrentes | cada `100` níveis depois de `100` |
| multiplicador por marco | `×2` cumulativo |
| Potência de Ciclo inicial | `1 Aura/ciclo` |
| contrato aritmético | `arith-v1` |
| quanta por Aura | `10.000.000` |
| unidade temporal econômica aberta | `1ms` monotônico |

## Perfis comportamentais

| Perfil | Sessões/dia | Duração | Cadência regular | Anúncios no baseline |
| --- | ---: | ---: | ---: | --- |
| Muito ativo | 4 | 30 min | `3 ciclos/s` | não |
| Referência | 3 | 15 min | `1,5 ciclo/s` | não |
| Casual | 2 | 10 min | `0,75 ciclo/s` | não |
| Passivo | 2 | `60s` após Bootstrap | `0` após Bootstrap | não |

Todas as agendas distribuem sessões uniformemente no dia, mantêm Produção Passiva aberta e aplicam no máximo oito horas por ausência. O onboarding inicial sempre usa `1,5 ciclo/s`. O Passivo repete a mesma cadência somente no Bootstrap posterior a cada Ascensão, até `TECH-01` L1 e um Item-raiz L1. Anúncios pertencem somente a cenários de sensibilidade.

## Janelas de Patamar sem anúncios

| Patamar | Muito ativo | Referência | Casual |
| --- | ---: | ---: | ---: |
| `1K` | `5–7min` | `5–7min` | `5–8min` |
| `1M` | `20–30min` | `6–10h` | `10–14h` |
| `1B` | `6–12h` | `24–36h` | `36–60h` |
| `1T` | `24–36h` | `72–96h` | `84–120h` |
| `1Qa` | `48–72h` | `96–120h` | `120–168h` |

O perfil Passivo deve progredir sem prazo fixo. As faixas medem calendário desde a primeira abertura e não incluem aceleração publicitária.

## Heurísticas de compra

| Cenário | Próxima compra |
| --- | --- |
| baseline | maior `Aura marginal em 24h ÷ custo` |
| mais barata | menor custo entre entradas desbloqueadas |
| Caçadora de meta | menor ETA estimada até o próximo Marco de Nível ou Pré-requisito relevante |

O baseline guarda Aura para sua melhor candidata, compra somente durante sessões e desempata diferenças de até 1% por meta, menor nível e ID. A estratégia Especialista, Dual ou Ampla limita o conjunto de ramos elegíveis.

## Entradas ancoradas

| ID | Tipo | Custo-base | Contribuição-base | Desbloqueio |
| --- | --- | ---: | ---: | --- |
| `TECH-01` | Técnica | `45 Aura` | `+1 Aura/ciclo` por nível | início |
| `ITEM-A-01` | Item-raiz | `270 Aura` | `+0,75 Aura/s` por nível | primeiro nível de `TECH-01` |
| `ITEM-B-01` | Item-raiz | `270 Aura` | `+0,75 Aura/s` por nível | primeiro nível de `TECH-01` |
| `ITEM-C-01` | Item-raiz | `270 Aura` | `+0,75 Aura/s` por nível | primeiro nível de `TECH-01` |

## Escada econômica dos Ramos de Aura — `balance-v0.1`

| Profundidade | IDs espelhados | Custo-base | Contribuição-base por nível | Nível-gate | Orçamento de Gate exato | Contribuição no gate |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| `01` | `ITEM-A/B/C-01` | `270` | `0,75 Aura/s` | `10` | `5.487` | `15 Aura/s` |
| `02` | `ITEM-A/B/C-02` | `2.350` | `6,7 Aura/s` | `25` | `500.078` | `670 Aura/s` |
| `03` | `ITEM-A/B/C-03` | `67.000` | `67 Aura/s` | `50` | `483.587.018` | `26.800 Aura/s` |
| `04` | `ITEM-A/B/C-04` | `67.000` | `6.700 Aura/s` | `100` | `524.526.228.030` | `10.720.000 Aura/s` |
| `05` | `ITEM-A/B/C-05` | `67.000.000.000` | `67.000.000 Aura/s` | — | — | — |

Cada Orçamento de Gate soma, para um único item, as compras `0→1` até `(L−1)→L` usando `ceil(C₀ × (23/20)ⁿ)` em cada nível. Como fixtures adicionais, para `C₀ = 67.000`, a compra `99→100` custa exatamente `68.416.522.780`, e `100→101` custa `78.679.001.197`.

O custo-base de `67 bilhões` da profundidade `05` cria um handoff próximo ao último preço necessário para concluir o gate da profundidade `04`. A igualdade de custo-base entre as profundidades `03` e `04` é intencional: o salto do gate de nível `50` para `100` já cria a diferença de investimento. Patamares continuam impedindo compras antecipadas.

As contribuições de gate já incluem os Marcos de Nível: `2×` no nível `10`, `4×` no `25`, `8×` no `50` e `16×` no `100`. Para a profundidade `05`, as fixtures exatas de contribuição nos níveis `1`, `10`, `25`, `50` e `100` são `67.000.000 Aura/s`, `1.340.000.000 Aura/s`, `6.700.000.000 Aura/s`, `26.800.000.000 Aura/s` e `107.200.000.000 Aura/s`, respectivamente, antes da Ascensão.

## Desbloqueio das Técnicas

| ID | Aura Total | Custo-base | Contribuição-base por nível | Eficiência-base |
| --- | ---: | ---: | ---: | ---: |
| `TECH-01` | início | `45 Aura` | `1 Aura/ciclo` | `1/45` |
| `TECH-02` | `1K` | `67 Aura` | `6,7 Aura/ciclo` | `1/10` |
| `TECH-03` | `1M` | `67.000 Aura` | `6.700 Aura/ciclo` | `1/10` |
| `TECH-04` | `1B` | `67.000.000 Aura` | `6.700.000 Aura/ciclo` | `1/10` |
| `TECH-05` | `1T` | `67.000.000.000 Aura` | `6.700.000.000 Aura/ciclo` | `1/10` |
| `TECH-06` | `1Qa` | `67.000.000.000.000 Aura` | `6.700.000.000.000 Aura/ciclo` | `1/10` |

Os desbloqueios são permanentes. Níveis são reiniciados pela Ascensão e custos permanecem inalterados. Depois do primeiro desbloqueio, uma Técnica pode estar visível desde o começo de jornadas futuras, mas seu custo-base continua limitando quando seus níveis voltam a ser compráveis.

De `TECH-02` a `TECH-06`, custo e contribuição avançam juntos por `1.000×`, preservando a razão exata `Contribuição-base ÷ custo-base = 1/10`. No nível `10`, o Marco `2×` produz, de `TECH-01` a `TECH-06`, `20`, `134`, `134.000`, `134.000.000`, `134.000.000.000` e `134.000.000.000.000 Aura/ciclo` antes da Ascensão.

## Patamares e marcos visuais

| Aura Total | Transformação | Nós cujo Patamar é aberto | Outro efeito |
| ---: | --- | --- | --- |
| inicial | — | `ITEM-A/B/C-01`, após `TECH-01` nível `1` | escolha do primeiro ramo |
| `1K` | `FORM-01` | `ITEM-A/B/C-02`, `ITEM-CONV-01` | — |
| `1M` | `FORM-02` | `ITEM-A/B/C-03` | — |
| `1B` | `FORM-03` | `ITEM-A/B/C-04`, `ITEM-CONV-02` | — |
| `1T` | `FORM-04` | `ITEM-A/B/C-05` | — |
| `1Qa` | `FORM-05` | `ITEM-CONV-03` | primeira Ascensão disponível |

## Pré-requisitos da Árvore de Aura

| Nós | Pré-requisito de nível |
| --- | --- |
| `ITEM-A/B/C-02` | respectivo `01` no nível `10` |
| `ITEM-A/B/C-03` | respectivo `02` no nível `25` |
| `ITEM-A/B/C-04` | respectivo `03` no nível `50` |
| `ITEM-A/B/C-05` | respectivo `04` no nível `100` |
| `ITEM-CONV-01` | `A-01`, `B-01` e `C-01` no nível `10` |
| `ITEM-CONV-02` | `A-03`, `B-03` e `C-03` no nível `25` |
| `ITEM-CONV-03` | `A-05`, `B-05` e `C-05` no nível `50` |

Cada nó também exige seu Patamar de Aura conforme a tabela anterior. Convergências são opcionais e não participam dos requisitos de Ascensão; `1Qa` libera a Ascensão independentemente de terem sido adquiridas.

## Economia das Convergências — `balance-v0.1`

| Entrada | Custo-base | Contribuição-base por nível | Orçamento de Amplitude | Soma dos três requisitos | Parcela adicionada em L1 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ITEM-CONV-01` | `6.700 Aura` | `7,5 Aura/s` | `16.461 Aura` | `45 Aura/s` | `1/6` |
| `ITEM-CONV-02` | `26.800.000 Aura` | `3.350 Aura/s` | `44.288.124 Aura` | `20.100 Aura/s` | `1/6` |
| `ITEM-CONV-03` | `670.000.000.000.000 Aura` | `13.400.000.000 Aura/s` | `1.452.336.002.684.412 Aura` | `80.400.000.000 Aura/s` | `1/6` |

O Orçamento de Amplitude inclui todos os níveis necessários nos três caminhos, mas exclui a própria Convergência. Assim, a recompensa não é gratuita: o custo-base adicional corresponde a aproximadamente `40,7%`, `60,5%` e `46,1%` do investimento prévio, respectivamente.

| Entrada | L1 | L10 (`2×`) | L25 (`4×`) | L50 (`8×`) | L100 (`16×`) | Custo acumulado até L10 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `ITEM-CONV-01` | `7,5 Aura/s` | `150 Aura/s` | `750 Aura/s` | `3.000 Aura/s` | `12.000 Aura/s` | `136.039 Aura` |
| `ITEM-CONV-02` | `3.350 Aura/s` | `67.000 Aura/s` | `335.000 Aura/s` | `1.340.000 Aura/s` | `5.360.000 Aura/s` | `544.139.651 Aura` |
| `ITEM-CONV-03` | `13.400.000.000 Aura/s` | `268.000.000.000 Aura/s` | `1.340.000.000.000 Aura/s` | `5.360.000.000.000 Aura/s` | `21.440.000.000.000 Aura/s` | `13.603.491.219.495.333 Aura` |

Todas as contribuições são medidas antes da Ascensão. `ITEM-CONV-03` compete deliberadamente com a decisão de Ascender depois de `1Qa` e funciona como objetivo de amplitude tardio, nunca como requisito de progresso.

### Espelhamento dos ramos

Para cada profundidade `n`, os parâmetros de `ITEM-A-n`, `ITEM-B-n` e `ITEM-C-n` são idênticos. As tabelas futuras devem possuir uma única linha econômica por profundidade e três referências de conteúdo. Convergências mantêm linhas próprias.

## Derivação do caminho-base

| Momento | Cálculo | Resultado |
| --- | --- | ---: |
| primeira Técnica | `1,5 × 30 × 1` | `45 Aura` em `30s` |
| produção depois de `TECH-01` | `1,5 × 2` | `3 Aura/s` |
| primeiro Item-raiz | `3 × 90` | `270 Aura` em mais `90s` |
| relação ativa/passiva | `3 ÷ 0,75` | `4×` |
| Aura Total ao comprar o Item | `45 + 270` | `315` |
| tempo restante até `FORM-01` | `(1.000 − 315) ÷ 3,75` | `182,67s` |
| tempo total até `FORM-01` | `120 + 182,67` | `302,67s` (`5min02,7s`) |

Esse cálculo pressupõe Cadência de Referência, compra imediata de um nível de `TECH-01`, nenhuma outra compra antes do Item-raiz e interação ativa contínua. O tempo parado no Consentimento de Analytics não integra a medição.

## Recompensa de Ascensão

Para `J = Aura da Jornada` e `Jmín = 10¹⁵`:

`U = floor(100 × √(J ÷ Jmín))`

`Parcela = U ÷ 100`

`Multiplicador total em centésimos = 100 + ΣU`

| `J` | `U` | Parcela |
| ---: | ---: | ---: |
| `1Qa` | `100` | `+1,00×` |
| `2Qa` | `141` | `+1,41×` |
| `4Qa` | `200` | `+2,00×` |
| `9Qa` | `300` | `+3,00×` |

Elegibilidade por jornada: `J ≥ 1Qa`. Não existe teto. O cálculo e a persistência usam inteiros.

### Políticas simuladas

| Cenário | Ascender em |
| --- | ---: |
| baseline | `1Qa` de Aura da Jornada |
| sensibilidade A | `2Qa` |
| sensibilidade B | `4Qa` |
| sensibilidade C | `9Qa` |

Cada cenário percorre no mínimo três Ascensões e permanece sem anúncios quando usado como baseline econômico.

## Validação ainda aberta

- validar todos os custos e contribuições já fixados contra as janelas e estratégias da matriz; qualquer mudança exige uma nova versão identificada.

Nenhum valor econômico deve ser inferido a partir do nome futuro do conteúdo. Somente parâmetros documentados e versionados podem orientar implementação.
