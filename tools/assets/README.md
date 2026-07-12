# Pipeline procedural de áudio

Esta pasta produz candidatos de áudio originais por síntese determinística. A
pipeline não baixa, lê nem transforma gravações externas; não usa voz, foley,
sample pack, DAW ou modelo generativo. Os resultados permanecem com o status
`candidate-reviewed`: revisão automatizada não equivale a aprovação musical,
jurídica, humana ou em aparelho real.

## Ambiente isolado

```bash
python3 -m venv .asset-venv
.asset-venv/bin/python -m pip install pip==26.1.2
.asset-venv/bin/python -m pip install -r tools/assets/requirements-audio.txt
```

As versões estão fixadas. Para uma reprodução de arquivo idêntica, também
registre arquitetura, Python, libsndfile e sistema operacional, pois o encoder
Vorbis fornecido pelo wheel de SoundFile pode mudar entre plataformas.

## Gerar e revisar

```bash
.asset-venv/bin/python tools/assets/generate_audio_assets.py
.asset-venv/bin/python tools/assets/review_audio_assets.py
```

O gerador lê `sources/audio/procedural/score-v1.json`, renderiza masters WAV
PCM 48 kHz/24-bit, nove exports musicais Ogg/Vorbis VBR q6 e 35 exports curtos
WAV PCM16 com dither determinístico. O revisor reabre todos os arquivos,
recalcula hashes e métricas, compara duas renderizações integrais independentes
e falha com código não zero quando um gate automatizável reprova.

Saídas principais:

- `masters/audio/`: 40 masters obrigatórios e quatro mixes condicionais;
- `assets/audio/`: exports runtime e manifesto candidato;
- `provenance/audio/`: registro por ID, sem alegação de aprovação;
- `reports/audio-generation-report.md`: resultado consolidado e limitações;
- `reports/audio-review-results.json`: evidência estruturada de QA;
- `reports/audio-listening-sheet.html`: 44 players locais e roteiro do gate
  humano, sem promover nenhum candidato.

Não renomeie o manifesto candidato para `audio-manifest-v1.json`. O contrato do
projeto reserva esse nome ao conjunto aprovado, e esta pipeline não realiza a
escuta humana, a auditoria adversarial de similaridade nem o teste Android.

## Promoção após decisão humana

Uma aprovação explícita é registrada em
`assets/manifests/asset-approval-v1.json`. Depois disso, execute:

```bash
python3 tools/assets/promote_approved_assets.py
```

O comando não altera os candidatos técnicos. Ele verifica escopo, estados e
revisões; deriva `assets/audio/audio-manifest-v1.json` e
`assets/manifests/art-approved-manifest-v1.json`; e cria
`assets/manifests/production-assets-v1.json`, ligando a decisão humana aos
hashes imutáveis e ao estado de integração. Testes físicos ainda pendentes
continuam declarados no manifesto de produção.
