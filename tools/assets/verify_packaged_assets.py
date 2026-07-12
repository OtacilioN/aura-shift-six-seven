#!/usr/bin/env python3
"""Verify that an Android APK contains exactly the approved runtime asset sets."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_APK = ROOT / "build/app/outputs/flutter-apk/app-debug.apk"
REPORT = ROOT / "reports/package-asset-review.json"
FLUTTER_PREFIX = "assets/flutter_assets/"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", nargs="?", type=Path, default=DEFAULT_APK)
    return parser.parse_args()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def png_dimensions(data: bytes) -> tuple[int, int] | None:
    if data[:16] != b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR" or len(data) < 24:
        return None
    return struct.unpack(">II", data[16:24])


def main() -> int:
    apk = parse_args().apk.resolve()
    art = json.loads(
        (ROOT / "assets/manifests/art-approved-manifest-v1.json").read_text()
    )
    audio = json.loads((ROOT / "assets/audio/audio-manifest-v2.json").read_text())
    fonts = json.loads((ROOT / "assets/manifests/font-manifest-v1.json").read_text())
    brand = json.loads((ROOT / "assets/manifests/brand-manifest-v1.json").read_text())
    production = json.loads(
        (ROOT / "assets/manifests/production-assets-v1.json").read_text()
    )

    if art.get("schemaVersion") != "art-approved-manifest-v1" or art.get("status") != "approved":
        raise SystemExit("art release manifest is not approved")
    if audio.get("contract") != "audio-manifest-v2" or audio.get("status") != "approved":
        raise SystemExit("audio release manifest is not approved")
    if production.get("schema") != "production-assets-v1" or production.get("status") != "integrated":
        raise SystemExit("production asset set is not integrated")
    if any(entry.get("status") != "approved" for entry in art.get("assets", [])):
        raise SystemExit("art release manifest contains an unapproved asset")
    if any(entry.get("status") != "approved" for entry in audio.get("assets", [])):
        raise SystemExit("audio release manifest contains an unapproved asset")

    expected: dict[str, str] = {}
    for entry in art["assets"]:
        if entry["runtimeIncluded"]:
            expected[entry["runtimePath"]] = entry["sha256"]
    for entry in audio["assets"]:
        expected[entry["runtimePath"]] = entry["runtimeSha256"]
    for entry in fonts["fonts"]:
        expected[entry["path"]] = entry["sha256"]

    expected_direct = {
        "assets/manifests/art-manifest-v1.json",
        "assets/manifests/art-approved-manifest-v1.json",
        "assets/manifests/brand-manifest-v1.json",
        "assets/manifests/font-manifest-v1.json",
        "assets/manifests/asset-approval-v1.json",
        "assets/manifests/music-selection-approval-v1.json",
        "assets/manifests/production-assets-v1.json",
        "assets/audio/audio-candidate-manifest-v2.json",
        "assets/audio/audio-manifest-v2.json",
    }
    errors: list[str] = []
    bindings = (
        (
            production["approval"]["decision"],
            production["approval"]["decisionSha256"],
        ),
        (
            production["musicSelection"]["decision"],
            production["musicSelection"]["decisionSha256"],
        ),
        (
            production["components"]["art"]["manifest"],
            production["components"]["art"]["manifestSha256"],
        ),
        (
            production["components"]["art"]["sourceManifest"],
            production["components"]["art"]["sourceManifestSha256"],
        ),
        (
            production["components"]["audio"]["manifest"],
            production["components"]["audio"]["manifestSha256"],
        ),
        (
            production["components"]["audio"]["sourceManifest"],
            production["components"]["audio"]["sourceManifestSha256"],
        ),
        (
            production["components"]["brand"]["sourceManifest"],
            production["components"]["brand"]["sourceManifestSha256"],
        ),
        (
            production["components"]["fonts"]["sourceManifest"],
            production["components"]["fonts"]["sourceManifestSha256"],
        ),
    )
    for relative, expected_sha in bindings:
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing production binding: {relative}")
        elif digest(path.read_bytes()) != expected_sha:
            errors.append(f"production binding drift: {relative}")

    with zipfile.ZipFile(apk) as archive:
        names = set(archive.namelist())
        bundle_prefix = "base/" if "base/manifest/AndroidManifest.xml" in names else ""
        flutter_prefix = bundle_prefix + FLUTTER_PREFIX
        for relative, expected_sha in expected.items():
            member = flutter_prefix + relative
            if member not in names:
                errors.append(f"missing: {relative}")
                continue
            observed = digest(archive.read(member))
            if observed != expected_sha:
                errors.append(f"hash drift: {relative}")
        for relative in expected_direct:
            member = flutter_prefix + relative
            if member not in names:
                errors.append(f"missing manifest: {relative}")
            elif digest(archive.read(member)) != digest((ROOT / relative).read_bytes()):
                errors.append(f"packaged manifest drift: {relative}")

        packaged_manifests = {
            name.removeprefix(flutter_prefix)
            for name in names
            if name.startswith(flutter_prefix)
            and name.endswith(".json")
            and (
                name.startswith(flutter_prefix + "assets/manifests/")
                or name.startswith(flutter_prefix + "assets/audio/")
            )
        }
        if packaged_manifests != expected_direct:
            errors.append(
                "manifest set mismatch: "
                f"missing={sorted(expected_direct - packaged_manifests)} "
                f"extra={sorted(packaged_manifests - expected_direct)}"
            )

        android_brand = [
            entry
            for entry in brand["files"]
            if entry["path"].startswith("android/app/src/main/res/")
            and entry["path"].endswith(".png")
        ]
        android_brand_transformed = 0
        for entry in android_brand:
            relative = entry["path"].removeprefix("android/app/src/main/res/")
            folder, filename = relative.split("/", 1)
            member = f"{bundle_prefix}res/{folder}-v4/{filename}"
            if member not in names:
                errors.append(f"missing Android brand asset: {member}")
                continue
            packaged_bytes = archive.read(member)
            source_bytes = (ROOT / entry["path"]).read_bytes()
            if digest(packaged_bytes) != entry["sha256"]:
                if png_dimensions(packaged_bytes) != png_dimensions(source_bytes):
                    errors.append(f"Android brand dimensions drift: {member}")
                else:
                    # AAPT2 may losslessly recompress PNG resources in release bundles.
                    android_brand_transformed += 1

        packaged_art = {
            name.removeprefix(flutter_prefix)
            for name in names
            if name.startswith(flutter_prefix + "assets/art/")
        }
        expected_art = {
            entry["runtimePath"]
            for entry in art["assets"]
            if entry["runtimeIncluded"]
        }
        if packaged_art != expected_art:
            errors.append(
                f"art set mismatch: missing={len(expected_art - packaged_art)} "
                f"extra={len(packaged_art - expected_art)}"
            )

        packaged_audio_runtime = {
            name.removeprefix(flutter_prefix)
            for name in names
            if name.startswith(flutter_prefix + "assets/audio/")
            and not name.endswith(".json")
        }
        expected_audio_runtime = {entry["runtimePath"] for entry in audio["assets"]}
        if packaged_audio_runtime != expected_audio_runtime:
            errors.append(
                f"audio set mismatch: missing={len(expected_audio_runtime - packaged_audio_runtime)} "
                f"extra={len(packaged_audio_runtime - expected_audio_runtime)}"
            )

        forbidden = sorted(
            name
            for name in names
            if name.startswith(flutter_prefix)
            and any(token in name.lower() for token in ("art-previews", "/qa/", "/reports/"))
        )
        if forbidden:
            errors.append(f"review-only files packaged: {forbidden[:8]}")

        packaged_store_art = sorted(
            name
            for name in names
            if name.startswith(flutter_prefix + "assets/brand/")
        )
        if packaged_store_art:
            errors.append(f"store-only brand art packaged: {packaged_store_art[:8]}")

    result = {
        "contract": "package-asset-review-v2",
        "status": "passed" if not errors else "failed",
        "approvalStatus": {
            "art": art["status"],
            "audio": audio["status"],
        },
        "productionStatus": production["status"],
        "apk": apk.relative_to(ROOT).as_posix(),
        "apkBytes": apk.stat().st_size,
        "apkSha256": digest(apk.read_bytes()),
        "artRuntime": len(
            [entry for entry in art["assets"] if entry["runtimeIncluded"]]
        ),
        "audioRuntime": len(audio["assets"]),
        "audioFormats": {
            "ogg": sum(entry["runtimePath"].endswith(".ogg") for entry in audio["assets"]),
            "wav": sum(entry["runtimePath"].endswith(".wav") for entry in audio["assets"]),
        },
        "fontFiles": len(fonts["fonts"]),
        "androidBrandFiles": len(android_brand),
        "androidBrandTransformed": android_brand_transformed,
        "reviewOnlyPackaged": len(forbidden),
        "storeOnlyBrandPackaged": len(packaged_store_art),
        "errors": errors,
    }
    REPORT.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
