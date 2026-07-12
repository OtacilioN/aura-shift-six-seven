#!/usr/bin/env python3
"""Shared deterministic DSP and evidence helpers for the audio asset pipeline."""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
from typing import Any

import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy import signal


EPSILON = 1.0e-12
PCM16_DITHER_NAMESPACE = "aura-shift-pcm16-tpdf-v1"


def db_to_amp(db: float) -> float:
    return float(10.0 ** (db / 20.0))


def amp_to_db(value: float) -> float:
    return float(20.0 * math.log10(max(abs(value), EPSILON)))


def stable_seed(master_seed: str, label: str) -> int:
    digest = hashlib.sha256(f"{master_seed}:{label}".encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big", signed=False)


def rng_for(master_seed: str, label: str) -> np.random.Generator:
    return np.random.default_rng(stable_seed(master_seed, label))


def pcm16_dither_seed(stable_label: str) -> int:
    return stable_seed(PCM16_DITHER_NAMESPACE, stable_label)


def tpdf_dither_pcm16(audio: np.ndarray, stable_label: str) -> np.ndarray:
    """Quantize normalized PCM to int16 with deterministic 2-LSB-peak TPDF dither.

    The two independent uniform streams form triangular noise in [-1, 1) LSB.
    NumPy is pinned by the audio requirements, and the seed is derived from the
    stable asset ID, so the runtime export is reproducible byte for byte.
    """
    data = as_2d(audio).astype(np.float64, copy=False)
    rng = np.random.default_rng(pcm16_dither_seed(stable_label))
    dither_lsb = rng.random(data.shape) - rng.random(data.shape)
    quantized = np.rint(data * 32768.0 + dither_lsb)
    return np.clip(quantized, -32768, 32767).astype(np.int16)


def as_2d(audio: np.ndarray) -> np.ndarray:
    data = np.asarray(audio, dtype=np.float32)
    return data[:, None] if data.ndim == 1 else data


def mono(audio: np.ndarray) -> np.ndarray:
    data = as_2d(audio)
    return np.mean(data, axis=1)


def constant_power_pan(audio: np.ndarray, pan: float = 0.0) -> np.ndarray:
    source = mono(audio)
    p = float(np.clip(pan, -1.0, 1.0))
    angle = (p + 1.0) * math.pi / 4.0
    return np.column_stack((source * math.cos(angle), source * math.sin(angle)))


def fade_edges(
    audio: np.ndarray,
    sample_rate: int,
    fade_in_ms: float = 2.0,
    fade_out_ms: float = 8.0,
) -> np.ndarray:
    data = np.array(audio, dtype=np.float32, copy=True)
    frames = data.shape[0]
    fade_in = min(frames, max(0, int(round(fade_in_ms * sample_rate / 1000.0))))
    fade_out = min(frames, max(0, int(round(fade_out_ms * sample_rate / 1000.0))))
    if fade_in:
        curve = np.sin(np.linspace(0.0, math.pi / 2.0, fade_in, endpoint=True)) ** 2
        data[:fade_in] *= curve[:, None] if data.ndim == 2 else curve
    if fade_out:
        curve = np.cos(np.linspace(0.0, math.pi / 2.0, fade_out, endpoint=True)) ** 2
        data[-fade_out:] *= curve[:, None] if data.ndim == 2 else curve
    return data


def taper_loop_boundary(audio: np.ndarray, fade_frames: int) -> np.ndarray:
    """Create a short deterministic low-energy boundary around a loop seam.

    Lossy decoders disagree about Vorbis pre-skip and final-packet trimming.
    A squared-sine taper keeps both sides of the encoded boundary near digital
    zero even when a decoder begins 128 frames into the logical PCM stream.
    """
    data = np.array(audio, dtype=np.float32, copy=True)
    frames = int(fade_frames)
    if frames < 2 or frames * 2 >= data.shape[0]:
        raise ValueError(
            f"loop boundary fade must be >= 2 and shorter than half the file: {frames}"
        )
    curve = np.sin(np.linspace(0.0, math.pi / 2.0, frames, endpoint=True)) ** 2
    curve = curve.astype(np.float32)
    if data.ndim == 2:
        data[:frames] *= curve[:, None]
        data[-frames:] *= curve[::-1, None]
    else:
        data[:frames] *= curve
        data[-frames:] *= curve[::-1]
    data[0] = 0.0
    data[-1] = 0.0
    return data


def soft_clip(audio: np.ndarray, drive: float = 1.35) -> np.ndarray:
    data = np.asarray(audio, dtype=np.float32)
    return (np.tanh(data * np.float32(drive)) / np.float32(math.tanh(drive))).astype(
        np.float32, copy=False
    )


def crest_compress(audio: np.ndarray, drive: float) -> np.ndarray:
    """Reduce crest factor with a symmetric, DC-neutral static curve."""
    data = np.asarray(audio, dtype=np.float32)
    peak = float(np.max(np.abs(data), initial=0.0))
    if peak <= EPSILON:
        return data
    normalized = data / np.float32(peak)
    shaped = np.tanh(normalized * np.float32(drive)) / np.float32(math.tanh(drive))
    return shaped.astype(np.float32, copy=False) * np.float32(peak)


def _sos(kind: str, cutoff: float | tuple[float, float], sample_rate: int, order: int = 3):
    nyquist = sample_rate / 2.0
    if isinstance(cutoff, tuple):
        normalized = (cutoff[0] / nyquist, cutoff[1] / nyquist)
    else:
        normalized = cutoff / nyquist
    return signal.butter(order, normalized, btype=kind, output="sos")


def lowpass(audio: np.ndarray, cutoff: float, sample_rate: int, order: int = 3) -> np.ndarray:
    return signal.sosfilt(_sos("lowpass", cutoff, sample_rate, order), audio, axis=0)


def highpass(audio: np.ndarray, cutoff: float, sample_rate: int, order: int = 3) -> np.ndarray:
    return signal.sosfilt(_sos("highpass", cutoff, sample_rate, order), audio, axis=0)


def bandpass(
    audio: np.ndarray,
    low: float,
    high: float,
    sample_rate: int,
    order: int = 2,
) -> np.ndarray:
    return signal.sosfilt(_sos("bandpass", (low, high), sample_rate, order), audio, axis=0)


def add_signal(
    destination: np.ndarray,
    source: np.ndarray,
    start: int,
    *,
    gain: float = 1.0,
    circular: bool = False,
) -> None:
    """Add a mono/stereo signal, optionally wrapping tails around a loop boundary."""
    target = destination
    incoming = np.asarray(source, dtype=np.float32)
    if target.ndim == 2 and incoming.ndim == 1:
        incoming = np.repeat(incoming[:, None], target.shape[1], axis=1)
    if target.ndim == 1 and incoming.ndim == 2:
        incoming = np.mean(incoming, axis=1)
    if circular:
        length = target.shape[0]
        offset = 0
        cursor = start % length
        while offset < incoming.shape[0]:
            count = min(length - cursor, incoming.shape[0] - offset)
            target[cursor : cursor + count] += incoming[offset : offset + count] * gain
            offset += count
            cursor = 0
        return
    if start >= target.shape[0] or start + incoming.shape[0] <= 0:
        return
    source_start = max(0, -start)
    target_start = max(0, start)
    count = min(incoming.shape[0] - source_start, target.shape[0] - target_start)
    target[target_start : target_start + count] += (
        incoming[source_start : source_start + count] * gain
    )


def integrated_lufs(audio: np.ndarray, sample_rate: int) -> float | None:
    data = np.asarray(audio, dtype=np.float32)
    if data.shape[0] < int(sample_rate * 0.4):
        return None
    try:
        value = float(pyln.Meter(sample_rate).integrated_loudness(data))
    except (ValueError, OverflowError, ZeroDivisionError):
        return None
    return value if math.isfinite(value) else None


def true_peak(
    audio: np.ndarray,
    oversample: int = 4,
    block_frames: int = 262_144,
    overlap_frames: int = 96,
) -> float:
    """Estimate inter-sample peak with bounded memory.

    Blocks include overlap so the polyphase filter reaches the same local result
    around boundaries without allocating a 4x version of an entire music loop.
    """
    data = as_2d(audio).astype(np.float32, copy=False)
    maximum = 0.0
    for channel in range(data.shape[1]):
        source = data[:, channel]
        for start in range(0, source.shape[0], block_frames):
            end = min(source.shape[0], start + block_frames)
            padded_start = max(0, start - overlap_frames)
            padded_end = min(source.shape[0], end + overlap_frames)
            upsampled = signal.resample_poly(
                source[padded_start:padded_end], oversample, 1
            )
            trim_left = (start - padded_start) * oversample
            trim_right = trim_left + (end - start) * oversample
            core = upsampled[trim_left:trim_right]
            maximum = max(maximum, float(np.max(np.abs(core), initial=0.0)))
    return maximum


def normalize_peak(audio: np.ndarray, target_dbfs: float) -> np.ndarray:
    data = np.asarray(audio, dtype=np.float32)
    peak = float(np.max(np.abs(data), initial=0.0))
    if peak <= EPSILON:
        return data
    return data * np.float32(db_to_amp(target_dbfs) / peak)


def normalize_loudness(
    audio: np.ndarray,
    sample_rate: int,
    target_lufs: float,
    true_peak_ceiling_dbtp: float,
) -> np.ndarray:
    original = np.asarray(audio, dtype=np.float32)
    ceiling = db_to_amp(true_peak_ceiling_dbtp)
    candidate = original
    for drive in (1.0, 1.25, 1.55, 1.95, 2.45, 3.1, 4.0):
        working = original if drive == 1.0 else crest_compress(original, drive)
        measured = integrated_lufs(working, sample_rate)
        if measured is None:
            raise ValueError("loudness normalization requires at least 400 ms of signal")
        candidate = working * np.float32(db_to_amp(target_lufs - measured))
        peak = true_peak(candidate)
        if peak <= ceiling:
            return candidate
    # Honest last resort: preserve the peak gate even if the loudness target
    # cannot coexist with the source crest factor.
    return candidate * np.float32(ceiling / max(true_peak(candidate), EPSILON))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def sha256_files(paths: list[Path], *, base: Path) -> str:
    """Hash a source bundle using repository-relative labels and contents."""
    digest = hashlib.sha256()
    resolved_base = base.resolve()
    labelled: list[tuple[str, Path]] = []
    for path in paths:
        resolved = path.resolve()
        try:
            label = resolved.relative_to(resolved_base).as_posix()
        except ValueError as error:
            raise ValueError(f"source path is outside bundle base: {resolved}") from error
        labelled.append((label, resolved))
    for label, path in sorted(labelled, key=lambda item: item[0]):
        digest.update(label.encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def _ogg_crc_table() -> tuple[int, ...]:
    polynomial = 0x04C11DB7
    table: list[int] = []
    for value in range(256):
        remainder = value << 24
        for _ in range(8):
            if remainder & 0x80000000:
                remainder = ((remainder << 1) ^ polynomial) & 0xFFFFFFFF
            else:
                remainder = (remainder << 1) & 0xFFFFFFFF
        table.append(remainder)
    return tuple(table)


OGG_CRC_TABLE = _ogg_crc_table()


def _ogg_crc(page: bytearray) -> int:
    checksum = 0
    for value in page:
        checksum = (
            ((checksum << 8) & 0xFFFFFFFF)
            ^ OGG_CRC_TABLE[((checksum >> 24) & 0xFF) ^ value]
        )
    return checksum


def canonicalize_ogg(path: Path, stable_label: str) -> None:
    """Replace libsndfile's random Ogg stream serial and repair page CRCs.

    Vorbis packets are deterministic for the same PCM/toolchain, but Ogg stream
    serials are intentionally random. Canonicalizing only this container field
    makes repeated local generation byte-identical without touching audio data.
    """
    payload = bytearray(path.read_bytes())
    serial = int.from_bytes(hashlib.sha256(stable_label.encode("utf-8")).digest()[:4], "little")
    position = 0
    page_count = 0
    while position < len(payload):
        if payload[position : position + 4] != b"OggS":
            raise ValueError(f"invalid Ogg capture pattern at byte {position}: {path}")
        if position + 27 > len(payload):
            raise ValueError(f"truncated Ogg page header: {path}")
        segment_count = payload[position + 26]
        header_end = position + 27 + segment_count
        if header_end > len(payload):
            raise ValueError(f"truncated Ogg segment table: {path}")
        body_length = sum(payload[position + 27 : header_end])
        page_end = header_end + body_length
        if page_end > len(payload):
            raise ValueError(f"truncated Ogg page body: {path}")
        payload[position + 14 : position + 18] = serial.to_bytes(4, "little")
        payload[position + 22 : position + 26] = b"\0\0\0\0"
        page = bytearray(payload[position:page_end])
        checksum = _ogg_crc(page)
        payload[position + 22 : position + 26] = checksum.to_bytes(4, "little")
        position = page_end
        page_count += 1
    if page_count == 0:
        raise ValueError(f"empty Ogg stream: {path}")
    path.write_bytes(payload)


def write_master_and_runtime(
    root: Path,
    asset: dict[str, Any],
    audio: np.ndarray,
    sample_rate: int,
    compression_level: float,
) -> None:
    data = np.asarray(audio, dtype=np.float32)
    if asset["channels"] == 1:
        data = mono(data)
    else:
        data = as_2d(data)
        if data.shape[1] == 1:
            data = np.repeat(data, 2, axis=1)
    master = root / asset["master"]
    runtime = root / asset["runtime"]
    master.parent.mkdir(parents=True, exist_ok=True)
    runtime.parent.mkdir(parents=True, exist_ok=True)
    sf.write(master, data, sample_rate, format="WAV", subtype="PCM_24")
    if runtime.suffix.lower() == ".wav":
        # Short SFX use PCM16 at runtime. Quantizing the encoded PCM24 master
        # (rather than the pre-master float buffer) makes the conversion chain
        # explicit and independently reconstructable by the reviewer.
        encoded_master, _ = sf.read(master, dtype="float32", always_2d=True)
        runtime_pcm16 = tpdf_dither_pcm16(encoded_master, asset["id"])
        sf.write(runtime, runtime_pcm16, sample_rate, format="WAV", subtype="PCM_16")
    elif runtime.suffix.lower() == ".ogg":
        # Stream long loops into libsndfile instead of passing a
        # multi-million-frame array through one CFFI call.
        with sf.SoundFile(
            runtime,
            mode="w",
            samplerate=sample_rate,
            channels=1 if data.ndim == 1 else data.shape[1],
            format="OGG",
            subtype="VORBIS",
            compression_level=compression_level,
        ) as handle:
            for start in range(0, data.shape[0], 65_536):
                handle.write(data[start : start + 65_536])
        canonicalize_ogg(runtime, asset["id"])
    else:
        raise ValueError(f"unsupported runtime extension for {asset['id']}: {runtime}")
    runtime_info = sf.info(runtime)
    if runtime_info.frames != data.shape[0]:
        raise RuntimeError(
            f"runtime export frame mismatch for {asset['id']}: "
            f"{runtime_info.frames} != {data.shape[0]}"
        )


def measure_audio(audio: np.ndarray, sample_rate: int, *, include_true_peak: bool) -> dict[str, Any]:
    data = as_2d(audio)
    sample_peak = float(np.max(np.abs(data), initial=0.0))
    rms = float(np.sqrt(np.mean(np.square(data), dtype=np.float64)))
    mean_by_channel = [float(value) for value in np.mean(data, axis=0)]
    result: dict[str, Any] = {
        "frames": int(data.shape[0]),
        "channels": int(data.shape[1]),
        "durationSeconds": round(data.shape[0] / sample_rate, 9),
        "samplePeakDbfs": round(amp_to_db(sample_peak), 4),
        "rmsDbfs": round(amp_to_db(rms), 4),
        "dcOffset": [round(value, 10) for value in mean_by_channel],
        "integratedLufs": None,
        "truePeakDbtp": None,
    }
    loudness = integrated_lufs(data, sample_rate)
    if loudness is not None:
        result["integratedLufs"] = round(loudness, 4)
    if include_true_peak:
        result["truePeakDbtp"] = round(amp_to_db(true_peak(data)), 4)
    return result


def measure_file(path: Path, *, include_true_peak: bool = True) -> tuple[dict[str, Any], sf.SoundFile]:
    info = sf.info(path)
    audio, sample_rate = sf.read(path, dtype="float32", always_2d=True)
    metrics = measure_audio(audio, sample_rate, include_true_peak=include_true_peak)
    metrics.update(
        {
            "sampleRate": int(sample_rate),
            "format": info.format,
            "subtype": info.subtype,
            "sha256": sha256_file(path),
            "bytes": path.stat().st_size,
        }
    )
    return metrics, info


def dump_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
