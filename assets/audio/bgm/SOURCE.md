# Combat Music Runtime Source

- Runtime asset: `assets/audio/bgm/combat_dungeon_pressure.wav`
- Authoritative source record: `assets/source/audio/lyria/v0.5/combat_dungeon_pressure/SOURCE.md`
- The runtime file is the explicitly promoted Lyria 3 candidate recorded in the v0.5 source record. The old procedural 30-second description is deprecated and must not be used as provenance.
- The v0.5 render contract declares 120 seconds, while the checked runtime WAV is 116.909 seconds at stereo 44.1 kHz. This duration mismatch remains an A1 loop-verification item; it is not silently relabeled as a procedural 30-second asset.
- The v1.2.2 manifest is `tools/audio/lyria_v122_manifest.json`; future re-generation or re-promotion must use its `plan-only-until-owner-approval` policy and `assets/source/audio/lyria/v1.2.2/` source root.
- The Godot WAV import settings enable forward looping before runtime. Loop seam and final duration still require the A1 transport check and owner listening.
