# MUS-AURA-NO-RETROVISOR — proveniência da trilha selecionada

- **Título:** Aura no Retrovisor
- **ID:** `MUS-AURA-NO-RETROVISOR`
- **Papel:** trilha selecionada
- **Status técnico:** `candidate-reviewed`; o derivado de runtime é promovido pela decisão humana de 12 de julho de 2026.
- **Origem declarada pelo usuário:** geração musical via ChatGPT, entregue como WAV e selecionada pelo usuário.
- **Prompt/modelo/sessão:** não fornecidos junto aos arquivos; não inferidos por este registro.
- **Licença/termos comerciais:** comprovação externa pendente antes de uma publicação comercial.

## Cadeia de custódia

- **Fonte preservada:** `sources/audio/imported/chatgpt-2026-07-12/02_aura_no_retrovisor.wav`
- **SHA-256 da fonte:** `47d68c8e54d912788c5c8beb6dba556024e25a9bc26e0e7e30f99948e40937a0`
- **Fonte:** `44100 Hz`, `PCM_24`, `2` canais, `27.042244898` s.
- **Métricas da fonte:** `-10.168` LUFS-I, `-0.7242` dBFS peak, `-0.4687` dBTP.
- **Processamento:** resample polifásico `160/147` para `48000 Hz`, ganho de `-5.8296` dB até `-16 LUFS-I`; sem compressor ou limiter.
- **Master derivado:** `masters/audio/mus_aura_no_retrovisor.wav` — `0b240ad7c0a0296a12f85ce1dd53d2c94b0058376bd825cdf1a22de07a946595`
- **Runtime Android:** `assets/audio/music/mus_aura_no_retrovisor.ogg` — `23214631ece76cd5b34dec90c964617fc52213e92eba8418c4531137725270ae`
- **Runtime:** Ogg/Vorbis q6, `48000 Hz`, `2` canais, `27.04225` s, `-15.9779` LUFS-I, `-6.0446` dBTP.

## Playback e revisão residual

- Faixa completa sem markers de loop; o controlador mantém a música atual em loop no mesmo menu e avança com crossfade somente quando o jogador troca de menu.
- A seleção humana desta faixa está registrada em `assets/manifests/music-selection-approval-v1.json`.
- Similaridade independente, fadiga, foco/retomada e crossfade em aparelho Android permanecem gates de release; esta proveniência não afirma que esses testes externos já ocorreram.
