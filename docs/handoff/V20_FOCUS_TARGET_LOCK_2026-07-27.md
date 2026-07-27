# 제품 2.0 집중 명령 대상 고정 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-room-route`
- 작업 기준 SHA: `61ec34bd9a872d38783ca7131230615483b06014`
- 원격 푸시, PR, 태그: 수행하지 않음

## 2. 목표와 완료 조건

- 요청: 집중 명령으로 적을 선택하면 최대 10초 동안 해당 적을 실제 집중 공격한다.
- 완료 조건:
  - 집중 지속시간이 전투 시간 기준 최대 10초다.
  - 선택 대상이 교전 가능한 동안 다른 가까운 적보다 우선한다.
  - 사거리 밖이면 다른 적으로 임의 전환하지 않고 집중 대상을 추격한다.
  - 대상 사망 또는 해당 몬스터의 교전 가능 구역 이탈 시 기존 AI로 복귀한다.
- 제외: 공격력, 적 HP, 명령 비용, 재사용 대기시간, 전투 배속 수치 변경.

## 3. 구현

- `v20_focus` 설명과 지속시간을 5초에서 최대 10초로 변경했다.
- 실제 기본 공격 대상 선정 앞단에 집중 대상 조회를 연결했다.
- 집중 대상이 사거리 밖일 때 가까운 다른 적을 공격하던 동작을 막고 추격을 유지한다.
- 역할 이동에 저장된 실제 집중 대상 ID를 사용하고, 교전 가능한 집중 대상을 구역 간 추격하도록 연결했다.
- 사망했거나 교전 불가능한 대상은 강제 고정하지 않는다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `data/v20/commands.json` | 집중 설명·지속시간 10초 |
| `scripts/combat/TargetingService.gd` | 집중 대상 식별 |
| `scripts/game/CombatSceneController.gd` | 이동·기본 공격 대상 고정 |
| `tools/tests/V20TacticalCommandsTest.gd` | 10초 지속·근접 적보다 우선·사망 해제 회귀 테스트 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 |

## 5. 검증

| 검증 | 결과 |
|---|---|
| `V20TacticalCommandsTest.tscn` | PASS, 32 assertions |
| `V20FinalUIFlowSmokeTest.tscn` | PASS, 25 assertions |
| `git diff --check` | PASS |
| 전체 평가·전체 플레이 검증 | NOT_REQUESTED |

- `V20FinalUIFlowSmokeTest` 종료 시 기존 ObjectDB/resource 잔여 경고가 출력됐지만 테스트 판정은 PASS였다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: WORKTREE (`61ec34bd9a872d38783ca7131230615483b06014` 기준)
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 로컬 빌드

- 폴더: `로컬테스트빌드/v2.0-focus-lock-10s-20260727/`
- 실행 파일: `MawangCastle_v2.0_focus_10s.exe`
- 데이터 파일: `MawangCastle_v2.0_focus_10s.pck`
- 웹 업로드·외부 배포: 수행하지 않음

## 7. 다음 확인

1. 로컬 빌드에서 집중 명령을 누른 뒤 교전 중인 적을 선택한다.
2. 가까운 다른 적이 있어도 선택 대상 공격을 유지하는지 확인한다.
3. 대상 사망 또는 최대 10초 경과 뒤 정상 AI로 복귀하는지 확인한다.
