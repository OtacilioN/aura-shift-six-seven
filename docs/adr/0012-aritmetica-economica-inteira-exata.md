# Representar a economia com aritmética inteira exata

O estado econômico usa inteiros de precisão arbitrária, Contribuições-base em vigésimos, Multiplicador de Ascensão em centésimos, `10.000.000` quanta por Aura e um Resto de Produção persistente. Essa escolha evita drift de ponto flutuante e resultados dependentes de frames, particionamento ou aparelho, ao custo de um contrato de save e uma ordem de operações mais explícitos. Alterar a escala depois de saves publicados exigiria migração econômica, por isso o contrato nasce versionado como `arith-v1`.

## Considered Options

- **Ponto flutuante:** mais simples para prototipar, mas incapaz de garantir igualdade reprodutível em números extremos e longas acumulações.
- **Arredondar cada atualização:** mantém saldos inteiros, porém perde produção e torna o resultado dependente da taxa de quadros.
- **Quanta inteiros com resto persistente:** preserva exatamente todos os denominadores aprovados e torna a integração associativa; opção escolhida.
