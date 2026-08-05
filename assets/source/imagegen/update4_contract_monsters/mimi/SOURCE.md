# 미미(mimic_porter) 기본 전투 자산 출처

- Generation model: GPT internal image generation
- Generated date: 2026-08-04
- Target version: v1.2.2
- Source image path: `assets/source/imagegen/update4_contract_monsters/mimi/mimi_combat_sheet_chroma_2026-08-04.png`
- Runtime image path: `assets/sprites/monsters/update4/monster_mimi_sheet.png`

## 자산 목적

`mimic_porter` 전용 기본 전투 스프라이트다. 기존 `goblin` 공유 이미지를 재사용하지 않고, 보물상자 형태의 미미를 독립 자산으로 만들었다. 제품 데이터와 시각 프로필 연결은 다음 CONNECT 패킷의 범위로 남겨 두었다.

## 생성 및 후처리

- 1254×1254 RGB 원본에 4×4, 총 16프레임을 배치했다.
- 행 계약은 `idle_down 2 + down 2 / move_down 4 / attack_down 4 / skill_down 4`다.
- 생성 원본은 평면 `#00ff00` 크로마키 배경으로 만들고, `remove_chroma_key.py`의 border 자동 키·soft matte·edge contract 1·despill로 투명화했다.
- 각 프레임의 실제 캐릭터 영역만 공통 크기로 축소하고, 192×192 셀 안에서 중앙 정렬했다. 모든 프레임의 발 기준선은 `y=183`으로 통일했다.
- 기술 행의 황금 방어막은 캐릭터에 밀착된 형태로 제한해 셀 경계를 침범하지 않도록 했다.
- 투명화 후 premultiplied RGBA 축소로 키 색 번짐을 줄였고, 남은 저알파 초록색 픽셀 3개를 제거했다.

## 연결 범위

이번 패킷에서는 `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 씬과 공통 렌더러를 수정하지 않는다. 런타임 연결은 별도 `V2-P4D-CONNECT-MIMIC` 패킷에서 수행한다.
