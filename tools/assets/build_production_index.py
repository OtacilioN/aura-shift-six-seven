#!/usr/bin/env python3
"""Build one deterministic, verified index for the complete asset candidate."""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets/manifests/production-candidate-v1.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load(relative: str) -> tuple[Path, dict]:
    path = ROOT / relative
    return path, json.loads(path.read_text(encoding="utf-8"))


def verify(relative: str, expected: str) -> None:
    path = ROOT / relative
    if not path.is_file():
        raise SystemExit(f"missing indexed file: {relative}")
    observed = sha256(path)
    if observed != expected:
        raise SystemExit(f"hash drift: {relative}: {observed} != {expected}")


def main() -> None:
    art_path, art = load("assets/manifests/art-manifest-v1.json")
    audio_path, audio = load("assets/audio/audio-candidate-manifest-v1.json")
    brand_path, brand = load("assets/manifests/brand-manifest-v1.json")
    font_path, fonts = load("assets/manifests/font-manifest-v1.json")

    expected_revisions = ((art, 3), (audio, 3), (brand, 2), (fonts, 1))
    for manifest, revision in expected_revisions:
        if manifest.get("status") != "candidate-reviewed":
            raise SystemExit("every component must remain candidate-reviewed")
        if manifest.get("revision") != revision:
            raise SystemExit(f"unexpected component revision: {manifest.get('revision')}")

    runtime_art = [entry for entry in art["assets"] if entry["runtimeIncluded"]]
    review_art = [entry for entry in art["assets"] if not entry["runtimeIncluded"]]
    for entry in runtime_art:
        verify(entry["runtimePath"], entry["sha256"])
    for entry in review_art:
        if entry["runtimePath"] is not None:
            raise SystemExit(f"review-only art has runtime path: {entry['manifestId']}")

    runtime_formats: Counter[str] = Counter()
    for entry in audio["assets"]:
        verify(entry["masterPath"], entry["masterSha256"])
        verify(entry["runtimePath"], entry["runtimeSha256"])
        runtime_formats[Path(entry["runtimePath"]).suffix.lstrip(".").lower()] += 1

    for entry in brand["files"]:
        verify(entry["path"], entry["sha256"])
    for entry in fonts["fonts"]:
        verify(entry["path"], entry["sha256"])
        if not (ROOT / entry["license"]).is_file():
            raise SystemExit(f"missing font license: {entry['license']}")

    key_art = "sources/art/concepts/aura_shift_key_art_imagegen_v1.png"
    feature_graphic = brand["featureGraphic"]
    for relative in (key_art, feature_graphic):
        if not (ROOT / relative).is_file():
            raise SystemExit(f"missing brand artwork: {relative}")

    result = {
        "schema": "production-candidate-v1",
        "revision": 1,
        "status": "candidate-reviewed",
        "components": {
            "art": {
                "manifest": art_path.relative_to(ROOT).as_posix(),
                "manifestSha256": sha256(art_path),
                "revision": art["revision"],
                "entries": len(art["assets"]),
                "runtimeEntries": len(runtime_art),
                "reviewOnlyEntries": len(review_art),
                "runtimeBytes": sum(entry["runtimeBytes"] for entry in runtime_art),
            },
            "audio": {
                "manifest": audio_path.relative_to(ROOT).as_posix(),
                "manifestSha256": sha256(audio_path),
                "revision": audio["revision"],
                "reviewEvidenceRevision": audio["reviewEvidenceRevision"],
                "reviewEvidenceSha256": audio["reviewBundle"]["sha256"],
                "masters": len(audio["assets"]),
                "requiredMasters": sum(bool(entry["required"]) for entry in audio["assets"]),
                "conditionalMasters": sum(bool(entry["conditional"]) for entry in audio["assets"]),
                "runtimeFormats": dict(sorted(runtime_formats.items())),
                "coreAudio": {
                    "musicFrameCountExact": audio["crossDecoderReview"][
                        "musicOggFrameCountExact"
                    ],
                    "musicSeamGate": audio["crossDecoderReview"][
                        "musicOggCoreAudioSeamGate"
                    ],
                    "musicZeroOffsetAligned": audio["crossDecoderReview"][
                        "musicOggZeroOffsetAligned"
                    ],
                    "sfxSampleExact": audio["crossDecoderReview"][
                        "sfxWavPcm16FrameAndValueExact"
                    ],
                },
                "runtimeBytes": sum(
                    (ROOT / entry["runtimePath"]).stat().st_size
                    for entry in audio["assets"]
                ),
                "masterBytes": sum(
                    (ROOT / entry["masterPath"]).stat().st_size
                    for entry in audio["assets"]
                ),
            },
            "brand": {
                "manifest": brand_path.relative_to(ROOT).as_posix(),
                "manifestSha256": sha256(brand_path),
                "revision": brand["revision"],
                "files": len(brand["files"]),
                "bytes": sum(entry["bytes"] for entry in brand["files"]),
                "keyArt": key_art,
                "keyArtSha256": sha256(ROOT / key_art),
                "featureGraphic": feature_graphic,
                "featureGraphicSha256": sha256(ROOT / feature_graphic),
            },
            "fonts": {
                "manifest": font_path.relative_to(ROOT).as_posix(),
                "manifestSha256": sha256(font_path),
                "revision": fonts["revision"],
                "files": len(fonts["fonts"]),
                "bytes": sum(entry["bytes"] for entry in fonts["fonts"]),
            },
        },
        "integration": {
            "visualSceneRuntime": "integrated-candidate",
            "visualUiCollectionTree": "generated-bundled-not-integrated",
            "audioRuntime": "bundled-candidate",
            "audioEventPlayback": "not-integrated",
        },
        "manualGates": [
            "visual-cultural-originality-acceptance",
            "human-listening-fatigue-and-similarity-review",
            "android-loop-latency-focus-and-resume-test",
            "adaptive-icon-splash-and-safe-area-device-test",
            "arabic-japanese-reflow-and-200-percent-text-scale-test",
        ],
    }

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(
        f"Indexed {len(runtime_art)} art runtimes, {len(audio['assets'])} audio "
        f"runtimes, {len(brand['files'])} brand files and {len(fonts['fonts'])} fonts"
    )


if __name__ == "__main__":
    main()
