# Aura Shift: Six Seven — Design de Economia

> Status: estrutura, fórmulas, parâmetros `balance-v0.1` e precisão `arith-v1` aprovados; resultados aguardam simulação.

## Objetivos

- sustentar crescimento de longo prazo sem apagar conquistas anteriores;
- tornar ações ativas e produção passiva igualmente compreensíveis, mas estrategicamente distintas;
- fazer cada compra parecer um avanço, mesmo quando reduz a Aura Disponível;
- permitir escolhas na progressão sem criar caminhos irrecuperáveis;
- manter anúncios opcionais e complementares à recompensa-base.

## Marcos de cadência

- primeira Técnica Six-Seven adquirível em cerca de 30 segundos;
- primeiro Item de Aura adquirível em cerca de 2 minutos;
- primeira Transformação de Aura em cerca de 5 minutos;
- primeira sessão natural entre 8 e 12 minutos, encerrando com Produção Passiva e próximo objetivo visível;
- primeira Ascensão em 2–3 dias para jogo muito ativo ou 5–7 dias para jogo casual.

Esses marcos orientarão simulações e testes; nenhuma mecânica deve aguardar um cronômetro apenas para reproduzir o tempo-alvo.

A calibração usa 1,5 Ciclo Six-Seven por segundo como Cadência de Referência. As simulações também cobrem 0,75 ciclo/s, 3 ciclos/s e ausência completa de toques. Esses perfis medem resultados; não criam limites de entrada.

Os ritmos integram quatro agendas canônicas: Muito ativo com quatro sessões de 30 minutos a `3 ciclos/s`; Referência com três sessões de 15 minutos a `1,5 ciclo/s`; Casual com duas sessões de 10 minutos a `0,75 ciclo/s`; e Passivo com duas aberturas de `60s` e nenhum ciclo depois de cada Bootstrap de Jornada. Sessões são uniformemente distribuídas e o cenário-base não utiliza anúncios.

As Janelas de Patamar oficiais variam por perfil: Muito ativo progride de `1K` em `5–7min` até `1Qa` em `48–72h`; Referência, de `5–7min` até `96–120h`; Casual, de `5–8min` até `120–168h`. Os marcos intermediários completos permanecem na especificação de balanceamento. O perfil Passivo precisa progredir sem prazo fixo.

O baseline escolhe compras pelo Retorno Projetado de 24 Horas: Aura marginal ativa e passiva esperada na agenda do perfil dividida pelo preço do próximo nível. Compras são avaliadas nível a nível, realizadas somente em sessão e restritas pela estratégia de ramo. Cenários “Mais barata” e “Caçadora de meta” verificam robustez contra decisões menos eficientes; a segunda minimiza a ETA estimada até o próximo Marco de Nível ou Pré-requisito relevante.

Com investimento equilibrado, a Produção Ativa na Cadência de Referência começa em cerca de 4× a Produção Passiva, converge para 2× no meio da jornada e para aproximadamente 1× antes da Ascensão. As duas fontes são somadas com o jogo aberto. Ramos e escolhas de investimento podem deslocar a relação individual sem alterar esses alvos sistêmicos.

## Âncoras numéricas iniciais

O balanceamento parte dos seguintes valores aprovados:

| Parâmetro | Valor |
| --- | ---: |
| Potência de Ciclo inicial | `1 Aura/ciclo` |
| custo-base de `TECH-01` | `45 Aura` |
| contribuição-base de `TECH-01` | `+1 Aura/ciclo` por nível |
| custo-base de cada Item-raiz | `270 Aura` |
| contribuição-base de cada Item-raiz | `+0,75 Aura/s` por nível |
| marco de `FORM-01` | `1.000 Aura Total` |

Os Itens-raiz são `ITEM-A-01`, `ITEM-B-01` e `ITEM-C-01`. Depois da primeira Técnica, os três ficam disponíveis ao mesmo tempo e usam custo e contribuição idênticos. O jogador escolhe qual Ramo de Aura iniciar sem existir uma opção numericamente superior naquele ponto.

## Escada de Patamares

A progressão permanente usa potências de mil:

| Aura Total | Transformação | Patamar da Loja | Progressão permanente |
| ---: | --- | --- | --- |
| `1K` | `FORM-01` | itens `02` e `CONV-01` | — |
| `1M` | `FORM-02` | itens `03` | — |
| `1B` | `FORM-03` | itens `04` e `CONV-02` | — |
| `1T` | `FORM-04` | itens `05` | — |
| `1Qa` | `FORM-05` | `CONV-03` | primeira Ascensão disponível |

Os três Itens-raiz pertencem ao acesso inicial liberado pela primeira compra de `TECH-01`. Abrir um Patamar não satisfaz Pré-requisitos de nível. Patamares e Transformações permanecem após Ascensão; aquisições e níveis são reconstruídos.

No caminho de referência — comprar um nível de `TECH-01` e depois guardar para um Item-raiz — a derivação é:

1. `1,5 ciclo/s × 30s × 1 Aura/ciclo = 45 Aura`;
2. depois da Técnica, `2 Aura/ciclo × 1,5 ciclo/s = 3 Aura/s`;
3. `3 Aura/s × 90s = 270 Aura`, alcançando o Item em `120s` totais;
4. o Item acrescenta `0,75 Aura/s`, portanto `3 ÷ 0,75 = 4`;
5. a Aura Total na compra do Item é `315`;
6. faltam `685 Aura` para `FORM-01`, produzidas a `3,75 Aura/s` em aproximadamente `182,67s`;
7. o marco visual ocorre em aproximadamente `302,67s`, ou `5min02,7s`.

O tempo mede interação econômica e exclui quanto o jogador permanecer no convite de Analytics. Caminhos com níveis adicionais, cadência diferente ou pausas podem variar e serão simulados separadamente.

## Valores centrais

### Aura Disponível

Saldo consumido por compras na Loja. Pode diminuir, sem representar regressão de jornada.

### Aura Total

Soma de toda a Aura produzida. Nunca diminui e controla marcos permanentes, incluindo Patamares de Aura e transformações visuais.

### Potência de Ciclo

Produção ativa exata gerada integralmente ao concluir a Fase Seven. Unidades completas são creditadas aos três contadores; a fração permanece no Resto de Produção. É ampliada por Técnicas Six-Seven.

A velocidade de entrada não modifica a Potência de Ciclo e não existe multiplicador econômico de combo. Jogar mais rápido aumenta somente o número de ciclos concluídos por tempo.

### Produção Passiva

Taxa de Aura gerada sem Ciclos Six-Seven. É ampliada por Itens de Aura e continua durante ausências segundo as regras de Produção Offline.

### Aura da Jornada

Produção acumulada desde o início da jornada atual. É reiniciada por uma Ascensão de Aura e serve como base exclusiva para calcular o próximo ganho do Multiplicador de Ascensão, sem substituir ou reduzir a Aura Total.

## Notação de grandes valores

O contrato `number-format-v1`, detalhado em `NUMBER-FORMATTING.md`, governa somente a apresentação. Valores inteiros até 999 são exibidos integralmente; taxas abaixo de mil preservam seu decimal terminante exato. A partir de mil, a interface usa a capitalização fixa de K a Dc e até três algarismos significativos truncados. Dígitos e magnitudes são ASCII, separadores são localizados. A partir de `10³⁶`, usa notação científica, e a representação não abreviada permanece consultável.

Todos os saldos, totais, preços e ganhos concedidos são inteiros não negativos de precisão arbitrária. Toda fonte pode alimentar um Resto de Produção compartilhado até completar uma unidade, sem descartá-la. A exibição compacta trunca para baixo, e decisões econômicas sempre consultam o valor exato.

O contrato `arith-v1`, detalhado em `ECONOMIC-ARITHMETIC.md`, usa Contribuições-base em vigésimos, Multiplicador de Ascensão em centésimos, milissegundos inteiros e `10.000.000` quanta por Aura. Frames nunca são unidades econômicas. A produção é integrada antes de mudanças de taxa, e somente unidades inteiras completas entram no Livro-Razão.

## Fontes de Aura

- conclusão de Ciclos Six-Seven;
- Produção Passiva com o jogo aberto;
- Produção Offline limitada a oito horas;
- Bônus de Retorno opcional de 20% sobre as oito horas após ausência superior a esse limite.

## Livro-Razão de Aura

| Evento | Aura Disponível | Aura Total | Aura da Jornada |
| --- | ---: | ---: | ---: |
| Ciclo Six-Seven concluído | +valor produzido | +valor produzido | +valor produzido |
| Produção Passiva aberta | +valor produzido | +valor produzido | +valor produzido |
| Produção Offline | +valor produzido | +valor produzido | +valor produzido |
| Bônus de Retorno | +bônus concedido | +bônus concedido | +bônus concedido |
| Compra normal | −preço | sem alteração | sem alteração |
| Compra com Complemento de Aura | −Aura possuída | sem alteração | sem alteração |

Multiplicadores são aplicados antes do crédito. O Complemento de Aura quita diretamente a parcela faltante e não representa Aura produzida.

## Destinos da Aura Disponível

- aquisição inicial e evolução de Itens de Aura;
- evolução de Técnicas Six-Seven.

O lançamento não possui moeda premium nem compras dentro do aplicativo. Nenhuma forma de Aura, multiplicador, nível, melhoramento ou Ascensão é vendida por dinheiro real.

## Complemento de Aura

Quando uma compra já está desbloqueada e o jogador possui entre 70% e menos de 100% de seu preço, a Loja pode oferecer um Complemento de Aura por Anúncio Recompensado. O jogador entrega sua Aura Disponível, e o complemento cobre somente o valor faltante, limitado a 30% do preço. A oferta nunca substitui condições de desbloqueio e não aparece quando o preço integral já pode ser pago.

Cada jogador pode concluir no máximo três Complementos em uma janela móvel de 24 horas, sem cooldown entre eles. O Bônus de Retorno offline é independente. Tentativas canceladas, indisponíveis ou com erro não consomem a cota, e a oferta nunca interrompe a tela principal.

## Limites do modelo publicitário

O lançamento utiliza exclusivamente Anúncios Recompensados iniciados pelo jogador. Banners e intersticiais automáticos ficam excluídos, assim como anúncios acionados por abertura, navegação, conclusão de ciclos ou compras. Os únicos pontos publicitários iniciais são o Bônus de Retorno e o Complemento de Aura.

## Produção Offline

A recompensa-base corresponde a no máximo oito horas de Produção Passiva. Após uma ausência superior a oito horas, o jogador pode receber essa recompensa sem anúncio ou assistir voluntariamente a um Anúncio Recompensado para acrescentar 20%.

A recompensa usa a Produção Passiva final registrada quando o jogo deixa o primeiro plano, incluindo Itens de Aura e Multiplicador de Ascensão então vigentes. Essa taxa é multiplicada pelo tempo válido, limitado a oito horas. Frações permanecem no Resto de Produção compartilhado.

Compras, níveis, desbloqueios e crescimento composto não são simulados durante a ausência. Produção Ativa não participa. Marcos e Transformações são processados somente no crédito da recompensa.

Intervalos de relógio incoerentes resultam em zero Produção Offline somente para aquela ausência e não oferecem Bônus de Retorno. O jogo estabelece uma nova referência sem banimento ou perda de estado. Mudanças para trás não renovam a cota de Complementos de Aura.

Cada ausência calculada é persistida como uma Recompensa de Retorno antes da apresentação. A base é creditada uma única vez. Quando o jogador escolhe o anúncio, a base é persistida primeiro e o adicional de 20% é creditado separadamente após o sucesso. Falhas podem ser repetidas sem reverter ou duplicar a base; fechamento e reabertura retomam o estado pendente.

## Modelo matemático de melhoramentos

Cada Técnica Six-Seven e Item de Aura possui custo-base e contribuição-base próprios. A razão geométrica e o calendário de Marcos de Nível são globais. Para uma entrada `i` cujo nível atual é `n`, o próximo preço segue:

`Cᵢ(n) = ceil(Cᵢ,0 × (23/20)ⁿ)`

`Cᵢ,0` é um inteiro positivo e `23/20` representa exatamente `1,15`. A aquisição inicial compra a passagem do nível `0` para o nível `1`. O cálculo sempre parte do custo-base e do nível atual, aplica a potência racional e somente então usa um único teto inteiro. O preço arredondado anterior nunca alimenta o próximo cálculo.

A contribuição de uma entrada segue a estrutura:

`Eᵢ(n) = Bᵢ × n × M(n)`

`Bᵢ` é a contribuição fixa de cada nível e `M(n)` é o fator acumulado dos Marcos de Nível já alcançados. Todas as entradas usam o mesmo calendário:

`S = {10, 25, 50, 100, 200, 300, ...}`

Cada marco duplica cumulativamente a contribuição. De forma compacta:

`m(n) = I(n≥10) + I(n≥25) + I(n≥50) + floor(n/100)`

`M(n) = 2^m(n)`

Assim, os fatores vigentes a partir dos níveis 10, 25, 50, 100 e 200 são, respectivamente, `2×`, `4×`, `8×`, `16×` e `32×`. O marco multiplica somente a contribuição total daquela entrada; não afeta outras entradas, não muda custos, não concede Aura e não cria um novo multiplicador global.

Antes da Ascensão:

- `Potência de Ciclo = Potência-base + Σ E_técnica(n)`;
- `Produção Passiva = Σ E_item(n)`.

O Multiplicador de Ascensão é aplicado uma única vez depois de cada soma. Cálculos de custo e comparações nunca derivam do texto abreviado; a apresentação visual dos preços segue `number-format-v1`. Compras `×10` e `MÁX` somam cada preço inteiro real atravessado, inclusive quando cruzam Marcos de Nível.

Esse modelo combina custos geométricos, ganhos aditivos e saltos de marco. Ele evita tanto a dominância permanente causada por custos lineares quanto a instabilidade de ganhos exponenciais puros por nível. Se uma Compra em Lote atravessar vários marcos, todos os fatores são aplicados, mas a interface usa uma celebração consolidada.

### Escada econômica dos ramos — `balance-v0.1`

| Profundidade | Custo-base de `A/B/C` | Contribuição-base | Gate | Investimento exato | Contribuição no gate |
| ---: | ---: | ---: | ---: | ---: | ---: |
| `01` | `270` | `0,75 Aura/s` | nível `10` | `5.487` | `15 Aura/s` |
| `02` | `2.350` | `6,7 Aura/s` | nível `25` | `500.078` | `670 Aura/s` |
| `03` | `67.000` | `67 Aura/s` | nível `50` | `483.587.018` | `26.800 Aura/s` |
| `04` | `67.000` | `6.700 Aura/s` | nível `100` | `524.526.228.030` | `10.720.000 Aura/s` |
| `05` | `67.000.000.000` | `67.000.000 Aura/s` | terminal | — | — |

O investimento cumulativo é o Orçamento de Gate: soma exata das transições do nível `0` ao nível exigido, com um teto independente em cada preço. Para validar o limite tardio, um item de custo-base `67.000` cobra `68.416.522.780` na transição `99→100` e `78.679.001.197` na transição seguinte, `100→101`.

As profundidades `03` e `04` compartilham o mesmo custo-base de propósito. O gate muda de `50` para `100`, elevando o investimento de aproximadamente `483,6 milhões` para `524,5 bilhões` sem introduzir outra razão de crescimento. O primeiro nível da profundidade `05` custa `67 bilhões`, formando um handoff memorável próximo ao último preço do gate anterior. Os Patamares de Aura permanecem uma trava independente, portanto essa escada não autoriza compras antecipadas.

A escada de contribuição, expressa em `Aura/s por nível`, é deliberadamente irregular: `0,75`, `6,7`, `67`, `6.700` e `67.000.000`. Ela acompanha os diferentes Orçamentos de Gate e intervalos de Patamar; uma progressão uniforme de `1.000×` começaria a profundidade `02` em `750 Aura/s` e comprimiria excessivamente a chegada a `1M`. Os valores decimais são racionais exatos (`3/4` e `67/10`).

No último item, as contribuições antes da Ascensão são `67.000.000 Aura/s` no nível `1`, `1.340.000.000 Aura/s` no nível `10`, `6.700.000.000 Aura/s` no nível `25`, `26.800.000.000 Aura/s` no nível `50` e `107.200.000.000 Aura/s` no nível `100`. Essas fixtures tornam explícito o salto mais sensível da escada e devem ser confrontadas com a janela `1T→1Qa`.

Os números são o baseline identificado `balance-v0.1`, não constantes imunes a teste. Uma mudança só é aceita depois de simulação reprodutível contra as Janelas de Patamar e deve atualizar conjuntamente todas as tabelas e fixtures numéricas.

## Progressão da Loja

Cada Item de Aura é único e pode receber níveis repetíveis. Técnicas Six-Seven também possuem níveis repetíveis. Todos os níveis aumentam resultados numéricos; mudanças visuais aparecem apenas em marcos selecionados.

As seis Técnicas formam uma trilha paralela sem Pré-requisitos internos: `TECH-01` começa disponível e `TECH-02` a `TECH-06` abrem permanentemente em `1K`, `1M`, `1B`, `1T` e `1Qa` de Aura Total. Ascensão reinicia seus níveis, mas a Aura Total preservada mantém todos os desbloqueios já alcançados.

| Técnica | Desbloqueio permanente | Custo-base | Contribuição-base por nível |
| --- | ---: | ---: | ---: |
| `TECH-01` | início | `45 Aura` | `1 Aura/ciclo` |
| `TECH-02` | `1K` | `67 Aura` | `6,7 Aura/ciclo` |
| `TECH-03` | `1M` | `67.000 Aura` | `6.700 Aura/ciclo` |
| `TECH-04` | `1B` | `67.000.000 Aura` | `6.700.000 Aura/ciclo` |
| `TECH-05` | `1T` | `67.000.000.000 Aura` | `6.700.000.000 Aura/ciclo` |
| `TECH-06` | `1Qa` | `67.000.000.000.000 Aura` | `6.700.000.000.000 Aura/ciclo` |

Depois da exceção inicial de `TECH-01`, cada custo-base equivale exatamente a `6,7%` do Patamar que revelou a Técnica. Isso a torna uma recompensa economicamente próxima, mas não gratuita. Em jornadas posteriores, o desbloqueio permanente permite vê-la desde cedo, enquanto o custo crescente ainda controla o momento da recompra.

Da segunda Técnica em diante, custo-base e Contribuição-base aumentam juntos por `1.000×`; a razão `Contribuição-base ÷ custo-base` permanece exatamente `1/10`. O valor `6,7` é o racional `67/10`. Essa regularidade mantém comparável a eficiência ativa de cada nova magnitude, enquanto sessões e Cadência limitam sua produção no calendário e preservam a função dos Itens passivos.

Níveis não possuem limite econômico planejado. A Loja permite `×1`, `×10` e `MÁX`. O custo de `×10` é a soma real dos próximos dez níveis; `MÁX` compra a maior quantidade inteira pagável. O Complemento de Aura é restrito a uma aquisição ou nível em `×1` e nunca cobre Compra em Lote.

O Efeito de Item permanece ativo para todo Item de Aura adquirido, independentemente da Aparência de Item escolhida. Personalização visual não modifica a Produção Passiva.

A Coleção Visual permanece entre Ascensões. Aparências podem continuar equipadas, mas o Efeito de Item é reiniciado junto com a propriedade econômica e só volta após a readquisição.

A Loja é organizada como uma Árvore de Aura:

- Aura Total libera Patamares de Aura permanentemente;
- Pré-requisitos de Item conectam itens dentro de Ramos de Aura;
- caminhos diferentes permitem escolhas de prioridade;
- itens especiais podem exigir níveis em mais de um ramo;
- dependências circulares são proibidas;
- avançar não exige maximizar todo o conteúdo anterior.

Cada ramo possui uma cadeia de cinco itens. Depois do Item-raiz, os itens `02`, `03`, `04` e `05` exigem o predecessor nos níveis `10`, `25`, `50` e `100`, respectivamente, além do Patamar de Aura correspondente.

Os três ramos são economicamente espelhados. Em cada profundidade, A, B e C usam o mesmo custo-base e a mesma contribuição-base, além das curvas globais compartilhadas. A escolha de ramo organiza identidade visual e coleção, não eficiência. Convergências permanecem fora desse espelho e recebem parâmetros próprios.

As Convergências recompensam amplitude:

- `ITEM-CONV-01` exige os três Itens-raiz no nível `10`;
- `ITEM-CONV-02` exige os três itens `03` no nível `25`;
- `ITEM-CONV-03` exige os três itens `05` no nível `50`.

Esses requisitos são conjuntivos, mas opcionais. Convergências não bloqueiam a continuidade de um ramo, novos Patamares ou Ascensão. Assim, especialização permanece viável e investimento equilibrado recebe objetivos extras.

| Convergência | Custo-base | Contribuição-base por nível | Orçamento de Amplitude | Produção dos requisitos |
| --- | ---: | ---: | ---: | ---: |
| `ITEM-CONV-01` | `6.700 Aura` | `7,5 Aura/s` | `16.461 Aura` | `45 Aura/s` |
| `ITEM-CONV-02` | `26.800.000 Aura` | `3.350 Aura/s` | `44.288.124 Aura` | `20.100 Aura/s` |
| `ITEM-CONV-03` | `670.000.000.000.000 Aura` | `13.400.000.000 Aura/s` | `1.452.336.002.684.412 Aura` | `80.400.000.000 Aura/s` |

Em cada caso, o primeiro nível acrescenta exatamente `1/6` da produção somada dos três nós diretamente exigidos. O Orçamento de Amplitude mede todos os custos para construir os três caminhos e não inclui o preço da Convergência. Esse preço adicional equivale a aproximadamente `40–61%` do investimento prévio, impedindo que amplitude receba um multiplicador gratuito.

`ITEM-CONV-03` exige mais investimento prévio que o limiar da primeira Ascensão e ainda custa `670T`. Portanto, é um objetivo opcional para quem prolonga a jornada; Ascender imediatamente em `1Qa` continua sendo a política-base da simulação. Todas as Convergências usam a curva e os Marcos globais, reiniciam economicamente na Ascensão e preservam somente a Aparência já colecionada.

O catálogo do MVP contém 15 itens distribuídos igualmente entre três Ramos de Aura e três Itens de Convergência, totalizando 18. Técnicas Six-Seven usam uma progressão separada com seis entradas. Cinco Transformações de Aura marcam a progressão visual. Essas quantidades são exatas para a primeira publicação.

## Ascensão de Aura

A progressão de longo prazo inclui uma Ascensão de Aura voluntária, disponível pela primeira vez em `1Qa` (`10¹⁵`) de Aura Total. Ela reinicia Aura Disponível, Técnicas Six-Seven e aquisição, níveis e Pré-requisitos dos Itens de Aura. Aura Total, Patamares de Aura, conquistas e transformações visuais permanecem.

A Coleção Visual e a personalização equipada também permanecem; efeitos econômicos dos itens ficam inativos até a readquisição.

Cada Ascensão concede um Multiplicador de Ascensão permanente aplicado às jornadas seguintes. A confirmação deve deixar perdas, preservações e ganhos explícitos. A ação não depende de anúncio ou pagamento.

Toda Ascensão exige ao menos `1Qa` de Aura da Jornada. Para `J` igual à Aura da Jornada e `Jmín = 10¹⁵`, o ganho permanente é:

`Δ = floor(100 × √(J ÷ Jmín)) ÷ 100`

O cálculo usa centésimos inteiros:

`U = floor(100 × √(J ÷ Jmín))`

`100` unidades correspondem a `+1,00×`. O total persistido é `100 + ΣU`, incluindo as `100` unidades da base `1×`. A implementação deverá usar aritmética inteira equivalente, sem ponto flutuante.

| Aura da Jornada | Parcela | Total após primeira Ascensão |
| ---: | ---: | ---: |
| `1Qa` | `+1,00×` | `2,00×` |
| `2Qa` | `+1,41×` | `2,41×` |
| `4Qa` | `+2,00×` | `3,00×` |
| `9Qa` | `+3,00×` | `4,00×` |

A raiz quadrada aumenta a recompensa por esperar, mas de forma sublinear. Não existe teto. Depois da confirmação, a Aura da Jornada volta a zero e uma nova Ascensão exige produzir outro `1Qa` nessa jornada.

Nas simulações, a política-base Ascende em `1Qa`; sensibilidades esperam `2Qa`, `4Qa` e `9Qa`. Cada uma percorre pelo menos três Ascensões para medir a troca entre bônus por Aura, frequência de reinício e tempo de reconstrução. Essas políticas não orientam automaticamente jogadores reais.

O Multiplicador de Ascensão se aplica igualmente à Potência de Ciclo e à Produção Passiva. A Produção Offline parte da taxa passiva já multiplicada; somente depois disso o Bônus de Retorno opcional acrescenta 20%, sem reaplicar o multiplicador.

Cada Ascensão acrescenta uma parcela permanente ao multiplicador-base de `1×`. As parcelas são somadas, nunca compostas entre si. Assim, `+0,5×` seguido de `+0,8×` produz `2,3×`, e o total é aplicado uma única vez às fontes de produção.

## Estado do modelo

Parâmetros do catálogo, aritmética e apresentação numérica estão definidos e versionados como `balance-v0.1`, `arith-v1` e `number-format-v1`. A próxima etapa econômica é executar `balance-v0.1` contra `balance-gate-v1`; ajustes somente podem entrar em uma nova versão identificada.
