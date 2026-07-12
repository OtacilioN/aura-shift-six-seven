# Aura Shift: Six Seven — Estado do Pacote de Assets

> Fotografia de produção e integração atualizada em 11 de julho de 2026. Os manifests
> técnicos `candidate-reviewed` permanecem imutáveis como evidência. A decisão
> humana explícita está registrada separadamente e promove derivados de runtime
> para `approved`; testes que exigem aparelho continuam declarados.

## Estado consolidado

| Frente | Revisão | Conteúdo | Estado atual |
| --- | ---: | --- | --- |
| arte de runtime | 3 | 219 WebP + fontes SVG e previews fora do bundle | approved + integrated |
| arte de QA | 3 | três goldens JSON/CoreGraphics review-only | approved, fora do runtime |
| áudio | 3 | 40 masters obrigatórios + quatro mixes condicionais | approved + integrated |
| marca | 2 | 39 arquivos de launcher, splash, loja e fonte vetorial | approved + integrated |
| fontes | 1 | seis binários pinados + licenças | approved + integrated |
| key art | 1 | conceito original + feature graphic 1024 × 500 | approved + integrated |

O áudio de runtime contém nove faixas Ogg/Vorbis e 35 SFX WAV PCM16; os 44
masters permanecem WAV PCM24 a 48 kHz. Música, ciclos, UI, Loja, Coleção,
progressão, retorno offline e anúncios possuem disparadores de domínio. A trilha
principal usa Base/Groove/Hype em camadas, com I0–I3 como fallback técnico.

Os 219 WebP têm consumidores verificáveis e sem sobreposição: 136 na cena Flame
(Mascote, fundos, Aparências, Formas e VFX) e 83 na UI (22 ícones, 15 assets de
Árvore, 13 badges, seis eventos, quatro Selos e 23 thumbnails). Os três assets
de QA não possuem caminho de runtime e continuam fora do pacote. A cena decodifica
sob demanda somente `base/accent/glow/reduced` da Aparência equipada, separa slots
de fundo e frente e troca as camadas pelos Marcos de Nível e Movimento Reduzido.

A arte passou 18 gates, incluindo goldens compostos a partir dos mesmos WebP,
pivôs, anchors e ângulos do runtime e regeneração byte a byte. O áudio passou
duas renderizações independentes, reconstrução TPDF 35/35 e seam CoreAudio 9/9.

Os 18 Itens de Aura receberam uma revisão individual multiagente nesta data:
ícones semânticos, slots vestíveis/world-space e um efeito de cena exclusivo por
item. Óculos, casaco, coroa, tênis e acessórios acompanham o Mascote; despertador
e roteador agora são props de chão; molduras e Convergências permanecem atrás do
rig. O relatório consolidado está em
[`reports/item-redesign/README.md`](../reports/item-redesign/README.md).

## Evidência reproduzível

- [pipeline e gates](ASSET-PRODUCTION-PIPELINE.md);
- [decisão humana de aprovação](../assets/manifests/asset-approval-v1.json);
- [manifesto de produção integrado](../assets/manifests/production-assets-v1.json);
- [manifesto visual aprovado](../assets/manifests/art-approved-manifest-v1.json)
  e [candidato técnico imutável](../assets/manifests/art-manifest-v1.json);
- [galeria visual](../reports/art-contact-sheet.html);
- [relatório de validação visual](../reports/art-validation-report.md);
- [manifesto aprovado de áudio](../assets/audio/audio-manifest-v1.json) e
  [candidato técnico imutável](../assets/audio/audio-candidate-manifest-v1.json);
- [relatório técnico de áudio](../reports/audio-generation-report.md);
- [resultado estruturado da revisão de áudio](../reports/audio-review-results.json);
- [folha de escuta com 44 players](../reports/audio-listening-sheet.html);
- [revisão do pacote Android](../reports/package-asset-review.json);
- [manifesto de marca](../assets/manifests/brand-manifest-v1.json) e
  [manifesto de fontes](../assets/manifests/font-manifest-v1.json);
- [prompt e proveniência do key art](../provenance/art/key-art-imagegen-v1.md).

## Verificação desta revisão de itens

- geração final: 222 entradas `art-v1`; 1.614.304 bytes WebP de runtime;
- `validate_art_assets.py --determinism`: 18/18 gates, regeneração byte a byte;
- promoção final: 219 assets de arte e 44 de áudio; candidato e aprovado usam
  `SLOT-GROUND-PROP-BACK` para despertador e roteador;
- `dart format`: 23 arquivos, zero alterações pendentes;
- `dart analyze`: zero issues;
- `flutter analyze --no-pub`: zero issues;
- foram adicionados contratos para os 18 efeitos distintos, movimento
  world-space/vestível, composição sob/sobre mãos e rota segura do B-04;
- a suíte de cenas cobre cada item nos modos animado e reduzido e permite
  captura opt-in de goldens por `ITEM_SCENE_GOLDENS=true`.

`flutter test` não carregou os testes neste sandbox: o runner precisa abrir um
socket efêmero em `127.0.0.1` e recebeu `Operation not permitted`. O rebuild do
APK também não concluiu porque a distribuição Gradle não está no cache isolado e
`services.gradle.org` ficou inacessível; a autorização para ambos foi recusada
automaticamente por limite de uso. Portanto o package review abaixo continua
sendo um baseline anterior e não prova o redesign atual.

### Último baseline empacotado, anterior ao redesign

- `flutter test`: 45/45 testes aprovados;
- `flutter build apk --debug`: aprovado;
- nove catálogos de localização empacotados idênticos byte a byte às fontes runtime;
- auditoria `package-asset-review-v2`: 219/219 WebP, 9/9 Ogg, 35/35 WAV,
  6/6 fontes, 8/8 PNG nativos Android e manifests de promoção; zero asset de
  QA/report/preview e zero arte exclusiva de loja no runtime;
- APK debug: `250361780` bytes; SHA-256
  `63e7ada2c0664181c3d00f0cab02e2f416e6517dd8b16aa64ca9130c1c8af641`.

## Gates que continuam físicos ou de publicação

- loop musical, latência, foco, anúncio, background e retomada no Android;
- máscaras do adaptive icon, splash e safe areas em aparelhos reais;
- árabe/japonês, reflow e escala de texto a 200% no app;
- identidade de publicação, assinatura e configuração dos SDKs externos.

Os nove Ogg mantiveram a contagem de frames e passaram o seam numérico no
CoreAudio, mas todos preservam offset de decode de `+128` frames. Isso é warning,
não prova de loop audivelmente perfeito. Os 35 SFX WAV foram sample-exact no
mesmo cross-decoder. A promoção não renomeia ou sobrescreve candidatos: o script
`promote_approved_assets.py` gera manifests aprovados derivados e mantém as
pendências físicas no índice de produção.
