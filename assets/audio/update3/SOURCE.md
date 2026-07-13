# Update 3 audio source record

- Created: 2026-07-13
- Source: original deterministic procedural synthesis in `tools/generate_update3_audio.py`
- Format: mono PCM WAV, 44.1 kHz, 16-bit
- Count: 31 cues
- Groups: 3 heart loops, heart ready/active/disabled, 6 duo activations, 6 new-enemy warnings, 2 final-boss motifs, 9 monster signatures
- Runtime overlap policy: one instance of the same cue, maximum four Update 3 one-shot cues at once, and only one heart loop player.
- Mix policy: heart loop -22 dB; boss motifs -12 dB; enemy warnings -10 dB; activation cues -6 to -7.5 dB.

The generator uses layered sine tones, small deterministic noise amounts, attack/release envelopes, pitch drift, and pulsing amplitude. Re-running the script recreates the same cues without external samples.
