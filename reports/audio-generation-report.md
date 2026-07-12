# Relatório de geração e revisão de áudio

> Status: **REVISÃO TÉCNICA CONCLUÍDA COM WARNINGS DE DECODER**. Os arquivos permanecem `candidate-reviewed`; não são `approved` nem `integrated`.

## Resultado

- revisão do áudio: **3**; revisão da evidência: **2**;
- candidatos verificados: **44/44**;
- obrigatórios verificados: **40/40**;
- condicionais verificados: **4/4**;
- bundle-fonte SHA-256: `23d5c30e6a44bb6ef8d213887d364676e349c419154af894e456f131de54cb5f`;
- bundle-fonte esperado versus observado: **PASS**;
- bundle do revisor SHA-256: `0d7123c8c8ecab87133800bb38051a48a1848a92f33264e8ad5d922e1dd0a335`;
- hashes esperados versus arquivos observados: **44/44**;
- reconstrução determinística TPDF dos runtimes PCM16: **35/35**;
- determinismo real: **PASS**, masters WAV `44/44`, runtimes `44/44`;
- duas renderizações temporárias: `['93606ece0532a7f9e71ff6d29d65c323d114863322b9a0ae09e2f860b9f119a6', '93606ece0532a7f9e71ff6d29d65c323d114863322b9a0ae09e2f860b9f119a6']`;
- candidato atual versus render: `88/88`;
- SHA-256 combinado atual: `93606ece0532a7f9e71ff6d29d65c323d114863322b9a0ae09e2f860b9f119a6`;
- fonte sonora externa, voz, foley, sample e modelo generativo: **nenhum**;
- masters: WAV PCM 48 kHz/24-bit; runtime: nove músicas Ogg/Vorbis q6 e 35 SFX WAV PCM16 com TPDF determinístico;
- tratamento de boundary musical: taper squared-sine de `1024` frames em cada lado;
- loops de gameplay: `[0, 4.404.706)` amostras; menu/Loja: `[0, 2.202.353)`.

## Estados musicais compostos

| Estado | LUFS-I | Sample peak dBFS | True peak dBTP |
| --- | ---: | ---: | ---: |
| I0 | -16.0 | -1.7745 | -1.7587 |
| I1 | -16.0551 | -1.7745 | -1.7587 |
| I2 | -16.3562 | -1.7454 | -1.7357 |
| I3 | -17.0612 | -1.0433 | -1.0378 |

`MUS-GAME-GROOVE` e `MUS-GAME-HYPE` são overlays intencionalmente mais baixos; o alvo de aproximadamente -16 LUFS-I pertence ao estado musical composto. Os quatro mixes condicionais são normalizados individualmente para crossfade estável.

## Inventário e métricas

| ID | Status | Frames master | LUFS-I master | TP runtime | Frames CoreAudio | Offset | Seam CoreAudio dBFS | Gate |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `MUS-GAME-BASE` | WARN | 4404706 | -16.0 | -1.6875 | 4404706/4404706 | 128 | [-31.3007, -31.3007] | pass |
| ↳ warning | MUS-GAME-BASE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-31.3007, -31.3007] dBFS | | | | | | | |
| `MUS-GAME-GROOVE` | WARN | 4404706 | -24.8 | -6.5133 | 4404706/4404706 | 128 | [-128.9314, -118.4738] | pass |
| ↳ warning | MUS-GAME-GROOVE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-128.9314, -118.4738] dBFS | | | | | | | |
| `MUS-GAME-HYPE` | WARN | 4404706 | -26.3 | -7.1768 | 4404706/4404706 | 128 | [-54.1637, -53.269] | pass |
| ↳ warning | MUS-GAME-HYPE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-54.1637, -53.269] dBFS | | | | | | | |
| `MUS-MENU` | WARN | 2202353 | -16.0 | -1.4809 | 2202353/2202353 | 128 | [-37.9088, -37.5707] | pass |
| ↳ warning | MUS-MENU CoreAudio frame 0 aligns to libsndfile frame 128; frame count 2202353/2202353 (+0); unmatched CoreAudio tail 128 frames; seam [-37.9088, -37.5707] dBFS | | | | | | | |
| `MUS-SHOP` | WARN | 2202353 | -16.0 | -3.0835 | 2202353/2202353 | 128 | [-38.3425, -39.4289] | pass |
| ↳ warning | MUS-SHOP CoreAudio frame 0 aligns to libsndfile frame 128; frame count 2202353/2202353 (+0); unmatched CoreAudio tail 128 frames; seam [-38.3425, -39.4289] dBFS | | | | | | | |
| `MUS-GAME-I0-MIX` | WARN | 4404706 | -16.0 | -2.7797 | 4404706/4404706 | 128 | [-50.9496, -50.9496] | pass |
| ↳ warning | MUS-GAME-I0-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-50.9496, -50.9496] dBFS | | | | | | | |
| `MUS-GAME-I1-MIX` | WARN | 4404706 | -16.0 | -2.6641 | 4404706/4404706 | 128 | [-60.0432, -60.0432] | pass |
| ↳ warning | MUS-GAME-I1-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-60.0432, -60.0432] dBFS | | | | | | | |
| `MUS-GAME-I2-MIX` | WARN | 4404706 | -16.0 | -2.0747 | 4404706/4404706 | 128 | [-56.6376, -57.631] | pass |
| ↳ warning | MUS-GAME-I2-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-56.6376, -57.631] dBFS | | | | | | | |
| `MUS-GAME-I3-MIX` | WARN | 4404706 | -16.0 | -1.4194 | 4404706/4404706 | 128 | [-108.1035, -58.4781] | pass |
| ↳ warning | MUS-GAME-I3-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-108.1035, -58.4781] dBFS | | | | | | | |
| `SFX-SIX-01` | PASS | 3648 | None | -5.9944 | 3648/3648 | 0 | n/a | pass |
| `SFX-SIX-02` | PASS | 4032 | None | -5.9903 | 4032/4032 | 0 | n/a | pass |
| `SFX-SIX-03` | PASS | 4416 | None | -5.9877 | 4416/4416 | 0 | n/a | pass |
| `SFX-SIX-04` | PASS | 4800 | None | -5.9944 | 4800/4800 | 0 | n/a | pass |
| `SFX-SIX-05` | PASS | 5088 | None | -5.8495 | 5088/5088 | 0 | n/a | pass |
| `SFX-SIX-06` | PASS | 5280 | None | -5.9944 | 5280/5280 | 0 | n/a | pass |
| `SFX-SEVEN-01` | PASS | 4608 | None | -4.9948 | 4608/4608 | 0 | n/a | pass |
| `SFX-SEVEN-02` | PASS | 5088 | None | -4.9948 | 5088/5088 | 0 | n/a | pass |
| `SFX-SEVEN-03` | PASS | 5568 | None | -4.9944 | 5568/5568 | 0 | n/a | pass |
| `SFX-SEVEN-04` | PASS | 6048 | None | -4.9855 | 6048/6048 | 0 | n/a | pass |
| `SFX-SEVEN-05` | PASS | 6624 | None | -4.9944 | 6624/6624 | 0 | n/a | pass |
| `SFX-SEVEN-06` | PASS | 7104 | None | -4.9944 | 7104/7104 | 0 | n/a | pass |
| `SFX-UI-TAB` | PASS | 5760 | None | -4.9944 | 5760/5760 | 0 | n/a | pass |
| `SFX-UI-OPEN` | PASS | 8640 | None | -4.9669 | 8640/8640 | 0 | n/a | pass |
| `SFX-UI-CLOSE` | PASS | 7680 | None | -4.9944 | 7680/7680 | 0 | n/a | pass |
| `SFX-UI-TOGGLE-ON` | PASS | 6720 | None | -4.9541 | 6720/6720 | 0 | n/a | pass |
| `SFX-UI-TOGGLE-OFF` | PASS | 6720 | None | -4.8623 | 6720/6720 | 0 | n/a | pass |
| `SFX-UI-ERROR` | PASS | 12480 | None | -4.9948 | 12480/12480 | 0 | n/a | pass |
| `SFX-SHOP-PURCHASE` | PASS | 16800 | None | -4.4892 | 16800/16800 | 0 | n/a | pass |
| `SFX-SHOP-BATCH` | PASS | 24000 | -18.3112 | -4.4939 | 24000/24000 | 0 | n/a | pass |
| `SFX-SHOP-UNAVAILABLE` | PASS | 12480 | None | -4.9927 | 12480/12480 | 0 | n/a | pass |
| `SFX-SHOP-UNLOCK` | PASS | 43200 | -18.8866 | -4.4272 | 43200/43200 | 0 | n/a | pass |
| `SFX-SHOP-MILESTONE` | PASS | 33600 | -23.761 | -4.4837 | 33600/33600 | 0 | n/a | pass |
| `SFX-COLLECTION-EQUIP` | PASS | 14400 | None | -4.9948 | 14400/14400 | 0 | n/a | pass |
| `SFX-COLLECTION-HIDE` | PASS | 12480 | None | -4.9944 | 12480/12480 | 0 | n/a | pass |
| `STG-FORM-01` | PASS | 57600 | -16.5 | -2.4074 | 57600/57600 | 0 | n/a | pass |
| `STG-FORM-02` | PASS | 72000 | -16.5 | -3.0837 | 72000/72000 | 0 | n/a | pass |
| `STG-FORM-03` | PASS | 86400 | -16.5 | -1.8468 | 86400/86400 | 0 | n/a | pass |
| `STG-FORM-04` | PASS | 100800 | -16.5 | -2.6356 | 100800/100800 | 0 | n/a | pass |
| `STG-FORM-05` | PASS | 115200 | -16.5 | -2.059 | 115200/115200 | 0 | n/a | pass |
| `STG-ACHIEVEMENT` | PASS | 43200 | -17.0 | -1.6688 | 43200/43200 | 0 | n/a | pass |
| `STG-ASCENSION` | PASS | 153600 | -15.5 | -1.7609 | 153600/153600 | 0 | n/a | pass |
| `STG-MARK-67` | PASS | 86400 | -16.5 | -3.2479 | 86400/86400 | 0 | n/a | pass |
| `SFX-RETURN-OFFLINE` | PASS | 24000 | -20.7841 | -4.3429 | 24000/24000 | 0 | n/a | pass |
| `SFX-RETURN-BONUS` | PASS | 31200 | -19.8737 | -4.4226 | 31200/31200 | 0 | n/a | pass |

## O que a revisão automatizada comprovou

- cardinalidade 40 obrigatórios + quatro condicionais, IDs e paths do score;
- sample rate, bit depth, canais, duração e número exato de amostras;
- SHA-256 de fonte consolidada, master e runtime;
- LUFS-I por BS.1770 via pyloudnorm, true peak estimado com oversampling 4× e picos;
- ausência de silêncio, clipping digital evidente, DC relevante e perda mono grosseira;
- alinhamento dos três stems e continuidade de fronteira do master e do decode libsndfile;
- boundary do decode CoreAudio dentro de -24 dBFS e ratio <= 6: `9/9`;
- frame count, offset PCM, overlap, cauda não pareada e seam são métricas separadas;
- duas renderizações temporárias reais: masters WAV `44/44`, runtimes WAV `35/35` e runtimes Ogg `9/9`;
- hashes observados foram comparados aos hashes esperados do manifesto gerado antes de qualquer anotação de revisão;
- conversão PCM16/TPDF reconstruída pelo revisor: `35/35`;

## Verificação cross-decoder CoreAudio

- resultado: **pass-with-music-decoder-variance**;
- SFX WAV PCM16 frame e valores sample-exact: `35/35`;
- músicas Ogg com mesmo frame count: `9/9`;
- músicas Ogg alinhadas em offset zero: `0/9`;
- músicas Ogg sample-exact em sentido estrito: `0/9`;
- offsets medidos: `{'128': 9}`;
- seams CoreAudio aprovados: `9/9`;
- o serial Ogg é derivado do ID e os CRCs das páginas são recalculados sem alterar packets Vorbis;
- o taper reduz o boundary numérico, mas não corrige pre-skip/alinhamento do decoder; a variação segue como warning explícito e o gate audível Android continua pendente;
- warnings por arquivo:
- `MUS-GAME-BASE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-31.3007, -31.3007] dBFS`
- `MUS-GAME-GROOVE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-128.9314, -118.4738] dBFS`
- `MUS-GAME-HYPE CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-54.1637, -53.269] dBFS`
- `MUS-MENU CoreAudio frame 0 aligns to libsndfile frame 128; frame count 2202353/2202353 (+0); unmatched CoreAudio tail 128 frames; seam [-37.9088, -37.5707] dBFS`
- `MUS-SHOP CoreAudio frame 0 aligns to libsndfile frame 128; frame count 2202353/2202353 (+0); unmatched CoreAudio tail 128 frames; seam [-38.3425, -39.4289] dBFS`
- `MUS-GAME-I0-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-50.9496, -50.9496] dBFS`
- `MUS-GAME-I1-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-60.0432, -60.0432] dBFS`
- `MUS-GAME-I2-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-56.6376, -57.631] dBFS`
- `MUS-GAME-I3-MIX CoreAudio frame 0 aligns to libsndfile frame 128; frame count 4404706/4404706 (+0); unmatched CoreAudio tail 128 frames; seam [-108.1035, -58.4781] dBFS`

## Limitações obrigatórias antes de aprovação

- o true peak é uma estimativa numérica por oversampling 4×, não medição certificada;
- agentes não escutaram o resultado e não podem aprovar musicalidade, fadiga, ausência de clique perceptível ou adequação cultural;
- a auditoria adversarial contra qualquer referência musical permanece pendente e não deve expor a gravação ao compositor;
- faltam testes de 20 min na cadência de referência, 10 min em alta cadência e 30 min em menu/Loja;
- faltam alto-falante móvel modesto, soma mono real, fones e diferentes fabricantes;
- faltam latência de primeiro toque/quente, drift dos stems, foco, anúncio, background e retomada no Android;
- não existe sessão/licença REAPER neste fluxo; a aceitação de fonte procedural precisa de decisão documental antes de `approved`;
- licenças e termos das ferramentas devem ser arquivados; esta pipeline não fornece parecer jurídico.

## Próximo gate humano

Ouvir primeiro `MUS-GAME-I0-MIX`, `MUS-GAME-I3-MIX`, as seis duplas Six/Seven, `STG-FORM-01`, `STG-FORM-05`, `STG-ASCENSION` e `STG-MARK-67`. Rejeitar qualquer fadiga, semelhança reconhecível, conotação de moeda/jackpot, Seven ambíguo ou Six que pareça recompensa. Somente depois executar a matriz completa em Android.
