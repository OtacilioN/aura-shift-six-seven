# Aura Shift: Six Seven — Exibição de Números

> Status: convenção completa de apresentação `number-format-v1` e precisão `arith-v1` aprovadas.

## Objetivos

- manter números legíveis durante progressão de grande magnitude;
- preservar o mesmo significado em todos os idiomas;
- evitar saltos visuais excessivos e textos que não caibam na interface;
- permitir auditoria do valor não abreviado quando necessário.

## Notação principal

Contadores inteiros de Aura, níveis, preços e créditos de zero a 999 aparecem sem sufixo. Potência de Ciclo e Produção Passiva usam o decimal terminante exato de sua razão canônica. A partir de mil, tanto inteiros quanto taxas preservam até três algarismos significativos truncados.

| Potência de dez | Sufixo | Exemplo em inglês | Exemplo em português |
| ---: | :---: | ---: | ---: |
| 3 | K | 1.25K | 1,25K |
| 6 | M | 1.25M | 1,25M |
| 9 | B | 1.25B | 1,25B |
| 12 | T | 1.25T | 1,25T |
| 15 | Qa | 1.25Qa | 1,25Qa |
| 18 | Qi | 1.25Qi | 1,25Qi |
| 21 | Sx | 1.25Sx | 1,25Sx |
| 24 | Sp | 1.25Sp | 1,25Sp |
| 27 | Oc | 1.25Oc | 1,25Oc |
| 30 | No | 1.25No | 1,25No |
| 33 | Dc | 1.25Dc | 1,25Dc |

A tabela é fechada para o MVP em `Dc`. Valores de `10³³` até imediatamente antes de `10³⁶` usam `Dc`; a partir de `10³⁶`, o formato passa à notação científica, como `1.25e120` em inglês ou `1,25e120` em português.

## Algoritmo compacto para inteiros

1. valores inteiros de `0` a `999` aparecem sem sufixo; esta etapa não se aplica a taxas ou efeitos fracionários;
2. entre `10³` e `10³⁶−1`, selecionar o maior expoente múltiplo de `3` presente na tabela;
3. escalar o coeficiente para o intervalo `[1,1000)`;
4. preservar no máximo três algarismos significativos: duas casas para coeficiente abaixo de `10`, uma abaixo de `100` e nenhuma a partir de `100`;
5. truncar as casas excedentes em direção a zero;
6. remover zeros decimais finais e o separador vazio;
7. nunca promover um valor ao sufixo seguinte por arredondamento;
8. em notação científica, usar coeficiente em `[1,10)`, até duas casas truncadas e expoente decimal integral.

| Valor exato | Exibição inglesa | Exibição portuguesa |
| ---: | ---: | ---: |
| `999` | `999` | `999` |
| `1.000` | `1K` | `1K` |
| `1.999` | `1.99K` | `1,99K` |
| `67.000` | `67K` | `67K` |
| `999.999` | `999K` | `999K` |
| `1.000.000` | `1M` | `1M` |
| `1.234.567` | `1.23M` | `1,23M` |
| `10³⁶` | `1e36` | `1e36` |

O expoente e os sufixos permanecem em caracteres ASCII e recebem isolamento bidirecional em idiomas RTL.

## Taxas racionais compactas

Após aplicar o Multiplicador `A/100` — inclusive no estado inicial `A=100` —, Potência de Ciclo, Produção Passiva e efeitos produtivos efetivos derivados de `arith-v1` podem ser representados pela forma exata `N/2000`, em que `N` é inteiro não negativo. Para as taxas totais, `N=P20×A` ou `N=T20×A`. Fórmulas canônicas escrevem `2000` sem agrupamento localizado, e a formatação nunca converte essa razão para ponto flutuante.

- para `0 ≤ N < 2000000`, exibir o decimal terminante exato de `N/2000` com até quatro casas e remover somente zeros finais;
- para `N ≥ 2000000`, selecionar o sufixo pelo maior `e` da tabela para o qual `N ≥ 2000×10ᵉ`;
- para `d=2`, `1` ou `0` casas segundo a faixa do coeficiente, calcular `q=floor(N×10ᵈ ÷ (2000×10ᵉ))` e exibir `q/10ᵈ` com remoção de zeros finais;
- a partir de `10³⁶`, escolher o maior expoente inteiro `s` que satisfaça `N ≥ 2000×10ˢ` e calcular o coeficiente pela mesma divisão inteira, com duas casas;
- remover zeros finais, localizar somente o separador e nunca promover o sufixo por arredondamento.

Assim, a mesma regra de até três algarismos significativos vale para uma taxa grande, mas sua magnitude e suas casas são decididas diretamente pelo racional exato.

| Numerador `N` | Valor exato | Exibição `en-US` |
| ---: | ---: | ---: |
| `1500` | `0.75` | `0.75` |
| `15000` | `7.5` | `7.5` |
| `21009` | `10.5045` | `10.5045` |
| `1999999` | `999.9995` | `999.9995` |
| `2000000` | `1000` | `1K` |
| `2469135` | `1234.5675` | `1.23K` |
| `19998000` | `9999` | `9.99K` |
| `20000000` | `10000` | `10K` |
| `199998000` | `99999` | `99.9K` |
| `200000000` | `100000` | `100K` |
| `1999999999` | `999999.9995` | `999K` |
| `2000000000` | `1000000` | `1M` |
| `2000×10³⁶−1` | `10³⁶−0.0005` | `999Dc` |
| `2000×10³⁶` | `10³⁶` | `1e36` |

## Localização

Sufixos e expoentes não são traduzidos. Todos os tokens econômicos usam os dígitos ASCII `0–9`, inclusive em árabe, para preservar a identidade visual de `67`, a comparação entre telas e a representação canônica. O locale controla:

- separador decimal;
- separador de agrupamento na visualização não abreviada;
- direção e composição tipográfica quando aplicável;
- a leitura localizada entregue à tecnologia assistiva.

Em interfaces RTL, cada token econômico completo — dígitos, separador, sinal quando existir, sufixo ou expoente — é isolado como trecho LTR, sem alterar o espelhamento da interface ao redor. Datas e textos não econômicos continuam seguindo as convenções normais do locale.

O sufixo B sempre representa `10^9`, independentemente de como cada idioma nomeia essa magnitude.

## Representação não abreviada

Uma área de detalhes permite consultar valores sem sufixo para:

- Aura Disponível;
- Aura Total;
- Aura da Jornada;
- Potência de Ciclo;
- Produção Passiva;
- preços e efeitos de melhoramentos quando necessário.

Para contadores e preços, a visualização usa a string inteira decimal canônica, aplica agrupamento localizado somente na apresentação e permite seleção e cópia. Números longos são apresentados em segmentos virtualizados e quebráveis, acompanhados da contagem de dígitos, sem impor um teto econômico visível. A ação de copiar entrega o inteiro ASCII sem agrupamento, preservando o valor exato.

Potência de Ciclo e Produção Passiva podem ser fracionárias em qualquer Jornada; a Ascensão altera o numerador, não o formato canônico. A área de detalhes deriva seu decimal terminante exato do denominador canônico `2000`, mostra até quatro casas necessárias e remove somente zeros finais; ela nunca arredonda a taxa. A ação de copiar entrega somente esse decimal exato com ponto ASCII, sem agrupamento nem sufixo; uma ação que inclua contexto textual apresenta a unidade em campo separado.

Para tecnologia assistiva, o valor compacto informa em linguagem localizada o coeficiente, a potência matemática, a unidade e se o valor representa saldo ou taxa; a área de detalhes disponibiliza o inteiro ou decimal exato e, para inteiros longos, a contagem de dígitos. Tokens numéricos usam isolamento de direção para não inverter sinal, expoente ou sufixo em árabe.

## Integralidade e precisão

Aura Disponível, Aura Total, Aura da Jornada, preços e recompensas concedidas são inteiros não negativos de precisão arbitrária. Produção fracionária de qualquer fonte é preservada no Resto de Produção compartilhado e somente transfere unidades completas aos três contadores. O contrato `arith-v1` utiliza `10.000.000` quanta por Aura; essa escala interna nunca aparece como saldo gastável.

A exibição compacta trunca para baixo em vez de arredondar. Por exemplo, o valor `1999` aparece como `1.99K` em inglês ou `1,99K` em português, nunca como `2K`. Essa regra evita sugerir poder de compra inexistente.

Compras, desbloqueios, marcos e comparações usam sempre o valor exato. Textos abreviados são apenas apresentação.

Um token compacto nunca constitui identidade econômica. Quando valores canônicos distintos em uma comparação produzirem o mesmo token, o formatador não aumenta dinamicamente a precisão: o contexto calcula a diferença exatamente. Se `saldo < preço`, a Loja mostra `Faltam {preço−saldo} Aura`; ao comparar contribuição atual e projetada, mostra `+{diferença} Aura/ciclo` ou `+{diferença} Aura/s`. O rótulo curto da diferença pode usar esta notação, mas seu detalhe acionável e sua leitura assistiva expõem o decimal completo. O mesmo valor faltante alimenta a oferta de Complemento de Aura quando ela for elegível.

## Fixtures de interface

| Cenário | Rótulo curto | Representação completa ou cópia |
| --- | --- | --- |
| taxa `N=2469135`, `en-US` | `1.23K` | `1234.5675` |
| mesma taxa, `pt-BR` | `1,23K` | cópia `1234.5675` |
| mesma taxa, `ar` | `1٫23K` como um único isolamento LTR | cópia `1234.5675` |
| saldo `1990`, preço `1999`, `en-US` | ambos `1.99K`; `Faltam 9 Aura` | saldo `1990`, preço `1999`, falta `9` |
| contribuição `1990→1999 Aura/s`, `en-US` | ambos `1.99K`; `+9 Aura/s` | atual `1990`, projetada `1999`, diferença `9` |

Os caracteres de controle ou a primitiva equivalente que formam o isolamento RTL pertencem ao token inteiro e não aparecem na cópia. Fixtures localizadas validam também o rótulo assistivo completo, não somente a string visual.

Valores econômicos persistidos usam texto decimal integral e nunca passam pelo formatador localizado durante cálculo ou serialização. Os detalhes completos de precisão, conversão e fixtures estão em `ECONOMIC-ARITHMETIC.md`.

Marcos 67 seguem `67 × 1000ⁿ` e são avaliados contra Aura Total exata. A aparência `67K`, `67M` ou equivalente é consequência da notação, não a origem do gatilho.

## Regra de evolução

Todas as superfícies econômicas consomem o mesmo `number-format-v1`; variantes locais por tela não pertencem ao contrato. Alterar dígitos, sufixos, expoentes, truncamento ou a política de apresentação de colisões compactas exige uma nova versão de apresentação. A mudança nunca pode alterar o inteiro econômico, os Marcos 67 ou a serialização `arith-v1`.
