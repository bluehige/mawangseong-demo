# 한밤 총대장 곱 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/gob/crown_gob_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/gob/crown_gob_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_goblin_crown_marshal_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_goblin_crown_marshal_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_goblin_crown_marshal_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_goblin_crown_marshal_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_goblin_crown_marshal_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_goblin_crown_marshal_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_goblin_crown_marshal_crown_03.png`

## Prompt

기존 매복대장 곱의 녹색 고블린, 검은 후드, 붉은 목도리, 창 전투 실루엣을 유지한다. 낮은 금빛 왕관, 왕실 열쇠 고리, 밀랍 인장 가방과 금장 갑옷을 더하고 16개 전투 동작과 의회·승리 초상을 생성한다.

## Reference and post-processing

- Reference image: `assets/sprites/monsters/monster_goblin_ambush_captain_idle_down_00.png`
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다.
