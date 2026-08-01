# Art validation report

Result: **PASS**
Manifest: `assets/manifests/art-manifest-v1.json`
Entries: `202`
Status: `candidate-reviewed`

- PASS — `manifest-schema-counts-and-unique-ids`
- PASS — `exact-27-background-and-18x5-skin-matrices`
- PASS — `canonical-skin-pivots-side-offset-milestone-reduced-metadata`
- PASS — `files-hashes-dimensions-provenance`
- PASS — `runtime-svg-no-external-art-or-text`
- PASS — `palette-whitelist`
- PASS — `runtime-size-budgets`
- PASS — `runtime-only-assets-art-tree`
- PASS — `unique-background-pixels`
- PASS — `normalized-48px-thumbnails`
- PASS — `contact-sheet-all-entries-and-compositions`
- PASS — `full-regeneration-byte-determinism`

## Budgets

- Runtime WebP total: `1605574` / `25165824` bytes
- Largest runtime entry: `form_03_ambient` at `209594` / `1048576` bytes
- Byte-for-byte regeneration: `PASS`

## Residual review

Automated validation does not promote assets to `approved`. Review the generated
contact sheet and in-game composites for silhouette, cultural ambiguity, color
vision deficiencies, reduced-motion equivalence, safe areas, and target-device
performance before release.
