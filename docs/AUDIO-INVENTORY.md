# Aura Shift: Six Seven — Inventário de Áudio

> Contrato de runtime `audio-inventory-v2`. A trilha selecionada em 12 de julho
> de 2026 contém sete faixas completas e substitui as nove renderizações
> musicais procedurais no app. `Boss Shift` é o tema principal, mas participa
> do mesmo sorteio de abertura das outras seis faixas. Os 35 SFX da revisão
> anterior permanecem inalterados. O snapshot v1
> permanece apenas como metadado histórico dos SFX herdados; os binários das nove
> músicas substituídas foram removidos. O runtime usa `audio-manifest-v2.json`.

## Regra de estado

Fluxo permitido: `planned → generated → technical-review → candidate-reviewed
→ approved → integrated`. A automação desta pipeline termina em
`candidate-reviewed`; apenas uma decisão humana promove para `approved`.

Um item só chega a `approved` no runtime quando possui arquivo real, SHA-256,
proveniência e decisão humana. Aprovação de seleção não equivale a clearance
comercial: termos do gerador, auditoria independente de similaridade, fadiga e
teste Android continuam gates de publicação explícitos.

Estrutura produzida:

```text
assets/audio/music/
assets/audio/sfx/cycle/
assets/audio/sfx/ui/
assets/audio/sfx/events/
sources/audio/reaper/
sources/audio/recordings/
sources/audio/imported/chatgpt-2026-07-12/
masters/audio/
provenance/audio/
```

## Trilha selecionada

| Catálogo | ID estável | Título | Master/runtime | Marker de loop | Duração aprox. | Papel |
| ---: | --- | --- | --- | --- | ---: | --- |
| 1 | `MUS-BOSS-SHIFT` | Boss Shift | `mus_boss_shift.wav/.ogg` | não | 26,48 s | tema principal |
| 2 | `MUS-NEON-DRIFT-67` | Neon Drift 67 | `mus_neon_drift_67.wav/.ogg` | não | 25,60 s | playlist |
| 3 | `MUS-AURA-NO-RETROVISOR` | Aura no Retrovisor | `mus_aura_no_retrovisor.wav/.ogg` | não | 27,04 s | playlist |
| 4 | `MUS-PASSINHO-DE-AURA` | Passinho de Aura | `mus_passinho_de_aura.wav/.ogg` | não | 23,27 s | playlist |
| 5 | `MUS-SIXSEVEN-NO-FLUXO` | SixSeven no Fluxo | `mus_sixseven_no_fluxo.wav/.ogg` | não | 24,30 s | playlist |
| 6 | `MUS-PHASE-BLOOM` | Phase Bloom | `mus_phase_bloom.wav/.ogg` | não | 22,07 s | playlist |
| 7 | `MUS-RITUAL-6-7` | Ritual 6/7 | `mus_ritual_6_7.wav/.ogg` | não | 29,09 s | playlist |

Os WAVs recebidos são preservados byte a byte como fontes PCM24/44,1 kHz. O
importador gera masters PCM24/48 kHz por resample polifásico, apenas atenua cada
faixa para `-16 LUFS-I` e exporta Ogg/Vorbis q6. Não há compressão ou limiter na
conversão. As faixas são completas e não possuem markers de loop; o controlador
seleciona uma ordem aleatória por sessão e toca a faixa vigente em loop. Trocar
entre Jogar, Loja, Coleção e Ajustes avança para a próxima faixa com crossfade
equal-power de `1 s`; intensidade, duração e conclusão do arquivo não avançam a
sequência. As sete faixas são usadas uma vez antes de novo embaralhamento, sem
repetição imediata entre ciclos.

## Ciclo Six-Seven

| IDs | Arquivos runtime previstos | Qtde. | Vozes | Status |
| --- | --- | ---: | ---: | --- |
| `SFX-SIX-01..06` | `assets/audio/sfx/cycle/sfx_six_01..06.wav` | 6 | máx. 2 Six simultâneos | candidate-reviewed |
| `SFX-SEVEN-01..06` | `assets/audio/sfx/cycle/sfx_seven_01..06.wav` | 6 | máx. 3 Seven simultâneos | candidate-reviewed |

Masters correspondentes ficam em `masters/audio/sfx_six_nn.wav` e
`sfx_seven_nn.wav`. O runtime curto usa WAV PCM16 a 48 kHz, derivado com dither
determinístico dos masters PCM24, para evitar padding e reduzir latência. O
randomizador usa shuffle bag por família, sem repetição imediata. Seven tem
prioridade quando o limite global de quatro vozes de ciclo for atingido.

## UI e Loja

| ID | Arquivo runtime | Função | Duração máxima | Status |
| --- | --- | --- | ---: | --- |
| `SFX-UI-TAB` | `sfx_ui_tab.wav` | trocar área | `120 ms` | candidate-reviewed |
| `SFX-UI-OPEN` | `sfx_ui_open.wav` | abrir painel/folha | `180 ms` | candidate-reviewed |
| `SFX-UI-CLOSE` | `sfx_ui_close.wav` | fechar painel | `160 ms` | candidate-reviewed |
| `SFX-UI-TOGGLE-ON` | `sfx_ui_toggle_on.wav` | controle ativado | `140 ms` | candidate-reviewed |
| `SFX-UI-TOGGLE-OFF` | `sfx_ui_toggle_off.wav` | controle desativado | `140 ms` | candidate-reviewed |
| `SFX-UI-ERROR` | `sfx_ui_error.wav` | falha recuperável | `260 ms` | candidate-reviewed |
| `SFX-SHOP-PURCHASE` | `sfx_shop_purchase.wav` | compra `×1` | `350 ms` | candidate-reviewed |
| `SFX-SHOP-BATCH` | `sfx_shop_batch.wav` | compra `×10/MÁX` consolidada | `500 ms` | candidate-reviewed |
| `SFX-SHOP-UNAVAILABLE` | `sfx_shop_unavailable.wav` | requisito/saldo ausente | `260 ms` | candidate-reviewed |
| `SFX-SHOP-UNLOCK` | `sfx_shop_unlock.wav` | item desbloqueado | `900 ms` | candidate-reviewed |
| `SFX-SHOP-MILESTONE` | `sfx_shop_milestone.wav` | Marco de Nível | `700 ms` | candidate-reviewed |
| `SFX-COLLECTION-EQUIP` | `sfx_collection_equip.wav` | equipar aparência | `300 ms` | candidate-reviewed |
| `SFX-COLLECTION-HIDE` | `sfx_collection_hide.wav` | esconder aparência | `260 ms` | candidate-reviewed |

Masters usam o mesmo basename em WAV dentro de `masters/audio/`. Arquivos UI ficam em `assets/audio/sfx/ui/`; Loja/Coleção podem usar `ui/` por pertencerem ao mesmo bus.

## Eventos e progressão

| ID | Arquivo runtime | Função | Duração máxima | Status |
| --- | --- | --- | ---: | --- |
| `STG-FORM-01` | `stg_form_01.wav` | desbloqueio `FORM-01` | `1,2 s` | candidate-reviewed |
| `STG-FORM-02` | `stg_form_02.wav` | desbloqueio `FORM-02` | `1,5 s` | candidate-reviewed |
| `STG-FORM-03` | `stg_form_03.wav` | desbloqueio `FORM-03` | `1,8 s` | candidate-reviewed |
| `STG-FORM-04` | `stg_form_04.wav` | desbloqueio `FORM-04` | `2,1 s` | candidate-reviewed |
| `STG-FORM-05` | `stg_form_05.wav` | desbloqueio `FORM-05` | `2,4 s` | candidate-reviewed |
| `STG-ACHIEVEMENT` | `stg_achievement.wav` | qualquer Conquista | `900 ms` | candidate-reviewed |
| `STG-ASCENSION` | `stg_ascension.wav` | Ascensão persistida | `3,2 s` | candidate-reviewed |
| `STG-MARK-67` | `stg_mark_67.wav` | assinatura do Marco 67 | `1,8 s` | candidate-reviewed |
| `SFX-RETURN-OFFLINE` | `sfx_return_offline.wav` | retorno com produção base | `500 ms` | candidate-reviewed |
| `SFX-RETURN-BONUS` | `sfx_return_bonus.wav` | bônus confirmado após anúncio | `650 ms` | candidate-reviewed |

Os cinco stingers de Transformação compartilham materiais, mas são masters distintos. Conquistas usam um único stinger para as 13 entradas; nome e texto diferenciam o conteúdo. Todos os Marcos 67 usam a mesma assinatura, enquanto a UI e o Selo informam magnitude.

## Haptics versionados

Haptics não são arquivos de áudio. Permanecem no inventário para integração coordenada.

| ID | Evento | Fallback | Status |
| --- | --- | --- | --- |
| `HAP-SIX` | Fase Six | seleção leve | specified |
| `HAP-SEVEN` | Fase Seven | impacto médio | specified |
| `HAP-PURCHASE` | compra | confirmação única | specified |
| `HAP-UNLOCK` | desbloqueio | duas pulsações | specified |
| `HAP-TRANSFORM` | Transformação | confirmação forte | specified |
| `HAP-ACHIEVEMENT` | Conquista | duas leves | specified |
| `HAP-ASCENSION` | Ascensão | uma forte | specified |
| `HAP-67` | Marco 67 | `2 leves + pausa + 1 médio` | specified |
| `HAP-ERROR` | erro | alerta do sistema | specified |

Tempos e rate limits estão em `MOTION-VFX-BIBLE.md`.

## Presets culturais e de Técnicas

Estes presets são parâmetros de mixagem/runtime, não masters nem arquivos de áudio. Permanecem em estado `specified` até teste com os masters reais.

| IDs | Função | Fonte reutilizada | Status |
| --- | --- | --- | --- |
| `AUD-PRESET-POISE/MOTION/SIGNAL/SPECTRUM` | assinatura contextual dos territórios | UI, Coleção, música e eventos existentes | specified |
| `AUD-PRESET-TECH-01..06` | tratamentos graduais das Técnicas | `SFX-SIX-01..06` e `SFX-SEVEN-01..06` | specified |

O manifesto técnico registra parâmetros, equivalente mono, limites de pan/ganho e preset neutro de fallback. Nenhum preset cria som de item individual, altera economia ou aumenta a contagem fechada de masters.

## Contagens fechadas

| Grupo | Obrigatórios | Condicionais |
| --- | ---: | ---: |
| música/playlist | 7 | 0 |
| Six/Seven | 12 | 0 |
| UI/Loja/Coleção | 13 | 0 |
| eventos/progressão | 10 | 0 |
| **total de masters de áudio** | **42** | **0** |
| padrões hápticos | 9 | 0 |

Os sete IDs musicais substituem Base/Groove/Hype, Menu, Loja e os quatro mixes
I0–I3. Os binários e masters desse lote obsoleto foram removidos; o snapshot v1
permanece apenas como registro histórico e não é carregado pelo app.

## Registro de proveniência por item

Para cada ID obrigatório, criar `provenance/audio/<id-em-minusculas>.md` com:

| Campo | Obrigatório antes de `approved` |
| --- | --- |
| `id`, `revision`, `status` | sim |
| autor, editor, revisores e datas | sim |
| sessão/ferramenta e versão conforme a origem | sim quando disponível |
| gravações/fontes e cadeia de custódia | sim |
| licença/termos da ferramenta e materiais | gate comercial |
| briefing sanitizado recebido | música/stingers |
| prompt/modelo e referências declaradas | música; pendente se não entregue |
| WAV master e export runtime | sim |
| SHA-256 de fonte consolidada, master e runtime | sim |
| LUFS, dBTP, pico, canais e duração | sim |
| teste de mono/loop/latência/fadiga aplicável | sim |
| auditoria de similaridade e decisão | música/stingers |
| aprovação final | sim |

Foley com pessoas identificáveis exige termo de cessão; o baseline não grava voz. Termos da ferramenta são arquivados em PDF ou captura datada junto do recibo aplicável.

## Manifesto de runtime

O runtime carrega `assets/audio/audio-manifest-v2.json`, derivado de
`audio-candidate-manifest-v2.json` e da decisão
`assets/manifests/music-selection-approval-v1.json`. O v2 contém exatamente 42
IDs obrigatórios: sete Ogg musicais e 35 WAV PCM16 de SFX. Os manifests v1 não
são alterados nem carregados pelo app; documentam o lote procedural anterior.

## QA do pacote

### Técnico

- todos os masters em `48 kHz / 24-bit`, sem clipping;
- sete fontes originais com hashes preservados e sete runtimes normalizados;
- escolha inicial e ordem da sessão determinísticas sob fonte aleatória injetada;
- loop sem avanço por posição ou conclusão, troca por menu e shuffle bag 7/7 sem repetição imediata;
- crossfade entre menus sem clique perceptível; SFX curto em WAV PCM16 sem padding;
- mix mono sem cancelamento que remova kick, sub, Six ou Seven;
- limites de loudness/pico de `AUDIO-DIRECTION.md` aprovados;
- pausa, background, anúncio e retomada não duplicam música ou SFX.

### Experiência

- Six é leve e não sugere ganho; Seven confirma o ciclo;
- seis variações passam pelo shuffle bag sem repetição imediata;
- 20 minutos de Cadência de Referência e 10 de cadência alta sem fadiga bloqueadora;
- buses desligados individualmente não removem informação essencial;
- Transformação, Ascensão e Marco 67 são reconhecíveis entre si;
- Loja não usa sonoridade de dinheiro, aposta ou raridade;
- intensidade musical não muda Potência de Ciclo nem comunica multiplicador.

### Direitos

- licença da ferramenta válida na data do trabalho;
- fontes próprias e termos arquivados;
- prompt/modelo/referências do gerador arquivados quando fornecidos;
- auditoria adversarial documentada;
- qualquer candidato reconhecivelmente próximo marcado `rejected` e excluído do build.

## Gate de integração

O pacote aprovado é empacotado pelo Flutter e os sons possuem disparadores de
domínio para Ciclo, UI, Loja, Coleção, progressão, retorno, Ascensão e anúncios.
A abertura sorteia uma das sete faixas; cada menu mantém sua faixa em loop e uma
troca de menu consome a próxima entrada da sequência da sessão. A cadência
continua controlando apresentação/SFX, nunca música ou economia. A promoção de
release ainda exige termos comerciais do gerador, similaridade/fadiga e teste
Android de crossfade entre menus, latência, foco/retomada, além de 9/9 padrões
hápticos.
