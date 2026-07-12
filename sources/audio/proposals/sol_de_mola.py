#!/usr/bin/env python3
"""Produce and validate the deterministic Sol de Mola proposal.

The track is built entirely from oscillators and seeded noise. No samples,
recordings, model output, or external audio are read. The default command runs
an actual v1 -> analysis -> refined v2 pipeline, writes the final PCM24/Vorbis
artifacts, verifies a second render byte-for-byte, and records the evidence.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
from importlib.metadata import version as package_version
import json
import math
from pathlib import Path
import platform
import sys
import tempfile
from typing import Any

import numpy as np
import soundfile as sf
from scipy import signal


ROOT = Path(__file__).resolve().parents[3]
TOOLS = ROOT / "tools" / "assets"
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from audio_common import (  # noqa: E402
    add_signal,
    amp_to_db,
    as_2d,
    bandpass,
    constant_power_pan,
    dump_json,
    fade_edges,
    highpass,
    integrated_lufs,
    lowpass,
    measure_audio,
    measure_file,
    normalize_loudness,
    rng_for,
    sha256_file,
    soft_clip,
    taper_loop_boundary,
    true_peak,
    write_master_and_runtime,
)


TRACK_ID = "SOL-DE-MOLA"
TITLE = "Sol de Mola"
STYLE = "brega funk abstrato"
MASTER_SEED = "six-seven-sol-de-mola-production-v2"
SAMPLE_RATE = 48_000
BPM = 136.0
BARS = 52
BEATS_PER_BAR = 4
PHRASE_BARS = 13
IMPULSE_BARS = 6
LOOP_FRAMES = round(BARS * BEATS_PER_BAR * 60.0 * SAMPLE_RATE / BPM)
TAPER_FRAMES = 1_024
TARGET_LUFS = -16.0
TRUE_PEAK_CEILING_DBTP = -1.6

MASTER_REL = Path("masters/audio/proposals/sol_de_mola.wav")
RUNTIME_REL = Path("assets/audio/proposals/sol_de_mola.ogg")
REPORT_REL = Path("reports/audio-proposals/sol_de_mola.json")

NOTE_FREQUENCIES = {
    "A": 220.000000,
    "C": 261.625565,
    "Eb": 311.126984,
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
    """Short round kick, tuned to settle around A1."""
    duration = 0.165 + 0.006 * (variant % 3)
    count = frames(duration)
    t = time_axis(count)
    frequency = 55.0 + (105.0 + 7.0 * (variant % 2)) * np.exp(-t / 0.018)
    phase = phase_from_frequency(frequency)
    envelope = (1.0 - np.exp(-t / 0.0018)) * np.exp(-t / 0.067)
    body = np.sin(phase) + 0.16 * np.sin(2.0 * phase + 0.22)
    click = highpass(rng.standard_normal(count), 2_100.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0042) * 0.030
    return fade_edges(body * envelope * 0.76 + click, SAMPLE_RATE, 0.4, 13.0)


def synth_spring_sub(variant: int, duration: float = 0.34) -> np.ndarray:
    """A1 sub whose pitch visibly dips, rebounds, then settles."""
    count = frames(duration)
    t = time_axis(count)
    dip = -0.145 * np.exp(-np.square((t - 0.034) / 0.019))
    rebound = 0.075 * np.exp(-np.square((t - 0.086) / 0.030))
    initial = (0.052 + 0.006 * (variant % 2)) * np.exp(-t / 0.014)
    frequency = 55.0 * (1.0 + initial + dip + rebound)
    phase = phase_from_frequency(frequency)
    envelope = (1.0 - np.exp(-t / 0.005)) * np.exp(-t / (0.132 + 0.008 * (variant % 3)))
    body = np.sin(phase) + 0.19 * np.sin(2.0 * phase + 0.26)
    return fade_edges(body * envelope * 0.53, SAMPLE_RATE, 1.0, 28.0)


def synth_palm(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Synthesized muted-palm illusion: resonators plus noise only."""
    duration = 0.115 + 0.006 * (variant % 2)
    count = frames(duration)
    t = time_axis(count)
    noise = bandpass(rng.standard_normal(count), 520.0, 4_100.0, SAMPLE_RATE, 2)
    bursts = np.exp(-t / 0.018)
    delayed_t = np.maximum(t - 0.011, 0.0)
    bursts += 0.55 * np.exp(-delayed_t / 0.016) * (t >= 0.011)
    f0 = 178.0 + 11.0 * (variant % 3)
    resonator = np.sin(2.0 * math.pi * f0 * t + 0.2) * np.exp(-t / 0.028)
    resonator += 0.35 * np.sin(2.0 * math.pi * f0 * 1.81 * t) * np.exp(-t / 0.019)
    return fade_edges(noise * bursts * 0.140 + resonator * 0.15, SAMPLE_RATE, 0.4, 11.0)


def synth_forearm_tap(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Dry synthesized skin tap, intentionally smaller than the palm."""
    duration = 0.082 + 0.005 * (variant % 3)
    count = frames(duration)
    t = time_axis(count)
    f0 = 244.0 + 17.0 * (variant % 4)
    phase = 2.0 * math.pi * f0 * t
    resonator = np.sin(phase) * np.exp(-t / 0.020)
    resonator += 0.28 * np.sin(phase * 1.63 + 0.5) * np.exp(-t / 0.014)
    noise = bandpass(rng.standard_normal(count), 850.0, 3_800.0, SAMPLE_RATE, 2)
    noise *= np.exp(-t / 0.009)
    return fade_edges(resonator * 0.17 + noise * 0.090, SAMPLE_RATE, 0.3, 8.0)


def synth_rubber_sole(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Low synthetic thud suggesting a sole on an elastic floor."""
    duration = 0.142 + 0.008 * (variant % 2)
    count = frames(duration)
    t = time_axis(count)
    base = 104.0 + 7.0 * (variant % 3)
    frequency = base * (1.0 - 0.07 * np.exp(-t / 0.031))
    phase = phase_from_frequency(frequency)
    thud = (np.sin(phase) + 0.21 * np.sin(2.0 * phase + 0.4)) * np.exp(-t / 0.045)
    grit = bandpass(rng.standard_normal(count), 180.0, 1_350.0, SAMPLE_RATE, 2)
    grit *= np.exp(-t / 0.016)
    return fade_edges(thud * 0.27 + grit * 0.047, SAMPLE_RATE, 0.5, 13.0)


def synth_hat(rng: np.random.Generator, brightness: float, variant: int) -> np.ndarray:
    duration = 0.047 + 0.006 * (variant % 3)
    count = frames(duration)
    t = time_axis(count)
    cutoff = float(np.clip(5_500.0 * brightness, 4_600.0, 7_600.0))
    noise = highpass(rng.standard_normal(count), cutoff, SAMPLE_RATE, 3)
    metallic_air = (
        np.sin(2.0 * math.pi * 6_173.0 * t + 0.4)
        + np.sin(2.0 * math.pi * 7_421.0 * t + 1.1)
    ) * 0.5
    envelope = np.exp(-t / (0.010 + 0.001 * (variant % 2)))
    return fade_edges((noise * 0.078 + metallic_air * 0.019) * envelope, SAMPLE_RATE, 0.2, 6.0)


def synth_stab(note_names: tuple[str, ...], variant: int, refined: bool) -> np.ndarray:
    """Short non-melodic stab; fundamentals are restricted to A/C/Eb."""
    duration = 0.155 if refined else 0.225
    count = frames(duration)
    t = time_axis(count)
    attack = 1.0 - np.exp(-t / 0.004)
    envelope = attack * np.exp(-t / (0.045 if refined else 0.068))
    output = np.zeros(count, dtype=np.float64)
    for voice, name in enumerate(note_names):
        frequency = NOTE_FREQUENCIES[name]
        phase = 2.0 * math.pi * frequency * t + voice * 0.31 + variant * 0.07
        output += np.sin(phase) + (0.14 if refined else 0.21) * np.sin(2.0 * phase + 0.35)
    output /= max(1, len(note_names))
    output = lowpass(output, 3_600.0 if refined else 5_200.0, SAMPLE_RATE, 2)
    return fade_edges(output * envelope * 0.30, SAMPLE_RATE, 0.6, 17.0)


def synth_air_puff(rng: np.random.Generator, variant: int) -> np.ndarray:
    """Quiet noise punctuation for section changes, not a riser melody."""
    duration = 0.24
    count = frames(duration)
    t = time_axis(count)
    noise = bandpass(rng.standard_normal(count), 640.0, 3_300.0, SAMPLE_RATE, 2)
    envelope = np.sin(np.linspace(0.0, math.pi, count, endpoint=True)) ** 2.2
    tremolo = 0.78 + 0.22 * np.sin(2.0 * math.pi * (5.4 + 0.2 * variant) * t)
    return fade_edges(noise * envelope * tremolo * 0.042, SAMPLE_RATE, 3.0, 22.0)


def add_mono_event(
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


def remove_dc_preserving_taper(audio: np.ndarray) -> np.ndarray:
    """Remove finite-loop mean without lifting the zero-valued seam frames."""
    data = np.asarray(audio, dtype=np.float64).copy()
    correction = np.ones(data.shape[0], dtype=np.float64)
    curve = np.sin(
        np.linspace(0.0, math.pi / 2.0, TAPER_FRAMES, endpoint=True)
    ) ** 2
    correction[:TAPER_FRAMES] = curve
    correction[-TAPER_FRAMES:] = curve[::-1]
    correction_mean = float(np.mean(correction))
    for channel in range(data.shape[1]):
        channel_mean = float(np.mean(data[:, channel]))
        data[:, channel] -= correction * (channel_mean / correction_mean)
    data[0] = 0.0
    data[-1] = 0.0
    return data.astype(np.float32)


def kick_pattern(phrase: int, local: int, refined: bool) -> tuple[float, ...]:
    impulse = local < IMPULSE_BARS
    if not refined:
        return (0.0, 2.5) if impulse else (0.0, 2.75)
    patterns: tuple[tuple[tuple[float, ...], ...], ...] = (
        (
            (0.0, 2.5), (0.0, 2.75), (0.0, 1.75, 3.25),
            (0.0, 2.5), (0.0, 2.25), (0.0, 2.0),
            (0.0, 2.75), (0.0, 1.75), (0.0, 2.5),
            (0.0, 3.0), (0.0, 2.25), (0.0, 1.5, 3.0), (0.0,),
        ),
        (
            (0.0, 1.75, 3.25), (0.0, 2.5), (0.0, 2.25, 3.5),
            (0.0, 1.5, 3.0), (0.0, 2.75), (0.0, 2.0),
            (0.0, 2.25), (0.0, 3.0), (0.0, 1.75, 3.25),
            (0.0, 2.5), (0.0, 2.0), (0.0, 2.75), (0.0,),
        ),
        (
            (0.25, 2.75), (0.0, 2.0), (0.25, 1.75, 3.25),
            (0.0, 2.75), (0.25, 2.25), (0.0, 2.0),
            (0.25, 2.0), (0.0, 2.75), (0.25, 1.5, 3.0),
            (0.0, 2.25), (0.25, 2.75), (0.0, 1.75), (0.0,),
        ),
        (
            (0.0, 3.0), (0.0, 1.5, 3.0), (0.0, 2.5),
            (0.0, 1.75, 3.25), (0.0, 2.75), (0.0, 2.0),
            (0.0, 2.5), (0.0, 3.0), (0.0, 1.75),
            (0.0, 2.75), (0.0, 2.25), (0.0, 1.5), (0.0,),
        ),
    )
    return patterns[phrase][local]


def body_patterns(phrase: int, local: int, refined: bool) -> dict[str, tuple[float, ...]]:
    impulse = local < IMPULSE_BARS
    if not refined:
        return {
            "palm": (1.0, 3.0) if impulse else (1.25, 3.0),
            "tap": (0.75, 2.25, 3.625),
            "sole": (1.5,),
        }
    families = (
        {
            "palm": (1.0, 3.0) if impulse else (1.25, 3.25),
            "tap": (0.75, 2.25, 3.625) if local % 2 == 0 else (0.5, 2.0),
            "sole": (1.5,) if local % 3 != 2 else (2.0,),
        },
        {
            "palm": (0.75, 2.75) if impulse else (1.5, 3.0),
            "tap": (1.25, 2.25, 3.5) if local % 2 == 0 else (0.5, 2.5),
            "sole": (1.75, 3.25) if local in (2, 8) else (2.25,),
        },
        {
            "palm": (1.5, 3.25) if impulse else (0.75, 2.5),
            "tap": (0.5, 2.125, 3.5) if local % 2 == 0 else (1.0, 3.0),
            "sole": (0.75, 2.75) if local in (3, 9) else (1.75,),
        },
        {
            "palm": (1.0, 2.75) if impulse else (1.25, 3.0),
            "tap": (0.625, 2.125) if local % 2 == 0 else (1.75, 3.5),
            "sole": (2.0,) if local < 10 else (0.75,),
        },
    )
    return families[phrase]


def within_reserved_window(local: int, offset: float) -> bool:
    # Last beat of bar 6 and last 1.25 beats of bar 13 are left for game cues.
    return (local == 5 and offset >= 3.0) or (local == 12 and offset >= 2.75)


def render_arrangement(pass_number: int) -> np.ndarray:
    refined = pass_number >= 2
    rng = rng_for(MASTER_SEED, f"{TRACK_ID}-pass-{pass_number}")
    mix = np.zeros((LOOP_FRAMES, 2), dtype=np.float32)

    for bar in range(BARS):
        phrase = bar // PHRASE_BARS
        local = bar % PHRASE_BARS
        impulse = local < IMPULSE_BARS

        for event_index, offset in enumerate(kick_pattern(phrase, local, refined)):
            if refined and within_reserved_window(local, offset):
                continue
            kick = synth_kick(rng, bar + event_index)
            spring = synth_spring_sub(bar + event_index, 0.30 if offset > 0.0 else 0.36)
            kick_gain = (0.78 if refined else 0.86) if event_index == 0 else (0.56 if refined else 0.72)
            sub_gain = (0.54 if refined else 0.69) if event_index == 0 else (0.34 if refined else 0.54)
            add_mono_event(mix, kick, bar, offset, gain=kick_gain)
            # Phrase 3 occasionally makes the spring answer 1/16 late.
            spring_offset = offset + (0.25 if refined and phrase == 3 and event_index > 0 else 0.0)
            if not (refined and within_reserved_window(local, spring_offset)):
                add_mono_event(mix, spring, bar, spring_offset, gain=sub_gain)

        patterns = body_patterns(phrase, local, refined)
        pan_width = 0.15 if refined else 0.26
        for event_index, offset in enumerate(patterns["palm"]):
            if refined and within_reserved_window(local, offset):
                continue
            palm = synth_palm(rng, bar + event_index)
            add_mono_event(
                mix,
                palm,
                bar,
                offset,
                gain=0.82 if refined else 0.52,
                pan=(-pan_width if event_index % 2 == 0 else pan_width),
            )
        for event_index, offset in enumerate(patterns["tap"]):
            if refined and within_reserved_window(local, offset):
                continue
            tap = synth_forearm_tap(rng, bar + event_index)
            add_mono_event(
                mix,
                tap,
                bar,
                offset,
                gain=0.68 if refined else 0.45,
                pan=(pan_width if event_index % 2 == 0 else -pan_width),
            )
        for event_index, offset in enumerate(patterns["sole"]):
            if refined and within_reserved_window(local, offset):
                continue
            sole = synth_rubber_sole(rng, bar + event_index)
            add_mono_event(mix, sole, bar, offset, gain=0.52 if refined else 0.48)

        if refined:
            active_hat_bars = local not in (2, 5, 8, 10, 12)
            if active_hat_bars:
                hat_offsets = (0.5, 1.5, 2.5, 3.5)
                if phrase == 1 and local % 2 == 0:
                    hat_offsets = (0.5, 1.25, 2.5, 3.25)
                elif phrase == 2:
                    hat_offsets = (0.75, 1.75, 3.25)
                elif phrase == 3 and not impulse:
                    hat_offsets = (1.5, 3.5)
                for event_index, offset in enumerate(hat_offsets):
                    if within_reserved_window(local, offset):
                        continue
                    hat = synth_hat(rng, 0.88 + 0.03 * phrase, bar + event_index)
                    add_mono_event(
                        mix,
                        hat,
                        bar,
                        offset,
                        gain=0.32 + 0.035 * ((bar + event_index) % 3 == 0),
                        pan=(-0.17 if event_index % 2 == 0 else 0.17),
                    )
        else:
            subdivision = 0.25 if local in (4, 5, 11, 12) else 0.5
            offset = 0.5
            event_index = 0
            while offset < 4.0:
                hat = synth_hat(rng, 1.18, bar + event_index)
                add_mono_event(
                    mix,
                    hat,
                    bar,
                    offset,
                    gain=0.27 + 0.025 * ((bar + event_index) % 2),
                    pan=(-0.25 if event_index % 2 == 0 else 0.25),
                )
                offset += subdivision
                event_index += 1

        if refined:
            should_stab = local in ((1, 4, 7, 10) if phrase % 2 == 0 else (2, 6, 9, 11))
            if should_stab:
                choices = (("A",), ("C",), ("Eb",), ("A", "C"))
                notes = choices[(phrase + local) % len(choices)]
                offset = (1.75, 2.25, 3.25, 1.5)[(phrase + local) % 4]
                if not within_reserved_window(local, offset):
                    stab = synth_stab(notes, bar, True)
                    add_mono_event(
                        mix,
                        stab,
                        bar,
                        offset,
                        gain=0.36,
                        pan=(-0.08 if bar % 2 == 0 else 0.08),
                    )
        elif local % 2 == 0:
            stab = synth_stab(("A", "C", "Eb"), bar, False)
            add_mono_event(
                mix,
                stab,
                bar,
                1.75 if impulse else 3.25,
                gain=0.36,
                pan=(-0.16 if phrase % 2 == 0 else 0.16),
            )

        if refined and local in (0, 6):
            puff = synth_air_puff(rng, phrase)
            add_mono_event(
                mix,
                puff,
                bar,
                3.25 if local == 0 else 0.5,
                gain=0.24,
                pan=(-0.10 if phrase % 2 == 0 else 0.10),
            )

    # DC/ultrasonic cleanup and a restrained saturation stage. Bass stays mono
    # because every low source is centered; only short percussion is panned.
    mix = highpass(mix, 18.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = lowpass(mix, 16_500.0 if refined else 18_500.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix * np.float32(1.10 if refined else 1.15), 1.22 if refined else 1.30)
    mix -= np.mean(mix, axis=0, dtype=np.float64).astype(np.float32)
    mix = taper_loop_boundary(mix, TAPER_FRAMES)
    mix = remove_dc_preserving_taper(mix)
    mix = normalize_loudness(
        mix,
        SAMPLE_RATE,
        TARGET_LUFS,
        TRUE_PEAK_CEILING_DBTP,
    ).astype(np.float32)
    # Loudness normalization may choose a symmetric crest-compression curve;
    # on an asymmetrically distributed drum loop that can shift the finite-file
    # mean even though the static curve itself is symmetric.
    mix = remove_dc_preserving_taper(mix)
    return mix


def array_sha256(audio: np.ndarray) -> str:
    return hashlib.sha256(np.asarray(audio, dtype="<f4").tobytes(order="C")).hexdigest()


def band_energy_percentages(audio: np.ndarray) -> dict[str, Any]:
    mono = np.mean(as_2d(audio), axis=1)
    decimated = signal.resample_poly(mono, 1, 2)
    frequencies, psd = signal.welch(
        decimated,
        fs=SAMPLE_RATE / 2,
        window="hann",
        nperseg=8_192,
        noverlap=4_096,
        detrend=False,
        scaling="spectrum",
    )
    total = float(np.sum(psd)) + 1.0e-20
    bands = {
        "sub20To90Hz": (20.0, 90.0),
        "bass90To250Hz": (90.0, 250.0),
        "lowMid250To800Hz": (250.0, 800.0),
        "presence800To4000Hz": (800.0, 4_000.0),
        "air4000To12000Hz": (4_000.0, 12_000.0),
    }
    percentages: dict[str, float] = {}
    for label, (low, high) in bands.items():
        mask = (frequencies >= low) & (frequencies < high)
        percentages[label] = round(float(np.sum(psd[mask]) / total * 100.0), 4)
    centroid = float(np.sum(frequencies * psd) / total)
    cumulative = np.cumsum(psd)
    rolloff_index = int(np.searchsorted(cumulative, cumulative[-1] * 0.95))
    rolloff = float(frequencies[min(rolloff_index, len(frequencies) - 1)])
    return {
        "method": "Welch PSD after deterministic 2x polyphase decimation",
        "spectralCentroidHz": round(centroid, 3),
        "spectralRolloff95Hz": round(rolloff, 3),
        "energyPercent": percentages,
    }


def mono_compatibility(audio: np.ndarray) -> dict[str, Any]:
    stereo = as_2d(audio).astype(np.float64, copy=False)
    left = stereo[:, 0]
    right = stereo[:, 1]
    correlation = float(np.corrcoef(left, right)[0, 1])
    mid = (left + right) * 0.5
    side = (left - right) * 0.5
    mid_rms = math.sqrt(float(np.mean(np.square(mid))))
    side_rms = math.sqrt(float(np.mean(np.square(side))))
    mono_loudness = integrated_lufs(mid.astype(np.float32), SAMPLE_RATE)
    return {
        "leftRightCorrelation": round(correlation, 6),
        "sideToMidDb": round(amp_to_db(side_rms / max(mid_rms, 1.0e-12)), 4),
        "monoIntegratedLufs": None if mono_loudness is None else round(mono_loudness, 4),
        "monoTruePeakDbtp": round(amp_to_db(true_peak(mid.astype(np.float32))), 4),
        "assessment": "pass" if correlation > 0.65 and side_rms < mid_rms else "review",
    }


def density_analysis(audio: np.ndarray) -> dict[str, Any]:
    mono = np.mean(as_2d(audio), axis=1)
    window = 1_024
    trimmed = mono[: mono.shape[0] - (mono.shape[0] % window)]
    blocks = trimmed.reshape(-1, window)
    rms = np.sqrt(np.mean(np.square(blocks), axis=1, dtype=np.float64))
    db = 20.0 * np.log10(np.maximum(rms, 1.0e-12))
    phrase_profiles: list[dict[str, Any]] = []
    for phrase in range(4):
        phrase_start = beat_frame(phrase * PHRASE_BARS * BEATS_PER_BAR)
        phrase_end = beat_frame((phrase + 1) * PHRASE_BARS * BEATS_PER_BAR)
        impulse_end = beat_frame(
            (phrase * PHRASE_BARS + IMPULSE_BARS) * BEATS_PER_BAR
        )
        phrase_audio = mono[phrase_start:phrase_end]
        impulse_audio = mono[phrase_start:impulse_end]
        response_audio = mono[impulse_end:phrase_end]

        def rms_db(values: np.ndarray) -> float:
            return round(amp_to_db(math.sqrt(float(np.mean(np.square(values), dtype=np.float64)))), 4)

        phrase_profiles.append(
            {
                "phrase": phrase + 1,
                "bars": f"{phrase * 13 + 1}-{phrase * 13 + 13}",
                "rmsDbfs": rms_db(phrase_audio),
                "impulse6BarsRmsDbfs": rms_db(impulse_audio),
                "response7BarsRmsDbfs": rms_db(response_audio),
            }
        )
    envelope = np.abs(mono)
    smoothed = signal.convolve(envelope, np.ones(512) / 512.0, mode="same", method="fft")
    peaks, _ = signal.find_peaks(smoothed, distance=frames(0.075), prominence=0.012)
    duration_minutes = audio.shape[0] / SAMPLE_RATE / 60.0
    return {
        "windowFrames": window,
        "activeWindowShareAboveMinus40Db": round(float(np.mean(db > -40.0)), 6),
        "activeWindowShareAboveMinus28Db": round(float(np.mean(db > -28.0)), 6),
        "silentWindowShareBelowMinus50Db": round(float(np.mean(db < -50.0)), 6),
        "transientEstimatePerMinute": round(len(peaks) / duration_minutes, 3),
        "phraseProfiles": phrase_profiles,
    }


def seam_analysis(audio: np.ndarray) -> dict[str, Any]:
    data = as_2d(audio)
    return {
        "taperFrames": TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(data[0]))), 12),
        "lastFrameAbsMax": round(float(np.max(np.abs(data[-1]))), 12),
        "boundaryDiscontinuityAbsMax": round(float(np.max(np.abs(data[0] - data[-1]))), 12),
        "firstTaperPeakDbfs": round(amp_to_db(float(np.max(np.abs(data[:TAPER_FRAMES])))), 4),
        "lastTaperPeakDbfs": round(amp_to_db(float(np.max(np.abs(data[-TAPER_FRAMES:])))), 4),
        "assessment": "pass" if np.max(np.abs(data[[0, -1]])) == 0.0 else "review",
    }


def pass_analysis(audio: np.ndarray, *, include_deep: bool) -> dict[str, Any]:
    result: dict[str, Any] = {
        "floatBufferSha256": array_sha256(audio),
        "metrics": measure_audio(audio, SAMPLE_RATE, include_true_peak=True),
        "density": density_analysis(audio),
        "seam": seam_analysis(audio),
    }
    if include_deep:
        result["spectral"] = band_energy_percentages(audio)
        result["monoCompatibility"] = mono_compatibility(audio)
    return result


def assert_file_gates(path: Path, *, runtime: bool) -> dict[str, Any]:
    metrics, info = measure_file(path, include_true_peak=True)
    failures: list[str] = []
    if metrics["sampleRate"] != SAMPLE_RATE:
        failures.append(f"sample rate {metrics['sampleRate']} != {SAMPLE_RATE}")
    if metrics["channels"] != 2:
        failures.append(f"channels {metrics['channels']} != 2")
    if metrics["frames"] != LOOP_FRAMES:
        failures.append(f"frames {metrics['frames']} != {LOOP_FRAMES}")
    if not runtime and (info.format != "WAV" or info.subtype != "PCM_24"):
        failures.append(f"master encoding {info.format}/{info.subtype} != WAV/PCM_24")
    if runtime and (info.format != "OGG" or info.subtype != "VORBIS"):
        failures.append(f"runtime encoding {info.format}/{info.subtype} != OGG/VORBIS")
    if metrics["integratedLufs"] is None or abs(metrics["integratedLufs"] - TARGET_LUFS) > 0.35:
        failures.append(f"integrated LUFS {metrics['integratedLufs']} outside target tolerance")
    if metrics["truePeakDbtp"] is None or metrics["truePeakDbtp"] > -1.0:
        failures.append(f"true peak {metrics['truePeakDbtp']} dBTP exceeds -1.0")
    if max(abs(value) for value in metrics["dcOffset"]) >= 1.0e-4:
        failures.append(f"DC offset {metrics['dcOffset']} exceeds 1e-4")
    if metrics["samplePeakDbfs"] >= 0.0:
        failures.append(f"sample peak {metrics['samplePeakDbfs']} indicates clipping")
    metrics["gateStatus"] = "pass" if not failures else "fail"
    metrics["gateFailures"] = failures
    if failures:
        raise RuntimeError(f"{path}: " + "; ".join(failures))
    return metrics


def asset_record() -> dict[str, Any]:
    return {
        "id": TRACK_ID,
        "channels": 2,
        "master": MASTER_REL.as_posix(),
        "runtime": RUNTIME_REL.as_posix(),
    }


def export_final(root: Path, audio: np.ndarray) -> None:
    write_master_and_runtime(
        root,
        asset_record(),
        audio,
        SAMPLE_RATE,
        compression_level=0.72,
    )


def render_pipeline(root: Path) -> dict[str, Any]:
    report_path = root / REPORT_REL
    report_path.parent.mkdir(parents=True, exist_ok=True)
    work_path = report_path.parent / ".sol_de_mola_v1.tmp.wav"

    print("[sol-de-mola] pass 1/2: rendering initial arrangement", flush=True)
    v1 = render_arrangement(1)
    sf.write(work_path, v1, SAMPLE_RATE, format="WAV", subtype="PCM_24")
    v1_analysis = pass_analysis(v1, include_deep=True)
    v1_analysis["ephemeralPcm24Sha256"] = sha256_file(work_path)
    work_path.unlink()

    print("[sol-de-mola] pass 2/2: rendering groove/space/spectrum refinement", flush=True)
    final = render_arrangement(2)
    final_analysis = pass_analysis(final, include_deep=True)
    export_final(root, final)

    master_path = root / MASTER_REL
    runtime_path = root / RUNTIME_REL
    master_metrics = assert_file_gates(master_path, runtime=False)
    runtime_metrics = assert_file_gates(runtime_path, runtime=True)
    master_audio, _ = sf.read(master_path, dtype="float32", always_2d=True)
    final_file_analysis = {
        "spectral": band_energy_percentages(master_audio),
        "monoCompatibility": mono_compatibility(master_audio),
        "density": density_analysis(master_audio),
        "seam": seam_analysis(master_audio),
    }

    print("[sol-de-mola] determinism: second source render and export", flush=True)
    with tempfile.TemporaryDirectory(prefix="sol-de-mola-determinism-") as temp_dir:
        verification_root = Path(temp_dir)
        repeated = render_arrangement(2)
        repeated_buffer_hash = array_sha256(repeated)
        export_final(verification_root, repeated)
        repeated_master = verification_root / MASTER_REL
        repeated_runtime = verification_root / RUNTIME_REL
        second_hashes = {
            "floatBufferSha256": repeated_buffer_hash,
            "masterSha256": sha256_file(repeated_master),
            "runtimeSha256": sha256_file(repeated_runtime),
        }
    first_hashes = {
        "floatBufferSha256": final_analysis["floatBufferSha256"],
        "masterSha256": sha256_file(master_path),
        "runtimeSha256": sha256_file(runtime_path),
    }
    determinism_pass = first_hashes == second_hashes
    if not determinism_pass:
        raise RuntimeError(
            f"determinism verification failed: first={first_hashes}, second={second_hashes}"
        )

    source_path = Path(__file__).resolve()
    dependency_path = ROOT / "tools/assets/audio_common.py"
    report: dict[str, Any] = {
        "contract": "six-seven-audio-proposal-production-v1",
        "status": "produced-refined-validated",
        "id": TRACK_ID,
        "title": TITLE,
        "style": STYLE,
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "creativeBrief": {
            "bpm": BPM,
            "meter": "4/4",
            "sampleRate": SAMPLE_RATE,
            "bars": BARS,
            "frames": LOOP_FRAMES,
            "macroStructure": "4 x 13 bars; each 13 = 6 impulse + 7 response",
            "tonalCenter": "A1 / 55 Hz",
            "allowedStabFundamentals": NOTE_FREQUENCIES,
            "identity": "synthetic body percussion plus a sub/tom pitch dip-and-rebound spring",
            "negativeSpace": "bar 6 reserves beat 4; bar 13 reserves the final 1.25 beats in every macrophrase",
            "prohibitions": [
                "voice",
                "external samples or foley",
                "cowbell",
                "copied beat/passinho",
                "regional caricature",
                "protagonist melody",
            ],
        },
        "provenance": {
            "method": "100% deterministic procedural synthesis from oscillators and seeded noise",
            "externalAudioRead": False,
            "generativeModelUsed": False,
            "masterSeed": MASTER_SEED,
            "source": source_path.relative_to(ROOT).as_posix(),
            "sourceSha256": sha256_file(source_path),
            "dependency": dependency_path.relative_to(ROOT).as_posix(),
            "dependencySha256": sha256_file(dependency_path),
        },
        "toolchain": {
            "python": platform.python_version(),
            "numpy": package_version("numpy"),
            "scipy": package_version("scipy"),
            "soundfile": package_version("soundfile"),
            "pyloudnorm": package_version("pyloudnorm"),
            "runtimeEncoder": sf.__libsndfile_version__,
        },
        "iterationHistory": [
            {
                "pass": 1,
                "label": "v1 initial",
                "artifactRetention": "temporary PCM24 measured and removed after analysis",
                "observations": [
                    "the same body-percussion cell repeats across all four macrophrases",
                    "continuous bright hats make long-loop fatigue more likely",
                    "stabs and late-bar events leave insufficient room for Six/Seven game cues",
                ],
                "analysis": v1_analysis,
            },
            {
                "pass": 2,
                "label": "v2 final",
                "changesApplied": [
                    "groove: four phrase-specific kick/body-percussion families replace the repeated v1 cell",
                    "anti-fatigue/spectrum: hats are sparser, darker, and absent in selected response bars; stabs are shorter and lower-passed",
                    "Six/Seven space: beat 4 of every sixth bar and the final 1.25 beats of every thirteenth bar are protected from new events",
                    "mono mix: short percussion pan width reduced from 0.26 to 0.15 while kick and spring sub remain centered",
                ],
                "analysis": final_analysis,
            },
        ],
        "outputs": {
            "master": master_metrics,
            "runtime": runtime_metrics,
        },
        "finalDecodedMasterAnalysis": final_file_analysis,
        "determinism": {
            "status": "pass" if determinism_pass else "fail",
            "method": "full second pass-2 synthesis and independent PCM24/Vorbis export",
            "firstRender": first_hashes,
            "secondRender": second_hashes,
            "byteIdenticalMaster": first_hashes["masterSha256"] == second_hashes["masterSha256"],
            "byteIdenticalRuntime": first_hashes["runtimeSha256"] == second_hashes["runtimeSha256"],
        },
        "gates": {
            "targetLufs": TARGET_LUFS,
            "lufsTolerance": 0.35,
            "truePeakMaximumDbtp": -1.0,
            "dcOffsetAbsoluteMaximum": 0.0001,
            "requiredFrames": LOOP_FRAMES,
            "requiredChannels": 2,
            "requiredMasterEncoding": "WAV/PCM_24",
            "requiredRuntimeEncoding": "OGG/VORBIS",
            "requiredTaperFrames": TAPER_FRAMES,
            "overall": "pass",
        },
        "arrangement": {
            "phrase1": "compression: grounded A spring with alternating 2-hit and 3-hit rebounds",
            "phrase2": "ricochet: denser off-grid kick answers and displaced palms",
            "phrase3": "inverted rebound: quarter-beat entrances and low-sole counterweight",
            "phrase4": "disassembly: half-time openings, late spring answers, and stripped landing",
        },
    }
    dump_json(report_path, report)
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument(
        "--verify-existing",
        action="store_true",
        help="measure existing final files without rendering (quick handoff check)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    if args.verify_existing:
        master = assert_file_gates(root / MASTER_REL, runtime=False)
        runtime = assert_file_gates(root / RUNTIME_REL, runtime=True)
        print(json.dumps({"master": master, "runtime": runtime}, indent=2))
        return 0
    report = render_pipeline(root)
    print(
        json.dumps(
            {
                "status": report["status"],
                "master": report["outputs"]["master"],
                "runtime": report["outputs"]["runtime"],
                "determinism": report["determinism"]["status"],
            },
            indent=2,
            ensure_ascii=False,
        ),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
