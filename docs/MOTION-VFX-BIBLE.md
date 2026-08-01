# Aura Shift: Six Seven — Bíblia de Motion, VFX e Haptics

> Contrato `motion-v1`. Timings são de apresentação; estado econômico e entrada nunca aguardam uma animação.

## Princípios

- reconhecer todo contato válido no primeiro frame disponível;
- distinguir Fase Six de Fase Seven sem depender de cor, som ou vibração;
- concentrar confirmação de Aura em Seven;
- permitir interrupção, retomada e descarte visual sem perder estado;
- escalar espetáculo, não recompensa: não existe combo econômico;
- oferecer uma versão reduzida equivalente para todo evento relevante.

O alvo é 60 fps. Em perfil degradado, a cena mantém entrada e poses a 30 fps, reduz emissores e desativa camadas secundárias antes de descartar feedback essencial.

## Vocabulário temporal

| Termo | Curva | Uso |
| --- | --- | --- |
| `snap` | cubic-bezier equivalente a `(0.20, 0.90, 0.25, 1.00)` | contato e entrada rápida |
| `settle` | spring criticamente amortecida, sem mais de 6% de overshoot | mãos e Mascote |
| `glide` | ease-in-out `(0.42, 0, 0.58, 1)` | fundo e intensidade |
| `reveal` | ease-out `(0.16, 1, 0.30, 1)` | desbloqueios e Transformações |
| `reduced` | linear/ease-out, sem overshoot | Movimento Reduzido |

Não encadear mais de um overshoot no mesmo elemento. Tremor, câmera e parallax nunca participam de navegação ou leitura econômica.

## Estado do Ciclo e reentrada

A fase canônica troca imediatamente no domínio de entrada. O pseudo-rig Canvas observa o estado e se move em direção à pose vigente. Novo contato durante a animação:

1. interrompe o tween anterior no valor visual atual;
2. retargeta a pose em até um frame;
3. mantém a fase e o crédito definidos pelo domínio;
4. resume feedback numérico de Seven, ainda que efeitos decorativos sejam agrupados.

Até oito contatos válidos podem chegar em qualquer janela móvel de um segundo. Acima da capacidade de renderização, rastros decorativos são agrupados em janelas de 50 ms; poses e créditos não são inventados nem reordenados.

## Storyboard — Fase Six

**Duração nominal:** `150 ms`; resposta inicial até `50 ms` após o contato.

| Tempo | Mãos/Mascote | VFX | Semântica |
| ---: | --- | --- | --- |
| `0 ms` | fase troca para Six | registra ponto de contato | nenhuma Aura |
| `0–45 ms` | compressão do corpo `1.00 → 0.97`; L sobe, R desce | disco de contato expande `0 → 22 dp` | contato reconhecido |
| `45–110 ms` | mãos atingem poses Six; inclinação máxima `4°` | 2–4 sparks convergem para o Mascote | preparação |
| `110–150 ms` | settle sem pausa obrigatória | rastro perde alpha | aguarda Seven, sem recompensa |

**Movimento Reduzido:** pose Six aparece por troca estática ou crossfade em `100 ms`, com deslocamento residual de no máximo `8 dp`, escala fixa e um contorno curto no ponto de contato; sem sparks convergentes.

## Storyboard — Fase Seven

**Duração nominal:** `190 ms`; crédito e número começam no primeiro frame após confirmação do domínio.

| Tempo | Mãos/Mascote | VFX | Semântica |
| ---: | --- | --- | --- |
| `0 ms` | fase troca para Seven | registra ponto de contato | ciclo concluído |
| `0–55 ms` | L desce, R sobe; corpo expande `1.00 → 1.035` | anel de contato e flash localizado | Aura concedida |
| `35–125 ms` | mãos cruzam eixo de altura e atingem pose | ribbon curto do ponto ao Mascote; número nasce no centro seguro | valor vigente confirmado |
| `125–190 ms` | settle | 4–7 sparks afastam-se; número sobe até 18 dp | saída |

**Movimento Reduzido:** pose Seven aparece por troca estática ou crossfade em `100 ms`, com deslocamento residual de no máximo `8 dp`; o número aparece por fade de `120 ms` e a borda aumenta contraste por `100 ms`, sem escala ou ribbon.

Six nunca usa número de ganho, explosão radial, som resolutivo ou padrão tátil de confirmação. Seven nunca mostra valor diferente do crédito canônico completo; o Resto de Produção não é arredondado para feedback.

## Feedback no ponto de contato

- diâmetro inicial máximo: `48 dp` normal e `32 dp` reduzido;
- duração: `180 ms` normal, `120 ms` reduzido;
- respeita a coordenada do toque, mas não cria alvo persistente;
- toques sobre controles não emitem feedback de ciclo;
- somente o primeiro contato físico ativo recebe marcador; contatos simultâneos adicionais não geram feedback.

## Curva de intensidade audiovisual

A intensidade usa a média móvel exponencial de Ciclos concluídos/s, janela efetiva de `1,3 s`. É local, efêmera e não salva progresso.

| Faixa | Cadência observada | Motion/VFX | Música |
| --- | ---: | --- | --- |
| `I0` repouso | `<0,5 ciclo/s` | idle e até 8 partículas | base |
| `I1` pulso | `0,5–1,49` | rastros curtos, até 24 partículas | base + groove até `-12 dB` |
| `I2` fluxo | `1,5–2,49` | ribbon e fundo leve, até 48 partículas | groove até `-6 dB`, hype até `-18 dB` |
| `I3` ápice | `≥2,5` | halo completo, até 80 partículas | groove `0 dB`, hype até `-6 dB` |

- ataque `I0 → I3`: no mínimo `900 ms`;
- mudança entre faixas: histerese de `0,15 ciclo/s` por `250 ms`;
- release para `I0`: `1.800 ms` após cessarem ciclos;
- nenhum degrau mostra rótulo, medidor, contagem, multiplicador ou promessa;
- volume do bus master não sobe; camadas entram dentro do headroom do mix;
- Movimento Reduzido mantém a música dinâmica, mas fixa deslocamento visual em `I1` e permite até 12 partículas.

## Orçamento de partículas e flashes

| Perfil | Partículas vivas | Emissão Six | Emissão Seven | Fundo |
| --- | ---: | ---: | ---: | --- |
| normal `I0/I1` | `8/24` | `2` | `4` | sem emissão contínua em `I0` |
| normal `I2/I3` | `48/80` | `3` | `7` | até 10/s, distribuídas |
| reduzir flashes/partículas | `12` | `0–1` | `2` | estático |
| modo degradado | `20` | `1` | `3` | sem partículas de fundo |

Partículas têm vida máxima de `900 ms`; rastros, `260 ms`. Não usar emissão em tela inteira, estroboscopia, inversão de alto contraste ou alternância vermelho/branco. Pulsos luminosos localizados ficam abaixo de três por segundo, com opacidade máxima de 18% sobre a cena; o Marco 67 usa transição sustentada, não série de flashes. A opção Reduzir flashes e partículas também remove bloom pulsante.

## Catálogo de eventos

| Evento | Entrada | Duração/hold | Saída | Reduced |
| --- | --- | --- | --- | --- |
| compra `×1` | card comprime 2%, nó acende | `240 ms` | settle `120 ms` | borda + ícone por `160 ms` |
| compra `×10/MÁX` | um pulso consolidado | `320 ms` | resumo persistente | sem escala; atualização textual |
| Marco de Nível | anel no item | `600 ms` | dissolve `180 ms` | emblema estático `500 ms` |
| item desbloqueado | capa abre e conexão desenha | `700 ms` | settle `200 ms` | crossfade `200 ms` |
| item indisponível | card desloca `4 dp` uma vez | `180 ms` | retorna | borda/ícone de bloqueio, sem shake |
| equipar Aparência | wipe segundo geometria do Ramo | `360 ms` | crossfade `120 ms` | crossfade `180 ms` |
| Conquista | emblema sobe `12 dp` | hold `1.400 ms` | sai `240 ms` | toast estático dispensável |
| Transformação | storyboard específico | `1.800–2.600 ms` | dissolve para idle `400 ms` | crossfade ≤`200 ms` + estado/cartão estático dispensável |
| Ascensão | contração, horizonte abre, estado troca | `3.200 ms` máximo | novo idle `500 ms` | crossfade ≤`200 ms` + resumo estático dispensável |
| Marco 67 | mãos enquadram 67, cena intensifica | total lógico `6.700 ms` | release final `500 ms` incluído | placa 67 + Selo por fade ≤`200 ms`; hold estático dispensável |
| retorno offline | número conta uma vez | `600 ms` | resumo permanece | valor final aparece por fade |
| erro persistível | UI assume foco | até ação do jogador | sem efeito decorativo | idêntico |

Atualizações de valor não esperam o fim de qualquer linha. Compra em lote atravessando vários Marcos produz um único evento consolidado com todos os fatores listados pela UI.

## Transformações — storyboard de desbloqueio

| Forma | Sequência normal | Reveal canônico / evento total | Saída reduzida |
| --- | --- | ---: | --- |
| `FORM-01` First Glow | contorno expande → duas partículas surgem → gradiente assenta | `450 / 1.800 ms` | estado estático em crossfade `200 ms` |
| `FORM-02` Afterimage | segunda silhueta desloca → rastro curto assenta | `650 / 2.000 ms` | contorno duplo estático em crossfade ≤`200 ms` |
| `FORM-03` Neon Weather | frente diagonal atravessa → símbolos desaceleram → luz ambiente assenta | `900 / 2.200 ms` | fundo estático em crossfade ≤`200 ms` |
| `FORM-04` Skyline Pulse | pulso único cruza barras → horizonte assenta | `1.100 / 2.400 ms` | barras estáticas em crossfade ≤`200 ms` |
| `FORM-05` Aura Zenith | halo liga → piso responde → horizonte fecha a composição | `1.500 / 2.600 ms` | composição final estática em crossfade ≤`200 ms` |

O jogador pode dispensar a apresentação após `500 ms`; a forma já está salva e equipada independentemente disso. Se a Transformação ocorrer durante retorno ou compra, ela entra na fila de celebrações depois do resumo econômico.

## Marco 67

Storyboard normal de `6,7 s`:

1. `0–300 ms`: interrompe apenas efeitos decorativos; mãos vão à moldura 67.
2. `300–900 ms`: placa `67` e Selo entram; stinger/tátil são acionados uma vez.
3. `900–5.900 ms`: fundo permanece intensificado com deriva lenta; interação continua.
4. `5.900–6.700 ms`: placa recolhe, Selo vai para a Coleção e a intensidade retorna ao valor de cadência.

O evento não apresenta `+Aura`, multiplicador, baú, raridade ou botão de coleta. Se múltiplos Marcos forem cruzados, os registros são persistidos imediatamente. A primeira celebração é completa; as seguintes podem ser compactadas em cartões de `1,2 s` cada ou dispensadas em conjunto, sempre listando todos os Selos recebidos.

No modo reduzido, uma placa estática de alto contraste mostra `67` e a magnitude em texto de UI; o Selo aparece por fade de até `200 ms`. A janela lógica de 6,7 s é apenas um hold estático dispensável e nunca impede toque ou navegação.

## Ascensão

A animação só começa depois da confirmação e da transação persistida com sucesso. Se persistência falhar, nenhum horizonte abre e a UI mostra erro recuperável.

- `0–500 ms`: ambiente reduz a saturação; valores antigos permanecem legíveis;
- `500–1.300 ms`: fitas convergem para o núcleo, sem sugerir Aura sendo creditada;
- `1.300–2.200 ms`: horizonte de `FORM-05` abre e o estado reiniciado é aplicado visualmente;
- `2.200–3.200 ms`: Multiplicador resultante aparece na UI e a cena assenta.

Aparências e Transformações preservadas nunca desaparecem. Reduced usa troca de fundo por crossfade de até `200 ms` e uma placa textual estática, dispensável, com o multiplicador resultante.

## Haptics

Haptics são semânticos e independentes do áudio. O runtime solicita capacidades; aparelho sem amplitude programável usa o fallback do sistema. Durações são máximos de intenção, não promessas idênticas entre fabricantes.

| ID | Intenção Android | Padrão de referência | Fallback |
| --- | --- | --- | --- |
| `HAP-SIX` | impacto leve | `12 ms`, amplitude baixa | seleção leve |
| `HAP-SEVEN` | impacto médio | `22 ms`, amplitude média | impacto médio |
| `HAP-PURCHASE` | confirmação | `16 ms` + pausa `35 ms` + `24 ms` | uma confirmação |
| `HAP-UNLOCK` | ascendente | `14/18/24 ms`, pausas `30 ms` | duas pulsações |
| `HAP-TRANSFORM` | expansão | `24 ms` + pausa `70 ms` + `36 ms` | uma confirmação forte |
| `HAP-ACHIEVEMENT` | distintivo | `18 ms` + pausa `45 ms` + `18 ms` | duas leves |
| `HAP-ASCENSION` | evento máximo | `30 ms` + pausa `80 ms` + `45 ms` | uma forte |
| `HAP-67` | assinatura | `12 ms` leve + pausa `35 ms` + `12 ms` leve + pausa `120 ms` + `28 ms` médio | `2 leves + pausa + 1 médio` |
| `HAP-ERROR` | atenção | `30 ms`, nunca repetido automaticamente | alerta do sistema |

`HAP-67` implementa a assinatura canônica `curto-curto | pausa | médio`, dura menos de `250 ms`, não repete durante os 6,7 s e deve ser testado quanto a conforto. Sequências Six/Seven acima de 4 ciclos/s usam rate limit háptico: preservam Seven e omitem Six alternados, sem alterar estado ou áudio. Vibração desligada elimina todas as solicitações.

## Prioridade, filas e interrupções

Da maior para a menor prioridade:

1. diálogo do sistema, consentimento, diagnóstico, anúncio e conflito de sincronização;
2. erro de persistência ou confirmação destrutiva;
3. resultado econômico que exige decisão;
4. Transformação e Ascensão;
5. Marco 67;
6. Conquista, desbloqueio e Marco de Nível;
7. compra e equipar;
8. intensidade e idle.

Regras:

- prioridades 1–2 pausam áudio/eventos e descartam decoração; nunca são cobertas por celebração;
- a cena Jogar continua aceitando toque durante Marco 67 e toasts, salvo quando um diálogo modal legítimo está aberto;
- eventos 4–6 entram em fila persistível por ID; fechar o app preserva o registro, não a obrigação de repetir toda a animação;
- eventos duplicados de compra são consolidados por transação;
- navegar para outra área conclui imediatamente motion não essencial e mantém o estado final;
- voltar do background restaura a pose canônica em até `120 ms`, sem reproduzir contato antigo;
- áudio e haptics nunca são “recuperados” retroativamente após interrupção.

## Modos reduzidos

### Movimento Reduzido

Segue `a11y-matrix-v1`: remove tremor, zoom de câmera, squash do corpo, parallax, órbitas em movimento, trajetórias longas e overshoot. Mantém pose Six/Seven, contraste, emblema, valor e estado final por crossfade de `100–200 ms` ou troca estática; o deslocamento funcional residual não excede `8 dp` nem `200 ms`. Celebrações longas podem manter somente um cartão estático dispensável depois da transição.

### Reduzir flashes e partículas

Limita partículas vivas a 12 e sua opacidade a `0,35`, remove emissor contínuo, bloom pulsante e flashes de tela, e troca emissões por borda/forma estática. Pode ser usada independentemente de Movimento Reduzido.

### Desempenho degradado

É automático e não altera preferência do jogador: reduz partículas para 20, remove `BG-NEAR`, fixa parallax, agrupa rastros e mantém poses, valores e eventos. Não deve ser apresentado como modo de acessibilidade.

## QA de aceite

- contato reconhecido em até 50 ms no aparelho-alvo;
- Six não credita nem aparenta creditar Aura; Seven mostra o valor canônico;
- oito contatos por janela móvel de um segundo não corrompem fase nem bloqueiam UI;
- novo toque interrompe e retargeta sem salto de mais de 20% do palco;
- cadência audiovisual sobe e desce sem medidor ou mudança econômica;
- cada evento possui entrada, duração, saída e versão reduzida executável;
- flashes respeitam o limite e nenhuma informação depende de partículas;
- áudio, haptics, movimento e flashes podem ser desligados separadamente;
- filas sobrevivem a fechamento sem duplicar recompensa;
- TalkBack, modais e navegação têm prioridade sobre a cena;
- 60 fps alvo/30 fps piso e orçamentos são medidos em aparelho Android modesto.

## Riscos a validar na fatia vertical

Latência real de áudio/haptic, diferenças de vibração entre fabricantes, retarget do pseudo-rig Canvas em cadências extremas, custo combinado de fundos e skins, e legibilidade de celebrações sobre UI localizada. Falha nesses testes reduz espetáculo antes de alterar semântica ou estado.
