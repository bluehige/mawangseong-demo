# 대균사제 모리 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/mori/crown_mori_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/mori/crown_mori_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_mori_crown_priest_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_mori_crown_priest_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_mori_crown_priest_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_mori_crown_priest_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_mori_crown_priest_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_mori_crown_priest_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_mori_crown_priest_crown_03.png`

## Prompt

기존 런타임이 임시 슬라임 그림을 쓰던 모리를 자그마한 비인간 버섯 치유사로 확정했다. 버건디 버섯갓, 크림색 몸, 이끼 망토, 포자 등불 지팡이와 갓 테두리 왕관을 사용해 16개 전투 동작과 의회·승리 초상을 생성한다.

## Reference and post-processing

- Reference image: 없음. 계획서의 모리 회복·정화 역할과 버섯 우산 키워드로 신규 디자인했다.
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다.
