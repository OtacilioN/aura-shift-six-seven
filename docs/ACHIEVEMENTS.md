# Aura Shift: Six Seven — Conquistas

> Status: 13 nomes, descrições e gatilhos de P04 fechados. Strings são fonte `en-US`; IDs e condições são canônicos.

## Contrato

- seis Conquistas são visíveis desde o início e sete permanecem ocultas até o desbloqueio;
- Conquistas são locais, permanentes, idempotentes e puramente comemorativas;
- não concedem Aura, itens, aparência, multiplicador ou desbloqueio;
- permanecem após Ascensões e integram save e Backup Manual;
- Selos 67 continuam em coleção separada.

## Visíveis

| ID | Nome-fonte | Descrição-fonte | Gatilho exato | Categoria |
| --- | --- | --- | --- | --- |
| `ACH-V-01` | **First Shift** | `You completed your first Six-Seven Cycle.` | primeiro crédito válido de Fase Seven | ciclo |
| `ACH-V-02` | **Hands in Motion** | `You completed 67 Six-Seven Cycles.` | contador vitalício de ciclos alcança `67` | volume de ciclo |
| `ACH-V-03` | **Passive Presence** | `Your first Aura Item started producing.` | primeira aquisição de qualquer Item de Aura | Loja |
| `ACH-V-04` | **Three Directions** | `You put one level into every root route.` | `ITEM-A-01`, `ITEM-B-01` e `ITEM-C-01` estão adquiridos na mesma jornada | Árvore |
| `ACH-V-05` | **The Room Noticed** | `You unlocked First Glow.` | `FORM-01` é desbloqueada em `1K` Aura Total | Transformação |
| `ACH-V-06` | **Same Presence, Bigger Sky** | `You completed your first Aura Ascension.` | primeira transação de Ascensão confirmada e persistida | Ascensão |

## Secretas

Antes do desbloqueio, UI e tecnologia assistiva mostram apenas `Secret achievement` e estado bloqueado. A coluna de gatilho é documentação interna e não entra em screenshots, metadados ou copy deck público.

| ID | Nome após desbloqueio | Descrição após desbloqueio | Gatilho confidencial exato | Categoria |
| --- | --- | --- | --- | --- |
| `ACH-S-01` | **Held the Pose** | `Six waited 67 seconds. Seven still answered.` | com app em primeiro plano, manter a Fase Six pendente por `≥67 s` monotônicos e então concluir a Fase Seven | easter egg de ciclo |
| `ACH-S-02` | **Quiet Hours** | `You came back after 6 hours and 7 minutes.` | criar e creditar uma Recompensa de Retorno para ausência válida de `≥6 h 7 min`; bônus não é necessário | retorno |
| `ACH-S-03` | **Exact Balance** | `You left exactly 67 Aura on the table.` | uma compra normal termina persistida com Aura Disponível exatamente `67`; Complemento não conta | Loja/easter egg |
| `ACH-S-04` | **Signals Stacked** | `One credit crossed more than one 67 milestone.` | um único crédito de produção cruza ao menos dois Marcos 67 inéditos | Marco 67 |
| `ACH-S-05` | **Routes Agree** | `Your first Convergence came online.` | primeira aquisição de qualquer Item de Convergência | Árvore ampla |
| `ACH-S-06` | **Full Spectrum** | `Every Convergence is active in one journey.` | `ITEM-CONV-01`, `02` e `03` adquiridos simultaneamente na jornada corrente | objetivo tardio |
| `ACH-S-07` | **Again, With Feeling** | `You completed a second Aura Ascension.` | contador vitalício de Ascensões alcança `2` | Ascensão |

## Ordem e idempotência

Cada gatilho registra primeiro `achievementId`, instante monotônico/lógico aplicável e versão da regra; só então agenda a apresentação. Reabrir, importar Backup Manual ou repetir o evento não cria duplicata.

Quando vários eventos ocorrem na mesma transação:

1. persistir créditos, Transformações, Selos e Conquistas;
2. apresentar Transformação ou Ascensão que causou a transação;
3. apresentar Marco 67;
4. apresentar Conquistas por ordem de ID;
5. permitir dispensar ou consolidar a fila sem perder registros.

## Apresentação

- toast compacto: emblema, nome e `Achievement unlocked`;
- detalhe na Coleção: nome, descrição e data local de desbloqueio;
- emblemas usam forma além de cor: ciclo, árvore, transformação, retorno, marco e ascensão possuem silhuetas distintas;
- animação padrão dura no máximo `1,2 s`; versão reduzida usa fade de até `200 ms`;
- som curto e haptic leve são opcionais e têm equivalente visual;
- nenhuma apresentação usa o mesmo stinger ou padrão tátil do Marco 67.

## Dependências de localização

- `First Shift`, `Held the Pose` e `Again, With Feeling` são transcriados por função, não literalmente;
- preservar `67`, `6 hours and 7 minutes` e a distinção Six/Seven;
- descrições secretas só entram no catálogo localizado final, marcado como conteúdo não promocional;
- árabe isola `67` como token LTR; leitores de tela recebem a frase localizada completa;
- nomes devem caber em duas linhas com escala textual máxima aprovada, sem reduzir fonte.

## QA obrigatório

1. disparo único antes e depois de Ascensão;
2. importação de save já desbloqueado;
3. compra em lote e Complemento não acionando `Exact Balance` indevidamente;
4. relógio civil alterado não acionando `Held the Pose`, que usa tempo monotônico;
5. ausência inválida não acionando `Quiet Hours`;
6. crédito que cruza dois Marcos acionando um único `Signals Stacked` e preservando ambos os Selos;
7. fila simultânea acessível, dispensável e persistente.
