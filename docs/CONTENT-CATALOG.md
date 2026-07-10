# Aura Shift: Six Seven — Catálogo Cultural do MVP

> Status: conteúdo-fonte de P04 fechado em 10 de julho de 2026; economia preservada em `balance-v0.1`. Nomes são `en-US` e podem ser transcriados sem alterar IDs ou função.

## Contratos invariáveis

- Os 42 slots são exatamente 18 Itens de Aura, seis Técnicas Six-Seven, cinco Transformações e 13 Conquistas.
- A razão universal é `23/20`; Marcos de Nível ocorrem em `10`, `25`, `50`, `100` e cada múltiplo de `100` posterior.
- A/B/C são economicamente idênticos em cada profundidade. Nome, ordem de coleção e Aparência não concedem vantagem.
- Aparência de Item é permanente e independente do Efeito de Item; esconder uma aparência não reduz produção.
- Texto essencial, números e estado nunca ficam incorporados no asset.

## Identidade dos ramos

| Ramo | Território | Promessa visual | Assinatura sonora original |
| --- | --- | --- | --- |
| A — **Poise** | presença quieta, linha e controle | formas limpas, reflexos, peso visual | impactos secos, ar curto, brilho discreto |
| B — **Motion** | pulso, piso e movimento urbano abstrato | ondas, fitas, deslocamento e eco | percussão corporal sintetizada e graves elásticos |
| C — **Signal** | repetição, estática e horizonte digital | glitches legíveis, scanlines largas, molduras | ticks digitais, ruído tonal e chamadas estéreo moderadas |

Poise não promete beleza física; Motion não reproduz dança ou figurino de comunidade real; Signal não imita interface, logo ou som de plataforma existente.

## Economia espelhada dos ramos

| Profundidade | IDs | Custo-base | Contribuição-base | Pré-requisito | Patamar |
| ---: | --- | ---: | ---: | --- | ---: |
| `01` | `ITEM-A/B/C-01` | `270 Aura` | `+0,75 Aura/s` por nível | `TECH-01` nível `1` | inicial |
| `02` | `ITEM-A/B/C-02` | `2.350 Aura` | `+6,7 Aura/s` por nível | respectivo `01` nível `10` | `1K` |
| `03` | `ITEM-A/B/C-03` | `67.000 Aura` | `+67 Aura/s` por nível | respectivo `02` nível `25` | `1M` |
| `04` | `ITEM-A/B/C-04` | `67.000 Aura` | `+6.700 Aura/s` por nível | respectivo `03` nível `50` | `1B` |
| `05` | `ITEM-A/B/C-05` | `67.000.000.000 Aura` | `+67.000.000 Aura/s` por nível | respectivo `04` nível `100` | `1T` |

Os custos iguais de `03` e `04` são intencionais. A contribuição é aditiva antes da aplicação única do Multiplicador de Ascensão.

## Ramo A — Poise

| ID | Nome-fonte | Descrição curta | Aparência e função visual | Variações nos Marcos | Dependências e risco |
| --- | --- | --- | --- | --- | --- |
| `ITEM-A-01` | **Quiet Flex** | `A small detail that does all the talking.` | broche assimétrico no peito; introduz Poise sem mudar silhueta | `10` borda dupla; `25` reflexo; `50` segundo plano; `100+` aro por centena | arte de torso, ping seco; baixo, expressão genérica |
| `ITEM-A-02` | **Clean Line** | `One clean edge. No wasted motion.` | faixa diagonal de ombro compatível com braços | linha dupla, filete claro, sombra rígida, nós luminosos | rig de ombro e RTL neutro; baixo |
| `ITEM-A-03` | **Mirror Glint** | `The room notices before the mascot does.` | visor abstrato sem lentes/marca, no slot de rosto | brilho lateral, prisma, reflexo móvel reduzível, facetas extras | oclusão facial e alternativa sem flash; baixo |
| `ITEM-A-04` | **Gravity Coat** | `Presence with its own pull.` | cauda curta flutuante atrás do corpo, sem cobrir mãos | bainha, duas abas, sombra-aura, constelação de pontos | simulação leve e modo reduzido estático; baixo |
| `ITEM-A-05` | **Crownless Halo** | `No throne. The signal is enough.` | arco aberto atrás da cabeça, explicitamente não religioso/real | segmento duplo, três órbitas, arco completo aberto, marcas por centena | legibilidade com FORM-04/05; baixo-médio por simbolismo, revisar locales |

## Ramo B — Motion

| ID | Nome-fonte | Descrição curta | Aparência e função visual | Variações nos Marcos | Dependências e risco |
| --- | --- | --- | --- | --- | --- |
| `ITEM-B-01` | **Pocket Pulse** | `A beat small enough to carry anywhere.` | módulo arredondado no quadril, sem marca ou tela textual | um pulso, dois pulsos, equalizador abstrato, aro por centena | slot de quadril e tick grave; baixo |
| `ITEM-B-02` | **Step Spark** | `Every move leaves the floor awake.` | tornozeleiras geométricas e faíscas no contato visual | contorno, rastro curto, rastro duplo, estrelas geométricas | não sugerir alvo de toque nem dança real; baixo |
| `ITEM-B-03` | **Floor Echo** | `The second wave arrives on its own.` | anéis achatados atrás dos pés, apenas decorativos | segundo anel, recorte, eco alternado, anéis por centena | partículas limitadas e redundância de forma; baixo |
| `ITEM-B-04` | **Night Current** | `The whole block moves in one direction.` | fita escura luminosa orbitando o torso atrás das mãos | ponta dupla, corrente larga, cortes rítmicos, nós adicionais | áudio percussivo original; médio por leitura urbana, sem caricatura |
| `ITEM-B-05` | **City Tremor** | `A quiet step. A skyline-sized response.` | silhueta de barras abstratas no fundo, não uma cidade real | três barras, skyline genérico, onda panorâmica, módulos por centena | fundo, desempenho e reduzir movimento; baixo |

## Ramo C — Signal

| ID | Nome-fonte | Descrição curta | Aparência e função visual | Variações nos Marcos | Dependências e risco |
| --- | --- | --- | --- | --- | --- |
| `ITEM-C-01` | **Glitch Pin** | `A tiny error with perfect timing.` | pin quadrado no peito com deslocamento de canais | duplicata, recorte, três canais, fragmento por centena | sem copiar ícones de app; baixo |
| `ITEM-C-02` | **Loop Lens** | `Catch the moment. Send it around again.` | lente flutuante única no slot lateral do rosto | anel duplo, retícula abstrata, eco de lente, pontos orbitais | não simular câmera/gravação; baixo-médio de privacidade, linguagem abstrata |
| `ITEM-C-03` | **Static Cape** | `The noise learned how to flow.` | painel de estática largo atrás do corpo | granulação, duas bandas, onda tonal, banda por centena | evitar cintilação/ruído rápido; baixo |
| `ITEM-C-04` | **Signal Crown** | `Every channel found the same frequency.` | três antenas curvas não funcionais atrás da cabeça | pontas, arcos, pulso de recepção, marcas por centena | distinguir de coroa real e Crownless Halo; baixo |
| `ITEM-C-05` | **Horizon Frame** | `The edge of the screen moved farther away.` | moldura aberta no fundo, sem encerrar controles | cantos, segunda moldura, profundidade, horizonte por centena | safe areas, RTL e telas largas; baixo |

## Itens de Convergência

| ID | Nome-fonte | Descrição curta | Requisitos simultâneos | Custo / contribuição | Aparência e Marcos | Dependências e risco |
| --- | --- | --- | --- | --- | --- | --- |
| `ITEM-CONV-01` | **Triple Sync** | `Three routes. One clean beat.` | três `01` no nível `10` + `1K` | `6.700`; `+7,5 Aura/s` | nó triangular atrás do Mascote; `10/25/50/100+` acrescentam contorno, giro reduzível, três pulsos e marcas | combina três paletas sem hierarquia; baixo |
| `ITEM-CONV-02` | **Full Spectrum** | `Every style, visible at once.` | três `03` no nível `25` + `1B` | `26.800.000`; `+3.350 Aura/s` | prisma aberto de três faixas; Marcos ampliam separação e profundidade | alternativa sem arco-íris piscante; baixo |
| `ITEM-CONV-03` | **Worldline** | `All paths arrive before the horizon.` | três `05` no nível `50` + `1Qa` | `670.000.000.000.000`; `+13.400.000.000 Aura/s` | linha contínua liga halo, piso e moldura; Marcos adicionam camadas estáticas | composição FORM-05 e desempenho; baixo |

Os Orçamentos de Amplitude permanecem `16.461`, `44.288.124` e `1.452.336.002.684.412 Aura`. Convergências são opcionais, reiniciam na Ascensão e não liberam ramo, Patamar ou Ascensão.

## Técnicas Six-Seven

| ID | Nome-fonte | Descrição curta | Desbloqueio | Custo / contribuição por nível | Marcos e feedback audiovisual | Risco/localização |
| --- | --- | --- | --- | --- | --- | --- |
| `TECH-01` | **Switch Stance** | `Set one hand. Send the other.` | início | `45`; `+1 Aura/ciclo` | mãos ganham contorno; Six “tak”, Seven “tum”; marcas engrossam rastro sem mudar timing | baixo; `stance` pode ser transcriado como posição |
| `TECH-02` | **Counterflow** | `One side rises as the other answers.` | `1K` | `67`; `+6,7 Aura/ciclo` | rastros complementares e resposta estéreo moderada | baixo; nunca exigir alternância espacial do toque |
| `TECH-03` | **Ghost Timing** | `The next move leaves an echo behind.` | `1M` | `67.000`; `+6.700 Aura/ciclo` | afterimage único e eco tonal; versão reduzida usa contorno | baixo; `ghost` pode exigir equivalente não sobrenatural |
| `TECH-04` | **Double Take** | `The motion lands twice. The reward lands once.` | `1B` | `67.000.000`; `+6.700.000 Aura/ciclo` | dois impactos visuais, um crédito claramente na Seven | médio: QA obrigatório para não sugerir recompensa dupla |
| `TECH-05` | **Zero-Drag** | `Nothing slows the shift.` | `1T` | `67.000.000.000`; `+6.700.000.000 Aura/ciclo` | smear curto e ataque sonoro limpo, sem acelerar economia | baixo; não prometer remoção de limite técnico |
| `TECH-06` | **Perfect Shift** | `Six moves. Seven closes the signal.` | `1Qa` | `67.000.000.000.000`; `+6.700.000.000.000 Aura/ciclo` | arco total Six→Seven, acorde original e haptic médio | baixo; “perfect” descreve ficção, não precisão exigida |

Técnicas não possuem pré-requisito entre si. Ascensão reinicia níveis, preserva desbloqueios. Os Marcos alteram apresentação, nunca a quantidade de toques, o limite de entrada ou a regra de crédito.

## Transformações de Aura

| ID | Nome-fonte | Marco | Silhueta, paleta, efeitos e fundo | Transição / versão reduzida | Dependências e risco |
| --- | ---: | --- | --- | --- | --- |
| `FORM-01` | **First Glow** | `1K` | contorno claro, duas partículas lentas, gradiente local | expansão de `450 ms`; reduzida: fade de `200 ms` | contraste e não ocultar itens; baixo |
| `FORM-02` | **Afterimage** | `1M` | segunda silhueta deslocada, paleta em dois tons, rastro curto | desloca e assenta em `650 ms`; reduzida: contorno duplo | evitar duplicar leitura de mãos; baixo |
| `FORM-03` | **Neon Weather** | `1B` | chuva diagonal lenta de símbolos abstratos e luz ambiente | frente passa em `900 ms`; reduzida: troca de fundo | limite de partículas e sem flash; baixo |
| `FORM-04` | **Skyline Pulse** | `1T` | Mascote maior por luz, horizonte de barras e ondas largas | pulso único de `1.100 ms`; reduzida: barras estáticas | compatibilidade com City Tremor; baixo |
| `FORM-05` | **Aura Zenith** | `1Qa` | halo aberto, piso e horizonte ligados; paleta espectral final | três estágios em `1.500 ms`; reduzida: fade por camadas | deve manter mãos e UI legíveis; `zenith` transcriável; baixo |

Transformações são permanentes, não são aparência equipável e não alteram economia. Cor nunca é o único diferenciador.

## Marcos 67

Todo limiar exato `67 × 1000ⁿ` usa a assinatura **Signal 67**:

1. Six: mão esquerda traça um arco curto e aparece `SIX`.
2. Seven: mão direita fecha o arco, aparece `SEVEN` e o Selo da magnitude entra na Coleção.
3. Fundo, partículas e música sobem por `6,7 segundos`, depois retornam sem corte.
4. Stinger: seis ticks leves e um impacto final original; haptic `curto-curto | pausa | médio`.
5. Versão reduzida: tipografia, contorno e fade, sem tremor, parallax ou sequência luminosa.
6. Leitor de tela: `67 milestone reached at {fullValue} Total Aura. Seal added to Collection.`

O evento não credita Aura, não multiplica produção e não se repete para a mesma magnitude.

## Inventário e slots visuais

Slots compatíveis: `chest`, `shoulder`, `face-side`, `head-back`, `hip`, `ankles`, `body-back`, `ground-back` e `scene-frame`. Itens que dividem slot podem ser selecionados individualmente; efeitos econômicos continuam ativos. Convergências usam `aura-back` e podem coexistir com um item por slot. QA deve testar as 18 Aparências com as cinco Transformações, RTL e movimento reduzido.

## Dependências de produção

- **Arte:** 18 aparências-base, quatro tratamentos reutilizáveis de Marco por item (materiais/overlays, não 72 assets exclusivos), cinco concept sheets de Transformação e três composições de Convergência.
- **Áudio:** famílias Poise/Motion/Signal originais, seis assinaturas de Técnica, stinger Signal 67 e alternativas sem áudio.
- **Localização:** nomes e descrições são transcriáveis; IDs, valores e regras não mudam; fornecer nota conceitual e limite de UI por string.
- **Acessibilidade:** todo rastro, glitch, estática, pulso ou partícula possui estado reduzido; nenhuma informação depende de cor/som/vibração.
- **Originalidade:** comparação obrigatória contra jogos concorrentes, assets de plataformas, pessoas e obras citadas no dossiê.

## Contagem fechada

| Família | Quantidade |
| --- | ---: |
| Itens próprios A/B/C | `15` |
| Convergências | `3` |
| Técnicas | `6` |
| Transformações | `5` |
| Conquistas em `ACHIEVEMENTS.md` | `13` |
| **Total de slots culturais** | **`42`** |
