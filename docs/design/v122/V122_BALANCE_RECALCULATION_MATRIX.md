# v1.2.2 밸런스 재계산 대응표

## 기준과 처리

| 항목 | 근거 | 처리 | 출력 |
|---|---|---|---|
| DAY 1~5 A/B/C/D | `7e61cc9`, `V20PlacementCausalityTest`, `day_response_scenarios.json` | `ADAPT_TO_121` | 캠페인 초기 상태 fixture |
| P_DPS·P_EHP·P_CONTROL | v20 battle evidence + 제품 성장 | `RECALCULATE` | DAY별 player power |
| P_FACILITY·P_COMMAND | 실제 v122 ledger | `RECALCULATE` | 시설·명령 기여 |
| E_HP·E_DPS | 제품 wave·enemy data | `RECALCULATE` | wave budget |
| E_OBJECTIVE·E_ROLE·E_COMPLEXITY | encounter 목표·역할 event | `RECALCULATE` | 압력·복잡도 |
| v20 level 1·EXP 0·독립 build 10 | v20 test-only session | `REMOVE_TEST_ONLY` | 제품 소비자 없음 |
| 기존 성장·재화·보상 | campaign state | `KEEP_121` | fixture 입력 |

## 동결할 계산식

```text
WaveHPBudget =
  P_DPS_median × TargetCombatSeconds × TargetAttackUptime
  × DifficultyModifier × ComplexityDiscount

WaveDPSBudget =
  (P_EHP_median × TargetMonsterLossRatio
   + ObjectiveHP × TargetObjectiveLossRatio
   + ExpectedHealing) / TargetCombatSeconds

ComplexityDiscount = clamp(
  1.00
  - 0.07 × NewHardPatternCount
  - 0.04 × ExtraSimultaneousObjectiveCount
  - 0.03 × ForcedCommandMomentCount,
  0.72, 1.00)

UnitHP = WaveHPBudget × RoleHPShare / UnitCount
UnitATK = WaveDPSBudget × AttackInterval × RoleDamageShare
          / ExpectedActiveAttackerCount
```

`FacilityValue = AddedDamage + PreventedDamage + EffectiveHealing + DelaySeconds × P_DPS + ObjectiveLossPreventedValue`

`CommandValue = NoCommandOutcome - CommandOutcome`

## 구간

| 구간 | DAY | 입력 | gate |
|---|---:|---|---|
| 기준 | 1~5 | 2.0 evidence를 제품 fixture로 재생 | 시간·피해 오차 ±10%, A/B 승리, C 불이익, D 2개 인과 |
| B1 | 6~10 | DAY 5 성장 결과 | 구간 전 DAY sheet 판정 |
| B2 | 11~15 | B1 fixture | 구간 전 DAY sheet 판정 |
| B3 | 16~20 | B2 fixture | 구간 전 DAY sheet 판정 |
| B4 | 21~25 | B3 fixture | 구간 전 DAY sheet 판정 |
| B5 | 26~30 | B4 fixture | DAY 30·엔딩 정상 |

각 DAY sheet는 DAY, 캠페인 fixture, 성장 수준, roster, 시설, 성 단계, 적 편대·목표, 새 패턴·예고, A/B/C/D, 명령 분류, 목표 시간, 허용 왕좌 피해·몬스터 손실, 실패 원인, seed 3 결과, 판정을 포함한다.

보스는 일반 wave 공식 대신 `PhaseHPBudget`, `PhaseTimeTarget`, `TelegraphWindow`, `InterruptThreshold`, `SummonBudget`, `ObjectivePressureBudget`, `RecoveryWindow`, `FinalPhaseRisk`를 사용한다. 새 판단을 추가한 페이즈는 raw HP·ATK 동시 상승을 제한한다.

명령 분류는 `OPTIONAL_ADVANTAGE`, `RECOMMENDED`, `REQUIRED_FOR_ONE_RESPONSE`, `REQUIRED_FOR_BOSS_INTERRUPT` 중 하나다.
