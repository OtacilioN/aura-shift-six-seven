#!/usr/bin/env python3
"""Produce, refine, export, and validate "Guichê das 03:67".

Everything is synthesized deterministically from oscillators and seeded noise.
No sample, foley recording, voice, or model-generated audio is read.  The loop
is 52 bars at 136 BPM: four different 13-bar macrophrases, each shaped 6+7.
"""

from __future__ import annotations

from datetime import datetime, timezone
import gc
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
    lowpass,
    measure_audio,
    measure_file,
    normalize_loudness,
    rng_for,
    sha256_file,
    soft_clip,
    taper_loop_boundary,
    write_master_and_runtime,
)


TITLE = "Guichê das 03:67"
TRACK_ID = "DEMO-BREGA-GUICHE-0367"
SEED = "six-seven-guiche-das-03-67-2026-07-12-v2"
SAMPLE_RATE = 48_000
BPM = 136.0
BARS = 52
BEATS_PER_BAR = 4
PHRASE_BARS = 13
IMPULSE_BARS = 6
TOTAL_FRAMES = 4_404_706
TAPER_FRAMES = 1_024

SOURCE_PATH = Path("sources/audio/proposals/guiche_das_03_67.py")
MASTER_PATH = Path("masters/audio/proposals/guiche_das_03_67.wav")
RUNTIME_PATH = Path("assets/audio/proposals/guiche_das_03_67.ogg")
REPORT_PATH = Path("reports/audio-proposals/guiche_das_03_67.json")

ASSET = {
    "id": TRACK_ID,
    "channels": 2,
    "master": MASTER_PATH.as_posix(),
    "runtime": RUNTIME_PATH.as_posix(),
}

PASS_CONFIGS: dict[str, dict[str, Any]] = {
    "v1": {
        "refined": False,
        "pluckDuration": 0.235,
        "pluckEveryKick": True,
        "hatDensity": 1.0,
        "brassCutoff": 2_850.0,
        "brassGain": 0.62,
        "clickGain": 0.54,
        "panWidth": 0.28,
        "masterDrive": 1.10,
    },
    "v2-final": {
        "refined": True,
        "pluckDuration": 0.158,
        "pluckEveryKick": False,
        "hatDensity": 0.54,
        "brassCutoff": 1_650.0,
        "brassGain": 0.47,
        "clickGain": 0.43,
        "panWidth": 0.16,
        "masterDrive": 1.20,
    },
}


def frames(seconds: float) -> int:
    return int(round(seconds * SAMPLE_RATE))


def beat_frame(beat: float) -> int:
    return int(round(beat * 60.0 * SAMPLE_RATE / BPM))


def time_axis(count: int) -> np.ndarray:
    return np.arange(count, dtype=np.float64) / SAMPLE_RATE


def phase_from_frequency(frequency: np.ndarray | float) -> np.ndarray:
    values = np.asarray(frequency, dtype=np.float64)
    return 2.0 * math.pi * np.cumsum(values) / SAMPLE_RATE


def synth_kick(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Short round kick settling at A1; never a long 808 tail."""
    duration = 0.145 + 0.006 * (variant % 3)
    count = frames(duration)
    t = time_axis(count)
    frequency = 55.0 + (94.0 + 5.0 * (variant % 2)) * np.exp(-t / 0.015)
    body = np.sin(phase_from_frequency(frequency))
    body += 0.13 * np.sin(2.0 * phase_from_frequency(frequency) + 0.23)
    envelope = (1.0 - np.exp(-t / 0.0015)) * np.exp(-t / 0.052)
    click = highpass(rng.standard_normal(count), 2_700.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0037) * 0.018
    return fade_edges(body * envelope * 0.76 + click, SAMPLE_RATE, 0.35, 11.0)


def synth_rubber_pluck(duration: float, variant: int, accent: bool) -> np.ndarray:
    """Fixed-pitch A rubber pluck: explicitly no glide, dip, or spring rebound."""
    count = frames(duration)
    t = time_axis(count)
    fundamental = 55.0 if variant % 3 else 110.0
    phase = 2.0 * math.pi * fundamental * t + 0.09 * (variant % 4)
    body = np.sin(phase)
    body += 0.24 * np.sin(2.0 * phase + 0.29)
    body += 0.08 * np.sin(3.0 * phase + 0.63)
    attack = 1.0 - np.exp(-t / 0.0027)
    decay = np.exp(-t / (0.060 if accent else 0.047))
    pluck = np.tanh(body * (1.50 if accent else 1.25)) * attack * decay
    return fade_edges(pluck * 0.52, SAMPLE_RATE, 0.6, 17.0)


def synth_noise_clap(rng: np.random.Generator, variant: int, accent: bool) -> np.ndarray:
    duration = 0.118 if accent else 0.087
    count = frames(duration)
    t = time_axis(count)
    noise = bandpass(rng.standard_normal(count), 720.0, 7_600.0, SAMPLE_RATE, 2)
    envelope = np.exp(-t / (0.019 if accent else 0.013))
    bursts = envelope.copy()
    if accent:
        for delay, gain in ((0.010, 0.42), (0.021, 0.25)):
            offset = frames(delay)
            bursts[offset:] += gain * envelope[:-offset]
    narrow = np.sin(2.0 * math.pi * (690.0 + 37.0 * (variant % 3)) * t)
    narrow *= np.exp(-t / 0.016) * 0.045
    return fade_edges(noise * bursts * 0.102 + narrow, SAMPLE_RATE, 0.25, 9.0)


def synth_plastic_click(rng: np.random.Generator, variant: int, double: bool) -> np.ndarray:
    """Tiny synthetic polymer tick: no metallic cowbell oscillator pair."""
    duration = 0.052 if double else 0.041
    count = frames(duration)
    t = time_axis(count)
    base = 1_080.0 + 117.0 * (variant % 5)
    resonator = np.sin(2.0 * math.pi * base * t + 0.21)
    resonator += 0.23 * np.sin(2.0 * math.pi * base * 1.57 * t + 0.75)
    envelope = np.exp(-t / 0.0085)
    noise = bandpass(rng.standard_normal(count), 1_500.0, 6_800.0, SAMPLE_RATE, 2)
    noise *= np.exp(-t / 0.0048)
    output = resonator * envelope * 0.18 + noise * 0.045
    if double:
        offset = frames(0.018)
        output[offset:] += resonator[:-offset] * envelope[:-offset] * 0.10
    return fade_edges(output, SAMPLE_RATE, 0.15, 5.5)


def synth_hat(rng: np.random.Generator, variant: int, open_hat: bool) -> np.ndarray:
    duration = 0.098 if open_hat else 0.042
    count = frames(duration)
    t = time_axis(count)
    noise = highpass(rng.standard_normal(count), 6_100.0, SAMPLE_RATE, 3)
    envelope = np.exp(-t / (0.026 if open_hat else 0.0085))
    return fade_edges(noise * envelope * 0.066, SAMPLE_RATE, 0.2, 6.5)


def synth_muted_brass(register: str, answer: bool, cutoff: float, variant: int) -> np.ndarray:
    """Low-passed subtractive brass punctuation, never a lead melody."""
    if register not in {"low", "high"}:
        raise ValueError(register)
    roots = (110.0, 164.813778) if register == "low" else (220.0, 329.627557)
    duration = 0.175 if answer else 0.205
    count = frames(duration)
    t = time_axis(count)
    output = np.zeros(count, dtype=np.float64)
    for voice, root in enumerate(roots):
        phase = 2.0 * math.pi * root * t + 0.17 * voice + 0.03 * variant
        for harmonic in range(1, 6):
            output += np.sin(harmonic * phase) / (harmonic ** 1.25)
    output /= 2.75
    attack = 1.0 - np.exp(-t / (0.010 if answer else 0.013))
    envelope = attack * np.exp(-t / (0.052 if answer else 0.068))
    output = lowpass(output * envelope, cutoff, SAMPLE_RATE, 3)
    return fade_edges(output * 0.23, SAMPLE_RATE, 1.1, 20.0)


def add_event(
    destination: np.ndarray,
    source: np.ndarray,
    bar: int,
    offset: float,
    *,
    gain: float,
    pan: float = 0.0,
) -> None:
    add_signal(
        destination,
        constant_power_pan(source, pan),
        beat_frame(bar * BEATS_PER_BAR + offset),
        gain=gain,
        circular=False,
    )


def remove_dc_preserving_loop_endpoints(audio: np.ndarray) -> np.ndarray:
    """Cancel channel mean with an inaudible zero-at-both-ends correction."""
    data = np.array(audio, dtype=np.float32, copy=True)
    channel_mean = np.mean(data, axis=0, dtype=np.float64)
    window_mean = (data.shape[0] - 1.0) / (2.0 * data.shape[0])
    correction = channel_mean / window_mean
    denominator = data.shape[0] - 1.0
    for start in range(0, data.shape[0], 262_144):
        end = min(data.shape[0], start + 262_144)
        index = np.arange(start, end, dtype=np.float64)
        window = np.sin(math.pi * index / denominator) ** 2
        data[start:end] -= (window[:, None] * correction[None, :]).astype(np.float32)
    data[0] = 0.0
    data[-1] = 0.0
    return data


# Four deliberately distinct 13-bar families. Near-empty bars are intentional
# comic timing, but the surrounding anchors preserve the dance pulse.
FINAL_KICKS: tuple[tuple[tuple[float, ...], ...], ...] = (
    (
        (0.0, 2.5), (0.0, 1.75, 3.25), (0.0, 2.75), (0.0, 2.25),
        (0.0, 1.5, 3.0), (0.0, 2.0), (0.0, 2.75), (0.0, 1.75),
        (0.0,), (0.0, 2.5), (0.0, 3.0), (0.0, 1.5, 3.25), (0.0,),
    ),
    (
        (0.0, 1.5, 3.0), (0.0, 2.75), (0.0, 2.0), (0.0, 1.75, 3.5),
        (0.0, 2.5), (0.0, 1.5), (0.0, 3.0), (2.5,),
        (0.0, 1.75, 3.0), (0.0, 2.25), (0.0, 2.75), (0.0, 1.5), (0.0,),
    ),
    (
        (0.25, 2.75), (0.0, 2.0), (0.25, 1.5, 3.25), (0.0, 2.5),
        (0.25, 2.25), (0.0, 1.75), (0.25, 2.75), (0.0, 2.0, 3.5),
        (0.25, 1.75), (0.0, 2.5), (), (0.0, 1.5, 3.0), (0.0,),
    ),
    (
        (0.0, 3.0), (0.0, 2.5), (0.0, 1.5, 3.0), (0.0, 2.75),
        (0.0, 1.75, 3.25), (0.0, 2.0), (0.0, 2.5), (0.0, 1.5, 3.0),
        (0.0, 2.75), (0.0, 1.75, 3.25), (0.0, 3.0), (), (0.0,),
    ),
)


def kick_pattern(phrase: int, local: int, refined: bool) -> tuple[float, ...]:
    if refined:
        return FINAL_KICKS[phrase][local]
    return (0.0, 2.5) if local < IMPULSE_BARS else (0.0, 2.75)


def clap_pattern(phrase: int, local: int, refined: bool) -> tuple[float, ...]:
    if not refined:
        return (1.0, 3.0) if local < IMPULSE_BARS else (1.25, 3.0)
    if local == 12:
        return ()
    families = (
        (1.0, 3.0) if local < 6 else ((1.25, 3.25) if local != 8 else ()),
        (0.75, 2.75) if local < 6 else ((1.5, 3.0) if local != 7 else (3.5,)),
        (1.25, 3.25) if local < 6 else ((0.75, 2.75) if local != 10 else (2.0,)),
        (1.0,) if local < 3 else ((1.0, 3.0) if local < 10 else (2.0,)),
    )
    value = families[phrase]
    return tuple(value)


def click_pattern(phrase: int, local: int, refined: bool) -> tuple[float, ...]:
    if not refined:
        return (0.75, 1.75, 3.5)
    patterns = (
        ((0.75, 1.75, 3.5), (0.5, 2.25), (), (1.5, 3.25)),
        ((0.5, 2.0, 3.5), (1.25, 2.75), (3.25,), (0.75, 2.5)),
        ((1.0, 2.25, 3.75), (0.5, 1.5), (3.25,), (1.25, 2.75)),
        ((0.75, 2.75), (0.5, 1.5, 3.25), (2.25,), (1.0, 3.0)),
    )
    if local in {5, 12}:
        return (1.25,) if local == 5 else ()
    choice = (local + (0 if local < 6 else 1)) % 4
    # One absurd response pause per phrase is encoded as a nearly empty cell.
    if (phrase, local) in {(0, 8), (1, 7), (2, 10), (3, 11)}:
        return ()
    return patterns[phrase][choice]


def brass_plan(phrase: int, local: int, refined: bool) -> tuple[tuple[float, str, bool], ...]:
    if not refined:
        if local in {1, 4, 7, 10}:
            return ((1.5, "low", local >= 6), (3.25, "high", local >= 6))
        return ()
    plans: tuple[dict[int, tuple[tuple[float, str, bool], ...]], ...] = (
        {1: ((1.50, "low", False),), 4: ((3.00, "high", False),), 7: ((0.75, "high", True),), 10: ((2.75, "low", True),)},
        {0: ((3.25, "high", False),), 3: ((1.25, "low", False),), 8: ((2.50, "low", True),), 11: ((0.75, "high", True),)},
        {2: ((0.75, "low", False),), 5: ((1.75, "high", False),), 6: ((3.00, "high", True),), 9: ((1.25, "low", True),)},
        {1: ((2.75, "high", False),), 4: ((0.75, "low", False),), 7: ((3.25, "low", True),), 10: ((1.50, "high", True),)},
    )
    return plans[phrase].get(local, ())


def render(pass_name: str) -> tuple[np.ndarray, dict[str, Any]]:
    config = PASS_CONFIGS[pass_name]
    refined = bool(config["refined"])
    base = np.zeros((TOTAL_FRAMES, 2), dtype=np.float32)
    groove = np.zeros_like(base)
    color = np.zeros_like(base)
    base_rng = rng_for(SEED, f"{pass_name}:base")
    groove_rng = rng_for(SEED, f"{pass_name}:groove")
    counts = {"kick": 0, "rubberPluck": 0, "noiseClap": 0, "plasticClick": 0, "hat": 0, "mutedBrass": 0}
    phrase_counts: list[dict[str, int]] = [dict.fromkeys(counts, 0) for _ in range(4)]

    for bar in range(BARS):
        phrase = bar // PHRASE_BARS
        local = bar % PHRASE_BARS
        impulse = local < IMPULSE_BARS
        kicks = kick_pattern(phrase, local, refined)
        for index, offset in enumerate(kicks):
            kick = synth_kick(base_rng, bar + index)
            add_event(base, kick, bar, offset, gain=0.85 if index == 0 else 0.69)
            counts["kick"] += 1
            phrase_counts[phrase]["kick"] += 1
            wants_pluck = bool(config["pluckEveryKick"]) or index == 0
            if refined and local in {5, 12} and index > 0:
                wants_pluck = False
            if wants_pluck:
                pluck = synth_rubber_pluck(float(config["pluckDuration"]), bar + index, index == 0)
                add_event(base, pluck, bar, offset, gain=0.72 if index == 0 else 0.48)
                counts["rubberPluck"] += 1
                phrase_counts[phrase]["rubberPluck"] += 1

        claps = clap_pattern(phrase, local, refined)
        for index, offset in enumerate(claps):
            clap = synth_noise_clap(groove_rng, bar + index, accent=index == 0 and not impulse)
            width = float(config["panWidth"])
            pan = (-width if (bar + index) % 2 == 0 else width)
            add_event(groove, clap, bar, offset, gain=0.65 if index == 0 else 0.50, pan=pan)
            counts["noiseClap"] += 1
            phrase_counts[phrase]["noiseClap"] += 1

        clicks = click_pattern(phrase, local, refined)
        for index, offset in enumerate(clicks):
            click = synth_plastic_click(groove_rng, bar * 3 + index, double=(index == len(clicks) - 1 and local % 4 == 2))
            width = float(config["panWidth"])
            pan = (-width, 0.0, width)[index % 3]
            add_event(groove, click, bar, offset, gain=float(config["clickGain"]), pan=pan)
            counts["plasticClick"] += 1
            phrase_counts[phrase]["plasticClick"] += 1

        if local not in {5, 12}:
            hats = (0.5, 1.5, 2.5, 3.5) if not refined else ((0.5, 2.5) if impulse else (1.5, 3.5))
            for index, offset in enumerate(hats):
                if refined and ((bar * 3 + index) % 100) / 100.0 > float(config["hatDensity"]):
                    continue
                hat = synth_hat(groove_rng, bar + index, open_hat=(not impulse and index == len(hats) - 1 and local % 3 == 1))
                width = float(config["panWidth"])
                add_event(groove, hat, bar, offset, gain=0.31 if not refined else 0.25, pan=(-width if index % 2 == 0 else width))
                counts["hat"] += 1
                phrase_counts[phrase]["hat"] += 1

        for event_index, (offset, register, answer) in enumerate(brass_plan(phrase, local, refined)):
            brass = synth_muted_brass(register, answer, float(config["brassCutoff"]), bar + event_index)
            width = float(config["panWidth"]) * 0.75
            pan = width if answer else -width
            add_event(color, brass, bar, offset, gain=float(config["brassGain"]), pan=pan)
            counts["mutedBrass"] += 1
            phrase_counts[phrase]["mutedBrass"] += 1

    mix = base * np.float32(0.92) + groove * np.float32(0.91) + color * np.float32(0.82)
    mix = highpass(mix, 24.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix, float(config["masterDrive"]))
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    mix = normalize_loudness(mix, SAMPLE_RATE, -16.08, -1.38).astype(np.float32)
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    # Damped pluck cycles are not mathematically mean-free over finite tails.
    # Remove their tiny aggregate bias while retaining digital-zero endpoints.
    mix = remove_dc_preserving_loop_endpoints(mix)
    if mix.shape != (TOTAL_FRAMES, 2):
        raise RuntimeError(f"unexpected render shape: {mix.shape}")
    diagnostics = {
        "pass": pass_name,
        "config": config,
        "eventCounts": counts,
        "eventCountsByMacrophrase": phrase_counts,
        "density": density_analysis(mix),
        "spectrum": band_analysis(mix),
        "monoCompatibility": mono_analysis(mix),
        "floatMetrics": measure_audio(mix, SAMPLE_RATE, include_true_peak=True),
    }
    return mix, diagnostics


def density_analysis(audio: np.ndarray) -> dict[str, Any]:
    amplitude = np.max(np.abs(audio), axis=1)
    phrase_frames = [beat_frame(index * PHRASE_BARS * BEATS_PER_BAR) for index in range(5)]
    phrase_ratios = []
    for index in range(4):
        section = amplitude[phrase_frames[index] : phrase_frames[index + 1]]
        phrase_ratios.append(round(float(np.mean(section > 10.0 ** (-45.0 / 20.0))), 6))
    return {
        "activeFrameRatioAboveMinus45Dbfs": round(float(np.mean(amplitude > 10.0 ** (-45.0 / 20.0))), 6),
        "quietFrameRatioBelowMinus60Dbfs": round(float(np.mean(amplitude < 10.0 ** (-60.0 / 20.0))), 6),
        "activeRatiosByMacrophrase": phrase_ratios,
    }


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
        "monoPeakDbfs": round(amp_to_db(float(np.max(np.abs(mid), initial=0.0))), 4),
        "monoRmsDbfs": round(amp_to_db(mid_rms), 4),
        "passed": correlation > 0.0 and side_rms < mid_rms,
    }


def band_analysis(audio: np.ndarray) -> dict[str, Any]:
    mono = np.mean(audio.astype(np.float64), axis=1)
    block = 65_536
    starts = np.linspace(0, len(mono) - block, 24, dtype=int)
    window = np.hanning(block)
    frequencies = np.fft.rfftfreq(block, 1.0 / SAMPLE_RATE)
    power = np.zeros_like(frequencies)
    for start in starts:
        power += np.abs(np.fft.rfft(mono[start : start + block] * window)) ** 2
    ranges = {
        "sub_25_90_hz": (25.0, 90.0),
        "low_90_250_hz": (90.0, 250.0),
        "mid_250_2000_hz": (250.0, 2_000.0),
        "presence_2000_8000_hz": (2_000.0, 8_000.0),
        "air_8000_20000_hz": (8_000.0, 20_000.0),
    }
    total = float(np.sum(power[(frequencies >= 25.0) & (frequencies < 20_000.0)]))
    values: dict[str, float] = {}
    for label, (low, high) in ranges.items():
        value = float(np.sum(power[(frequencies >= low) & (frequencies < high)]))
        values[label] = round(10.0 * math.log10(max(value / max(total, 1.0e-30), 1.0e-30)), 4)
    return {"relativePowerDb": values, "fftBlocks": len(starts), "fftSize": block}


def array_sha256(audio: np.ndarray) -> str:
    return hashlib.sha256(np.asarray(audio, dtype="<f4").tobytes(order="C")).hexdigest()


def validate_file(metrics: dict[str, Any], *, runtime: bool) -> list[str]:
    label = "runtime" if runtime else "master"
    failures: list[str] = []
    if metrics["frames"] != TOTAL_FRAMES:
        failures.append(f"{label}: frames {metrics['frames']} != {TOTAL_FRAMES}")
    if metrics["channels"] != 2:
        failures.append(f"{label}: channels {metrics['channels']} != 2")
    if metrics["sampleRate"] != SAMPLE_RATE:
        failures.append(f"{label}: sample rate {metrics['sampleRate']} != {SAMPLE_RATE}")
    if metrics["integratedLufs"] is None or abs(float(metrics["integratedLufs"]) + 16.0) > 0.35:
        failures.append(f"{label}: loudness {metrics['integratedLufs']} outside -16 ±0.35 LUFS")
    if metrics["truePeakDbtp"] is None or float(metrics["truePeakDbtp"]) > -1.0:
        failures.append(f"{label}: true peak {metrics['truePeakDbtp']} > -1 dBTP")
    if max(abs(float(value)) for value in metrics["dcOffset"]) >= 1.0e-4:
        failures.append(f"{label}: DC offset {metrics['dcOffset']} >= 1e-4")
    if float(metrics["samplePeakDbfs"]) >= 0.0:
        failures.append(f"{label}: sample peak indicates clipping")
    return failures


def seam_analysis(path: Path) -> dict[str, Any]:
    audio, _ = sf.read(path, dtype="float32", always_2d=True)
    return {
        "taperFrames": TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(audio[0]), initial=0.0)), 10),
        "lastFrameAbsMax": round(float(np.max(np.abs(audio[-1]), initial=0.0)), 10),
        "decodedSeamDeltaDbfs": round(amp_to_db(float(np.max(np.abs(audio[0] - audio[-1]), initial=0.0))), 4),
        "first1024PeakDbfs": round(amp_to_db(float(np.max(np.abs(audio[:TAPER_FRAMES]), initial=0.0))), 4),
        "last1024PeakDbfs": round(amp_to_db(float(np.max(np.abs(audio[-TAPER_FRAMES:]), initial=0.0))), 4),
    }


def export(root: Path, audio: np.ndarray) -> None:
    write_master_and_runtime(root, ASSET, audio, SAMPLE_RATE, compression_level=0.72)


def main() -> int:
    print("[guiche-03-67] pass 1/2: renderizando versão inicial", flush=True)
    v1, v1_diagnostics = render("v1")
    v1_hash = array_sha256(v1)
    del v1
    gc.collect()

    print("[guiche-03-67] pass 2/2: refinando groove, pausas, timbre e mono", flush=True)
    final, final_diagnostics = render("v2-final")
    first_float_hash = array_sha256(final)
    export(ROOT, final)
    del final
    gc.collect()

    master_metrics, master_info = measure_file(ROOT / MASTER_PATH, include_true_peak=True)
    runtime_metrics, runtime_info = measure_file(ROOT / RUNTIME_PATH, include_true_peak=True)
    first_master_hash = sha256_file(ROOT / MASTER_PATH)
    first_runtime_hash = sha256_file(ROOT / RUNTIME_PATH)

    print("[guiche-03-67] determinismo: segunda síntese e exportação independentes", flush=True)
    verify_audio, _ = render("v2-final")
    second_float_hash = array_sha256(verify_audio)
    with tempfile.TemporaryDirectory(prefix="guiche-03-67-determinism-") as temp_name:
        temp_root = Path(temp_name)
        export(temp_root, verify_audio)
        second_master_hash = sha256_file(temp_root / MASTER_PATH)
        second_runtime_hash = sha256_file(temp_root / RUNTIME_PATH)
    del verify_audio
    gc.collect()

    determinism = {
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

    failures = validate_file(master_metrics, runtime=False) + validate_file(runtime_metrics, runtime=True)
    if master_info.format != "WAV" or master_info.subtype != "PCM_24":
        failures.append(f"master encoding {master_info.format}/{master_info.subtype} != WAV/PCM_24")
    if runtime_info.format != "OGG" or runtime_info.subtype != "VORBIS":
        failures.append(f"runtime encoding {runtime_info.format}/{runtime_info.subtype} != OGG/VORBIS")
    if not all((determinism["float32Match"], determinism["masterMatch"], determinism["runtimeMatch"])):
        failures.append("second render/export hashes differ")
    master_seam = seam_analysis(ROOT / MASTER_PATH)
    runtime_seam = seam_analysis(ROOT / RUNTIME_PATH)
    if master_seam["firstFrameAbsMax"] > 1.0e-7 or master_seam["lastFrameAbsMax"] > 1.0e-7:
        failures.append("master taper endpoints are not digital zero")
    if runtime_seam["decodedSeamDeltaDbfs"] > -90.0:
        failures.append(f"runtime decoded seam delta {runtime_seam['decodedSeamDeltaDbfs']} dBFS > -90")

    report = {
        "contract": "six-seven-audio-proposal-production-v1",
        "schemaVersion": 1,
        "status": "produced-refined-validated" if not failures else "failed-gates",
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "track": {
            "id": TRACK_ID,
            "title": TITLE,
            "style": "brega funk futurista, abstrato e respeitoso",
            "bpm": BPM,
            "meter": "4/4",
            "tonalCenter": "A / Lá; rubber pluck fixed at A1 or A2",
            "bars": BARS,
            "frames": TOTAL_FRAMES,
            "macroStructure": "4 x 13 bars; each 13 = 6 impulse + 7 response",
            "identity": "short kick, fixed-pitch rubber pluck, noise clap, synthesized plastic clicks, and muted synthetic brass call-response",
            "prohibitions": [
                "cowbell",
                "body percussion",
                "external audio or foley",
                "voice",
                "literal office sounds",
                "regional caricature",
                "recognizable artist, beat, or dance imitation",
                "glissando or spring-tone bass",
            ],
            "externalAudioUsed": False,
        },
        "seed": SEED,
        "paths": {
            "source": SOURCE_PATH.as_posix(),
            "master": MASTER_PATH.as_posix(),
            "runtime": RUNTIME_PATH.as_posix(),
            "report": REPORT_PATH.as_posix(),
        },
        "provenance": {
            "method": "100% deterministic procedural synthesis from oscillators and seeded noise",
            "externalAudioRead": False,
            "generativeModelUsed": False,
            "sourceSha256": sha256_file(ROOT / SOURCE_PATH),
            "audioCommonSha256": sha256_file(ROOT / "tools/assets/audio_common.py"),
        },
        "refinementHistory": [
            {
                "pass": "v1",
                "rendered": True,
                "float32Sha256": v1_hash,
                "observations": [
                    "one repeated kick/clap/click cell made the four macrophrases too similar",
                    "a rubber pluck on every kick produced excess low-mid occupancy",
                    "bright frequent brass and continuous hats competed with the comic pauses",
                ],
                "diagnostics": v1_diagnostics,
            },
            {
                "pass": "v2-final",
                "rendered": True,
                "changesApplied": [
                    "composition: replaced the repeated cell with four distinct kick, clap, click, and brass call-response families",
                    "negative space: inserted a different near-empty response bar per macrophrase plus stripped sixth/thirteenth-bar landings",
                    "low-end mix: shortened the fixed-pitch rubber pluck from 235 ms to 158 ms and retained it only on anchor kicks",
                    "anti-fatigue mix: reduced hats, darkened brass from 2850 Hz to 1650 Hz, lowered click/brass levels, and narrowed panning",
                    "technical mix: canceled finite-tail channel bias with a zero-at-both-ends correction, preserving the 1024-frame loop taper",
                ],
                "diagnostics": final_diagnostics,
            },
        ],
        "arrangement": {
            "phrase1": "senha impossível: grounded call, clipped answer, and a one-kick pause",
            "phrase2": "guichê deslizante: denser impulse, delayed response, and a beat-2.5 restart",
            "phrase3": "fila reversa: quarter-beat entrances, inverted clap answers, and one kickless bar",
            "phrase4": "fecha e reabre: half-time opening, compressed double-time middle, and a clap-only absurd pause",
        },
        "master": master_metrics,
        "runtime": runtime_metrics,
        "loopBoundary": {"master": master_seam, "runtime": runtime_seam},
        "determinism": determinism,
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
            "requiredTaperFrames": TAPER_FRAMES,
            "failures": failures,
            "passed": not failures,
        },
        "environment": {
            "python": platform.python_version(),
            "numpy": np.__version__,
            "soundfile": sf.__version__,
            "libsndfile": sf.__libsndfile_version__,
        },
    }
    dump_json(ROOT / REPORT_PATH, report)
    if failures:
        raise SystemExit("Audio gates failed:\n- " + "\n- ".join(failures))
    print(json.dumps({
        "title": TITLE,
        "master": master_metrics,
        "runtime": runtime_metrics,
        "determinism": determinism,
        "gatesPassed": True,
    }, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
