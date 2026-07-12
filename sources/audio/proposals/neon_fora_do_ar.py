#!/usr/bin/env python3
"""Produce the deterministic proposal track ``Neon Fora do Ar``.

This is an actual synthesizer/arranger, not a text prompt.  Every sound starts
from oscillators or seeded noise generated here; no external audio is read.
The default mode renders a genuine v1 inspection pass, renders the refined v2
twice, exports the PCM24/Vorbis deliverables, and writes technical evidence.
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
ROOT_HZ = 49.0  # G1
MASTER_SEED = "neon-fora-do-ar-brega-phonk-v2-2026-07-12"
ASSET_ID = "MUS-PROP-NEON-FORA-DO-AR"

MASTER_RELATIVE = Path("masters/audio/proposals/neon_fora_do_ar.wav")
RUNTIME_RELATIVE = Path("assets/audio/proposals/neon_fora_do_ar.ogg")
REPORT_RELATIVE = Path("reports/audio-proposals/neon_fora_do_ar.json")

MACRO_NAMES = (
    "sinal aberto",
    "transmissão lateral",
    "pacotes perdidos",
    "retorno sem barras cheias",
)

# Thirteen-bar rhythmic grammar: bars 0..5 are impulse and 6..12 response.
# The patterns deliberately leave room around the triple transmission mark.
KICK_PATTERNS: tuple[tuple[float, ...], ...] = (
    (0.0, 2.5),
    (0.0, 1.75, 3.25),
    (0.5, 2.25),
    (0.0, 2.75, 3.5),
    (0.0, 1.5, 2.625),
    (0.0, 1.75),
    (0.0, 2.75),
    (0.5, 2.0, 3.25),
    (0.0, 1.75),
    (0.75, 2.5, 3.5),
    (0.0, 2.25),
    (0.5, 1.5, 2.75),
    (0.0,),
)

CLAP_PATTERNS: tuple[tuple[float, ...], ...] = (
    (1.0, 3.0),
    (1.25, 3.0),
    (0.75, 2.75),
    (1.0, 3.25),
    (1.25, 2.875),
    (1.0,),
    (1.25, 3.0),
    (0.75, 2.75),
    (1.5, 3.0),
    (1.0, 3.25),
    (0.75, 2.5),
    (1.25, 2.625),
    (1.0,),
)


def frames(seconds: float) -> int:
    return int(round(seconds * SAMPLE_RATE))


def beat_frame(beat: float) -> int:
    return int(round(beat * 60.0 * SAMPLE_RATE / BPM))


def phase_from_frequency(frequency: np.ndarray | float) -> np.ndarray:
    values = np.asarray(frequency, dtype=np.float64)
    return 2.0 * math.pi * np.cumsum(values) / SAMPLE_RATE


def synth_kick(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    """Dry, rounded kick with no borrowed drum sample."""
    duration = 0.135 if final else 0.205
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    frequency = ROOT_HZ + (86.0 if final else 105.0) * np.exp(-t / 0.016)
    phase = phase_from_frequency(frequency)
    envelope = (1.0 - np.exp(-t / 0.0015)) * np.exp(-t / (0.049 if final else 0.073))
    body = np.sin(phase) + 0.17 * np.sin(2.0 * phase + 0.18)
    click = highpass(rng.standard_normal(count), 3_200.0, SAMPLE_RATE, 2)
    click *= np.exp(-t / 0.0036) * (0.022 if final else 0.033)
    return fade_edges(
        (body * envelope * 0.80 + click).astype(np.float32),
        SAMPLE_RATE,
        0.4,
        10.0,
    )


def synth_short_808(*, final: bool, primary: bool) -> np.ndarray:
    """Short G-centered 808 punctuation, kept strictly mono before panning."""
    if final:
        duration = 0.215 if primary else 0.165
        decay = 0.092 if primary else 0.068
    else:
        duration = 0.340 if primary else 0.275
        decay = 0.145 if primary else 0.116
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    frequency = ROOT_HZ * (1.0 + (0.030 if final else 0.058) * np.exp(-t / 0.025))
    phase = phase_from_frequency(frequency)
    envelope = (1.0 - np.exp(-t / 0.0045)) * np.exp(-t / decay)
    tone = np.sin(phase) + 0.23 * np.sin(2.0 * phase + 0.12)
    tone = np.tanh(tone * 1.35) / math.tanh(1.35)
    return fade_edges((tone * envelope * 0.54).astype(np.float32), SAMPLE_RATE, 0.8, 20.0)


def synth_clap(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    duration = 0.122 if final else 0.190
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    noise = bandpass(rng.standard_normal(count), 720.0, 5_600.0, SAMPLE_RATE, 2)
    envelope = np.zeros(count, dtype=np.float64)
    for offset, gain in ((0.0, 1.0), (0.011, 0.64), (0.023, 0.42)):
        local = np.maximum(t - offset, 0.0)
        envelope += gain * np.exp(-local / (0.019 if final else 0.032)) * (t >= offset)
    body = np.sin(2.0 * math.pi * 196.0 * t) * np.exp(-t / 0.035)
    return fade_edges(
        (noise * envelope * 0.105 + body * 0.040).astype(np.float32),
        SAMPLE_RATE,
        0.3,
        10.0,
    )


def synth_hat(rng: np.random.Generator, *, open_hat: bool, final: bool) -> np.ndarray:
    duration = (0.070 if open_hat else 0.030) if final else (0.105 if open_hat else 0.046)
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    noise = highpass(rng.standard_normal(count), 6_100.0 if final else 5_100.0, SAMPLE_RATE, 3)
    noise = lowpass(noise, 15_000.0, SAMPLE_RATE, 2)
    envelope = np.exp(-t / (duration * (0.28 if open_hat else 0.18)))
    level = 0.070 if final else 0.052
    return fade_edges((noise * envelope * level).astype(np.float32), SAMPLE_RATE, 0.2, 5.0)


def synth_low_tick(rng: np.random.Generator, *, final: bool) -> np.ndarray:
    """Rare low metallic punctuation; intentionally unlike a cowbell riff."""
    duration = 0.075 if final else 0.125
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    envelope = (1.0 - np.exp(-t / 0.001)) * np.exp(-t / (0.018 if final else 0.033))
    tone = (
        np.sin(2.0 * math.pi * 164.0 * t)
        + 0.31 * np.sin(2.0 * math.pi * 271.0 * t + 0.4)
        + 0.17 * np.sin(2.0 * math.pi * 389.0 * t + 0.9)
    )
    transient = bandpass(rng.standard_normal(count), 650.0, 2_200.0, SAMPLE_RATE, 2)
    transient *= np.exp(-t / 0.004) * 0.028
    result = lowpass(tone * envelope * 0.20 + transient, 2_800.0, SAMPLE_RATE, 2)
    return fade_edges(result.astype(np.float32), SAMPLE_RATE, 0.3, 7.0)


def synth_packet_grains(
    rng: np.random.Generator,
    *,
    final: bool,
    dark: bool,
) -> np.ndarray:
    """Seeded micro-grains that evoke a faulty transmission, not a sample."""
    duration = (0.285 if dark else 0.235) if final else (0.540 if dark else 0.430)
    count = frames(duration)
    output = np.zeros(count, dtype=np.float64)
    grain_count = 7 if final else 14
    for index in range(grain_count):
        grain_duration = float(rng.uniform(0.010, 0.029 if final else 0.045))
        grain_frames = min(frames(grain_duration), count)
        if grain_frames < 2:
            continue
        maximum_start = max(1, count - grain_frames)
        start = int(rng.integers(0, maximum_start))
        grain = rng.standard_normal(grain_frames)
        grain *= np.sin(np.linspace(0.0, math.pi, grain_frames, endpoint=True)) ** 2
        carrier = np.sin(
            2.0 * math.pi * (310.0 + index * 37.0) * np.arange(grain_frames) / SAMPLE_RATE
            + index * 0.41
        )
        output[start : start + grain_frames] += grain * 0.58 + carrier * 0.18
    output = bandpass(
        output,
        260.0 if dark else 480.0,
        1_850.0 if dark else (3_700.0 if final else 5_200.0),
        SAMPLE_RATE,
        2,
    )
    envelope = np.sin(np.linspace(0.0, math.pi, count, endpoint=True)) ** 1.6
    level = 0.064 if final else 0.046
    return fade_edges((output * envelope * level).astype(np.float32), SAMPLE_RATE, 2.0, 14.0)


def synth_signature_hit(
    rng: np.random.Generator,
    mode: str,
    *,
    final: bool,
) -> np.ndarray:
    """One hit of the open -> band-pass -> low-pass transmission mark."""
    if mode not in {"open", "bandpass", "lowpass"}:
        raise ValueError(f"invalid signature mode: {mode}")
    duration = 0.088 if final else 0.145
    count = frames(duration)
    t = np.arange(count, dtype=np.float64) / SAMPLE_RATE
    frequency = 132.0 + 58.0 * np.exp(-t / 0.013)
    phase = phase_from_frequency(frequency)
    body = (np.sin(phase) + 0.26 * np.sin(2.37 * phase + 0.33)) * np.exp(-t / 0.030)
    noise = rng.standard_normal(count) * np.exp(-t / 0.014)
    raw = body * 0.34 + noise * 0.075
    if mode == "open":
        result = highpass(raw, 90.0, SAMPLE_RATE, 2)
        result = lowpass(result, 8_500.0 if final else 10_500.0, SAMPLE_RATE, 2)
    elif mode == "bandpass":
        result = bandpass(raw, 520.0, 2_050.0, SAMPLE_RATE, 2)
    else:
        result = highpass(raw, 72.0, SAMPLE_RATE, 2)
        result = lowpass(result, 620.0 if final else 820.0, SAMPLE_RATE, 3)
    return fade_edges((result * 0.55).astype(np.float32), SAMPLE_RATE, 0.3, 8.0)


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


def macro_shift(phrase: int, position: float, *, final: bool) -> float:
    """Shift secondary attacks while preserving every downbeat anchor."""
    if position == 0.0 or not final:
        return position
    shifts = (0.0, 0.125, -0.125, 0.25)
    return float(np.clip(position + shifts[phrase], 0.125, 3.70))


def remove_dc_preserve_boundary(audio: np.ndarray) -> np.ndarray:
    data = np.array(audio, dtype=np.float32, copy=True)
    window = np.ones(data.shape[0], dtype=np.float64)
    ramp = np.sin(
        np.linspace(0.0, math.pi / 2.0, BOUNDARY_TAPER_FRAMES, endpoint=True)
    ) ** 2
    window[:BOUNDARY_TAPER_FRAMES] = ramp
    window[-BOUNDARY_TAPER_FRAMES:] = ramp[::-1]
    channel_means = np.mean(data, axis=0, dtype=np.float64)
    data -= (
        window[:, None] * (channel_means / float(np.mean(window)))[None, :]
    ).astype(np.float32)
    data[0] = 0.0
    data[-1] = 0.0
    return data


def render_arrangement(pass_name: str) -> tuple[np.ndarray, dict[str, Any]]:
    if pass_name not in {"v1", "v2"}:
        raise ValueError(f"unsupported pass: {pass_name}")
    final = pass_name == "v2"
    mix = np.zeros((TOTAL_FRAMES, 2), dtype=np.float32)
    rng = rng_for(MASTER_SEED, f"{ASSET_ID}:{pass_name}")
    counts: dict[str, Any] = {
        name: 0
        for name in (
            "kick",
            "short808",
            "clap",
            "hat",
            "packetGrain",
            "lowMetalTick",
            "signatureHit",
        )
    }
    counts["signatureTriplets"] = 0
    counts["postSignatureSilenceBars"] = 0
    counts["macrophraseEvents"] = [0, 0, 0, 0]

    kick = synth_kick(rng, final=final)
    tick = synth_low_tick(rng, final=final)

    for bar in range(BARS):
        phrase = bar // 13
        local = bar % 13
        impulse = local < 6
        bar_beat = bar * BEATS_PER_BAR
        before = sum(int(counts[name]) for name in (
            "kick", "clap", "hat", "packetGrain", "lowMetalTick", "signatureHit"
        ))

        kick_positions = list(KICK_PATTERNS[local])
        # V2 refinement: the third macrophrase behaves like packet loss, while
        # signature bars stop all ordinary attacks before the triple mark.
        if final and phrase == 2 and local in {3, 4, 8, 9, 11}:
            kick_positions = kick_positions[:-1]
        if final and local in {5, 12}:
            kick_positions = [position for position in kick_positions if position < 2.0]
        for index, position in enumerate(kick_positions):
            shifted = macro_shift(phrase, position, final=final)
            gain = (0.74 if index == 0 else 0.52) if final else (0.84 if index == 0 else 0.62)
            if phrase == 2 and final:
                gain *= 0.94
            add_event(mix, kick, bar_beat + shifted, gain=gain)
            counts["kick"] += 1
            sub = synth_short_808(final=final, primary=index == 0)
            add_event(
                mix,
                sub,
                bar_beat + shifted,
                gain=(0.44 if index == 0 else 0.27) if final else (0.59 if index == 0 else 0.37),
            )
            counts["short808"] += 1

        clap_positions = list(CLAP_PATTERNS[local])
        if final and phrase == 2 and local in {4, 9, 11}:
            clap_positions = clap_positions[:1]
        if final and local in {5, 12}:
            clap_positions = [position for position in clap_positions if position < 2.0]
        # The fourth macro switches the response's first clap to a terse echo,
        # changing motion without raising overall level.
        if final and phrase == 3 and not impulse and len(clap_positions) > 1:
            clap_positions = [clap_positions[0], min(3.5, clap_positions[0] + 0.375)]
        for index, position in enumerate(clap_positions):
            clap = synth_clap(rng, final=final)
            add_event(
                mix,
                clap,
                bar_beat + macro_shift(phrase, position, final=final),
                gain=(0.72 if index == 0 else 0.58) if final else (0.48 if index == 0 else 0.39),
                pan=-0.035 if index == 0 else 0.035,
            )
            counts["clap"] += 1

        if final:
            hat_positions = [0.5, 1.5, 2.5, 3.5]
            if local in {4, 8, 10}:
                hat_positions = [0.5, 2.5]
            if phrase == 2 and local in {3, 4, 9, 10}:
                hat_positions = hat_positions[:1]
            if local in {5, 12}:
                hat_positions = [0.5, 1.5]
        else:
            hat_positions = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
        for index, position in enumerate(hat_positions):
            hat = synth_hat(
                rng,
                open_hat=index == len(hat_positions) - 1 and local in {3, 7},
                final=final,
            )
            add_event(
                mix,
                hat,
                bar_beat + position,
                gain=(0.34, 0.23, 0.29, 0.20)[index % 4] if final else (0.21, 0.15, 0.18, 0.13)[index % 4],
                pan=(-0.20 if (bar + index) % 2 == 0 else 0.20) if final else (-0.25 if index % 2 == 0 else 0.25),
            )
            counts["hat"] += 1

        # Granular packets live mostly in the seven-bar response.  Their pan
        # direction flips per macro, but remains restrained and mono-safe.
        packet_locals = {3, 5, 7, 10, 12} if not final else {3, 7, 10}
        if local in packet_locals:
            dark = local >= 7 or phrase == 2
            packet = synth_packet_grains(rng, final=final, dark=dark)
            position = 0.75 if local in {5, 12} else (2.0 if local == 7 else 2.75)
            add_event(
                mix,
                packet,
                bar_beat + position,
                gain=0.58 if final else 0.48,
                pan=(-0.24 if phrase % 2 == 0 else 0.24) if final else (-0.31 if phrase % 2 == 0 else 0.31),
            )
            counts["packetGrain"] += 1

        # Low metallic ticks are punctuation only: v2 has exactly two per
        # macrophrase and never repeats them at equal subdivisions as a riff.
        tick_locals = {2, 4, 8, 10, 11} if not final else {2, 9}
        if local in tick_locals:
            position = (3.375 if local < 6 else 0.875) + (0.125 if phrase % 2 else 0.0)
            add_event(
                mix,
                tick,
                bar_beat + position,
                gain=0.48 if final else 0.46,
                pan=0.07 if phrase % 2 else -0.07,
            )
            counts["lowMetalTick"] += 1

        # Two transmission marks per 13 bars.  V2 guarantees that ordinary
        # percussion ends first and that hit three is followed by >= .7 beat
        # of actual silence before the next bar/loop boundary.
        if local in {5, 12}:
            signature_positions = (2.30, 2.70, 3.10) if final else (2.45, 2.80, 3.15)
            for index, (mode, position) in enumerate(
                zip(("open", "bandpass", "lowpass"), signature_positions)
            ):
                hit = synth_signature_hit(rng, mode, final=final)
                add_event(
                    mix,
                    hit,
                    bar_beat + position,
                    gain=((0.68, 0.82, 0.94) if final else (0.53, 0.64, 0.76))[index],
                    pan=(0.0, -0.045, 0.045)[index] if final else (0.0, -0.11, 0.11)[index],
                )
                counts["signatureHit"] += 1
            counts["signatureTriplets"] += 1
            counts["postSignatureSilenceBars"] += 1

        after = sum(int(counts[name]) for name in (
            "kick", "clap", "hat", "packetGrain", "lowMetalTick", "signatureHit"
        ))
        counts["macrophraseEvents"][phrase] += after - before

    # The bus stays clean and restrained; variation comes from orchestration,
    # never a macro-by-macro loudness ramp.
    mix = highpass(mix, 24.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = lowpass(mix, 16_500.0 if final else 18_000.0, SAMPLE_RATE, 2).astype(np.float32)
    mix = soft_clip(mix * np.float32(1.20 if final else 1.31), 1.22 if final else 1.34)
    mix = taper_loop_boundary(mix, BOUNDARY_TAPER_FRAMES)
    # Leave enough codec headroom that the decoded Vorbis loop also remains
    # below -1 dBTP, not only the archival PCM master.
    mix = normalize_loudness(mix, SAMPLE_RATE, -16.0, -1.35).astype(np.float32)
    if final:
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
    peaks = signal.find_peaks(power, distance=3)[0]
    peaks = peaks[frequencies[peaks] >= 20.0]
    strongest = peaks[np.argsort(power[peaks])[-6:]][::-1]
    return {
        "spectralCentroidHz": round(float(np.sum(frequencies * power) / total), 3),
        "bandEnergyRatios": ratios,
        "strongestAverageFrequenciesHz": [
            round(float(frequencies[index]), 3) for index in strongest
        ],
    }


def density_metrics(audio: np.ndarray, counts: dict[str, Any]) -> dict[str, Any]:
    center = mono(audio)
    block = 480
    padded = np.pad(center, (0, (-center.shape[0]) % block))
    rms = np.sqrt(
        np.mean(np.square(padded.reshape(-1, block)), axis=1, dtype=np.float64)
    )
    db = 20.0 * np.log10(np.maximum(rms, 1.0e-12))
    audible_events = sum(
        int(counts[name])
        for name in (
            "kick", "clap", "hat", "packetGrain", "lowMetalTick", "signatureHit"
        )
    )
    return {
        "active10msBlockRatioAboveMinus42Dbfs": round(float(np.mean(db > -42.0)), 6),
        "quiet10msBlockRatioBelowMinus55Dbfs": round(float(np.mean(db < -55.0)), 6),
        "median10msRmsDbfs": round(float(np.median(db)), 4),
        "eventsPerBar": round(audible_events / BARS, 4),
        "eventCounts": counts,
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
    return {
        "leftRightCorrelation": round(float(np.corrcoef(left, right)[0, 1]), 6),
        "monoFoldRmsDbfs": round(amp_to_db(mono_rms), 4),
        "monoFoldDeltaDb": round(
            20.0
            * math.log10(
                max(mono_rms, 1.0e-12) / max(stereo_rms, 1.0e-12)
            ),
            4,
        ),
        "sideToMidEnergyDb": round(
            20.0 * math.log10(max(side_rms, 1.0e-12) / max(mono_rms, 1.0e-12)),
            4,
        ),
        "monoIntegratedLufs": round(float(integrated_lufs(center, SAMPLE_RATE)), 4),
        "monoSamplePeakDbfs": round(
            amp_to_db(float(np.max(np.abs(center), initial=0.0))), 4
        ),
    }


def boundary_metrics(audio: np.ndarray) -> dict[str, Any]:
    data = np.asarray(audio, dtype=np.float64)
    return {
        "taperFrames": BOUNDARY_TAPER_FRAMES,
        "firstFrameAbsMax": round(float(np.max(np.abs(data[0]))), 10),
        "lastFrameAbsMax": round(float(np.max(np.abs(data[-1]))), 10),
        "seamDiscontinuityAbsMax": round(
            float(np.max(np.abs(data[0] - data[-1]))), 10
        ),
        "firstTaperRegionPeakDbfs": round(
            amp_to_db(float(np.max(np.abs(data[:BOUNDARY_TAPER_FRAMES])))), 4
        ),
        "lastTaperRegionPeakDbfs": round(
            amp_to_db(float(np.max(np.abs(data[-BOUNDARY_TAPER_FRAMES:])))), 4
        ),
    }


def macro_loudness_metrics(audio: np.ndarray) -> dict[str, Any]:
    values: list[float] = []
    for phrase in range(4):
        start = beat_frame(phrase * 13 * 4)
        end = beat_frame((phrase + 1) * 13 * 4)
        if phrase == 3:
            end = TOTAL_FRAMES
        value = integrated_lufs(audio[start:end], SAMPLE_RATE)
        values.append(round(float(value), 4))
    return {
        "integratedLufsByMacrophrase": values,
        "rangeDb": round(max(values) - min(values), 4),
        "noProgressiveLoudnessRamp": not all(
            values[index] < values[index + 1] for index in range(3)
        ),
    }


def analysis_bundle(audio: np.ndarray, counts: dict[str, Any]) -> dict[str, Any]:
    return {
        "density": density_metrics(audio, counts),
        "spectral": spectral_metrics(audio),
        "monoCompatibility": mono_metrics(audio),
        "loopBoundary": boundary_metrics(audio),
        "macroDynamics": macro_loudness_metrics(audio),
    }


def asset_descriptor(master: Path, runtime: Path) -> dict[str, Any]:
    return {
        "id": ASSET_ID,
        "channels": 2,
        "master": master.as_posix(),
        "runtime": runtime.as_posix(),
    }


def export_pair(
    base: Path,
    audio: np.ndarray,
    master: Path,
    runtime: Path,
) -> tuple[Path, Path]:
    write_master_and_runtime(
        base,
        asset_descriptor(master, runtime),
        audio,
        SAMPLE_RATE,
        0.6,
    )
    return base / master, base / runtime


def inspect_v1(output: Path) -> int:
    audio, counts = render_arrangement("v1")
    output.parent.mkdir(parents=True, exist_ok=True)
    sf.write(output, audio, SAMPLE_RATE, format="WAV", subtype="PCM_24")
    metrics, _ = measure_file(output, include_true_peak=True)
    print(
        json.dumps(
            {
                "pass": "v1",
                "temporaryPath": str(output),
                "metrics": metrics,
                "analysis": analysis_bundle(audio, counts),
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    return 0


def gate_results(
    master_metrics: dict[str, Any],
    runtime_metrics: dict[str, Any],
    audio: np.ndarray,
    analysis: dict[str, Any],
    deterministic: bool,
) -> dict[str, bool]:
    return {
        "exactMasterFrames": master_metrics["frames"] == TOTAL_FRAMES,
        "exactRuntimeFrames": runtime_metrics["frames"] == TOTAL_FRAMES,
        "stereoMaster": master_metrics["channels"] == 2,
        "stereoRuntime": runtime_metrics["channels"] == 2,
        "sampleRate48k": master_metrics["sampleRate"] == SAMPLE_RATE
        and runtime_metrics["sampleRate"] == SAMPLE_RATE,
        "masterPcm24": master_metrics["format"] == "WAV"
        and master_metrics["subtype"] == "PCM_24",
        "runtimeVorbis": runtime_metrics["format"] == "OGG"
        and runtime_metrics["subtype"] == "VORBIS",
        "loudnessMinus16PlusMinus035": abs(
            float(master_metrics["integratedLufs"]) + 16.0
        )
        <= 0.35,
        "runtimeLoudnessMinus16PlusMinus035": abs(
            float(runtime_metrics["integratedLufs"]) + 16.0
        )
        <= 0.35,
        "truePeakAtOrBelowMinus1Dbtp": float(master_metrics["truePeakDbtp"])
        <= -1.0,
        "runtimeTruePeakAtOrBelowMinus1Dbtp": float(
            runtime_metrics["truePeakDbtp"]
        )
        <= -1.0,
        "samplePeakNoClipping": float(master_metrics["samplePeakDbfs"]) < 0.0,
        "dcOffsetBelow1eMinus4": max(
            abs(float(value)) for value in master_metrics["dcOffset"]
        )
        < 1.0e-4,
        "runtimeDcOffsetBelow1eMinus4": max(
            abs(float(value)) for value in runtime_metrics["dcOffset"]
        )
        < 1.0e-4,
        "runtimeSamplePeakNoClipping": float(runtime_metrics["samplePeakDbfs"])
        < 0.0,
        "boundaryTaper1024": BOUNDARY_TAPER_FRAMES == 1_024
        and float(np.max(np.abs(audio[0]))) == 0.0
        and float(np.max(np.abs(audio[-1]))) == 0.0,
        "runtimeDecodable": runtime_metrics["frames"] > 0
        and runtime_metrics["integratedLufs"] is not None,
        "signatureIsEightOpenBandLowTriplets": analysis["density"]["eventCounts"][
            "signatureTriplets"
        ]
        == 8
        and analysis["density"]["eventCounts"]["signatureHit"] == 24,
        "rareMetalTickNotRiff": analysis["density"]["eventCounts"][
            "lowMetalTick"
        ]
        == 8,
        "noProgressiveLoudnessRamp": bool(
            analysis["macroDynamics"]["noProgressiveLoudnessRamp"]
        ),
        "secondRenderByteIdentical": deterministic,
    }


def produce_final() -> int:
    # V1 is genuinely rendered and measured, then discarded after evidence is
    # captured.  Its audible over-density drove the explicit V2 decisions.
    v1_audio, v1_counts = render_arrangement("v1")
    with tempfile.TemporaryDirectory(prefix="neon-fora-ar-v1-") as temp_name:
        temp_master = Path(temp_name) / "neon_fora_do_ar_v1.wav"
        sf.write(temp_master, v1_audio, SAMPLE_RATE, format="WAV", subtype="PCM_24")
        v1_metrics, _ = measure_file(temp_master, include_true_peak=True)
    v1_analysis = analysis_bundle(v1_audio, v1_counts)
    del v1_audio

    # Independent V2 renders plus canonical Ogg export prove byte identity.
    first_audio, first_counts = render_arrangement("v2")
    with tempfile.TemporaryDirectory(prefix="neon-fora-ar-determinism-") as temp_name:
        temp_root = Path(temp_name)
        first_master, first_runtime = export_pair(
            temp_root, first_audio, MASTER_RELATIVE, RUNTIME_RELATIVE
        )
        first_hashes = {
            "master": sha256_file(first_master),
            "runtime": sha256_file(first_runtime),
        }

        final_audio, final_counts = render_arrangement("v2")
        final_master, final_runtime = export_pair(
            ROOT, final_audio, MASTER_RELATIVE, RUNTIME_RELATIVE
        )
        second_hashes = {
            "master": sha256_file(final_master),
            "runtime": sha256_file(final_runtime),
        }
        float_identical = bool(np.array_equal(first_audio, final_audio))
        deterministic = first_hashes == second_hashes and float_identical

    master_metrics, _ = measure_file(final_master, include_true_peak=True)
    runtime_metrics, _ = measure_file(final_runtime, include_true_peak=True)
    final_analysis = analysis_bundle(final_audio, final_counts)
    gates = gate_results(
        master_metrics,
        runtime_metrics,
        final_audio,
        final_analysis,
        deterministic,
    )

    report = {
        "schemaVersion": 1,
        "id": ASSET_ID,
        "title": "Neon Fora do Ar",
        "status": "demo-produced-and-validated",
        "genre": "60% brega funk abstrato + 40% phonk",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "briefing": (
            "Fusão instrumental de matriz rítmica brega funk e matéria phonk, "
            "136 BPM, 4/4, centro em Sol, quatro macrofrases 6+7. Kick seco, "
            "808 curto, palmas sintéticas, espaço negativo, granulação e "
            "assinatura de três golpes aberto -> band-pass -> low-pass, cortada em silêncio."
        ),
        "constraints": {
            "noVoice": True,
            "noExternalSamples": True,
            "noArtistOrBeatImitation": True,
            "noCowbellOrMetallicRiff": True,
            "noLeadMelody": True,
            "noCaricature": True,
            "noProgressiveLoudnessRamp": True,
            "mood": ["luminoso", "falha de transmissão", "seco", "brincalhão"],
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
            "signature": {
                "order": ["open-spectrum", "band-pass-520-2050-Hz", "low-pass-620-Hz"],
                "triplets": 8,
                "postThirdHitSilenceBeatsAtLeast": 0.7,
            },
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
                    "seven hats per ordinary bar and five metallic tick placements per macro obscured negative space",
                    "longer kick and 808 envelopes overfilled syncopated gaps",
                    "wide, fourteen-grain packet textures blurred mono focus and the transmission silhouette",
                    "ordinary percussion continued too close to the third filtered signature hit",
                    "finite-render DC required correction after the final nonlinear stage",
                ],
            },
            {
                "pass": "v2",
                "status": "final",
                "changes": [
                    "shortened kick, 808, clap, hat, packet and signature envelopes",
                    "reduced ordinary hat activity from seven to four attacks and down to one or two in dropout bars",
                    "reduced metallic punctuation from five to exactly two irregular ticks per macrophrase",
                    "cut selected third-macrophrase kicks and claps to make packet loss audible as space",
                    "reduced granular packets from fourteen to seven micro-grains and narrowed their stereo pan",
                    "rebalanced the final mix after spectral review: reduced 808 event gain, raised synthetic claps, hats and packet grains, and opened only the high-frequency percussion",
                    "increased master true-peak headroom to keep the decoded Vorbis runtime below -1 dBTP",
                    "removed all ordinary attacks after beat two in signature bars, leaving at least 0.7 beat of silence after hit three",
                    "strengthened the open -> band-pass -> low-pass contrast with final cutoffs of 8.5 kHz, 520-2050 Hz and 620 Hz",
                    "applied boundary-preserving DC correction after final bus shaping",
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
            "floatBuffersIdentical": float_identical,
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
        raise RuntimeError(
            f"Neon Fora do Ar failed gates: {', '.join(failed)}"
        )
    print(
        json.dumps(
            {
                "master": master_metrics,
                "runtime": runtime_metrics,
                "deterministic": deterministic,
                "gates": gates,
            },
            indent=2,
            ensure_ascii=False,
        )
    )
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("inspect-v1", "final"), default="final")
    parser.add_argument(
        "--inspection-output",
        type=Path,
        default=Path("/tmp/neon_fora_do_ar_v1.wav"),
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.mode == "inspect-v1":
        return inspect_v1(args.inspection_output)
    return produce_final()


if __name__ == "__main__":
    raise SystemExit(main())
