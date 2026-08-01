# Escalar quadraticamente o custo marginal da Ascensão

O `balance-v0.4` preserva o acumulado permanente `L` de Aura Ascendida, mas substitui a raiz quadrada por uma curva cuja passagem de `n×` para `(n+1)×` custa exatamente `n² Qa`.

Para um multiplicador candidato inteiro `A≥100`, em centésimos:

`L_req(A) = ceil(1Qa × (A−100) × A × (2A−100) ÷ 6.000.000)`

O multiplicador vigente é o maior `A` para o qual `L_req(A)≤L`. A expressão é a extensão em centésimos da soma dos quadrados. Nos multiplicadores inteiros, `L_req(100n)=1Qa×Σ(k²), k=1..n−1`.

Assim, a primeira passagem continua significativa e familiar:

- `1×→2×` custa `1Qa`;
- `2×→3×` custa `4Qa`;
- `10×` exige `285Qa`;
- `10×→11×` custa `100Qa`, levando o acumulado a `385Qa`.

Como o jogador em `10×` produz aproximadamente dez vezes mais Aura que em `1×`, cobrar `100Qa` torna essa passagem aproximadamente dez vezes mais demorada no modelo econômico ideal. A curva anterior cobrava `19Qa`, que viravam apenas cerca de `1,9×` o tempo-base depois de considerar a produção multiplicada.

A implementação usa somente `BigInt`, teto inteiro e busca binária. A prévia e a confirmação consultam a mesma função canônica, compartilhada também pela migração e validação do Cloud Save. Particionar a mesma Aura entre resets continua sem produzir vantagem.

Saves `balance-v0.2` e `balance-v0.3` preservam `L`, que representa Aura realmente ascendida, e reconciliam o multiplicador pela curva nova. Não se aumenta `L` para conservar um multiplicador antigo, pois isso fabricaria progresso e poderia violar a relação entre Aura Ascendida, Aura da Jornada e Aura Total.

## Alternativas rejeitadas

- **Custo marginal bruto `n Qa`:** faria `10×→11×` custar `10Qa`, abaixo dos `19Qa` da curva anterior, produzindo um buff.
- **Preservar a raiz quadrada:** mantém o crescimento de calendário próximo do linear porque o próprio multiplicador compensa grande parte do custo bruto.
- **Preservar o multiplicador antigo fabricando `L`:** evita redução visível, mas registra Aura nunca ascendida e cria vantagem permanente incompatível com o nerf.
- **Conceder apenas multiplicadores inteiros:** simplifica a curva, porém remove o feedback gradual em centésimos já exposto pela interface.
