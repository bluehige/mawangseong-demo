# 왕관 대전령 포포 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_crowns/popo/crown_popo_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_crowns/popo/crown_popo_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/crowns/monster_popo_crown_courier_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_popo_crown_courier_council.png`
- Runtime image path: `assets/sprites/portraits/update4/crowns/portrait_popo_crown_courier_victory.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_popo_crown_courier_crown_00.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_popo_crown_courier_crown_01.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_popo_crown_courier_crown_02.png`
- Runtime image path: `assets/sprites/effects/update4/crowns/fx_popo_crown_courier_crown_03.png`

## Prompt

계획서의 남색·보라·금색 작은 박쥐 전령을 신규 디자인했다. 큰 둥근 귀, 전령 모자, 자주 접힌 편지와 우편 가방을 핵심 정체성으로 삼고 모자에 통합된 작은 왕관, 달빛 중계 부적, 왕실 인장을 더해 16개 전투 동작과 두 초상을 생성한다.

## Reference and post-processing

- Reference image: 없음. Phase 30의 일반 포포 최종 그래픽과 공유할 기준 정체성으로 먼저 확정했다.
- Post-processing: `tools/prepare_update4_crown_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상, 4프레임 VFX를 생성했다.
