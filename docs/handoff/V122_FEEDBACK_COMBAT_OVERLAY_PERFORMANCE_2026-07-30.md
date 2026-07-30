# v1.2.2 사용자 피드백 전투 오버레이 성능 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 작업 시작 SHA: `cee86be8e9c4baed1fb99b706fab15ca2a51692a`
- 구현 상태: 미커밋
- 원격 푸시·빌드 여부: 하지 않음

## 2. 사용자 요청과 완료 조건

- 사용자 피드백: 적은 수의 몬스터만 있는 전투 중에도 갑자기 프레임이 크게 떨어지는 원인을 확인하고 해결한다.
- 추가 지시: 확인된 최우선 방법을 적용하고, 같은 방식으로 발생하는 문제를 이번에 함께 처리한다.
- 완료 조건:
  - 반복 전투 효과가 정적 던전 전체를 다시 그리지 않는다.
  - 같은 전체 redraw 경로인 산성 예고, 명령 대상 표시, 장부 표식, 시설 무력화 카운트다운, 관리 드래그 표시를 함께 분리한다.
  - 함정 프레임 애니메이션도 전체 던전 redraw 없이 재생한다.
  - 정적 레이아웃이 실제로 바뀌는 경로의 redraw는 유지한다.
  - 스크립트 파싱과 직접 영향 회귀 테스트를 통과한다.

## 3. 원인

- 기존 `GameRoot._draw()`는 정적 던전과 전투 중 동적 표식을 같은 CanvasItem에서 그렸다.
- 전투 컨트롤러는 동적 표식이 있는 동안 최대 10fps로 `GameRoot.queue_redraw()`를 호출했다.
- 따라서 산성 예고, 장부 표식, 명령 대상 표시, 시설 카운트다운 같은 작은 변화에도 728개 셀과 방·벽·문·장식 전체가 다시 제출됐다.
- 함정 발동 애니메이션도 프레임마다 같은 전체 redraw를 요청했다.
- 수정 전 headless CPU/submission 진단에서 동적 구간은 p95 `36.694ms`, 최대 `48.190ms`였고 함정 발동 단일 프레임은 약 `32.72ms`였다. 순간적인 20~30fps대 하락과 일치하는 병목이다.

## 4. 구현

### 정적 던전과 동적 표식 분리

- `WorldOverlayLayer`를 별도 `Node2D` CanvasItem으로 추가했다.
- `GameRoot._draw()`는 정적 quarter dungeon만 그린다.
- 튜토리얼 방 포커스, 전투 시설 상태, v1.2.2 명령 대상, 관리·맵 편집 드래그 표식은 `WorldOverlayLayer._draw()`에서 그린다.
- 동적 효과 갱신은 `queue_world_overlay_redraw()`만 호출한다.
- 화면 변경, 레이아웃 변경, 성 진화, 방 선택처럼 정적 그림 자체가 바뀌는 경로에는 기존 전체 redraw를 유지했다.

### 같은 원인의 전투 효과 일괄 처리

- 명령 대상 선택·취소
- 산성 예고·산성 지대
- 정화 찬가·장부 표식·부채·과부하·정화
- 공병 시설 대상
- 시설 무력화 카운트다운
- Update 3 심장 활성화·억제·부채 표식
- 튜토리얼 고블린 전열·후열 선택 포커스
- 관리·맵 편집 드래그 피드백

### 함정 애니메이션 분리

- 정적 맵에는 함정의 idle 프레임만 남겼다.
- 발동 프레임은 전용 `AnimatedSprite2D`로 생성해 오버레이에서 재생한다.
- 같은 함정이 다시 발동하면 기존 스프라이트를 교체하며 완료 시 자동 해제한다.
- 기존 디버그용 활성 프레임 계약은 유지했다.

### 테스트 호환

- 실제 `GameRoot`에서는 반드시 전용 오버레이를 갱신한다.
- 오래된 테스트 더블처럼 전용 API가 없는 CanvasItem에 한해서만 `queue_redraw()` 대체 경로를 사용한다.

## 5. 변경 파일

| 경로 | 변경 목적 |
|---|---|
| `scripts/game/WorldOverlayLayer.gd` | 동적 월드 표식 전용 CanvasItem |
| `scripts/game/WorldOverlayLayer.gd.uid` | Godot 스크립트 UID |
| `scripts/game/GameRoot.gd` | 정적 던전과 동적 오버레이 draw 경로 분리 |
| `scripts/game/CombatSceneController.gd` | 반복 전투 효과를 오버레이 redraw로 전환 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 함정 발동을 독립 AnimatedSprite2D로 전환 |
| `tools/EngineerPerformanceSmokeTest.gd` | 전체 맵 redraw 0회와 오버레이·함정 분리 회귀 검사 |

`CombatSceneController.gd`에는 이번 성능 수정 전에 진행한 사용자 피드백 수정이 함께 미커밋 상태로 존재한다. 이번 작업은 해당 변경을 되돌리지 않고 그 위에 최소 범위로 적용했다.

## 6. 성능 결과

동일한 임시 headless CPU/submission 진단 기준이다.

| 구간 | 수정 전 | 수정 후 | 전체 맵 redraw |
|---|---:|---:|---:|
| 동적 전투 표식 p95 | 36.694ms | 16.132ms | 0회 |
| 동적 전투 표식 최대 | 48.190ms | 17.559ms | 0회 |
| 함정 발동 대표 프레임 | 약 32.72ms | 최대 17.783ms 구간 안 | 0회 |
| idle 전투 p95 | 해당 없음 | 15.121ms | 0회 |

- 동적 표식 20회 갱신 동안 정적 맵 redraw는 0회였다.
- 함정 발동은 독립 `AnimatedSprite2D` 1개를 사용했고 정적 맵 redraw는 0회였다.
- 이 수치는 구조적 병목 제거를 확인하는 headless 계측이다. 실제 Windows GPU의 체감 프레임과 장시간 전투는 새 QA 빌드에서 다시 확인해야 한다.

## 7. 테스트

| 검증 | 결과 |
|---|---|
| Godot 4.5.2 headless editor 스크립트 파싱 | PASS |
| `V122CommandButtonIntegrationTest` | PASS |
| `V122CombatVisualHierarchyTest` | PASS |
| `V122CombatUISimplificationTest` | PASS |
| `V122FacilityZoneCombatConsumerTest` | PASS |
| `V122Day02FeedbackTest` | PASS |
| `V122DefenderConnectorTest` | PASS |
| `V122EnemyLaneRoutingTest` | PASS |
| `EngineerPerformanceSmokeTest` | PASS, 20 assertions |

- 파싱 중 `%APPDATA%`의 Godot editor settings 저장 제한과 Windows root certificate 읽기 오류는 sandbox 환경 메시지이며 스크립트 파싱과 테스트 종료에는 영향을 주지 않았다.
- `QuarterModuleSmokeTest`는 함정 발동 검사를 포함한 이번 변경 관련 항목을 통과했지만 전체 결과는 기존 한 항목 때문에 FAIL이다. 현재 HEAD 자체가 Stage 01 왕좌 텍스처를 투영 안전 예외로 허용하는 반면 테스트는 이를 거부해야 한다고 기대한다. 이번 성능 변경과 무관한 기존 계약 불일치이므로 범위를 넓혀 수정하지 않았다.

## 8. 전체 redraw 재감사

- `GameRoot`에 남은 전체 redraw는 레이아웃 적용, 길 후보 변경, 맵 편집, 성 진화, 디버그 표시, 화면 변경, 방 선택 경로다.
- `QuarterDungeonRenderer`에 남은 전체 redraw는 layout cache 무효화 뒤 정적 맵을 다시 그리는 `refresh_layout()`뿐이다.
- `CombatSceneController`의 실제 게임 경로에는 전체 맵 redraw 직접 호출이 남아 있지 않다.

## 9. 검수 정책 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A_UNCOMMITTED`
- Review range: `cee86be8e9c4baed1fb99b706fab15ca2a51692a..WORKTREE`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 10. 다음 작업

1. 사용자 피드백 3건과 이번 성능 수정을 한 묶음으로 최종 diff·테스트 확인한 뒤 커밋한다.
2. 새 커밋에서 Windows QA 빌드를 다시 만든다. 기존 `tmp/v122_windows_qa_c0c5871/` 빌드는 이번 수정 이전 버전이므로 재검수에 사용하지 않는다.
3. 새 빌드에서 DAY 1~5를 우선 재검수하면서 샛길 선택, 금고 내부 적 공격, 왕좌 공격 모션, 산성·장부·시설·함정이 겹치는 전투의 프레임을 확인한다.
4. DAY 1~5가 완벽하다는 사용자 확인 뒤 같은 기준으로 DAY 6~30을 진행한다.

## 11. 아직 하지 않은 작업

- 이번 미커밋 변경의 커밋·푸시
- 이번 변경이 포함된 Windows QA 빌드
- 실제 Windows GPU 장시간 전투 프레임 계측
- 전체 회귀·전체 DAY 1~30 플레이 검수
- 기존 `QuarterModuleSmokeTest` Stage 01 왕좌 투영 안전 기대값 불일치 정리
