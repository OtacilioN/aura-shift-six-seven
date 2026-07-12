# Aura Shift: Six Seven — Direção de Áudio

> Status: direção de runtime `audio-v2`. Em 12 de julho de 2026, a decisão
> humana substituiu as nove renderizações musicais procedurais por sete faixas
> completas geradas via ChatGPT e selecionadas pelo usuário. `Boss Shift` é o
> tema principal. Os 35 SFX anteriores permanecem. Termos comerciais,
> similaridade/fadiga e teste Android continuam gates antes da publicação.

## Objetivos

- sustentar repetição longa sem fadiga ou aumento indefinido de volume;
- dar identidades complementares e inequívocas a Six e Seven;
- unir jogo, Loja e menus em uma composição original;
- intensificar a cena sem sugerir combo ou recompensa adicional;
- funcionar em alto-falantes móveis modestos, mono e fones;
- preservar proveniência, fontes editáveis e licença comercial verificável.

## Briefing sanitizado de composição

Este é o único briefing musical que o compositor recebe:

> Criar uma peça eletrônica instrumental original, corporal e elástica, a `136 BPM`, `4/4`, com frase macro própria de 13 compassos organizada como seis compassos de impulso e sete de resposta. O groove deve funcionar em alto-falante pequeno, aceitar três camadas perfeitamente alinhadas e evitar protagonista melódico reconhecível. A energia nasce de síncopes percussivas, silêncio, sub grave curto, texturas granuladas e stabs harmônicos mínimos. O resultado precisa soar contemporâneo e brincalhão, não agressivo, sombrio, nostálgico ou épico. Não usar voz, contagem falada, sample identificável, progressão ou timbre-assinatura de qualquer obra, artista ou cena específica.

O briefing não contém letra, melodia, harmonia, arranjo, sample, descrição de timbre exclusivo ou sequência da obra associada ao meme. A divisão 6+7 é uma regra estrutural original do jogo, não uma transcrição.

Este briefing documenta o lote procedural v1 preservado. Os prompts, modelo e
sessão que originaram as sete faixas selecionadas não acompanharam os WAVs e
não são inferidos aqui; a proveniência v2 registra essa ausência explicitamente.

## Influências abstratas e limites

Funk brasileiro, brega funk de Recife, phonk e trap orientam energia, síncope, peso e economia de elementos. O tratamento reconhece o brega funk como expressão cultural recifense e evita reduzir a cena a caricatura, “som exótico”, preset ou efeito cômico.

São proibidos:

- música, stem, vocal, letra, contagem ou sample da referência;
- imitação de artista, produtor, voz, beat, melodia, progressão ou timbre-assinatura;
- sample pack sem licença comercial comprovável e arquivo de licença preservado;
- prompt com nome de artista, faixa, personagem ou “no estilo de”;
- geração/edição que receba a gravação de referência como entrada;
- master sem fonte editável, licença, hash e auditoria de similaridade.

## Instrumentação

| Família | Papel | Construção permitida | Restrições |
| --- | --- | --- | --- |
| kick | centro rítmico curto | síntese senoidal + transient próprio | cauda <180 ms; sem clipping destrutivo |
| sub | peso legível em mono | seno/triângulo sintetizado | fundamental entre 48–72 Hz; harmônico audível em celular |
| caixa/clap | resposta seca | síntese de ruído + foley próprio | estéreo estreito; sem sample reconhecível |
| hats/shakers | movimento | ruído filtrado e gravação própria do responsável humano | variação de velocity; agudos controlados |
| perc orgânica | identidade corporal | palmas, batidas em superfícies e objetos gravados pelo responsável humano da produção | cadeia de gravação; cessão se houver terceiro |
| stab | marca harmônica curta | sintetizador subtrativo/FM | até três alturas por seção; sem hook cantável |
| textura | cola e transição | ruído granular/síntese | não carregar melodia |
| impacto de Aura | eventos e Seven | síntese + foley próprio | não soar como moeda, slot ou loot |

Não há vocal, canto, fala, tag de produtor ou imitação de instrumento cultural específico. O mix precisa continuar inteligível somado em mono.

## Paleta sonora

- transientes arredondados, secos e com pouco reverb;
- sub grave curto, com harmônico médio que sobreviva a alto-falante móvel;
- médios elásticos entre `500 Hz–2,5 kHz` para Six/Seven;
- agudos macios, sem hats contínuos acima de fadiga;
- espaço negativo em pelo menos um tempo de cada frase curta;
- reverbs de sala curta até `450 ms`; eventos máximos podem usar cauda de `1,2 s`;
- nenhum som de moeda, caixa registradora, sino de jackpot ou sirene de cassino.

### Assinaturas dos territórios culturais

As identidades de P04 são tratamentos autorais, não referências de gênero nem vantagens. Elas usam síntese, foley e DSP da própria sessão; não criam música, sample ou master por item.

| Território | Vocabulário | Aplicação | Limite |
| --- | --- | --- | --- |
| Poise | impacto seco, ar curto, centro estável | acentos de menu/coleção e filtros sutis ao equipar Poise | sem “som de luxo”, voz ou brilho de moeda |
| Motion | percussão corporal sintetizada, grave elástico curto | groove e resposta amortecida ao equipar Motion | sem copiar passinho, beat, artista ou cena real |
| Signal | tick digital, ruído tonal, chamada estéreo moderada | texturas e resposta filtrada ao equipar Signal | sem imitar notificação, interface ou marca existente |
| Spectrum | um gesto de cada território em equilíbrio | Convergências e culminação de `FORM-05` | mesma duração/loudness; nunca comunica ramo superior |

Loja e Coleção aplicam esses tratamentos como presets determinísticos sobre os
assets neutros já inventariados. O equivalente mono e visual permanece
completo; direção estéreo nunca é portadora de estado. Presets não são arquivos
nem ampliam os 42 assets obrigatórios do contrato v2.

## Trilha principal e playlist

As sete músicas são mixes completos independentes e nunca são sobrepostas como
stems. A playlist canônica é:

1. `Boss Shift` — tema principal e primeira faixa de toda sessão;
2. `Neon Drift 67`;
3. `Aura no Retrovisor`;
4. `Passinho de Aura`;
5. `SixSeven no Fluxo`;
6. `Phase Bloom`;
7. `Ritual 6/7`.

Após `Ritual 6/7`, o ciclo volta para `Boss Shift`. Uma única voz musical fica
ativa em condições normais; duas vozes coexistem somente durante o crossfade
equal-power de `1 s`. O avanço usa a posição real do player aproximadamente um
segundo antes do fim e a conclusão da faixa como fallback idempotente. Callback
atrasado de uma faixa antiga não pode avançar a playlist duas vezes.

As faixas não usam `ReleaseMode.loop`. Navegar entre Jogar, Loja, Coleção e
Ajustes mantém música e posição; cadência I0–I3 não troca faixa. Diálogos e
consentimentos atenuam música em `-8 dB`; anúncio/background pausam os buses e o
retorno faz fade-in de `400 ms`, sem reiniciar nem pular a faixa corrente.

## Six e Seven

Cada fase possui exatamente seis variações. Um shuffle bag toca todas antes de repetir, impede repetição imediata e evita sequência de altura sempre ascendente.

### Six — preparação

- duração `70–110 ms`;
- transiente macio, centro tonal médio-baixo;
- três famílias tímbricas × duas articulações;
- sem cauda resolutiva, número, brilho tonal ou impacto grave;
- ganho aleatório máximo `±0,6 dB`; pitch aleatório máximo `±12 cents`.

### Seven — conclusão

- duração `90–150 ms`;
- impacto complementar com corpo médio e cauda curta de Aura;
- seis variações pareadas conceitualmente às de Six, mas seleção independente;
- confirmação clara sem sino de moeda;
- ganho aleatório máximo `±0,5 dB`; pitch aleatório máximo `±10 cents`.

Cadência alta pode abrir discretamente filtro/camada de textura já presente; não transpõe continuamente, não eleva master e não cria uma “escada” de recompensa. Acima de oito SFX de ciclo/s, o mixer aplica voice limit: prioriza Seven, reduz Six sobreposto e mantém no máximo quatro vozes simultâneas.

### Feedback das Técnicas

As seis Técnicas reutilizam as 12 variações Six/Seven e presets versionados; não exigem um master novo por Técnica. O feedback muda somente apresentação após o desbloqueio e nunca Potência, cadência aceita ou quantidade de créditos.

| Técnica | Tratamento de áudio | Redundância/risco |
| --- | --- | --- |
| `TECH-01` Switch Stance | par base seco “tak/tum”, sem resolução em Six | pose e contorno identificam a Técnica |
| `TECH-02` Counterflow | respostas L/R limitadas a 15% de pan, com soma mono aprovada | direção não carrega informação |
| `TECH-03` Ghost Timing | uma early reflection até `-18 dB`, cauda total dentro do limite da variação | versão reduzida/mono mantém contorno visual |
| `TECH-04` Double Take | ataque visual duplo; áudio usa um pré-transiente leve e uma única resolução Seven | QA deve impedir impressão de duas recompensas |
| `TECH-05` Zero-Drag | envelope 10% mais curto, sem antecipar o crédito | não promete reduzir limite técnico |
| `TECH-06` Perfect Shift | harmônico filtrado do próprio Seven, sem novo acorde ou hook | arco visual confirma o estado |

Os presets são parâmetros de runtime a registrar no manifesto técnico. Desbloquear uma Técnica nunca troca música nem dispara stinger por si só; o evento de desbloqueio continua usando a família comum aprovada.

## Eventos

| Família | Direção | Duração máxima |
| --- | --- | ---: |
| compra | toque seco + confirmação suave | `350 ms` |
| compra em lote | mesma assinatura com corpo maior, uma vez | `500 ms` |
| indisponível/erro | ruído abafado descendente curto | `260 ms` |
| item desbloqueado | três pulsos que abrem espaço | `900 ms` |
| equipar/ocultar | wipe filtrado curto | `300 ms` |
| Marco de Nível | dobra tímbrica única, sem jackpot | `700 ms` |
| Transformação `01–05` | cinco stingers da mesma família, complexidade crescente | `1,2–2,4 s` |
| Conquista | emblema sonoro curto | `900 ms` |
| Ascensão | contração + abertura + resolve original | `3,2 s` |
| Marco 67 | seis ticks leves + um impacto final original e cauda, acionados uma vez | `1,8 s` |
| retorno offline | textura de chegada; valor comunicado visualmente | `500 ms` |

Transformações não usam versões aceleradas da música principal. `FORM-05` e Ascensão compartilham paleta, mas têm finais distintos: Transformação afirma estado permanente; Ascensão confirma uma transação já persistida.

O Marco 67 intensifica a mixagem por `6,7 s`, porém seu stinger toca uma única vez. Ele não inclui `+Aura`, contagem monetária ou resolução de prêmio.

## Haptics e redundância

Os padrões táteis canônicos e seus fallbacks estão em `MOTION-VFX-BIBLE.md`: `HAP-SIX`, `HAP-SEVEN`, compra, desbloqueio, Transformação, Conquista, Ascensão, Marco 67 e erro. Áudio e vibração podem ser desligados separadamente; toda semântica possui equivalente visual.

Som nunca determina timing econômico. Se um arquivo não carregar ou o app estiver silenciado, fase, crédito, compra e progresso continuam completos.

## Mixagem e fadiga

- buses independentes: `music`, `cycle`, `ui`, `event`;
- sliders de Música, Efeitos e Vibração separados; `cycle/ui/event` obedecem Efeitos;
- master de música: alvo `-16 LUFS-I`, pico verdadeiro até `-1 dBTP`;
- masters de stinger: alvo entre `-18 e -14 LUFS-I` conforme duração, pico até `-1 dBTP`;
- SFX individuais: pico até `-3 dBFS`; mix concorrente precisa manter `-1 dBTP` no master;
- duck de música por Seven: máximo `1,5 dB` por `80 ms`; eventos máximos, máximo `4 dB` por até `1,2 s`;
- nenhum bus ganha volume com cadência; o headroom existe desde `I0`;
- limiter é proteção, não fonte de loudness;
- teste de fadiga: 20 minutos contínuos na Cadência de Referência, 10 minutos em cadência alta e 30 minutos de menu/Loja, em celular e fones;
- critério: sem clipping, pumping audível, repetição imediata, agudo doloroso, sub que mascare feedback ou necessidade de reduzir volume para tolerar Six/Seven.

## Especificações de master e runtime

| Entrega | Formato | Sample rate/bit depth | Canais | Observação |
| --- | --- | --- | --- | --- |
| fonte musical preservada | WAV PCM | `44,1 kHz / 24-bit` | estéreo | cópia byte a byte do arquivo selecionado |
| master musical derivado | WAV PCM | `48 kHz / 24-bit` | estéreo | resample 160/147 e atenuação para `-16 LUFS-I` |
| SFX master | WAV PCM | `48 kHz / 24-bit` | mono preferencial | cauda completa |
| runtime música | Ogg Vorbis | `48 kHz`, qualidade alvo `q6` | estéreo | faixa completa `non-loop` |
| runtime SFX | Ogg Vorbis ou WAV | `48 kHz` | mono preferencial | escolher por latência/tamanho na prova |

Não usar MP3 em loops por padding. O codec final de SFX é decidido por teste de latência no Android, sem mudar IDs.

## Ferramentas e licença

Pipeline padrão previsto:

- **DAW:** REAPER 7.x, com licença Cockos adequada à situação comercial da equipe adquirida antes da produção final;
- **processamento:** plugins nativos ReaPlugs/JSFX e síntese construída no projeto;
- **edição/QA:** ferramentas open source podem analisar loudness, fase, hash e loops, com versão registrada;
- **fontes:** síntese original e foley gravado pelo responsável humano da produção; agentes apoiam briefing, documentação e QA, mas não fingem captura física; sample packs externos são proibidos no baseline para simplificar direitos;
- **IA generativa musical:** usada nas sete faixas selecionadas, conforme declaração do usuário (`ChatGPT`). Os arquivos não contêm prompt, modelo, sessão ou licença embutidos; esses registros e a elegibilidade comercial continuam pendentes. A decisão humana aprova a seleção e integração, não substitui clearance ou auditoria de similaridade.

Este documento não afirma que uma licença já foi comprada. O recibo, versão dos termos e elegibilidade ficam no dossiê de proveniência antes que qualquer master receba status `approved`.

## Proveniência e auditoria de similaridade

Para cada master e candidato, preservar:

- ID, versão, data, autor/editor e responsáveis pela aprovação;
- briefing recebido e declaração de isolamento da referência;
- fonte original, prompt/sessão quando disponíveis e cadeia de processamento;
- ferramenta, versão, licença, recibo/termos e origem de qualquer material;
- render WAV, export runtime e hashes SHA-256;
- relatório de loudness, pico, mono, playback/crossfade e fadiga;
- comparação adversarial com referência e decisão `reject/revise/approve`;
- histórico de alterações posterior.

A auditoria compara impressão global, ritmo, motivo, harmonia, arranjo, timbre e sequência. Qualquer reconhecimento plausível de obra ou artista reprova a versão, ainda que não exista sample idêntico. O processo reduz risco e não substitui parecer jurídico.

## Inventário e gate

`AUDIO-INVENTORY.md` lista todos os IDs, masters, exports, ordem da playlist,
variações e registros. Planejamento fechado não equivale a pacote produzido. O
gate de integração exige arquivo real, fonte, hash e decisão humana; licença,
similaridade e aparelho continuam gates de publicação separados.

## Riscos residuais

- atraso ou duplicação de callbacks entre posição, conclusão e crossfade;
- latência de SFX Ogg em aparelhos modestos;
- inconsistência de loudness entre alto-falantes fabricantes;
- fadiga de Six/Seven em cadências extremas;
- disponibilidade, termos comerciais e metadados ausentes do gerador.

A fatia vertical testa esses riscos. Se Ogg falhar no Android, a música pode
migrar para outro codec sem mudar IDs/ordem; se Ogg atrasar em SFX, sons curtos
continuam em WAV. Nenhuma contingência altera identidade ou economia.
