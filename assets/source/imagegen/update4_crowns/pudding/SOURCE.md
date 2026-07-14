# 왕관성벽 푸딩 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/pudding/crown_pudding_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/pudding/crown_pudding_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_slime_crown_bastion_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_slime_crown_bastion_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_slime_crown_bastion_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_slime_crown_bastion_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_slime_crown_bastion_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_slime_crown_bastion_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_slime_crown_bastion_crown_03.png`

## Prompt

기존 성문 방벽 푸딩의 보라색 디저트 슬라임, 체리·크림, 청록 수정 성벽 갑주 정체성을 유지한다. 작은 금빛 왕관, 왕실 인장, 강화된 성채 판금을 더하고 idle 2, move 4, attack 4, skill 4, down 2 동작과 의회·승리 초상을 단색 녹색 배경에 생성한다.

## Reference and post-processing

- Reference image: `assets/sprites/monsters/monster_slime_gate_bulwark_idle_down_00.png`
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다.
