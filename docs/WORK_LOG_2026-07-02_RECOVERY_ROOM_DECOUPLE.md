이 파일이 왜 필요한지: 2026-07-02 회복방 배경 고정 표현을 제거하고 회복 시설 아이콘을 별도 에셋으로 분리한 작업 내역과 검증 결과를 백업한다.

# 작업 로그: 회복방 배경/아이콘 분리

작성일: 2026-07-02

## 요청

사용자가 보물방 배경 수정 후 "회복방을 그대로 둔 이유는 뭐야? 없으면 수정하고 회복실방도 아이콘 따로 만들어줘"라고 요청했다.

이전 작업에서 회복방을 남긴 특별한 이유는 없었다. 우선 사용자가 명시적으로 지적한 보물방 배경만 수정했기 때문에 회복 둥지가 배경에 남아 있었다. 방 용도 변경 시스템 기준에서는 회복방도 배경에 고정되면 안 되므로 이번 작업에서 같이 분리했다.

## 작업 내용

- 배경 이미지 수정:
  - `assets/sprites/dungeon_gpt2/gpt2_dungeon_connected_map.png`
  - 우상단 회복방에 고정으로 그려진 둥지, 알, 회복 느낌의 녹색 바닥 표현 제거
  - 중립적인 빈 방/보관 공간처럼 보이게 변경

- 새 회복 시설 아이콘 추가:
  - `assets/sprites/room_markers/marker_recovery_room_gpt2.png`
  - 자홍색 크로마키 배경으로 생성
  - 로컬 투명 처리 후 256x256 RGBA PNG로 리사이즈
  - 기존 `marker_recovery_nest_gpt2.png`도 같은 아이콘으로 갱신해 이전 참조가 남아도 깨지지 않게 처리

- 데이터/코드 연결:
  - `data/rooms.json`의 회복 방 icon 값을 새 아이콘으로 변경
  - `scripts/game/GameRoot.gd`의 props 로딩 목록에 새 아이콘 추가
  - 회복 시설 변경 정의도 새 아이콘을 사용하도록 변경

## 생성 원본

- 회복방 중립 배경 편집본:
  - `C:\Users\LDK-6248\.codex\generated_images\019f200d-8e32-7233-a6f3-72a76f65ec97\ig_0eff091449cf6d66016a45c3363fd881919b3ef8e52d87a90a.png`
- 회복 아이콘 자홍색 크로마키 소스:
  - `C:\Users\LDK-6248\.codex\generated_images\019f200d-8e32-7233-a6f3-72a76f65ec97\ig_05ba4aac5f7ade84016a45c445d7008199b5fdafb6a29ec33a.png`

## 검증 계획

다음 명령으로 확인한다.

```powershell
godot --headless --path . --import
godot --headless --path . --scene res://tools/DemoSmokeTest.tscn
godot --path . --scene res://tools/ManualVerificationCapture.tscn
```

확인할 항목:

- 우상단 방 배경에 회복 둥지와 알이 고정으로 남아 있지 않은지
- 회복 방 마커가 새 별도 아이콘으로 표시되는지
- 방 용도 변경 후 회복 아이콘이 현재 회복 시설 위치를 따라가는지
- 스모크 테스트가 기존 방 용도 변경 흐름과 전투 흐름을 통과하는지

## 검증 결과

- `godot --headless --path . --import` 성공
- `godot --headless --path . --scene res://tools/DemoSmokeTest.tscn` PASS
- `godot --path . --scene res://tools/ManualVerificationCapture.tscn` 성공
- `tmp/manual_verification/01_management.png` 기준 우상단 방 배경의 고정 회복 둥지는 제거됨
- 회복 시설은 새 별도 아이콘 오버레이로 표시됨
