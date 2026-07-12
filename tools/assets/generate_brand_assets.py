#!/usr/bin/env python3
"""Generate the launcher, splash and store-brand derivatives from one mark.

The mark is intentionally geometric and deterministic. It does not depend on the
AI-generated feature graphic; that image is kept as separately documented key art.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
INK = "#090B1A"
INK_700 = "#141936"
PAPER = "#F7F5FF"
VIOLET = "#8B7CFF"
CYAN = "#43E6FF"
MAGENTA = "#FF4FA3"
GOLD = "#FFD166"


def _mask_outline(mask: Image.Image, width: int) -> Image.Image:
    kernel = max(3, width | 1)
    expanded = mask.filter(ImageFilter.MaxFilter(kernel))
    outline = Image.new("L", mask.size)
    outline.point(lambda _: 0)
    return Image.eval(expanded, lambda value: value)


def _paint_mask(canvas: Image.Image, mask: Image.Image, fill: str, outline: int) -> None:
    expanded = _mask_outline(mask, outline)
    canvas.paste(INK, (0, 0), expanded)
    canvas.paste(fill, (0, 0), mask)


def _hand_mask(side: str) -> Image.Image:
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    if side == "left":
        draw.ellipse((82, 315, 370, 665), fill=255)
        draw.ellipse((95, 215, 230, 430), fill=255)
        draw.ellipse((190, 160, 330, 425), fill=255)
        draw.ellipse((295, 235, 425, 455), fill=255)
        draw.ellipse((302, 480, 440, 620), fill=255)
        draw.line((350, 565, 455, 665), fill=255, width=70)
    else:
        draw.ellipse((654, 315, 942, 665), fill=255)
        draw.ellipse((794, 215, 929, 430), fill=255)
        draw.ellipse((694, 160, 834, 425), fill=255)
        draw.ellipse((599, 235, 729, 455), fill=255)
        draw.ellipse((584, 480, 722, 620), fill=255)
        draw.line((674, 565, 569, 665), fill=255, width=70)
    return mask


def _body_mask() -> Image.Image:
    mask = Image.new("L", (1024, 1024), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((300, 295, 724, 700), radius=180, fill=255)
    draw.polygon(((324, 540), (700, 540), (640, 820), (384, 820)), fill=255)
    draw.ellipse((348, 756, 500, 880), fill=255)
    draw.ellipse((524, 756, 676, 880), fill=255)
    return mask


def make_mark(*, transparent: bool = False, monochrome: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0) if transparent else INK)
    draw = ImageDraw.Draw(canvas)

    if not transparent:
        for inset, color in [(46, "#10152E"), (92, "#171D43"), (150, "#111632")]:
            draw.rounded_rectangle((inset, inset, 1024 - inset, 1024 - inset), radius=220, fill=color)
        draw.arc((110, 125, 914, 929), 195, 345, fill=VIOLET, width=28)
        draw.arc((155, 170, 869, 884), 15, 165, fill=GOLD, width=13)

    body_fill = PAPER if monochrome else INK_700
    hand_left = PAPER if monochrome else CYAN
    hand_right = PAPER if monochrome else MAGENTA

    body = _body_mask()
    _paint_mask(canvas, body, body_fill, 29)

    left = _hand_mask("left")
    right = _hand_mask("right")
    _paint_mask(canvas, left, hand_left, 29)
    _paint_mask(canvas, right, hand_right, 29)

    if not monochrome:
        draw.ellipse((392, 328, 632, 568), fill=PAPER, outline=INK, width=20)
        draw.ellipse((439, 410, 470, 465), fill=INK)
        draw.ellipse((554, 410, 585, 465), fill=INK)
        draw.rounded_rectangle((476, 487, 548, 510), radius=12, fill=INK)
        draw.arc((410, 585, 614, 785), 200, 340, fill=VIOLET, width=22)
        draw.ellipse((486, 670, 538, 722), fill=GOLD, outline=INK, width=9)
    else:
        # Android themed icons tint the alpha mask. Preserve the face by using
        # transparent negative-space eyes and mouth inside one monochrome mark.
        draw.ellipse((392, 328, 632, 568), fill=PAPER)
        draw.ellipse((439, 410, 470, 465), fill=(0, 0, 0, 0))
        draw.ellipse((554, 410, 585, 465), fill=(0, 0, 0, 0))
        draw.rounded_rectangle(
            (476, 487, 548, 510), radius=12, fill=(0, 0, 0, 0)
        )

    return canvas


def save_resized(image: Image.Image, path: Path, size: tuple[int, int], *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize(size, Image.Resampling.LANCZOS)
    if opaque:
        flattened = Image.new("RGB", size, INK)
        flattened.paste(resized, mask=resized.getchannel("A"))
        resized = flattened
    resized.save(path, optimize=True)


def save_padded(image: Image.Image, path: Path, size: int, content_ratio: float) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = max(1, round(size * content_ratio))
    resized = image.resize((content, content), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - content) // 2
    canvas.alpha_composite(resized, (offset, offset))
    canvas.save(path, optimize=True)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_svg() -> Path:
    target = ROOT / "sources" / "art" / "brand" / "app_icon_master.svg"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" rx="224" fill="{INK}"/>
  <rect x="46" y="46" width="932" height="932" rx="220" fill="#10152E"/>
  <path d="M322 302 Q512 250 702 302 L640 820 Q512 880 384 820 Z" fill="{INK_700}" stroke="{INK}" stroke-width="28" stroke-linejoin="round"/>
  <path d="M445 650 C370 610 280 560 190 420 M170 420 C100 330 150 235 220 320 M220 320 C195 205 305 150 292 330 M292 330 C330 220 430 265 360 410" fill="none" stroke="{CYAN}" stroke-width="116" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M579 650 C654 610 744 560 834 420 M854 420 C924 330 874 235 804 320 M804 320 C829 205 719 150 732 330 M732 330 C694 220 594 265 664 410" fill="none" stroke="{MAGENTA}" stroke-width="116" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="512" cy="448" r="120" fill="{PAPER}" stroke="{INK}" stroke-width="20"/>
  <ellipse cx="455" cy="438" rx="16" ry="28" fill="{INK}"/><ellipse cx="569" cy="438" rx="16" ry="28" fill="{INK}"/>
  <rect x="476" y="487" width="72" height="23" rx="12" fill="{INK}"/>
  <path d="M410 665 Q512 760 614 665" fill="none" stroke="{VIOLET}" stroke-width="22" stroke-linecap="round"/>
  <circle cx="512" cy="696" r="26" fill="{GOLD}" stroke="{INK}" stroke-width="9"/>
</svg>\n''',
        encoding="utf-8",
    )
    return target


def main() -> None:
    mark = make_mark()
    foreground = make_mark(transparent=True)
    monochrome = make_mark(transparent=True, monochrome=True)
    generated: list[Path] = []

    source = write_svg()
    generated.append(source)

    brand_dir = ROOT / "assets" / "brand"
    save_resized(mark, brand_dir / "app_icon_store_512.png", (512, 512), opaque=True)
    save_resized(mark, brand_dir / "app_icon_master_1024.png", (1024, 1024), opaque=True)
    generated += [brand_dir / "app_icon_store_512.png", brand_dir / "app_icon_master_1024.png"]

    android_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, size in android_sizes.items():
        path = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png"
        save_resized(mark, path, (size, size), opaque=True)
        generated.append(path)

    drawable = ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-nodpi"
    save_padded(foreground, drawable / "ic_launcher_foreground.png", 432, 0.70)
    save_padded(monochrome, drawable / "ic_launcher_monochrome.png", 432, 0.70)
    save_padded(foreground, drawable / "launch_brand.png", 320, 0.82)
    generated += [drawable / "ic_launcher_foreground.png", drawable / "ic_launcher_monochrome.png", drawable / "launch_brand.png"]

    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios_sizes.items():
        path = ios_dir / filename
        save_resized(mark, path, (size, size), opaque=True)
        generated.append(path)

    launch_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename, size in [("LaunchImage.png", 168), ("LaunchImage@2x.png", 336), ("LaunchImage@3x.png", 504)]:
        path = launch_dir / filename
        save_resized(foreground, path, (size, size))
        generated.append(path)

    generated += [
        ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml",
        ROOT / "android" / "app" / "src" / "main" / "res" / "values" / "brand_colors.xml",
        ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-anydpi-v26" / "ic_launcher.xml",
        ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-anydpi-v33" / "ic_launcher.xml",
        ROOT / "android" / "app" / "src" / "main" / "res" / "drawable" / "launch_background.xml",
        ROOT / "android" / "app" / "src" / "main" / "res" / "drawable-v21" / "launch_background.xml",
        ROOT / "ios" / "Runner" / "Base.lproj" / "LaunchScreen.storyboard",
    ]

    generator_source = ROOT / "tools" / "assets" / "generate_brand_assets.py"
    generated.append(generator_source)
    manifest = {
        "schema": "brand-manifest-v1",
        "status": "candidate-reviewed",
        "revision": 2,
        "source": generator_source.relative_to(ROOT).as_posix(),
        "sourceType": "deterministic-python-geometry",
        "editableVectorReference": source.relative_to(ROOT).as_posix(),
        "licenseRecord": "provenance/art/brand-v2.md",
        "featureGraphic": "assets/brand/aura_shift_feature_graphic_v1.webp",
        "featureGraphicConcept": "sources/art/concepts/aura_shift_key_art_imagegen_v1.png",
        "files": [
            {
                "path": path.relative_to(ROOT).as_posix(),
                "bytes": path.stat().st_size,
                "sha256": sha256(path),
            }
            for path in generated
        ],
    }
    feature = ROOT / manifest["featureGraphic"]
    concept = ROOT / manifest["featureGraphicConcept"]
    for extra in (feature, concept):
        if extra.exists():
            manifest["files"].append(
                {"path": extra.relative_to(ROOT).as_posix(), "bytes": extra.stat().st_size, "sha256": sha256(extra)}
            )
    manifest_path = ROOT / "assets" / "manifests" / "brand-manifest-v1.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    provenance = ROOT / "provenance" / "art" / "brand-v2.md"
    provenance.parent.mkdir(parents=True, exist_ok=True)
    provenance.write_text(
        "# Brand asset provenance v2\n\n"
        "- Revision: `2`\n"
        "- Status: `candidate-reviewed`\n"
        "- Canonical launcher source: deterministic project-local geometry from `tools/assets/generate_brand_assets.py`.\n"
        "- Editable vector reference: `sources/art/brand/app_icon_master.svg`; the manifest truthfully identifies the Python geometry as the raster source.\n"
        "- Feature graphic concept: OpenAI built-in image generation; prompt recorded in the production report.\n"
        "- External visual samples: none.\n"
        "- Text embedded in art: none.\n"
        "- Human store review and physical-device mask/splash checks: pending.\n"
        "- Hashes: `assets/manifests/brand-manifest-v1.json`.\n",
        encoding="utf-8",
    )
    print(f"Generated {len(manifest['files'])} brand assets")


if __name__ == "__main__":
    main()
