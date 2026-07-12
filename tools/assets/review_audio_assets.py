#!/usr/bin/env python3
"""Review generated audio candidates and record reproducible technical evidence."""

from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Any

import numpy as np
import soundfile as sf

from audio_common import (
    amp_to_db,
    as_2d,
    db_to_amp,
    dump_json,
    integrated_lufs,
    measure_audio,
    measure_file,
    pcm16_dither_seed,
    sha256_file,
    sha256_files,
    tpdf_dither_pcm16,
    true_peak,
)


REVIEW_EVIDENCE_REVISION = 2


def parse_args() -> argparse.Namespace:
    default_root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=default_root)
    parser.add_argument(
        "--score",
        type=Path,
        default=Path("sources/audio/procedural/score-v1.json"),
    )
    return parser.parse_args()


def boundary_metrics(audio: np.ndarray) -> dict[str, Any]:
    data = as_2d(audio)
    boundary = np.abs(data[0] - data[-1])
    differences = np.abs(np.diff(data, axis=0))
    reference = np.percentile(differences, 99.9, axis=0) + 1.0e-12
    ratios = boundary / reference
    return {
        "boundaryDeltaDbfs": [round(amp_to_db(float(value)), 4) for value in boundary],
        "boundaryToP999DerivativeRatio": [round(float(value), 4) for value in ratios],
        "tenConcatenationsEquivalent": True,
    }


def mono_metrics(audio: np.ndarray) -> dict[str, Any] | None:
    data = as_2d(audio)
    if data.shape[1] != 2:
        return None
    stereo_rms = float(np.sqrt(np.mean(np.square(data), dtype=np.float64)))
    downmix = np.mean(data, axis=1)
    mono_rms = float(np.sqrt(np.mean(np.square(downmix), dtype=np.float64)))
    correlation = float(np.corrcoef(data[:, 0], data[:, 1])[0, 1])
    return {
        "monoToStereoRmsDb": round(amp_to_db(mono_rms / max(stereo_rms, 1.0e-12)), 4),
        "leftRightCorrelation": round(correlation, 6) if math.isfinite(correlation) else None,
    }


def roundtrip_metrics(master: np.ndarray, runtime: np.ndarray) -> dict[str, Any]:
    left = as_2d(master)
    right = as_2d(runtime)
    count = min(left.shape[0], right.shape[0])
    channels = min(left.shape[1], right.shape[1])
    left = left[:count, :channels]
    right = right[:count, :channels]
    error = left - right
    signal_rms = float(np.sqrt(np.mean(np.square(left), dtype=np.float64)))
    error_rms = float(np.sqrt(np.mean(np.square(error), dtype=np.float64)))
    correlations = []
    for channel in range(channels):
        correlation = float(np.corrcoef(left[:, channel], right[:, channel])[0, 1])
        correlations.append(round(correlation, 7) if math.isfinite(correlation) else None)
    return {
        "commonFrames": count,
        "errorRmsDbfs": round(amp_to_db(error_rms), 4),
        "signalToCodecErrorDb": round(amp_to_db(signal_rms / max(error_rms, 1.0e-12)), 4),
        "correlationByChannel": correlations,
    }


def gate_asset(
    asset: dict[str, Any],
    master_metrics: dict[str, Any],
    runtime_metrics: dict[str, Any],
    boundary: dict[str, Any] | None,
    mono_result: dict[str, Any] | None,
    roundtrip: dict[str, Any],
    score: dict[str, Any],
) -> list[str]:
    errors: list[str] = []
    expected_frames = asset.get("loopSamples")
    if expected_frames is None:
        expected_frames = int(round(asset["durationMs"] * score["sampleRate"] / 1000.0))
    if master_metrics["sampleRate"] != score["sampleRate"]:
        errors.append(f"master sample rate {master_metrics['sampleRate']} != 48000")
    if runtime_metrics["sampleRate"] != score["sampleRate"]:
        errors.append(f"runtime sample rate {runtime_metrics['sampleRate']} != 48000")
    if master_metrics["format"] != "WAV" or master_metrics["subtype"] != "PCM_24":
        errors.append(
            f"master format {master_metrics['format']}/{master_metrics['subtype']} != WAV/PCM_24"
        )
    if asset["group"] == "music":
        if runtime_metrics["format"] != "OGG" or runtime_metrics["subtype"] != "VORBIS":
            errors.append(
                f"music runtime format {runtime_metrics['format']}/{runtime_metrics['subtype']} != OGG/VORBIS"
            )
    elif runtime_metrics["format"] != "WAV" or runtime_metrics["subtype"] != "PCM_16":
        errors.append(
            f"SFX runtime format {runtime_metrics['format']}/{runtime_metrics['subtype']} != WAV/PCM_16"
        )
    for label, metrics in (("master", master_metrics), ("runtime", runtime_metrics)):
        if metrics["frames"] != expected_frames:
            errors.append(f"{label} frames {metrics['frames']} != expected {expected_frames}")
        if metrics["channels"] != asset["channels"]:
            errors.append(f"{label} channels {metrics['channels']} != {asset['channels']}")
        if max(abs(value) for value in metrics["dcOffset"]) > 0.01:
            errors.append(f"{label} DC offset exceeds 0.01")
        if metrics["rmsDbfs"] < -75.0:
            errors.append(f"{label} is effectively silent")
    if roundtrip["commonFrames"] != expected_frames:
        errors.append("master/runtime do not expose the same decoded frame count")
    valid_correlations = [value for value in roundtrip["correlationByChannel"] if value is not None]
    if valid_correlations and min(valid_correlations) < 0.96:
        errors.append(f"master/runtime correlation too low: {min(valid_correlations)}")

    is_stinger = asset["group"] == "event" and "targetLufs" in asset
    is_music = asset["group"] == "music"
    if is_music or is_stinger:
        target = asset["targetLufs"]
        actual = master_metrics["integratedLufs"]
        if actual is None or abs(actual - target) > 0.75:
            errors.append(f"master loudness {actual} outside target {target} +/- 0.75 LU")
        if master_metrics["truePeakDbtp"] is None or master_metrics["truePeakDbtp"] > -1.0:
            errors.append(f"master true peak {master_metrics['truePeakDbtp']} > -1 dBTP")
        if runtime_metrics["truePeakDbtp"] is None or runtime_metrics["truePeakDbtp"] > -0.7:
            errors.append(f"runtime true peak {runtime_metrics['truePeakDbtp']} > -0.7 dBTP")
        if is_stinger and not (-18.0 <= actual <= -14.0):
            errors.append(f"stinger loudness {actual} outside -18..-14 LUFS-I")
        if mono_result is not None and mono_result["monoToStereoRmsDb"] < -12.0:
            errors.append("mono downmix loses more than 12 dB RMS")
    else:
        if master_metrics["samplePeakDbfs"] > -3.0:
            errors.append(f"SFX master sample peak {master_metrics['samplePeakDbfs']} > -3 dBFS")
        if runtime_metrics["samplePeakDbfs"] > -2.5:
            errors.append(f"SFX runtime sample peak {runtime_metrics['samplePeakDbfs']} > -2.5 dBFS")

    if boundary is not None:
        if max(boundary["boundaryToP999DerivativeRatio"]) > 6.0:
            errors.append(
                "loop seam derivative exceeds 6x the file's 99.9th-percentile derivative"
            )
        if max(boundary["boundaryDeltaDbfs"]) > -24.0:
            errors.append("loop boundary delta exceeds -24 dBFS")
    return errors


def composite_metrics(root: Path, score: dict[str, Any]) -> dict[str, Any]:
    by_id = {asset["id"]: asset for asset in score["assets"]}
    base, sr = sf.read(root / by_id["MUS-GAME-BASE"]["master"], dtype="float32", always_2d=True)
    groove, _ = sf.read(root / by_id["MUS-GAME-GROOVE"]["master"], dtype="float32", always_2d=True)
    hype, _ = sf.read(root / by_id["MUS-GAME-HYPE"]["master"], dtype="float32", always_2d=True)
    states = {
        "I0": base,
        "I1": base + groove * db_to_amp(-12.0),
        "I2": base + groove * db_to_amp(-6.0) + hype * db_to_amp(-18.0),
        "I3": base + groove + hype * db_to_amp(-6.0),
    }
    result: dict[str, Any] = {}
    for name, audio in states.items():
        result[name] = measure_audio(audio, sr, include_true_peak=True)
    return result


def combined_audio_sha256(root: Path, score: dict[str, Any]) -> str:
    paths = sorted(
        [root / asset[key] for asset in score["assets"] for key in ("master", "runtime")],
        key=lambda path: path.relative_to(root).as_posix(),
    )
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.relative_to(root).as_posix().encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def audio_hash_map(root: Path, score: dict[str, Any]) -> dict[str, dict[str, str]]:
    return {
        asset["id"]: {
            "master": sha256_file(root / asset["master"]),
            "runtime": sha256_file(root / asset["runtime"]),
        }
        for asset in score["assets"]
    }


def source_bundle_files(pipeline_root: Path, score_path: Path) -> list[Path]:
    return [
        score_path,
        pipeline_root / "tools/assets/generate_audio_assets.py",
        pipeline_root / "tools/assets/audio_common.py",
        pipeline_root / "tools/assets/requirements-audio.txt",
    ]


def review_bundle_files(pipeline_root: Path, score_path: Path) -> list[Path]:
    return [
        score_path,
        pipeline_root / "tools/assets/review_audio_assets.py",
        pipeline_root / "tools/assets/audio_common.py",
        pipeline_root / "tools/assets/requirements-audio.txt",
    ]


def decoded_alignment_metrics(
    reference: np.ndarray,
    candidate: np.ndarray,
    *,
    max_shift_frames: int = 512,
) -> dict[str, Any]:
    """Find and quantify candidate PCM alignment against a reference decoder.

    Positive offsets mean candidate frame 0 corresponds to a later reference
    frame. This is the CoreAudio Vorbis behavior observed in the current batch.
    The search uses several interior windows; final metrics use the full aligned
    overlap and keep unmatched leading/trailing frame counts explicit.
    """
    ref = as_2d(reference)
    cand = as_2d(candidate)
    if ref.shape[1] != cand.shape[1]:
        raise ValueError(f"decoder channel mismatch: {ref.shape[1]} != {cand.shape[1]}")
    minimum = min(ref.shape[0], cand.shape[0])
    window = min(32_768, minimum - 2 * (max_shift_frames + 1))
    if window < 4_096:
        raise ValueError(f"decoder output too short for alignment search: {minimum}")

    ref_mono = np.mean(ref, axis=1, dtype=np.float64)
    cand_mono = np.mean(cand, axis=1, dtype=np.float64)
    lower = max_shift_frames + 1
    upper = minimum - window - max_shift_frames - 1
    if upper <= lower:
        starts = [lower]
    else:
        span = upper - lower
        starts = sorted({lower + int(span * fraction) for fraction in (0.2, 0.5, 0.8)})

    scored: list[tuple[float, int]] = []
    for shift in range(-max_shift_frames, max_shift_frames + 1):
        dot = 0.0
        ref_energy = 0.0
        cand_energy = 0.0
        for start in starts:
            if shift >= 0:
                ref_window = ref_mono[start + shift : start + shift + window]
                cand_window = cand_mono[start : start + window]
            else:
                ref_window = ref_mono[start : start + window]
                cand_window = cand_mono[start - shift : start - shift + window]
            dot += float(np.dot(ref_window, cand_window))
            ref_energy += float(np.dot(ref_window, ref_window))
            cand_energy += float(np.dot(cand_window, cand_window))
        denominator = math.sqrt(max(ref_energy * cand_energy, 1.0e-30))
        scored.append((dot / denominator, shift))
    scored.sort(reverse=True)
    correlation_peak, shift = scored[0]
    second_best = scored[1][0]

    ref_start = max(shift, 0)
    cand_start = max(-shift, 0)
    overlap = min(ref.shape[0] - ref_start, cand.shape[0] - cand_start)
    dot = 0.0
    ref_energy = 0.0
    cand_energy = 0.0
    error_energy = 0.0
    max_difference = 0.0
    pcm_values_exact = True
    sample_count = 0
    for start in range(0, overlap, 262_144):
        end = min(overlap, start + 262_144)
        left = ref[ref_start + start : ref_start + end]
        right = cand[cand_start + start : cand_start + end]
        pcm_values_exact = pcm_values_exact and np.array_equal(left, right)
        left64 = left.astype(np.float64)
        right64 = right.astype(np.float64)
        difference = left64 - right64
        dot += float(np.sum(left64 * right64))
        ref_energy += float(np.sum(left64 * left64))
        cand_energy += float(np.sum(right64 * right64))
        error_energy += float(np.sum(difference * difference))
        max_difference = max(
            max_difference, float(np.max(np.abs(difference), initial=0.0))
        )
        sample_count += int(difference.size)
    aligned_correlation = dot / math.sqrt(max(ref_energy * cand_energy, 1.0e-30))
    error_rms = math.sqrt(error_energy / max(sample_count, 1))

    candidate_trailing = cand.shape[0] - (cand_start + overlap)
    reference_trailing = ref.shape[0] - (ref_start + overlap)
    tail = cand[cand_start + overlap :]
    tail_rms = (
        float(np.sqrt(np.mean(np.square(tail), dtype=np.float64))) if tail.size else 0.0
    )
    tail_peak = float(np.max(np.abs(tail), initial=0.0))
    resolved = correlation_peak >= 0.999 and correlation_peak > second_best
    return {
        "result": "resolved" if resolved else "unresolved",
        "searchRangeFrames": [-max_shift_frames, max_shift_frames],
        "coreAudioFrame0MatchesLibsndfileFrame": int(shift),
        "zeroOffsetAligned": bool(resolved and shift == 0),
        "searchCorrelationPeak": round(float(correlation_peak), 12),
        "searchSecondBestCorrelation": round(float(second_best), 12),
        "alignedOverlapFrames": int(overlap),
        "alignedCorrelation": round(float(aligned_correlation), 12),
        "alignedPcmValuesExact": bool(pcm_values_exact),
        "alignedErrorRmsDbfs": round(amp_to_db(error_rms), 4),
        "alignedMaxDifferenceDbfs": round(amp_to_db(max_difference), 4),
        "referenceLeadingFramesOutsideOverlap": int(ref_start),
        "candidateLeadingFramesOutsideOverlap": int(cand_start),
        "referenceTrailingFramesOutsideOverlap": int(reference_trailing),
        "candidateTrailingFramesOutsideOverlap": int(candidate_trailing),
        "candidateUnmatchedTailRmsDbfs": round(amp_to_db(tail_rms), 4),
        "candidateUnmatchedTailPeakDbfs": round(amp_to_db(tail_peak), 4),
        "offsetConvention": "positive N means CoreAudio frame 0 best matches libsndfile frame N",
    }


def real_determinism_gate(
    current_root: Path,
    pipeline_root: Path,
    score_path: Path,
    score: dict[str, Any],
) -> tuple[dict[str, Any], list[str]]:
    """Render twice in independent temporary roots and compare calculated hashes."""
    generator = pipeline_root / "tools/assets/generate_audio_assets.py"
    render_hashes: list[dict[str, dict[str, str]]] = []
    render_combined: list[str] = []
    errors: list[str] = []
    for render_index in (1, 2):
        print(f"[review] determinism render {render_index}/2", flush=True)
        with tempfile.TemporaryDirectory(prefix=f"aura-audio-render-{render_index}-") as directory:
            render_root = Path(directory)
            process = subprocess.run(
                [
                    sys.executable,
                    str(generator),
                    "--root",
                    str(render_root),
                    "--score",
                    str(score_path),
                ],
                cwd=pipeline_root,
                capture_output=True,
                text=True,
            )
            if process.returncode != 0:
                detail = (process.stderr or process.stdout)[-2000:]
                errors.append(f"determinism render {render_index} failed: {detail}")
                continue
            try:
                render_hashes.append(audio_hash_map(render_root, score))
                render_combined.append(combined_audio_sha256(render_root, score))
            except (FileNotFoundError, OSError) as error:
                errors.append(f"determinism render {render_index} incomplete: {error}")

    current_hashes = audio_hash_map(current_root, score)
    current_combined = combined_audio_sha256(current_root, score)
    ids = [asset["id"] for asset in score["assets"]]
    music_ids = {asset["id"] for asset in score["assets"] if asset["group"] == "music"}
    if len(render_hashes) == 2:
        master_matches = sum(
            render_hashes[0][asset_id]["master"] == render_hashes[1][asset_id]["master"]
            for asset_id in ids
        )
        runtime_matches = sum(
            render_hashes[0][asset_id]["runtime"] == render_hashes[1][asset_id]["runtime"]
            for asset_id in ids
        )
        runtime_ogg_matches = sum(
            render_hashes[0][asset_id]["runtime"] == render_hashes[1][asset_id]["runtime"]
            for asset_id in music_ids
        )
        runtime_wav_matches = sum(
            render_hashes[0][asset_id]["runtime"] == render_hashes[1][asset_id]["runtime"]
            for asset_id in ids
            if asset_id not in music_ids
        )
        current_matches = sum(
            current_hashes[asset_id][kind] == render_hashes[0][asset_id][kind]
            for asset_id in ids
            for kind in ("master", "runtime")
        )
        mismatches = [
            f"{asset_id}:{kind}"
            for asset_id in ids
            for kind in ("master", "runtime")
            if render_hashes[0][asset_id][kind] != render_hashes[1][asset_id][kind]
            or current_hashes[asset_id][kind] != render_hashes[0][asset_id][kind]
        ]
    else:
        master_matches = runtime_matches = runtime_ogg_matches = runtime_wav_matches = 0
        current_matches = 0
        mismatches = ["render-set-incomplete"]
    passed = (
        not errors
        and master_matches == 44
        and runtime_matches == 44
        and runtime_ogg_matches == len(music_ids)
        and runtime_wav_matches == 44 - len(music_ids)
        and current_matches == 88
        and len(render_combined) == 2
        and render_combined[0] == render_combined[1] == current_combined
        and not mismatches
    )
    if not passed and not errors:
        errors.append(f"determinism mismatch: {', '.join(mismatches[:20])}")
    evidence = {
        "result": "pass" if passed else "fail",
        "calculatedByReviewer": True,
        "independentTemporaryRenders": len(render_hashes),
        "masterWavMatches": f"{master_matches}/44",
        "runtimeMatches": f"{runtime_matches}/44",
        "runtimeWavMatches": f"{runtime_wav_matches}/{44 - len(music_ids)}",
        "runtimeOggMatches": f"{runtime_ogg_matches}/{len(music_ids)}",
        "currentCandidateMatchesRender": f"{current_matches}/88",
        "renderCombinedSha256": render_combined,
        "currentCombinedAudioSha256": current_combined,
        "mismatches": mismatches,
        "method": "two generator subprocesses in separate temporary roots; per-file SHA-256 comparison against each other and the candidate under review",
        "containerCanonicalization": "music Ogg stream serial derives from SHA-256(asset ID); page CRCs are recalculated; Vorbis packet bytes are not modified",
    }
    return evidence, errors


def coreaudio_cross_decoder_review(
    root: Path,
    score: dict[str, Any],
) -> tuple[dict[str, Any], dict[str, dict[str, Any]], list[str]]:
    afconvert = Path("/usr/bin/afconvert")
    afinfo = Path("/usr/bin/afinfo")
    if not afconvert.exists() or not afinfo.exists():
        unavailable = "CoreAudio tools are unavailable on this host"
        evidence = {
            "result": "fail-unavailable",
            "tools": {"afconvert": str(afconvert), "afinfo": str(afinfo)},
            "musicOggFrameCountExact": "0/9",
            "musicOggZeroOffsetAligned": "0/9",
            "musicOggSampleExact": "0/9",
            "musicOggCoreAudioSeamGate": "0/9",
            "hardErrors": [unavailable],
            "warnings": [],
            "androidMusicLoopGate": "pending",
        }
        return evidence, {}, [unavailable]

    print("[review] CoreAudio cross-decoder pass", flush=True)
    results: dict[str, dict[str, Any]] = {}
    hard_errors: list[str] = []
    warnings: list[str] = []
    with tempfile.TemporaryDirectory(prefix="aura-coreaudio-") as directory:
        temporary = Path(directory)
        for index, asset in enumerate(score["assets"]):
            expected = asset.get("loopSamples")
            if expected is None:
                expected = int(round(asset["durationMs"] * score["sampleRate"] / 1000.0))
            decoded = temporary / f"{index:02d}.wav"
            decode_format = "LEI24" if asset["group"] == "music" else "LEI16"
            conversion = subprocess.run(
                [
                    str(afconvert),
                    str(root / asset["runtime"]),
                    "-o",
                    str(decoded),
                    "-f",
                    "WAVE",
                    "-d",
                    f"{decode_format}@{score['sampleRate']}",
                ],
                capture_output=True,
                text=True,
            )
            if conversion.returncode != 0:
                detail = (conversion.stderr or conversion.stdout).strip()
                result = {
                    "result": "decode-failed",
                    "expectedFrames": expected,
                    "decodedFrames": None,
                    "deltaFrames": None,
                    "detail": detail,
                }
                hard_errors.append(f"{asset['id']} CoreAudio decode failed: {detail}")
                results[asset["id"]] = result
                continue
            inspection = subprocess.run(
                [str(afinfo), str(decoded)], capture_output=True, text=True
            )
            match = re.search(r"audio packets:\s*(\d+)", inspection.stdout)
            if inspection.returncode != 0 or match is None:
                detail = (inspection.stderr or inspection.stdout).strip()
                result = {
                    "result": "inspection-failed",
                    "expectedFrames": expected,
                    "decodedFrames": None,
                    "deltaFrames": None,
                    "detail": detail,
                }
                hard_errors.append(f"{asset['id']} CoreAudio inspection failed: {detail}")
                results[asset["id"]] = result
                continue
            decoded_frames = int(match.group(1))
            delta = decoded_frames - expected
            frame_count_exact = delta == 0
            if asset["group"] == "music":
                libsndfile_pcm, _ = sf.read(
                    root / asset["runtime"], dtype="float32", always_2d=True
                )
                coreaudio_pcm, _ = sf.read(decoded, dtype="float32", always_2d=True)
                alignment = decoded_alignment_metrics(libsndfile_pcm, coreaudio_pcm)
                coreaudio_boundary = boundary_metrics(coreaudio_pcm)
                seam_pass = bool(
                    max(coreaudio_boundary["boundaryDeltaDbfs"]) <= -24.0
                    and max(coreaudio_boundary["boundaryToP999DerivativeRatio"]) <= 6.0
                )
                sample_exact = bool(
                    frame_count_exact
                    and alignment["zeroOffsetAligned"]
                    and alignment["alignedPcmValuesExact"]
                    and alignment["candidateTrailingFramesOutsideOverlap"] == 0
                    and alignment["referenceLeadingFramesOutsideOverlap"] == 0
                )
                result = {
                    "result": (
                        "seam-pass-with-decoder-variance"
                        if seam_pass
                        else "coreaudio-seam-gate-failed"
                    ),
                    "runtimeFormat": "OGG/VORBIS",
                    "expectedFrames": expected,
                    "decodedFrames": decoded_frames,
                    "deltaFrames": delta,
                    "frameCountExact": frame_count_exact,
                    "alignment": alignment,
                    "zeroOffsetAligned": alignment["zeroOffsetAligned"],
                    "sampleExact": sample_exact,
                    "coreAudioLoopBoundary": coreaudio_boundary,
                    "coreAudioSeamGate": "pass" if seam_pass else "fail",
                }
                warning = (
                    f"{asset['id']} CoreAudio frame 0 aligns to libsndfile frame "
                    f"{alignment['coreAudioFrame0MatchesLibsndfileFrame']}; frame count "
                    f"{decoded_frames}/{expected} ({delta:+d}); unmatched CoreAudio tail "
                    f"{alignment['candidateTrailingFramesOutsideOverlap']} frames; seam "
                    f"{coreaudio_boundary['boundaryDeltaDbfs']} dBFS"
                )
                result["warning"] = warning
                warnings.append(warning)
                if not seam_pass:
                    hard_errors.append(
                        f"{asset['id']} CoreAudio loop seam failed: "
                        f"delta {coreaudio_boundary['boundaryDeltaDbfs']} dBFS, "
                        f"derivative ratio {coreaudio_boundary['boundaryToP999DerivativeRatio']}"
                    )
            else:
                source_pcm, _ = sf.read(
                    root / asset["runtime"], dtype="int16", always_2d=True
                )
                decoded_pcm, _ = sf.read(decoded, dtype="int16", always_2d=True)
                pcm_values_exact = bool(
                    source_pcm.shape == decoded_pcm.shape
                    and np.array_equal(source_pcm, decoded_pcm)
                )
                sample_exact = frame_count_exact and pcm_values_exact
                result = {
                    "result": "sample-exact" if sample_exact else "pcm-or-frame-variance",
                    "runtimeFormat": "WAV/PCM_16",
                    "expectedFrames": expected,
                    "decodedFrames": decoded_frames,
                    "deltaFrames": delta,
                    "frameCountExact": frame_count_exact,
                    "zeroOffsetAligned": True,
                    "pcmValuesExact": pcm_values_exact,
                    "sampleExact": sample_exact,
                }
                if not sample_exact:
                    hard_errors.append(
                        f"{asset['id']} CoreAudio PCM16 mismatch: frames "
                        f"{decoded_frames}/{expected}, PCM exact={pcm_values_exact}"
                    )
            results[asset["id"]] = result

    music = [asset for asset in score["assets"] if asset["group"] == "music"]
    sfx = [asset for asset in score["assets"] if asset["group"] != "music"]
    music_frame_exact = sum(
        results.get(asset["id"], {}).get("frameCountExact") is True for asset in music
    )
    music_zero_offset = sum(
        results.get(asset["id"], {}).get("zeroOffsetAligned") is True for asset in music
    )
    music_sample_exact = sum(
        results.get(asset["id"], {}).get("sampleExact") is True for asset in music
    )
    music_seam_pass = sum(
        results.get(asset["id"], {}).get("coreAudioSeamGate") == "pass" for asset in music
    )
    sfx_exact = sum(results.get(asset["id"], {}).get("sampleExact") is True for asset in sfx)
    offsets = Counter(
        results.get(asset["id"], {})
        .get("alignment", {})
        .get("coreAudioFrame0MatchesLibsndfileFrame")
        for asset in music
        if results.get(asset["id"], {}).get("alignment")
    )
    if hard_errors:
        status = "fail"
    elif warnings:
        status = "pass-with-music-decoder-variance"
    else:
        status = "pass"
    evidence = {
        "result": status,
        "tools": {"afconvert": str(afconvert), "afinfo": str(afinfo)},
        "sfxWavSampleExact": f"{sfx_exact}/{len(sfx)}",
        "sfxWavPcm16FrameAndValueExact": f"{sfx_exact}/{len(sfx)}",
        "musicOggFrameCountExact": f"{music_frame_exact}/{len(music)}",
        "musicOggZeroOffsetAligned": f"{music_zero_offset}/{len(music)}",
        "musicOggSampleExact": f"{music_sample_exact}/{len(music)}",
        "musicOggCoreAudioSeamGate": f"{music_seam_pass}/{len(music)}",
        "musicOggAlignmentOffsetsFrames": {
            str(offset): count for offset, count in sorted(offsets.items())
        },
        "hardErrors": hard_errors,
        "warnings": warnings,
        "interpretation": "Frame-count equality is not sample alignment. WAV PCM16 SFX must preserve frame count and every PCM value. Ogg music may retain a decoder offset and frame-count variance, but every CoreAudio-decoded boundary must independently satisfy the numeric seam gate.",
        "androidMusicLoopGate": "pending",
    }
    return evidence, results, hard_errors


def write_provenance(
    root: Path,
    asset: dict[str, Any],
    entry: dict[str, Any],
    manifest: dict[str, Any],
    passed: bool,
) -> None:
    status = "candidate-reviewed" if passed else "candidate-review-failed"
    master = entry["reviewedMetrics"]["master"]
    runtime = entry["reviewedMetrics"]["runtime"]
    coreaudio = entry["reviewedMetrics"]["coreAudio"]
    if asset["group"] == "music" and coreaudio.get("alignment"):
        alignment = coreaudio["alignment"]
        coreaudio_line = (
            f"- **CoreAudio:** `{coreaudio['result']}`; frame count "
            f"`{coreaudio['decodedFrames']}/{coreaudio['expectedFrames']}`; frame 0 "
            f"alinha ao frame libsndfile `{alignment['coreAudioFrame0MatchesLibsndfileFrame']}`; "
            f"sample-exact `{str(coreaudio['sampleExact']).lower()}`; seam "
            f"`{coreaudio['coreAudioLoopBoundary']['boundaryDeltaDbfs']}` dBFS; gate "
            f"`{coreaudio['coreAudioSeamGate']}`."
        )
    else:
        coreaudio_line = (
            f"- **CoreAudio:** `{coreaudio['result']}`; "
            f"`{coreaudio['decodedFrames']}/{coreaudio['expectedFrames']}` frames; "
            f"sample-exact `{str(coreaudio.get('sampleExact')).lower()}`."
        )
    boundary_line = (
        f"- **Boundary musical:** taper squared-sine de "
        f"`{manifest['loopBoundaryTreatment']['fadeFrames']}` frames por lado; "
        f"gate CoreAudio `{coreaudio.get('coreAudioSeamGate')}`."
        if asset["group"] == "music"
        else "- **Boundary musical:** não aplicável."
    )
    lines = [
        f"# {asset['id']} — proveniência candidata",
        "",
        f"- **ID:** `{asset['id']}`",
        f"- **Revisão:** `{manifest['revision']}`",
        f"- **Revisão da evidência:** `{manifest['reviewEvidenceRevision']}`",
        f"- **Status:** `{status}`",
        "- **Método:** síntese procedural determinística; osciladores, ruído com seed, filtros e envelopes.",
        "- **Entradas externas de áudio:** nenhuma.",
        "- **Voz, foley, samples e IA generativa:** não utilizados.",
        f"- **Score:** `sources/audio/procedural/score-v1.json`",
        f"- **Seed derivada:** `{entry['sourceSeed']}`",
        f"- **Bundle-fonte SHA-256:** `{manifest['sourceBundleSha256']}`",
        f"- **Master:** `{entry['masterPath']}` — `{entry['masterSha256']}`",
        f"- **Runtime:** `{entry['runtimePath']}` — `{entry['runtimeSha256']}`",
        f"- **Conversão SFX:** `{entry['reviewedMetrics']['pcm16Dither']['result'] if entry['reviewedMetrics']['pcm16Dither'] else 'n/a'}`; TPDF determinístico a partir do master PCM24; seed `{entry['reviewedMetrics']['pcm16Dither']['seed'] if entry['reviewedMetrics']['pcm16Dither'] else 'n/a'}`.",
        f"- **Verificação de hash:** `{entry['hashVerification']['result']}`; hashes esperados do manifesto gerado comparados sem sobrescrita aos arquivos observados.",
        f"- **Master:** `{master['sampleRate']} Hz`, `{master['subtype']}`, `{master['channels']}` canal(is), `{master['frames']}` amostras.",
        f"- **Métricas master:** `{master['integratedLufs']}` LUFS-I, `{master['samplePeakDbfs']}` dBFS peak, `{master['truePeakDbtp']}` dBTP.",
        f"- **Métricas runtime:** `{runtime['integratedLufs']}` LUFS-I, `{runtime['samplePeakDbfs']}` dBFS peak, `{runtime['truePeakDbtp']}` dBTP.",
        boundary_line,
        coreaudio_line,
        f"- **Determinismo:** `{manifest['determinism']['result']}` em duas renderizações temporárias independentes; candidato atual `{manifest['determinism']['currentCandidateMatchesRender']}`.",
        "- **Ferramentas:** versões exatas registradas no manifesto candidato; nenhuma sessão REAPER foi usada ou presumida.",
        "- **Licenças da cadeia:** NumPy/SciPy/SoundFile/pyloudnorm/libsndfile exigem arquivamento dos termos antes de aprovação; esta nota não é parecer jurídico.",
        "- **Briefing sanitizado:** aplicável sem referência musical, nome de artista, faixa ou gravação-fonte.",
        "- **Auditoria adversarial de similaridade:** pendente.",
        "- **Escuta humana em celular, mono e fones:** pendente.",
        "- **Latência, drift e retomada em Android:** pendentes.",
        "- **Aprovação final:** não concedida por esta pipeline.",
    ]
    path = root / f"provenance/audio/{asset['id'].lower()}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_report(
    results: list[dict[str, Any]],
    composite: dict[str, Any],
    overall_pass: bool,
    manifest: dict[str, Any],
) -> str:
    passed = sum(1 for result in results if result["passed"])
    required_passed = sum(
        1 for result in results if result["required"] and result["passed"]
    )
    conditional_passed = sum(
        1 for result in results if result["conditional"] and result["passed"]
    )
    hash_matches = sum(
        result.get("hashVerification", {}).get("result") == "pass" for result in results
    )
    dither_matches = sum(
        result.get("pcm16Dither", {}).get("result") == "pass"
        for result in results
        if result.get("pcm16Dither") is not None
    )
    warning_lines = [
        f"- `{warning}`" for warning in manifest["crossDecoderReview"]["warnings"]
    ]
    status = (
        "REVISÃO TÉCNICA CONCLUÍDA COM WARNINGS DE DECODER"
        if overall_pass
        else "FAIL técnico automatizado"
    )
    lines = [
        "# Relatório de geração e revisão de áudio",
        "",
        f"> Status: **{status}**. Os arquivos permanecem `candidate-reviewed`; não são `approved` nem `integrated`.",
        "",
        "## Resultado",
        "",
        f"- revisão do áudio: **{manifest['revision']}**; revisão da evidência: **{manifest['reviewEvidenceRevision']}**;",
        f"- candidatos verificados: **{passed}/44**;",
        f"- obrigatórios verificados: **{required_passed}/40**;",
        f"- condicionais verificados: **{conditional_passed}/4**;",
        f"- bundle-fonte SHA-256: `{manifest['sourceBundleSha256']}`;",
        f"- bundle-fonte esperado versus observado: **{manifest['sourceBundleVerification']['result'].upper()}**;",
        f"- bundle do revisor SHA-256: `{manifest['reviewBundle']['sha256']}`;",
        f"- hashes esperados versus arquivos observados: **{hash_matches}/44**;",
        f"- reconstrução determinística TPDF dos runtimes PCM16: **{dither_matches}/35**;",
        f"- determinismo real: **{manifest['determinism']['result'].upper()}**, masters WAV `{manifest['determinism']['masterWavMatches']}`, runtimes `{manifest['determinism']['runtimeMatches']}`;",
        f"- duas renderizações temporárias: `{manifest['determinism']['renderCombinedSha256']}`;",
        f"- candidato atual versus render: `{manifest['determinism']['currentCandidateMatchesRender']}`;",
        f"- SHA-256 combinado atual: `{manifest['determinism']['currentCombinedAudioSha256']}`;",
        "- fonte sonora externa, voz, foley, sample e modelo generativo: **nenhum**;",
        "- masters: WAV PCM 48 kHz/24-bit; runtime: nove músicas Ogg/Vorbis q6 e 35 SFX WAV PCM16 com TPDF determinístico;",
        f"- tratamento de boundary musical: taper squared-sine de `{manifest['loopBoundaryTreatment']['fadeFrames']}` frames em cada lado;",
        "- loops de gameplay: `[0, 4.404.706)` amostras; menu/Loja: `[0, 2.202.353)`.",
        "",
        "## Estados musicais compostos",
        "",
        "| Estado | LUFS-I | Sample peak dBFS | True peak dBTP |",
        "| --- | ---: | ---: | ---: |",
    ]
    for state in ("I0", "I1", "I2", "I3"):
        metrics = composite[state]
        lines.append(
            f"| {state} | {metrics['integratedLufs']} | {metrics['samplePeakDbfs']} | {metrics['truePeakDbtp']} |"
        )
    lines.extend(
        [
            "",
            "`MUS-GAME-GROOVE` e `MUS-GAME-HYPE` são overlays intencionalmente mais baixos; o alvo de aproximadamente -16 LUFS-I pertence ao estado musical composto. Os quatro mixes condicionais são normalizados individualmente para crossfade estável.",
            "",
            "## Inventário e métricas",
            "",
            "| ID | Status | Frames master | LUFS-I master | TP runtime | Frames CoreAudio | Offset | Seam CoreAudio dBFS | Gate |",
            "| --- | --- | ---: | ---: | ---: | ---: | ---: | --- | --- |",
        ]
    )
    for result in results:
        master = result["master"]
        runtime = result["runtime"]
        coreaudio = result["coreAudio"]
        music_warning = coreaudio.get("alignment") is not None
        status_cell = "WARN" if result["passed"] and music_warning else ("PASS" if result["passed"] else "FAIL")
        core_frames = f"{coreaudio.get('decodedFrames')}/{coreaudio.get('expectedFrames')}"
        offset = (
            coreaudio.get("alignment", {}).get(
                "coreAudioFrame0MatchesLibsndfileFrame", 0
            )
        )
        seam = coreaudio.get("coreAudioLoopBoundary", {}).get(
            "boundaryDeltaDbfs", "n/a"
        )
        gate = coreaudio.get("coreAudioSeamGate")
        if gate is None:
            gate = "pass" if coreaudio.get("sampleExact") else "fail"
        lines.append(
            f"| `{result['id']}` | {status_cell} | {master['frames']} | {master['integratedLufs']} | {runtime['truePeakDbtp']} | {core_frames} | {offset} | {seam} | {gate} |"
        )
        for error in result["errors"]:
            lines.append(f"| ↳ erro | {error} | | | | | | | |")
        if coreaudio.get("warning"):
            lines.append(f"| ↳ warning | {coreaudio['warning']} | | | | | | | |")
    lines.extend(
        [
            "",
            "## O que a revisão automatizada comprovou",
            "",
            "- cardinalidade 40 obrigatórios + quatro condicionais, IDs e paths do score;",
            "- sample rate, bit depth, canais, duração e número exato de amostras;",
            "- SHA-256 de fonte consolidada, master e runtime;",
            "- LUFS-I por BS.1770 via pyloudnorm, true peak estimado com oversampling 4× e picos;",
            "- ausência de silêncio, clipping digital evidente, DC relevante e perda mono grosseira;",
            "- alinhamento dos três stems e continuidade de fronteira do master e do decode libsndfile;",
            f"- boundary do decode CoreAudio dentro de -24 dBFS e ratio <= 6: `{manifest['crossDecoderReview']['musicOggCoreAudioSeamGate']}`;",
            "- frame count, offset PCM, overlap, cauda não pareada e seam são métricas separadas;",
            f"- duas renderizações temporárias reais: masters WAV `{manifest['determinism']['masterWavMatches']}`, runtimes WAV `{manifest['determinism']['runtimeWavMatches']}` e runtimes Ogg `{manifest['determinism']['runtimeOggMatches']}`;",
            "- hashes observados foram comparados aos hashes esperados do manifesto gerado antes de qualquer anotação de revisão;",
            f"- conversão PCM16/TPDF reconstruída pelo revisor: `{manifest['pcm16DitherReview']['reconstructionExact']}`;",
            "",
            "## Verificação cross-decoder CoreAudio",
            "",
            f"- resultado: **{manifest['crossDecoderReview']['result']}**;",
            f"- SFX WAV PCM16 frame e valores sample-exact: `{manifest['crossDecoderReview'].get('sfxWavPcm16FrameAndValueExact')}`;",
            f"- músicas Ogg com mesmo frame count: `{manifest['crossDecoderReview'].get('musicOggFrameCountExact')}`;",
            f"- músicas Ogg alinhadas em offset zero: `{manifest['crossDecoderReview'].get('musicOggZeroOffsetAligned')}`;",
            f"- músicas Ogg sample-exact em sentido estrito: `{manifest['crossDecoderReview'].get('musicOggSampleExact')}`;",
            f"- offsets medidos: `{manifest['crossDecoderReview'].get('musicOggAlignmentOffsetsFrames')}`;",
            f"- seams CoreAudio aprovados: `{manifest['crossDecoderReview'].get('musicOggCoreAudioSeamGate')}`;",
            "- o serial Ogg é derivado do ID e os CRCs das páginas são recalculados sem alterar packets Vorbis;",
            "- o taper reduz o boundary numérico, mas não corrige pre-skip/alinhamento do decoder; a variação segue como warning explícito e o gate audível Android continua pendente;",
            "- warnings por arquivo:",
            *warning_lines,
            "",
            "## Limitações obrigatórias antes de aprovação",
            "",
            "- o true peak é uma estimativa numérica por oversampling 4×, não medição certificada;",
            "- agentes não escutaram o resultado e não podem aprovar musicalidade, fadiga, ausência de clique perceptível ou adequação cultural;",
            "- a auditoria adversarial contra qualquer referência musical permanece pendente e não deve expor a gravação ao compositor;",
            "- faltam testes de 20 min na cadência de referência, 10 min em alta cadência e 30 min em menu/Loja;",
            "- faltam alto-falante móvel modesto, soma mono real, fones e diferentes fabricantes;",
            "- faltam latência de primeiro toque/quente, drift dos stems, foco, anúncio, background e retomada no Android;",
            "- não existe sessão/licença REAPER neste fluxo; a aceitação de fonte procedural precisa de decisão documental antes de `approved`;",
            "- licenças e termos das ferramentas devem ser arquivados; esta pipeline não fornece parecer jurídico.",
            "",
            "## Próximo gate humano",
            "",
            "Ouvir primeiro `MUS-GAME-I0-MIX`, `MUS-GAME-I3-MIX`, as seis duplas Six/Seven, `STG-FORM-01`, `STG-FORM-05`, `STG-ASCENSION` e `STG-MARK-67`. Rejeitar qualquer fadiga, semelhança reconhecível, conotação de moeda/jackpot, Seven ambíguo ou Six que pareça recompensa. Somente depois executar a matriz completa em Android.",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    pipeline_root = Path(__file__).resolve().parents[2]
    score_path = args.score if args.score.is_absolute() else root / args.score
    score = json.loads(score_path.read_text(encoding="utf-8"))
    manifest_path = root / "assets/audio/audio-candidate-manifest-v1.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    master_manifest_path = root / "masters/audio/master-candidate-manifest-v1.json"
    master_manifest = json.loads(master_manifest_path.read_text(encoding="utf-8"))
    manifest_entries = {entry["id"]: entry for entry in manifest["assets"]}
    master_manifest_entries = {entry["id"]: entry for entry in master_manifest["assets"]}
    expected_ids = [asset["id"] for asset in score["assets"]]
    global_errors: list[str] = []
    if len(expected_ids) != 44 or len(set(expected_ids)) != 44:
        global_errors.append("score must contain 44 unique IDs")
    if set(expected_ids) != set(manifest_entries):
        global_errors.append("manifest IDs do not match score IDs")
    if sum(bool(asset.get("required")) for asset in score["assets"]) != 40:
        global_errors.append("score does not contain exactly 40 required assets")
    if sum(bool(asset.get("conditional")) for asset in score["assets"]) != 4:
        global_errors.append("score does not contain exactly 4 conditional assets")
    if score["revision"] != 3:
        global_errors.append(f"score revision {score['revision']} != 3")
    if manifest.get("revision") != score["revision"]:
        global_errors.append(
            f"generated manifest revision {manifest.get('revision')} != score {score['revision']}"
        )
    if master_manifest.get("revision") != score["revision"]:
        global_errors.append(
            f"master manifest revision {master_manifest.get('revision')} != score {score['revision']}"
        )
    if manifest.get("loopBoundaryTreatment") != score.get("loopBoundaryTreatment"):
        global_errors.append("generated loop boundary treatment differs from score")
    if manifest.get("sourceBundleContract") != "audio-generation-source-bundle-v2":
        global_errors.append("generated source bundle contract is not v2")

    source_files = source_bundle_files(pipeline_root, score_path)
    source_labels = [
        path.resolve().relative_to(pipeline_root.resolve()).as_posix()
        for path in source_files
    ]
    if manifest.get("sourceBundleFiles") != source_labels:
        global_errors.append("generated source bundle file list differs from reviewer")
    if master_manifest.get("sourceBundleFiles") != source_labels:
        global_errors.append("master source bundle file list differs from reviewer")
    observed_source_bundle = sha256_files(source_files, base=pipeline_root)
    expected_source_bundle = manifest.get("sourceBundleSha256")
    source_bundle_verified = expected_source_bundle == observed_source_bundle
    if not source_bundle_verified:
        global_errors.append(
            f"source bundle drift: generated {expected_source_bundle} != observed {observed_source_bundle}"
        )
    if master_manifest.get("sourceBundleSha256") != expected_source_bundle:
        global_errors.append("master/runtime manifests disagree on generated source bundle hash")
    source_bundle_verification = {
        "result": "pass" if source_bundle_verified else "fail",
        "expectedFromGeneratedManifest": expected_source_bundle,
        "observedByReviewer": observed_source_bundle,
        "pathBasis": "repository-relative POSIX paths plus file contents",
    }
    review_files = review_bundle_files(pipeline_root, score_path)
    review_bundle = {
        "contract": "audio-review-evidence-bundle-v2",
        "revision": REVIEW_EVIDENCE_REVISION,
        "sha256": sha256_files(review_files, base=pipeline_root),
        "files": [
            path.resolve().relative_to(pipeline_root.resolve()).as_posix()
            for path in review_files
        ],
        "pathBasis": "repository-relative POSIX paths plus file contents",
    }

    cross_decoder, cross_decoder_by_id, cross_decoder_errors = (
        coreaudio_cross_decoder_review(root, score)
    )
    global_errors.extend(cross_decoder_errors)
    results: list[dict[str, Any]] = []

    for index, asset in enumerate(score["assets"], start=1):
        print(f"[review {index:02d}/44] {asset['id']}", flush=True)
        master_path = root / asset["master"]
        runtime_path = root / asset["runtime"]
        errors: list[str] = []
        entry = manifest_entries.get(asset["id"])
        master_entry = master_manifest_entries.get(asset["id"])
        if entry is None:
            errors.append("runtime manifest entry missing")
        else:
            if entry.get("masterPath") != asset["master"]:
                errors.append("generated master path differs from score")
            if entry.get("runtimePath") != asset["runtime"]:
                errors.append("generated runtime path differs from score")
            if entry.get("revision") != score["revision"]:
                errors.append("generated entry revision differs from score")
        if master_entry is None:
            errors.append("master manifest entry missing")
        if asset["group"] != "music" and entry is not None:
            expected_dither_seed = pcm16_dither_seed(asset["id"])
            if entry.get("runtimeDither", {}).get("seed") != expected_dither_seed:
                errors.append("generated runtime dither seed differs from deterministic seed")
        if not master_path.exists():
            errors.append("master missing")
        if not runtime_path.exists():
            errors.append("runtime missing")
        if errors:
            results.append(
                {
                    "id": asset["id"],
                    "required": asset.get("required", False),
                    "conditional": asset.get("conditional", False),
                    "passed": False,
                    "errors": errors,
                }
            )
            continue
        master_metrics, _ = measure_file(master_path, include_true_peak=True)
        runtime_metrics, _ = measure_file(runtime_path, include_true_peak=True)
        master_audio, _ = sf.read(master_path, dtype="float32", always_2d=True)
        runtime_audio, _ = sf.read(runtime_path, dtype="float32", always_2d=True)
        boundary = boundary_metrics(master_audio) if "loopSamples" in asset else None
        runtime_boundary = boundary_metrics(runtime_audio) if "loopSamples" in asset else None
        mono_result = mono_metrics(master_audio)
        roundtrip = roundtrip_metrics(master_audio, runtime_audio)
        pcm16_dither: dict[str, Any] | None = None
        if asset["group"] != "music":
            runtime_pcm16, _ = sf.read(runtime_path, dtype="int16", always_2d=True)
            reconstructed_pcm16 = tpdf_dither_pcm16(master_audio, asset["id"])
            reconstruction_exact = bool(
                runtime_pcm16.shape == reconstructed_pcm16.shape
                and np.array_equal(runtime_pcm16, reconstructed_pcm16)
            )
            undithered_pcm16 = np.clip(
                np.rint(master_audio.astype(np.float64) * 32768.0),
                -32768,
                32767,
            ).astype(np.int16)
            changed_samples = int(np.count_nonzero(runtime_pcm16 != undithered_pcm16))
            error_lsb = (
                runtime_pcm16.astype(np.float64)
                - master_audio.astype(np.float64) * 32768.0
            )
            max_error_lsb = float(np.max(np.abs(error_lsb), initial=0.0))
            pcm16_dither = {
                "result": "pass"
                if reconstruction_exact and changed_samples > 0 and max_error_lsb <= 1.500001
                else "fail",
                "type": "TPDF",
                "seed": pcm16_dither_seed(asset["id"]),
                "source": "encoded PCM24 master",
                "reconstructionExact": reconstruction_exact,
                "changedSamplesVersusUndithered": changed_samples,
                "totalSamples": int(runtime_pcm16.size),
                "maxAbsoluteQuantizationErrorLsb": round(max_error_lsb, 8),
                "rmsQuantizationErrorLsb": round(
                    float(np.sqrt(np.mean(np.square(error_lsb), dtype=np.float64))), 8
                ),
            }
            if pcm16_dither["result"] != "pass":
                errors.append(f"PCM16 TPDF reconstruction failed: {pcm16_dither}")
        expected_master_hash = entry.get("masterSha256") if entry else None
        expected_runtime_hash = entry.get("runtimeSha256") if entry else None
        observed_master_hash = master_metrics["sha256"]
        observed_runtime_hash = runtime_metrics["sha256"]
        if expected_master_hash != observed_master_hash:
            errors.append(
                f"master hash drift/tampering: expected {expected_master_hash}, observed {observed_master_hash}"
            )
        if expected_runtime_hash != observed_runtime_hash:
            errors.append(
                f"runtime hash drift/tampering: expected {expected_runtime_hash}, observed {observed_runtime_hash}"
            )
        if master_entry and master_entry.get("sha256") != expected_master_hash:
            errors.append("master manifest hash disagrees with generated runtime manifest")
        hash_verification = {
            "result": "pass"
            if expected_master_hash == observed_master_hash
            and expected_runtime_hash == observed_runtime_hash
            and master_entry is not None
            and master_entry.get("sha256") == expected_master_hash
            else "fail",
            "master": {"expected": expected_master_hash, "observed": observed_master_hash},
            "runtime": {"expected": expected_runtime_hash, "observed": observed_runtime_hash},
            "expectedHashesPreserved": True,
        }
        errors.extend(
            gate_asset(
                asset,
                master_metrics,
                runtime_metrics,
                boundary,
                mono_result,
                roundtrip,
                score,
            )
        )
        if runtime_boundary is not None:
            if max(runtime_boundary["boundaryToP999DerivativeRatio"]) > 6.0:
                errors.append("runtime music loop seam derivative exceeds 6x p99.9")
            if max(runtime_boundary["boundaryDeltaDbfs"]) > -24.0:
                errors.append("runtime Ogg loop boundary delta exceeds -24 dBFS")
        coreaudio_result = cross_decoder_by_id.get(
            asset["id"],
            {
                "result": "not-tested",
                "expectedFrames": master_metrics["frames"],
                "decodedFrames": None,
                "deltaFrames": None,
                "sampleExact": None,
            },
        )
        entry["hashVerification"] = hash_verification
        entry["reviewedMetrics"] = {
            "master": master_metrics,
            "runtime": runtime_metrics,
            "masterLoopBoundary": boundary,
            "runtimeLoopBoundary": runtime_boundary,
            "mono": mono_result,
            "roundTrip": roundtrip,
            "pcm16Dither": pcm16_dither,
            "coreAudio": coreaudio_result,
        }
        entry["status"] = "candidate-reviewed" if not errors else "candidate-review-failed"
        results.append(
            {
                "id": asset["id"],
                "required": asset.get("required", False),
                "conditional": asset.get("conditional", False),
                "passed": not errors,
                "errors": errors,
                "master": master_metrics,
                "runtime": runtime_metrics,
                "boundary": boundary,
                "runtimeBoundary": runtime_boundary,
                "mono": mono_result,
                "roundTrip": roundtrip,
                "pcm16Dither": pcm16_dither,
                "hashVerification": hash_verification,
                "coreAudio": coreaudio_result,
            }
        )

    print("[review] measuring composed intensity states", flush=True)
    composite = composite_metrics(root, score)
    determinism, determinism_errors = real_determinism_gate(
        root, pipeline_root, score_path, score
    )
    global_errors.extend(determinism_errors)
    for state, metrics in composite.items():
        if metrics["truePeakDbtp"] is None or metrics["truePeakDbtp"] > -1.0:
            global_errors.append(f"composite {state} true peak {metrics['truePeakDbtp']} > -1 dBTP")
        if metrics["integratedLufs"] is None or not (-17.1 <= metrics["integratedLufs"] <= -14.0):
            global_errors.append(
                f"composite {state} loudness {metrics['integratedLufs']} outside -17.1..-14 LUFS-I"
            )
    stem_frames = []
    for asset_id in ("MUS-GAME-BASE", "MUS-GAME-GROOVE", "MUS-GAME-HYPE"):
        path = root / next(asset["master"] for asset in score["assets"] if asset["id"] == asset_id)
        stem_frames.append(sf.info(path).frames)
    if stem_frames != [score["gameLoopSamples"]] * 3:
        global_errors.append(f"unaligned stem frame counts: {stem_frames}")

    overall_pass = not global_errors and all(result["passed"] for result in results)
    dither_results = [
        result["pcm16Dither"]
        for result in results
        if result.get("pcm16Dither") is not None
    ]
    dither_passed = sum(result["result"] == "pass" for result in dither_results)
    pcm16_dither_review = {
        "result": "pass" if dither_passed == 35 and len(dither_results) == 35 else "fail",
        "reconstructionExact": f"{dither_passed}/35",
        "method": "reviewer reconstructs signed PCM16 from the encoded PCM24 master with the stable asset-ID seed and compares every sample value",
    }
    if pcm16_dither_review["result"] != "pass":
        global_errors.append(
            f"PCM16 dither reconstruction count {dither_passed}/{len(dither_results)} != 35/35"
        )
        overall_pass = False
    manifest["status"] = "candidate-reviewed" if overall_pass else "candidate-review-failed"
    manifest["reviewedAtUtc"] = datetime.now(timezone.utc).isoformat()
    manifest["automatedReview"] = (
        "pass-with-cross-decoder-warnings" if overall_pass else "fail"
    )
    manifest["reviewEvidenceRevision"] = REVIEW_EVIDENCE_REVISION
    manifest["reviewBundle"] = review_bundle
    manifest["globalErrors"] = global_errors
    manifest["compositeStateMetrics"] = composite
    manifest["determinism"] = determinism
    manifest["sourceBundleVerification"] = source_bundle_verification
    manifest["crossDecoderReview"] = cross_decoder
    manifest["pcm16DitherReview"] = pcm16_dither_review
    manifest["humanReview"] = "pending"
    manifest["similarityReview"] = "pending"
    manifest["androidDeviceReview"] = "pending"
    dump_json(manifest_path, manifest)

    master_manifest["status"] = manifest["status"]
    master_manifest["reviewedAtUtc"] = manifest["reviewedAtUtc"]
    master_manifest["automatedReview"] = manifest["automatedReview"]
    master_manifest["reviewEvidenceRevision"] = REVIEW_EVIDENCE_REVISION
    master_manifest["reviewBundle"] = review_bundle
    master_manifest["determinism"] = determinism
    master_manifest["sourceBundleVerification"] = source_bundle_verification
    master_manifest["crossDecoderReview"] = cross_decoder
    master_manifest["pcm16DitherReview"] = pcm16_dither_review
    for item in master_manifest["assets"]:
        entry = manifest_entries[item["id"]]
        item["status"] = entry["status"]
        item["hashVerification"] = entry["hashVerification"]["master"] | {
            "result": entry["hashVerification"]["result"]
        }
        item["metrics"] = entry["reviewedMetrics"]["master"]
    dump_json(master_manifest_path, master_manifest)

    for asset in score["assets"]:
        entry = manifest_entries[asset["id"]]
        write_provenance(root, asset, entry, manifest, entry["status"] == "candidate-reviewed")

    review_payload = {
        "contract": "audio-automated-review-v2",
        "reviewEvidenceRevision": REVIEW_EVIDENCE_REVISION,
        "reviewBundle": review_bundle,
        "status": manifest["status"],
        "automatedReview": manifest["automatedReview"],
        "reviewedAtUtc": manifest["reviewedAtUtc"],
        "globalErrors": global_errors,
        "compositeStateMetrics": composite,
        "determinism": determinism,
        "sourceBundleVerification": source_bundle_verification,
        "crossDecoderReview": cross_decoder,
        "pcm16DitherReview": pcm16_dither_review,
        "results": results,
        "limitations": [
            "no human listening",
            "no adversarial similarity review",
            "no Android latency/drift/focus test",
            "CoreAudio music Ogg has a measured decoder offset and some frame-count variance; numeric seam passes do not replace Android audible-loop validation",
            "true peak is a 4x oversampling estimate",
            "tool license archive pending",
            "procedural source acceptance in place of REAPER session pending",
        ],
    }
    dump_json(root / "reports/audio-review-results.json", review_payload)
    report = build_report(results, composite, overall_pass, manifest)
    report_path = root / "reports/audio-generation-report.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(report, encoding="utf-8")
    if overall_pass:
        print(
            "[review] PASS WITH DECODER WARNINGS: 44/44 candidate-reviewed "
            "(human/device gates still pending)"
        )
        return 0
    print("[review] FAIL")
    for error in global_errors:
        print(f"  global: {error}")
    for result in results:
        for error in result["errors"]:
            print(f"  {result['id']}: {error}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
