# Aura Shift: Six Seven — Inventário de Áudio

> Contrato `audio-inventory-v1`. Os 40 itens obrigatórios e os quatro mixes
> condicionais possuem candidatos reais, fontes procedurais, hashes e
> proveniência. O manifesto técnico em
> `assets/audio/audio-candidate-manifest-v1.json` é a fotografia executável do
> lote. A decisão humana de 10 de julho de 2026 está no derivado
> `assets/audio/audio-manifest-v1.json`; o teste em aparelho permanece gate de
> publicação, não é ocultado pela promoção.

## Regra de estado

Fluxo permitido: `planned → generated → technical-review → candidate-reviewed
→ approved → integrated`. A automação desta pipeline termina em
`candidate-reviewed`; apenas uma decisão humana promove para `approved`.

Um item só chega a `approved` quando possui master real, fonte editável, licença/proveniência, SHA-256, relatório técnico e aceite de similaridade. Nomes de arquivo e IDs são estáveis; revisões substituem o conteúdo e incrementam `revision`.

Estrutura produzida:

```text
assets/audio/music/
assets/audio/sfx/cycle/
assets/audio/sfx/ui/
assets/audio/sfx/events/
sources/audio/reaper/
sources/audio/recordings/
masters/audio/
provenance/audio/
```

## Música e mixes

| ID estável | Master previsto | Runtime previsto | Loop | Duração musical | Status |
| --- | --- | --- | --- | ---: | --- |
| `MUS-GAME-BASE` | `masters/audio/mus_game_base.wav` | `assets/audio/music/mus_game_base.ogg` | sim, sample-aligned | 52 compassos, ~91,76 s | candidate-reviewed |
| `MUS-GAME-GROOVE` | `masters/audio/mus_game_groove.wav` | `assets/audio/music/mus_game_groove.ogg` | sim, alinhado a Base | 52 compassos | candidate-reviewed |
| `MUS-GAME-HYPE` | `masters/audio/mus_game_hype.wav` | `assets/audio/music/mus_game_hype.ogg` | sim, alinhado a Base | 52 compassos | candidate-reviewed |
| `MUS-MENU` | `masters/audio/mus_menu.wav` | `assets/audio/music/mus_menu.ogg` | sim | 26 compassos, ~45,88 s | candidate-reviewed |
| `MUS-SHOP` | `masters/audio/mus_shop.wav` | `assets/audio/music/mus_shop.ogg` | sim | 26 compassos | candidate-reviewed |

Contingência produzida somente se stems apresentarem drift:

| ID | Conteúdo | Status |
| --- | --- | --- |
| `MUS-GAME-I0-MIX` | Base pré-renderizada | candidate-reviewed/conditional |
| `MUS-GAME-I1-MIX` | Base + Groove leve | candidate-reviewed/conditional |
| `MUS-GAME-I2-MIX` | Base + Groove + Hype leve | candidate-reviewed/conditional |
| `MUS-GAME-I3-MIX` | mix completo com headroom | candidate-reviewed/conditional |

Os quatro mixes condicionais não ampliam conteúdo musical; são renders alternativos da mesma sessão.

Na revisão 3, todos os nove loops musicais receberam taper squared-sine de
`1.024` frames por lado em uma fronteira de espaço negativo. No CoreAudio, 9/9
mantiveram o número de frames e passaram o gate de seam abaixo de `-24 dBFS`;
os 9/9 ainda apresentam offset de decode de `+128` frames e, portanto, não são
declarados sample-exact. A escuta e o loop no Android continuam obrigatórios.

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
| música/mixes | 5 | 4 |
| Six/Seven | 12 | 0 |
| UI/Loja/Coleção | 13 | 0 |
| eventos/progressão | 10 | 0 |
| **total de masters de áudio** | **40** | **4** |
| padrões hápticos | 9 | 0 |

Produzir arquivos além destes 40 masters obrigatórios não faz parte do MVP sem Substituição de Escopo. Revisões e formatos alternativos do mesmo ID não contam como conteúdo novo.

## Registro de proveniência por item

Para cada ID obrigatório, criar `provenance/audio/<id-em-minusculas>.md` com:

| Campo | Obrigatório antes de `approved` |
| --- | --- |
| `id`, `revision`, `status` | sim |
| autor, editor, revisores e datas | sim |
| sessão REAPER e versão | sim |
| gravações/fontes e cadeia de custódia | sim |
| licença da DAW, plugins e materiais | sim |
| briefing sanitizado recebido | música/stingers |
| declaração de ausência de referência no compositor | música/stingers |
| WAV master e export runtime | sim |
| SHA-256 de fonte consolidada, master e runtime | sim |
| LUFS, dBTP, pico, canais e duração | sim |
| teste de mono/loop/latência/fadiga aplicável | sim |
| auditoria de similaridade e decisão | música/stingers |
| aprovação final | sim |

Foley com pessoas identificáveis exige termo de cessão; o baseline não grava voz. Termos da ferramenta são arquivados em PDF ou captura datada junto do recibo aplicável.

## Manifesto de runtime

O lote produzido usa
`assets/audio/audio-candidate-manifest-v1.json`. Ele registra os 44 IDs,
revisão, estado, master, runtime, SHA-256, métricas, fonte procedural e
proveniência sem campos placeholder. As nove faixas musicais usam Ogg/Vorbis;
os 35 SFX usam WAV PCM16. O nome reservado `audio-manifest-v1.json` só deve ser
criado quando uma decisão humana promover os itens obrigatórios para
`approved`.

A decisão humana foi registrada em 10 de julho de 2026. O candidato acima
continua imutável; `tools/assets/promote_approved_assets.py` deriva o contrato
aprovado `assets/audio/audio-manifest-v1.json`, que é o manifesto carregado pelo
runtime. As linhas `candidate-reviewed` deste inventário descrevem a evidência
técnica de origem, não o estado atual do derivado aprovado.

## QA do pacote

### Técnico

- todos os masters em `48 kHz / 24-bit`, sem clipping;
- stems com mesmo primeiro sample e número de samples;
- loops sem clique em dez repetições consecutivas;
- Ogg musical sem clique perceptível; SFX curto em WAV PCM16 sem padding;
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
- nenhum nome de artista/referência em prompt ou sessão de composição;
- auditoria adversarial documentada;
- qualquer candidato reconhecivelmente próximo marcado `rejected` e excluído do build.

## Gate de integração

O pacote aprovado é empacotado pelo Flutter e os sons possuem disparadores de
domínio para Ciclo, UI, Loja, Coleção, progressão, retorno, Ascensão e anúncios.
Base/Groove/Hype formam a estratégia principal em camadas; os quatro mixes
condicionais continuam a alternativa técnica de fallback, não conteúdo
adicional. A promoção de release ainda exige teste Android de
loop/latência/foco/retomada e 9/9 padrões hápticos em aparelho.
