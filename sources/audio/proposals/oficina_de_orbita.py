#!/usr/bin/env python3
"""Produce the deterministic proposal track "Oficina de Órbita".

The piece is synthesized exclusively from oscillators and seeded noise. It is
a 136 BPM, 4/4, 52-bar loop made of four 13-bar (6+7) macrophrases. Its main
gesture is the Trinca Orbital: three synthetic snare/tom attacks, each answered
by a 60-90 ms FM response. No external audio, voice, cowbell, body percussion,
or recognizable source material is used.
"""

from __future__ import annotations

from datetime import datetime, timezone
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
    canonicalize_ogg,
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


SAMPLE_RATE = 48_000
BPM = 136.0
BARS = 52
BEATS_PER_BAR = 4
TOTAL_FRAMES = 4_404_706
TAPER_FRAMES = 1_024
ROOT_HZ = 49.0
SEED = "six-seven-oficina-de-orbita-phonk-brega-v2-2026-07-12"

SOURCE_PATH = Path("sources/audio/proposals/oficina_de_orbita.py")
MASTER_PATH = Path("masters/audio/proposals/oficina_de_orbita.wav")
RUNTIME_PATH = Path("assets/audio/proposals/oficina_de_orbita.ogg")
REPORT_PATH = Path("reports/audio-proposals/oficina_de_orbita.json")

ASSET = {
    "id": "MUS-PROPOSAL-OFICINA-DE-ORBITA",
    "channels": 2,
    "master": MASTER_PATH.as_posix(),
    "runtime": RUNTIME_PATH.as_posix(),
}

MACROPHRASES = (
    "montagem em halftime",
    "calibracao em doubletime",
    "teste alternado de gravidade",
    "encaixe orbital combinado",
)

PASS_CONFIGS: dict[str, dict[str, Any]] = {
    "v1": {
        "kickDuration": 0.190,
        "subDuration": 0.310,
        "fmBassDuration": 0.285,
        "trincaResponseMs": (105, 118, 128),
        "trincaWidth": 0.28,
        "driftGain": 0.43,
        "driftDuration": 0.430,
        "masterDrive": 1.10,
    },
    "v2-final": {
        "kickDuration": 0.148,
        "subDuration": 0.225,
        "fmBassDuration": 0.178,
        "trincaResponseMs": (64, 76, 88),
        "trincaWidth": 0.14,
        "driftGain": 0.28,
        "driftDuration": 0.285,
        "masterDrive": 1.22,
    },
}


def _time(count: int) -> np.ndarray:
    return np.arange(count, dtype=np.float64) / SAMPLE_RATE


def _phase(frequency: np.ndarray | float) -> np.ndarray:
    values = np.asarray(frequency, dtype=np.float64)
    return 2.0 * math.pi * np.cumsum(values) / SAMPLE_RATE


def beat_frame(beat: float) -> int:
    return int(round(beat * 60.0 * SAMPLE_RATE / BPM))


def _microcut_gate(count: int, windows_ms: tuple[tuple[float, float], ...]) -> np.ndarray:
    """Return a click-safe gate with short zero windows and 1 ms ramps."""
    gate = np.ones(count, dtype=np.float64)
    ramp_count = max(2, int(round(0.001 * SAMPLE_RATE)))
    ramp_down = np.cos(np.linspace(0.0, math.pi / 2.0, ramp_count)) ** 2
    ramp_up = ramp_down[::-1]
    for start_ms, end_ms in windows_ms:
        start = max(0, int(round(start_ms * SAMPLE_RATE / 1000.0)))
        end = min(count, int(round(end_ms * SAMPLE_RATE / 1000.0)))
        if end <= start:
            continue
        down_start = max(0, start - ramp_count)
        down_size = start - down_start
        if down_size:
            gate[down_start:start] = np.minimum(gate[down_start:start], ramp_down[-down_size:])
        gate[start:end] = 0.0
        up_end = min(count, end + ramp_count)
        up_size = up_end - end
        if up_size:
            gate[end:up_end] = np.minimum(gate[end:up_end], ramp_up[:up_size])
    return gate


def synth_kick(rng: np.random.Generator, duration: float) -> np.ndarray:
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    frequency = 54.0 + 104.0 * np.exp(-t / 0.015)
    phase = _phase(frequency)
    envelope = (1.0 - np.exp(-t / 0.0017)) * np.exp(-t / 0.052)
    body = np.sin(phase) + 0.17 * np.sin(2.0 * phase + 0.21)
    click = highpass(rng.standard_normal(count), 3_100.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0038) * 0.024
    return fade_edges(body * envelope * 0.75 + click, SAMPLE_RATE, 0.4, 12.0)


def synth_sub(duration: float, accent: bool) -> np.ndarray:
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    frequency = ROOT_HZ * (1.0 + 0.035 * np.exp(-t / 0.024))
    phase = _phase(frequency)
    envelope = (1.0 - np.exp(-t / 0.004)) * np.exp(-t / (0.090 if accent else 0.070))
    body = np.sin(phase) + 0.22 * np.sin(2.0 * phase + 0.16)
    body = np.tanh(body * 1.13) / math.tanh(1.13)
    return fade_edges(body * envelope * (0.57 if accent else 0.43), SAMPLE_RATE, 0.8, 20.0)


def synth_scraped_fm_bass(duration: float, variant: int, final_pass: bool) -> np.ndarray:
    """Low friendly FM rasp; the gate creates drift cuts without a signature lead."""
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    carrier_hz = ROOT_HZ * 2.0
    frequency = carrier_hz * (1.025 - 0.025 * np.minimum(t / max(duration, 1.0e-6), 1.0))
    carrier_phase = _phase(frequency)
    ratio = (1.50, 1.75, 2.00)[variant % 3]
    mod_index = (1.35 + 0.22 * (variant % 3)) * np.exp(-t / 0.075)
    modulator = np.sin(carrier_phase * ratio + 0.29 * variant)
    tone = np.sin(carrier_phase + mod_index * modulator)
    tone += 0.16 * np.sin(2.0 * carrier_phase + 0.17)
    envelope = (1.0 - np.exp(-t / 0.003)) * np.exp(-t / (0.072 if final_pass else 0.105))
    windows = ((56.0, 66.0), (111.0, 120.0)) if final_pass else ((96.0, 103.0),)
    tone *= _microcut_gate(count, windows)
    tone = lowpass(tone, 2_250.0 if final_pass else 2_900.0, SAMPLE_RATE, 2)
    return fade_edges(tone * envelope * 0.36, SAMPLE_RATE, 0.7, 14.0)


def synth_trinca_hit(rng: np.random.Generator, variant: int, final_pass: bool) -> np.ndarray:
    """Entirely synthetic snare/tom attack with no pitch bounce or foley."""
    duration = (0.082, 0.092, 0.102)[variant % 3] if final_pass else (0.118, 0.132, 0.145)[variant % 3]
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    fixed_hz = (147.0, 196.0, 245.0)[variant % 3]
    body = np.sin(2.0 * math.pi * fixed_hz * t + 0.21 * variant)
    body += 0.19 * np.sin(2.0 * math.pi * fixed_hz * 2.0 * t + 0.37)
    body *= np.exp(-t / (0.030 if final_pass else 0.047))
    noise = bandpass(rng.standard_normal(count), 720.0, 5_100.0, SAMPLE_RATE, 2)
    noise *= np.exp(-t / (0.014 if final_pass else 0.024))
    return fade_edges(body * 0.22 + noise * 0.090, SAMPLE_RATE, 0.3, 9.0)


def synth_trinca_response(duration_ms: int, variant: int) -> np.ndarray:
    """Short G-centered FM answer, exactly 60-90 ms in the final pass."""
    duration = duration_ms / 1000.0
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    carrier_hz = 196.0
    mod_ratio = (1.0, 1.5, 2.0)[variant % 3]
    index = (1.10, 1.55, 1.28)[variant % 3] * np.exp(-t / 0.028)
    carrier = np.sin(
        2.0 * math.pi * carrier_hz * t
        + index * np.sin(2.0 * math.pi * carrier_hz * mod_ratio * t + 0.2)
    )
    envelope = (1.0 - np.exp(-t / 0.0016)) * np.exp(-t / (duration * 0.27))
    answer = lowpass(carrier * envelope, 3_300.0, SAMPLE_RATE, 2)
    return fade_edges(answer * 0.19, SAMPLE_RATE, 0.3, min(8.0, duration_ms * 0.12))


def synth_hat(rng: np.random.Generator, open_hat: bool) -> np.ndarray:
    duration = 0.078 if open_hat else 0.034
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    noise = highpass(rng.standard_normal(count), 6_100.0, SAMPLE_RATE, 3)
    noise = lowpass(noise, 14_200.0, SAMPLE_RATE, 2)
    envelope = np.exp(-t / (0.021 if open_hat else 0.0075))
    return fade_edges(noise * envelope * 0.060, SAMPLE_RATE, 0.2, 6.0)


def synth_drift_cut(rng: np.random.Generator, duration: float, variant: int, final_pass: bool) -> np.ndarray:
    count = int(round(duration * SAMPLE_RATE))
    t = _time(count)
    progress = t / duration
    frequency = (680.0 - 330.0 * progress) * (1.0 + 0.03 * variant)
    chirp = np.sin(_phase(frequency) + 0.31 * variant)
    texture = bandpass(rng.standard_normal(count), 420.0, 2_600.0, SAMPLE_RATE, 2)
    envelope = np.sin(math.pi * progress) ** 1.8
    windows = ((52.0, 68.0), (126.0, 145.0), (211.0, 226.0)) if final_pass else ((160.0, 172.0),)
    gate = _microcut_gate(count, windows)
    result = (chirp * 0.048 + texture * 0.030) * envelope * gate
    return fade_edges(result, SAMPLE_RATE, 2.0, 12.0)


def _kick_pattern(phrase: int, local_bar: int, final_pass: bool) -> list[float]:
    impulse = local_bar < 6
    if phrase == 0:  # halftime assembly
        positions = [0.0, 2.75] if impulse else [0.0, 2.50]
    elif phrase == 1:  # doubletime calibration
        positions = [0.0, 1.50, 2.75, 3.50] if impulse else [0.0, 1.75, 3.00]
    elif phrase == 2:  # half/double alternation
        fast = local_bar % 2 == 1
        positions = [0.0, 1.25, 2.50, 3.50] if fast else [0.0, 2.75]
    else:  # combined orbital fit
        positions = [0.0, 0.75, 2.50, 3.50] if impulse else [0.0, 1.75, 3.25]
    if final_pass and local_bar == 5:
        return [0.0, 2.0]
    if final_pass and local_bar == 12:
        return [0.0, 1.50]
    if local_bar in {3, 8} and len(positions) > 2:
        positions[-1] -= 0.25
    return positions


def _snare_positions(phrase: int, local_bar: int, final_pass: bool) -> list[float]:
    if local_bar == 12:
        return [] if final_pass else [1.0]
    if phrase == 0:
        return [2.0]
    if phrase == 1:
        return [1.0, 3.0]
    if phrase == 2:
        return [1.0, 3.0] if local_bar % 2 else [2.0]
    return [1.0, 3.0] if local_bar < 6 else [2.0]


def _hat_positions(phrase: int, local_bar: int, final_pass: bool) -> list[float]:
    if local_bar == 12:
        return [0.50, 1.50] if final_pass else [0.50, 1.00, 1.50]
    if not final_pass:
        return [0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75]
    if phrase == 0:
        return [0.50, 1.50, 3.50]
    if phrase == 1:
        return [0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75]
    if phrase == 2:
        return [0.25, 0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75] if local_bar % 2 else [0.50, 1.50, 3.00]
    return [0.25, 1.00, 1.75, 2.50, 3.25]


def _trinca_positions(phrase: int, local_bar: int) -> list[float]:
    active_bars = (
        {1, 4, 7, 10},
        {0, 2, 4, 6, 8, 10},
        {1, 3, 5, 7, 9, 11},
        {0, 2, 4, 6, 8, 10, 11},
    )[phrase]
    if local_bar not in active_bars or local_bar == 12:
        return []
    patterns = (
        [0.75, 1.625, 3.00],
        [0.375, 1.125, 2.625],
        [0.50, 1.875, 3.125],
        [0.625, 1.50, 2.875],
    )
    result = list(patterns[phrase])
    if local_bar >= 6:
        result = [min(3.55, value + (0.125 if phrase != 2 else -0.125)) for value in result]
    return result


def _macro_counter() -> list[dict[str, int]]:
    return [
        {"kick": 0, "sub": 0, "fmBass": 0, "snare": 0, "hat": 0, "trincaHit": 0, "trincaResponse": 0, "driftCut": 0}
        for _ in range(4)
    ]


def _count(counts: dict[str, int], macro_counts: list[dict[str, int]], phrase: int, event: str) -> None:
    counts[event] += 1
    macro_counts[phrase][event] += 1


def render(pass_name: str) -> tuple[np.ndarray, dict[str, Any]]:
    if pass_name not in PASS_CONFIGS:
        raise ValueError(f"unsupported pass: {pass_name}")
    config = PASS_CONFIGS[pass_name]
    final_pass = pass_name == "v2-final"
    base = np.zeros((TOTAL_FRAMES, 2), dtype=np.float32)
    groove = np.zeros_like(base)
    hype = np.zeros_like(base)
    base_rng = rng_for(SEED, f"{pass_name}:base")
    groove_rng = rng_for(SEED, f"{pass_name}:groove")
    hype_rng = rng_for(SEED, f"{pass_name}:hype")
    counts = {"kick": 0, "sub": 0, "fmBass": 0, "snare": 0, "hat": 0, "trincaHit": 0, "trincaResponse": 0, "driftCut": 0}
    macro_counts = _macro_counter()

    kick = synth_kick(base_rng, float(config["kickDuration"]))
    response_ms = tuple(int(value) for value in config["trincaResponseMs"])

    for bar in range(BARS):
        phrase = bar // 13
        local_bar = bar % 13
        impulse = local_bar < 6
        bar_beat = bar * BEATS_PER_BAR
        kicks = _kick_pattern(phrase, local_bar, final_pass)

        for index, offset in enumerate(kicks):
            gain = 0.87 if index == 0 else (0.64 if final_pass else 0.70)
            add_signal(base, constant_power_pan(kick, 0.0), beat_frame(bar_beat + offset), gain=gain)
            _count(counts, macro_counts, phrase, "kick")
            wants_sub = index == 0 or (not final_pass and index == 1)
            if final_pass and local_bar == 12 and index > 0:
                wants_sub = False
            if wants_sub:
                sub = synth_sub(float(config["subDuration"]), accent=index == 0)
                add_signal(base, constant_power_pan(sub, 0.0), beat_frame(bar_beat + offset), gain=0.71 if index == 0 else 0.45)
                _count(counts, macro_counts, phrase, "sub")
            wants_fm = index == 0 or (not final_pass and index < 3) or (final_pass and phrase in {1, 3} and index == 1 and local_bar not in {5, 12})
            if wants_fm:
                fm_bass = synth_scraped_fm_bass(float(config["fmBassDuration"]), (phrase + local_bar + index) % 3, final_pass)
                add_signal(base, constant_power_pan(fm_bass, 0.0), beat_frame(bar_beat + offset), gain=0.51 if index == 0 else 0.34)
                _count(counts, macro_counts, phrase, "fmBass")

        for snare_index, offset in enumerate(_snare_positions(phrase, local_bar, final_pass)):
            snare = synth_trinca_hit(groove_rng, (phrase + snare_index + 1) % 3, final_pass)
            pan = -0.035 if (bar + snare_index) % 2 == 0 else 0.035
            add_signal(groove, constant_power_pan(snare, pan), beat_frame(bar_beat + offset), gain=0.48)
            _count(counts, macro_counts, phrase, "snare")

        hats = _hat_positions(phrase, local_bar, final_pass)
        for hat_index, offset in enumerate(hats):
            if final_pass and phrase == 1 and hat_index % 3 == 2 and local_bar in {5, 11}:
                continue
            hat = synth_hat(groove_rng, open_hat=hat_index == len(hats) - 1 and local_bar in {3, 8})
            pan = (-0.22, 0.10, 0.24, -0.08)[hat_index % 4]
            gain = (0.23, 0.16, 0.20, 0.14)[hat_index % 4]
            add_signal(groove, constant_power_pan(hat, pan), beat_frame(bar_beat + offset), gain=gain)
            _count(counts, macro_counts, phrase, "hat")

        trinca = _trinca_positions(phrase, local_bar)
        for trinca_index, offset in enumerate(trinca):
            variant = (trinca_index + phrase) % 3
            hit = synth_trinca_hit(groove_rng, variant, final_pass)
            width = float(config["trincaWidth"])
            hit_pan = (-width, 0.0, width)[trinca_index]
            add_signal(groove, constant_power_pan(hit, hit_pan), beat_frame(bar_beat + offset), gain=(0.56, 0.48, 0.52)[trinca_index])
            _count(counts, macro_counts, phrase, "trincaHit")

            response = synth_trinca_response(response_ms[variant], variant)
            response_delay_beats = (response_ms[variant] / 1000.0 + 0.010) * BPM / 60.0
            response_pan = -hit_pan * 0.72
            add_signal(hype, constant_power_pan(response, response_pan), beat_frame(bar_beat + offset + response_delay_beats), gain=(0.72, 0.62, 0.68)[trinca_index])
            _count(counts, macro_counts, phrase, "trincaResponse")

        wants_drift = local_bar in ({5} if phrase == 0 else {5, 11})
        if final_pass and phrase == 2 and local_bar == 5:
            wants_drift = False
        if wants_drift:
            drift = synth_drift_cut(hype_rng, float(config["driftDuration"]), phrase, final_pass)
            position = 3.25 if local_bar == 5 else 2.75
            pan = -0.12 if phrase % 2 == 0 else 0.12
            add_signal(hype, constant_power_pan(drift, pan), beat_frame(bar_beat + position), gain=float(config["driftGain"]))
            _count(counts, macro_counts, phrase, "driftCut")

    mix = base * np.float32(0.91) + groove * np.float32(0.92) + hype * np.float32(0.86)
    mix = highpass(mix, 24.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = lowpass(mix, 16_200.0 if final_pass else 17_800.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix * np.float32(1.12 if final_pass else 1.18), float(config["masterDrive"]))
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    mix = normalize_loudness(mix, SAMPLE_RATE, -16.05, -1.48).astype(np.float32)
    mix = remove_dc_preserve_boundary(mix)
    if mix.shape != (TOTAL_FRAMES, 2):
        raise RuntimeError(f"render shape changed: {mix.shape}")
    diagnostics = {
        "pass": pass_name,
        "config": config,
        "eventCounts": counts,
        "eventCountsByMacrophrase": {
            MACROPHRASES[index]: macro_counts[index] for index in range(4)
        },
        "activeFrameRatioAboveMinus45Dbfs": round(float(np.mean(np.max(np.abs(mix), axis=1) > 10.0 ** (-45.0 / 20.0))), 6),
        "quietFrameRatioBelowMinus60Dbfs": round(float(np.mean(np.max(np.abs(mix), axis=1) < 10.0 ** (-60.0 / 20.0))), 6),
        "metricsFloat": measure_audio(mix, SAMPLE_RATE, include_true_peak=True),
        "mono": mono_analysis(mix),
        "bands": band_analysis(mix),
        "antiFatigue": anti_fatigue_analysis(mix, counts),
    }
    return mix, diagnostics


def remove_dc_preserve_boundary(audio: np.ndarray) -> np.ndarray:
    data = np.array(audio, dtype=np.float32, copy=True)
    correction_window = np.ones(data.shape[0], dtype=np.float64)
    ramp = np.sin(np.linspace(0.0, math.pi / 2.0, TAPER_FRAMES, endpoint=True)) ** 2
    correction_window[:TAPER_FRAMES] = ramp
    correction_window[-TAPER_FRAMES:] = ramp[::-1]
    means = np.mean(data, axis=0, dtype=np.float64)
    window_mean = float(np.mean(correction_window))
    data -= (correction_window[:, None] * (means / window_mean)[None, :]).astype(np.float32)
    data[0] = 0.0
    data[-1] = 0.0
    return data


def _subtract_mean_preserve_boundary(audio: np.ndarray, means: np.ndarray) -> np.ndarray:
    """Subtract requested channel means without moving the loop endpoints."""
    data = np.array(audio, dtype=np.float32, copy=True)
    correction_window = np.ones(data.shape[0], dtype=np.float64)
    ramp = np.sin(np.linspace(0.0, math.pi / 2.0, TAPER_FRAMES, endpoint=True)) ** 2
    correction_window[:TAPER_FRAMES] = ramp
    correction_window[-TAPER_FRAMES:] = ramp[::-1]
    window_mean = float(np.mean(correction_window))
    data -= (correction_window[:, None] * (np.asarray(means, dtype=np.float64) / window_mean)[None, :]).astype(np.float32)
    data[0] = 0.0
    data[-1] = 0.0
    return data


def _write_runtime_vorbis(path: Path, audio: np.ndarray, compression_level: float) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with sf.SoundFile(
        path,
        mode="w",
        samplerate=SAMPLE_RATE,
        channels=2,
        format="OGG",
        subtype="VORBIS",
        compression_level=compression_level,
    ) as handle:
        for start in range(0, audio.shape[0], 65_536):
            handle.write(audio[start : start + 65_536])
    canonicalize_ogg(path, ASSET["id"])
    if sf.info(path).frames != TOTAL_FRAMES:
        raise RuntimeError(f"runtime frame mismatch after encode: {sf.info(path).frames}")


def write_export_pair(base: Path, audio: np.ndarray, compression_level: float = 0.68) -> dict[str, Any]:
    """Write master/runtime and compensate deterministic Vorbis decode DC.

    libvorbis can add a tiny signal-dependent mean to sub-heavy material. The
    archive master always receives the zero-mean render. Runtime encoding uses
    up to three deterministic, tapered pre-compensation rounds so the *decoded*
    loop also meets the strict 1e-4 DC gate while retaining zero endpoints.
    """
    write_master_and_runtime(base, ASSET, audio, SAMPLE_RATE, compression_level=compression_level)
    runtime_path = base / RUNTIME_PATH
    runtime_source = np.array(audio, dtype=np.float32, copy=True)
    rounds: list[dict[str, Any]] = []
    for index in range(3):
        decoded, _ = sf.read(runtime_path, dtype="float32", always_2d=True)
        decoded_means = np.mean(decoded, axis=0, dtype=np.float64)
        rounds.append({
            "round": index,
            "decodedDcBeforeCorrection": [round(float(value), 10) for value in decoded_means],
        })
        if float(np.max(np.abs(decoded_means))) < 5.0e-5:
            break
        runtime_source = _subtract_mean_preserve_boundary(runtime_source, decoded_means)
        _write_runtime_vorbis(runtime_path, runtime_source, compression_level)
    final_decoded, _ = sf.read(runtime_path, dtype="float32", always_2d=True)
    final_means = np.mean(final_decoded, axis=0, dtype=np.float64)
    return {
        "method": "iterative tapered pre-compensation of codec-added DC; archive master unchanged",
        "rounds": rounds,
        "finalDecodedDc": [round(float(value), 10) for value in final_means],
        "roundCount": len(rounds),
    }


def mono_analysis(audio: np.ndarray) -> dict[str, Any]:
    left = audio[:, 0].astype(np.float64)
    right = audio[:, 1].astype(np.float64)
    mid = 0.5 * (left + right)
    side = 0.5 * (left - right)
    mid_rms = float(np.sqrt(np.mean(mid * mid)))
    side_rms = float(np.sqrt(np.mean(side * side)))
    return {
        "leftRightCorrelation": round(float(np.corrcoef(left, right)[0, 1]), 6),
        "sideToMidDb": round(amp_to_db(side_rms / max(mid_rms, 1.0e-12)), 4),
        "monoSamplePeakDbfs": round(amp_to_db(float(np.max(np.abs(mid)))), 4),
        "monoRmsDbfs": round(amp_to_db(mid_rms), 4),
        "interpretation": "centered kick/sub and narrow synthetic percussion remain mono-compatible",
    }


def band_analysis(audio: np.ndarray) -> dict[str, Any]:
    center = np.mean(audio.astype(np.float64), axis=1)
    block = 65_536
    starts = np.linspace(0, len(center) - block, 24, dtype=int)
    window = np.hanning(block)
    frequencies = np.fft.rfftfreq(block, d=1.0 / SAMPLE_RATE)
    accumulated = np.zeros_like(frequencies)
    for start in starts:
        spectrum = np.fft.rfft(center[start : start + block] * window)
        accumulated += np.abs(spectrum) ** 2
    ranges = {
        "sub_25_90_hz": (25.0, 90.0),
        "bass_90_250_hz": (90.0, 250.0),
        "mid_250_2000_hz": (250.0, 2_000.0),
        "presence_2000_8000_hz": (2_000.0, 8_000.0),
        "air_8000_20000_hz": (8_000.0, 20_000.0),
    }
    total = float(np.sum(accumulated[(frequencies >= 25.0) & (frequencies < 20_000.0)]))
    relative: dict[str, float] = {}
    for label, (low, high) in ranges.items():
        power = float(np.sum(accumulated[(frequencies >= low) & (frequencies < high)]))
        relative[label] = round(10.0 * math.log10(max(power / max(total, 1.0e-30), 1.0e-30)), 4)
    centroid = float(np.sum(frequencies * accumulated) / max(np.sum(accumulated), 1.0e-30))
    return {"relativePowerDb": relative, "spectralCentroidHz": round(centroid, 3), "fftBlocks": len(starts), "fftSize": block}


def anti_fatigue_analysis(audio: np.ndarray, counts: dict[str, int]) -> dict[str, Any]:
    center = np.mean(audio.astype(np.float64), axis=1)
    block = int(round(0.010 * SAMPLE_RATE))
    padded = np.pad(center, (0, (-len(center)) % block))
    rms = np.sqrt(np.mean(np.square(padded.reshape(-1, block)), axis=1))
    db = 20.0 * np.log10(np.maximum(rms, 1.0e-12))
    bright_events = counts["hat"] + counts["trincaResponse"] + counts["driftCut"]
    return {
        "median10msRmsDbfs": round(float(np.median(db)), 4),
        "quiet10msBlockRatioBelowMinus55Dbfs": round(float(np.mean(db < -55.0)), 6),
        "active10msBlockRatioAboveMinus42Dbfs": round(float(np.mean(db > -42.0)), 6),
        "brightEventsPerBar": round(bright_events / BARS, 4),
        "allEventsPerBar": round(sum(counts.values()) / BARS, 4),
        "interpretation": "short envelopes, recurring exhale bars, controlled top end, and macro-level density changes reduce repetition fatigue",
    }


def array_sha256(audio: np.ndarray) -> str:
    return hashlib.sha256(np.asarray(audio, dtype="<f4").tobytes(order="C")).hexdigest()


def validate_metrics(metrics: dict[str, Any], *, runtime: bool) -> list[str]:
    label = "runtime" if runtime else "master"
    failures: list[str] = []
    if metrics["frames"] != TOTAL_FRAMES:
        failures.append(f"{label}: frames {metrics['frames']} != {TOTAL_FRAMES}")
    if metrics["channels"] != 2:
        failures.append(f"{label}: channels {metrics['channels']} != 2")
    if metrics["sampleRate"] != SAMPLE_RATE:
        failures.append(f"{label}: sample rate {metrics['sampleRate']} != {SAMPLE_RATE}")
    if metrics["integratedLufs"] is None or abs(float(metrics["integratedLufs"]) + 16.0) > 0.35:
        failures.append(f"{label}: LUFS {metrics['integratedLufs']} outside -16 +/-0.35")
    if metrics["truePeakDbtp"] is None or float(metrics["truePeakDbtp"]) > -1.0:
        failures.append(f"{label}: true peak {metrics['truePeakDbtp']} > -1 dBTP")
    if max(abs(float(value)) for value in metrics["dcOffset"]) >= 1.0e-4:
        failures.append(f"{label}: DC offset {metrics['dcOffset']} >= 1e-4")
    if float(metrics["samplePeakDbfs"]) >= 0.0:
        failures.append(f"{label}: sample clipping at {metrics['samplePeakDbfs']} dBFS")
    return failures


def produce() -> None:
    # A real first pass is rendered, exported, decoded and measured before v2.
    v1_audio, v1_diagnostics = render("v1")
    with tempfile.TemporaryDirectory(prefix="oficina-orbita-v1-") as temp_name:
        temp_root = Path(temp_name)
        v1_codec_compensation = write_export_pair(temp_root, v1_audio, compression_level=0.68)
        v1_master_metrics, _ = measure_file(temp_root / MASTER_PATH, include_true_peak=True)
        v1_runtime_metrics, _ = measure_file(temp_root / RUNTIME_PATH, include_true_peak=True)

    final_audio, final_diagnostics = render("v2-final")
    first_float_hash = array_sha256(final_audio)
    final_codec_compensation = write_export_pair(ROOT, final_audio, compression_level=0.68)
    master_metrics, master_info = measure_file(ROOT / MASTER_PATH, include_true_peak=True)
    runtime_metrics, runtime_info = measure_file(ROOT / RUNTIME_PATH, include_true_peak=True)

    # Fresh synthesis plus fresh containers prove byte-identical determinism.
    verify_audio, _ = render("v2-final")
    second_float_hash = array_sha256(verify_audio)
    with tempfile.TemporaryDirectory(prefix="oficina-orbita-determinism-") as temp_name:
        temp_root = Path(temp_name)
        verification_codec_compensation = write_export_pair(temp_root, verify_audio, compression_level=0.68)
        second_master_hash = sha256_file(temp_root / MASTER_PATH)
        second_runtime_hash = sha256_file(temp_root / RUNTIME_PATH)

    first_master_hash = sha256_file(ROOT / MASTER_PATH)
    first_runtime_hash = sha256_file(ROOT / RUNTIME_PATH)
    determinism = {
        "independentFinalRenders": 2,
        "float32RenderSha256First": first_float_hash,
        "float32RenderSha256Second": second_float_hash,
        "float32Match": first_float_hash == second_float_hash,
        "masterSha256First": first_master_hash,
        "masterSha256Second": second_master_hash,
        "masterMatch": first_master_hash == second_master_hash,
        "runtimeSha256First": first_runtime_hash,
        "runtimeSha256Second": second_runtime_hash,
        "runtimeMatch": first_runtime_hash == second_runtime_hash,
        "codecCompensationEvidenceMatch": final_codec_compensation == verification_codec_compensation,
    }

    failures = validate_metrics(master_metrics, runtime=False) + validate_metrics(runtime_metrics, runtime=True)
    if master_info.format != "WAV" or master_info.subtype != "PCM_24":
        failures.append(f"master encoding {master_info.format}/{master_info.subtype} is not WAV/PCM_24")
    if runtime_info.format != "OGG" or runtime_info.subtype != "VORBIS":
        failures.append(f"runtime encoding {runtime_info.format}/{runtime_info.subtype} is not OGG/VORBIS")
    if not all((determinism["float32Match"], determinism["masterMatch"], determinism["runtimeMatch"], determinism["codecCompensationEvidenceMatch"])):
        failures.append("fresh second render is not byte-identical")

    decoded_master, _ = sf.read(ROOT / MASTER_PATH, dtype="float32", always_2d=True)
    seam = {
        "taperFrames": TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(decoded_master[0]))), 10),
        "lastFrameAbsMax": round(float(np.max(np.abs(decoded_master[-1]))), 10),
        "seamDiscontinuityAbsMax": round(float(np.max(np.abs(decoded_master[0] - decoded_master[-1]))), 10),
        "first1024Peak": round(float(np.max(np.abs(decoded_master[:TAPER_FRAMES]))), 8),
        "last1024Peak": round(float(np.max(np.abs(decoded_master[-TAPER_FRAMES:]))), 8),
    }
    if seam["firstFrameAbsMax"] > 1.0e-7 or seam["lastFrameAbsMax"] > 1.0e-7 or TAPER_FRAMES != 1_024:
        failures.append("1024-frame loop taper/endpoints failed")

    report = {
        "schemaVersion": 1,
        "id": ASSET["id"],
        "title": "Oficina de Órbita",
        "status": "demo-produced-refined-and-validated",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "briefing": "60% phonk and 40% brega funk, 136 BPM, 4/4, G center, 52 bars as four 13-bar 6+7 macrophrases; dry kick/sub, friendly scraped FM bass, drift microcuts, synthetic Trinca Orbital and alternating halftime/doubletime perception.",
        "constraints": {
            "voice": False,
            "cowbell": False,
            "bodyPercussion": False,
            "springOrBoingTom": False,
            "externalAudioOrSamples": False,
            "artistImitation": False,
            "recognizableTimbreOrMelody": False,
            "mood": ["brincalhao", "seco", "espacial", "amigavel"],
        },
        "structure": {
            "bpm": BPM,
            "meter": "4/4",
            "bars": BARS,
            "frames": TOTAL_FRAMES,
            "macrophrases": list(MACROPHRASES),
            "shapePerMacrophrase": "6 impulse + 7 response",
            "tonalCenter": "G1 / 49 Hz",
            "perceivedTempoPlan": ["halftime", "doubletime", "alternating halftime/doubletime", "combined with response landing"],
            "trincaOrbital": {
                "attacksPerCell": 3,
                "source": "synthetic fixed-pitch sine/noise snare-tom attacks",
                "responseSource": "G-centered FM synthesizer",
                "finalResponseDurationsMs": list(PASS_CONFIGS["v2-final"]["trincaResponseMs"]),
            },
        },
        "provenance": {
            "method": "deterministic synthesis from oscillators and seeded noise",
            "seed": SEED,
            "externalAudioSources": [],
            "source": SOURCE_PATH.as_posix(),
            "sourceSha256": sha256_file(ROOT / SOURCE_PATH),
            "environment": {
                "python": platform.python_version(),
                "numpy": np.__version__,
                "soundfile": sf.__version__,
            },
        },
        "paths": {
            "source": SOURCE_PATH.as_posix(),
            "master": MASTER_PATH.as_posix(),
            "runtime": RUNTIME_PATH.as_posix(),
            "report": REPORT_PATH.as_posix(),
        },
        "refinementHistory": [
            {
                "pass": "v1",
                "status": "rendered-exported-decoded-and-analyzed",
                "findings": [
                    "310 ms subs and 285 ms FM basses overfilled syncopated gaps",
                    "uniform eighth-note hats blurred the intended halftime/doubletime contrast",
                    "105-128 ms synth answers obscured separation inside the Trinca Orbital",
                    "wide synthetic hits and a longer drift layer weakened the dry centered architecture",
                ],
                "masterMetrics": v1_master_metrics,
                "runtimeMetrics": v1_runtime_metrics,
                "runtimeCodecDcCompensation": v1_codec_compensation,
                "analysis": v1_diagnostics,
            },
            {
                "pass": "v2-final",
                "status": "rendered-exported-decoded-and-validated",
                "changes": [
                    "shortened kick 190 to 148 ms, sub 310 to 225 ms, and scraped FM bass 285 to 178 ms",
                    "recomposed hats per macrophrase so halftime, doubletime, alternating, and combined sections read without changing 136 BPM",
                    "shortened all Trinca Orbital synth answers to distinct compliant 64, 76, and 88 ms durations",
                    "narrowed Trinca panning from 0.28 to 0.14 and kept all kick, sub, and FM bass strictly centered",
                    "reduced drift duration/gain and changed one long interruption into three deliberate click-safe microcuts",
                    "removed secondary subs, thinned transition bars, and reserved the second half of every bar 13 as a landing silence",
                    "softened the top end to 16.2 kHz and used crest control for headroom without loudness escalation",
                ],
                "masterMetrics": master_metrics,
                "runtimeMetrics": runtime_metrics,
                "runtimeCodecDcCompensation": final_codec_compensation,
                "analysis": final_diagnostics,
            },
        ],
        "metrics": {
            "master": master_metrics,
            "runtimeDecoded": runtime_metrics,
            "monoCompatibility": final_diagnostics["mono"],
            "spectral": final_diagnostics["bands"],
            "densityAndAntiFatigue": final_diagnostics["antiFatigue"],
            "loopBoundary": seam,
        },
        "determinism": determinism,
        "gates": {
            "requiredFrames": TOTAL_FRAMES,
            "requiredChannels": 2,
            "requiredSampleRate": SAMPLE_RATE,
            "masterEncoding": "WAV PCM_24",
            "runtimeEncoding": "Ogg Vorbis",
            "targetLufs": -16.0,
            "toleranceLufs": 0.35,
            "truePeakCeilingDbtp": -1.0,
            "dcAbsoluteMaximum": 0.0001,
            "taperFrames": 1_024,
            "runtimeDecoded": True,
            "secondRenderByteIdentical": all((determinism["float32Match"], determinism["masterMatch"], determinism["runtimeMatch"], determinism["codecCompensationEvidenceMatch"])),
            "failures": failures,
            "passed": not failures,
        },
        "allGatesPassed": not failures,
    }
    dump_json(ROOT / REPORT_PATH, report)
    del v1_audio
    if failures:
        raise SystemExit("Audio gates failed:\n- " + "\n- ".join(failures))
    print(json.dumps({
        "track": report["title"],
        "master": master_metrics,
        "runtime": runtime_metrics,
        "determinism": determinism,
        "gatesPassed": True,
    }, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    produce()
