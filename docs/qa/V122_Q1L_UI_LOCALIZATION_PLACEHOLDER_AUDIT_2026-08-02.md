# V1.2.2 Q1-L UI·현지화·placeholder 상세 감사

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 감사 목적과 범위

Q1-L은 새 UI를 만드는 단계가 아니라, 현재 제품 화면의 사용자 문구·현지화·내부 ID·placeholder·긴 문구·dead click 경계를 읽기 전용으로 확인하는 단계다. 런타임 코드·데이터·그래픽·오디오·빌드는 수정하지 않았다.

기계 판독 결과는 [Q1-L 인벤토리 JSON](../../tmp/v122_release_polish/q1_l/q1_l_inventory.json)과 [Q1-L 인벤토리 TSV](../../tmp/v122_release_polish/q1_l/q1_l_inventory.tsv)다.

## 현지화와 문구 기준선

- `data/localization/v122_stage10_ui.json`의 `ko`와 `en`은 각각 142개 키이며 누락 키 0개, 빈 값 0개다.
- 설정 키 61개, 이름 등록 키 20개, 튜토리얼 키 61개가 양 언어에 대칭으로 존재한다.
- 가장 긴 한국어 값은 `tutorial.step.TUT_130_GOBLIN_CONTROL` 85자, 가장 긴 영어 값은 `tutorial.instruction.TUT_130_GOBLIN_CONTROL` 124자다. 자동 현지화·튜토리얼·관리·전투·결산 계약은 모두 PASS했다.
- `name.placeholder`는 이름 입력창에서 의도적으로 보이는 사용자 안내 문구다. `open_placeholder` 소켓 상태, `debug_placeholder`, 벽 자산의 placeholder 수치와 legacy socket marker는 UI 문구가 아니라 맵 구조·자산 메타데이터이므로 같은 결함으로 세지 않았다.
- 현지화 값에서 `TODO`, `NOT IMPLEMENTED`, `COMING SOON`, `DEBUG_PLACEHOLDER`를 찾지 못했고, Q1-L 합성 모델의 `developer_copy`도 비어 있다.

## 사용자 화면에 실제 들어가는 ID 재현

### 1. 의회 왕관 후보

`Update4CouncilDecisionOverlay.gd:108`은 후보 표시 이름 뒤에 `candidate.instance_id`를 연결한다. 합성 후보 `{display_name: 곱, instance_id: MON_GOBLIN}`을 넣었을 때 버튼이 `곱 · MON_GOBLIN`으로 생성됐다. 신호 전달에는 ID가 필요하지만 플레이어 문구에는 필요하지 않으므로 `Q1-L-P3-01`로 분리한다.

### 2. 전투 목표와 활성 경로

`V122CombatResultViewModel._objective_label`과 `_route_label`은 내부 room ID 배열을 그대로 `str`로 합친다. 합성 결과는 `방어 목표 · throne`, `활성 경로 · entrance → spike_corridor → throne`이었다. 제품 화면에 연결된 값이므로 `Q1-L-P3-03`으로 기록한다.

### 3. 결산 미지 room fallback

`_room_segment_label`은 알려진 7개 방만 한국어로 변환하고, 새 ID는 입력값 그대로 반환한다. `service_entrance` 합성 결과가 그대로 `service_entrance`였다. 현재 알려진 Stage 경로의 즉시 P1/P2는 아니지만 새 방 추가 때 다시 노출될 수 있어 `Q1-L-P3-04`로 남긴다.

### 4. 기존 S09 `trap` 기록

S09 실제 플레이 보고에는 DAY 2 우측 방·지침의 `trap`, `현재 · trap` 노출이 기록돼 있다. 당시 QA 빌드 SHA가 현재 감사 기준과 다르므로 현재 결함으로 단정하지 않고 `Q1-L-P3-02` 역사적 carry-forward로 둔다. 현재 후보의 DAY 2 대표 화면에서 한 번 재확인한 뒤 재현될 때만 별도 수정 패킷을 만든다.

## 대상 테스트 결과

| 테스트 | 결과 | 확인 내용 | 증거 |
|---|---|---|---|
| `V122Stage10LocalizationTest` | PASS | 설정·이름·ko/en 카탈로그·DAY 1~3 안내 | `tmp/v122_release_polish/q1_l/V122Stage10LocalizationTest.log` |
| `V122StoryProductFlowTest` | PASS | 33 assertions; 스토리·관리·전투 대표 흐름 | `tmp/v122_release_polish/q1_l/V122StoryProductFlowTest.log` |
| `V122TutorialGuidanceLevelTest` | PASS | 전체·핵심만·끄기와 필수 선택/비가림 | `tmp/v122_release_polish/q1_l/V122TutorialGuidanceLevelTest.log` |
| `V122ManagementUIContractTest` | PASS | 관리 표준·Compact·터치 가로·세로 안내 | `tmp/v122_release_polish/q1_l/V122ManagementUIContractTest.log` |
| `V122CombatUISimplificationTest` | PASS | 85 assertions; failure_count 0 | `tmp/v122_release_polish/q1_l/V122CombatUISimplificationTest.log` |
| `V122CombatResultUIContractTest` | PASS | 결과 화면 영역·방향 계약 | `tmp/v122_release_polish/q1_l/V122CombatResultUIContractTest.log` |
| `Q1LUiLocalizationRepro` | PASS_WITH_FINDINGS | 8 assertions; 왕관 후보·전투 라벨·placeholder 합성 재현 | `tmp/v122_release_polish/q1_l/q1_l_ui_localization_repro.log` |

Godot headless 테스트는 모두 종료 코드 0이다. 일부 테스트의 ObjectDB 리소스 정리 경고는 기존 headless 종료 경고이며 UI 판정을 실패시키지 않았다. 전체 회귀·전체 플레이·실제 Windows 후보 화면은 실행하지 않았다.

## 발견 사항과 출시 경계

1. 자동 범위에서 P0/P1/P2 런타임 결함은 재현되지 않았다. 현지화 키·설정·이름·튜토리얼·관리·전투·결산 계약은 PASS다.
2. `Q1-L-P3-01`은 현재 활성 의회 오버레이의 플레이어 문구에 instance ID가 들어가는 재현 가능한 P3다.
3. `Q1-L-P3-03`은 현재 전투 전술 목표/활성 경로에서 room ID가 노출되는 재현 가능한 P3다.
4. `Q1-L-P3-04`는 새 room ID가 추가될 때 결산 문구가 내부 ID로 fallback할 수 있는 P3 검토 항목이다.
5. `Q1-L-P3-02`는 이전 QA SHA의 `trap` 노출 기록을 현재 후보에서 재확인해야 하는 carry-forward다.
6. 전체 버튼·최대 글꼴·긴 문구·dead click의 실제 Windows 화면 검수는 `Q1-L-OWNER-01` `OWNER_QA_PENDING` 출시 게이트다.

따라서 Q1-L 상태는 `TARGETED_PASS_WITH_P3_AND_OWNER_PENDING`이다. P3는 출시 차단 등급이 아니지만 사용자 최종검수 전 별도 작은 수정 패킷으로 분리해야 하며, 실제 화면 확인 전 출시 완료로 표시하지 않는다.

## 다음 작업

1. 계획 순서대로 Q1-P 성능 상세 감사로 이동한다.
2. Q1-L-P3-01·03은 각각 별도 UI 문구 수정 패킷으로 처리한다. 두 결함을 한 커밋에 묶지 않는다.
3. 사용자는 1280×720 대표 화면에서 의회·전투·결산 문구와 전체 버튼/긴 문구/dead click을 확인한다.
4. 사용자 재현이 확인된 항목만 수정하고 해당 테스트와 대표 화면을 다시 확인한다.

## 범위 밖 작업

- 현지화 문구·runtime ID adapter·UI 레이아웃·버튼 동작 수정
- Windows 후보 export·실행·커밋·푸시
- Full 회귀·전체 DAY 1~30 플레이·실제 Mobile Web/기기 검수

Related tests: `V122Stage10LocalizationTest` PASS, `V122StoryProductFlowTest` PASS(33), `V122TutorialGuidanceLevelTest` PASS, `V122ManagementUIContractTest` PASS, `V122CombatUISimplificationTest` PASS(85), `V122CombatResultUIContractTest` PASS, `Q1LUiLocalizationRepro` PASS_WITH_FINDINGS(8)
UI check: headless 합성에서 `곱 · MON_GOBLIN`, `방어 목표 · throne`, `활성 경로 · entrance → spike_corridor → throne`을 확인했고 실제 1280×720 사용자 화면은 미검수
Unresolved issues: Q1-L-P3-01·03 수정 필요, S09 `trap` 현재 후보 재확인, 미지 room label fallback 검토, 전체 UI/max font/long text/dead click 실기 소유자 검수
