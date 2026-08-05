# v1.2.2 시각 개편 20단계 DAY 1 곱 선택 실제 플레이 비교 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Phase 19 다음 작업인 DAY 1 곱 `전열 봉쇄`·`후열 화력`을 동일 조건으로 각각 실제 전투까지 진행해 첫 교전 위치와 결산 문구를 비교한다.
- 완료 조건:
  - 두 선택을 독립 프로세스와 동일 seed로 재생한다.
  - 곱의 실제 생성 위치, 첫 피해 발생 시점·방, 최종 기여도와 결과 문구를 기록한다.
  - 후열 선택이 교전에 참여하지 못하면 능력치 보너스 없이 기존 경로·적 도착·anchor 중 최소 범위만 조정한다.
  - 관련 공간·저장·결산 계약을 다시 검증한다.
- 범위에서 제외한 사항: 튜토리얼 전용 능력치 보너스, 몬스터·적 HP/ATK 변경, 전체 회귀·전체 플레이, Windows/Web 빌드, 커밋·푸시.

## 3. 발견과 수정

### 수정 전 실제 결과

- 전열 곱은 `spike_corridor`에서 정상적으로 첫 교전과 피해 기여를 기록했다.
- 후열 곱은 `lane_a_rear`에서 시작했지만 DAY 1 전투가 끝날 때까지 공격 0, `교전 기록 없음`이었다.
- 원인은 `사수` AI가 배정 방과 인접 방만 방어하는데 `lane_a_rear`와 실제 첫 교전 구역 `spike_corridor` 사이에 `path_a_front_rear`가 하나 더 있어 곱이 전선에 합류하지 못하는 구조였다.

### 최소 수정

- `zone_a_rear`의 anchor를 기존 연결 통로 `path_a_front_rear`로 옮겼다.
- rear zone의 `room_ids`에는 `path_a_front_rear`와 기존 `lane_a_rear`를 함께 유지했다.
- 따라서 후열 곱은 전열보다 깊은 연결 통로에서 시작하지만, 인접한 `spike_corridor`에 적이 도착하면 기존 `사수` AI 규칙으로 지원 교전에 합류한다.
- 곱의 HP, ATK, 이동 속도, 사거리, 스킬, 지침에는 손대지 않았다.
- 결과 view model은 zone ID가 없는 구 저장 payload도 새 rear anchor를 `후방 화력`·`후열`로 판정하도록 room fallback을 보강했다.

## 4. 동일 seed 최종 비교

- seed: `20260730`
- 실행 종류: 실제 `GameRoot`·`CombatSceneController`를 사용하는 자동 런타임 플레이
- 전투 배속: 제품값 x1, 검증 프로세스만 `Engine.time_scale=8`

| 항목 | 전열 봉쇄 | 후열 화력 |
|---|---:|---:|
| 실제 생성 방 | `spike_corridor` | `path_a_front_rear` |
| 곱 첫 타격 | 2.933초 | 4.133초 |
| 첫 타격 시 곱 방 | `spike_corridor` | `spike_corridor` |
| 첫 타격 대상 방 | `path_a_entry_front` | `spike_corridor` |
| 곱 공격 기여 | 186 | 168 |
| 곱 피해 흡수 | 4 | 0 |
| 곱 마무리 | 2회 | 1회 |
| 전투 시간 | 10.533초 | 10.667초 |
| 잔여 몬스터 HP | 431 | 433 |
| 결산 전략 | `전방 봉쇄` | `후방 화력` |
| 결산 배치 | `곱 → 전열` | `곱 → 후열` |
| 결과 | 승리 | 승리 |

- 판정:
  - 전열은 후열보다 1.2초 먼저 접촉하고 입구 쪽 연결 통로의 적을 맞아 봉쇄 역할이 읽힌다.
  - 후열은 더 깊은 위치에서 시작해 적이 가시 복도까지 들어온 뒤 합류하며, 이번 실행에서는 피해를 받지 않았다.
  - 두 선택 모두 공격 기여와 결산 인과가 남으므로 재미 최소 게이트를 통과했다.
- 주의:
  - seed는 wave 구성을 고정하지만 실시간 unit 충돌·공격 순서에는 프레임 간 작은 변동이 있다. 위 수치는 최종 연속 headless 실행 기록이며 balance golden 값으로 고정하지 않는다.
  - GUI 캡처에서도 두 선택의 생성 깊이·첫 교전 위치·비영(非零) 기여·결산 전략 문구는 동일하게 확인했다.

## 5. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/dungeon_quarter/layouts/stage01_dual_front_01.json` | lane A 후열 지원 anchor를 기존 연결 통로로 조정 | 완료 |
| `scripts/v122/ui/V122CombatResultViewModel.gd` | zone ID 없는 payload의 새 rear anchor 결산 fallback | 완료 |
| `tools/DayOneGoblinFormationPlayCompare.gd` | 동일 seed 실제 전투·첫 타격·결산 기록과 PNG 캡처 | 완료 |
| `tools/DayOneGoblinFormationPlayCompare.tscn` | 비교 도구 실행 scene | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 새 실제 후열 생성 anchor 회귀 단언 | 완료 |
| `tools/tests/V122DualFrontLayoutContractTest.gd` | rear support anchor·기존 rear zone coverage 계약 | 완료 |
| `tools/tests/V122CombatResultUIContractTest.gd` | 구 payload room fallback의 후열 결산 계약 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 5~9단계 완료와 다음 10단계 갱신 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE20_DAY1_GOBLIN_PLAY_COMPARE_2026-07-30.md` | 이번 세션 결과와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 최신 진입점과 다음 작업 갱신 | 완료 |

## 6. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델·원본·`SOURCE.md`: N/A
- 신규 런타임 자산: 없음
- 기존 Stage 01 공간·캐릭터·UI 자산만 사용했다.
- 실제 렌더 근거:
  - `tmp/day1_goblin_formation_compare/front_first_engagement.png`
  - `tmp/day1_goblin_formation_compare/rear_first_engagement.png`
  - `tmp/day1_goblin_formation_compare/front_result.png`
  - `tmp/day1_goblin_formation_compare/rear_result.png`

## 7. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `DayOneGoblinFormationPlayCompare.tscn --formation=front` | PASS | `tmp/phase20_front_final.log`, `tmp/day1_goblin_formation_compare/front.json` |
| 2 | `DayOneGoblinFormationPlayCompare.tscn --formation=rear` | PASS | `tmp/phase20_rear_final.log`, `tmp/day1_goblin_formation_compare/rear.json` |
| 3 | Godot GUI 전열·후열 첫 교전과 결과 육안 확인 | PASS | `tmp/day1_goblin_formation_compare/*.png` |
| 4 | `TutorialFlowSmokeTest.tscn` | PASS | `tmp/phase20_targeted_0.log` |
| 5 | `V122DualFrontLayoutContractTest.tscn` | PASS | `tmp/phase20_layout_recheck.log` |
| 6 | `V122DualFrontDefaultActivationTest.tscn` | PASS | `tmp/phase20_targeted_2.log` |
| 7 | `V122SaveZonePlacementCompatibilityTest.tscn` | PASS | `tmp/phase20_targeted_3.log` |
| 8 | `V122FacilityZoneCombatConsumerTest.tscn` | PASS | `tmp/phase20_targeted_4.log` |
| 9 | `V122CombatResultUIContractTest.tscn` | PASS | `tmp/phase20_result_recheck.log` |
| 10 | `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | `tmp/phase20_targeted_6.log` |
| 11 | 관련 파일 `git diff --check` | PASS | 명령 출력 |
| 12 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- Godot root certificate와 종료 시 resource 잔류 메시지는 테스트 판정과 무관한 기존 환경 관찰이며 모든 대상 scene의 exit code는 0이었다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능·데이터 변경 여부: 결과 fallback과 두 계약 단언을 추가한 뒤 해당 테스트를 다시 실행해 PASS를 확인했다. 이후 변경은 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 8. 다음 작업 순서

1. 순차 시각 개편 10단계 `튜토리얼·등록·문구`로 돌아간다.
2. 먼저 튜토리얼 안내 수준 `전체/핵심만/끄기`, 이름 등록 화면, 한국어/영어 노출 문구의 현재 연결 상태를 조사해 기능 공백을 목록화한다.
3. 조사 뒤 가장 작은 공통 공백 하나만 구현하고 1920 full-canvas와 1366/1280 compact에서 안내가 실제 클릭 대상을 가리지 않는지 확인한다.
4. 10단계 완료 뒤 11단계 DAY 2 이후 파급 수정으로 넘어간다.
5. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification...origin/codex/v122-ui-simplification`, Phase 3~20 누적 미커밋 변경이 존재한다.
- 이번 단계의 코드·데이터·테스트·문서는 미커밋 상태다.
- 대량 `.import` 갱신과 이전 Phase 누적 변경을 그대로 보존했다.
- 빌드·커밋·푸시는 진행하지 않았다.
- 비교 JSON·PNG와 테스트 로그는 `tmp/`에 있으며 커밋 대상이 아니다.

## 10. 종료 체크리스트

- [x] 동일 seed 전열·후열 실제 런타임 비교
- [x] 수정 전 후열 무교전 원인 확인
- [x] 능력치 보너스 없는 기존 anchor 최소 조정
- [x] 두 선택 모두 실제 교전·결산 인과 연결
- [x] 관련 공간·저장·결산 테스트 통과
- [x] 실제 GUI 전열·후열 첫 교전과 결과 확인
- [x] 요청받지 않은 전체 회귀·전체 플레이 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
