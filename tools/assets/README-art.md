# Deterministic art-v1 pipeline

This pipeline produces the editable vector sources and review/runtime exports for
the in-game `art-v1` catalog. It does not generate audio, app icons, key art, or
store artwork.

## Requirements

- Python 3.11+ standard library;
- macOS `clang` + AppKit, used by the checked-in in-process SVG rasterizer;
- macOS Objective-C with CoreGraphics/ImageIO, used to compose QA goldens directly from runtime WebPs;
- `cwebp` 1.6 or compatible, used for deterministic WebP exports.

No Python package, external image, font, network service, or generative model is
used by the in-game art generator. SVG is the canonical runtime source; the
checked-in `render_svg_appkit.m` keeps SVG decoding inside the generator process,
and QA JSON render commands remain canonical for goldens. PNG and WebP files are
disposable derivatives. Brand generation and review are separate and
use the pinned Pillow version in `requirements-visual.txt`.

## Commands

```sh
python3 tools/assets/generate_art_assets.py
python3 tools/assets/validate_art_assets.py --determinism
```

The full determinism check regenerates all 222 manifest entries (219 runtime and
three review-only QA sheets) under a temporary root and compares the manifest,
SVG/JSON sources, renderer helper, PNG, WebP, and provenance files byte for byte.

## Outputs

- `sources/art/<family>/*.svg`: editable vector runtime sources;
- `sources/art/qa/*.json`: editable golden composition specs containing exact runtime paths, hashes, pivots, anchors and views;
- `assets/art/<family>/*.webp`: runtime-only exports; no PNG or QA file is stored here;
- `reports/art-previews/<family>/*.png`: normalized sRGB review exports and 48px derivatives;
- `reports/art-previews/qa/*`: review-only QA PNG/WebP files, never runtime assets;
- `assets/manifests/art-manifest-v1.json`: dimensions, pivots, hashes, status, and paths;
- `provenance/art/<family>/*.md`: one provenance record per manifest entry;
- `reports/art-generation-report.md`: catalog summary;
- `reports/art-validation-report.md`: automated validation result;
- `reports/art-contact-sheet.html`: lazy-loaded gallery of all entries.

`candidate-reviewed` is not human approval. Promotion to `approved` requires an
explicit human decision after the visual/compositing review; safe-area/RTL and
performance checks on the target Android device remain release gates and stay
listed in the production manifest until executed.

After an explicit human decision, `promote_approved_assets.py` derives
`assets/manifests/art-approved-manifest-v1.json` without mutating this
deterministic candidate. Flutter loads the approved derivative; generation and
byte-for-byte validation continue to use the candidate as immutable evidence.
