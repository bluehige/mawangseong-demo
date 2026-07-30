# v1.2.2 시각 개편 18단계 DAY 1 곱 선택 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 상태: 미커밋 작업 트리

## 2. 확정한 DAY 1 선택

- 푸딩은 전열, 핀은 후열에 고정한다.
- 플레이어가 직접 선택하는 몬스터는 푸딩이 아니라 곱이다.
- 곱을 고르면 지도에서 다음 두 위치만 선택할 수 있다.
  - `전열 봉쇄`: 푸딩이 지키는 전열에 합류
  - `후열 화력`: 핀이 지키는 후열에 합류
- 전체 지침 `사수`는 DAY 1 기준선으로 계속 고정한다.
- 별도 능력치 보너스를 만들지 않고 기존 구역·경로·전투 규칙으로 차이를 만든다.

## 3. 구현 내용

### 튜토리얼과 입력

- `TUT_030_SELECT_SLIME`, `TUT_040_DEPLOY_SLIME` ID는 기존 저장 호환을 위해 이름을 바꾸지 않았다.
- 두 단계의 실제 focus·문구·검증 대상은 각각 `CHR_GOB`, `DAY1_GOBLIN_FORMATION`으로 바꿨다.
- 곱 선택 뒤 배치 단계가 자동 완료되던 기존 슬라임 예외 처리를 제거했다.
- 푸딩·핀 카드는 DAY 1 튜토리얼 동안 비활성화하고 지도 드래그·클릭 배치도 차단했다.
- 곱을 고르면 배치 모드를 유지하고 `barracks`, `recovery` 두 물리 슬롯만 유효 대상으로 표시한다.
- 이 두 ID는 시설 내용이 아니라 Stage 01의 전열·후열 물리 슬롯을 가리킨다. 병영·회복실·금고 등 시설 내용의 교체 가능 규칙은 바꾸지 않았다.
- 단일 자동 선택 배지는 제거했다. 플레이어가 지도에서 두 노란 대상을 직접 비교하고 클릭해야 한다.
- 안내 카드는 두 대상과 우측 관리 서랍을 피하는 후보 위치를 계산한다.
- 같은 배치 계층 문제로 검출된 DAY 2 가시 복도 안내 카드도 가시 복도 클릭 대상과 우측 서랍을 동시에 피하도록 정리했다.

### 방어 구역 저장과 실제 전투

- 새 게임 기본 roster에 푸딩 `zone_a_front`, 곱 `zone_a_front`, 핀 `zone_a_rear`를 명시했다.
- 몬스터 방을 바꿀 때 기존 zone·slot 값을 먼저 지우고 현재 제품 topology에서 방어 구역과 slot을 다시 계산한다.
- 전열 선택은 곱의 `defense_zone_id`를 `zone_a_front`, 후열 선택은 `zone_a_rear`로 저장한다.
- 전투 생성은 더 이상 roster의 과거 room만 사용하지 않는다. 전투 시작 때 확정한 `monster_placements`의 방어 구역 anchor room을 우선 사용한다.
- 따라서 후열을 고른 곱은 실제 전투에서 `lane_a_rear`에 생성된다.

### 결산 인과

- DAY 1 결산 대표 몬스터를 푸딩에서 곱으로 바꿨다.
- 결산 위치명은 교체 가능한 시설명이 아니라 `전열` 또는 `후열`로 표시한다.
- 예시:
  - `전방 봉쇄 · 곱 → 전열 · 사수 · ...`
  - `후방 화력 · 곱 → 후열 · 사수 · ...`
- 피해 흡수·공격·마무리·시설 지원은 계속 실제 전투 측정값을 사용한다.

## 4. 저장 호환

- 기존 튜토리얼 저장은 완료 단계 ID 목록으로 복원되므로 legacy step ID를 유지했다.
- focus와 문구만 바꿔 기존 `current_index`·`completed` 상태를 그대로 읽을 수 있다.
- 기존 roster에 zone 필드가 없어도 제품 배치 adapter가 room에서 zone을 다시 계산한다.
- 새 배치 시에는 zone·slot을 명시적으로 동기화한다.

## 5. 직접 영향 검사

| 검사 | 결과 | 범위 |
|---|---|---|
| Godot 4.5.2 editor parse | PASS | 변경 스크립트 구문·클래스 등록 |
| JSON parse·DAY 1 focus 계약 | PASS | legacy ID 유지, 곱·두 위치 focus |
| `TutorialFlowSmokeTest.tscn` | PASS | 푸딩·핀 고정, 곱 선택, 전열/후열 저장, 후열 실제 스폰, DAY 2 안내 비가림 |
| `V122CombatResultUIContractTest.tscn` | PASS | 곱 선택과 실제 기여 결산 |
| `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | 실제 결과 화면 인과 문구 |
| 관련 파일 `git diff --check` | PASS | 공백 오류 없음 |

검사 환경에서 Windows root certificate store 읽기 경고와 사용자 AppData 관찰 보고서 쓰기 경고가 출력됐지만 테스트 결과에는 영향을 주지 않았다. `V122ResultUISimplificationTest`의 기존 ObjectDB/resource leak 종료 경고도 남아 있다.

전체 회귀, 실제 사용자 플레이, Windows/Web 빌드, 커밋, 푸시는 수행하지 않았다.

## 6. 다음 세션 시작점

1. `docs/handoff/CURRENT.md`와 이 문서를 먼저 읽는다.
2. DAY 1 선택 내용은 확정 완료 상태다. 푸딩 선택 방식으로 되돌리거나 다시 질문하지 않는다.
3. 다음 직접 작업은 1920 full-canvas와 1366/1280 compact에서 곱 카드, 두 노란 지도 대상, 안내 카드 비가림을 렌더로 확인하는 것이다.
4. 그 다음 전열·후열 각 1회 최소 플레이 비교로 실제 교전 위치와 결산 문구를 확인한다.
5. 두 선택의 체감 차이가 약할 때만 기존 경로·적 도착 시점·배치 anchor를 조정한다. 튜토리얼 전용 숨은 능력치 보너스는 추가하지 않는다.
6. 재미 최소 게이트를 통과한 뒤 보류 중인 시각 개편 순서로 돌아간다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
