# 루미(moon_tracker) 기본 전투 자산 출처

- Generation model: GPT internal image generation
- Generated date: 2026-08-04
- Target version: v1.2.2
- Source image path: `assets/source/imagegen/update4_contract_monsters/moon/moon_combat_sheet_chroma_2026-08-04.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_moon_sheet.png`

## 자산 목적

`moon_tracker` 전용 기본 전투 스프라이트다. 기존 `kobold_scout`·로로 초상 이미지를 재사용하지 않고, 은빛 초승달 표식과 활을 사용하는 작은 달박쥐 추적자로 새로 만들었다. 제품 데이터와 전투 profile 연결은 다음 CONNECT 패킷 범위다.

## 생성 및 후처리

- 1254×1254 RGB 원본에 4×4, 총 16프레임을 배치했다.
- 행 계약은 `idle_down 2 + down 2 / move_down 4 / attack_down 4 / skill_down 4`다.
- 원본은 평면 `#00ff00` 크로마키 배경으로 생성하고 `remove_chroma_key.py`의 border 자동 키·soft matte·edge contract 1·despill로 투명화했다.
- 8방향 연결 성분을 명목 셀의 다수 프레임에 배정해 셀 경계를 가로지른 화살·문양이 이웃 프레임과 섞이지 않도록 했다.
- 각 프레임의 캐릭터 영역을 공통 크기로 축소해 192×192 셀 중앙에 배치하고, 모든 프레임의 발 기준선을 `y=183`으로 맞췄다.
- 은빛 달 표식과 보랏빛 추적 문양은 캐릭터 가까이에만 남겨 셀 가장자리를 침범하지 않도록 했다.
- premultiplied RGBA 축소 뒤 초록색 잔류 픽셀 126개(저알파 포함)를 제거했다.

## 연결 범위

이번 패킷에서는 `data/monsters.json`, `data/update2_contracts.json`, `data/v122/combat_visual_profiles.json`, 씬과 공통 렌더러를 수정하지 않는다. 런타임 연결은 별도 `V2-P4E-CONNECT-MOON` 패킷에서 수행한다.
