# Update 4 contract-monster procedural audio source record

- Created: 2026-07-14
- Target version: v1.2.2 (legacy runtime assets retained)
- Source: original deterministic PCM synthesis in `tools/prepare_update4_contract_monster_assets.py`, using `write_sfx` from `tools/prepare_update4_crown_assets.py`
- Introduction commit: `19a41538b1d29b7e5da2019b4b0fe0ff6813bcb9`
- Runtime assets: `sfx_silky_stitch.wav`, `sfx_silky_rescue.wav`, `sfx_popo_relay.wav`, `sfx_popo_alarm.wav`
- Format: mono PCM WAV, 22.05 kHz, 16-bit
- External sample input: none

The repository scripts synthesize each cue from configured sine-wave frequencies and envelopes without reading an external audio file. The v1.2.2 release audit found that two semantically different cues share frequencies with crown cues; their planned Lyria replacements remain tracked separately in `tools/audio/lyria_v122_manifest.json`.
