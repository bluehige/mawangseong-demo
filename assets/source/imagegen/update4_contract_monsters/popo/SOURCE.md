# 박쥐 전령 포포 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_contract_monsters/popo/popo_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_contract_monsters/popo/popo_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_bat_courier_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_bat_courier_base.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_bat_courier_happy.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_bat_courier_determined.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_popo_relay_00.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_popo_relay_01.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_popo_relay_02.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_popo_relay_03.png`

## Prompt

왕관 대전령 포포 원본에서 왕관·왕실 인장 장식을 제거한 일반 형태다. 남색 털, 큰 둥근 귀, 보라 눈, 달 핀 전령 모자, 짧은 보라 망토, 초승달 중계 부적, 자주 접힌 편지와 우편 가방을 유지한다. 군복·인간형·흡혈귀 고어 없이 밤길 중계·메아리 경보 행동과 기본·기쁨·결의 초상을 생성했다.

## Reference and post-processing

- Reference image: `assets/source/imagegen/update4_crowns/popo/crown_popo_combat_sheet_chroma_2026-07-14.png`
- Post-processing: `tools/prepare_update4_contract_monster_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상 3개, 4프레임 VFX를 생성했다.
