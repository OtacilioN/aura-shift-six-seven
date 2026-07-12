# Derivar Ascensão da Aura sacrificada acumulada

O `balance-v0.2` substitui parcelas independentes por um acumulado permanente `L` de toda Aura da Jornada sacrificada. O multiplicador em centésimos passa a ser `A(L)=100+floor(√(L÷10¹¹))`, e cada Ascensão mostra `A(L+J)−A(L)`. Assim, a primeira Ascensão em `1Qa` ainda dobra a produção, mas dividir `4Qa` em quatro resets produz o mesmo `3×` que uma jornada única de `4Qa`. O farm deixa de premiar a frequência de resets com crescimento aproximadamente exponencial e passa a crescer de forma aproximadamente linear no calendário idealizado.

Saves anteriores não registram cada jornada sacrificada. A migração estima `L` uma vez a partir da contagem `N` e do bônus antigo `B=max(0,A−100)`: para `N>0`, `L=max(N×1Qa, floor(B²×10¹¹/N))`; para `N=0`, `L=B²×10¹¹`. Essa aproximação não recupera jornadas históricas desiguais com perfeição, mas normaliza o multiplicador para a curva nova sem apagar saldos, Aura Total, Resto, coleção, conquistas ou a Taxa Offline Registrada.

## Alternativas rejeitadas

- **Reduzir cada parcela por uma porcentagem fixa:** desacelera a curva, mas mantém o mesmo feedback exponencial por calendário.
- **Dividir o ganho pela raiz do multiplicador atual:** reduz retornos repetidos, porém o resultado depende de como a mesma Aura foi particionada entre resets.
- **Preservar integralmente todo multiplicador antigo:** evita redução visível no save, mas mantém imediatamente o farm que motivou o nerf.
- **Garantir ao menos `+0,01×` por reset:** reintroduz, no limite, recompensa por frequência. Em quantização extrema, `L` continua acumulando até o próximo centésimo.
