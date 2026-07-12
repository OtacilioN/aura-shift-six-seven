#!/usr/bin/env python3
"""Promote immutable reviewed candidates after explicit human decisions.

The technical manifests remain untouched so generation and review stay
reproducible. This script creates the reserved approved audio manifest and one
production integration index that binds approval, candidate hashes and runtime
coverage together.
"""

from __future__ import annotations

import hashlib
import json
from collections import Counter
from copy import deepcopy
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
APPROVAL_PATH = ROOT / "assets/manifests/asset-approval-v1.json"
ART_APPROVED_PATH = ROOT / "assets/manifests/art-approved-manifest-v1.json"
MUSIC_APPROVAL_PATH = ROOT / "assets/manifests/music-selection-approval-v1.json"
AUDIO_CANDIDATE_PATH = ROOT / "assets/audio/audio-candidate-manifest-v2.json"
AUDIO_APPROVED_PATH = ROOT / "assets/audio/audio-manifest-v2.json"
PRODUCTION_PATH = ROOT / "assets/manifests/production-assets-v1.json"


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise SystemExit(f"expected JSON object: {path.relative_to(ROOT)}")
    return value


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main() -> None:
    approval = read_json(APPROVAL_PATH)
    music_approval = read_json(MUSIC_APPROVAL_PATH)
    art_path = ROOT / "assets/manifests/art-manifest-v1.json"
    brand_path = ROOT / "assets/manifests/brand-manifest-v1.json"
    fonts_path = ROOT / "assets/manifests/font-manifest-v1.json"
    art = read_json(art_path)
    audio_candidate = read_json(AUDIO_CANDIDATE_PATH)
    brand = read_json(brand_path)
    fonts = read_json(fonts_path)

    require(approval.get("status") == "approved", "approval decision is not approved")
    require(
        approval.get("decisionSource") == "human-user",
        "asset promotion requires an explicit human-user decision",
    )
    required_scope = {"art", "audio", "brand", "fonts", "key-art"}
    require(
        required_scope.issubset(set(approval.get("scope", []))),
        "approval decision does not cover the complete asset scope",
    )
    require(
        music_approval.get("status") == "approved"
        and music_approval.get("decisionSource") == "human-user",
        "selected soundtrack requires an explicit human-user decision",
    )
    require(
        music_approval.get("primaryTrack") == "MUS-BOSS-SHIFT"
        and len(music_approval.get("playlist", [])) == 7,
        "selected soundtrack approval is incomplete",
    )
    for name, manifest, revision in (
        ("art", art, 3),
        ("audio", audio_candidate, 1),
        ("brand", brand, 2),
        ("fonts", fonts, 1),
    ):
        require(
            manifest.get("status") == "candidate-reviewed",
            f"{name} source manifest is not candidate-reviewed",
        )
        require(
            manifest.get("revision") == revision,
            f"unexpected {name} source revision: {manifest.get('revision')}",
        )

    art_approved = deepcopy(art)
    art_approved["schemaVersion"] = "art-approved-manifest-v1"
    art_approved["status"] = "approved"
    art_approved["promotion"] = {
        "approvalDecision": APPROVAL_PATH.relative_to(ROOT).as_posix(),
        "approvalDecisionSha256": sha256(APPROVAL_PATH),
        "candidateManifest": art_path.relative_to(ROOT).as_posix(),
        "candidateManifestSha256": sha256(art_path),
        "decisionDate": approval["decisionDate"],
        "integrationStatus": "integrated-in-build",
    }
    for entry in art_approved.get("assets", []):
        require(isinstance(entry, dict), "invalid art asset entry")
        require(
            entry.get("status") == "candidate-reviewed",
            f"art asset is not reviewed: {entry.get('manifestId')}",
        )
        entry["status"] = "approved"
    write_json(ART_APPROVED_PATH, art_approved)

    audio_approved = deepcopy(audio_candidate)
    audio_approved["contract"] = "audio-manifest-v2"
    audio_approved["status"] = "approved"
    audio_approved["humanReview"] = "approved-by-user"
    audio_approved["similarityReview"] = "independent-review-pending"
    audio_approved["rightsReview"] = "commercial-terms-pending"
    audio_approved["promotion"] = {
        "approvalDecision": MUSIC_APPROVAL_PATH.relative_to(ROOT).as_posix(),
        "approvalDecisionSha256": sha256(MUSIC_APPROVAL_PATH),
        "candidateManifest": AUDIO_CANDIDATE_PATH.relative_to(ROOT).as_posix(),
        "candidateManifestSha256": sha256(AUDIO_CANDIDATE_PATH),
        "decisionDate": music_approval["decisionDate"],
        "integrationStatus": "integrated-in-build",
    }
    for entry in audio_approved.get("assets", []):
        require(isinstance(entry, dict), "invalid audio asset entry")
        require(
            entry.get("status") == "candidate-reviewed",
            f"audio asset is not reviewed: {entry.get('id')}",
        )
        entry["status"] = "approved"
    write_json(AUDIO_APPROVED_PATH, audio_approved)

    art_runtime = [entry for entry in art["assets"] if entry["runtimeIncluded"]]
    art_review = [entry for entry in art["assets"] if not entry["runtimeIncluded"]]
    runtime_formats = Counter(
        Path(entry["runtimePath"]).suffix.lstrip(".").lower()
        for entry in audio_approved["assets"]
    )
    audio_groups = Counter(entry["group"] for entry in audio_approved["assets"])
    music_entries = [
        entry for entry in audio_approved["assets"] if entry["group"] == "music"
    ]
    components = {
        "art": {
            "approvalStatus": "approved",
            "integrationStatus": "integrated",
            "manifest": ART_APPROVED_PATH.relative_to(ROOT).as_posix(),
            "manifestSha256": sha256(ART_APPROVED_PATH),
            "sourceManifest": art_path.relative_to(ROOT).as_posix(),
            "sourceManifestSha256": sha256(art_path),
            "revision": art["revision"],
            "runtimeEntries": len(art_runtime),
            "reviewOnlyEntries": len(art_review),
            "runtimeConsumers": {
                "scene": 136,
                "ui": 83,
                "total": 219,
            },
        },
        "audio": {
            "approvalStatus": "approved",
            "integrationStatus": "integrated",
            "manifest": AUDIO_APPROVED_PATH.relative_to(ROOT).as_posix(),
            "manifestSha256": sha256(AUDIO_APPROVED_PATH),
            "sourceManifest": AUDIO_CANDIDATE_PATH.relative_to(ROOT).as_posix(),
            "sourceManifestSha256": sha256(AUDIO_CANDIDATE_PATH),
            "revision": audio_approved["revision"],
            "runtimeEntries": len(audio_approved["assets"]),
            "runtimeFormats": dict(sorted(runtime_formats.items())),
            "runtimeConsumers": {
                "musicMain": sum(
                    bool(entry.get("primary")) for entry in music_entries
                ),
                "musicPlaylist": sum(
                    not bool(entry.get("primary")) for entry in music_entries
                ),
                "cycle": audio_groups["cycle"],
                "ui": audio_groups["ui"],
                "event": audio_groups["event"],
                "total": len(audio_approved["assets"]),
            },
        },
        "brand": {
            "approvalStatus": "approved",
            "integrationStatus": "integrated-native-platforms",
            "sourceManifest": brand_path.relative_to(ROOT).as_posix(),
            "sourceManifestSha256": sha256(brand_path),
            "revision": brand["revision"],
            "files": len(brand["files"]),
        },
        "fonts": {
            "approvalStatus": "approved",
            "integrationStatus": "integrated-flutter",
            "sourceManifest": fonts_path.relative_to(ROOT).as_posix(),
            "sourceManifestSha256": sha256(fonts_path),
            "revision": fonts["revision"],
            "files": len(fonts["fonts"]),
        },
    }
    production = {
        "schema": "production-assets-v1",
        "revision": 2,
        "status": "integrated",
        "approval": {
            "decision": APPROVAL_PATH.relative_to(ROOT).as_posix(),
            "decisionSha256": sha256(APPROVAL_PATH),
            "decisionDate": approval["decisionDate"],
            "decisionSource": approval["decisionSource"],
            "statement": approval["statement"],
        },
        "musicSelection": {
            "decision": MUSIC_APPROVAL_PATH.relative_to(ROOT).as_posix(),
            "decisionSha256": sha256(MUSIC_APPROVAL_PATH),
            "decisionDate": music_approval["decisionDate"],
            "decisionSource": music_approval["decisionSource"],
            "primaryTrack": music_approval["primaryTrack"],
        },
        "components": components,
        "runtimeIntegration": {
            "visualSceneRuntime": "integrated",
            "visualUiCollectionTree": "integrated",
            "audioRuntime": "integrated",
            "audioEventPlayback": "integrated",
        },
        "remainingDeviceValidation": sorted(
            (
                set(approval["remainingDeviceValidation"])
                - {"android-loop-latency-focus-and-resume-test"}
            )
            | set(music_approval["remainingReleaseValidation"])
        ),
    }
    write_json(PRODUCTION_PATH, production)
    print(
        f"Promoted {len(art_runtime)} art runtimes and "
        f"{len(audio_approved['assets'])} audio runtimes"
    )


if __name__ == "__main__":
    main()
