# Aura Shift: Six Seven — Estado do Pacote de Assets

> Fotografia de produção e integração atualizada em 12 de julho de 2026. Os manifests
> técnicos `candidate-reviewed` permanecem imutáveis como evidência. A decisão
> humana explícita está registrada separadamente e promove derivados de runtime
> para `approved`; testes que exigem aparelho continuam declarados.

## Estado consolidado

| Frente | Revisão | Conteúdo | Estado atual |
| --- | ---: | --- | --- |
| arte de runtime | 3 | 219 WebP + fontes SVG e previews fora do bundle | approved + integrated |
| arte de QA | 3 | três goldens JSON/CoreGraphics review-only | approved, fora do runtime |
| áudio runtime v2 | 1 | 7 músicas selecionadas + 35 SFX herdados | approved + integrated |
| marca | 2 | 39 arquivos de launcher, splash, loja e fonte vetorial | approved + integrated |
| fontes | 1 | seis binários pinados + licenças | approved + integrated |
| key art | 1 | conceito original + feature graphic 1024 × 500 | approved + integrated |

O áudio de runtime contém sete faixas Ogg/Vorbis e 35 SFX WAV PCM16: 42 assets
obrigatórios, sem condicionais. Os WAVs selecionados são preservados como fontes
PCM24/44,1 kHz e derivados para masters PCM24/48 kHz a `-16 LUFS-I`. `Boss
Shift` abre a playlist de voz única; as outras seis avançam por posição/conclusão
com crossfade de `1 s`. Os nove Ogg do lote procedural v1 permanecem no repo
como evidência, mas não são declarados no `pubspec.yaml` nem entram no APK.

Os 219 WebP têm consumidores verificáveis e sem sobreposição: 136 na cena Flame
(Mascote, fundos, Aparências, Formas e VFX) e 83 na UI (22 ícones, 15 assets de
Árvore, 13 badges, seis eventos, quatro Selos e 23 thumbnails). Os três assets
de QA não possuem caminho de runtime e continuam fora do pacote. A cena decodifica
sob demanda somente `base/accent/glow/reduced` atualmente necessários para todas
as Aparências ativas, separa fundo, corpo e mãos em ordem determinística e aplica
relayout aos territórios compartilhados. Marcos de Nível e Movimento Reduzido
trocam apenas as variantes afetadas.

A arte passou 18 gates, incluindo goldens compostos a partir dos mesmos WebP,
pivôs, anchors e ângulos do runtime e regeneração byte a byte. Os 35 SFX mantêm
a evidência r3 de reconstrução TPDF/sample-exact. As sete músicas v2 passaram
validação de fonte, resample, loudness, frame count e hashes; escuta, termos e
aparelho permanecem pendentes.

Os 18 Itens de Aura receberam uma revisão individual multiagente nesta data:
ícones semânticos, slots vestíveis/world-space e um efeito de cena exclusivo por
item. Óculos, casaco, coroa, tênis e acessórios acompanham o Mascote; despertador
e roteador agora são props de chão; molduras e Convergências permanecem atrás do
rig. O relatório consolidado está em
[`reports/item-redesign/README.md`](../reports/item-redesign/README.md).

## Evidência reproduzível

- [pipeline e gates](ASSET-PRODUCTION-PIPELINE.md);
- [decisão humana de aprovação](../assets/manifests/asset-approval-v1.json);
- [decisão da trilha selecionada](../assets/manifests/music-selection-approval-v1.json);
- [manifesto de produção integrado](../assets/manifests/production-assets-v1.json);
- [manifesto visual aprovado](../assets/manifests/art-approved-manifest-v1.json)
  e [candidato técnico imutável](../assets/manifests/art-manifest-v1.json);
- [galeria visual](../reports/art-contact-sheet.html);
- [relatório de validação visual](../reports/art-validation-report.md);
- [manifesto aprovado de áudio v2](../assets/audio/audio-manifest-v2.json) e
  [candidato técnico v2](../assets/audio/audio-candidate-manifest-v2.json);
- [snapshot procedural v1](../assets/audio/audio-candidate-manifest-v1.json);
- [relatório técnico de áudio](../reports/audio-generation-report.md);
- [resultado estruturado da revisão de áudio](../reports/audio-review-results.json);
- [folha de escuta com 42 players atuais](../reports/audio-listening-sheet.html);
- [revisão do pacote Android](../reports/package-asset-review.json);
- [manifesto de marca](../assets/manifests/brand-manifest-v1.json) e
  [manifesto de fontes](../assets/manifests/font-manifest-v1.json);
- [prompt e proveniência do key art](../provenance/art/key-art-imagegen-v1.md).

## Verificação desta revisão integrada

- geração final: 222 entradas `art-v1`; 1.614.304 bytes WebP de runtime;
- `validate_art_assets.py --determinism`: 18/18 gates, regeneração byte a byte;
- promoção final: 219 assets de arte e 42 de áudio; candidato e aprovado usam
  `SLOT-GROUND-PROP-BACK` para despertador e roteador;
- importação musical executada duas vezes a partir das fontes preservadas, com
  manifesto candidato SHA-256 idêntico nas duas execuções;
- `dart format`: 27 arquivos, zero alterações;
- `flutter analyze --no-fatal-infos`: zero issues;
- `flutter test`: 118/118 testes aprovados;
- `validate_planning.py`: P01–P11 presentes, 42 slots e oito catálogos
  alinhados;
- `flutter build apk --debug`: aprovado;
- auditoria `package-asset-review-v2`: 219/219 WebP, 7/7 Ogg, 35/35 WAV,
  6/6 fontes, 8/8 PNG nativos Android e somente os manifests atuais; zero
  asset de QA/report/preview, arte exclusiva de loja ou manifesto de áudio v1
  no runtime;
- APK debug: `210835622` bytes; SHA-256
  `c6d3ac4a1a31764cc0dae0db80b580b7f1841661f65a33a507d2d3ddf7747f1a`;
- foram adicionados contratos para os 18 efeitos distintos, movimento
  world-space/vestível, composição sob/sobre mãos e rota segura do B-04;
- a suíte de cenas cobre cada item nos modos animado e reduzido e permite
  captura opt-in de goldens por `ITEM_SCENE_GOLDENS=true`.

## Gates que continuam físicos ou de publicação

- playlist/crossfade, latência, foco, anúncio, background e retomada no Android;
- termos comerciais do ChatGPT, prompt/modelo quando recuperáveis, similaridade e fadiga;
- máscaras do adaptive icon, splash e safe areas em aparelhos reais;
- árabe/japonês, reflow e escala de texto a 200% no app;
- identidade de publicação, assinatura e configuração dos SDKs externos.

As sete músicas são `non-loop`; o gate relevante é o crossfade em aparelho, não
o seam repetido do lote antigo. Os 35 SFX WAV continuam sample-exact na evidência
herdada. A promoção não sobrescreve o candidato v1: o script deriva o manifesto
v2 da nova decisão e mantém pendências jurídicas/físicas no índice de produção.
