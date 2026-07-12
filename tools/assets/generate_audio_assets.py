#!/usr/bin/env python3
"""Generate the complete Aura Shift audio candidate set from deterministic DSP.

No external audio is read. Every waveform begins with oscillators or seeded
noise created in this process. This script deliberately stops at the honest
status ``candidate-generated``; the companion reviewer may advance automated
evidence to ``candidate-reviewed``, never to approved/integrated.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from importlib.metadata import version
import json
import math
from pathlib import Path
from typing import Any

import numpy as np

from audio_common import (
    add_signal,
    as_2d,
    bandpass,
    constant_power_pan,
    db_to_amp,
    dump_json,
    fade_edges,
    highpass,
    integrated_lufs,
    lowpass,
    measure_audio,
    normalize_loudness,
    normalize_peak,
    pcm16_dither_seed,
    rng_for,
    sha256_file,
    sha256_files,
    soft_clip,
    stable_seed,
    taper_loop_boundary,
    write_master_and_runtime,
)


def _frames(milliseconds: float, sample_rate: int) -> int:
    return int(round(milliseconds * sample_rate / 1000.0))


def _time(frame_count: int, sample_rate: int) -> np.ndarray:
    return np.arange(frame_count, dtype=np.float64) / sample_rate


def _phase(frequency: np.ndarray | float, sample_rate: int) -> np.ndarray:
    values = np.asarray(frequency, dtype=np.float64)
    return 2.0 * math.pi * np.cumsum(values) / sample_rate


def synth_kick(sample_rate: int, rng: np.random.Generator, duration: float = 0.19) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    frequency = 49.0 + 71.0 * np.exp(-t / 0.022)
    body = np.sin(_phase(frequency, sample_rate)) * np.exp(-t / 0.075)
    harmonic = 0.22 * np.sin(2.0 * _phase(frequency, sample_rate) + 0.3) * np.exp(-t / 0.045)
    click = highpass(rng.standard_normal(count), 2400.0, sample_rate, 2)
    click *= np.exp(-t / 0.006) * 0.035
    return fade_edges((body + harmonic) * 0.78 + click, sample_rate, 0.8, 14.0)


def synth_sub(
    sample_rate: int,
    frequency: float,
    duration: float = 0.31,
    articulation: float = 1.0,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    glide = frequency * (1.0 + 0.035 * np.exp(-t / 0.025))
    phase = _phase(glide, sample_rate)
    envelope = (1.0 - np.exp(-t / 0.006)) * np.exp(-t / (0.12 * articulation))
    body = np.sin(phase) + 0.24 * np.sin(2.0 * phase + 0.2)
    return fade_edges(body * envelope * 0.54, sample_rate, 1.0, 24.0)


def synth_hat(
    sample_rate: int,
    rng: np.random.Generator,
    duration: float = 0.075,
    brightness: float = 1.0,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    noise = rng.standard_normal(count)
    cutoff = float(np.clip(5200.0 * brightness, 3900.0, 7600.0))
    noise = highpass(noise, cutoff, sample_rate, 3)
    metallic = sum(
        np.sin(2.0 * math.pi * frequency * t + index * 0.71)
        for index, frequency in enumerate((5931.0, 7213.0, 8879.0))
    ) / 3.0
    envelope = np.exp(-t / (duration * 0.22))
    return fade_edges((noise * 0.13 + metallic * 0.035) * envelope, sample_rate, 0.3, 8.0)


def synth_clap(sample_rate: int, rng: np.random.Generator, duration: float = 0.19) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    noise = bandpass(rng.standard_normal(count), 520.0, 5200.0, sample_rate, 2)
    envelope = np.zeros(count, dtype=np.float64)
    for offset, strength in ((0.0, 1.0), (0.013, 0.74), (0.027, 0.52)):
        local = np.maximum(0.0, t - offset)
        envelope += strength * np.exp(-local / 0.026) * (t >= offset)
    envelope += 0.18 * np.exp(-t / 0.09)
    return fade_edges(noise * envelope * 0.16, sample_rate, 0.4, 16.0)


def synth_body_perc(
    sample_rate: int,
    rng: np.random.Generator,
    frequency: float,
    duration: float = 0.16,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    phase = 2.0 * math.pi * frequency * t
    resonator = (
        np.sin(phase) * np.exp(-t / 0.038)
        + 0.34 * np.sin(phase * 1.73 + 0.4) * np.exp(-t / 0.026)
    )
    noise = bandpass(rng.standard_normal(count), 240.0, 2600.0, sample_rate, 2)
    noise *= np.exp(-t / 0.018) * 0.07
    return fade_edges(resonator * 0.24 + noise, sample_rate, 0.5, 12.0)


def synth_stab(
    sample_rate: int,
    frequencies: tuple[float, ...],
    duration: float = 0.27,
    brightness: float = 1.0,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    envelope = (1.0 - np.exp(-t / 0.006)) * np.exp(-t / (duration * 0.24))
    output = np.zeros(count, dtype=np.float64)
    for voice, frequency in enumerate(frequencies):
        phase = 2.0 * math.pi * frequency * t + voice * 0.37
        output += np.sin(phase) + 0.22 * brightness * np.sin(2.0 * phase + 0.1)
    output /= max(1, len(frequencies))
    return fade_edges(output * envelope * 0.26, sample_rate, 0.8, 24.0)


def synth_texture(
    sample_rate: int,
    rng: np.random.Generator,
    duration: float = 0.42,
    low: float = 420.0,
    high: float = 3100.0,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    noise = bandpass(rng.standard_normal(count), low, high, sample_rate, 2)
    envelope = np.sin(np.linspace(0.0, math.pi, count, endpoint=True)) ** 1.7
    tremolo = 0.76 + 0.24 * np.sin(2.0 * math.pi * 6.7 * t + 0.4)
    return fade_edges(noise * envelope * tremolo * 0.085, sample_rate, 3.0, 22.0)


def synth_tick(
    sample_rate: int,
    rng: np.random.Generator,
    frequency: float,
    duration: float,
    downward: bool = True,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    ratio = 1.0 + (0.21 if downward else -0.12) * np.exp(-t / 0.018)
    phase = _phase(frequency * ratio, sample_rate)
    envelope = (1.0 - np.exp(-t / 0.0014)) * np.exp(-t / (duration * 0.24))
    tone = np.sin(phase) + 0.16 * np.sin(2.0 * phase + 0.6)
    transient = highpass(rng.standard_normal(count), 1800.0, sample_rate, 2)
    transient *= np.exp(-t / 0.004) * 0.028
    return fade_edges(tone * envelope * 0.42 + transient, sample_rate, 0.3, 8.0)


def synth_whoosh(
    sample_rate: int,
    rng: np.random.Generator,
    duration: float,
    rising: bool,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    noise = bandpass(rng.standard_normal(count), 480.0, 6400.0, sample_rate, 2)
    position = t / max(duration, 1.0e-6)
    envelope = np.sin(math.pi * position) ** 1.5
    tilt = (0.35 + 0.65 * position) if rising else (1.0 - 0.65 * position)
    chirp = signal_chirp(t, 620.0 if rising else 1750.0, 1750.0 if rising else 620.0)
    return fade_edges((noise * 0.085 + chirp * 0.045) * envelope * tilt, sample_rate, 2.0, 12.0)


def signal_chirp(t: np.ndarray, start_frequency: float, end_frequency: float) -> np.ndarray:
    if t.size == 0:
        return np.zeros(0, dtype=np.float64)
    duration = max(float(t[-1]), 1.0e-6)
    slope = (end_frequency - start_frequency) / duration
    return np.sin(2.0 * math.pi * (start_frequency * t + 0.5 * slope * t * t))


def synth_impact(
    sample_rate: int,
    rng: np.random.Generator,
    duration: float = 0.31,
    frequency: float = 118.0,
) -> np.ndarray:
    count = int(round(duration * sample_rate))
    t = _time(count, sample_rate)
    glide = frequency * (1.0 + 0.34 * np.exp(-t / 0.021))
    phase = _phase(glide, sample_rate)
    body = (np.sin(phase) + 0.25 * np.sin(2.0 * phase + 0.4)) * np.exp(-t / 0.085)
    noise = bandpass(rng.standard_normal(count), 330.0, 3600.0, sample_rate, 2)
    noise *= np.exp(-t / 0.019) * 0.07
    return fade_edges(body * 0.46 + noise, sample_rate, 0.6, 20.0)


def beat_sample(beat: float, sample_rate: int, bpm: float) -> int:
    return int(round(beat * 60.0 * sample_rate / bpm))


def render_game_stems(score: dict[str, Any]) -> dict[str, np.ndarray]:
    sr = score["sampleRate"]
    bpm = score["bpm"]
    length = score["gameLoopSamples"]
    seed = score["masterSeed"]
    buffers = {
        "game_base": np.zeros((length, 2), dtype=np.float32),
        "game_groove": np.zeros((length, 2), dtype=np.float32),
        "game_hype": np.zeros((length, 2), dtype=np.float32),
    }
    base_rng = rng_for(seed, "MUS-GAME-BASE")
    groove_rng = rng_for(seed, "MUS-GAME-GROOVE")
    hype_rng = rng_for(seed, "MUS-GAME-HYPE")
    phrase_roots = (54.0, 60.0, 51.0, 57.0)

    for bar in range(score["gameBars"]):
        phrase = bar // 13
        local_bar = bar % 13
        impulse = local_bar < 6
        root = phrase_roots[phrase]
        bar_beat = bar * 4.0

        kick_positions = [0.0, 2.5 if impulse else 2.75]
        if local_bar in (5, 12):
            kick_positions.append(3.5)
        for index, offset in enumerate(kick_positions):
            event = synth_kick(sr, base_rng, 0.18 + 0.008 * ((bar + index) % 2))
            add_signal(
                buffers["game_base"],
                constant_power_pan(event, 0.0),
                beat_sample(bar_beat + offset, sr, bpm),
                gain=0.76 if index else 0.92,
                circular=True,
            )
            sub = synth_sub(sr, root * (1.0 if index == 0 else 1.125), 0.28, 1.0 + 0.06 * phrase)
            add_signal(
                buffers["game_base"],
                constant_power_pan(sub, 0.0),
                beat_sample(bar_beat + offset, sr, bpm),
                gain=0.76 if index == 0 else 0.54,
                circular=True,
            )

        if local_bar % 2 == 0:
            frequencies = (root * 2.0, root * 2.7, root * 3.54)
            stab = synth_stab(sr, frequencies, 0.25, 0.72)
            add_signal(
                buffers["game_base"],
                constant_power_pan(stab, -0.08 if phrase % 2 == 0 else 0.08),
                beat_sample(bar_beat + (1.75 if impulse else 3.25), sr, bpm),
                gain=0.42,
                circular=True,
            )
        texture = synth_texture(sr, base_rng, 0.34, 360.0, 2200.0)
        add_signal(
            buffers["game_base"],
            constant_power_pan(texture, 0.12 if bar % 2 else -0.12),
            beat_sample(bar_beat + (3.0 if impulse else 1.5), sr, bpm),
            gain=0.28,
            circular=True,
        )

        clap_offsets = (1.0, 3.0) if impulse else (1.25, 3.0)
        for offset in clap_offsets:
            clap = synth_clap(sr, groove_rng, 0.18)
            add_signal(
                buffers["game_groove"],
                constant_power_pan(clap, -0.04 if offset < 2 else 0.04),
                beat_sample(bar_beat + offset, sr, bpm),
                gain=0.66,
                circular=True,
            )
        subdivision = 0.5 if local_bar not in (4, 5, 11, 12) else 0.25
        offset = 0.5
        hat_index = 0
        while offset < 4.0:
            if not (subdivision == 0.25 and hat_index % 4 == 2 and local_bar % 2):
                hat = synth_hat(sr, groove_rng, 0.052 + 0.012 * (hat_index % 2), 0.88 + 0.08 * phrase)
                velocity = 0.22 + 0.10 * ((hat_index + bar) % 3 == 0)
                add_signal(
                    buffers["game_groove"],
                    constant_power_pan(hat, -0.13 if hat_index % 2 else 0.13),
                    beat_sample(bar_beat + offset, sr, bpm),
                    gain=velocity,
                    circular=True,
                )
            offset += subdivision
            hat_index += 1
        for perc_index, offset in enumerate((0.75, 2.25 if impulse else 2.0, 3.625)):
            perc = synth_body_perc(sr, groove_rng, 215.0 + 38.0 * ((bar + perc_index) % 3), 0.14)
            add_signal(
                buffers["game_groove"],
                constant_power_pan(perc, (-0.16, 0.0, 0.16)[perc_index]),
                beat_sample(bar_beat + offset, sr, bpm),
                gain=0.46,
                circular=True,
            )

        hype_offsets = (0.375, 1.875, 3.375) if impulse else (0.625, 2.125, 3.625)
        for hype_index, offset in enumerate(hype_offsets):
            tick = synth_tick(sr, hype_rng, 480.0 + 67.0 * ((bar + hype_index) % 4), 0.085, downward=False)
            add_signal(
                buffers["game_hype"],
                constant_power_pan(tick, -0.18 if hype_index % 2 == 0 else 0.18),
                beat_sample(bar_beat + offset, sr, bpm),
                gain=0.34,
                circular=True,
            )
        if local_bar in (5, 12):
            aura = synth_texture(sr, hype_rng, 0.78, 650.0, 4800.0)
            stereo = constant_power_pan(aura, -0.16)
            delayed = np.roll(stereo[:, 0], _frames(5.0, sr))
            stereo[:, 1] = 0.72 * stereo[:, 1] + 0.28 * delayed
            add_signal(
                buffers["game_hype"],
                stereo,
                beat_sample(bar_beat + 2.75, sr, bpm),
                gain=0.52,
                circular=True,
            )
            response = synth_stab(sr, (root * 3.0, root * 4.05), 0.31, 0.9)
            add_signal(
                buffers["game_hype"],
                constant_power_pan(response, 0.1),
                beat_sample(bar_beat + 3.5, sr, bpm),
                gain=0.37,
                circular=True,
            )

    buffers["game_base"] = soft_clip(buffers["game_base"] * 1.18, 1.28)
    buffers["game_groove"] = soft_clip(buffers["game_groove"] * 1.35, 1.22)
    buffers["game_hype"] = soft_clip(buffers["game_hype"] * 1.45, 1.18)
    return buffers


def render_menu_or_shop(score: dict[str, Any], *, shop: bool) -> np.ndarray:
    sr = score["sampleRate"]
    bpm = score["bpm"]
    length = score["menuLoopSamples"]
    seed = score["masterSeed"]
    label = "MUS-SHOP" if shop else "MUS-MENU"
    rng = rng_for(seed, label)
    buffer = np.zeros((length, 2), dtype=np.float32)
    roots = (54.0, 60.0)
    for bar in range(score["menuBars"]):
        root = roots[bar // 13]
        local = bar % 13
        bar_beat = bar * 4.0
        if bar % (1 if shop else 2) == 0:
            pulse = synth_sub(sr, root * 2.0, 0.22, 0.84)
            add_signal(
                buffer,
                constant_power_pan(pulse, 0.0),
                beat_sample(bar_beat, sr, bpm),
                gain=0.24 if shop else 0.18,
                circular=True,
            )
        stab = synth_stab(sr, (root * 2.0, root * 2.7), 0.31 if shop else 0.38, 0.52)
        add_signal(
            buffer,
            constant_power_pan(stab, -0.1 if bar % 2 == 0 else 0.1),
            beat_sample(bar_beat + (1.5 if local < 6 else 2.5), sr, bpm),
            gain=0.34 if shop else 0.28,
            circular=True,
        )
        texture = synth_texture(sr, rng, 0.62, 280.0, 1900.0 if not shop else 2800.0)
        add_signal(
            buffer,
            constant_power_pan(texture, 0.12 if local % 2 else -0.12),
            beat_sample(bar_beat + 3.0, sr, bpm),
            gain=0.42,
            circular=True,
        )
        if shop:
            for index, offset in enumerate((0.75, 2.25, 3.5)):
                perc = synth_body_perc(sr, rng, 250.0 + index * 64.0, 0.13)
                add_signal(
                    buffer,
                    constant_power_pan(perc, (-0.1, 0.1, 0.0)[index]),
                    beat_sample(bar_beat + offset, sr, bpm),
                    gain=0.26,
                    circular=True,
                )
        elif local in (5, 12):
            breath = synth_whoosh(sr, rng, 0.42, rising=False)
            add_signal(
                buffer,
                constant_power_pan(breath, 0.08),
                beat_sample(bar_beat + 3.25, sr, bpm),
                gain=0.18,
                circular=True,
            )
    return soft_clip(buffer * (1.5 if shop else 1.7), 1.18)


def render_cycle(asset: dict[str, Any], score: dict[str, Any]) -> np.ndarray:
    sr = score["sampleRate"]
    rng = rng_for(score["masterSeed"], asset["id"])
    duration = asset["durationMs"] / 1000.0
    variant = asset["variant"]
    if asset["kind"] == "six":
        family = (178.0, 214.0, 252.0)[(variant - 1) // 2]
        articulation = 0.92 if variant % 2 else 1.08
        tick = synth_tick(sr, rng, family * articulation, duration, downward=True)
        perc = synth_body_perc(sr, rng, 132.0 + variant * 9.0, duration)
        audio = tick * 0.61 + perc * 0.23
    else:
        family = (116.0, 132.0, 148.0)[(variant - 1) // 2]
        impact = synth_impact(sr, rng, duration, family)
        tick = synth_tick(sr, rng, 310.0 + variant * 29.0, duration, downward=True)
        audio = impact * 0.74 + tick * 0.19
    audio = fade_edges(soft_clip(audio, 1.18), sr, 0.4, 7.0)
    return normalize_peak(audio, asset["peakCeilingDbfs"])


def _blank(asset: dict[str, Any], sample_rate: int, channels: int | None = None) -> np.ndarray:
    count = _frames(asset["durationMs"], sample_rate)
    channel_count = channels or asset["channels"]
    return (
        np.zeros((count, channel_count), dtype=np.float32)
        if channel_count > 1
        else np.zeros(count, dtype=np.float32)
    )


def render_ui(asset: dict[str, Any], score: dict[str, Any]) -> np.ndarray:
    sr = score["sampleRate"]
    rng = rng_for(score["masterSeed"], asset["id"])
    duration = asset["durationMs"] / 1000.0
    kind = asset["kind"]
    output = _blank(asset, sr, 1)

    def add(event: np.ndarray, at_ms: float = 0.0, gain: float = 1.0) -> None:
        add_signal(output, event, _frames(at_ms, sr), gain=gain)

    if kind == "ui_tab":
        add(synth_tick(sr, rng, 510.0, duration, downward=False))
    elif kind in ("ui_open", "ui_close"):
        add(synth_whoosh(sr, rng, duration, rising=kind == "ui_open"))
        add(synth_tick(sr, rng, 430.0 if kind == "ui_open" else 340.0, duration * 0.62, downward=kind == "ui_close"), 18.0, 0.34)
    elif kind in ("ui_toggle_on", "ui_toggle_off"):
        on = kind == "ui_toggle_on"
        add(synth_tick(sr, rng, 470.0 if on else 390.0, duration * 0.72, downward=not on), 0.0, 0.75)
        add(synth_tick(sr, rng, 610.0 if on else 320.0, duration * 0.48, downward=not on), 42.0, 0.42)
    elif kind in ("ui_error", "shop_unavailable"):
        t = _time(output.shape[0], sr)
        chirp = signal_chirp(t, 430.0 if kind == "ui_error" else 360.0, 185.0)
        noise = bandpass(rng.standard_normal(output.shape[0]), 260.0, 1800.0, sr, 2)
        envelope = np.exp(-t / (duration * 0.34))
        output[:] = (chirp * 0.32 + noise * 0.07) * envelope
    elif kind in ("shop_purchase", "shop_batch"):
        add(synth_body_perc(sr, rng, 196.0, min(0.2, duration)), 0.0, 0.76)
        add(synth_tick(sr, rng, 360.0, min(0.24, duration * 0.64), downward=False), 58.0, 0.46)
        if kind == "shop_batch":
            add(synth_impact(sr, rng, 0.34, 104.0), 110.0, 0.34)
    elif kind == "shop_unlock":
        for index, at_ms in enumerate((0.0, 165.0, 345.0)):
            add(synth_tick(sr, rng, 280.0 + 82.0 * index, 0.24, downward=False), at_ms, 0.52 - 0.04 * index)
        add(synth_texture(sr, rng, 0.52, 520.0, 2800.0), 280.0, 0.38)
    elif kind == "shop_milestone":
        add(synth_body_perc(sr, rng, 212.0, 0.24), 0.0, 0.68)
        add(synth_stab(sr, (286.0, 392.0), 0.42, 0.7), 120.0, 0.52)
    elif kind in ("collection_equip", "collection_hide"):
        rising = kind == "collection_equip"
        add(synth_whoosh(sr, rng, duration, rising=rising), 0.0, 0.78)
        add(synth_tick(sr, rng, 520.0 if rising else 310.0, duration * 0.42, downward=not rising), duration * 520.0, 0.32)
    else:
        raise ValueError(f"unsupported UI kind: {kind}")
    output = fade_edges(soft_clip(output, 1.16), sr, 0.4, 8.0)
    return normalize_peak(output, asset["peakCeilingDbfs"])


def render_stinger(asset: dict[str, Any], score: dict[str, Any]) -> np.ndarray:
    sr = score["sampleRate"]
    rng = rng_for(score["masterSeed"], asset["id"])
    output = _blank(asset, sr, 2)
    duration = asset["durationMs"] / 1000.0

    def add(event: np.ndarray, at: float, gain: float = 1.0, pan: float = 0.0) -> None:
        add_signal(output, constant_power_pan(event, pan), int(round(at * sr)), gain=gain)

    kind = asset["kind"]
    if kind == "form":
        variant = asset["variant"]
        pulse_count = variant + 1
        spacing = min(0.24, (duration * 0.54) / pulse_count)
        for index in range(pulse_count):
            base = 180.0 + variant * 17.0 + index * 31.0
            add(synth_body_perc(sr, rng, base, min(0.23, duration * 0.2)), index * spacing, 0.42, -0.14 + 0.28 * (index % 2))
        frequencies = (110.0 + variant * 7.0, 148.5 + variant * 9.45, 194.7 + variant * 12.39)
        add(synth_stab(sr, frequencies, duration * 0.54, 0.62 + variant * 0.05), duration * 0.24, 0.62, 0.0)
        add(synth_texture(sr, rng, duration * 0.48, 420.0, 3200.0 + variant * 270.0), duration * 0.46, 0.55, 0.12)
    elif kind == "achievement":
        add(synth_body_perc(sr, rng, 246.0, 0.22), 0.0, 0.52, -0.08)
        add(synth_stab(sr, (330.0, 445.5), 0.5, 0.72), 0.12, 0.58, 0.08)
        add(synth_texture(sr, rng, 0.38, 700.0, 3600.0), 0.36, 0.34, 0.0)
    elif kind == "ascension":
        contraction = synth_whoosh(sr, rng, 0.86, rising=False)
        add(contraction, 0.0, 0.55, -0.08)
        add(synth_impact(sr, rng, 0.72, 76.0), 0.72, 0.65, 0.0)
        opening = synth_whoosh(sr, rng, 1.18, rising=True)
        add(opening, 1.02, 0.64, 0.1)
        add(synth_stab(sr, (108.0, 145.8, 191.16), 1.12, 0.72), 1.56, 0.72, 0.0)
        add(synth_texture(sr, rng, 1.12, 380.0, 4200.0), 1.94, 0.48, -0.04)
    elif kind == "mark67":
        for index in range(6):
            tick = synth_tick(sr, rng, 360.0 + index * 43.0, 0.105, downward=False)
            add(tick, 0.10 + index * 0.13, 0.38, -0.16 if index % 2 == 0 else 0.16)
        add(synth_impact(sr, rng, 0.72, 92.0), 0.86, 0.72, 0.0)
        add(synth_texture(sr, rng, 0.68, 520.0, 3900.0), 0.94, 0.46, 0.08)
    else:
        raise ValueError(f"unsupported stinger kind: {kind}")
    output = fade_edges(soft_clip(output * 1.25, 1.26), sr, 1.0, 24.0)
    return normalize_loudness(
        output,
        sr,
        asset["targetLufs"],
        asset["truePeakCeilingDbtp"],
    )


def render_return(asset: dict[str, Any], score: dict[str, Any]) -> np.ndarray:
    sr = score["sampleRate"]
    rng = rng_for(score["masterSeed"], asset["id"])
    output = _blank(asset, sr, 1)
    if asset["kind"] == "return_offline":
        add_signal(output, synth_whoosh(sr, rng, 0.42, rising=False), 0, gain=0.62)
        add_signal(output, synth_body_perc(sr, rng, 176.0, 0.25), _frames(150.0, sr), gain=0.44)
    else:
        add_signal(output, synth_body_perc(sr, rng, 188.0, 0.28), 0, gain=0.52)
        add_signal(output, synth_tick(sr, rng, 330.0, 0.32, downward=False), _frames(120.0, sr), gain=0.42)
        add_signal(output, synth_texture(sr, rng, 0.36, 520.0, 2600.0), _frames(220.0, sr), gain=0.28)
    output = fade_edges(soft_clip(output, 1.18), sr, 0.8, 12.0)
    return normalize_peak(output, asset["peakCeilingDbfs"])


def asset_by_kind(score: dict[str, Any], kind: str) -> dict[str, Any]:
    return next(asset for asset in score["assets"] if asset["kind"] == kind)


def quick_entry(root: Path, asset: dict[str, Any], audio: np.ndarray, score: dict[str, Any]) -> dict[str, Any]:
    metrics = measure_audio(audio, score["sampleRate"], include_true_peak=False)
    return {
        "id": asset["id"],
        "revision": score["revision"],
        "status": "candidate-generated",
        "required": asset.get("required", False),
        "conditional": asset.get("conditional", False),
        "group": asset["group"],
        "kind": asset["kind"],
        "masterPath": asset["master"],
        "runtimePath": asset["runtime"],
        "sampleRate": score["sampleRate"],
        "channels": asset["channels"],
        "loop": "loopSamples" in asset,
        "loopStartSample": 0 if "loopSamples" in asset else None,
        "loopEndSample": asset.get("loopSamples"),
        "sourceSeed": stable_seed(score["masterSeed"], asset["id"]),
        "sourceScore": "sources/audio/procedural/score-v1.json",
        "masterSha256": sha256_file(root / asset["master"]),
        "runtimeSha256": sha256_file(root / asset["runtime"]),
        "runtimeDither": (
            {
                "type": "TPDF",
                "seed": pcm16_dither_seed(asset["id"]),
                "peakToPeakLsb": 2,
                "source": "encoded PCM24 master",
            }
            if asset["group"] != "music"
            else None
        ),
        "generatedMetrics": metrics,
        "reviewedMetrics": None,
        "licenseRecord": f"provenance/audio/{asset['id'].lower()}.md",
    }


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


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    pipeline_root = Path(__file__).resolve().parents[2]
    score_path = args.score if args.score.is_absolute() else root / args.score
    score = json.loads(score_path.read_text(encoding="utf-8"))
    sr = score["sampleRate"]
    compression_level = score["runtimeEncoding"]["music"]["compressionLevel"]
    assets = {asset["kind"]: asset for asset in score["assets"] if asset["group"] == "music"}
    entries: list[dict[str, Any]] = []

    print("[audio] rendering aligned gameplay stems", flush=True)
    stems = render_game_stems(score)
    for kind in ("game_base", "game_groove", "game_hype"):
        asset = assets[kind]
        audio = taper_loop_boundary(
            stems.pop(kind), score["loopBoundaryTreatment"]["fadeFrames"]
        )
        audio = normalize_loudness(
            audio, sr, asset["targetLufs"], asset["truePeakCeilingDbtp"]
        )
        write_master_and_runtime(root, asset, audio, sr, compression_level)
        entries.append(quick_entry(root, asset, audio, score))
        print(f"[audio] wrote {asset['id']}", flush=True)
        del audio
    del stems

    for kind, shop in (("menu", False), ("shop", True)):
        asset = assets[kind]
        audio = render_menu_or_shop(score, shop=shop)
        audio = taper_loop_boundary(
            audio, score["loopBoundaryTreatment"]["fadeFrames"]
        )
        audio = normalize_loudness(audio, sr, asset["targetLufs"], asset["truePeakCeilingDbtp"])
        write_master_and_runtime(root, asset, audio, sr, compression_level)
        entries.append(quick_entry(root, asset, audio, score))
        print(f"[audio] wrote {asset['id']}", flush=True)

    music_by_id = {asset["id"]: asset for asset in score["assets"]}
    import soundfile as sf

    base, _ = sf.read(
        root / music_by_id["MUS-GAME-BASE"]["master"],
        dtype="float32",
        always_2d=True,
    )
    groove, _ = sf.read(
        root / music_by_id["MUS-GAME-GROOVE"]["master"],
        dtype="float32",
        always_2d=True,
    )
    hype, _ = sf.read(
        root / music_by_id["MUS-GAME-HYPE"]["master"],
        dtype="float32",
        always_2d=True,
    )
    mix_kinds = ("mix_i0", "mix_i1", "mix_i2", "mix_i3")
    for kind in mix_kinds:
        if kind == "mix_i0":
            raw = base.copy()
        elif kind == "mix_i1":
            raw = base + groove * np.float32(db_to_amp(-12.0))
        elif kind == "mix_i2":
            raw = (
                base
                + groove * np.float32(db_to_amp(-6.0))
                + hype * np.float32(db_to_amp(-18.0))
            )
        else:
            raw = base + groove + hype * np.float32(db_to_amp(-6.0))
        asset = assets[kind]
        audio = taper_loop_boundary(
            soft_clip(raw, 1.08), score["loopBoundaryTreatment"]["fadeFrames"]
        )
        audio = normalize_loudness(
            audio, sr, asset["targetLufs"], asset["truePeakCeilingDbtp"]
        )
        del raw
        write_master_and_runtime(root, asset, audio, sr, compression_level)
        entries.append(quick_entry(root, asset, audio, score))
        print(f"[audio] wrote {asset['id']}", flush=True)
        del audio

    del base, groove, hype

    for asset in score["assets"]:
        if asset["group"] == "music":
            continue
        if asset["group"] == "cycle":
            audio = render_cycle(asset, score)
        elif asset["group"] == "ui":
            audio = render_ui(asset, score)
        elif asset["kind"] in ("form", "achievement", "ascension", "mark67"):
            audio = render_stinger(asset, score)
        else:
            audio = render_return(asset, score)
        write_master_and_runtime(root, asset, audio, sr, compression_level)
        entries.append(quick_entry(root, asset, audio, score))
        print(f"[audio] wrote {asset['id']}", flush=True)

    order = {asset["id"]: index for index, asset in enumerate(score["assets"])}
    entries.sort(key=lambda item: order[item["id"]])
    source_files = [
        score_path,
        pipeline_root / "tools/assets/generate_audio_assets.py",
        pipeline_root / "tools/assets/audio_common.py",
        pipeline_root / "tools/assets/requirements-audio.txt",
    ]
    manifest = {
        "contract": "audio-candidate-manifest-v1",
        "revision": score["revision"],
        "status": "candidate-generated",
        "generatedAtUtc": datetime.now(timezone.utc).isoformat(),
        "sourceBundleSha256": sha256_files(source_files, base=pipeline_root),
        "sourceBundleContract": "audio-generation-source-bundle-v2",
        "sourceBundleFiles": [
            path.resolve().relative_to(pipeline_root.resolve()).as_posix()
            for path in source_files
        ],
        "sourcePolicy": score["sourcePolicy"],
        "sampleRate": sr,
        "masterBitDepth": score["masterBitDepth"],
        "runtimeEncoding": score["runtimeEncoding"],
        "loopBoundaryTreatment": score["loopBoundaryTreatment"],
        "toolVersions": {
            "python": __import__("platform").python_version(),
            "numpy": version("numpy"),
            "scipy": version("scipy"),
            "soundfile": version("soundfile"),
            "libsndfile": __import__("soundfile").__libsndfile_version__,
            "pyloudnorm": version("pyloudnorm"),
        },
        "counts": {"required": 40, "conditional": 4, "total": 44},
        "humanReview": "pending",
        "similarityReview": "pending",
        "androidDeviceReview": "pending",
        "assets": entries,
    }
    dump_json(root / "assets/audio/audio-candidate-manifest-v1.json", manifest)
    master_manifest = {
        **{key: value for key, value in manifest.items() if key != "assets"},
        "contract": "audio-master-candidate-manifest-v1",
        "assets": [
            {
                "id": entry["id"],
                "status": entry["status"],
                "path": entry["masterPath"],
                "sha256": entry["masterSha256"],
                "loopStartSample": entry["loopStartSample"],
                "loopEndSample": entry["loopEndSample"],
            }
            for entry in entries
        ],
    }
    dump_json(root / "masters/audio/master-candidate-manifest-v1.json", master_manifest)
    print("[audio] generation complete: 40 required + 4 conditional candidates", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
