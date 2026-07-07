# Handoff: Next Worker Current State (2026-07-08)

이 문서는 다음 작업자가 가장 먼저 읽어야 하는 최신 인수인계 문서다.

## Session Compass

우리는 장식용 배경이 아니라 플레이 가능한 마왕성 던전 데모를 만들고 있다.

초보자 설명:

- 맵은 그림 한 장이 아니라, 방과 통로가 실제 데이터로 연결된 구조여야 한다.
- 플레이어가 방을 고르고, 길을 잇고, 몬스터를 배치하고, 전투를 준비하는 흐름이 직관적이어야 한다.
- 보기 좋은 UI보다 먼저, "내가 지금 무엇을 선택했고 다음에 무엇을 누르면 되는지"가 보여야 한다.

## Latest User Direction

최신 사용자 피드백:

- 건물 배치와 도로 배치가 너무 복잡하고 직관성이 없다.
- 버튼 수가 너무 많고 이상하다.
- 더 쉽고 자연스럽고 재미있게 배치할 수 있게 해야 한다.
- 유사 게임 레퍼런스를 참고해 단순한 조작 방식으로 바꿔야 한다.

이번 세션의 결론:

- 길 배치는 "버튼으로 방향을 조립하는 방식"에서 "시작 방을 고르고 연결할 방을 클릭하면 자동으로 통로가 생기는 방식"으로 바꿨다.
- 오른쪽 선택방 패널은 지침 버튼 7개를 없애고, 선택 메뉴 2개로 압축했다.
- 다음 작업은 건물 배치와 몬스터 배치까지 같은 원칙으로 더 자연스럽게 만드는 것이다.

## Reference Direction Used

참고 방향:

- `Dungeon Keeper` / `War for the Overworld`: 플레이어가 던전 영역을 고르면 시스템과 일꾼이 실제 공사를 처리한다.
- `Two Point Hospital` / `Prison Architect`: 방과 시설은 팔레트에서 고르고, 배치는 맵에서 직접 조작한다.
- `Cities: Skylines`: 길은 세부 방향 버튼보다 시작점과 끝점 중심으로 연결한다.

우리 게임에 적용한 원칙:

- 길은 "시작 방 -> 목표 방 클릭"으로 만든다.
- 버튼은 항상 보이는 개수를 줄이고, 선택지는 메뉴나 맥락 UI로 숨긴다.
- 선택된 방, 연결 후보, 추천 경로는 색과 선으로 맵 위에 보여준다.

## Implemented This Pass

### Map / Road Placement UX

- `scripts/game/GameRoot.gd`
  - `_map_editor_connect_selected_to()` 추가.
  - 맵 편집 중 방을 클릭하면 선택된 방과 목표 방을 자동 연결한다.
  - 바로 붙은 방이면 직접 연결하고, 떨어진 방이면 중간 통로 모듈을 자동 생성한다.
  - 연결 후 클릭한 목표 방이 다음 시작 방이 되어 연속 연결이 가능하다.

- `scripts/game/ManagementSceneController.gd`
  - 왼쪽 `맵 커스텀` 패널을 단순화했다.
  - 이전처럼 방향/후보/통로/양끝 연결 버튼을 많이 보여주지 않는다.
  - 현재 노출 버튼은 `추천 연결`, `연결 끊기`, `통로 삭제`, `저장`, `취소` 중심이다.

- `tools/RoomPathAuthoringProbe.gd`
  - 목표 방 클릭 자동 연결 검증을 추가했다.
  - 중간 통로 생성, 양쪽 소켓 연결, 목표 방으로 선택 전환되는 흐름을 테스트한다.

초보자 설명:

- 소켓은 방이나 통로에 있는 "문 연결 지점"이다.
- 자동 연결은 사용자가 세부 방향을 고르지 않아도, 시스템이 연결 가능한 문과 통로를 찾아 이어주는 기능이다.

### Selected Room Inspector UI

- `scripts/ui/HUDController.gd`
  - 오른쪽 선택방 패널을 요약 / 연결 / 운영 지침 / 몬스터 배치 구조로 정리했다.
  - 전체 지침 3개 버튼과 방 지침 4개 버튼을 없애고, `운영 지침` 선택 메뉴 2개로 압축했다.
  - 튜토리얼 하이라이트 대상은 유지했다.
  - 이미 선택된 `사수`를 다시 골라도 튜토리얼 진행 신호가 나가도록 메뉴 신호를 보완했다.

- `scripts/game/GameRoot.gd`
  - 튜토리얼 문구를 실제 UI에 맞게 수정했다.
  - 기존: "사수 버튼을 누르세요."
  - 현재: "운영 지침에서 전체를 사수로 바꾸세요."

### Build Flow

- `scripts/game/GameRoot.gd`
  - 하단 `건설` 버튼이 감시초소를 바로 짓지 않고, 변경 가능한 방을 찾아 시설 변경 메뉴를 열도록 바꿨다.
  - 고정 방이 선택된 상태에서도 첫 번째 변경 가능한 방을 찾아 건설 흐름을 시작한다.

## Related Work Already In Tree

현재 작업 트리에는 이번 UX 수정 외에도 이전 세션의 튜토리얼/전투/에셋 임포트 변경이 함께 있다.

주요 묶음:

- 튜토리얼 전투 밸런스 개선
- 전투 결과 성장 확인 루프
- 온보딩 대사/초상화/폰트/UI 스킨 임포트
- 진화 시스템 참고 문서
- 맵 커스텀 핸드오프 업데이트

주의:

- `.import` 파일이 많이 생기거나 수정되어 있다. Godot가 에셋을 다시 임포트하며 만든 메타 파일이다.
- 단, 오래된 실패 시안과 격리된 콘셉트 이미지는 사용자에게 현재 방향처럼 보여주면 안 된다. `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`의 quarantine 규칙을 먼저 읽어라.

## Fresh Verification

최근 확인된 검증:

```powershell
godot --headless --path . --import
godot --headless --path . --run res://tools/RoomPathAuthoringProbe.tscn
godot --headless --path . --run res://tools/DemoSmokeTest.tscn
godot --headless --path . --run res://tools/TutorialFlowSmokeTest.tscn
godot --headless --path . --run res://tools/BalanceSimulation.tscn -- --assert-tutorial-balance
godot --path . --run res://tools/ManualVerificationCapture.tscn
```

결과:

- `ROOM_PATH_AUTHORING_PROBE: PASS`
- `DEMO_SMOKE_TEST: PASS`
- `TUTORIAL_FLOW_SMOKE_TEST: PASS`
- `BALANCE_ASSERT: PASS`
- 수동 캡처 확인: `tmp/manual_verification/01_management.png`, `tmp/manual_verification/01_map_editor.png`

밸런스 검증 최신 수치:

```text
DAY1_AUTO: WIN 56.4s, enemy_down 2/2
DAY2_TRAP_DIRECTIVE: WIN 54.1s, enemy_down 3/3
DAY3_ASSISTED: WIN 70.0s, enemy_down 5/5
```

기존부터 반복되는 경고:

- `Loaded resource as image file, this will not work on export`
- 이는 현재 UI 스킨 PNG를 런타임에서 직접 이미지로 로드하는 방식 때문에 나오는 Godot 내보내기 경고다.
- 이번 UX 변경 실패는 아니지만, 정식 배포 전에는 `ResourceLoader` 기반 텍스처 임포트 방식으로 정리할 필요가 있다.

## Next Work Order

1. 최신 빌드를 직접 실행해 새 경로 편집 흐름을 손으로 확인한다.
   - 시작 방 선택
   - 연결할 방 클릭
   - 통로 자동 생성
   - 저장

2. 건물 배치 UX를 같은 원칙으로 단순화한다.
   - 현재는 `건설` 버튼이 시설 변경 메뉴를 여는 수준이다.
   - 다음 목표는 빈 슬롯 또는 변경 가능한 방을 맵에서 직접 클릭하면 시설 팔레트가 자연스럽게 뜨는 흐름이다.
   - 버튼보다 맵 클릭을 우선시해야 한다.

3. 몬스터 배치 UX를 개선한다.
   - 현재는 맵 위 드래그 또는 오른쪽 패널의 몬스터 이름 버튼으로 배치한다.
   - 다음 목표는 방 수용량과 여러 마리 배치를 더 명확히 보여주는 것이다.
   - 방 하나에 한 마리만 가능한 느낌을 주면 안 된다.

4. 오른쪽 패널 메뉴 팝업의 실제 클릭감을 확인한다.
   - 선택 메뉴가 튜토리얼 중 잘 열리는지 확인한다.
   - `사수`가 이미 선택된 상태에서도 다시 선택하면 튜토리얼이 넘어가는지 직접 확인한다.

5. UI 스킨 PNG 로딩 경고를 정리한다.
   - 지금은 실패가 아니지만 정식 빌드 전에는 경고를 줄여야 한다.

## Files To Inspect First

다음 작업자는 이 순서로 읽어라:

1. `docs/HANDOFF_NEXT_WORKER_2026-07-08.md`
2. `docs/HANDOFF_MAP_CUSTOM_CURRENT_2026-07-03.md`
3. `docs/HANDOFF_TUTORIAL_GAME_LOOP_AUDIT_2026-07-07.md`
4. `docs/WORK_LOG_2026-07-07_TUTORIAL_COMBAT_BALANCE.md`
5. `docs/design/EVOLUTION_SYSTEM_REFERENCE_OPTIONS_2026-07-07.md`
6. `scripts/game/GameRoot.gd`
7. `scripts/game/ManagementSceneController.gd`
8. `scripts/ui/HUDController.gd`
9. `tools/RoomPathAuthoringProbe.gd`

## Risks And Do-Not-Disturb Notes

- 사용자 변경이 섞인 작업 트리일 수 있다. 변경을 되돌리지 말고, 먼저 `git status --short --branch`로 확인한다.
- 격리된 실패 이미지와 콘셉트 이미지를 현재 방향으로 제시하지 않는다.
- 자동 경로 연결은 사용자가 쉽게 쓰기 위한 상위 UX다. 기존 수동 경로 함수들은 테스트와 후속 확장에 쓰일 수 있으므로 함부로 삭제하지 않는다.
- 튜토리얼 대상 ID인 `GLOBAL_DIRECTIVE_DEFEND`, `ROOM_DIRECTIVE_BLOCK_ENTRANCE`는 UI 구조를 바꿔도 유지해야 한다.
- 전투 밸런스는 현재 튜토리얼 기준 통과 상태다. 침공/스토리 확장 전까지 무작정 적 체력만 올리지 않는다.

## Exact Start Sentence For Next Session

다음 세션은 이렇게 시작한다:

> 최신 핸드오프를 읽었습니다. 지금 목표는 맵 편집처럼 건물 배치와 몬스터 배치도 맵 클릭 중심으로 단순화하고, 튜토리얼 UI가 실제 조작과 어긋나지 않는지 직접 확인하는 것입니다.
