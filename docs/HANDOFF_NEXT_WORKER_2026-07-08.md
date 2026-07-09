# Handoff: Next Worker Current State (2026-07-08)

이 문서는 다음 작업자가 가장 먼저 읽어야 하는 최신 인수인계 문서다.

최신 2026-07-09 추가 업데이트:

- DAY 15 성기사 견습 셀렌 보스/Stage 02 해금 게이트 조각은 구현했고 `docs/HANDOFF_DAY15_SELEN_STAGE_TWO_UNLOCK_2026-07-09.md`에 정리했다.
- 신규 보스 적 `selen_trainee_paladin`과 캐릭터 `CHR_SELEN`을 추가했다. 전투 스프라이트 16장, `.import` 16장, 체크리스트 초상 1장과 `.import` 1장을 생성했다.
- 셀렌 디자인 원본은 built-in `image_gen`으로 생성했고 `assets/source/imagegen/selen/CHR_SELEN_design_sheet_imagegen.png`에 복사했다. 실제 `CHR_SELEN` 초상은 이 원본에서 crop했다. 전투 프레임은 이 디자인을 기준으로 단순화한 192px 런타임 스프라이트다.
- DAY 15는 `campaign_stage_two_upgrade_funded` 플래그만으로 열리지 않는다. 현재 자원도 Stage 02 비용 `gold 720 / infamy 720` 이상이어야 전투가 시작된다.
- DAY 15 승리 시 `campaign_stage_two_unlock_ready`가 true가 된다. Stage 02 비주얼 전환은 아직 하지 않는다.
- 셀렌 실전 HP는 DAY15 탐험가보다 높게 조정했다: 탐험가 369, 셀렌 403.
- DAY 15 밸런스는 세 첫 승급 선택지 모두 통과했다: slime 89.4s, goblin 73.7s, imp 75.4s, 모두 왕좌 피해 0, 몬스터 다운 1, 도둑 도달/도난 없음, Stage 02 unlock ready true.
- 검수 에이전트 1차 지적 3건은 수정했다: 현재 비용 재검사 누락, 밸런스 시뮬레이션 경제 조건 불일치, 보스 HP가 일반 탐험가보다 낮던 문제.
- 이미지 생성 보정 후 재검수 지적도 반영했다. 아래 `Next Work Order`, `Files To Inspect First`, 시작 문장은 이제 DAY16 지역 보급로 원정 기준이며, 최종 재검수 결과는 `No findings`다.
- 다음 권장 작업은 DAY16 지역 보급로 원정 선택지다. 두 번째 승급은 계속 DAY23까지 열지 말고, Stage 02 비주얼 전환은 승인된 런타임 방/경로 자산이 있을 때만 진행한다.

이전 2026-07-09 추가 업데이트:

- DAY 14 성 업그레이드 심사 조각은 구현했고 `docs/HANDOFF_DAY14_STAGE_TWO_REVIEW_2026-07-09.md`에 정리했다.
- DAY 14는 Stage 02 비주얼 전환이 아니다. 승인된 런타임 방/경로 자산이 아직 없으므로 비용 마련/심사 플래그만 구현했다.
- Stage 02 심사 비용은 `gold 720 / infamy 720`이며, 승리 후 비용이 있으면 `campaign_stage_two_upgrade_funded`가 true가 된다.
- DAY 14 웨이브는 탐험가 3, 조사관 1, 방패병 1, 도둑 2로 조정했다. 세 첫 승급 선택지 모두 승리, 왕좌 피해 0, 도둑 도달/도난 없음, Stage 02 funded true다.
- 다음 권장 작업은 DAY15 성기사 견습 셀렌 보스/Stage 02 unlock gate다. 두 번째 승급은 계속 열지 말고 DAY23 계획을 유지한다.

이전 2026-07-09 추가 업데이트:

- DAY 13 방패병 역할 카운터 조각은 구현했고 `docs/HANDOFF_DAY13_SHIELDBEARER_COUNTER_2026-07-09.md`에 정리했다.
- 몬스터 진화 계획표 기준으로 두 번째 승급은 DAY23까지 보류한다. DAY13~15는 첫 승급 1명 기준으로 밸런스를 본다.
- `promotion_limit` 데이터 필드를 추가해 DAY12/DAY13 모두 승급 1명 제한을 명시했다. 캠페인 데이터가 아직 없는 DAY14 이후도 DAY23 전까지는 코드 기본값으로 1명 제한을 유지한다.
- 신규 적 `shieldbearer` / `왕국 방패병`을 추가했다. 느리고 단단한 전열 카운터이며 특수 AI는 아직 넣지 않았다.
- 방패병 전투 스프라이트 16장과 `.import` 16장을 생성했다. 재생성 스크립트는 `tools/generate_shieldbearer_enemy_assets.py`다. 스모크에서 idle/move/attack/skill/down 프레임을 확인한다.
- DAY13 밸런스는 세 첫 승급 선택지 모두 승리로 확인했다: slime 86.1s, goblin 76.1s, imp 75.9s, 모두 왕좌 피해 0, 몬스터 다운 1, 도둑 도달/도난 없음.
- 검수 에이전트 1차 지적 2건은 수정했다: DAY14 이후 승급 제한 누락, 방패병 down 애니메이션 테스트 누락.
- 다음 권장 작업은 DAY14 성 업그레이드 심사/Stage 02 준비다. 두 번째 승급을 열지 말고, 업그레이드 비용/이벤트 게이트를 먼저 정한다.

이전 2026-07-09 추가 업데이트:

- DAY 12 첫 몬스터 승급/진화 조각은 구현 완료했고 `docs/HANDOFF_DAY12_FIRST_PROMOTION_2026-07-09.md`에 정리했다.
- 진화 계획표 분석 결과, 이번 범위는 분기/합성이 아니라 승급형 1단계로 제한했다.
- DAY 12는 `slime`, `goblin`, `imp` 중 1명만 첫 승급할 수 있고, 첫 승급 전에는 DAY 12 전투가 시작되지 않는다.
- 승급은 실제 전투 스킬에도 반영된다: 점액 방패 강화, 날붙이 베기 피해 증가, 화염구 피해/사거리 증가.
- 승급 그래픽 리소스는 full evolved combat sprite가 아니라 UI 배지 3종으로 처리했다. 다음 분기 진화 전까지 기존 전투 스프라이트를 유지한다.
- 검수 에이전트 지적을 두 차례 반영했고 최종 재검수 결과는 `No findings`다.
- 다음 권장 작업은 DAY 13에서 두 번째 승급 해금 타이밍과 승급 대응용 신규 적 역할을 정하는 것이다. 신규 적을 실제 스폰시키면 전투 스프라이트 제작/import와 스모크 검증을 같이 해야 한다.

이전 2026-07-09 추가 업데이트:

- DAY 11 왕국 대응 조각은 구현 완료했고 `docs/HANDOFF_DAY11_KINGDOM_NOTICE_2026-07-09.md`에 정리했다.
- DAY 11은 기존 1장 자산을 의도적으로 재사용한다. 새 raster art는 생성하지 않았다.
- Stage 02 비주얼 전환은 승인된 방/경로 자산이 생기기 전까지 시작하지 않는다.

2026-07-09 업데이트:

- 튜토리얼 P1 확인과 최신 pull 기준 검증은 `docs/HANDOFF_TUTORIAL_P1_AND_VERIFICATION_2026-07-09.md`에 이어서 정리됐다.
- DAY 05~07 정규 캠페인, 출연 타이밍, 웨이브, 첫 시설 강화, 생성 초상 자산은 `docs/HANDOFF_DAY05_07_CAMPAIGN_AND_ASSETS_2026-07-09.md`에 이어서 정리한다.
- 다음 구현 시작점은 DAY 08~10 묶음이다. 다음 세션은 `docs/HANDOFF_NEXT_SESSION_DAY08_10_PLAN_2026-07-09.md`를 먼저 읽고 시작한다.
- DAY 08~10은 추가 몬스터 확인, 스토리 라인/밸런스 배분, 신규 적 클래스 추가, 초상/전투 그래픽 리소스 제작과 Godot import 검증까지 포함한다.
- DAY 08~10 구현 결과, 신규 `investigator` 적 클래스, 조사관 아이리스 초상/전투 자산, 밸런스 결과는 `docs/HANDOFF_DAY08_10_CAMPAIGN_INVESTIGATOR_ASSETS_2026-07-09.md`에 정리했다.

## Session Compass

우리는 장식용 배경이 아니라 플레이 가능한 마왕성 던전 데모를 만들고 있다.

초보자 설명:

- 맵은 그림 한 장이 아니라, 방과 통로가 실제 데이터로 연결된 구조여야 한다.
- 플레이어가 방을 고르고, 길을 잇고, 몬스터를 배치하고, 전투를 준비하는 흐름이 직관적이어야 한다.
- 보기 좋은 UI보다 먼저, "내가 지금 무엇을 선택했고 다음에 무엇을 누르면 되는지"가 보여야 한다.

## Latest User Direction

최신 사용자 피드백:

- 디자인 이미지는 Codex built-in `image_gen`으로 생성한 원본을 남겨야 한다. 로컬/절차 생성 이미지를 최종 디자인 원본처럼 쓰지 않는다.
- 작업은 정한 순서대로 구현하고, 종료 전 검수 에이전트를 돌린 뒤 지적 사항을 수정하고 다시 검수한다.
- 핸드오프 문서에는 다음 세션이 바로 이어갈 수 있게 규칙, 검증 결과, 검수 결과를 남긴다.
- 현재 다음 구현 목표는 DAY16 지역 보급로 원정 선택지다.

이번 세션의 결론:

- DAY15 셀렌 보스와 Stage 02 해금 준비 게이트는 구현/검증했다.
- 셀렌 디자인 원본은 built-in `image_gen` 결과로 보정했고, 초상은 그 원본에서 crop했다.
- Stage 02 비주얼 전환은 아직 보류다.
- 두 번째 승급은 DAY23 전까지 열지 않는다.
- 다음 작업은 DAY16 지역 보급로 원정 선택지를 첫 승급 1명 기준 밸런스로 구현하는 것이다.

## Previous UX Reference Direction

이전 맵/배치 UX 작업 때 사용한 참고 방향이다. 현재 다음 작업 지시는 위 DAY16 계획과 `Next Work Order`를 따른다.

- `Dungeon Keeper` / `War for the Overworld`: 플레이어가 던전 영역을 고르면 시스템과 일꾼이 실제 공사를 처리한다.
- `Two Point Hospital` / `Prison Architect`: 방과 시설은 팔레트에서 고르고, 배치는 맵에서 직접 조작한다.
- `Cities: Skylines`: 길은 세부 방향 버튼보다 시작점과 끝점 중심으로 연결한다.

우리 게임에 적용한 원칙:

- 길은 "시작 방 -> 목표 방 클릭"으로 만든다.
- 버튼은 항상 보이는 개수를 줄이고, 선택지는 메뉴나 맥락 UI로 숨긴다.
- 선택된 방, 연결 후보, 추천 경로는 색과 선으로 맵 위에 보여준다.

## Previous UX Implementation Notes

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

1. `docs/HANDOFF_DAY15_SELEN_STAGE_TWO_UNLOCK_2026-07-09.md`를 먼저 읽고 DAY15 최종 상태를 기준으로 시작한다.
   - Stage 02는 `campaign_stage_two_unlock_ready` 플래그까지만 준비된 상태다.
   - 성/방 비주얼 전환은 승인된 room/path 런타임 에셋 매트릭스가 준비될 때까지 건드리지 않는다.
   - 두 번째 승급은 DAY23 계획 전까지 열지 않는다.

2. DAY16 지역 보급로 원정 선택지를 구현한다.
   - DAY15 이후 Stage 02 해금 준비 상태를 한두 줄 관리 대사로 후속 처리한다.
   - 원정 선택지는 다음 방어의 자원 또는 적 구성에 영향을 주는 정도로 제한한다.
   - 새 보스나 두 번째 승급을 동시에 넣지 않는다.

3. DAY16 방어/원정 밸런스를 검증한다.
   - 첫 승급 1명 기준을 유지한다.
   - 보물/자원 압박은 한 가지 축만 추가한다.
   - 기존 DAY15 셀렌 보스 밸런스가 회귀하지 않는지 최소 한 번 재확인한다.

4. 새 NPC/적/이미지가 필요하면 이 순서를 지킨다.
   - 캐릭터/적 데이터 추가.
   - Codex built-in `image_gen` 원본 생성 및 프로젝트 복사.
   - 런타임 초상/스프라이트 연결과 Godot import.
   - smoke test, balance simulation, 검수 에이전트, 핸드오프 갱신.

5. 작업 종료 전 문서화한다.
   - DAY16 전용 핸드오프 문서를 새로 만든다.
   - 이 `HANDOFF_NEXT_WORKER_2026-07-08.md`의 최상단 최신 업데이트와 `Next Work Order`를 다시 갱신한다.
   - 검수 에이전트 지적 사항과 수정 결과를 문서에 남긴다.

## Files To Inspect First

다음 작업자는 이 순서로 읽어라:

1. `docs/HANDOFF_NEXT_WORKER_2026-07-08.md`
2. `docs/HANDOFF_DAY15_SELEN_STAGE_TWO_UNLOCK_2026-07-09.md`
3. `docs/HANDOFF_DAY14_STAGE_TWO_REVIEW_2026-07-09.md`
4. `docs/design/EVOLUTION_SYSTEM_REFERENCE_OPTIONS_2026-07-07.md`
5. `data/campaign_days.json`
6. `data/waves.json`
7. `data/raid_missions.json`
8. `scripts/game/GameRoot.gd`
9. `tools/DemoSmokeTest.gd`
10. `tools/BalanceSimulation.gd`

## Risks And Do-Not-Disturb Notes

- 사용자 변경이 섞인 작업 트리일 수 있다. 변경을 되돌리지 말고, 먼저 `git status --short --branch`로 확인한다.
- 격리된 실패 이미지와 콘셉트 이미지를 현재 방향으로 제시하지 않는다.
- DAY16 작업 중 Stage 02 비주얼 전환을 임의로 시작하지 않는다.
- DAY23 전에는 두 번째 승급을 열지 않는다.
- 새 이미지가 필요하면 Codex built-in `image_gen` 원본을 남긴다. 로컬/절차 생성 이미지를 최종 디자인 원본처럼 기록하지 않는다.
- 전투 밸런스는 DAY15 기준 통과 상태다. 침공/스토리 확장 전까지 무작정 적 체력만 올리지 않는다.

## Exact Start Sentence For Next Session

다음 세션은 이렇게 시작한다:

> 최신 핸드오프를 읽었습니다. DAY15 셀렌 보스와 Stage 02 해금 준비 플래그는 검수까지 끝났고, 다음 목표는 DAY16 지역 보급로 원정 선택지를 첫 승급 1명 기준 밸런스로 구현하는 것입니다.
