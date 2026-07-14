# 왕성화염 현자 핀 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/pynn/crown_pynn_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/pynn/crown_pynn_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_imp_crown_flame_sage_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_imp_crown_flame_sage_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_imp_crown_flame_sage_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_imp_crown_flame_sage_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_imp_crown_flame_sage_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_imp_crown_flame_sage_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_imp_crown_flame_sage_crown_03.png`

## Prompt

기존 화염 숙련자 핀의 분홍빛 임프, 연보라 머리, 검은 뿔, 박쥐 날개와 보라 화염 지팡이를 유지한다. 뿔 사이 흑금 관, 화염 재상 띠, 여섯 불씨와 왕실 인장을 더하고 16개 전투 동작과 의회·승리 초상을 생성한다.

## Reference and post-processing

- Reference image: `assets/sprites/monsters/monster_imp_flame_adept_idle_down_00.png`
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다. 생성 시트의 부족한 이동 중간 자세 2개는 같은 원본의 좌우 반전 변형으로 보완했다.
