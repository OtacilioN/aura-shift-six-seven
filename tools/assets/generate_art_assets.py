#!/usr/bin/env python3
"""Generate the complete deterministic art-v1 asset catalog.

Runtime SVG files in ``sources/art`` are canonical editable sources. The QA
JSON files are canonical compositor recipes over the exported runtime WebPs.
PNG previews are normalized to remove incidental metadata, and runtime WebP
files are encoded with cwebp.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
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


def compile_coregraphics_qa_renderer(root: Path, clang: str) -> tuple[Path, str]:
    template = Path(__file__).with_name("render_art_qa.m")
    renderer_source = root / "tools" / "assets" / "render_art_qa.m"
    source_bytes = template.read_bytes()
    write_if_changed(renderer_source, source_bytes)
    renderer_hash = sha256_bytes(source_bytes)[:16]
    build_root = Path(tempfile.gettempdir()) / "aura-shift-qa-renderer"
    build_root.mkdir(parents=True, exist_ok=True)
    module_cache = build_root / "clang-module-cache"
    module_cache.mkdir(parents=True, exist_ok=True)
    executable = build_root / f"render-art-qa-{renderer_hash}"
    temporary = executable.with_name(f".{executable.name}.tmp-{os.getpid()}")
    env = dict(os.environ)
    env["CLANG_MODULE_CACHE_PATH"] = str(module_cache)
    completed = subprocess.run(
        [
            clang,
            "-fobjc-arc",
            "-O2",
            "-framework",
            "CoreGraphics",
            "-framework",
            "Foundation",
            "-framework",
            "ImageIO",
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
            f"CoreGraphics QA renderer compilation failed: "
            f"{completed.stdout.strip()}"
        )
    os.replace(temporary, executable)
    return renderer_source, str(executable)


def clean_packaged_art_directory(root: Path) -> None:
    """Keep the pubspec-facing art tree runtime-only.

    Earlier revisions stored review PNGs beside runtime WebPs. Remove those
    generated previews and any review-only QA directory before every run.
    """
    art_root = root / "assets" / "art"
    if not art_root.exists():
        return
    for png in art_root.rglob("*.png"):
        png.unlink()
    qa_directory = art_root / "qa"
    if qa_directory.exists():
        shutil.rmtree(qa_directory)


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


Matrix = tuple[float, float, float, float, float, float]


def _matrix_multiply(left: Matrix, right: Matrix) -> Matrix:
    a1, b1, c1, d1, tx1, ty1 = left
    a2, b2, c2, d2, tx2, ty2 = right
    return (
        a1 * a2 + c1 * b2,
        b1 * a2 + d1 * b2,
        a1 * c2 + c1 * d2,
        b1 * c2 + d1 * d2,
        a1 * tx2 + c1 * ty2 + tx1,
        b1 * tx2 + d1 * ty2 + ty1,
    )


def _translate(x: float, y: float) -> Matrix:
    return (1, 0, 0, 1, x, y)


def _scale(x: float, y: float | None = None) -> Matrix:
    return (x, 0, 0, x if y is None else y, 0, 0)


def _rotate_degrees(degrees: float) -> Matrix:
    angle = math.radians(degrees)
    return (math.cos(angle), math.sin(angle), -math.sin(angle), math.cos(angle), 0, 0)


def _skew_y(degrees: float) -> Matrix:
    return (1, math.tan(math.radians(degrees)), 0, 1, 0, 0)


def _compose(*matrices: Matrix) -> Matrix:
    result: Matrix = (1, 0, 0, 1, 0, 0)
    for matrix in matrices:
        result = _matrix_multiply(result, matrix)
    return result


def _sprite_command(
    record: dict[str, Any],
    matrix: Matrix,
    *,
    tint: str | None = None,
    view_id: str | None = None,
) -> dict[str, Any]:
    command: dict[str, Any] = {
        "type": "sprite",
        "manifestId": record["manifestId"],
        "runtimePath": record["runtimePath"],
        "runtimeSha256": record["sha256"],
        "logicalSize": record.get("logicalSizeStagePx") or record["sourceSizePx"],
        "matrix": [round(value, 9) for value in matrix],
    }
    if tint is not None:
        command["tint"] = tint
    if view_id is not None:
        command["viewId"] = view_id
    return command


def _attached_matrix(
    record: dict[str, Any],
    attachment: list[float],
    *,
    angle_degrees: float = 0,
    scale: float = 1,
) -> Matrix:
    logical = record.get("logicalSizeStagePx") or record["sourceSizePx"]
    pivot_x = record["pivot"][0] * logical[0]
    pivot_y = record["pivot"][1] * logical[1]
    return _compose(
        _translate(attachment[0], attachment[1]),
        _rotate_degrees(angle_degrees),
        _scale(scale),
        _translate(-pivot_x, -pivot_y),
    )


def _arm_matrix(record: dict[str, Any], wrist: list[float]) -> Matrix:
    logical = record["logicalSizeStagePx"]
    shoulder = record["attachmentStage"]
    endpoint = record["endpointPx"]
    pivot_x = record["pivot"][0] * logical[0]
    pivot_y = record["pivot"][1] * logical[1]
    source_x = endpoint[0] - pivot_x
    source_y = endpoint[1] - pivot_y
    target_x = wrist[0] - shoulder[0]
    target_y = wrist[1] - shoulder[1]
    scale = math.hypot(target_x, target_y) / math.hypot(source_x, source_y)
    angle = math.degrees(math.atan2(target_y, target_x) - math.atan2(source_y, source_x))
    return _attached_matrix(record, shoulder, angle_degrees=angle, scale=scale)


def _rig_render_commands(
    records: dict[str, dict[str, Any]],
    *,
    view_id: str,
    pose: str,
    expression: str,
    outer: Matrix,
    silhouette: bool = False,
) -> list[dict[str, Any]]:
    left_hand = records["chr_hand_l"]
    right_hand = records["chr_hand_r"]
    left_wrist = left_hand["poseAttachments"][pose]
    right_wrist = right_hand["poseAttachments"][pose]
    eyes = records[f"chr_eye_{expression}"]
    mouth = records[f"chr_mouth_{expression}"]
    tint = PALETTE["ink_900"] if silhouette else None
    layers = [
        (records["chr_shadow"], _attached_matrix(records["chr_shadow"], records["chr_shadow"]["attachmentStage"])),
        (records["chr_arm_l"], _arm_matrix(records["chr_arm_l"], left_wrist)),
        (records["chr_arm_r"], _arm_matrix(records["chr_arm_r"], right_wrist)),
        (records["chr_body_base"], (1, 0, 0, 1, 0, 0)),
        (eyes, _attached_matrix(eyes, eyes["attachmentStage"])),
        (mouth, _attached_matrix(mouth, mouth["attachmentStage"])),
        (left_hand, _attached_matrix(left_hand, left_wrist, angle_degrees=left_hand["poseAnglesDegrees"][pose])),
        (right_hand, _attached_matrix(right_hand, right_wrist, angle_degrees=right_hand["poseAnglesDegrees"][pose])),
    ]
    return [
        _sprite_command(record, _matrix_multiply(outer, local), tint=tint, view_id=view_id)
        for record, local in layers
    ]


def _rect_command(
    x: float,
    y: float,
    width: float,
    height: float,
    *,
    fill: str,
    radius: float = 0,
    stroke: str | None = None,
    stroke_width: float = 0,
) -> dict[str, Any]:
    command: dict[str, Any] = {
        "type": "rect", "x": x, "y": y, "width": width, "height": height,
        "radius": radius, "fill": fill,
    }
    if stroke is not None:
        command.update({"stroke": stroke, "strokeWidth": stroke_width})
    return command


def _qa_render_commands(
    spec: AssetSpec,
    records: dict[str, dict[str, Any]],
) -> list[dict[str, Any]]:
    commands: list[dict[str, Any]] = []
    if spec.manifest_id == "chr_composite_qa":
        commands += [
            _rect_command(0, 0, 2160, 2160, fill=PALETTE["ink_900"]),
            _rect_command(70, 70, 2020, 2020, fill=PALETTE["ink_700"], radius=120, stroke=PALETTE["divider"], stroke_width=22),
        ]
        commands += _rig_render_commands(records, view_id="golden_six_runtime", pose="six", expression="neutral", outer=_compose(_translate(80, 380), _scale(0.92)))
        commands += _rig_render_commands(records, view_id="golden_seven_runtime", pose="seven", expression="satisfaction", outer=_compose(_translate(1140, 380), _scale(0.92)))
    elif spec.manifest_id == "chr_silhouette_test":
        commands += [
            _rect_command(0, 0, 2160, 2160, fill=PALETTE["paper_050"]),
            _rect_command(60, 60, 1320, 2040, fill=PALETTE["paper_050"], radius=120, stroke=PALETTE["ink_900"], stroke_width=28),
            _rect_command(1450, 120, 620, 620, fill=PALETTE["paper_050"], radius=72, stroke=PALETTE["ink_900"], stroke_width=22),
            _rect_command(1450, 790, 620, 620, fill=PALETTE["ink_700"], radius=72, stroke=PALETTE["ink_900"], stroke_width=22),
            _rect_command(1450, 1460, 620, 620, fill=PALETTE["ink_700"], radius=72, stroke=PALETTE["ink_900"], stroke_width=22),
        ]
        commands += _rig_render_commands(records, view_id="silhouette_full_runtime", pose="six", expression="neutral", outer=_compose(_translate(180, 450), _scale(1.02)), silhouette=True)
        commands += _rig_render_commands(records, view_id="silhouette_ten_percent_runtime", pose="six", expression="neutral", outer=_compose(_translate(1708, 365), _scale(0.10)), silhouette=True)
        commands += _rig_render_commands(records, view_id="golden_48px_runtime", pose="seven", expression="satisfaction", outer=_compose(_translate(1712, 1042), _scale(0.09375)))
        commands += _rig_render_commands(records, view_id="golden_reduced_scale_runtime", pose="neutral", expression="neutral", outer=_compose(_translate(1608, 1620), _scale(0.30)))
    else:
        commands.append(_rect_command(0, 0, 2160, 2160, fill=PALETTE["ink_900"]))
        panels = [
            ("view_front_neutral", "neutral", "neutral", _compose(_translate(92, 180), _scale(0.56)), False),
            ("view_front_six", "six", "neutral", _compose(_translate(778, 180), _scale(0.56)), False),
            ("view_front_seven", "seven", "satisfaction", _compose(_translate(1464, 180), _scale(0.56)), False),
            ("view_three_quarter_left", "neutral", "neutral", _compose(_translate(160, 1160), _scale(0.46, 0.56), _skew_y(-2)), False),
            ("view_profile_technical", "neutral", "neutral", _compose(_translate(920, 1160), _scale(0.30, 0.56)), False),
            ("view_silhouette_ten_percent", "six", "neutral", _compose(_translate(1750, 1430), _scale(0.10)), True),
        ]
        for index, (view_id, pose, expression, outer, silhouette) in enumerate(panels):
            commands.append(_rect_command(50 + (index % 3) * 700, 50 + (index // 3) * 1040, 660, 1000, fill=PALETTE["ink_700"], radius=90, stroke=PALETTE["divider"], stroke_width=18))
            commands += _rig_render_commands(records, view_id=view_id, pose=pose, expression=expression, outer=outer, silhouette=silhouette)
        for idx, color in enumerate((PALETTE["ink_900"], PALETTE["ink_700"], PALETTE["paper_050"], PALETTE["aura_violet"], PALETTE["aura_cyan"], PALETTE["aura_magenta"], PALETTE["aura_gold"], PALETTE["aura_mint"])):
            commands.append(_rect_command(190 + idx * 222, 2010, 150, 78, fill=color, radius=28, stroke=PALETTE["ink_900"], stroke_width=12))
    return commands


def qa_composition_source(
    spec: AssetSpec,
    runtime_records: dict[str, dict[str, Any]],
) -> str:
    runtime_ids = dict(spec.metadata).get("composedFromRuntimeIds", [])
    views = {
        "chr_composite_qa": ["golden_six_runtime", "golden_seven_runtime"],
        "chr_silhouette_test": [
            "silhouette_full_runtime", "silhouette_ten_percent_runtime",
            "golden_48px_runtime", "golden_reduced_scale_runtime",
        ],
        "chr_concept_sheet": [
            "view_front_neutral", "view_front_six", "view_front_seven",
            "view_three_quarter_left", "view_profile_technical",
            "view_silhouette_ten_percent",
        ],
    }[spec.manifest_id]
    inputs: list[dict[str, Any]] = []
    for asset_id in runtime_ids:
        record = runtime_records[asset_id]
        inputs.append(
            {
                "manifestId": asset_id,
                "runtimePath": record["runtimePath"],
                "runtimeSha256": record["sha256"],
                "pivot": record["pivot"],
                "logicalSizeStagePx": record.get("logicalSizeStagePx"),
                "attachmentId": record.get("attachmentId"),
                "attachmentStage": record.get("attachmentStage"),
                "endpointPx": record.get("endpointPx"),
                "visualCenterPx": record.get("visualCenterPx"),
                "poseAttachments": record.get("poseAttachments"),
                "poseAnglesDegrees": record.get("poseAnglesDegrees"),
            }
        )
    payload = {
        "schemaVersion": "art-runtime-composition-v1",
        "revision": ASSET_REVISION,
        "manifestId": spec.manifest_id,
        "compositionContract": "runtime-sprites-pivots-attachments-v3",
        "sourceSizePx": list(spec.source_size),
        "renderSizePx": list(spec.runtime_size),
        "views": views,
        "runtimeInputs": inputs,
        "renderCommands": _qa_render_commands(spec, runtime_records),
    }
    return json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=False) + "\n"


def render_qa_coregraphics(
    composition_path: Path,
    root: Path,
    renderer_executable: str,
) -> bytes:
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as handle:
        output_path = Path(handle.name)
    output_path.unlink(missing_ok=True)
    try:
        completed = subprocess.run(
            [
                renderer_executable,
                str(composition_path),
                str(root),
                str(output_path),
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            check=False,
        )
        if completed.returncode != 0 or not output_path.exists():
            raise RuntimeError(
                f"CoreGraphics QA compositor failed for {composition_path}: {completed.stdout.strip()}"
            )
        return output_path.read_bytes()
    finally:
        output_path.unlink(missing_ok=True)


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
    webp_path = record.get("runtimePath") or record.get("reviewWebpPath")
    webp_role = "WebP runtime" if record["runtimeIncluded"] else "WebP QA preview"
    construction = (
        "deterministic project-authored SVG primitives only"
        if record["runtimeIncluded"]
        else "deterministic compositor decoding declared runtimePath WebPs with manifest pivots and attachments"
    )
    return f"""# {record['manifestId']}

- Status: `{record['status']}`
- Revision: `{record['revision']}`
- Style contract: `art-v1`
- Generator: `{GENERATOR_VERSION}`
- Review date: `{FIXED_REVIEW_DATE}`
- Construction: {construction}
- External inputs: none
- License: {LICENSE}
- Source: `{record['sourcePath']}` — `{record['sourceSizePx'][0]} × {record['sourceSizePx'][1]}` — SHA-256 `{record['sourceSha256']}`
- PNG preview: `{record['previewPath']}` — `{record['sizePx'][0]} × {record['sizePx'][1]}` — SHA-256 `{record['pngSha256']}`
- {webp_role}: `{webp_path}` — `{record['sizePx'][0]} × {record['sizePx'][1]}` — SHA-256 `{record['sha256']}`
- Slot: `{record['slot'] or 'none'}`
- Z layer: `{record['zLayer']}`
- Runtime included: `{str(record['runtimeIncluded']).lower()}`
{f"- Normalized 48px thumbnail: `{record['thumb48Path']}` — SHA-256 `{record['thumb48Sha256']}`" if record.get('thumb48Path') else ''}
{f"- QA renderer: `{record['qaRendererPath']}` — `{record['qaRendererPlatform']}` — SHA-256 `{record['qaRendererSha256']}`" if record.get('qaRendererPath') else ''}

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
    qa_record = next(item for item in records if not item["runtimeIncluded"])
    return {
        "schemaVersion": SCHEMA_VERSION,
        "revision": ASSET_REVISION,
        "reviewBatch": "runtime-compositor-golden-corrections-v3",
        "styleContract": "art-v1",
        "generator": GENERATOR_VERSION,
        "status": STATUS,
        "deterministic": True,
        "externalArtInputs": [],
        "qaRenderer": {
            "path": qa_record["qaRendererPath"],
            "sha256": qa_record["qaRendererSha256"],
            "platform": qa_record["qaRendererPlatform"],
            "canonicalSource": "sources/art/qa/*.json renderCommands",
        },
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

The deterministic pipeline generated **{manifest['runtimeAssetCount']}** editable SVG
runtime sources plus **{manifest['assetCount'] - manifest['runtimeAssetCount']}** editable JSON compositor sources for review-only QA sheets. Each has matching PNG/WebP review exports and one provenance
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
            composition("Mascot Six / Seven composite QA", ["reports/art-previews/qa/chr_composite_qa.png"]),
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
<p>Runtime assets plus review-only QA sheets. Every entry includes color, grayscale, 48px, and 10% checks.</p>
<h2>Layer and character compositions</h2><section class=compositions>""" + compositions + """</section>
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
    renderer_path, qa_renderer = compile_coregraphics_qa_renderer(root, clang)
    renderer_hash = sha256_file(renderer_path)
    clean_packaged_art_directory(root)
    runtime_specs = [spec for spec in specs if spec.runtime_included]
    qa_only_specs = [spec for spec in specs if not spec.runtime_included]
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
    runtime_by_id = {record["manifestId"]: record for record in runtime_records}
    qa_records: list[dict[str, Any]] = []
    qa_source_dir = root / "sources" / "art" / "qa"
    if qa_source_dir.exists():
        for obsolete_svg in qa_source_dir.glob("*.svg"):
            obsolete_svg.unlink()
    for spec in qa_only_specs:
        source_json = qa_composition_source(spec, runtime_by_id)
        if source_json != qa_composition_source(spec, runtime_by_id):
            raise RuntimeError(f"Non-deterministic QA source: {spec.manifest_id}")
        composition_path = root / "sources" / "art" / "qa" / f"{spec.manifest_id}.json"
        write_if_changed(composition_path, source_json.encode("utf-8"))
        rendered_png = render_qa_coregraphics(
            composition_path,
            root,
            qa_renderer,
        )
        qa_record = render_one(
            spec,
            root,
            svg_renderer,
            cwebp,
            source_override=source_json,
            source_extension=".json",
            pre_rendered_png=rendered_png,
        )
        qa_record.update(
            {
                "qaRendererPath": relative_path(renderer_path, root),
                "qaRendererSha256": renderer_hash,
                "qaRendererPlatform": "macOS Objective-C CoreGraphics ImageIO",
            }
        )
        provenance_path = root / qa_record["licenseRecord"]
        write_if_changed(provenance_path, provenance_markdown(qa_record).encode("utf-8"))
        qa_records.append(qa_record)
    records = [*runtime_records, *qa_records]
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
