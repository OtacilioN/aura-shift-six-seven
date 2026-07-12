#!/usr/bin/env python3
"""Automated QA for brand derivatives and bundled fonts."""

from __future__ import annotations

import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []
    brand_path = ROOT / "assets" / "manifests" / "brand-manifest-v1.json"
    font_path = ROOT / "assets" / "manifests" / "font-manifest-v1.json"
    brand = json.loads(brand_path.read_text(encoding="utf-8"))
    fonts = json.loads(font_path.read_text(encoding="utf-8"))

    check(brand.get("status") == "candidate-reviewed", "brand status must remain candidate-reviewed", failures)
    check(fonts.get("status") == "candidate-reviewed", "font status must remain candidate-reviewed", failures)
    check(brand.get("revision") == 2, "brand revision must be 2", failures)
    check(fonts.get("revision") == 1, "font revision must be 1", failures)

    for entry in brand["files"]:
        path = ROOT / entry["path"]
        check(path.is_file(), f"missing brand file: {entry['path']}", failures)
        if path.is_file():
            check(path.stat().st_size == entry["bytes"], f"byte count drift: {entry['path']}", failures)
            check(sha256(path) == entry["sha256"], f"hash drift: {entry['path']}", failures)

    image_expectations = {
        "assets/brand/app_icon_store_512.png": ((512, 512), False),
        "assets/brand/app_icon_master_1024.png": ((1024, 1024), False),
        "assets/brand/aura_shift_feature_graphic_v1.webp": ((1024, 500), False),
        "android/app/src/main/res/drawable-nodpi/ic_launcher_foreground.png": ((432, 432), True),
        "android/app/src/main/res/drawable-nodpi/ic_launcher_monochrome.png": ((432, 432), True),
        "android/app/src/main/res/drawable-nodpi/launch_brand.png": ((320, 320), True),
        "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png": ((1024, 1024), False),
    }
    for relative, (expected_size, expect_alpha) in image_expectations.items():
        path = ROOT / relative
        check(path.is_file(), f"missing image: {relative}", failures)
        if not path.is_file():
            continue
        with Image.open(path) as image:
            check(image.size == expected_size, f"wrong dimensions: {relative} {image.size}", failures)
            has_alpha = "A" in image.getbands()
            check(has_alpha == expect_alpha, f"wrong alpha policy: {relative} mode={image.mode}", failures)
            if expect_alpha:
                alpha = image.getchannel("A")
                corners = [alpha.getpixel((0, 0)), alpha.getpixel((image.width - 1, 0)), alpha.getpixel((0, image.height - 1)), alpha.getpixel((image.width - 1, image.height - 1))]
                check(max(corners) == 0, f"transparent derivative corners are not clear: {relative}", failures)

    xml_paths = [
        "android/app/src/main/res/values/brand_colors.xml",
        "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
        "android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml",
        "android/app/src/main/res/drawable/launch_background.xml",
        "android/app/src/main/res/drawable-v21/launch_background.xml",
        "ios/Runner/Base.lproj/LaunchScreen.storyboard",
    ]
    for relative in xml_paths:
        try:
            ET.parse(ROOT / relative)
        except (ET.ParseError, OSError) as error:
            failures.append(f"invalid XML {relative}: {error}")

    seen_families: set[str] = set()
    for entry in fonts["fonts"]:
        path = ROOT / entry["path"]
        check(path.is_file(), f"missing font: {entry['path']}", failures)
        if not path.is_file():
            continue
        check(path.stat().st_size == entry["bytes"], f"font byte count drift: {entry['path']}", failures)
        check(sha256(path) == entry["sha256"], f"font hash drift: {entry['path']}", failures)
        check(path.read_bytes()[:4] in (b"\x00\x01\x00\x00", b"OTTO", b"true"), f"invalid sfnt header: {entry['path']}", failures)
        license_path = ROOT / "assets" / "fonts" / Path(entry["license"]).name
        if not license_path.exists():
            license_path = ROOT / entry["license"]
        check(license_path.is_file(), f"missing font license: {entry['license']}", failures)
        seen_families.add(entry["family"])
    required = {"Noto Sans", "Noto Sans JP", "Noto Sans Arabic", "Noto Kufi Arabic", "M PLUS Rounded 1c"}
    check(required <= seen_families, f"font families missing: {sorted(required - seen_families)}", failures)

    warnings += [
        "Adaptive icon masks still require inspection on physical launchers.",
        "Arabic/Japanese shaping, locale reflow and 200% text scaling require Flutter device QA.",
        "Feature graphic publication review and originality acceptance remain human gates.",
    ]
    result = {
        "contract": "brand-font-review-v1",
        "status": "passed-automated" if not failures else "failed",
        "failures": failures,
        "warnings": warnings,
        "brandFileCount": len(brand["files"]),
        "fontFileCount": len(fonts["fonts"]),
    }
    report_dir = ROOT / "reports"
    report_dir.mkdir(parents=True, exist_ok=True)
    (report_dir / "brand-font-review-results.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    (report_dir / "brand-font-review.md").write_text(
        "# Brand and font automated review\n\n"
        f"- Status: `{result['status']}`\n"
        f"- Brand files checked: `{result['brandFileCount']}`\n"
        f"- Font files checked: `{result['fontFileCount']}`\n"
        f"- Failures: `{len(failures)}`\n\n"
        "## Pending human/device gates\n\n"
        + "".join(f"- {item}\n" for item in warnings),
        encoding="utf-8",
    )
    print(json.dumps(result, ensure_ascii=False))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
