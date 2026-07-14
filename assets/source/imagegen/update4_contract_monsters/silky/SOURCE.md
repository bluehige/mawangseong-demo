# 거미 재봉사 실키 생성 기록

- Generation model: GPT internal image generation
- Generated date: 2026-07-14
- Target version: v0.4
- Source image path: `assets/source/imagegen/update4_contract_monsters/silky/silky_combat_sheet_chroma_2026-07-14.png`
- Source image path: `assets/source/imagegen/update4_contract_monsters/silky/silky_portraits_chroma_2026-07-14.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_spider_tailor_sheet.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_spider_tailor_base.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_spider_tailor_happy.png`
- Runtime image path: `assets/sprites/portraits/update4/portrait_spider_tailor_determined.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_silky_thread_00.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_silky_thread_01.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_silky_thread_02.png`
- Runtime image path: `assets/sprites/effects/update4/contract_monsters/fx_silky_thread_03.png`

## Prompt

연보라색의 작고 친근한 비인간 거미 재봉사다. 둥근 얼굴, 큰 보라 눈 둘과 작은 보조 눈, 짧은 6~8개 다리, 은빛 앞머리, 자주색 재봉 모자, 골무 목걸이, 보라·은색 실꾸러미와 굽은 바늘을 일관되게 유지한다. 현대 재봉틀과 공포 표현을 금지하고 계단 실 설치·아군 구조 행동이 보이는 전투 자세와 기본·기쁨·결의 초상을 생성했다.

## Reference and post-processing

- Reference image: 없음. Update 4 계획서의 작은 거미·재봉 도구·보라/은색 실 키워드로 신규 디자인했다.
- Post-processing: `tools/prepare_update4_contract_monster_assets.py`가 크로마 제거, 192×192 셀 16개의 4×4 런타임 시트, 512×512 초상 3개, 4프레임 VFX를 생성했다.
