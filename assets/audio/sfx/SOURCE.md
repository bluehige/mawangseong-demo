# Core combat procedural audio source record

- Created: 2026-07-11
- Target version: v1.2.2 (legacy runtime assets retained)
- Source: original deterministic PCM synthesis in `tools/generate_combat_sfx.py`
- Introduction commit: `1db50c0cf54c32a45959a539f8fad3a762e2cbfb`
- Runtime assets: `combat_slash.wav`, `combat_shield_bash.wav`, `combat_fire_burst.wav`, `combat_down.wav`
- Format: mono PCM WAV, 44.1 kHz, 16-bit
- External sample input: none

The generator builds the cues from mathematical oscillators, deterministic pseudo-random noise, and attack/release envelopes. It does not read, copy, or transform any third-party recording. `combat_hit.wav` is not covered by this shared record because its authoritative provenance is the separate Lyria source record in the audio catalog.
