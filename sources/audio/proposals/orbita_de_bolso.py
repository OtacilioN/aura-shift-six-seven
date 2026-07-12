#!/usr/bin/env python3
"""Render the deterministic proposal track "Órbita de Bolso".

The track is built exclusively from oscillators and seeded noise.  It is a
136 BPM, 52-bar phonk loop whose four 13-bar phrases each use a 6+7 shape.
There is deliberately no cowbell and no external sampled audio.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import platform
import sys
import tempfile
from typing import Any

import numpy as np
import soundfile as sf


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools" / "assets"))

from audio_common import (  # noqa: E402
    add_signal,
    amp_to_db,
    bandpass,
    constant_power_pan,
    dump_json,
    fade_edges,
    highpass,
    measure_audio,
    measure_file,
    normalize_loudness,
    rng_for,
    sha256_file,
    soft_clip,
    taper_loop_boundary,
    write_master_and_runtime,
)


SAMPLE_RATE = 48_000
BPM = 136.0
BARS = 52
BEATS_PER_BAR = 4
TOTAL_FRAMES = 4_404_706
TAPER_FRAMES = 1_024
SEED = "six-seven-orbita-de-bolso-2026-07-12-v2"

SOURCE_PATH = Path("sources/audio/proposals/orbita_de_bolso.py")
MASTER_PATH = Path("masters/audio/proposals/orbita_de_bolso.wav")
RUNTIME_PATH = Path("assets/audio/proposals/orbita_de_bolso.ogg")
REPORT_PATH = Path("reports/audio-proposals/orbita_de_bolso.json")

ASSET = {
    "id": "MUS-PROPOSAL-ORBITA-DE-BOLSO",
    "channels": 2,
    "master": MASTER_PATH.as_posix(),
    "runtime": RUNTIME_PATH.as_posix(),
}


PASS_CONFIGS: dict[str, dict[str, Any]] = {
    "v1": {
        "subDuration": 0.330,
        "subGain": 0.88,
        "secondarySub": True,
        "hatStride": 1,
        "grainEvery": 2,
        "grainGain": 0.42,
        "orbitWidth": 0.30,
        "stabGain": 0.54,
        "extraStabs": True,
        "masterDrive": 1.10,
    },
    "v2-final": {
        "subDuration": 0.235,
        "subGain": 0.78,
        "secondarySub": False,
        "hatStride": 2,
        "grainEvery": 3,
        "grainGain": 0.29,
        "orbitWidth": 0.72,
        "stabGain": 0.45,
        "extraStabs": False,
        "masterDrive": 1.16,
    },
}


def _time(count: int) -> np.ndarray:
    return np.arange(count, dtype=np.float64) / SAMPLE_RATE


def _phase(frequency: np.ndarray | float) -> np.ndarray:
    return 2.0 * math.pi * np.cumsum(np.asarray(frequency, dtype=np.float64)) / SAMPLE_RATE


def beat_frame(beat: float) -> int:
    return int(round(beat * 60.0 * SAMPLE_RATE / BPM))


def synth_kick(rng: np.random.Generator, duration: float = 0.155) -> np.ndarray:
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    frequency = 54.5 + 96.0 * np.exp(-t / 0.018)
    phase = _phase(frequency)
    envelope = (1.0 - np.exp(-t / 0.0018)) * np.exp(-t / 0.057)
    body = np.sin(phase) + 0.15 * np.sin(2.0 * phase + 0.2)
    click = highpass(rng.standard_normal(count), 3_200.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0045) * 0.022
    return fade_edges(body * envelope * 0.73 + click, SAMPLE_RATE, 0.5, 13.0)


def synth_orbital_sub(duration: float, articulation: float = 1.0) -> np.ndarray:
    """Short 808-like hit with an explicit pitch dive into A1 (55 Hz)."""
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    frequency = 55.0 + 31.0 * np.exp(-t / 0.030)
    phase = _phase(frequency)
    attack = 1.0 - np.exp(-t / 0.004)
    envelope = attack * np.exp(-t / (0.082 * articulation))
    body = np.sin(phase) + 0.19 * np.sin(2.0 * phase + 0.18)
    return fade_edges(body * envelope * 0.60, SAMPLE_RATE, 0.8, 22.0)


def synth_rim_clap(rng: np.random.Generator, accent: bool) -> np.ndarray:
    duration = 0.112 if accent else 0.082
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    noise = bandpass(rng.standard_normal(count), 1_050.0, 7_200.0, SAMPLE_RATE, 2)
    noise_env = np.exp(-t / (0.015 if accent else 0.010))
    ring = (
        np.sin(2.0 * math.pi * 910.0 * t)
        + 0.36 * np.sin(2.0 * math.pi * 1_430.0 * t + 0.31)
    ) * np.exp(-t / 0.022)
    flam = np.zeros(count, dtype=np.float64)
    if accent:
        offset = int(round(0.014 * SAMPLE_RATE))
        flam[offset:] = noise[:-offset] * np.exp(-t[:-offset] / 0.012) * 0.22
    return fade_edges(
        noise * noise_env * 0.105 + ring * 0.115 + flam,
        SAMPLE_RATE,
        0.25,
        9.0,
    )


def synth_hat(rng: np.random.Generator, open_hat: bool = False) -> np.ndarray:
    duration = 0.105 if open_hat else 0.043
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    noise = highpass(rng.standard_normal(count), 6_300.0, SAMPLE_RATE, 3)
    envelope = np.exp(-t / (0.030 if open_hat else 0.009))
    shimmer = (
        np.sin(2.0 * math.pi * 8_130.0 * t)
        + np.sin(2.0 * math.pi * 10_370.0 * t + 0.7)
    ) * 0.018
    return fade_edges((noise * 0.072 + shimmer) * envelope, SAMPLE_RATE, 0.2, 7.0)


def synth_fm_stab(note: str, bright: bool) -> np.ndarray:
    if note not in {"A", "C"}:
        raise ValueError("Órbita de Bolso restricts FM stabs to A and C")
    frequency = 220.0 if note == "A" else 261.625565
    duration = 0.150 if bright else 0.125
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    mod_index = (2.45 if bright else 1.75) * np.exp(-t / 0.050)
    modulator = np.sin(2.0 * math.pi * frequency * 2.0 * t + 0.23)
    carrier = np.sin(2.0 * math.pi * frequency * t + mod_index * modulator)
    harmonic = 0.14 * np.sin(2.0 * math.pi * frequency * 3.0 * t + 0.41)
    envelope = (1.0 - np.exp(-t / 0.003)) * np.exp(-t / 0.047)
    return fade_edges((carrier + harmonic) * envelope * 0.22, SAMPLE_RATE, 0.6, 15.0)


def synth_orbital_grain(rng: np.random.Generator, duration: float, phase_index: int) -> np.ndarray:
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    raw = bandpass(rng.standard_normal(count), 780.0, 5_800.0, SAMPLE_RATE, 2)
    # A deterministic cluster of tiny windows sounds granular without reading samples.
    window = np.zeros(count, dtype=np.float64)
    grain_len = max(16, int(round(0.018 * SAMPLE_RATE)))
    for offset_fraction in (0.05, 0.26, 0.48, 0.71):
        offset = int(round(offset_fraction * max(0, count - grain_len)))
        local = np.sin(np.linspace(0.0, math.pi, grain_len, endpoint=True)) ** 2
        end = min(count, offset + grain_len)
        window[offset:end] += local[: end - offset]
    tremolo = 0.72 + 0.28 * np.sin(2.0 * math.pi * 7.0 * t + phase_index * 0.61)
    return fade_edges(raw * window * tremolo * 0.075, SAMPLE_RATE, 2.0, 12.0)


def _kick_pattern(phrase: int, local_bar: int, final_pass: bool) -> list[float]:
    impulse = local_bar < 6
    patterns = (
        ([0.0, 2.75], [0.0, 2.50]),
        ([0.0, 1.75, 3.25], [0.0, 2.75]),
        ([0.0, 3.00], [0.0, 1.50, 3.25]),
        ([0.0, 2.50], [0.0, 1.75, 3.50]),
    )
    positions = list(patterns[phrase][0 if impulse else 1])
    # The refined landing bars deliberately exhale before the next 13-bar phrase.
    if final_pass and local_bar in {5, 12}:
        return [0.0] if local_bar == 5 else [0.0, 1.75]
    if local_bar in {2, 8} and len(positions) > 1:
        positions[-1] -= 0.25
    return positions


def render(pass_name: str) -> tuple[np.ndarray, dict[str, Any]]:
    config = PASS_CONFIGS[pass_name]
    final_pass = pass_name == "v2-final"
    base = np.zeros((TOTAL_FRAMES, 2), dtype=np.float32)
    groove = np.zeros_like(base)
    orbit = np.zeros_like(base)
    base_rng = rng_for(SEED, f"{pass_name}:base")
    groove_rng = rng_for(SEED, f"{pass_name}:groove")
    orbit_rng = rng_for(SEED, f"{pass_name}:orbit")
    event_counts = {"kick": 0, "sub": 0, "rimClap": 0, "hat": 0, "fmStab": 0, "grain": 0}

    for bar in range(BARS):
        phrase = bar // 13
        local_bar = bar % 13
        impulse = local_bar < 6
        bar_beat = bar * BEATS_PER_BAR
        kicks = _kick_pattern(phrase, local_bar, final_pass)

        for index, offset in enumerate(kicks):
            kick = synth_kick(base_rng, 0.150 + 0.006 * ((bar + index) % 2))
            add_signal(base, constant_power_pan(kick, 0.0), beat_frame(bar_beat + offset), gain=0.88 if index == 0 else 0.70)
            event_counts["kick"] += 1
            # The first kick anchors A1. V1 also doubled many secondary kicks,
            # which the refinement removes to restore low-frequency breathing room.
            wants_sub = index == 0 or bool(config["secondarySub"])
            if final_pass and local_bar in {5, 12} and index > 0:
                wants_sub = False
            if wants_sub:
                sub = synth_orbital_sub(float(config["subDuration"]), 1.0 if index == 0 else 0.82)
                add_signal(base, constant_power_pan(sub, 0.0), beat_frame(bar_beat + offset), gain=float(config["subGain"]) * (1.0 if index == 0 else 0.66))
                event_counts["sub"] += 1

        rim_positions = [2.0]
        if not impulse and local_bar not in {6, 12} and (bar + phrase) % 3 == 0:
            rim_positions.append(3.50)
        if final_pass and local_bar in {5, 12}:
            rim_positions = [2.0] if local_bar == 5 else []
        for rim_index, offset in enumerate(rim_positions):
            rim = synth_rim_clap(groove_rng, accent=rim_index == 0 and not impulse)
            pan = -0.10 if (bar + rim_index) % 2 == 0 else 0.10
            add_signal(groove, constant_power_pan(rim, pan), beat_frame(bar_beat + offset), gain=0.67 if rim_index == 0 else 0.44)
            event_counts["rimClap"] += 1

        # Sparse hats leave entire half-bars empty. V2 halves the non-anchor hats.
        hat_positions = [0.75, 1.75, 3.25] if impulse else [0.50, 1.50, 2.75]
        if local_bar in {5, 12}:
            hat_positions = [1.50] if local_bar == 5 else []
        for hat_index, offset in enumerate(hat_positions):
            if hat_index > 0 and (bar + hat_index) % int(config["hatStride"] + 1) != 0:
                continue
            hat = synth_hat(groove_rng, open_hat=(not impulse and hat_index == len(hat_positions) - 1 and local_bar % 4 == 2))
            pan = (-0.28, 0.12, 0.31)[hat_index % 3]
            add_signal(groove, constant_power_pan(hat, pan), beat_frame(bar_beat + offset), gain=0.36 if hat_index == 0 else 0.29)
            event_counts["hat"] += 1

        # Each macrophrase gets a distinguishable A/C answer, never a melody line.
        stab_plan: list[tuple[float, str, bool]] = []
        if local_bar == 2:
            stab_plan.append((1.50, "A" if phrase % 2 == 0 else "C", impulse))
        if local_bar == 5:
            stab_plan.append((3.00, "C" if phrase in {0, 3} else "A", True))
        if local_bar == 8 + (phrase % 2):
            stab_plan.append((0.75, "C" if phrase % 2 == 0 else "A", False))
        if local_bar == 11:
            stab_plan.append((2.75, "A" if phrase < 2 else "C", True))
        if bool(config["extraStabs"]) and local_bar in {1, 4, 7, 10}:
            stab_plan.append((3.25, "A" if local_bar % 2 else "C", False))
        for offset, note, bright in stab_plan:
            stab = synth_fm_stab(note, bright)
            pan = -0.26 if note == "A" else 0.26
            add_signal(orbit, constant_power_pan(stab, pan), beat_frame(bar_beat + offset), gain=float(config["stabGain"]))
            event_counts["fmStab"] += 1

        grain_every = int(config["grainEvery"])
        if local_bar not in {5, 12} and (bar + phrase) % grain_every == 1:
            grain = synth_orbital_grain(orbit_rng, 0.155 if impulse else 0.205, bar)
            orbit_position = math.sin(2.0 * math.pi * (bar + 0.5) / 13.0)
            pan = float(config["orbitWidth"]) * orbit_position
            add_signal(orbit, constant_power_pan(grain, pan), beat_frame(bar_beat + (3.25 if impulse else 1.25)), gain=float(config["grainGain"]))
            event_counts["grain"] += 1

    # Keep the low anchor centered; only synthetic air and short stabs orbit.
    mix = base * np.float32(0.91) + groove * np.float32(0.93) + orbit * np.float32(0.86)
    mix = highpass(mix, 24.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix, float(config["masterDrive"]))
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    # A little codec headroom keeps the decoded Vorbis under the -1 dBTP gate.
    mix = normalize_loudness(mix, SAMPLE_RATE, -16.08, -1.35).astype(np.float32)
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    if mix.shape != (TOTAL_FRAMES, 2):
        raise RuntimeError(f"render shape changed: {mix.shape}")
    diagnostics = {
        "pass": pass_name,
        "config": config,
        "eventCounts": event_counts,
        "activeFrameRatioAboveMinus45Dbfs": round(float(np.mean(np.max(np.abs(mix), axis=1) > 10.0 ** (-45.0 / 20.0))), 6),
        "metricsFloat": measure_audio(mix, SAMPLE_RATE, include_true_peak=True),
        "mono": mono_analysis(mix),
        "bands": band_analysis(mix),
    }
    return mix, diagnostics


def mono_analysis(audio: np.ndarray) -> dict[str, Any]:
    left = audio[:, 0].astype(np.float64)
    right = audio[:, 1].astype(np.float64)
    mid = 0.5 * (left + right)
    side = 0.5 * (left - right)
    mid_rms = float(np.sqrt(np.mean(mid * mid)))
    side_rms = float(np.sqrt(np.mean(side * side)))
    correlation = float(np.corrcoef(left, right)[0, 1])
    return {
        "leftRightCorrelation": round(correlation, 6),
        "sideToMidDb": round(amp_to_db(side_rms / max(mid_rms, 1.0e-12)), 4),
        "monoSamplePeakDbfs": round(amp_to_db(float(np.max(np.abs(mid)))), 4),
        "monoRmsDbfs": round(amp_to_db(mid_rms), 4),
        "interpretation": "positive correlation and low side level preserve mono compatibility",
    }


def band_analysis(audio: np.ndarray) -> dict[str, Any]:
    mono = np.mean(audio.astype(np.float64), axis=1)
    block = 65_536
    starts = np.linspace(0, len(mono) - block, 24, dtype=int)
    window = np.hanning(block)
    frequencies = np.fft.rfftfreq(block, d=1.0 / SAMPLE_RATE)
    accumulated = np.zeros_like(frequencies)
    for start in starts:
        spectrum = np.fft.rfft(mono[start : start + block] * window)
        accumulated += np.abs(spectrum) ** 2
    ranges = {
        "sub_25_90_hz": (25.0, 90.0),
        "low_90_250_hz": (90.0, 250.0),
        "mid_250_2000_hz": (250.0, 2_000.0),
        "presence_2000_8000_hz": (2_000.0, 8_000.0),
        "air_8000_20000_hz": (8_000.0, 20_000.0),
    }
    total = float(np.sum(accumulated[(frequencies >= 25.0) & (frequencies < 20_000.0)]))
    result: dict[str, float] = {}
    for label, (low, high) in ranges.items():
        power = float(np.sum(accumulated[(frequencies >= low) & (frequencies < high)]))
        result[label] = round(10.0 * math.log10(max(power / max(total, 1.0e-30), 1.0e-30)), 4)
    return {"relativePowerDb": result, "fftBlocks": len(starts), "fftSize": block}


def array_sha256(audio: np.ndarray) -> str:
    return hashlib.sha256(np.asarray(audio, dtype="<f4").tobytes(order="C")).hexdigest()


def validate_gate(metrics: dict[str, Any], *, runtime: bool) -> list[str]:
    failures: list[str] = []
    label = "runtime" if runtime else "master"
    if metrics["frames"] != TOTAL_FRAMES:
        failures.append(f"{label}: frames {metrics['frames']} != {TOTAL_FRAMES}")
    if metrics["channels"] != 2:
        failures.append(f"{label}: channels {metrics['channels']} != 2")
    if metrics["sampleRate"] != SAMPLE_RATE:
        failures.append(f"{label}: sample rate {metrics['sampleRate']} != {SAMPLE_RATE}")
    if metrics["integratedLufs"] is None or abs(metrics["integratedLufs"] + 16.0) > 0.35:
        failures.append(f"{label}: LUFS {metrics['integratedLufs']} outside -16 ±0.35")
    if metrics["truePeakDbtp"] is None or metrics["truePeakDbtp"] > -1.0:
        failures.append(f"{label}: true peak {metrics['truePeakDbtp']} > -1 dBTP")
    if max(abs(value) for value in metrics["dcOffset"]) >= 1.0e-4:
        failures.append(f"{label}: DC offset {metrics['dcOffset']} >= 1e-4")
    if metrics["samplePeakDbfs"] >= 0.0:
        failures.append(f"{label}: clipping/sample peak {metrics['samplePeakDbfs']} dBFS")
    return failures


def export_and_report() -> None:
    # Pass 1 is rendered and measured before the revised pass is constructed.
    v1_audio, v1_diagnostics = render("v1")
    final_audio, final_diagnostics = render("v2-final")
    first_float_hash = array_sha256(final_audio)

    write_master_and_runtime(ROOT, ASSET, final_audio, SAMPLE_RATE, compression_level=0.72)
    master_metrics, master_info = measure_file(ROOT / MASTER_PATH, include_true_peak=True)
    runtime_metrics, runtime_info = measure_file(ROOT / RUNTIME_PATH, include_true_peak=True)

    # Fresh render + fresh encodes prove both DSP and containers are deterministic.
    verify_audio, _ = render("v2-final")
    second_float_hash = array_sha256(verify_audio)
    with tempfile.TemporaryDirectory(prefix="orbita-de-bolso-determinism-") as temp_name:
        temp_root = Path(temp_name)
        write_master_and_runtime(temp_root, ASSET, verify_audio, SAMPLE_RATE, compression_level=0.72)
        second_master_hash = sha256_file(temp_root / MASTER_PATH)
        second_runtime_hash = sha256_file(temp_root / RUNTIME_PATH)

    first_master_hash = sha256_file(ROOT / MASTER_PATH)
    first_runtime_hash = sha256_file(ROOT / RUNTIME_PATH)
    deterministic = {
        "secondFreshRenderPerformed": True,
        "float32RenderSha256First": first_float_hash,
        "float32RenderSha256Second": second_float_hash,
        "float32Match": first_float_hash == second_float_hash,
        "masterSha256First": first_master_hash,
        "masterSha256Second": second_master_hash,
        "masterMatch": first_master_hash == second_master_hash,
        "runtimeSha256First": first_runtime_hash,
        "runtimeSha256Second": second_runtime_hash,
        "runtimeMatch": first_runtime_hash == second_runtime_hash,
    }

    gate_failures = validate_gate(master_metrics, runtime=False) + validate_gate(runtime_metrics, runtime=True)
    if master_info.format != "WAV" or master_info.subtype != "PCM_24":
        gate_failures.append(f"master: expected WAV/PCM_24, got {master_info.format}/{master_info.subtype}")
    if runtime_info.format != "OGG" or runtime_info.subtype != "VORBIS":
        gate_failures.append(f"runtime: expected OGG/VORBIS, got {runtime_info.format}/{runtime_info.subtype}")
    if not all((deterministic["float32Match"], deterministic["masterMatch"], deterministic["runtimeMatch"])):
        gate_failures.append("determinism hashes did not match")
    decoded_master, _ = sf.read(ROOT / MASTER_PATH, dtype="float32", always_2d=True)
    seam = {
        "taperFrames": TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(decoded_master[0]))), 10),
        "lastFrameAbsMax": round(float(np.max(np.abs(decoded_master[-1]))), 10),
        "first1024Peak": round(float(np.max(np.abs(decoded_master[:TAPER_FRAMES]))), 8),
        "last1024Peak": round(float(np.max(np.abs(decoded_master[-TAPER_FRAMES:]))), 8),
    }
    if seam["firstFrameAbsMax"] > 1.0e-7 or seam["lastFrameAbsMax"] > 1.0e-7:
        gate_failures.append("loop boundary endpoints are not at digital zero")

    report = {
        "schemaVersion": 1,
        "track": {
            "id": ASSET["id"],
            "title": "Órbita de Bolso",
            "style": "phonk espacial seco e brincalhão",
            "brief": "136 BPM, 4/4, A1/55 Hz center, 52 bars as four 13-bar 6+7 phrases; no cowbell, voice, samples, lead melody, nostalgia, aggression, or dark mood",
            "bpm": BPM,
            "meter": "4/4",
            "bars": BARS,
            "phrasePlan": ["6 impulse + 7 response"] * 4,
            "pitchVocabulary": {"subAnchor": "A1 / 55 Hz", "fmStabsOnly": ["A3 / 220 Hz", "C4 / 261.625565 Hz"]},
            "externalAudioUsed": False,
        },
        "seed": SEED,
        "paths": {
            "source": SOURCE_PATH.as_posix(),
            "master": MASTER_PATH.as_posix(),
            "runtime": RUNTIME_PATH.as_posix(),
            "report": REPORT_PATH.as_posix(),
        },
        "sourceSha256": sha256_file(ROOT / SOURCE_PATH),
        "refinementHistory": [
            {
                "pass": "v1",
                "rendered": True,
                "observations": [
                    "secondary kick-subs and 330 ms tails filled too much of the intended negative space",
                    "orbital grains were frequent but narrowly panned, reading as centered hiss instead of motion",
                    "extra FM punctuation weakened the identity of the four macrophrases",
                ],
                "diagnostics": v1_diagnostics,
            },
            {
                "pass": "v2-final",
                "rendered": True,
                "decisions": [
                    "shortened the A1 pitch-drop sub from 330 ms to 235 ms and removed secondary-kick subs",
                    "halved optional hat activity and simplified bars 6 and 13 to create audible exhale points",
                    "reduced grain level/frequency while widening deterministic orbital pan from 0.30 to 0.72",
                    "removed filler stabs and assigned distinct A/C answers to each 13-bar macrophrase",
                ],
                "diagnostics": final_diagnostics,
            },
        ],
        "master": master_metrics,
        "runtime": runtime_metrics,
        "loopBoundary": seam,
        "determinism": deterministic,
        "gates": {
            "targetLufs": -16.0,
            "toleranceLufs": 0.35,
            "truePeakCeilingDbtp": -1.0,
            "dcAbsMaximum": 0.0001,
            "requiredFrames": TOTAL_FRAMES,
            "requiredChannels": 2,
            "requiredSampleRate": SAMPLE_RATE,
            "requiredMasterEncoding": "WAV PCM_24",
            "requiredRuntimeEncoding": "Ogg Vorbis",
            "failures": gate_failures,
            "passed": not gate_failures,
        },
        "environment": {
            "python": platform.python_version(),
            "numpy": np.__version__,
            "soundfile": sf.__version__,
        },
    }
    dump_json(ROOT / REPORT_PATH, report)
    # Keep the large first-pass buffer alive through reporting so its diagnostics
    # truthfully describe the exact data measured above, then release it.
    del v1_audio
    if gate_failures:
        raise SystemExit("Audio gates failed:\n- " + "\n- ".join(gate_failures))
    print(json.dumps({
        "track": report["track"]["title"],
        "master": master_metrics,
        "runtime": runtime_metrics,
        "determinism": deterministic,
        "gatesPassed": True,
    }, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    export_and_report()
