# v1.2.2 P9 DAY 1~5 계산 모델 보정

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-balance-model`
- 기준 브랜치 및 SHA: `codex/v122-save-progression@3c9a9339c3251c3820d8de5b385d516bead9d656`
- 기능 커밋 SHA: `2cb02232f3359fa0c03bf702310e34ff57fa5226`
- 원격 푸시: 미실행

## 2. 완료한 작업

- 2.0 기준 `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`의 A/B 실제 물리 ledger 10개를 재생해 전투 시간·몬스터 피해·E_HP 기준을 회수했다.
- 제품 `ModuleGraph`, DAY별 성장 roster와 A/B 배치에서 P_DPS를 계산하고 DAY별 spawn 겹침을 `TargetAttackUptime`으로 고정했다.
- `WaveHPBudget`, `WaveDPSBudget`, 복잡도 할인, `UnitHP`, `UnitATK`, `P_EHP`, `P_CONTROL`, `FacilityValue`, `CommandValue`를 순수 계산 모델로 고정했다.
- 복잡도 계수 `0.07/0.04/0.03`, 하한·상한 `0.72/1.00`, 최대 상대 오차 `0.10`을 데이터와 테스트에 동결했다.
- DAY 1~5 A/B 최대 시간 오차는 5.9030%, E_HP 피해 예산 오차는 최대 0.0001%로 ±10% gate를 통과했다.
- P10~P14가 계수를 재조정하지 않고 각 DAY의 성장·시설·경로·목표·spawn 겹침만 다시 측정하도록 입력 경계를 분리했다.

## 3. 테스트

| 방법 | 결과 |
|---|---|
| `V122BalanceModelTest` 계산식·DAY 1~5 보정 | PASS |
| 기존 `V122Day01To05ParityTest` | PASS |
| 2.0 실제 A/B ledger 10전 읽기 전용 재생 | PASS, 기준 핸드오프와 일치 |
| DAY 1~5 최대 시간 오차 | PASS, 5.9030% |
| DAY 1~5 최대 E_HP 피해 예산 오차 | PASS, 0.0001% |
| Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 2cb02232f3359fa0c03bf702310e34ff57fa5226
- Review range: 3c9a9339c3251c3820d8de5b385d516bead9d656..2cb02232f3359fa0c03bf702310e34ff57fa5226
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 4. 다음 작업

1. P10에서 DAY 6~10의 성장·roster·시설·성 단계·wave·목표를 sheet로 만들고 동결 모델로 구간 gate를 계산한다.
2. 각 DAY는 유효 대응 A/B, 오답 C, 한 slot 인과 D, seed 3과 x3 표본을 포함한다.
