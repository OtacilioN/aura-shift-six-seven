# Aura Shift: Six Seven — Aritmética Econômica Exata

> Status: contrato econômico `arith-v1` aprovado para planejamento e simulação; nenhuma implementação faz parte desta fase.

## Objetivo

Garantir que produção ativa, produção passiva, ausência, anúncios, compras e Ascensão produzam o mesmo resultado em qualquer aparelho, taxa de quadros, particionamento de tempo ou ciclo de salvamento. Nenhum estado econômico canônico utiliza ponto flutuante.

## Representação canônica

- Aura Disponível, Aura Total, Aura da Jornada, preços, níveis e parcelas econômicas são inteiros não negativos de precisão arbitrária.
- Valores econômicos arbitrariamente grandes são serializados como texto decimal integral, nunca como número JSON de precisão limitada.
- Contribuições-base de Técnica usam `B20_técnica` em vigésimos de `Aura/ciclo por nível`; as de Item usam `B20_item` em vigésimos de `Aura/s por nível`.
- O Multiplicador de Ascensão é o inteiro `A` em centésimos: `100 = 1×`, `141 = 1,41×` e `200 = 2×`.
- Uma Aura contém exatamente `Q = 10.000.000` quanta econômicos.
- Um único Resto de Produção persistente `R` satisfaz `0 ≤ R < Q` e reúne quanta ainda não reconhecidos nem atribuídos a qualquer contador ou jornada.
- O contrato de aritmética é identificado como `arith-v1`.

A escala `Q` representa exatamente as contribuições em vigésimos, o Multiplicador em centésimos, intervalos inteiros de milissegundos e o Bônus de Retorno de `20%`. Uma contribuição futura cujo denominador não divida `20` exige nova versão deste contrato; ela nunca pode ser aproximada silenciosamente.

## Contribuições e taxas

Para uma entrada de nível `n`:

`E20(n) = B20 × n × M(n)`

O fator universal de Marcos é definido no próprio contrato por:

`m(n) = I(n≥10) + I(n≥25) + I(n≥50) + floor(n/100)`

`M(n) = 2^m(n)`

Assim, os níveis `10`, `25`, `50`, `100`, `200` e seguintes aplicam cumulativamente os fatores já aprovados.

As somas canônicas antes da Ascensão são:

- `P20 = 20 + Σ E20_técnica(n)`, em vigésimos de `Aura/ciclo`, para Potência de Ciclo;
- `T20 = Σ E20_item(n)`, em vigésimos de `Aura/s`, para Produção Passiva.

O `20` inicial de `P20` representa a Potência-base de `1 Aura/ciclo`. Entradas são somadas primeiro; o Multiplicador `A/100` é aplicado uma única vez somente depois da soma.

## Produção ativa

Um Ciclo Six-Seven concluído gera exatamente:

`q_ativo = P20 × A × 5.000` quanta

Frames, Fase Six e toques isolados não produzem Aura. Somente a conclusão da Fase Seven cria esse valor.

## Produção passiva aberta

Para um intervalo inteiro `Δms` durante o qual `T20` e `A` não mudam:

`q_passivo = T20 × A × Δms × 5` quanta

A economia usa milissegundos inteiros de relógio monotônico enquanto o jogo está aberto. Frames apenas solicitam a integração do intervalo desde o último checkpoint; eles não são unidades econômicas.

Antes de compra, mudança de nível, Ascensão, ida ao segundo plano ou qualquer evento que altere uma taxa, o jogo integra o tempo até o timestamp do evento usando o estado anterior. Só então aplica a mudança e recalcula as taxas.

Dez integrações de `100ms` precisam produzir os mesmos contadores, `R`, desbloqueios e conjunto ordenado de limiares cruzados que uma integração de `1.000ms`, desde que nenhuma taxa mude no intervalo. Agrupamento visual e instante de emissão de telemetria podem variar; a identidade de um marco é seu limiar canônico, nunca o checkpoint de atualização.

## Conversão para Aura inteira

Para qualquer lote de produção exata `q`:

1. `S = R + q`;
2. `crédito = floor(S ÷ Q)`;
3. `R = S mod Q`;
4. o mesmo `crédito` inteiro é acrescentado a Aura Disponível, Aura Total e Aura da Jornada.

O Resto de Produção nunca pode ser exibido como saldo gastável, mas também nunca é descartado entre atualizações válidas, fechamento, importação ou Ascensão. Compras consomem apenas Aura Disponível inteira e não alteram `R`.

## Produção Offline e Bônus de Retorno

Ao entrar em segundo plano, depois de integrar o trecho aberto, o jogo registra o snapshot canônico e congelado:

`F_registrado = T20 × A`

O inteiro `F_registrado` é o numerador da Taxa Offline Registrada `F_registrado/2000 Aura/s`. Ele não é um cache recalculável: permanece imutável até materializar a Recompensa de Retorno daquela ausência, mesmo que níveis, parâmetros ou versão mudem. Para uma ausência coerente de `D` milissegundos:

- se `D < 0` ou o intervalo for incoerente, `D_válido = 0` e uma nova referência temporal é estabelecida;
- caso contrário, `D_válido = min(D, 28.800.000)`.

`q_offline = F_registrado × D_válido × 5`

A taxa permanece congelada durante a ausência. Não existem compras, níveis, Marcos de Nível ou crescimento composto offline.

Quando o intervalo é coerente, `D > 28.800.000` e o anúncio é concluído validamente:

`q_bônus = q_offline ÷ 5`

O bônus é exatamente `20%` da produção-base em quanta, antes da conversão em Aura inteira e sem reaplicar Ascensão. `q_offline` é sempre divisível por `5` nesse contrato.

A Recompensa de Retorno persiste identificador, base exata, bônus exato, status de cada crédito e referências temporais. A base é aplicada uma vez; o bônus é uma transação separada e idempotente. Antes de Ascender, a base sempre precisa estar creditada e a oportunidade de bônus precisa ser aceita ou explicitamente recusada. Recusar o bônus nunca remove nem reduz a base.

## Custos e Compras em Lote

Para custo-base `C₀` e nível atual `n`:

`C(n) = ceil(C₀ × 23ⁿ ÷ 20ⁿ)`

O cálculo inteiro equivalente usa:

`ceil(N ÷ D) = floor((N + D − 1) ÷ D)`

Regras:

- `0→1` usa `n = 0`;
- cada preço parte de `C₀`, nunca do preço arredondado anterior;
- existe um único teto por nível;
- `×10` e `MÁX` somam preços inteiros individuais;
- a soma do lote não recebe um segundo teto;
- cálculos de preço, leituras de saldo e comparações nunca derivam do texto abreviado; sua apresentação visual segue `number-format-v1`.

## Complemento de Aura

Para saldo inteiro `D` e preço inteiro `C`, a oferta é elegível somente quando:

`7 × C ≤ 10 × D < 10 × C`

O cálculo não usa `0,7` em ponto flutuante. Ao iniciar o anúncio, a transação registra item, nível, `C`, `D` e a falta `C − D`. A conclusão válida consome exatamente o saldo `D` cotado, cobre diretamente `C − D`, não credita Aura e não altera Aura Total ou Aura da Jornada. Qualquer produção válida ocorrida depois da cotação permanece separada. Falha, cancelamento ou invalidação do item não consome saldo nem cota.

## Ascensão

A transação de Ascensão somente é elegível quando `J ≥ Jmín = 10¹⁵`. A fórmula pode alimentar uma prévia abaixo do limiar, mas a confirmação permanece inválida. Para Aura da Jornada inteira `J`, a parcela em centésimos é o maior inteiro `U` que satisfaz:

`U² × 10¹¹ ≤ J`

Isso equivale exatamente a:

`U = floor(100 × √(J ÷ 10¹⁵))`

O Multiplicador total permanece:

`A = 100 + ΣU`

A prévia e a confirmação usam o mesmo cálculo inteiro. Antes de confirmar, o jogo integra a produção aberta até o timestamp da ação, atualiza `J` e recalcula a prévia se necessário. A transação persiste parcela, total, reinícios e contagem atomicamente. Aura Total e `R` permanecem; Aura Disponível e Aura da Jornada voltam a zero.

## Ordem econômica normativa

1. ordenar eventos por timestamp e sequência determinística;
2. integrar a produção aberta pendente com o estado anterior, converter seus quanta e processar os limiares cruzados;
3. validar a ação contra esse estado atualizado e derivar seu `q_evento`, que pode ser zero;
4. converter `q_evento` e processar, na mesma transação, Patamares, Transformações e Marcos 67 que ele atravessar;
5. aplicar as mutações não produtivas da ação, como débito, nível, fase ou reset;
6. recalcular taxas derivadas;
7. persistir estado, resto, limiares e efeitos do evento atomicamente.

Ao entrar em segundo plano, a taxa offline somente é registrada depois da integração aberta. Ao retornar, a ausência não é integrada como tempo aberto; ela passa exclusivamente pela Recompensa de Retorno.

Potência de Ciclo, Produção Passiva e preço seguinte podem ser caches verificáveis. Níveis, parâmetros versionados, Aura inteira, `R` e `A` são as fontes canônicas; enquanto uma ausência ainda não foi materializada, `F_registrado` também é fonte canônica daquele retorno.

## Invariantes

- `0 ≤ Aura Disponível ≤ Aura da Jornada ≤ Aura Total`;
- todo crédito de produção acrescenta o mesmo inteiro aos três contadores;
- compras reduzem somente Aura Disponível;
- `0 ≤ R < 10.000.000` e nenhuma atualização válida descarta `R`;
- dividir um intervalo sem mudança de taxa não altera contadores, `R`, desbloqueios ou limiares cruzados;
- a identidade e a ordem de Marcos usam seus limiares canônicos, não o checkpoint de atualização;
- telemetria atribui produção por quanta de cada fonte e não tenta atribuir a uma fonte única a Aura inteira completada pelo resto compartilhado;
- Ascensão é aplicada uma única vez depois das somas;
- Bônus de Retorno é aplicado uma única vez sobre a produção offline já multiplicada;
- texto compacto ou localizado nunca participa de cálculo;
- nenhum intermediário pode sofrer overflow ou perda silenciosa de precisão;
- caches divergentes são reconstruídos a partir das fontes canônicas.

## Fixtures obrigatórias

Salvo quando uma linha declara encadeamento, cada fixture começa com `R=0`, contadores zerados e nenhuma produção pendente.

| Caso | Resultado exato esperado |
| --- | --- |
| `0,75 Aura/s`, `A=100`, `1s` | crédito `0`, `R=7.500.000` |
| mesmo estado por mais `1s` | crédito `1`, `R=5.000.000` |
| `6,7 Aura/s`, `A=100`, `1s` | crédito `6`, `R=7.000.000` |
| `7,45 Aura/s`, `A=141`, `1s` | crédito `10`, `R=5.045.000` |
| Potência-base `1` + `TECH-02` L1 (`P=7,7`), `A=141` | crédito `10`, `R=8.570.000` |
| `10 × 100ms` versus `1 × 1.000ms` | contadores, `R`, desbloqueios e limiares idênticos |
| `0,75/s` por `1s`, depois `6,7/s` por `1s` | produção exata `7,45 Aura` |
| offline `6,7 Aura/s`, `A=200`, `8h` | `385.920 Aura` |
| nova fixture, `R=0`, offline `6,7 Aura/s`, `A=200`, ausência de `12h` | mesma base limitada de `385.920 Aura` |
| ausência de `12h`, offline `7,45 Aura/s`, `A=141` | base `q=3.025.296.000.000`: crédito `302.529`, `R=6.000.000`; bônus `q=605.059.200.000`: crédito `60.506`, `R final=5.200.000`; total creditado `363.035` |
| `C₀=270`, `n=0,1,2` | preços `270`, `311`, `358` |
| `C₀=270`, níveis `0..9` | total `5.487` |
| partindo de L0, saldo `5.486` e `5.487` | não compra / compra o lote completo `0→10` |
| `J=1Qa,2Qa,4Qa,9Qa` | `U=100,141,200,300` |
| `J=2.016.399.999.999.999` | `U=141` |
| `J=2.016.400.000.000.000` | `U=142` |
| primeira Ascensão em `1Qa` | `A=200` |
| estado inicial `A=200`, segunda Ascensão com `J=2Qa` | `A=341`, nunca `482` |
| `J=1Qa`, Ascensão elegível e `R=9.999.999`; depois `1` quantum | crédito `1` na nova jornada |
| relógio offline negativo | base zero, `R` preservado e nova referência |
| reprocessar a mesma Recompensa de Retorno | nenhum segundo crédito |

Toda simulação e futura implementação precisa passar essas fixtures antes de produzir resultados de balanceamento válidos.
