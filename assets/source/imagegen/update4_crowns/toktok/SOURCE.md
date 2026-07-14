# 왕관 갑주공 톡톡 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/toktok/crown_toktok_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/toktok/crown_toktok_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_toktok_crown_armorer_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_toktok_crown_armorer_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_toktok_crown_armorer_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_toktok_crown_armorer_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_toktok_crown_armorer_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_toktok_crown_armorer_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_toktok_crown_armorer_crown_03.png`

## Prompt

기존 갑주 딱정벌레의 낮은 6족 실루엣, 겹친 청동 판금과 보라 보석 리벳을 유지한다. 등딱지에 통합된 왕관 마루, 왕실 보라 결정, 금빛 지휘 무늬와 강화 머리판을 더하고 비인간 형태의 16개 전투 동작과 두 초상을 생성한다.

## Reference and post-processing

- Reference image: `assets/sprites/monsters/monster_armored_beetle_idle_down_00.png`
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다.
