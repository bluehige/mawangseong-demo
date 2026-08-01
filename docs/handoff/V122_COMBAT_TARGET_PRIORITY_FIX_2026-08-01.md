# 제품 1.2.2 전투 타깃 우선순위 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-01
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/codex/v122-ui-simplification` / `481be99bad796ef487ed39baa8f7b4ae658ea89e`
- 마지막 커밋 SHA: `UNCOMMITTED_WORKTREE`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: DAY 3 도둑 침입 때 집중 명령과 도둑 우선 공격 특성이 실제 공격에 반영되지 않는 문제를 수정하고, 같은 구조를 쓰는 유사 전투 문제를 선제 점검·수정한다.
- 완료 조건: 명시된 우선 타깃을 이동·기본 공격·자동 스킬이 일관되게 따르고, 타깃이 사거리 밖일 때 가까운 다른 적을 때리느라 추격을 중단하지 않는다.
- 범위에서 제외한 사항: 전체 회귀 검증, 전체 DAY 플레이, 빌드·배포, 전투 밸런스 수치 변경.

## 3. 완료한 작업

- 구현: 집중 명령, 도둑·부상자·금고 침입자 사냥 특성, 코코의 위험 추적, 현상금 추적이 공통 전투 타깃 결정 경로를 사용하도록 정리했다.
- 구현: 우선 타깃이 사거리 밖이면 가까운 일반 적으로 바꾸지 않고 추격 경로를 유지하도록 수정했다.
- 구현: 집중 명령이 기본 공격뿐 아니라 자동·수동 스킬의 타깃 선택, 미리보기, 피해 배율에도 적용되도록 수정했다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 수치 변경 없음. 기존 집중 피해 배율과 특성 조건을 그대로 사용했다.
- UI/UX: 레이아웃 변경 없음. 스킬 미리보기가 실제 우선 타깃과 일치하도록 보완했다.
- 저장 및 호환성: 저장 형식 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/CombatSceneController.gd` | 공통 우선 타깃 결정, 추격 유지, 집중 스킬 피해 적용 | 완료 |
| `tools/tests/V122CommandButtonIntegrationTest.gd` | 집중 이동·기본 공격·자동 스킬·피해 배율 회귀 검증 | 완료 |
| `tools/tests/V122DefenderConnectorTest.gd` | 도둑·부상자·금고 침입자 특성의 경쟁 타깃 검증 | 완료 |
| `tools/tests/KokoPhase13Test.gd` | 코코의 원거리 위험 타깃 추격 유지 검증 | 완료 |
| `tools/tests/BountyTrackerPhase14Test.gd` | 현상금 타깃 추격 유지 검증 | 완료 |
| `docs/handoff/V122_COMBAT_TARGET_PRIORITY_FIX_2026-08-01.md` | 세션 변경·검수 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 자산 변경 없음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122CommandButtonIntegrationTest.tscn`, `V122DefenderConnectorTest.tscn`, `KokoPhase13Test.tscn`, `BountyTrackerPhase14Test.tscn` headless 실행 | PASS | `tools/tests/` 해당 테스트 |
| 2 | `V122CombatRuleAdapterTest.tscn`, `BebePhase11Test.tscn`, `ToktokPhase15Test.tscn`, `ReliquaryGuardPhase17ATest.tscn` headless 실행 | PASS | `tools/tests/` 해당 테스트 |
| 3 | `V122DualFrontDay01To05WaveTest.tscn`, `V122Day01To05ParityTest.tscn` headless 실행 | PASS | `tools/tests/` 해당 테스트 |
| 4 | `V122CombatUISimplificationTest.tscn` headless 실행, 1280×720 포함 3개 가로 해상도·85 assertions | PASS | `tools/tests/V122CombatUISimplificationTest.gd` |
| 5 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 없음 |
| 6 | DAY 3 실제 수동 플레이 | NOT_REQUESTED | 자동 경쟁 타깃 회귀 테스트로 대체하지 않고 미실행으로 기록 |

테스트 우선 방식으로 수정 전 실패를 재현했다. 집중 명령은 가까운 다른 적을 공격하며 이동 경로를 지웠고, 도둑 사냥꾼·코코·현상금 추적도 원거리 우선 타깃 대신 가까운 일반 적을 공격했다. 수정 후 같은 조건이 모두 통과했다.

- Related tests: 관련 전투 테스트 10종과 전투 UI 계약 테스트 1종이 모두 통과했다.
- UI check: 레이아웃 변경은 없으며 1280×720을 포함한 전투 UI 계약 테스트 85개 검사가 통과했다. 실제 화면 수동 확인은 실행하지 않았다.
- Unresolved issues: 자동 회귀에서 확인된 타깃 우선순위 문제는 없으나 DAY 3 실제 플레이 체감은 사용자가 확인해야 한다. 일부 Godot 테스트 종료 시 기존 객체 정리 경고가 나오지만 모든 assertion과 종료 코드는 통과했다.

### 검수 에이전트 반복 기록

- 사용자가 별도 검수 에이전트나 전체 검수를 요청하지 않아 실행하지 않았다.
- 남은 P1/P2 지적: 해당 없음
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀와 실제 플레이는 이번 요청의 필수 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 기능 변경 없음. 핸드오프 문서만 추가·갱신했다.

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `UNCOMMITTED_WORKTREE`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동 검증에서는 해소됐다. 실제 DAY 3에서 다수 적이 겹치는 순간의 조작 체감은 수동 확인이 남아 있다.
- 밸런스 관찰 항목: 집중 명령 스킬 피해가 기존 명세대로 적용되므로 실제 플레이에서 피해 체감만 관찰한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 일부 기존 Godot 테스트가 종료 시 객체·리소스 정리 경고를 출력한다. 테스트 실패는 아니다.

## 8. 다음 작업 순서

1. 사용자가 DAY 3에서 가까운 일반 탐험가와 도둑이 함께 있을 때 집중 명령과 도둑 사냥꾼 특성을 실제 플레이로 확인한다.
2. 문제가 남으면 해당 전투 상황만 최소 재현 테스트로 추가하고 타깃 결정 경로를 수정한다.
3. 사용자 최종 검수 요청이 있을 때만 전체 회귀와 출시 후보 빌드를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`에서 코드 1개, 테스트 4개, 핸드오프 2개 변경을 커밋할 예정이다.
- 미커밋 파일: 이 문서에 기재한 7개 파일.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 새 산출물 없음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트는 실행하지 않음
- [x] 검수 대상 상태와 작업 ID 기록
- [x] 그래픽·오디오 자산 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋 준비
- [x] 원격 미푸시 상태 기록
