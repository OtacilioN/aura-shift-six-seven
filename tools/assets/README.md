# Pipelines de áudio

## Snapshot procedural v1

Esta pasta produz candidatos de áudio originais por síntese determinística. A
pipeline não baixa, lê nem transforma gravações externas; não usa voz, foley,
sample pack, DAW ou modelo generativo. Os resultados permanecem com o status
`candidate-reviewed`: revisão automatizada não equivale a aprovação musical,
jurídica, humana ou em aparelho real. Esse lote permanece preservado como
snapshot histórico e não é mais a música carregada pelo app.

## Ambiente isolado

```bash
python3 -m venv .asset-venv
.asset-venv/bin/python -m pip install pip==26.1.2
.asset-venv/bin/python -m pip install -r tools/assets/requirements-audio.txt
```

As versões estão fixadas. Para uma reprodução de arquivo idêntica, também
registre arquitetura, Python, libsndfile e sistema operacional, pois o encoder
Vorbis fornecido pelo wheel de SoundFile pode mudar entre plataformas.

## Gerar e revisar o snapshot histórico

```bash
.asset-venv/bin/python tools/assets/generate_audio_assets.py
.asset-venv/bin/python tools/assets/review_audio_assets.py
```

O gerador lê `sources/audio/procedural/score-v1.json`, renderiza masters WAV
PCM 48 kHz/24-bit, nove exports musicais Ogg/Vorbis VBR q6 e 35 exports curtos
WAV PCM16 com dither determinístico. O revisor reabre todos os arquivos,
recalcula hashes e métricas, compara duas renderizações integrais independentes
e falha com código não zero quando um gate automatizável reprova.

Estes comandos preservam somente a reprodutibilidade histórica do lote v1 e
**não devem ser executados para montar o pacote atual**: eles recriam as nove
músicas substituídas. O pipeline ativo parte do manifesto v2 com sete músicas
selecionadas e 35 efeitos.

Saídas principais:

- `masters/audio/`: 35 masters de SFX ainda aproveitados; os nove masters musicais v1 foram removidos;
- `assets/audio/`: 35 SFX ainda aproveitados; os nove exports musicais v1 foram removidos;
- `provenance/audio/`: registro por ID, sem alegação de aprovação;
- `reports/audio-generation-report.md`: resultado consolidado e limitações;
- `reports/audio-review-results.json`: evidência estruturada de QA;
- `reports/audio-listening-sheet.html`: 42 players ativos (sete músicas e 35
  SFX) e roteiro do gate humano, sem promover nenhum candidato.

Não renomeie o manifesto candidato para `audio-manifest-v1.json`. O contrato do
projeto reserva esse nome ao conjunto aprovado, e esta pipeline não realiza a
escuta humana, a auditoria adversarial de similaridade nem o teste Android.

## Trilha selecionada v2

Os sete WAVs escolhidos pelo usuário entram por um importador separado; não são
tratados como se tivessem sido gerados pelo pipeline procedural:

```bash
.asset-venv/bin/python tools/assets/import_selected_music.py
```

O comando valida os sete hashes esperados, preserva os originais em
`sources/audio/imported/chatgpt-2026-07-12/`, reamostra para 48 kHz, atenua para
`-16 LUFS-I`, gera masters PCM24 e runtimes Ogg/Vorbis q6, escreve proveniência
factual e cria `audio-candidate-manifest-v2.json`. O lote v1 não é alterado.
Por padrão ele lê as próprias fontes preservadas; `--source-dir` permite repetir
o primeiro ingresso a partir de outro diretório com os mesmos hashes.
Prompt, modelo, termos comerciais, similaridade e escuta em aparelho não são
inferidos nem marcados como concluídos.

## Promoção após decisão humana

A aprovação geral permanece em `asset-approval-v1.json`; a seleção musical v2
fica em `music-selection-approval-v1.json`. Depois disso, execute:

```bash
python3 tools/assets/promote_approved_assets.py
```

O comando não altera os candidatos técnicos. Ele verifica escopo, estados e
revisões; deriva `assets/audio/audio-manifest-v2.json` e
`assets/manifests/art-approved-manifest-v1.json`; e cria
`assets/manifests/production-assets-v1.json`, ligando a decisão humana aos
hashes imutáveis e ao estado de integração. Testes físicos ainda pendentes
continuam declarados no manifesto de produção.
