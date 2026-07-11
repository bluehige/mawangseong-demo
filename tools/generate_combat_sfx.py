import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "audio" / "sfx"
SAMPLE_RATE = 44_100
RNG = random.Random(20260710)


def envelope(index: int, length: int, attack_seconds: float, decay_power: float = 1.5) -> float:
    attack_samples = max(1, int(attack_seconds * SAMPLE_RATE))
    attack = min(1.0, index / attack_samples)
    release = max(0.0, 1.0 - index / max(1, length - 1)) ** decay_power
    return attack * release


def save_wav(name: str, samples: list[float]) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    fade_samples = min(len(samples), int(0.012 * SAMPLE_RATE))
    for index in range(fade_samples):
        samples[-1 - index] *= index / max(1, fade_samples - 1)
    peak = max(0.001, max(abs(value) for value in samples))
    gain = 0.90 / peak
    pcm = bytearray()
    for value in samples:
        clamped = max(-1.0, min(1.0, value * gain))
        pcm.extend(struct.pack("<h", int(clamped * 32767)))
    output_path = OUTPUT_DIR / name
    with wave.open(str(output_path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(pcm)
    print(f"{output_path.relative_to(ROOT)}: {len(samples) / SAMPLE_RATE:.3f}s")


def slash() -> list[float]:
    length = int(0.18 * SAMPLE_RATE)
    samples: list[float] = []
    low_pass = 0.0
    phase = 0.0
    for index in range(length):
        progress = index / length
        noise = RNG.uniform(-1.0, 1.0)
        low_pass += (noise - low_pass) * (0.05 + progress * 0.20)
        high_pass = noise - low_pass
        frequency = 2100.0 * (1.0 - progress) + 420.0 * progress
        phase += math.tau * frequency / SAMPLE_RATE
        body = math.sin(phase) * 0.18
        samples.append((high_pass * 0.82 + body) * envelope(index, length, 0.008, 1.65))
    return samples


def shield_bash() -> list[float]:
    length = int(0.23 * SAMPLE_RATE)
    samples: list[float] = []
    phase = 0.0
    resonance_phase = 0.0
    for index in range(length):
        progress = index / length
        frequency = 135.0 * (1.0 - progress) + 46.0 * progress
        phase += math.tau * frequency / SAMPLE_RATE
        resonance_phase += math.tau * 330.0 / SAMPLE_RATE
        transient = RNG.uniform(-1.0, 1.0) * math.exp(-progress * 34.0)
        thump = math.sin(phase) * (1.0 - progress) ** 1.8
        wood = math.sin(resonance_phase) * math.exp(-progress * 17.0)
        samples.append(thump * 0.78 + transient * 0.52 + wood * 0.20)
    return samples


def fire_burst() -> list[float]:
    length = int(0.34 * SAMPLE_RATE)
    samples: list[float] = []
    low_pass = 0.0
    phase = 0.0
    for index in range(length):
        progress = index / length
        noise = RNG.uniform(-1.0, 1.0)
        low_pass += (noise - low_pass) * (0.025 + progress * 0.08)
        frequency = 520.0 * (1.0 - progress) + 115.0 * progress
        phase += math.tau * frequency / SAMPLE_RATE
        ignition = math.sin(phase) * 0.24
        crackle = RNG.uniform(-0.8, 0.8) if RNG.random() < 0.035 * (1.0 - progress) else 0.0
        samples.append((low_pass * 2.4 + ignition + crackle) * envelope(index, length, 0.018, 1.25))
    return samples


def hit() -> list[float]:
    length = int(0.14 * SAMPLE_RATE)
    samples: list[float] = []
    phase = 0.0
    for index in range(length):
        progress = index / length
        frequency = 175.0 * (1.0 - progress) + 72.0 * progress
        phase += math.tau * frequency / SAMPLE_RATE
        click = RNG.uniform(-1.0, 1.0) * math.exp(-progress * 40.0)
        body = math.sin(phase) * (1.0 - progress) ** 2.0
        samples.append(body * 0.72 + click * 0.58)
    return samples


def down() -> list[float]:
    length = int(0.36 * SAMPLE_RATE)
    samples: list[float] = []
    low_phase = 0.0
    mid_phase = 0.0
    for index in range(length):
        progress = index / length
        low_frequency = 92.0 * (1.0 - progress) + 38.0 * progress
        low_phase += math.tau * low_frequency / SAMPLE_RATE
        mid_phase += math.tau * 185.0 / SAMPLE_RATE
        drop = math.sin(low_phase) * (1.0 - progress) ** 1.45
        knock = math.sin(mid_phase) * math.exp(-progress * 18.0)
        dust = RNG.uniform(-1.0, 1.0) * math.exp(-progress * 28.0)
        samples.append(drop * 0.82 + knock * 0.24 + dust * 0.30)
    return samples


def main() -> None:
    save_wav("combat_slash.wav", slash())
    save_wav("combat_shield_bash.wav", shield_bash())
    save_wav("combat_fire_burst.wav", fire_burst())
    save_wav("combat_hit.wav", hit())
    save_wav("combat_down.wav", down())


if __name__ == "__main__":
    main()
