# Aura Shift: Six Seven — Inventário de Áudio

> Contrato `audio-inventory-v1`. Todos os itens abaixo estão em estado `planned`; nenhum arquivo de áudio foi criado ou é apresentado como master final.

## Regra de estado

Fluxo permitido: `planned → composing/recording → edit → similarity-review → mix-review → approved → integrated`.

Um item só chega a `approved` quando possui master real, fonte editável, licença/proveniência, SHA-256, relatório técnico e aceite de similaridade. Nomes de arquivo e IDs são estáveis; revisões substituem o conteúdo e incrementam `revision`.

Estrutura prevista:

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
| `MUS-GAME-BASE` | `masters/audio/mus_game_base.wav` | `assets/audio/music/mus_game_base.ogg` | sim, sample-aligned | 52 compassos, ~91,76 s | planned |
| `MUS-GAME-GROOVE` | `masters/audio/mus_game_groove.wav` | `assets/audio/music/mus_game_groove.ogg` | sim, alinhado a Base | 52 compassos | planned |
| `MUS-GAME-HYPE` | `masters/audio/mus_game_hype.wav` | `assets/audio/music/mus_game_hype.ogg` | sim, alinhado a Base | 52 compassos | planned |
| `MUS-MENU` | `masters/audio/mus_menu.wav` | `assets/audio/music/mus_menu.ogg` | sim | 26 compassos, ~45,88 s | planned |
| `MUS-SHOP` | `masters/audio/mus_shop.wav` | `assets/audio/music/mus_shop.ogg` | sim | 26 compassos | planned |

Contingência produzida somente se stems apresentarem drift:

| ID | Conteúdo | Status |
| --- | --- | --- |
| `MUS-GAME-I0-MIX` | Base pré-renderizada | conditional |
| `MUS-GAME-I1-MIX` | Base + Groove leve | conditional |
| `MUS-GAME-I2-MIX` | Base + Groove + Hype leve | conditional |
| `MUS-GAME-I3-MIX` | mix completo com headroom | conditional |

Os quatro mixes condicionais não ampliam conteúdo musical; são renders alternativos da mesma sessão.

## Ciclo Six-Seven

| IDs | Arquivos runtime previstos | Qtde. | Vozes | Status |
| --- | --- | ---: | ---: | --- |
| `SFX-SIX-01..06` | `assets/audio/sfx/cycle/sfx_six_01..06.ogg` | 6 | máx. 2 Six simultâneos | planned |
| `SFX-SEVEN-01..06` | `assets/audio/sfx/cycle/sfx_seven_01..06.ogg` | 6 | máx. 3 Seven simultâneos | planned |

Masters correspondentes ficam em `masters/audio/sfx_six_nn.wav` e `sfx_seven_nn.wav`. O randomizador usa shuffle bag por família, sem repetição imediata. Seven tem prioridade quando o limite global de quatro vozes de ciclo for atingido.

## UI e Loja

| ID | Arquivo runtime | Função | Duração máxima | Status |
| --- | --- | --- | ---: | --- |
| `SFX-UI-TAB` | `sfx_ui_tab.ogg` | trocar área | `120 ms` | planned |
| `SFX-UI-OPEN` | `sfx_ui_open.ogg` | abrir painel/folha | `180 ms` | planned |
| `SFX-UI-CLOSE` | `sfx_ui_close.ogg` | fechar painel | `160 ms` | planned |
| `SFX-UI-TOGGLE-ON` | `sfx_ui_toggle_on.ogg` | controle ativado | `140 ms` | planned |
| `SFX-UI-TOGGLE-OFF` | `sfx_ui_toggle_off.ogg` | controle desativado | `140 ms` | planned |
| `SFX-UI-ERROR` | `sfx_ui_error.ogg` | falha recuperável | `260 ms` | planned |
| `SFX-SHOP-PURCHASE` | `sfx_shop_purchase.ogg` | compra `×1` | `350 ms` | planned |
| `SFX-SHOP-BATCH` | `sfx_shop_batch.ogg` | compra `×10/MÁX` consolidada | `500 ms` | planned |
| `SFX-SHOP-UNAVAILABLE` | `sfx_shop_unavailable.ogg` | requisito/saldo ausente | `260 ms` | planned |
| `SFX-SHOP-UNLOCK` | `sfx_shop_unlock.ogg` | item desbloqueado | `900 ms` | planned |
| `SFX-SHOP-MILESTONE` | `sfx_shop_milestone.ogg` | Marco de Nível | `700 ms` | planned |
| `SFX-COLLECTION-EQUIP` | `sfx_collection_equip.ogg` | equipar aparência | `300 ms` | planned |
| `SFX-COLLECTION-HIDE` | `sfx_collection_hide.ogg` | esconder aparência | `260 ms` | planned |

Masters usam o mesmo basename em WAV dentro de `masters/audio/`. Arquivos UI ficam em `assets/audio/sfx/ui/`; Loja/Coleção podem usar `ui/` por pertencerem ao mesmo bus.

## Eventos e progressão

| ID | Arquivo runtime | Função | Duração máxima | Status |
| --- | --- | --- | ---: | --- |
| `STG-FORM-01` | `stg_form_01.ogg` | desbloqueio `FORM-01` | `1,2 s` | planned |
| `STG-FORM-02` | `stg_form_02.ogg` | desbloqueio `FORM-02` | `1,5 s` | planned |
| `STG-FORM-03` | `stg_form_03.ogg` | desbloqueio `FORM-03` | `1,8 s` | planned |
| `STG-FORM-04` | `stg_form_04.ogg` | desbloqueio `FORM-04` | `2,1 s` | planned |
| `STG-FORM-05` | `stg_form_05.ogg` | desbloqueio `FORM-05` | `2,4 s` | planned |
| `STG-ACHIEVEMENT` | `stg_achievement.ogg` | qualquer Conquista | `900 ms` | planned |
| `STG-ASCENSION` | `stg_ascension.ogg` | Ascensão persistida | `3,2 s` | planned |
| `STG-MARK-67` | `stg_mark_67.ogg` | assinatura do Marco 67 | `1,8 s` | planned |
| `SFX-RETURN-OFFLINE` | `sfx_return_offline.ogg` | retorno com produção base | `500 ms` | planned |
| `SFX-RETURN-BONUS` | `sfx_return_bonus.ogg` | bônus confirmado após anúncio | `650 ms` | planned |

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

O desenvolvimento gera `assets/audio/audio-manifest-v1.json` somente a partir de itens `approved`. Exemplo de esquema, ainda sem alegar arquivo real:

```json
{
  "id": "SFX-SEVEN-01",
  "revision": 1,
  "path": "audio/sfx/cycle/sfx_seven_01.ogg",
  "bus": "cycle",
  "channels": 1,
  "sampleRate": 48000,
  "loop": false,
  "lufs": null,
  "truePeakDbtp": null,
  "sha256": "TO_BE_FILLED_AFTER_MASTER_APPROVAL",
  "licenseRecord": "provenance/audio/sfx-seven-01.md"
}
```

Campos técnicos nulos e hashes placeholder são aceitos somente neste exemplo de planejamento, nunca no manifesto do build candidato.

## QA do pacote

### Técnico

- todos os masters em `48 kHz / 24-bit`, sem clipping;
- stems com mesmo primeiro sample e número de samples;
- loops sem clique em dez repetições consecutivas;
- Ogg sem padding perceptível; SFX curto migrado para WAV se latência reprovar;
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

O inventário está documentalmente estável agora, mas o pacote não está produzido. Integração de desenvolvimento pode começar com stubs silenciosos explicitamente técnicos apenas em builds internos; esses stubs não são assets e não podem ser promovidos. O build candidato exige 40/40 masters obrigatórios em `approved` ou `integrated`, 9/9 padrões hápticos testados e zero item com proveniência pendente.
