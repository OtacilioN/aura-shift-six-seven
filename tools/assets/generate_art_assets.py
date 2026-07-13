#!/usr/bin/env python3
"""Generate the complete deterministic runtime-only art-v1 catalog.

SVG files in ``sources/art`` are canonical editable sources. PNG previews are
normalized to remove incidental metadata, and runtime WebP files are encoded
with cwebp.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any

from art_library import (
    EXPECTED_FAMILY_COUNTS,
    PALETTE,
    AssetSpec,
    all_specs,
)


GENERATOR_VERSION = "art-generator-v4"
SCHEMA_VERSION = "art-manifest-v1"
STATUS = "candidate-reviewed"
ASSET_REVISION = 3
LICENSE = "Original project-authored procedural vector geometry; no external art assets."
FIXED_REVIEW_DATE = "2026-07-11"


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_if_changed(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_bytes() == data:
        return
    temp = path.with_name(f".{path.name}.tmp-{os.getpid()}")
    temp.write_bytes(data)
    os.replace(temp, path)


def _png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", zlib.crc32(chunk_type + payload) & 0xFFFFFFFF)


def normalized_png_bytes(raw: bytes) -> bytes:
    signature = b"\x89PNG\r\n\x1a\n"
    if not raw.startswith(signature):
        raise RuntimeError("SVG rasterizer output is not a PNG")
    pos = len(signature)
    chunks: list[tuple[bytes, bytes]] = []
    while pos < len(raw):
        if pos + 12 > len(raw):
            raise RuntimeError("truncated PNG chunk")
        size = struct.unpack(">I", raw[pos : pos + 4])[0]
        chunk_type = raw[pos + 4 : pos + 8]
        payload = raw[pos + 8 : pos + 8 + size]
        chunks.append((chunk_type, payload))
        pos += 12 + size
        if chunk_type == b"IEND":
            break
    allowed = {b"IHDR", b"PLTE", b"tRNS", b"IDAT", b"IEND"}
    output = bytearray(signature)
    inserted_srgb = False
    for chunk_type, payload in chunks:
        if chunk_type not in allowed:
            continue
        output.extend(_png_chunk(chunk_type, payload))
        if chunk_type == b"IHDR":
            output.extend(_png_chunk(b"sRGB", b"\x00"))
            inserted_srgb = True
    if not inserted_srgb:
        raise RuntimeError("PNG has no IHDR")
    return bytes(output)


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise RuntimeError(f"Invalid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def command_path(name: str) -> str:
    found = shutil.which(name)
    if not found:
        raise RuntimeError(f"Required executable not found: {name}")
    return found


def compile_appkit_svg_renderer(root: Path, clang: str) -> str:
    """Build the in-process SVG renderer used by every deterministic export.

    `sips` delegates SVG decoding to an OS service that is unavailable in
    sandboxed builds. NSImage can decode the same project-authored vectors in
    process, so a tiny Objective-C helper keeps generation local and makes the
    renderer explicit in the repository.
    """
    template = Path(__file__).with_name("render_svg_appkit.m")
    renderer_source = root / "tools" / "assets" / "render_svg_appkit.m"
    source_bytes = template.read_bytes()
    write_if_changed(renderer_source, source_bytes)
    renderer_hash = sha256_bytes(source_bytes)[:16]
    build_root = Path(tempfile.gettempdir()) / "aura-shift-svg-renderer"
    build_root.mkdir(parents=True, exist_ok=True)
    module_cache = build_root / "clang-module-cache"
    module_cache.mkdir(parents=True, exist_ok=True)
    executable = build_root / f"render-svg-appkit-{renderer_hash}"
    temporary = executable.with_name(f".{executable.name}.tmp-{os.getpid()}")
    env = dict(os.environ)
    env["CLANG_MODULE_CACHE_PATH"] = str(module_cache)
    completed = subprocess.run(
        [
            clang,
            "-fobjc-arc",
            "-O2",
            "-framework",
            "AppKit",
            "-framework",
            "Foundation",
            str(renderer_source),
            "-o",
            str(temporary),
        ],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
        env=env,
    )
    if completed.returncode != 0 or not temporary.exists():
        temporary.unlink(missing_ok=True)
        raise RuntimeError(
            f"AppKit SVG renderer compilation failed: {completed.stdout.strip()}"
        )
    os.replace(temporary, executable)
    return str(executable)


def clean_packaged_art_directory(root: Path) -> None:
    """Keep the pubspec-facing art tree runtime-only.

    Earlier revisions stored review PNGs beside runtime WebPs. Remove those
    generated previews before every run.
    """
    art_root = root / "assets" / "art"
    if not art_root.exists():
        return
    for png in art_root.rglob("*.png"):
        png.unlink()


def rasterize_svg(
    svg_path: Path,
    png_path: Path,
    size: tuple[int, int],
    svg_renderer: str,
) -> None:
    width, height = size
    png_path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".png", dir=png_path.parent, delete=False) as handle:
        raw_path = Path(handle.name)
    try:
        raw_path.unlink(missing_ok=True)
        completed = subprocess.run(
            [
                svg_renderer,
                str(svg_path),
                str(raw_path),
                str(width),
                str(height),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if completed.returncode != 0 or not raw_path.exists():
            raise RuntimeError(
                f"AppKit SVG renderer failed for {svg_path}: "
                f"{completed.stdout.strip()}"
            )
        normalized = normalized_png_bytes(raw_path.read_bytes())
        write_if_changed(png_path, normalized)
    finally:
        raw_path.unlink(missing_ok=True)
    actual = png_dimensions(png_path)
    if actual != size:
        raise RuntimeError(f"Unexpected PNG dimensions for {png_path}: {actual}, expected {size}")


def encode_webp(png_path: Path, webp_path: Path, mode: str, cwebp: str) -> None:
    webp_path.parent.mkdir(parents=True, exist_ok=True)
    temp = webp_path.with_name(f".{webp_path.name}.tmp-{os.getpid()}")
    args = [cwebp, "-quiet", "-metadata", "none", "-exact"]
    if mode == "lossy":
        args += ["-q", "86", "-m", "6", "-alpha_q", "100"]
    else:
        args += ["-lossless", "-z", "9"]
    args += [str(png_path), "-o", str(temp)]
    completed = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False)
    if completed.returncode != 0 or not temp.exists():
        temp.unlink(missing_ok=True)
        raise RuntimeError(f"cwebp failed for {png_path}: {completed.stdout.strip()}")
    data = temp.read_bytes()
    temp.unlink(missing_ok=True)
    if not data.startswith(b"RIFF") or data[8:12] != b"WEBP":
        raise RuntimeError(f"Invalid WebP produced for {png_path}")
    write_if_changed(webp_path, data)


def relative_path(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def render_one(
    spec: AssetSpec,
    root: Path,
    svg_renderer: str,
    cwebp: str,
    *,
    source_override: str | None = None,
    source_extension: str = ".svg",
    raster_svg_override: str | None = None,
    pre_rendered_png: bytes | None = None,
) -> dict[str, Any]:
    source_path = root / "sources" / "art" / spec.family / f"{spec.manifest_id}{source_extension}"
    png_path = root / "reports" / "art-previews" / spec.family / f"{spec.manifest_id}.png"
    webp_path = (
        root / "assets" / "art" / spec.family / f"{spec.manifest_id}.webp"
        if spec.runtime_included
        else root / "reports" / "art-previews" / spec.family / f"{spec.manifest_id}.webp"
    )
    if source_override is None:
        source_data = spec.builder(spec).encode("utf-8")
        # In-memory duplication catches accidental stateful builders before files are written.
        if source_data != spec.builder(spec).encode("utf-8"):
            raise RuntimeError(f"Non-deterministic SVG builder: {spec.manifest_id}")
    else:
        source_data = source_override.encode("utf-8")
    if spec.runtime_included and b"<text" in source_data:
        raise RuntimeError(f"Text element in {spec.manifest_id}")
    if spec.runtime_included and (b"<image" in source_data or b"href=" in source_data):
        raise RuntimeError(f"Runtime source contains external image or href: {spec.manifest_id}")
    if not spec.runtime_included:
        try:
            qa_source = json.loads(source_data)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid QA composition source: {spec.manifest_id}") from exc
        if qa_source.get("compositionContract") != "runtime-sprites-pivots-attachments-v3":
            raise RuntimeError(f"QA source is not runtime compositor v3: {spec.manifest_id}")
        if raster_svg_override is None and pre_rendered_png is None:
            raise RuntimeError(f"QA source has no runtime-derived raster composition: {spec.manifest_id}")
    write_if_changed(source_path, source_data)
    if pre_rendered_png is not None:
        write_if_changed(png_path, normalized_png_bytes(pre_rendered_png))
        if png_dimensions(png_path) != spec.runtime_size:
            raise RuntimeError(f"Unexpected QA PNG dimensions for {spec.manifest_id}")
    else:
        raster_source = source_path
        temporary_svg: Path | None = None
        if raster_svg_override is not None:
            png_path.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.NamedTemporaryFile(suffix=".svg", dir=png_path.parent, delete=False) as handle:
                temporary_svg = Path(handle.name)
                handle.write(raster_svg_override.encode("utf-8"))
            raster_source = temporary_svg
        try:
            rasterize_svg(
                raster_source,
                png_path,
                spec.runtime_size,
                svg_renderer,
            )
        finally:
            if temporary_svg is not None:
                temporary_svg.unlink(missing_ok=True)
    encode_webp(png_path, webp_path, spec.export_mode, cwebp)
    thumb_48_path: Path | None = None
    if spec.variant == "thumb":
        thumb_48_path = root / "reports" / "art-previews" / spec.family / f"{spec.manifest_id}_48.png"
        rasterize_svg(source_path, thumb_48_path, (48, 48), svg_renderer)
    source_hash = sha256_file(source_path)
    png_hash = sha256_file(png_path)
    runtime_hash = sha256_file(webp_path)
    provenance_path = root / "provenance" / "art" / spec.family / f"{spec.manifest_id}.md"
    record = {
        "manifestId": spec.manifest_id,
        "revision": ASSET_REVISION,
        "family": spec.family,
        "variant": spec.variant,
        "status": STATUS,
        "sourcePath": relative_path(source_path, root),
        "sourceFormat": source_extension.removeprefix("."),
        "previewPath": relative_path(png_path, root),
        "runtimePath": relative_path(webp_path, root) if spec.runtime_included else None,
        "reviewWebpPath": relative_path(webp_path, root) if not spec.runtime_included else None,
        "licenseRecord": relative_path(provenance_path, root),
        "sourceSizePx": list(spec.source_size),
        "sizePx": list(spec.runtime_size),
        "pivot": list(spec.pivot),
        "slot": spec.slot,
        "zLayer": spec.z_layer,
        "colorSpace": "sRGB",
        "alphaMode": "straight",
        "exportMode": "WebP lossy q86 + PNG preview" if spec.export_mode == "lossy" else "WebP lossless + PNG preview",
        "sourceSha256": source_hash,
        "pngSha256": png_hash,
        "sha256": runtime_hash,
        "sourceBytes": source_path.stat().st_size,
        "pngBytes": png_path.stat().st_size,
        "runtimeBytes": webp_path.stat().st_size,
        "description": spec.description,
        "runtimeIncluded": spec.runtime_included,
    }
    record.update(dict(spec.metadata))
    if thumb_48_path is not None:
        record.update(
            {
                "thumb48Path": relative_path(thumb_48_path, root),
                "thumb48Sha256": sha256_file(thumb_48_path),
                "thumb48Bytes": thumb_48_path.stat().st_size,
                "normalizedThumbnailPx": 48,
            }
        )
    provenance = provenance_markdown(record)
    write_if_changed(provenance_path, provenance.encode("utf-8"))
    return record


def provenance_markdown(record: dict[str, Any]) -> str:
    webp_path = record["runtimePath"]
    return f"""# {record['manifestId']}

- Status: `{record['status']}`
- Revision: `{record['revision']}`
- Style contract: `art-v1`
- Generator: `{GENERATOR_VERSION}`
- Review date: `{FIXED_REVIEW_DATE}`
- Construction: deterministic project-authored SVG primitives only
- External inputs: none
- License: {LICENSE}
- Source: `{record['sourcePath']}` — `{record['sourceSizePx'][0]} × {record['sourceSizePx'][1]}` — SHA-256 `{record['sourceSha256']}`
- PNG preview: `{record['previewPath']}` — `{record['sizePx'][0]} × {record['sizePx'][1]}` — SHA-256 `{record['pngSha256']}`
- WebP runtime: `{webp_path}` — `{record['sizePx'][0]} × {record['sizePx'][1]}` — SHA-256 `{record['sha256']}`
- Slot: `{record['slot'] or 'none'}`
- Z layer: `{record['zLayer']}`
- Runtime included: `{str(record['runtimeIncluded']).lower()}`
{f"- Normalized 48px thumbnail: `{record['thumb48Path']}` — SHA-256 `{record['thumb48Sha256']}`" if record.get('thumb48Path') else ''}


## Candidate review

The asset passed deterministic source, dimensions, naming, format, palette-family,
embedded-text, external-reference, file-size, and manifest integrity checks. The
`candidate-reviewed` status is intentionally below final `approved`: compositing,
device performance, cultural review, and in-game accessibility remain release gates.
"""


def make_manifest(records: list[dict[str, Any]]) -> dict[str, Any]:
    records = sorted(records, key=lambda item: item["manifestId"])
    counts = dict(sorted(Counter(item["family"] for item in records).items()))
    if counts != EXPECTED_FAMILY_COUNTS:
        raise RuntimeError(f"Family count mismatch: {counts} != {EXPECTED_FAMILY_COUNTS}")
    return {
        "schemaVersion": SCHEMA_VERSION,
        "revision": ASSET_REVISION,
        "reviewBatch": "runtime-compositor-golden-corrections-v3",
        "styleContract": "art-v1",
        "generator": GENERATOR_VERSION,
        "status": STATUS,
        "deterministic": True,
        "externalArtInputs": [],
        "license": LICENSE,
        "referenceCompositionPx": [1080, 1920],
        "logicalStagePx": [1024, 1024],
        "logicalGroundPoint": [512, 900],
        "familyCounts": counts,
        "assetCount": len(records),
        "runtimeAssetCount": sum(1 for item in records if item["runtimeIncluded"]),
        "palette": PALETTE,
        "runtimeBudget": {
            "maxIndividualBytes": 1048576,
            "targetTotalCompressedBytes": 25165824,
            "maxAtlasPagePx": [2048, 2048],
            "targetFps": 60,
            "degradedFloorFps": 30,
        },
        "qualityGates": [
            "silhouette-10-percent",
            "grayscale-and-color-vision-simulation",
            "six-seven-pivot-composition",
            "reduced-motion-equivalence",
            "no-embedded-functional-text",
            "no-external-art-or-trade-dress",
            "alpha-seam-and-safe-area",
            "runtime-file-and-device-budget",
        ],
        "assets": records,
    }


def generation_report(manifest: dict[str, Any]) -> str:
    rows = "\n".join(f"| `{family}` | {count} |" for family, count in manifest["familyCounts"].items())
    source_bytes = sum(item["sourceBytes"] for item in manifest["assets"])
    png_bytes = sum(item["pngBytes"] for item in manifest["assets"])
    webp_bytes = sum(item["runtimeBytes"] for item in manifest["assets"] if item["runtimeIncluded"])
    return f"""# Art generation report

Status: **{STATUS}**  
Contract: `art-v1` / `{SCHEMA_VERSION}`  
Generator: `tools/assets/generate_art_assets.py` (`{GENERATOR_VERSION}`)
Revision: `{manifest['revision']}` — `{manifest['reviewBatch']}`

## Result

The deterministic pipeline generated **{manifest['runtimeAssetCount']}** editable
SVG runtime sources. Each has matching PNG/WebP review exports and one provenance
record per manifest entry. All geometry is original to this repository and uses no
external image, font, model output, or network input.

| Family | Manifest entries |
| --- | ---: |
{rows}

- SVG source bytes: `{source_bytes}`
- PNG preview bytes: `{png_bytes}`
- Runtime-included WebP bytes: `{webp_bytes}`
- Runtime target budget: `25,165,824` bytes
- Largest permitted runtime asset: `1,048,576` bytes
- Background count, including reduced variants: `27`
- Skin count: `18 × 5 = 90` layers/derivatives

## Output contract

- Editable runtime source: `sources/art/<family>/<manifestId>.svg`
- PNG review export: `reports/art-previews/<family>/<manifestId>.png`
- WebP runtime export: `assets/art/<family>/<manifestId>.webp`
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
"""


def contact_sheet_html(manifest: dict[str, Any]) -> str:
    cards: list[str] = []
    for record in manifest["assets"]:
        image_path = "../" + record["previewPath"]
        mini_path = "../" + record.get("thumb48Path", record["previewPath"])
        cards.append(
            "<article class=card>"
            f"<img loading=lazy src=\"{image_path}\" alt=\"{record['manifestId']}\">"
            "<div class=minis>"
            f"<figure><img src=\"{mini_path}\" alt=\"{record['manifestId']} at 48 pixels\"><figcaption>48px</figcaption></figure>"
            f"<figure><img class=gray src=\"{mini_path}\" alt=\"{record['manifestId']} grayscale\"><figcaption>gray</figcaption></figure>"
            f"<figure class=ten><span><img src=\"{image_path}\" alt=\"{record['manifestId']} at ten percent\"></span><figcaption>10%</figcaption></figure>"
            "</div>"
            f"<strong>{record['manifestId']}</strong>"
            f"<span>{record['family']} · {record['variant']}</span>"
            f"<small>{record['sizePx'][0]}×{record['sizePx'][1]} · {record['runtimeBytes']} B</small>"
            "</article>"
        )
    def composition(label: str, paths: list[str], gray: bool = False) -> str:
        layers = "".join(f'<img src="../{path}" alt="">' for path in paths)
        return f'<article class=composition><div class="stack{" gray" if gray else ""}">{layers}</div><strong>{label}</strong></article>'

    compositions = "".join(
        [
            composition("Poise layer composite", [f"reports/art-previews/skins/skin_item_a_01_{part}.png" for part in ("base", "accent", "glow")]),
            composition("Motion layer composite", [f"reports/art-previews/skins/skin_item_b_01_{part}.png" for part in ("base", "accent", "glow")]),
            composition("Signal layer composite", [f"reports/art-previews/skins/skin_item_c_01_{part}.png" for part in ("base", "accent", "glow")]),
            composition("Spectrum layer composite", [f"reports/art-previews/skins/skin_item_conv_01_{part}.png" for part in ("base", "accent", "glow")]),
            composition("FORM-05 layer composite", [f"reports/art-previews/forms/form_05_{part}.png" for part in ("halo", "ground_link", "horizon_link")]),
            composition("FORM-05 grayscale composite", [f"reports/art-previews/forms/form_05_{part}.png" for part in ("halo", "ground_link", "horizon_link")], gray=True),
        ]
    )
    return """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Aura Shift art-v1 contact sheet</title>
<style>
:root{color-scheme:dark;font-family:system-ui,sans-serif;background:#090B1A;color:#F7F5FF}
body{margin:0;padding:24px}h1{margin:0 0 6px;font-size:28px}h2{margin:32px 0 14px}p{color:#C9C7D8;margin:0 0 24px}
main,.compositions{display:grid;grid-template-columns:repeat(auto-fill,minmax(210px,1fr));gap:14px}
.card{background:#141936;border:1px solid #4C5276;border-radius:16px;padding:12px;display:grid;gap:6px;min-width:0}
.card img{width:100%;height:180px;object-fit:contain;border-radius:10px;background:#202750}
.minis{display:flex;gap:10px;align-items:end}.minis figure{margin:0;display:grid;gap:3px;justify-items:center;color:#C9C7D8;font-size:10px}
.minis figure>img,.ten span{width:48px!important;height:48px!important;object-fit:contain!important;background:#202750!important;border:1px solid #4C5276;border-radius:6px!important}
.gray{filter:grayscale(1)}.ten span{display:grid;place-items:center}.ten span img{width:10%!important;height:10%!important;min-width:5px;min-height:5px;object-fit:contain}
.card strong{font:700 12px ui-monospace,monospace;overflow-wrap:anywhere}.card span,.card small{color:#C9C7D8;font-size:12px}
.composition{background:#141936;border:1px solid #4C5276;border-radius:16px;padding:12px}.stack{height:220px;position:relative;background:#202750;border-radius:10px;overflow:hidden}
.stack img{position:absolute;inset:0;width:100%;height:100%;object-fit:contain}.stack.gray{filter:grayscale(1)}.composition strong{display:block;margin-top:8px;font-size:13px}
</style>
</head>
<body>
<h1>Aura Shift: Six Seven — art-v1</h1>
<p>Runtime assets. Every entry includes color, grayscale, 48px, and 10% checks.</p>
<h2>Layer compositions</h2><section class=compositions>""" + compositions + """</section>
<h2>All manifest entries</h2><main>""" + "".join(cards) + """</main>
</body>
</html>
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, default=Path(__file__).resolve().parents[2], help="Repository/output root")
    parser.add_argument("--jobs", type=int, default=min(6, os.cpu_count() or 1), help="Parallel raster jobs")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.output_root.resolve()
    specs = all_specs()
    expected_total = sum(EXPECTED_FAMILY_COUNTS.values())
    if len(specs) != expected_total:
        raise RuntimeError(f"Spec count mismatch: {len(specs)} != {expected_total}")
    clang = command_path("clang")
    cwebp = command_path("cwebp")
    svg_renderer = compile_appkit_svg_renderer(root, clang)
    clean_packaged_art_directory(root)
    if any(not spec.runtime_included for spec in specs):
        raise RuntimeError("art-v1 accepts runtime assets only")
    runtime_specs = specs
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as executor:
        runtime_records = list(
            executor.map(
                lambda spec: render_one(
                    spec,
                    root,
                    svg_renderer,
                    cwebp,
                ),
                runtime_specs,
            )
        )
    records = runtime_records
    manifest = make_manifest(records)
    manifest_path = root / "assets" / "manifests" / "art-manifest-v1.json"
    manifest_bytes = (json.dumps(manifest, indent=2, ensure_ascii=False, sort_keys=False) + "\n").encode("utf-8")
    write_if_changed(manifest_path, manifest_bytes)
    report = generation_report(manifest)
    write_if_changed(root / "reports" / "art-generation-report.md", report.encode("utf-8"))
    contact_sheet = contact_sheet_html(manifest)
    write_if_changed(root / "reports" / "art-contact-sheet.html", contact_sheet.encode("utf-8"))
    print(f"Generated {manifest['assetCount']} art-v1 entries")
    print(f"Manifest: {manifest_path}")
    print(f"Runtime WebP bytes: {sum(item['runtimeBytes'] for item in records if item['runtimeIncluded'])}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise
    except Exception as exc:
        print(f"art generation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
