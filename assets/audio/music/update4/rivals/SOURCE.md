# Update 4 rival motif procedural audio source record

- Created: 2026-07-14
- Target version: v1.2.2 (legacy runtime assets retained)
- Source: original deterministic PCM synthesis in `tools/prepare_update4_rival_assets.py`
- Introduction commit: `5afbb83bea134f9bb05c126c2bccd51de64fd107`
- Runtime assets: `boss_brassa_motif.wav`, `boss_vesper_motif.wav`, `boss_mirella_motif.wav`
- Format: mono PCM WAV, 22.05 kHz, 16-bit
- External sample input: none

The repository script creates each compact motif directly from configured tones and envelopes. It has no audio-file input and therefore uses no external sample or recording.
