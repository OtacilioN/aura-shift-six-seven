# Calcular a recompensa de Ascensão pela raiz quadrada da jornada

> Substituída por [ADR-0013](0013-ascensao-por-aura-ascendida-acumulada.md) em 11 de julho de 2026. Este arquivo preserva a decisão histórica de `balance-v0.1`.

Cada Ascensão exige pelo menos `1Qa` de Aura da Jornada e concede `floor(100 × √(Aura da Jornada ÷ 1Qa))` centésimos permanentes de multiplicador. As parcelas são armazenadas como inteiros, somadas a uma base de `100` e nunca compostas. A primeira Ascensão em `1Qa` dobra a produção; jornadas maiores concedem mais, mas com retorno sublinear e sem teto. Essa escolha torna a primeira reinicialização impactante, impede ganho sem nova jornada e aceita favorecer reinicializações mais frequentes em troca do custo de reconstrução.

## Considered Options

- **Bônus linear pela Aura da Jornada:** valorizaria igualmente toda espera, mas permitiria crescimento permanente rápido demais.
- **Bônus fixo por Ascensão:** seria simples, porém eliminaria a decisão de esperar além do mínimo.
- **Raiz quadrada quantizada em centésimos:** oferece ganho adicional com retornos decrescentes e cálculo determinístico; opção escolhida.
