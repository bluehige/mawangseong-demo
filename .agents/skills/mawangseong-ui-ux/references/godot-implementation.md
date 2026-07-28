# Godot 구현 규칙

## 엔진과 기준

- Godot 4.5.2 이상을 현재 실행 기준으로 사용한다.
- UI 변경 전 `AGENTS.md`, 최신 handoff, 관련 controller/test를 읽는다.
- 작업 브랜치와 기준 SHA를 기록한다.

## 현재 주요 경로

- 공통 테마: `scripts/v20/ui/V20UITheme.gd`
- 정보 HUD: `scripts/v20/ui/V20InformationHUD.gd`
- 타이틀 진입: `scripts/v20/ui/V20TitleEntryPanel.gd`
- 관리 연결: `scripts/game/ManagementSceneController.gd`
- 배치 보드: `scripts/v20/placement/V20PlacementBoard.gd`
- 몬스터 drag: `scripts/v20/placement/V20MonsterDragButton.gd`
- 배치 구역 버튼: `scripts/v20/placement/V20PlacementRoomButton.gd`

경로가 이동했거나 새 버전 구조가 생기면 최신 저장소를 기준으로 갱신한다.

## 구현 경계

UI 요청만 있을 때 변경하지 않는다.

- combat balance
- AI와 target priority
- spawn timing/count
- HP/ATK
- 시설·몬스터 효과
- 저장 schema
- DAY 콘텐츠와 스토리
- release/tag/build provenance

UI 표시와 실제 데이터가 불일치하면 임시 표시 계산을 추가하지 말고 데이터 소유자와 연결 경로를 확인한다.

## Theme와 토큰

- 재사용 색·폰트·여백·StyleBox는 `V20UITheme` 또는 합의된 theme resource에 둔다.
- 개별 노드에 같은 색상과 스타일을 반복 하드코딩하지 않는다.
- primary, secondary, danger, selected, focus, disabled 상태를 역할 기반 함수로 만든다.
- responsive scale은 글꼴뿐 아니라 hit target, 간격, panel constraints와 함께 검증한다.

## 레이아웃

- anchor/container 기반을 우선하고 절대 좌표는 지도·전장 overlay처럼 좌표 계약이 필요한 곳에 제한한다.
- 최소 1280×720, 1366×768, 1920×1080에서 핵심 rect가 화면 내부에 있고 서로 가리지 않는지 확인한다.
- text wrapping과 minimum size가 긴 한국어·영어·숫자에서 유지되는지 확인한다.
- 선택 상세를 열어도 지도와 전장의 중심 좌표가 불필요하게 이동하지 않아야 한다.

## 입력

- `mouse_filter`, focus mode, focus neighbor를 의도적으로 설정한다.
- 투명 overlay가 world/board 입력을 가로채지 않는지 실제 입력으로 확인한다.
- 텍스트 입력 포커스가 전역 단축키에 빼앗기지 않게 한다.
- drag preview와 drop target의 logical/world ID를 기록하고 invalid drop에서 상태가 변하지 않게 한다.
- 모바일 범위가 포함될 때 drag 외 탭 선택·배치 대체를 검토한다.

## 상태와 피드백

- UI는 입력을 받았다는 상태와 제품 결과를 구분한다.
- 실패 시 이유를 실제 validator/service 결과에서 가져온다.
- 성공 시 실제 대상 ID, 자원 변화, 지속/완료를 표시한다.
- 애니메이션은 상태 전환을 설명해야 하며 입력 가능 시점을 감추지 않는다.

## 테스트 코드

- 노드 존재와 문구 검사만 추가하지 않는다.
- rect 내부·비겹침, primary action count, hit target, focus, 데이터 ID, signal wiring을 목적에 맞게 검사한다.
- 자동 테스트가 사용자 이해를 증명한다고 서술하지 않는다.
- 실제 렌더 캡처는 `tmp/` 등 비추적 경로에 둔다.
