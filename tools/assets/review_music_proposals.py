#!/usr/bin/env python3
"""Review the six independently produced music demos and build their manifest.

The proposal tracks are exploratory music candidates. Passing this review means
that the files are technically playable and meet the demo delivery contract; it
does not approve musical taste, cultural fit, similarity, or device fatigue.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
from typing import Any

import numpy as np
import soundfile as sf

from audio_common import amp_to_db, dump_json, measure_file, sha256_file


ROOT = Path(__file__).resolve().parents[2]
SAMPLE_RATE = 48_000
EXPECTED_FRAMES = 4_404_706
EXPECTED_CHANNELS = 2
TARGET_LUFS = -16.0
LUFS_TOLERANCE = 0.35
TRUE_PEAK_CEILING_DBTP = -1.0
DC_LIMIT = 1.0e-4
BOUNDARY_FRAMES = 1_024
# The shipped audio pipeline accepts decoded Vorbis seams at -24 dBFS because
# CoreAudio/libsndfile disagree about pre-skip. Proposal demos use a much
# stricter threshold while still allowing harmless codec residue.
DECODED_SEAM_CEILING_DBFS = -80.0

TRACKS: tuple[dict[str, str], ...] = (
    {
        "id": "DEMO-PHONK-CORTE-NEON",
        "title": "Corte de Neon",
        "genre": "Phonk",
        "agent": "producer_corte_neon",
        "slug": "corte_de_neon",
        "description": "Cowbell FM monofonico, freios ritmicos e derrapagem controlada.",
    },
    {
        "id": "DEMO-PHONK-ORBITA-DE-BOLSO",
        "title": "Órbita de Bolso",
        "genre": "Phonk",
        "agent": "producer_orbita_bolso",
        "slug": "orbita_de_bolso",
        "description": "Sub orbital com pitch envelope, rim seco e nenhum cowbell.",
    },
    {
        "id": "DEMO-BREGA-SOL-DE-MOLA",
        "title": "Sol de Mola",
        "genre": "Brega funk",
        "agent": "producer_sol_mola",
        "slug": "sol_de_mola",
        "description": "Percussão corporal sintetizada e grave elástico de resposta.",
    },
    {
        "id": "DEMO-BREGA-GUICHE-0367",
        "title": "Guichê das 03:67",
        "genre": "Brega funk",
        "agent": "producer_guiche_0367",
        "slug": "guiche_das_03_67",
        "description": "Clicks plásticos e metais abafados numa repartição cósmica.",
    },
    {
        "id": "DEMO-HYBRID-NEON-FORA-DO-AR",
        "title": "Neon Fora do Ar",
        "genre": "Brega funk 60% + Phonk 40%",
        "agent": "producer_neon_fora_ar",
        "slug": "neon_fora_do_ar",
        "description": "Chamada de três golpes atravessando filtros como um sinal interrompido.",
    },
    {
        "id": "DEMO-HYBRID-OFICINA-DE-ORBITA",
        "title": "Oficina de Órbita",
        "genre": "Phonk 60% + Brega funk 40%",
        "agent": "producer_oficina_orbita",
        "slug": "oficina_de_orbita",
        "description": "Baixo FM e trinca sincopada alternando halftime e doubletime.",
    },
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rerender",
        action="store_true",
        help="run each source once and require audio hashes to remain unchanged",
    )
    return parser.parse_args()


def paths_for(track: dict[str, str]) -> dict[str, Path]:
    slug = track["slug"]
    return {
        "source": ROOT / f"sources/audio/proposals/{slug}.py",
        "master": ROOT / f"masters/audio/proposals/{slug}.wav",
        "runtime": ROOT / f"assets/audio/proposals/{slug}.ogg",
        "report": ROOT / f"reports/audio-proposals/{slug}.json",
    }


def boundary_metrics(path: Path) -> dict[str, Any]:
    audio, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    boundary = min(BOUNDARY_FRAMES, audio.shape[0] // 2)
    first = float(np.max(np.abs(audio[:boundary]), initial=0.0))
    last = float(np.max(np.abs(audio[-boundary:]), initial=0.0))
    seam = float(np.max(np.abs(audio[0] - audio[-1]), initial=0.0))
    mono = np.mean(audio, axis=1)
    side = (audio[:, 0] - audio[:, 1]) * np.float32(0.5)
    mono_rms = float(np.sqrt(np.mean(np.square(mono), dtype=np.float64)))
    side_rms = float(np.sqrt(np.mean(np.square(side), dtype=np.float64)))
    return {
        "sampleRate": sample_rate,
        "firstBoundaryPeakDbfs": round(amp_to_db(first), 4),
        "lastBoundaryPeakDbfs": round(amp_to_db(last), 4),
        "seamDeltaDbfs": round(amp_to_db(seam), 4),
        "sideToMonoRmsDb": round(amp_to_db(side_rms / max(mono_rms, 1.0e-12)), 4),
    }


def check_metrics(label: str, metrics: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    if metrics["sampleRate"] != SAMPLE_RATE:
        failures.append(f"{label}: sample rate {metrics['sampleRate']} != {SAMPLE_RATE}")
    if metrics["frames"] != EXPECTED_FRAMES:
        failures.append(f"{label}: frames {metrics['frames']} != {EXPECTED_FRAMES}")
    if metrics["channels"] != EXPECTED_CHANNELS:
        failures.append(f"{label}: channels {metrics['channels']} != {EXPECTED_CHANNELS}")
    loudness = metrics["integratedLufs"]
    if loudness is None or abs(loudness - TARGET_LUFS) > LUFS_TOLERANCE:
        failures.append(f"{label}: integrated loudness {loudness} outside target")
    true_peak = metrics["truePeakDbtp"]
    if true_peak is None or true_peak > TRUE_PEAK_CEILING_DBTP:
        failures.append(f"{label}: true peak {true_peak} exceeds {TRUE_PEAK_CEILING_DBTP}")
    if max(abs(float(value)) for value in metrics["dcOffset"]) >= DC_LIMIT:
        failures.append(f"{label}: DC offset {metrics['dcOffset']} exceeds {DC_LIMIT}")
    if metrics["samplePeakDbfs"] >= -0.1:
        failures.append(f"{label}: sample peak {metrics['samplePeakDbfs']} risks clipping")
    return failures


def rerender(track: dict[str, str], paths: dict[str, Path]) -> dict[str, Any]:
    before = {
        "master": sha256_file(paths["master"]),
        "runtime": sha256_file(paths["runtime"]),
    }
    command = [str(ROOT / ".asset-venv/bin/python"), str(paths["source"])]
    completed = subprocess.run(command, cwd=ROOT, check=False, text=True, capture_output=True)
    if completed.returncode != 0:
        raise RuntimeError(
            f"rerender failed for {track['title']}:\n{completed.stdout}\n{completed.stderr}"
        )
    after = {
        "master": sha256_file(paths["master"]),
        "runtime": sha256_file(paths["runtime"]),
    }
    return {
        "command": command,
        "masterStable": before["master"] == after["master"],
        "runtimeStable": before["runtime"] == after["runtime"],
        "before": before,
        "after": after,
    }


def main() -> int:
    args = parse_args()
    entries: list[dict[str, Any]] = []
    failures: list[str] = []

    for track in TRACKS:
        paths = paths_for(track)
        missing = [name for name, path in paths.items() if not path.is_file()]
        if missing:
            failures.append(f"{track['title']}: missing {', '.join(missing)}")
            continue

        master_metrics, _ = measure_file(paths["master"])
        runtime_metrics, _ = measure_file(paths["runtime"])
        failures.extend(check_metrics(f"{track['title']} master", master_metrics))
        failures.extend(check_metrics(f"{track['title']} runtime", runtime_metrics))
        boundary = boundary_metrics(paths["runtime"])
        if boundary["seamDeltaDbfs"] > DECODED_SEAM_CEILING_DBFS:
            failures.append(
                f"{track['title']}: decoded seam delta {boundary['seamDeltaDbfs']} dBFS"
            )

        agent_report = json.loads(paths["report"].read_text(encoding="utf-8"))
        deterministic = None
        if args.rerender:
            deterministic = rerender(track, paths)
            if not deterministic["masterStable"] or not deterministic["runtimeStable"]:
                failures.append(f"{track['title']}: rerender changed audio hashes")

        entries.append(
            {
                **track,
                "status": "refined-demo",
                "sourcePath": paths["source"].relative_to(ROOT).as_posix(),
                "masterPath": paths["master"].relative_to(ROOT).as_posix(),
                "runtimePath": paths["runtime"].relative_to(ROOT).as_posix(),
                "reportPath": paths["report"].relative_to(ROOT).as_posix(),
                "masterSha256": sha256_file(paths["master"]),
                "runtimeSha256": sha256_file(paths["runtime"]),
                "metrics": {"master": master_metrics, "runtime": runtime_metrics},
                "boundary": boundary,
                "agentRefinement": agent_report.get("refinementHistory")
                or agent_report.get("revisions")
                or agent_report.get("passes"),
                "deterministicRerender": deterministic,
            }
        )

    passed = not failures and len(entries) == len(TRACKS)
    review = {
        "contract": "music-proposal-review-v1",
        "reviewedAtUtc": datetime.now(timezone.utc).isoformat(),
        "status": "pass" if passed else "fail",
        "expected": len(TRACKS),
        "reviewed": len(entries),
        "gates": {
            "sampleRate": SAMPLE_RATE,
            "frames": EXPECTED_FRAMES,
            "channels": EXPECTED_CHANNELS,
            "targetLufs": TARGET_LUFS,
            "lufsTolerance": LUFS_TOLERANCE,
            "truePeakCeilingDbtp": TRUE_PEAK_CEILING_DBTP,
            "dcLimit": DC_LIMIT,
            "decodedSeamCeilingDbfs": DECODED_SEAM_CEILING_DBFS,
        },
        "failures": failures,
        "tracks": entries,
        "humanListening": "pending",
        "culturalReview": "pending",
        "similarityReview": "pending",
        "deviceFatigueReview": "pending",
    }
    dump_json(ROOT / "reports/audio-proposals/review-summary.json", review)

    if passed:
        manifest = {
            "contract": "music-proposal-manifest-v1",
            "generatedAtUtc": review["reviewedAtUtc"],
            "status": "refined-demo-reviewed",
            "count": len(entries),
            "humanListening": "pending",
            "tracks": entries,
        }
        dump_json(ROOT / "assets/audio/proposals/proposal-manifest-v1.json", manifest)
        print(f"music proposal review passed: {len(entries)}/{len(TRACKS)}")
        return 0

    print("music proposal review failed:")
    for failure in failures:
        print(f"- {failure}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
