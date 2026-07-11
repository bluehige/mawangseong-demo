import math
import struct
import wave
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "assets" / "audio" / "bgm" / "combat_dungeon_pressure.wav"
SAMPLE_RATE = 44_100
BPM = 128.0
BEAT_SECONDS = 60.0 / BPM
BAR_SECONDS = BEAT_SECONDS * 4.0
BAR_COUNT = 16
DURATION_SECONDS = BAR_SECONDS * BAR_COUNT
SAMPLE_COUNT = int(round(DURATION_SECONDS * SAMPLE_RATE))
RNG = np.random.default_rng(20260711)


def midi_frequency(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def pan_gains(pan: float) -> tuple[float, float]:
    angle = (max(-1.0, min(1.0, pan)) + 1.0) * math.pi * 0.25
    return math.cos(angle), math.sin(angle)


def note_wave(phase: np.ndarray, voice: str) -> np.ndarray:
    if voice == "bass":
        return np.sin(phase) + 0.34 * np.sin(phase * 2.0) + 0.12 * np.sin(phase * 3.0)
    if voice == "pad":
        return (
            np.sin(phase)
            + 0.30 * np.sin(phase * 2.0 + 0.15)
            + 0.16 * np.sin(phase * 3.0)
            + 0.08 * np.sin(phase * 5.0)
        )
    if voice == "horn":
        return np.sin(phase) + 0.42 * np.sin(phase * 2.0) + 0.18 * np.sin(phase * 3.0)
    return np.sin(phase) + 0.45 * np.sin(phase * 2.0) + 0.20 * np.sin(phase * 4.0)


def add_note(
    mix: np.ndarray,
    start_seconds: float,
    duration_seconds: float,
    midi_note: int,
    amplitude: float,
    voice: str,
    pan: float = 0.0,
    attack_seconds: float = 0.01,
    release_seconds: float = 0.08,
) -> None:
    start = max(0, int(round(start_seconds * SAMPLE_RATE)))
    end = min(SAMPLE_COUNT, start + int(round(duration_seconds * SAMPLE_RATE)))
    length = end - start
    if length <= 1:
        return
    time = np.arange(length, dtype=np.float64) / SAMPLE_RATE
    phase = math.tau * midi_frequency(midi_note) * time
    signal = note_wave(phase, voice)
    attack = np.minimum(1.0, time / max(0.001, attack_seconds))
    remaining = np.maximum(0.0, duration_seconds - time)
    release = np.minimum(1.0, remaining / max(0.001, release_seconds))
    envelope = np.sin(attack * math.pi * 0.5) * np.sin(release * math.pi * 0.5)
    if voice == "pluck":
        envelope *= np.exp(-time * 5.2)
    elif voice == "bass":
        envelope *= np.exp(-time * 1.2)
    left, right = pan_gains(pan)
    mix[0, start:end] += signal * envelope * amplitude * left
    mix[1, start:end] += signal * envelope * amplitude * right


def add_kick(mix: np.ndarray, start_seconds: float, amplitude: float = 0.34) -> None:
    duration = 0.24
    start = int(round(start_seconds * SAMPLE_RATE))
    end = min(SAMPLE_COUNT, start + int(duration * SAMPLE_RATE))
    length = end - start
    if length <= 1:
        return
    time = np.arange(length, dtype=np.float64) / SAMPLE_RATE
    frequency = 92.0 * np.exp(-time * 17.0) + 42.0
    phase = math.tau * np.cumsum(frequency) / SAMPLE_RATE
    signal = np.sin(phase) * np.exp(-time * 15.0)
    click = RNG.uniform(-1.0, 1.0, length) * np.exp(-time * 70.0)
    mix[:, start:end] += (signal * 0.86 + click * 0.16) * amplitude


def add_snare(mix: np.ndarray, start_seconds: float, amplitude: float = 0.18) -> None:
    duration = 0.20
    start = int(round(start_seconds * SAMPLE_RATE))
    end = min(SAMPLE_COUNT, start + int(duration * SAMPLE_RATE))
    length = end - start
    if length <= 1:
        return
    time = np.arange(length, dtype=np.float64) / SAMPLE_RATE
    noise = RNG.uniform(-1.0, 1.0, length)
    tone = np.sin(math.tau * 185.0 * time)
    signal = (noise * 0.72 + tone * 0.28) * np.exp(-time * 19.0) * amplitude
    mix[0, start:end] += signal * 0.86
    mix[1, start:end] += signal


def add_hat(mix: np.ndarray, start_seconds: float, pan: float, amplitude: float = 0.038) -> None:
    duration = 0.065
    start = int(round(start_seconds * SAMPLE_RATE))
    end = min(SAMPLE_COUNT, start + int(duration * SAMPLE_RATE))
    length = end - start
    if length <= 1:
        return
    time = np.arange(length, dtype=np.float64) / SAMPLE_RATE
    noise = RNG.uniform(-1.0, 1.0, length)
    smooth = np.convolve(noise, np.ones(9) / 9.0, mode="same")
    signal = (noise - smooth) * np.exp(-time * 52.0) * amplitude
    left, right = pan_gains(pan)
    mix[0, start:end] += signal * left
    mix[1, start:end] += signal * right


def add_tom(mix: np.ndarray, start_seconds: float, frequency: float, pan: float) -> None:
    duration = 0.28
    start = int(round(start_seconds * SAMPLE_RATE))
    end = min(SAMPLE_COUNT, start + int(duration * SAMPLE_RATE))
    length = end - start
    if length <= 1:
        return
    time = np.arange(length, dtype=np.float64) / SAMPLE_RATE
    phase = math.tau * np.cumsum(frequency * np.exp(-time * 4.5) + 28.0) / SAMPLE_RATE
    signal = np.sin(phase) * np.exp(-time * 11.0) * 0.22
    left, right = pan_gains(pan)
    mix[0, start:end] += signal * left
    mix[1, start:end] += signal * right


def build_music() -> np.ndarray:
    mix = np.zeros((2, SAMPLE_COUNT), dtype=np.float64)
    progression = [
        (50, 53, 57),
        (46, 50, 53),
        (48, 52, 55),
        (45, 49, 52),
        (43, 46, 50),
        (46, 50, 53),
        (48, 52, 55),
        (45, 49, 52),
        (50, 53, 57),
        (48, 52, 55),
        (46, 50, 53),
        (45, 49, 52),
        (43, 46, 50),
        (46, 50, 53),
        (45, 49, 52),
        (50, 53, 57),
    ]
    ostinato_pattern = (0, 2, 1, 2, 0, 2, 1, 2)
    bass_pattern = (0, 0, 2, 0)

    for bar_index, chord in enumerate(progression):
        bar_start = bar_index * BAR_SECONDS
        for note_index, note in enumerate(chord):
            add_note(
                mix,
                bar_start,
                BAR_SECONDS * 0.98,
                note,
                0.034,
                "pad",
                pan=(-0.34 + note_index * 0.34),
                attack_seconds=0.12,
                release_seconds=0.18,
            )
        for beat_index, pattern_index in enumerate(bass_pattern):
            add_note(
                mix,
                bar_start + beat_index * BEAT_SECONDS,
                BEAT_SECONDS * 0.72,
                chord[pattern_index] - 12,
                0.105,
                "bass",
                pan=-0.05,
                attack_seconds=0.008,
                release_seconds=0.10,
            )
        for step, chord_index in enumerate(ostinato_pattern):
            add_note(
                mix,
                bar_start + step * BEAT_SECONDS * 0.5,
                BEAT_SECONDS * 0.42,
                chord[chord_index] + 12,
                0.047 if bar_index >= 4 else 0.034,
                "pluck",
                pan=-0.42 if step % 2 == 0 else 0.42,
                attack_seconds=0.004,
                release_seconds=0.06,
            )

        add_kick(mix, bar_start)
        add_kick(mix, bar_start + BEAT_SECONDS * 2.0, 0.30)
        if bar_index >= 8:
            add_kick(mix, bar_start + BEAT_SECONDS * 2.75, 0.22)
        add_snare(mix, bar_start + BEAT_SECONDS)
        add_snare(mix, bar_start + BEAT_SECONDS * 3.0, 0.21)
        for step in range(8):
            add_hat(mix, bar_start + step * BEAT_SECONDS * 0.5, -0.30 if step % 2 == 0 else 0.30)

        if bar_index % 4 == 3:
            add_tom(mix, bar_start + BEAT_SECONDS * 3.25, 105.0, -0.32)
            add_tom(mix, bar_start + BEAT_SECONDS * 3.55, 82.0, 0.0)
            add_tom(mix, bar_start + BEAT_SECONDS * 3.82, 64.0, 0.32)

    melody = {
        4: ((0.0, 62, 1.5), (2.0, 65, 1.0), (3.0, 67, 0.8)),
        5: ((0.0, 65, 1.0), (1.5, 62, 0.8), (2.5, 60, 1.2)),
        6: ((0.0, 64, 1.0), (1.0, 67, 1.0), (2.0, 69, 1.7)),
        7: ((0.0, 64, 0.8), (1.0, 61, 0.8), (2.0, 57, 1.7)),
        12: ((0.0, 67, 1.0), (1.0, 65, 1.0), (2.0, 62, 1.7)),
        13: ((0.0, 65, 1.0), (1.5, 69, 0.8), (2.5, 67, 1.2)),
        14: ((0.0, 69, 0.8), (1.0, 67, 0.8), (2.0, 64, 1.7)),
        15: ((0.0, 62, 1.0), (1.0, 65, 0.8), (2.0, 62, 1.65)),
    }
    for bar_index, notes in melody.items():
        for beat_offset, midi_note, beat_length in notes:
            add_note(
                mix,
                bar_index * BAR_SECONDS + beat_offset * BEAT_SECONDS,
                beat_length * BEAT_SECONDS,
                midi_note,
                0.072,
                "horn",
                pan=0.08,
                attack_seconds=0.055,
                release_seconds=0.14,
            )

    dry = mix.copy()
    mix += np.roll(dry, int(BEAT_SECONDS * 0.75 * SAMPLE_RATE), axis=1) * 0.095
    mix += np.roll(dry, int(BEAT_SECONDS * 1.50 * SAMPLE_RATE), axis=1) * 0.052
    mix -= np.mean(mix, axis=1, keepdims=True)
    mix = np.tanh(mix * 1.32)
    seam_samples = int(0.008 * SAMPLE_RATE)
    seam_fade = np.sin(np.linspace(0.0, math.pi * 0.5, seam_samples))
    mix[:, :seam_samples] *= seam_fade
    mix[:, -seam_samples:] *= seam_fade[::-1]
    peak = max(0.001, float(np.max(np.abs(mix))))
    return mix * (0.90 / peak)


def save_wav(mix: np.ndarray) -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    interleaved = np.column_stack((mix[0], mix[1])).reshape(-1)
    pcm = bytearray()
    for value in interleaved:
        pcm.extend(struct.pack("<h", int(max(-1.0, min(1.0, float(value))) * 32767)))
    with wave.open(str(OUTPUT_PATH), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)


def main() -> None:
    mix = build_music()
    save_wav(mix)
    rms = float(np.sqrt(np.mean(np.square(mix))))
    seam_delta = float(np.max(np.abs(mix[:, 0] - mix[:, -1])))
    print(f"{OUTPUT_PATH.relative_to(ROOT)}: {DURATION_SECONDS:.3f}s stereo {SAMPLE_RATE}Hz")
    print(f"peak={np.max(np.abs(mix)):.4f} rms_db={20.0 * math.log10(max(rms, 1e-9)):.2f} seam_delta={seam_delta:.6f}")


if __name__ == "__main__":
    main()
