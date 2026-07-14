# Mirella rival boss source

Generation model: GPT internal image generation
Generated date: 2026-07-14
Target version: v0.4
Source image path: res://assets/source/imagegen/update4_rivals/mirella/mirella_combat_sheet_chroma_2026-07-14.png
Source image path: res://assets/source/imagegen/update4_rivals/mirella/mirella_portraits_chroma_2026-07-14.png
Runtime image path: res://assets/sprites/enemies/update4/rivals/enemy_rival_mirella_council_champion_sheet.png
Runtime image path: res://assets/sprites/portraits/update4/rivals/portrait_mirella_council.png
Runtime image path: res://assets/sprites/portraits/update4/rivals/portrait_mirella_respect.png
Runtime image path: res://assets/sprites/portraits/update4/rivals/portrait_mirella_challenge.png
Runtime image path: res://assets/sprites/portraits/update4/rivals/portrait_mirella_victory.png
Runtime image path: res://assets/sprites/effects/update4/rivals/fx_mirella_boss_00.png
Runtime image path: res://assets/sprites/effects/update4/rivals/fx_mirella_boss_01.png
Runtime image path: res://assets/sprites/effects/update4/rivals/fx_mirella_boss_02.png
Runtime image path: res://assets/sprites/effects/update4/rivals/fx_mirella_boss_03.png

Prompt: A single calm mist-garden demon with pale mint-gray skin, lavender eyes, branch-like horns, mushroom parasol, gardener robes, grave-marker flowerpot and mist lantern, produced separately as a 4x4 combat action sheet and a 2x2 expression sheet on chroma green. Body horror and generic witch imagery were excluded.

Post-processing: `tools/prepare_update4_rival_assets.py` removes chroma, normalizes sixteen 192px combat frames, crops four 512px portraits, extracts four boss VFX frames, and synthesizes `res://assets/audio/music/update4/rivals/boss_mirella_motif.wav`.
