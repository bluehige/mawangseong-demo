# Update 4 crown procedural audio source record

- Created: 2026-07-14
- Target version: v1.2.2 (legacy runtime assets retained)
- Source: original deterministic PCM synthesis in `tools/prepare_update4_crown_assets.py`
- Introduction commit: `eba39efd3d88eecb1da6be97beb094df82a1b370`
- Runtime assets: `sfx_crown_gob_ascend.wav`, `sfx_crown_mori_ascend.wav`, `sfx_crown_popo_ascend.wav`, `sfx_crown_pudding_ascend.wav`, `sfx_crown_pynn_ascend.wav`, `sfx_crown_toktok_ascend.wav`
- Format: mono PCM WAV, 22.05 kHz, 16-bit
- External sample input: none

The repository script synthesizes each cue from configured sine-wave frequencies and envelopes without reading an external audio file. The v1.2.2 release audit found that the Mori and Popo crown cues duplicate two contract-monster cues; their planned Lyria replacements remain tracked separately in `tools/audio/lyria_v122_manifest.json`.
