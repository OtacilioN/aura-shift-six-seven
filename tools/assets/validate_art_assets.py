#!/usr/bin/env python3
"""Validate completeness, integrity, safety, budgets, and determinism of art-v1."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

from art_library import (
    BACKGROUND_IDS,
    EXPECTED_FAMILY_COUNTS,
    PALETTE,
    SKIN_ATTACHMENTS,
    SKIN_META,
    SLOT_PIVOTS,
    SLOT_Z,
)


EXPECTED_TOTAL = sum(EXPECTED_FAMILY_COUNTS.values())
MAX_RUNTIME_BYTES = 1_048_576
MAX_TOTAL_BYTES = 25_165_824
HEX_RE = re.compile(rb"#[0-9A-Fa-f]{6}")


class ValidationError(RuntimeError):
    pass


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        raise ValidationError(f"invalid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def webp_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:40]
    if len(data) < 30 or data[:4] != b"RIFF" or data[8:12] != b"WEBP":
        raise ValidationError(f"invalid WebP: {path}")
    kind = data[12:16]
    payload = 20
    if kind == b"VP8X":
        width = int.from_bytes(data[payload + 4 : payload + 7], "little") + 1
        height = int.from_bytes(data[payload + 7 : payload + 10], "little") + 1
        return width, height
    if kind == b"VP8L":
        if data[payload] != 0x2F:
            raise ValidationError(f"invalid VP8L signature: {path}")
        bits = int.from_bytes(data[payload + 1 : payload + 5], "little")
        return (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1
    if kind == b"VP8 ":
        if data[payload + 3 : payload + 6] != b"\x9d\x01\x2a":
            raise ValidationError(f"invalid VP8 signature: {path}")
        width = int.from_bytes(data[payload + 6 : payload + 8], "little") & 0x3FFF
        height = int.from_bytes(data[payload + 8 : payload + 10], "little") & 0x3FFF
        return width, height
    raise ValidationError(f"unsupported WebP chunk {kind!r}: {path}")


def load_manifest(root: Path) -> tuple[Path, dict[str, Any]]:
    path = root / "assets" / "manifests" / "art-manifest-v1.json"
    if not path.exists():
        raise ValidationError(f"missing manifest: {path}")
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        raise ValidationError(f"cannot read manifest: {exc}") from exc
    return path, manifest


def validate_svg(
    project_root: Path,
    path: Path,
    record: dict[str, Any],
    runtime_paths: set[str],
) -> None:
    data = path.read_bytes()
    if b"<text" in data:
        raise ValidationError(f"text element in {path}")
    if record.get("runtimeIncluded") and (b"<image" in data or b"href=" in data):
        raise ValidationError(f"runtime SVG contains image/href in {path}")
    allowed_colors = {value.upper().encode("ascii") for value in PALETTE.values()}
    colors = {match.upper() for match in HEX_RE.findall(data)}
    unexpected = colors - allowed_colors
    if unexpected:
        raise ValidationError(f"non-art-v1 colors in {path}: {sorted(item.decode() for item in unexpected)}")
    try:
        root = ET.fromstring(data)
    except ET.ParseError as exc:
        raise ValidationError(f"invalid SVG XML {path}: {exc}") from exc
    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise ValidationError(f"root is not SVG: {path}")
    width = int(float(root.attrib["width"]))
    height = int(float(root.attrib["height"]))
    if [width, height] != record["sourceSizePx"]:
        raise ValidationError(f"source dimensions mismatch in {path}: {(width, height)}")
    qa_hrefs: set[str] = set()
    for element in root.iter():
        local_name = element.tag.rsplit("}", 1)[-1]
        if local_name in {"text", "foreignObject", "script"}:
            raise ValidationError(f"forbidden SVG element {local_name} in {path}")
        for attr_name, value in element.attrib.items():
            if attr_name.rsplit("}", 1)[-1] in {"href", "src"}:
                if record.get("runtimeIncluded") or local_name != "image":
                    raise ValidationError(f"unexpected reference attribute in {path}: {value}")
                if value.startswith(("http:", "https:", "data:", "/")):
                    raise ValidationError(f"non-local QA sprite reference in {path}: {value}")
                resolved = (path.parent / value).resolve()
                try:
                    relative = resolved.relative_to(project_root.resolve()).as_posix()
                except ValueError as exc:
                    raise ValidationError(f"QA reference escapes project root: {value}") from exc
                if relative not in runtime_paths or not resolved.is_file():
                    raise ValidationError(f"QA does not reference a runtimePath: {value} -> {relative}")
                qa_hrefs.add(relative)
    if not record.get("runtimeIncluded"):
        expected_ids = set(record.get("composedFromRuntimeIds", []))
        referenced_ids = {
            Path(runtime_path).stem
            for runtime_path in qa_hrefs
        }
        if not qa_hrefs or not expected_ids.issubset(referenced_ids):
            raise ValidationError(
                f"QA source is not composed from declared runtime sprites: {path}; "
                f"missing={sorted(expected_ids - referenced_ids)}"
            )


def validate_qa_composition_source(
    path: Path,
    record: dict[str, Any],
    by_id: dict[str, dict[str, Any]],
) -> None:
    if path.suffix != ".json" or record.get("sourceFormat") != "json":
        raise ValidationError(f"QA source must be JSON: {path}")
    try:
        source = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        raise ValidationError(f"invalid QA composition JSON {path}: {exc}") from exc
    if (
        source.get("schemaVersion") != "art-runtime-composition-v1"
        or source.get("revision") != 3
        or source.get("manifestId") != record["manifestId"]
        or source.get("compositionContract") != "runtime-sprites-pivots-attachments-v3"
    ):
        raise ValidationError(f"invalid QA composition identity: {path}")
    expected_ids = set(record.get("composedFromRuntimeIds", []))
    inputs = source.get("runtimeInputs")
    if not isinstance(inputs, list) or {item.get("manifestId") for item in inputs if isinstance(item, dict)} != expected_ids:
        raise ValidationError(f"QA runtime input set mismatch: {path}")
    mirrored_keys = (
        "runtimePath", "pivot", "logicalSizeStagePx", "attachmentId",
        "attachmentStage", "endpointPx", "visualCenterPx",
        "poseAttachments", "poseAnglesDegrees",
    )
    for item in inputs:
        if not isinstance(item, dict):
            raise ValidationError(f"invalid QA runtime input: {path}")
        actual = by_id[item["manifestId"]]
        if item.get("runtimeSha256") != actual["sha256"]:
            raise ValidationError(f"QA runtime hash drift: {path}/{item['manifestId']}")
        for key in mirrored_keys:
            if item.get(key) != actual.get(key):
                raise ValidationError(f"QA {key} drift: {path}/{item['manifestId']}")
    commands = source.get("renderCommands")
    if not isinstance(commands, list) or not commands:
        raise ValidationError(f"QA source has no renderCommands: {path}")
    sprite_commands = [item for item in commands if isinstance(item, dict) and item.get("type") == "sprite"]
    if not sprite_commands:
        raise ValidationError(f"QA source has no runtime sprite commands: {path}")
    for command in sprite_commands:
        asset_id = command.get("manifestId")
        if asset_id not in expected_ids:
            raise ValidationError(f"QA command uses undeclared runtime sprite: {path}/{asset_id}")
        actual = by_id[asset_id]
        if command.get("runtimePath") != actual.get("runtimePath") or command.get("runtimeSha256") != actual.get("sha256"):
            raise ValidationError(f"QA render command runtime drift: {path}/{asset_id}")
        matrix = command.get("matrix")
        if not isinstance(matrix, list) or len(matrix) != 6 or any(not isinstance(value, (int, float)) for value in matrix):
            raise ValidationError(f"QA render command matrix invalid: {path}/{asset_id}")
    view_ids = set(source.get("views", []))
    command_views = {item.get("viewId") for item in sprite_commands}
    if not view_ids.issubset(command_views):
        raise ValidationError(f"QA render commands omit views: {path}/{sorted(view_ids - command_views)}")


def validate_skin_matrix(records: list[dict[str, Any]]) -> None:
    variants: dict[str, set[str]] = defaultdict(set)
    for record in records:
        if record["family"] != "skins":
            continue
        match = re.fullmatch(r"skin_(item_(?:a|b|c)_\d{2}|item_conv_\d{2})_(base|accent|glow|reduced|thumb)", record["manifestId"])
        if not match:
            raise ValidationError(f"invalid skin ID: {record['manifestId']}")
        variants[match.group(1)].add(match.group(2))
    expected_items = {item_id for item_id, _, _, _ in SKIN_META}
    if set(variants) != expected_items:
        raise ValidationError(f"skin item set mismatch: {set(variants) ^ expected_items}")
    expected_variants = {"base", "accent", "glow", "reduced", "thumb"}
    by_id = {record["manifestId"]: record for record in records}
    slots = {item_id: slot for item_id, _, slot, _ in SKIN_META}
    for item_id, actual in variants.items():
        if actual != expected_variants:
            raise ValidationError(f"skin variants mismatch for {item_id}: {actual}")
        side, subslot, offset = SKIN_ATTACHMENTS[item_id]
        expected_slot = slots[item_id]
        for variant in expected_variants:
            record = by_id[f"skin_{item_id}_{variant}"]
            if record.get("slot") != expected_slot:
                raise ValidationError(
                    f"invalid slot for {record['manifestId']}: {record.get('slot')} != {expected_slot}"
                )
            if record.get("zLayer") != SLOT_Z[expected_slot]:
                raise ValidationError(
                    f"invalid zLayer for {record['manifestId']}: {record.get('zLayer')} != {SLOT_Z[expected_slot]}"
                )
            if record["pivot"] != list(SLOT_PIVOTS[expected_slot]):
                raise ValidationError(f"non-canonical slot pivot: {record['manifestId']} {record['pivot']}")
            expected_metadata = {
                "side": side,
                "subslot": subslot,
                "offsetNormalized": list(offset),
                "milestoneProfile": f"{item_id}_v1",
                "reducedId": f"skin_{item_id}_reduced",
            }
            for key, value in expected_metadata.items():
                if record.get(key) != value:
                    raise ValidationError(f"invalid {key} for {record['manifestId']}: {record.get(key)} != {value}")
            if record["reducedId"] not in by_id:
                raise ValidationError(f"missing reducedId target for {record['manifestId']}")


def validate_manifest(root: Path, manifest: dict[str, Any]) -> list[str]:
    checks: list[str] = []
    if manifest.get("schemaVersion") != "art-manifest-v1":
        raise ValidationError("wrong schemaVersion")
    if manifest.get("styleContract") != "art-v1":
        raise ValidationError("wrong styleContract")
    if manifest.get("status") != "candidate-reviewed":
        raise ValidationError("manifest status must be candidate-reviewed")
    if manifest.get("generator") != "art-generator-v4":
        raise ValidationError("manifest generator must be art-generator-v4")
    if manifest.get("revision") != 3 or manifest.get("reviewBatch") != "runtime-compositor-golden-corrections-v3":
        raise ValidationError("manifest must record revision-3 runtime compositor golden corrections")
    records = manifest.get("assets")
    if not isinstance(records, list) or len(records) != EXPECTED_TOTAL:
        raise ValidationError(f"expected {EXPECTED_TOTAL} assets, got {len(records) if isinstance(records, list) else 'invalid'}")
    ids = [item.get("manifestId") for item in records]
    if len(ids) != len(set(ids)):
        raise ValidationError("duplicate manifest IDs")
    family_counts = dict(sorted(Counter(item["family"] for item in records).items()))
    if family_counts != EXPECTED_FAMILY_COUNTS or manifest.get("familyCounts") != EXPECTED_FAMILY_COUNTS:
        raise ValidationError(f"family counts mismatch: {family_counts}")
    checks.append("manifest-schema-counts-and-unique-ids")

    background_ids = {item["manifestId"] for item in records if item["family"] == "backgrounds"}
    if background_ids != set(BACKGROUND_IDS):
        raise ValidationError(f"background matrix mismatch: {background_ids ^ set(BACKGROUND_IDS)}")
    validate_skin_matrix(records)
    checks.append("exact-27-background-and-18x5-skin-matrices")
    checks.append("canonical-skin-pivots-side-offset-milestone-reduced-metadata")

    if any(item.get("family") == "qa" for item in records):
        raise ValidationError("legacy character QA sheets must not remain in art-v1")
    if sum(1 for item in records if item.get("runtimeIncluded")) != 202 or manifest.get("runtimeAssetCount") != 202:
        raise ValidationError("runtime asset count changed; expected 202 current IDs")

    total_runtime = 0
    records_by_id = {item["manifestId"]: item for item in records}
    runtime_paths = {
        item["runtimePath"]
        for item in records
        if item.get("runtimeIncluded") and isinstance(item.get("runtimePath"), str)
    }
    for record in records:
        if record.get("status") != "candidate-reviewed" or record.get("revision") != 3:
            raise ValidationError(f"invalid status/revision: {record.get('manifestId')}")
        source = root / record["sourcePath"]
        png = root / record["previewPath"]
        webp_path_value = record.get("runtimePath") or record.get("reviewWebpPath")
        if not webp_path_value:
            raise ValidationError(f"missing WebP export path: {record['manifestId']}")
        webp = root / webp_path_value
        provenance = root / record["licenseRecord"]
        for path in (source, png, webp, provenance):
            if not path.is_file():
                raise ValidationError(f"missing referenced file: {path}")
        if record.get("runtimeIncluded"):
            validate_svg(root, source, record, runtime_paths)
        else:
            validate_qa_composition_source(source, record, records_by_id)
        if sha256_file(source) != record["sourceSha256"]:
            raise ValidationError(f"source hash mismatch: {source}")
        if sha256_file(png) != record["pngSha256"]:
            raise ValidationError(f"PNG hash mismatch: {png}")
        if sha256_file(webp) != record["sha256"]:
            raise ValidationError(f"WebP hash mismatch: {webp}")
        expected_size = tuple(record["sizePx"])
        if png_dimensions(png) != expected_size:
            raise ValidationError(f"PNG dimensions mismatch: {png}")
        if webp_dimensions(webp) != expected_size:
            raise ValidationError(f"WebP dimensions mismatch: {webp}")
        if record["sourceBytes"] != source.stat().st_size or record["pngBytes"] != png.stat().st_size or record["runtimeBytes"] != webp.stat().st_size:
            raise ValidationError(f"recorded file size mismatch: {record['manifestId']}")
        if record.get("runtimeIncluded") and webp.stat().st_size > MAX_RUNTIME_BYTES:
            raise ValidationError(f"runtime asset exceeds 1 MiB: {webp}")
        if record.get("runtimeIncluded"):
            total_runtime += webp.stat().st_size
        if record.get("variant") == "thumb":
            thumb_path_value = record.get("thumb48Path")
            if not thumb_path_value:
                raise ValidationError(f"missing 48px thumbnail derivative: {record['manifestId']}")
            thumb_path = root / thumb_path_value
            if not thumb_path.is_file() or png_dimensions(thumb_path) != (48, 48):
                raise ValidationError(f"invalid 48px thumbnail derivative: {thumb_path}")
            if sha256_file(thumb_path) != record.get("thumb48Sha256") or thumb_path.stat().st_size != record.get("thumb48Bytes"):
                raise ValidationError(f"48px thumbnail hash/size mismatch: {thumb_path}")
            if record.get("normalizedThumbnailPx") != 48:
                raise ValidationError(f"thumbnail not normalized for 48px: {record['manifestId']}")
        provenance_text = provenance.read_text(encoding="utf-8")
        for required in (record["manifestId"], record["sourceSha256"], record["pngSha256"], record["sha256"], "candidate-reviewed", "External inputs: none"):
            if required not in provenance_text:
                raise ValidationError(f"incomplete provenance {provenance}: missing {required}")
    if total_runtime > MAX_TOTAL_BYTES:
        raise ValidationError(f"total runtime art exceeds budget: {total_runtime}")
    packaged_art = root / "assets" / "art"
    packaged_files = [path for path in packaged_art.rglob("*") if path.is_file()]
    if len(packaged_files) != 202 or any(path.suffix != ".webp" or "qa" in path.parts for path in packaged_files):
        invalid = [str(path.relative_to(root)) for path in packaged_files if path.suffix != ".webp" or "qa" in path.parts]
        raise ValidationError(f"assets/art must contain exactly 202 runtime WebPs and no previews/QA; invalid={invalid}")
    if any(not str(item.get("previewPath", "")).startswith("reports/art-previews/") for item in records):
        raise ValidationError("PNG previews must live under reports/art-previews")
    background_hashes = [item["pngSha256"] for item in records if item["family"] == "backgrounds"]
    if len(background_hashes) != len(set(background_hashes)):
        duplicates = [value for value, count in Counter(background_hashes).items() if count > 1]
        duplicate_ids = [[item["manifestId"] for item in records if item.get("pngSha256") == value] for value in duplicates]
        raise ValidationError(f"duplicate background pixels: {duplicate_ids}")
    contact_sheet = root / "reports" / "art-contact-sheet.html"
    if not contact_sheet.is_file():
        raise ValidationError(f"missing contact sheet: {contact_sheet}")
    contact_html = contact_sheet.read_text(encoding="utf-8")
    if contact_html.count("<article class=card>") != EXPECTED_TOTAL:
        raise ValidationError("contact sheet does not contain exactly one card per manifest entry")
    for record in records:
        expected_reference = "../" + record["previewPath"]
        if expected_reference not in contact_html:
            raise ValidationError(f"contact sheet missing {record['manifestId']}")
    required_compositions = ("Poise layer composite", "Motion layer composite", "Signal layer composite", "Spectrum layer composite", "FORM-05 layer composite", "FORM-05 grayscale composite")
    if any(label not in contact_html for label in required_compositions) or "48px" not in contact_html or "10%" not in contact_html or "gray" not in contact_html:
        raise ValidationError("contact sheet is missing composition, grayscale, 10%, or 48px review modes")
    checks += ["files-hashes-dimensions-provenance", "runtime-svg-no-external-art-or-text", "palette-whitelist", "runtime-size-budgets", "runtime-only-assets-art-tree", "unique-background-pixels", "normalized-48px-thumbnails", "contact-sheet-all-entries-and-compositions"]
    return checks


def validate_determinism(root: Path, manifest_path: Path, manifest: dict[str, Any]) -> str:
    generator = Path(__file__).with_name("generate_art_assets.py")
    with tempfile.TemporaryDirectory(prefix="aura-art-determinism-") as tmp:
        temp_root = Path(tmp)
        completed = subprocess.run(
            [sys.executable, str(generator), "--output-root", str(temp_root), "--jobs", "6"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if completed.returncode != 0:
            raise ValidationError(f"determinism regeneration failed:\n{completed.stdout}")
        temp_manifest_path = temp_root / "assets" / "manifests" / "art-manifest-v1.json"
        if manifest_path.read_bytes() != temp_manifest_path.read_bytes():
            original = manifest
            regenerated = json.loads(temp_manifest_path.read_text(encoding="utf-8"))
            for left, right in zip(original["assets"], regenerated["assets"], strict=True):
                for key in ("sourceSha256", "pngSha256", "sha256"):
                    if left[key] != right[key]:
                        raise ValidationError(f"non-deterministic {key} for {left['manifestId']}: {left[key]} != {right[key]}")
            raise ValidationError("manifest bytes drifted despite matching asset hashes")
        for record in manifest["assets"]:
            for key in ("sourcePath", "previewPath", "runtimePath", "reviewWebpPath", "licenseRecord", "thumb48Path"):
                path_value = record.get(key)
                if path_value and sha256_file(root / path_value) != sha256_file(temp_root / path_value):
                    raise ValidationError(f"non-deterministic file {path_value}")
    return "full-regeneration-byte-determinism"


def validation_report(manifest: dict[str, Any], checks: list[str], deterministic: bool) -> str:
    rows = "\n".join(f"- PASS — `{check}`" for check in checks)
    runtime_records = [item for item in manifest["assets"] if item["runtimeIncluded"]]
    total = sum(item["runtimeBytes"] for item in runtime_records)
    largest = max(runtime_records, key=lambda item: item["runtimeBytes"])
    return f"""# Art validation report

Result: **PASS**
Manifest: `assets/manifests/art-manifest-v1.json`
Entries: `{manifest['assetCount']}`
Status: `candidate-reviewed`

{rows}

## Budgets

- Runtime WebP total: `{total}` / `{MAX_TOTAL_BYTES}` bytes
- Largest runtime entry: `{largest['manifestId']}` at `{largest['runtimeBytes']}` / `{MAX_RUNTIME_BYTES}` bytes
- Byte-for-byte regeneration: `{'PASS' if deterministic else 'NOT RUN'}`

## Residual review

Automated validation does not promote assets to `approved`. Review the generated
contact sheet and in-game composites for silhouette, cultural ambiguity, color
vision deficiencies, reduced-motion equivalence, safe areas, and target-device
performance before release.
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--determinism", action="store_true", help="Regenerate into a temporary root and compare every byte")
    parser.add_argument("--no-report", action="store_true", help="Do not write reports/art-validation-report.md")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    manifest_path, manifest = load_manifest(root)
    checks = validate_manifest(root, manifest)
    if args.determinism:
        checks.append(validate_determinism(root, manifest_path, manifest))
    if not args.no_report:
        report_path = root / "reports" / "art-validation-report.md"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(validation_report(manifest, checks, args.determinism), encoding="utf-8")
    print(f"PASS: {len(manifest['assets'])} art-v1 entries; {len(checks)} validation gates")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
