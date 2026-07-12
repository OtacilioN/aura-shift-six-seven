#!/usr/bin/env python3
"""Import the user-selected ChatGPT soundtrack without rewriting legacy r3 evidence.

The seven supplied WAV files are preserved byte-for-byte under ``sources/``.
This importer derives 48 kHz / PCM24 masters and deterministic Ogg/Vorbis
runtime files, then creates the v2 candidate/master manifests. The existing v1
candidate, masters and reports remain an immutable snapshot of the old
procedural soundtrack.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import platform
import shutil
from datetime import datetime, timezone
from importlib.metadata import version
from pathlib import Path
from typing import Any

import numpy as np
import soundfile as sf
from scipy import signal

from audio_common import (
    EPSILON,
    amp_to_db,
    integrated_lufs,
    measure_file,
    sha256_file,
    sha256_files,
    true_peak,
    write_master_and_runtime,
)


ROOT = Path(__file__).resolve().parents[2]
LEGACY_CANDIDATE = ROOT / "assets/audio/audio-candidate-manifest-v1.json"
CANDIDATE = ROOT / "assets/audio/audio-candidate-manifest-v2.json"
MASTER_CANDIDATE = ROOT / "masters/audio/master-candidate-manifest-v2.json"
SOURCE_DESTINATION = ROOT / "sources/audio/imported/chatgpt-2026-07-12"
TARGET_SAMPLE_RATE = 48_000
TARGET_LUFS = -16.0
TRUE_PEAK_CEILING_DBTP = -1.0
VORBIS_COMPRESSION_LEVEL = 0.4


TRACKS = (
    {
        "id": "MUS-BOSS-SHIFT",
        "title": "Boss Shift",
        "source": "09_boss_shift.wav",
        "slug": "boss_shift",
        "sha256": "2e580e738faab248b451f59e1a342e8f20be7e2a65e109cfb4b1618f1c1011d5",
        "primary": True,
    },
    {
        "id": "MUS-NEON-DRIFT-67",
        "title": "Neon Drift 67",
        "source": "01_neon_drift_67.wav",
        "slug": "neon_drift_67",
        "sha256": "cf22770c88ce4c82516026cae5e536262a5169aeb7dd1e4f3b5f3394c3e0f12e",
        "primary": False,
    },
    {
        "id": "MUS-AURA-NO-RETROVISOR",
        "title": "Aura no Retrovisor",
        "source": "02_aura_no_retrovisor.wav",
        "slug": "aura_no_retrovisor",
        "sha256": "47d68c8e54d912788c5c8beb6dba556024e25a9bc26e0e7e30f99948e40937a0",
        "primary": False,
    },
    {
        "id": "MUS-PASSINHO-DE-AURA",
        "title": "Passinho de Aura",
        "source": "04_passinho_de_aura.wav",
        "slug": "passinho_de_aura",
        "sha256": "cb98ccdf99df10ff1309a86ff30d6c366df9372f5994e9c614ba250cd3b7f786",
        "primary": False,
    },
    {
        "id": "MUS-SIXSEVEN-NO-FLUXO",
        "title": "SixSeven no Fluxo",
        "source": "05_sixseven_no_fluxo.wav",
        "slug": "sixseven_no_fluxo",
        "sha256": "56f439581f77d64589f1654345b3192bfb5a23214f6d22042611621ed1644692",
        "primary": False,
    },
    {
        "id": "MUS-PHASE-BLOOM",
        "title": "Phase Bloom",
        "source": "07_phase_bloom.wav",
        "slug": "phase_bloom",
        "sha256": "85a1108a000f7ecc7ba76030833e571b9d81fd9a60df15bf5a8dcd90d8fdb667",
        "primary": False,
    },
    {
        "id": "MUS-RITUAL-6-7",
        "title": "Ritual 6/7",
        "source": "08_ritual_6_7.wav",
        "slug": "ritual_6_7",
        "sha256": "375987f8425e5de946ab5ddd69aa9e781fb3d7858aab7569273e5f9f9fe6b005",
        "primary": False,
    },
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=SOURCE_DESTINATION,
        help=(
            "Directory containing the seven selected WAV files. Defaults to "
            "the byte-for-byte sources preserved in this repository."
        ),
    )
    return parser.parse_args()


def dump_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def normalized_master(source: Path) -> tuple[np.ndarray, float, dict[str, Any]]:
    audio, sample_rate = sf.read(source, dtype="float32", always_2d=True)
    if sample_rate != 44_100 or audio.shape[1] != 2:
        raise SystemExit(
            f"unexpected source layout for {source.name}: "
            f"{sample_rate} Hz / {audio.shape[1]} channels"
        )
    resampled = signal.resample_poly(audio, 160, 147, axis=0).astype(
        np.float32, copy=False
    )
    measured_lufs = integrated_lufs(resampled, TARGET_SAMPLE_RATE)
    if measured_lufs is None:
        raise SystemExit(f"unable to measure loudness: {source}")
    gain_db = TARGET_LUFS - measured_lufs
    mastered = resampled * np.float32(10.0 ** (gain_db / 20.0))
    measured_true_peak = true_peak(mastered)
    ceiling = 10.0 ** (TRUE_PEAK_CEILING_DBTP / 20.0)
    if measured_true_peak > ceiling:
        safety_gain = ceiling / max(measured_true_peak, EPSILON)
        mastered *= np.float32(safety_gain)
        gain_db += amp_to_db(safety_gain)
    return mastered, gain_db, {
        "algorithm": "scipy.signal.resample_poly",
        "ratio": "160/147",
        "sourceSampleRate": sample_rate,
        "targetSampleRate": TARGET_SAMPLE_RATE,
        "targetIntegratedLufs": TARGET_LUFS,
        "truePeakCeilingDbtp": TRUE_PEAK_CEILING_DBTP,
        "appliedGainDb": round(gain_db, 4),
        "compressionOrLimiting": False,
    }


def mono_metrics(path: Path) -> dict[str, float]:
    audio, _ = sf.read(path, dtype="float32", always_2d=True)
    left = audio[:, 0]
    right = audio[:, 1]
    correlation = float(np.corrcoef(left, right)[0, 1])
    stereo_rms = float(np.sqrt(np.mean(np.square(audio), dtype=np.float64)))
    mono = np.mean(audio, axis=1)
    mono_rms = float(np.sqrt(np.mean(np.square(mono), dtype=np.float64)))
    return {
        "leftRightCorrelation": round(correlation, 6),
        "monoToStereoRmsDb": round(amp_to_db(mono_rms / stereo_rms), 4),
    }


def provenance_text(
    track: dict[str, Any],
    source_path: str,
    source_metrics: dict[str, Any],
    master_path: str,
    master_metrics: dict[str, Any],
    runtime_path: str,
    runtime_metrics: dict[str, Any],
    processing: dict[str, Any],
) -> str:
    role = "tema principal e primeira faixa da playlist" if track["primary"] else "playlist"
    return f"""# {track['id']} — proveniência da trilha selecionada

- **Título:** {track['title']}
- **ID:** `{track['id']}`
- **Papel:** {role}
- **Status técnico:** `candidate-reviewed`; o derivado de runtime é promovido pela decisão humana de 12 de julho de 2026.
- **Origem declarada pelo usuário:** geração musical via ChatGPT, entregue como WAV e selecionada pelo usuário.
- **Prompt/modelo/sessão:** não fornecidos junto aos arquivos; não inferidos por este registro.
- **Licença/termos comerciais:** comprovação externa pendente antes de uma publicação comercial.

## Cadeia de custódia

- **Fonte preservada:** `{source_path}`
- **SHA-256 da fonte:** `{source_metrics['sha256']}`
- **Fonte:** `{source_metrics['sampleRate']} Hz`, `{source_metrics['subtype']}`, `{source_metrics['channels']}` canais, `{source_metrics['durationSeconds']}` s.
- **Métricas da fonte:** `{source_metrics['integratedLufs']}` LUFS-I, `{source_metrics['samplePeakDbfs']}` dBFS peak, `{source_metrics['truePeakDbtp']}` dBTP.
- **Processamento:** resample polifásico `{processing['ratio']}` para `48000 Hz`, ganho de `{processing['appliedGainDb']}` dB até `-16 LUFS-I`; sem compressor ou limiter.
- **Master derivado:** `{master_path}` — `{master_metrics['sha256']}`
- **Runtime Android:** `{runtime_path}` — `{runtime_metrics['sha256']}`
- **Runtime:** Ogg/Vorbis q6, `{runtime_metrics['sampleRate']} Hz`, `{runtime_metrics['channels']}` canais, `{runtime_metrics['durationSeconds']}` s, `{runtime_metrics['integratedLufs']}` LUFS-I, `{runtime_metrics['truePeakDbtp']}` dBTP.

## Playback e revisão residual

- Faixa completa `non-loop`; o runtime toca uma voz musical e avança por posição/conclusão com crossfade.
- A seleção humana desta faixa está registrada em `assets/manifests/music-selection-approval-v1.json`.
- Similaridade independente, fadiga, foco/retomada e crossfade em aparelho Android permanecem gates de release; esta proveniência não afirma que esses testes externos já ocorreram.
"""


def main() -> int:
    args = parse_args()
    source_dir = args.source_dir.expanduser().resolve()
    legacy = json.loads(LEGACY_CANDIDATE.read_text(encoding="utf-8"))
    effects = [entry for entry in legacy["assets"] if entry["group"] != "music"]
    if len(effects) != 35 or any(entry.get("status") != "candidate-reviewed" for entry in effects):
        raise SystemExit("legacy candidate must provide exactly 35 reviewed SFX")

    SOURCE_DESTINATION.mkdir(parents=True, exist_ok=True)
    entries: list[dict[str, Any]] = []
    for playlist_order, track in enumerate(TRACKS):
        incoming = source_dir / track["source"]
        if not incoming.is_file():
            raise SystemExit(f"missing selected source: {incoming}")
        if sha256_file(incoming) != track["sha256"]:
            raise SystemExit(f"selected source hash mismatch: {incoming}")

        source_copy = SOURCE_DESTINATION / track["source"]
        if incoming.resolve() != source_copy.resolve():
            shutil.copyfile(incoming, source_copy)
        source_metrics, source_info = measure_file(source_copy)
        if source_info.format != "WAV" or source_info.subtype != "PCM_24":
            raise SystemExit(f"selected source is not WAV/PCM24: {incoming}")

        master_path = f"masters/audio/mus_{track['slug']}.wav"
        runtime_path = f"assets/audio/music/mus_{track['slug']}.ogg"
        asset = {
            "id": track["id"],
            "channels": 2,
            "master": master_path,
            "runtime": runtime_path,
        }
        mastered, _, processing = normalized_master(source_copy)
        write_master_and_runtime(
            ROOT,
            asset,
            mastered,
            TARGET_SAMPLE_RATE,
            VORBIS_COMPRESSION_LEVEL,
        )
        master_metrics, _ = measure_file(ROOT / master_path)
        runtime_metrics, _ = measure_file(ROOT / runtime_path)
        if runtime_metrics["frames"] != master_metrics["frames"]:
            raise SystemExit(f"runtime frame mismatch: {track['id']}")
        if runtime_metrics["integratedLufs"] is None or not math.isclose(
            runtime_metrics["integratedLufs"], TARGET_LUFS, abs_tol=0.25
        ):
            raise SystemExit(f"runtime loudness mismatch: {track['id']}")

        source_relative = source_copy.relative_to(ROOT).as_posix()
        license_record = f"provenance/audio/mus-{track['slug'].replace('_', '-')}.md"
        entry = {
            "id": track["id"],
            "revision": 1,
            "status": "candidate-reviewed",
            "required": True,
            "conditional": False,
            "group": "music",
            "kind": "soundtrack_primary" if track["primary"] else "soundtrack",
            "title": track["title"],
            "primary": track["primary"],
            "playlistOrder": playlist_order,
            "sourcePath": source_relative,
            "sourceSha256": source_metrics["sha256"],
            "sourceGenerator": "ChatGPT (declared by user)",
            "masterPath": master_path,
            "masterSha256": master_metrics["sha256"],
            "runtimePath": runtime_path,
            "runtimeSha256": runtime_metrics["sha256"],
            "sampleRate": TARGET_SAMPLE_RATE,
            "channels": 2,
            "loop": False,
            "loopStartSample": None,
            "loopEndSample": None,
            "runtimeDither": None,
            "generatedMetrics": source_metrics,
            "reviewedMetrics": {
                "source": source_metrics,
                "master": master_metrics,
                "runtime": runtime_metrics,
                "mono": mono_metrics(ROOT / master_path),
                "processing": processing,
                "decoder": {
                    "result": "frame-count-exact-libsndfile",
                    "expectedFrames": master_metrics["frames"],
                    "decodedFrames": runtime_metrics["frames"],
                    "nonLoop": True,
                },
            },
            "licenseRecord": license_record,
            "humanSelection": "approved-by-user-2026-07-12",
            "rightsReview": "commercial-terms-and-similarity-pending",
        }
        entries.append(entry)
        provenance = ROOT / license_record
        provenance.parent.mkdir(parents=True, exist_ok=True)
        provenance.write_text(
            provenance_text(
                track,
                source_relative,
                source_metrics,
                master_path,
                master_metrics,
                runtime_path,
                runtime_metrics,
                processing,
            ),
            encoding="utf-8",
        )
        print(f"[music-v2] imported {track['title']}", flush=True)

    inherited_sfx = json.loads(json.dumps(effects))
    assets = entries + inherited_sfx
    source_files = [
        *(ROOT / entry["sourcePath"] for entry in entries),
        ROOT / "tools/assets/import_selected_music.py",
        ROOT / "tools/assets/audio_common.py",
        LEGACY_CANDIDATE,
    ]
    source_bundle_sha256 = sha256_files(source_files, base=ROOT)
    generated_at = datetime.now(timezone.utc).isoformat()
    if CANDIDATE.is_file():
        previous = json.loads(CANDIDATE.read_text(encoding="utf-8"))
        if previous.get("sourceBundleSha256") == source_bundle_sha256:
            generated_at = previous.get("generatedAtUtc", generated_at)
    manifest = {
        "contract": "audio-candidate-manifest-v2",
        "revision": 1,
        "status": "candidate-reviewed",
        "generatedAtUtc": generated_at,
        "reviewedAtUtc": generated_at,
        "sourceBundleContract": "selected-music-import-v1-plus-legacy-sfx-r3",
        "sourceBundleSha256": source_bundle_sha256,
        "sourceBundleFiles": [path.relative_to(ROOT).as_posix() for path in source_files],
        "legacySfxSource": {
            "manifest": LEGACY_CANDIDATE.relative_to(ROOT).as_posix(),
            "manifestSha256": sha256_file(LEGACY_CANDIDATE),
            "reviewEvidenceRevision": legacy.get("reviewEvidenceRevision"),
            "reviewEvidenceSha256": legacy.get("reviewBundle", {}).get("sha256"),
        },
        "sourcePolicy": {
            "music": {
                "externalAudioInputs": True,
                "generativeAudioModel": True,
                "declaredTool": "ChatGPT",
                "promptAndModelMetadata": "not-provided",
                "userSelectionDate": "2026-07-12",
            },
            "soundEffects": "inherited-unchanged-from-reviewed-r3-candidate",
        },
        "sampleRate": TARGET_SAMPLE_RATE,
        "masterBitDepth": 24,
        "runtimeEncoding": {
            "music": {
                "format": "Ogg/Vorbis",
                "compressionLevel": VORBIS_COMPRESSION_LEVEL,
                "target": "q6",
                "loop": False,
            },
            "soundEffects": legacy["runtimeEncoding"]["sfx"],
        },
        "counts": {"required": 42, "conditional": 0, "total": 42},
        "humanReview": "selected-and-approved-by-user-2026-07-12",
        "similarityReview": "independent-review-pending",
        "rightsReview": "commercial-terms-pending",
        "androidDeviceReview": "playlist-crossfade-focus-resume-pending",
        "toolVersions": {
            "python": platform.python_version(),
            "numpy": version("numpy"),
            "scipy": version("scipy"),
            "soundfile": version("soundfile"),
            "libsndfile": sf.__libsndfile_version__,
        },
        "technicalReview": {
            "musicSources": "7/7 WAV PCM24 stereo validated",
            "musicRuntimeFrameCount": "7/7",
            "musicLoudnessTarget": "7/7 within 0.25 LU of -16 LUFS-I",
            "musicPlayback": "non-loop single-voice playlist",
            "sfxInherited": "35/35 unchanged from r3",
        },
        "assets": assets,
    }
    dump_json(CANDIDATE, manifest)
    dump_json(
        MASTER_CANDIDATE,
        {
            **{key: value for key, value in manifest.items() if key != "assets"},
            "contract": "audio-master-candidate-manifest-v2",
            "assets": assets,
        },
    )
    print(f"[music-v2] wrote {CANDIDATE.relative_to(ROOT)} with 42 assets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
