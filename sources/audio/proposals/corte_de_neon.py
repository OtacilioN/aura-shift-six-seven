#!/usr/bin/env python3
"""Deterministic production source for the proposal track "Corte de Neon".

The piece is synthesized from oscillators and seeded noise only.  It preserves
the game's 52-bar / 6+7 contract while giving each 13-bar macrophrase a
different rhythmic function.  ``inspect-v1`` exists to reproduce the first
mix pass that informed the final refinement; the default ``final`` mode writes
the archive master, runtime loop, and evidence report.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from importlib.metadata import version as package_version
import json
import math
from pathlib import Path
import sys
import tempfile
from typing import Any

import numpy as np
import scipy
from scipy import signal
import soundfile as sf


ROOT = Path(__file__).resolve().parents[3]
ASSET_TOOLS = ROOT / "tools" / "assets"
if str(ASSET_TOOLS) not in sys.path:
    sys.path.insert(0, str(ASSET_TOOLS))

from audio_common import (  # noqa: E402
    add_signal,
    amp_to_db,
    bandpass,
    constant_power_pan,
    dump_json,
    fade_edges,
    highpass,
    integrated_lufs,
    lowpass,
    measure_file,
    mono,
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
BOUNDARY_TAPER_FRAMES = 1_024
MASTER_SEED = "corte-de-neon-phonk-proposal-v2-2026-07-12"
ASSET_ID = "MUS-PROP-CORTE-DE-NEON"
ROOT_HZ = 49.0
COWBELL_HZ = 783.990872  # G5; unchanged for every cowbell event.

MASTER_RELATIVE = Path("masters/audio/proposals/corte_de_neon.wav")
RUNTIME_RELATIVE = Path("assets/audio/proposals/corte_de_neon.ogg")
REPORT_RELATIVE = Path("reports/audio-proposals/corte_de_neon.json")


KICK_PATTERNS: tuple[tuple[float, ...], ...] = (
    (0.0, 2.5),
    (0.0, 1.75, 3.25),
    (0.0, 2.75),
    (0.5, 2.5, 3.5),
    (0.0, 2.25, 3.375),
    (0.0, 1.5, 2.875),
    (0.0, 2.75),
    (0.5, 2.0, 3.25),
    (0.0, 1.75, 3.0),
    (0.0, 2.5),
    (0.25, 2.25, 3.5),
    (0.0, 3.0),
    (0.0, 0.75, 1.5),
)

COWBELL_PATTERNS: tuple[tuple[float, ...], ...] = (
    (0.75, 2.25),
    (1.5, 3.25),
    (0.75, 1.75, 3.5),
    (1.25, 2.75),
    (0.5, 2.0, 3.25),
    (0.75, 1.5, 3.0),
    (1.75, 3.25),
    (1.25, 2.75),
    (0.75, 2.0, 3.5),
    (),  # Full cowbell brake in the seven-bar response.
    (0.5, 1.5, 3.25),
    (1.0, 2.5),
    (0.375, 1.125, 1.75),
)

MACRO_NAMES = (
    "entrada fluorescente",
    "derrapagem lateral",
    "freada de vidro",
    "retorno ao eixo",
)


def frames(seconds: float) -> int:
    return int(round(seconds * SAMPLE_RATE))


def beat_frame(beat: float) -> int:
    return int(round(beat * 60.0 * SAMPLE_RATE / BPM))


def phase_from_frequency(frequency: np.ndarray | float) -> np.ndarray:
    values = np.asarray(frequency, dtype=np.float64)
    return 2.0 * math.pi * np.cumsum(values) / SAMPLE_RATE


def synth_kick(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    duration = 0.165 if final else 0.195
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    frequency = ROOT_HZ + (86.0 if final else 98.0) * np.exp(-t / 0.018)
    phase = phase_from_frequency(frequency)
    envelope = (1.0 - np.exp(-t / 0.0018)) * np.exp(-t / (0.058 if final else 0.076))
    body = np.sin(phase) + 0.18 * np.sin(2.0 * phase + 0.22)
    click = highpass(rng.standard_normal(count), 2_600.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0042) * (0.030 if final else 0.040)
    return fade_edges((body * envelope * 0.78 + click).astype(np.float32), SAMPLE_RATE, 0.5, 12.0)


def synth_sub(*, final: bool, accent: bool) -> np.ndarray:
    duration = (0.235 if accent else 0.205) if final else (0.315 if accent else 0.285)
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    glide = ROOT_HZ * (1.0 + (0.024 if final else 0.045) * np.exp(-t / 0.022))
    phase = phase_from_frequency(glide)
    envelope = (1.0 - np.exp(-t / 0.005)) * np.exp(-t / (0.096 if final else 0.132))
    tone = np.sin(phase) + (0.22 if final else 0.16) * np.sin(2.0 * phase + 0.18)
    tone = np.tanh(tone * 1.18) / math.tanh(1.18)
    return fade_edges((tone * envelope * 0.54).astype(np.float32), SAMPLE_RATE, 1.0, 22.0)


def synth_cowbell(*, final: bool) -> np.ndarray:
    duration = 0.112 if final else 0.145
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    carrier_phase = 2.0 * math.pi * COWBELL_HZ * t
    modulator_phase = 2.0 * math.pi * (COWBELL_HZ * math.sqrt(2.0)) * t + 0.37
    fm_index = (2.05 if final else 2.42) * np.exp(-t / 0.032)
    metallic = np.sin(carrier_phase + fm_index * np.sin(modulator_phase))
    metallic += 0.28 * np.sin(1.487 * carrier_phase + 0.43)
    envelope = (1.0 - np.exp(-t / 0.0011)) * np.exp(-t / (0.031 if final else 0.043))
    tone = highpass(metallic * envelope, 420.0, SAMPLE_RATE, 2)
    tone = lowpass(tone, 7_200.0 if final else 7_600.0, SAMPLE_RATE, 2)
    return fade_edges((tone * (0.35 if final else 0.31)).astype(np.float32), SAMPLE_RATE, 0.3, 9.0)


def synth_snare(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    duration = 0.145 if final else 0.19
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    noise = bandpass(rng.standard_normal(count), 650.0, 5_400.0, SAMPLE_RATE, 2)
    envelope = np.exp(-t / (0.031 if final else 0.046))
    envelope += 0.54 * np.exp(-np.maximum(t - 0.014, 0.0) / 0.022) * (t >= 0.014)
    body = np.sin(2.0 * math.pi * 196.0 * t + 0.21) * np.exp(-t / 0.052)
    result = noise * envelope * 0.115 + body * 0.075
    return fade_edges(result.astype(np.float32), SAMPLE_RATE, 0.4, 14.0)


def synth_shaker(rng: np.random.Generator, *, open_hat: bool, final: bool) -> np.ndarray:
    duration = (0.078 if open_hat else 0.038) if final else (0.105 if open_hat else 0.052)
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    noise = highpass(rng.standard_normal(count), 5_200.0 if final else 4_700.0, SAMPLE_RATE, 3)
    noise = lowpass(noise, 14_500.0, SAMPLE_RATE, 2)
    envelope = np.exp(-t / (duration * (0.28 if open_hat else 0.19)))
    return fade_edges((noise * envelope * 0.075).astype(np.float32), SAMPLE_RATE, 0.2, 6.0)


def synth_stab(*, final: bool) -> np.ndarray:
    duration = 0.17 if final else 0.28
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    envelope = (1.0 - np.exp(-t / 0.004)) * np.exp(-t / (0.041 if final else 0.07))
    frequencies = (196.0, 293.664768)  # G3 + D4; a fixed color, not a melodic line.
    tone = np.zeros(count, dtype=np.float64)
    for index, frequency in enumerate(frequencies):
        local_phase = 2.0 * math.pi * frequency * t + index * 0.31
        tone += np.sin(local_phase) + 0.16 * np.sin(2.0 * local_phase + 0.2)
    tone /= len(frequencies)
    tone = lowpass(tone, 2_600.0 if final else 3_400.0, SAMPLE_RATE, 2)
    return fade_edges((tone * envelope * 0.22).astype(np.float32), SAMPLE_RATE, 0.8, 16.0)


def synth_texture(rng: np.random.Generator, *, final: bool, long: bool) -> np.ndarray:
    duration = (0.62 if long else 0.31) if final else (0.84 if long else 0.42)
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    noise = bandpass(rng.standard_normal(count), 520.0, 3_900.0 if final else 5_200.0, SAMPLE_RATE, 2)
    envelope = np.sin(np.linspace(0.0, math.pi, count, endpoint=True)) ** 1.8
    flutter = 0.72 + 0.28 * np.sin(2.0 * math.pi * 6.7 * t + 0.4)
    return fade_edges((noise * envelope * flutter * 0.050).astype(np.float32), SAMPLE_RATE, 3.0, 20.0)


def synth_brake(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    duration = 0.24 if final else 0.37
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    progress = t / duration
    frequency = 1_300.0 - 860.0 * progress
    chirp = np.sin(phase_from_frequency(frequency) + 0.2)
    noise = bandpass(rng.standard_normal(count), 420.0, 2_800.0, SAMPLE_RATE, 2)
    envelope = np.sin(math.pi * progress) ** 1.6
    result = (chirp * 0.040 + noise * 0.028) * envelope
    return fade_edges(result.astype(np.float32), SAMPLE_RATE, 2.0, 15.0)


def add_event(
    target: np.ndarray,
    source: np.ndarray,
    beat: float,
    *,
    gain: float,
    pan: float = 0.0,
) -> None:
    add_signal(
        target,
        constant_power_pan(source, pan),
        beat_frame(beat),
        gain=gain,
        circular=False,
    )


def _secondary_shift(phrase: int, local_bar: int, position: float, *, final: bool) -> float:
    if position == 0.0 or local_bar == 12:
        return position
    if not final:
        return position + (0.125 if phrase in (1, 3) else 0.0)
    shifts = (0.0, 0.125, -0.125, 0.25)
    shifted = position + shifts[phrase]
    return float(np.clip(shifted, 0.125, 3.75))


def remove_dc_preserve_boundary(audio: np.ndarray) -> np.ndarray:
    """Remove finite-render DC without lifting the zero-valued loop endpoints."""
    data = np.array(audio, dtype=np.float32, copy=True)
    correction_window = np.ones(data.shape[0], dtype=np.float64)
    ramp = np.sin(
        np.linspace(0.0, math.pi / 2.0, BOUNDARY_TAPER_FRAMES, endpoint=True)
    ) ** 2
    correction_window[:BOUNDARY_TAPER_FRAMES] = ramp
    correction_window[-BOUNDARY_TAPER_FRAMES:] = ramp[::-1]
    window_mean = float(np.mean(correction_window))
    channel_means = np.mean(data, axis=0, dtype=np.float64)
    data -= (correction_window[:, None] * (channel_means / window_mean)[None, :]).astype(np.float32)
    data[0] = 0.0
    data[-1] = 0.0
    return data


def render_arrangement(pass_name: str) -> tuple[np.ndarray, dict[str, Any]]:
    if pass_name not in {"v1", "v2"}:
        raise ValueError(f"unsupported pass: {pass_name}")
    final = pass_name == "v2"
    mix = np.zeros((TOTAL_FRAMES, 2), dtype=np.float32)
    rng = rng_for(MASTER_SEED, f"{ASSET_ID}:{pass_name}")
    counts = {name: 0 for name in ("kick", "sub", "cowbell", "snare", "shaker", "stab", "texture", "brake")}
    counts["intentionalCowbellSilentBars"] = 0
    counts["intentionalHalfBarSilences"] = 0

    kick = synth_kick(rng, final=final)
    cowbell = synth_cowbell(final=final)
    stab = synth_stab(final=final)

    for bar in range(BARS):
        phrase = bar // 13
        local = bar % 13
        bar_beat = bar * BEATS_PER_BAR
        impulse = local < 6

        kick_positions = list(KICK_PATTERNS[local])
        if final and phrase == 2 and local in {4, 5, 10}:
            kick_positions = kick_positions[:-1]
        if final and phrase == 3 and local == 11:
            kick_positions = (0.0, 2.5)
        for index, base_position in enumerate(kick_positions):
            position = _secondary_shift(phrase, local, base_position, final=final)
            gain = (0.82 if index == 0 else 0.62) if final else (0.86 if index == 0 else 0.67)
            if local == 12:
                gain *= (1.0, 0.86, 0.72)[min(index, 2)]
            add_event(mix, kick, bar_beat + position, gain=gain)
            counts["kick"] += 1
            sub = synth_sub(final=final, accent=index == 0)
            add_event(
                mix,
                sub,
                bar_beat + position,
                gain=(0.58 if index == 0 else 0.36) if final else (0.68 if index == 0 else 0.45),
            )
            counts["sub"] += 1

        cow_positions = list(COWBELL_PATTERNS[local])
        if not cow_positions:
            counts["intentionalCowbellSilentBars"] += 1
        if final and phrase == 2 and local in {5, 11}:
            cow_positions = cow_positions[::2]
        if final and phrase == 3 and local == 12:
            cow_positions = [0.375, 1.125]
        if phrase % 2:
            cow_positions = list(reversed(cow_positions))
        for index, base_position in enumerate(cow_positions):
            position = _secondary_shift(phrase, local, base_position, final=final)
            velocity_cycle = (0.84, 0.63, 0.73) if final else (0.78, 0.58, 0.68)
            gain = velocity_cycle[(bar + index + phrase) % len(velocity_cycle)]
            add_event(
                mix,
                cowbell,
                bar_beat + position,
                gain=gain,
                pan=(-0.11 if (index + bar) % 2 == 0 else 0.11) if final else (-0.19 if index % 2 == 0 else 0.19),
            )
            counts["cowbell"] += 1

        if local == 12:
            snare_positions = (1.5,)
        elif impulse:
            snare_positions = (1.0, 3.0)
        else:
            snare_positions = (1.25, 3.0)
        if final and local in {5, 9, 11}:
            snare_positions = snare_positions[:1]
        for index, position in enumerate(snare_positions):
            snare = synth_snare(rng, final=final)
            add_event(
                mix,
                snare,
                bar_beat + position,
                gain=0.53 if index == 0 else 0.42,
                pan=-0.035 if index == 0 else 0.035,
            )
            counts["snare"] += 1

        shaker_positions = [0.5, 1.5, 2.5, 3.5]
        if not final:
            shaker_positions += [1.0, 2.0, 3.0]
        if final and local in {5, 9, 12}:
            shaker_positions = [0.5] if local == 12 else [0.5, 2.5]
        if final and phrase == 2 and local in {4, 10}:
            shaker_positions = shaker_positions[::2]
        for index, position in enumerate(shaker_positions):
            shaker = synth_shaker(rng, open_hat=index == len(shaker_positions) - 1 and local in {4, 8}, final=final)
            gain = (0.24, 0.17, 0.21, 0.15)[index % 4]
            add_event(
                mix,
                shaker,
                bar_beat + position,
                gain=gain,
                pan=-0.23 if (bar + index) % 2 == 0 else 0.23,
            )
            counts["shaker"] += 1

        if local in ({5, 11} if not final else {5, 11}) and not (final and phrase == 2 and local == 5):
            position = 3.25 if impulse else 2.75
            add_event(mix, stab, bar_beat + position, gain=0.36 if final else 0.44, pan=0.07 if phrase % 2 else -0.07)
            counts["stab"] += 1

        if local in {2, 5, 8, 11}:
            texture = synth_texture(rng, final=final, long=local in {5, 11})
            position = 3.0 if impulse else 2.0
            if local == 11:
                position = 3.25
            add_event(
                mix,
                texture,
                bar_beat + position,
                gain=0.27 if final else 0.42,
                pan=(-0.15 if bar % 2 == 0 else 0.15) if final else (-0.28 if bar % 2 == 0 else 0.28),
            )
            counts["texture"] += 1

        if local in {5, 11} and (phrase >= 1 or not final):
            brake = synth_brake(rng, final=final)
            add_event(mix, brake, bar_beat + 3.5, gain=0.38 if final else 0.52, pan=0.12 if phrase % 2 else -0.12)
            counts["brake"] += 1

        if local == 12:
            counts["intentionalHalfBarSilences"] += 1

    # Broadband cleanup and a restrained bus curve keep the low end centered,
    # the metallic hook soft, and the limiter out of the composition role.
    mix = highpass(mix, 24.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = lowpass(mix, 16_800.0 if final else 18_200.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix * np.float32(1.16 if final else 1.28), 1.22 if final else 1.34)
    mix = taper_loop_boundary(mix, BOUNDARY_TAPER_FRAMES)
    mix = normalize_loudness(mix, SAMPLE_RATE, -16.0, -1.15).astype(np.float32)
    if final:
        # Loudness normalization may select a nonlinear crest-control curve;
        # correct DC after that final nonlinearity so the archived result, not
        # merely the pre-master buffer, satisfies the offset gate.
        mix = remove_dc_preserve_boundary(mix)
    return mix, counts


def spectral_metrics(audio: np.ndarray) -> dict[str, Any]:
    center = mono(audio).astype(np.float64, copy=False)
    frequencies, power = signal.welch(
        center,
        fs=SAMPLE_RATE,
        window="hann",
        nperseg=4_096,
        noverlap=2_048,
        detrend=False,
        scaling="spectrum",
    )
    total = float(np.sum(power)) + 1.0e-18
    centroid = float(np.sum(frequencies * power) / total)
    bands = {
        "sub20To90": (20.0, 90.0),
        "bass90To250": (90.0, 250.0),
        "mid250To2500": (250.0, 2_500.0),
        "presence2500To6000": (2_500.0, 6_000.0),
        "air6000To16000": (6_000.0, 16_000.0),
    }
    ratios: dict[str, float] = {}
    for name, (low, high) in bands.items():
        mask = (frequencies >= low) & (frequencies < high)
        ratios[name] = round(float(np.sum(power[mask]) / total), 6)
    peak_indices = signal.find_peaks(power, distance=3)[0]
    peak_indices = peak_indices[frequencies[peak_indices] >= 20.0]
    strongest = peak_indices[np.argsort(power[peak_indices])[-6:]][::-1]
    return {
        "spectralCentroidHz": round(centroid, 3),
        "bandEnergyRatios": ratios,
        "strongestAverageFrequenciesHz": [round(float(frequencies[index]), 3) for index in strongest],
    }


def density_metrics(audio: np.ndarray, event_counts: dict[str, Any]) -> dict[str, Any]:
    center = mono(audio)
    block = 480  # 10 ms
    padded = np.pad(center, (0, (-center.shape[0]) % block))
    rms = np.sqrt(np.mean(np.square(padded.reshape(-1, block)), axis=1, dtype=np.float64))
    db = 20.0 * np.log10(np.maximum(rms, 1.0e-12))
    return {
        "active10msBlockRatioAboveMinus42Dbfs": round(float(np.mean(db > -42.0)), 6),
        "quiet10msBlockRatioBelowMinus55Dbfs": round(float(np.mean(db < -55.0)), 6),
        "median10msRmsDbfs": round(float(np.median(db)), 4),
        "eventsPerBar": round(
            sum(int(event_counts[name]) for name in ("kick", "cowbell", "snare", "shaker", "stab", "texture", "brake")) / BARS,
            4,
        ),
        "eventCounts": event_counts,
    }


def mono_metrics(audio: np.ndarray) -> dict[str, Any]:
    data = np.asarray(audio, dtype=np.float64)
    left = data[:, 0]
    right = data[:, 1]
    center = (left + right) * 0.5
    side = (left - right) * 0.5
    stereo_rms = math.sqrt(float(np.mean((left * left + right * right) * 0.5)))
    mono_rms = math.sqrt(float(np.mean(center * center)))
    side_rms = math.sqrt(float(np.mean(side * side)))
    correlation = float(np.corrcoef(left, right)[0, 1])
    return {
        "leftRightCorrelation": round(correlation, 6),
        "monoFoldRmsDbfs": round(amp_to_db(mono_rms), 4),
        "monoFoldDeltaDb": round(20.0 * math.log10(max(mono_rms, 1.0e-12) / max(stereo_rms, 1.0e-12)), 4),
        "sideToMidEnergyDb": round(20.0 * math.log10(max(side_rms, 1.0e-12) / max(mono_rms, 1.0e-12)), 4),
        "monoIntegratedLufs": round(float(integrated_lufs(center, SAMPLE_RATE)), 4),
        "monoSamplePeakDbfs": round(amp_to_db(float(np.max(np.abs(center)))), 4),
    }


def boundary_metrics(audio: np.ndarray) -> dict[str, Any]:
    data = np.asarray(audio, dtype=np.float64)
    return {
        "taperFrames": BOUNDARY_TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(data[0]))), 10),
        "lastFrameAbsMax": round(float(np.max(np.abs(data[-1]))), 10),
        "seamDiscontinuityAbsMax": round(float(np.max(np.abs(data[0] - data[-1]))), 10),
        "firstTaperRegionPeakDbfs": round(amp_to_db(float(np.max(np.abs(data[:BOUNDARY_TAPER_FRAMES])))), 4),
        "lastTaperRegionPeakDbfs": round(amp_to_db(float(np.max(np.abs(data[-BOUNDARY_TAPER_FRAMES:])))), 4),
    }


def analysis_bundle(audio: np.ndarray, event_counts: dict[str, Any]) -> dict[str, Any]:
    return {
        "density": density_metrics(audio, event_counts),
        "spectral": spectral_metrics(audio),
        "monoCompatibility": mono_metrics(audio),
        "loopBoundary": boundary_metrics(audio),
    }


def asset_descriptor(master: Path, runtime: Path) -> dict[str, Any]:
    return {
        "id": ASSET_ID,
        "channels": 2,
        "master": master.as_posix(),
        "runtime": runtime.as_posix(),
    }


def export_pair(base: Path, audio: np.ndarray, master: Path, runtime: Path) -> tuple[Path, Path]:
    descriptor = asset_descriptor(master, runtime)
    write_master_and_runtime(base, descriptor, audio, SAMPLE_RATE, 0.6)
    return base / master, base / runtime


def inspect_v1(output: Path) -> int:
    audio, counts = render_arrangement("v1")
    output.parent.mkdir(parents=True, exist_ok=True)
    sf.write(output, audio, SAMPLE_RATE, format="WAV", subtype="PCM_24")
    file_metrics, _ = measure_file(output, include_true_peak=True)
    payload = {
        "pass": "v1",
        "temporaryPath": str(output),
        "metrics": file_metrics,
        "analysis": analysis_bundle(audio, counts),
    }
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


def gate_results(master_metrics: dict[str, Any], runtime_metrics: dict[str, Any], audio: np.ndarray, deterministic: bool) -> dict[str, bool]:
    return {
        "exactMasterFrames": master_metrics["frames"] == TOTAL_FRAMES,
        "exactRuntimeFrames": runtime_metrics["frames"] == TOTAL_FRAMES,
        "stereoMaster": master_metrics["channels"] == 2,
        "stereoRuntime": runtime_metrics["channels"] == 2,
        "sampleRate48k": master_metrics["sampleRate"] == SAMPLE_RATE and runtime_metrics["sampleRate"] == SAMPLE_RATE,
        "masterPcm24": master_metrics["format"] == "WAV" and master_metrics["subtype"] == "PCM_24",
        "runtimeVorbis": runtime_metrics["format"] == "OGG" and runtime_metrics["subtype"] == "VORBIS",
        "loudnessMinus16PlusMinus035": abs(float(master_metrics["integratedLufs"]) + 16.0) <= 0.35,
        "truePeakAtOrBelowMinus1Dbtp": float(master_metrics["truePeakDbtp"]) <= -1.0,
        "samplePeakNoClipping": float(master_metrics["samplePeakDbfs"]) < 0.0,
        "dcOffsetBelow1eMinus4": max(abs(float(value)) for value in master_metrics["dcOffset"]) < 1.0e-4,
        "boundaryTaper1024": BOUNDARY_TAPER_FRAMES == 1_024 and float(np.max(np.abs(audio[0]))) == 0.0 and float(np.max(np.abs(audio[-1]))) == 0.0,
        "runtimeDecodable": runtime_metrics["frames"] > 0 and runtime_metrics["integratedLufs"] is not None,
        "secondRenderByteIdentical": deterministic,
    }


def produce_final() -> int:
    # Pass one remains fully reproducible and is genuinely rendered/measured;
    # its temporary binary is intentionally discarded after evidence capture.
    v1_audio, v1_counts = render_arrangement("v1")
    with tempfile.TemporaryDirectory(prefix="corte-neon-v1-") as temp_name:
        temp_root = Path(temp_name)
        v1_master, _ = export_pair(temp_root, v1_audio, Path("v1/corte_de_neon.wav"), Path("v1/corte_de_neon.ogg"))
        v1_metrics, _ = measure_file(v1_master, include_true_peak=True)
    v1_analysis = analysis_bundle(v1_audio, v1_counts)

    # Two independent final renders and exports must agree byte-for-byte.
    first_audio, first_counts = render_arrangement("v2")
    with tempfile.TemporaryDirectory(prefix="corte-neon-determinism-") as temp_name:
        temp_root = Path(temp_name)
        first_master, first_runtime = export_pair(temp_root, first_audio, MASTER_RELATIVE, RUNTIME_RELATIVE)
        first_hashes = {"master": sha256_file(first_master), "runtime": sha256_file(first_runtime)}

        final_audio, final_counts = render_arrangement("v2")
        final_master, final_runtime = export_pair(ROOT, final_audio, MASTER_RELATIVE, RUNTIME_RELATIVE)
        second_hashes = {"master": sha256_file(final_master), "runtime": sha256_file(final_runtime)}
        deterministic = first_hashes == second_hashes and np.array_equal(first_audio, final_audio)

    master_metrics, _ = measure_file(final_master, include_true_peak=True)
    runtime_metrics, _ = measure_file(final_runtime, include_true_peak=True)
    final_analysis = analysis_bundle(final_audio, final_counts)
    gates = gate_results(master_metrics, runtime_metrics, final_audio, deterministic)

    report = {
        "schemaVersion": 1,
        "id": ASSET_ID,
        "title": "Corte de Neon",
        "status": "demo-produced-and-validated",
        "genre": "phonk luminoso e elástico",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "briefing": (
            "Phonk luminoso e elástico, 136 BPM, 4/4, centro em Sol (~49 Hz), "
            "52 compassos em quatro macrofrases 6+7; cowbell FM de altura única "
            "como gancho rítmico, grave curto, micro-silêncios e derrapagem controlada."
        ),
        "constraints": {
            "noVoice": True,
            "noExternalSamples": True,
            "noArtistImitation": True,
            "noLeadMelody": True,
            "mood": ["luminoso", "elástico", "brincalhão", "controlado"],
        },
        "structure": {
            "bpm": BPM,
            "timeSignature": "4/4",
            "bars": BARS,
            "macrophrases": 4,
            "barsPerMacrophrase": 13,
            "impulseResponseBars": "6+7",
            "macrophraseProfiles": list(MACRO_NAMES),
            "rootFrequencyHz": ROOT_HZ,
            "cowbellFrequencyHz": COWBELL_HZ,
            "cowbellPitchCount": 1,
        },
        "provenance": {
            "method": "deterministic synthesis from oscillators and seeded noise",
            "masterSeed": MASTER_SEED,
            "externalAudioSources": [],
            "source": str(Path(__file__).resolve().relative_to(ROOT)),
            "sourceSha256": sha256_file(Path(__file__)),
            "tools": {
                "python": sys.version.split()[0],
                "numpy": np.__version__,
                "scipy": scipy.__version__,
                "soundfile": sf.__version__,
                "pyloudnorm": package_version("pyloudnorm"),
            },
        },
        "deliverables": {
            "master": str(MASTER_RELATIVE),
            "runtime": str(RUNTIME_RELATIVE),
            "report": str(REPORT_RELATIVE),
        },
        "refinementHistory": [
            {
                "pass": "v1",
                "status": "rendered-analyzed-discarded",
                "metrics": v1_metrics,
                "analysis": v1_analysis,
                "findings": [
                    "longer kick/sub tails raised low-frequency occupancy between syncopations",
                    "seven shaker positions per ordinary bar reduced the intended negative space",
                    "wide and longer texture/cowbell tails softened the controlled-brake silhouette",
                    "finite-render DC offset exceeded the 1e-4 master gate",
                ],
            },
            {
                "pass": "v2",
                "status": "final",
                "changes": [
                    "shortened kick, sub, snare, cowbell and texture envelopes",
                    "reduced ordinary shaker density from seven to four positions and to two or one in brake bars",
                    "removed selected late kicks in macrophrase three and preserved a cowbell-free response bar",
                    "narrowed cowbell/texture stereo placement while keeping kick and sub strictly centered",
                    "softened the cowbell top end and raised its fixed G5 definition without creating pitch motion",
                    "made macrophrase shifts 0, +1/8, -1/8 and +1/4 beat, with an explicit final half-bar silence",
                    "applied boundary-preserving DC correction after the final nonlinear bus stage",
                ],
                "metrics": master_metrics,
                "analysis": final_analysis,
            },
        ],
        "metrics": {
            "master": master_metrics,
            "runtimeDecoded": runtime_metrics,
            **final_analysis,
        },
        "determinism": {
            "independentFinalRendersCompared": 2,
            "floatBuffersIdentical": bool(np.array_equal(first_audio, final_audio)),
            "firstRenderSha256": first_hashes,
            "secondRenderSha256": second_hashes,
            "byteIdentical": deterministic,
        },
        "gates": gates,
        "allGatesPassed": all(gates.values()),
    }
    dump_json(ROOT / REPORT_RELATIVE, report)
    if not report["allGatesPassed"]:
        failed = [name for name, passed in gates.items() if not passed]
        raise RuntimeError(f"Corte de Neon failed gates: {', '.join(failed)}")
    print(json.dumps({
        "master": master_metrics,
        "runtime": runtime_metrics,
        "deterministic": deterministic,
        "gates": gates,
    }, indent=2, ensure_ascii=False))
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("inspect-v1", "final"), default="final")
    parser.add_argument(
        "--inspection-output",
        type=Path,
        default=Path("/tmp/corte_de_neon_v1.wav"),
        help="temporary WAV path used only by inspect-v1",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.mode == "inspect-v1":
        return inspect_v1(args.inspection_output)
    return produce_final()


if __name__ == "__main__":
    raise SystemExit(main())
