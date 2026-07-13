"""Generate deterministic, original Update 3 game audio cues as PCM WAV files."""

from __future__ import annotations

import math
import random
import wave
from pathlib import Path


RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "update3"


def write_cue(name: str, frequencies: tuple[float, ...], duration: float, *, noise: float = 0.0,
              pulse: float = 0.0, volume: float = 0.42) -> None:
    rng = random.Random(name)
    count = int(RATE * duration)
    samples = bytearray()
    for i in range(count):
        t = i / RATE
        attack = min(1.0, t / 0.025)
        release = min(1.0, max(0.0, duration - t) / 0.11)
        envelope = attack * release
        if pulse > 0.0:
            envelope *= 0.58 + 0.42 * max(0.0, math.sin(math.tau * pulse * t))
        tone = 0.0
        for index, frequency in enumerate(frequencies):
            glide = frequency * (1.0 + 0.045 * math.sin(math.tau * (0.7 + index * 0.13) * t))
            tone += math.sin(math.tau * glide * t + index * 0.61) / (index + 1)
        tone /= max(1.0, sum(1.0 / (index + 1) for index in range(len(frequencies))))
        tone += (rng.uniform(-1.0, 1.0) * noise) * (0.4 + 0.6 * release)
        value = int(max(-1.0, min(1.0, tone * envelope * volume)) * 32767)
        samples.extend(value.to_bytes(2, "little", signed=True))
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(samples)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cues = {
        "heart_stonebone_loop": ((73.4, 146.8, 293.7), 2.4, 0.015, 1.35),
        "heart_hungry_loop": ((55.0, 82.4, 110.0), 2.4, 0.035, 1.8),
        "heart_dream_loop": ((98.0, 196.0, 392.0), 2.4, 0.008, 0.72),
        "heart_ready": ((220.0, 330.0, 660.0), 0.55, 0.01, 4.0),
        "heart_stonebone_active": ((82.4, 164.8, 329.6), 1.05, 0.08, 2.0),
        "heart_hungry_active": ((49.0, 73.4, 146.8), 1.05, 0.16, 3.0),
        "heart_dream_active": ((130.8, 261.6, 523.3), 1.05, 0.025, 1.2),
        "heart_disabled": ((116.5, 87.3, 58.3), 0.85, 0.12, 2.2),
        "duo_spore": ((196.0, 293.7, 392.0), 0.8, 0.03, 2.4),
        "duo_ghost": ((174.6, 349.2, 698.5), 0.8, 0.015, 1.5),
        "duo_moon": ((220.0, 440.0, 659.3), 0.8, 0.04, 2.8),
        "duo_molten": ((82.4, 123.5, 246.9), 0.8, 0.14, 3.2),
        "duo_stone": ((65.4, 130.8, 196.0), 0.8, 0.11, 2.0),
        "duo_beacon": ((146.8, 293.7, 587.3), 0.8, 0.025, 3.5),
        "enemy_seal_chainbearer": ((92.5, 185.0), 0.62, 0.13, 2.4),
        "enemy_reliquary_guard": ((130.8, 261.6), 0.62, 0.06, 1.8),
        "enemy_choir_exorcist": ((196.0, 293.7, 392.0), 0.72, 0.015, 5.0),
        "enemy_bounty_tracker": ((110.0, 164.8), 0.58, 0.10, 4.0),
        "enemy_combat_alchemist": ((146.8, 220.0), 0.62, 0.16, 3.0),
        "enemy_ledger_binder": ((77.8, 155.6, 233.1), 0.72, 0.07, 2.0),
        "boss_selen_motif": ((123.5, 246.9, 370.0), 2.2, 0.025, 1.1),
        "boss_roman_motif": ((98.0, 146.8, 293.7), 2.2, 0.045, 1.45),
    }
    monster_bases = [73.4, 82.4, 92.5, 103.8, 116.5, 130.8, 146.8, 164.8, 185.0]
    for index, base in enumerate(monster_bases, 1):
        cues[f"monster_signature_{index:02d}"] = ((base, base * 1.5, base * 2.0), 0.52, 0.04 + index * 0.007, 2.0 + (index % 3))
    for name, (freqs, duration, noise, pulse) in cues.items():
        write_cue(name, freqs, duration, noise=noise, pulse=pulse)
    print(f"generated={len(cues)} directory={OUT}")


if __name__ == "__main__":
    main()
