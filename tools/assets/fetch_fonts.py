#!/usr/bin/env python3
"""Fetch the exact, redistributable font binaries required by ui-system-v1.

The repository SHAs are intentionally pinned. Updating either SHA is a deliberate
asset revision and must be followed by localization/reflow QA.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = ROOT / "assets" / "fonts"
LICENSE_DIR = FONT_DIR / "licenses"
PROVENANCE_DIR = ROOT / "provenance" / "fonts"
MANIFEST_PATH = ROOT / "assets" / "manifests" / "font-manifest-v1.json"

GOOGLE_FONTS_COMMIT = "ec0464b978de222073645d6d3366f3fdf03376d8"
MPLUS_COMMIT = "0d4459efc913a91f33c3f08b219a5a95d282c7b8"

FILES = [
    {
        "family": "Noto Sans",
        "asset": "NotoSans-Variable.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/notosans/NotoSans%5Bwdth%2Cwght%5D.ttf",
        "weights": [400, 450, 500, 700, 800],
        "scripts": ["Latin"],
        "license": "licenses/google-fonts-OFL.txt",
    },
    {
        "family": "Noto Sans JP",
        "asset": "NotoSansJP-Variable.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf",
        "weights": [400, 500, 700, 800],
        "scripts": ["Japanese", "Latin"],
        "license": "licenses/google-fonts-OFL.txt",
    },
    {
        "family": "Noto Sans Arabic",
        "asset": "NotoSansArabic-Variable.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf",
        "weights": [400, 500, 700, 800],
        "scripts": ["Arabic", "Latin"],
        "license": "licenses/google-fonts-OFL.txt",
    },
    {
        "family": "Noto Kufi Arabic",
        "asset": "NotoKufiArabic-Variable.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/notokufiarabic/NotoKufiArabic%5Bwght%5D.ttf",
        "weights": [400, 500, 700, 800],
        "scripts": ["Arabic", "Latin"],
        "license": "licenses/google-fonts-OFL.txt",
    },
    {
        "family": "M PLUS Rounded 1c",
        "asset": "MPlusRounded1c-Bold.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/mplusrounded1c/MPLUSRounded1c-Bold.ttf",
        "weights": [700],
        "scripts": ["Japanese", "Latin"],
        "license": "licenses/mplus-OFL.txt",
    },
    {
        "family": "M PLUS Rounded 1c",
        "asset": "MPlusRounded1c-ExtraBold.ttf",
        "source": f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/mplusrounded1c/MPLUSRounded1c-ExtraBold.ttf",
        "weights": [800],
        "scripts": ["Japanese", "Latin"],
        "license": "licenses/mplus-OFL.txt",
    },
]

SUPPORT_FILES = [
    (
        f"https://raw.githubusercontent.com/google/fonts/{GOOGLE_FONTS_COMMIT}/ofl/notosans/OFL.txt",
        LICENSE_DIR / "google-fonts-OFL.txt",
    ),
    (
        f"https://raw.githubusercontent.com/rayshan/mplus-fonts/{MPLUS_COMMIT}/OFL.txt",
        LICENSE_DIR / "mplus-OFL.txt",
    ),
]


def fetch(url: str, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(target.suffix + ".download")
    subprocess.run(
        ["curl", "--globoff", "--location", "--fail", "--silent", "--show-error", url, "--output", str(temporary)],
        check=True,
    )
    temporary.replace(target)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    FONT_DIR.mkdir(parents=True, exist_ok=True)
    PROVENANCE_DIR.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)

    for url, target in SUPPORT_FILES:
        fetch(url, target)

    manifest = {
        "schema": "font-manifest-v1",
        "revision": 1,
        "status": "candidate-reviewed",
        "sourceRepositories": {
            "google/fonts": GOOGLE_FONTS_COMMIT,
            "rayshan/mplus-fonts": MPLUS_COMMIT,
        },
        "fonts": [],
    }
    for item in FILES:
        target = FONT_DIR / item["asset"]
        fetch(item["source"], target)
        manifest["fonts"].append(
            {
                "family": item["family"],
                "path": target.relative_to(ROOT).as_posix(),
                "weights": item["weights"],
                "scripts": item["scripts"],
                "license": f"assets/fonts/{item['license']}",
                "sourceUrl": item["source"],
                "bytes": target.stat().st_size,
                "sha256": sha256(target),
            }
        )

    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (PROVENANCE_DIR / "README.md").write_text(
        "# Font provenance\n\n"
        "Binaries are unmodified snapshots from the pinned Google Fonts commit "
        f"`{GOOGLE_FONTS_COMMIT}`. M PLUS licensing text is pinned at "
        f"`{MPLUS_COMMIT}`. See `assets/manifests/font-manifest-v1.json` for "
        "per-file URLs and SHA-256 hashes. Status remains `candidate-reviewed` "
        "until localized reflow and physical-device rendering are accepted.\n",
        encoding="utf-8",
    )
    print(f"Fetched {len(FILES)} font files -> {MANIFEST_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
