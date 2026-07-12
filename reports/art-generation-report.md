# Art generation report

Status: **candidate-reviewed**  
Contract: `art-v1` / `art-manifest-v1`  
Generator: `tools/assets/generate_art_assets.py` (`art-generator-v4`)
Revision: `3` — `runtime-compositor-golden-corrections-v3`

## Result

The deterministic pipeline generated **219** editable SVG
runtime sources plus **3** editable JSON compositor sources for review-only QA sheets. Each has matching PNG/WebP review exports and one provenance
record per manifest entry. All geometry is original to this repository and uses no
external image, font, model output, or network input.

| Family | Manifest entries |
| --- | ---: |
| `backgrounds` | 27 |
| `badges` | 13 |
| `branches` | 15 |
| `character` | 16 |
| `events` | 6 |
| `forms` | 21 |
| `icons` | 22 |
| `qa` | 3 |
| `seals` | 4 |
| `skins` | 90 |
| `vfx` | 5 |

- SVG source bytes: `367840`
- PNG preview bytes: `10734278`
- Runtime-included WebP bytes: `1614304`
- Runtime target budget: `25,165,824` bytes
- Largest permitted runtime asset: `1,048,576` bytes
- Background count, including reduced variants: `27`
- Skin count: `18 × 5 = 90` layers/derivatives

## Output contract

- Editable runtime source: `sources/art/<family>/<manifestId>.svg`
- Editable QA composition source: `sources/art/qa/<manifestId>.json`
- PNG review export: `reports/art-previews/<family>/<manifestId>.png`
- WebP runtime export: `assets/art/<family>/<manifestId>.webp`
- Review-only QA PNG/WebP: `reports/art-previews/qa/`
- Provenance: `provenance/art/<family>/<manifestId>.md`
- Manifest: `assets/manifests/art-manifest-v1.json`

PNG files are normalized to critical pixel chunks plus an explicit sRGB intent,
so host metadata does not make repeat runs drift. WebP files are encoded with
`cwebp` using lossless mode except portrait backgrounds, which use quality 86.

## Review meaning

`candidate-reviewed` means the generated catalog passed deterministic structural
preflight. It does not claim final art approval. Final integration still requires
in-game compositing across all slots and Forms, grayscale/CVD review, RTL and safe
area capture review, and performance measurement on the target Android device.

## Reproduction

```sh
python3 tools/assets/generate_art_assets.py
python3 tools/assets/validate_art_assets.py --determinism
```
