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

## P9 동결 계수와 DAY 1~5 보정 결과

`7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`의 x1·60 Hz 실제 A/B ledger를 기준으로 제품 `ModuleGraph`·roster·성장 상태에서 계산한 P_DPS를 보정했다. spawn 겹침은 DAY별 `TargetAttackUptime` 측정값으로 입력하고 복잡도 계수는 검증 뒤 다음 값으로 동결한다.

| 계수 | 동결값 |
|---|---:|
| `NewHardPatternCount` | `0.07` |
| `ExtraSimultaneousObjectiveCount` | `0.04` |
| `ForcedCommandMomentCount` | `0.03` |
| `ComplexityDiscount` 하한·상한 | `0.72`·`1.00` |
| 시간·E_HP 피해 예산 최대 상대 오차 | `0.10` |

| DAY | 기준 E_HP | 목표 초 | `TargetAttackUptime` | 복잡도 할인 | A/B 최대 시간 오차 | E_HP 피해 예산 오차 |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 834 | 49.225 | 0.355169 | 1.00 | 5.9030% | 0.0001% |
| 2 | 497 | 54.815 | 0.219809 | 0.89 | 2.3568% | 0.0000% |
| 3 | 548 | 60.435 | 0.222657 | 0.86 | 1.8045% | 0.0001% |
| 4 | 939 | 64.840 | 0.333412 | 0.86 | 0.8959% | 0.0000% |
| 5 | 837 | 83.170 | 0.230239 | 0.86 | 2.6694% | 0.0001% |

P9 계산 입력과 기준 ledger는 `data/v122/balance_model.json`, 순수 계산식은 `scripts/v122/balance/V122BalanceModel.gd`, 자동 gate는 `tools/tests/V122BalanceModelTest.gd`에 고정한다. `P_EHP`, `P_CONTROL`, `FacilityValue`, `CommandValue`, `WaveDPSBudget`, `UnitHP`, `UnitATK`도 같은 테스트에서 식을 고정했다. P10~P14는 이 계수를 바꾸지 않고 각 DAY의 성장·roster·시설·경로·목표·spawn 겹침을 다시 측정한다.

## P10 B1 DAY 6~10

DAY 5 승리 직후의 정규 캠페인 상태를 입력으로 사용했다. 계산 sheet의 A/B/C/D는 고정 seed `1220601~1220603`과 x3 불변성으로 검증하고, 별도의 실제 제품 전투 대표 경로로 목표 시간·왕좌 피해·몬스터 손실·목표 손실을 대조했다.

| DAY | 실제 E_HP | 목표·실측 초 | 복잡도 할인 | 명령 분류 | 실제 대표 결과 | 판정 |
|---:|---:|---:|---:|---|---|---|
| 6 | 1,638.0 | 28.2 | 0.96 | `OPTIONAL_ADVANTAGE` | 승리·왕좌 0·손실 0·도난 0 | PASS |
| 7 | 2,116.0 | 55.4 | 0.96 | `OPTIONAL_ADVANTAGE` | 방어+감시 승리·왕좌 0·손실 0·도난 0 | PASS |
| 8 | 1,782.0 | 37.467 | 0.96 | `OPTIONAL_ADVANTAGE` | 승리·왕좌 0·손실 1·도난 0 | PASS |
| 9 | 1,869.5 | 58.733 | 0.89 | `RECOMMENDED` | 승리·왕좌 0·손실 1·도난 0 | PASS |
| 10 | 1,954.0 | 38.2 | 0.86 | `REQUIRED_FOR_ONE_RESPONSE` | 승리·왕좌 0·손실 0·도난 0 | PASS |

DAY 7의 전력 지시 기준 배치는 승리하더라도 몬스터 3명이 전투 불능이 되어 sheet 한도를 넘었다. 제품 수치를 낮추지 않고 `DEFENSE`+감시초소 대응을 유효 B로 고정하자 55.4초, 전투 불능 0, 도난 0으로 gate를 통과했다. `SURVIVAL`만 사용하고 보물 경로를 비운 오답은 병력은 보존하지만 도난이 발생해 `objective_uncovered` 인과가 유지된다.

원본 입력과 실제 표본은 `data/v122/balance_day06_30.json`, 계산·seed·x3 gate는 `scripts/v122/balance/V122BalanceSheetAudit.gd`, 제품 물리 표본은 `tools/BalanceSimulation.gd`에 기록한다.

## P11 B2 DAY 11~15

B1 DAY 10 승리 뒤 Lv.2~3 core roster와 1차 승급 1명, Stage 02 심사 자원을 순차 fixture로 사용했다. 세 승급 선택지가 모두 기존 제품 시뮬레이션에 존재하는 상태에서 슬라임 승급을 대표 물리 표본으로 대조했다.

| DAY | 실제 E_HP | 목표·실측 초 | 복잡도 할인 | 명령 분류 | 실제 대표 결과 | 판정 |
|---:|---:|---:|---:|---|---|---|
| 11 | 2,289.75 | 61.4 | 0.96 | `RECOMMENDED` | 승리·왕좌 0·손실 2·도난 0 | PASS |
| 12 | 2,298.25 | 62.6 | 0.89 | `RECOMMENDED` | 승리·왕좌 0·손실 1·도난 0 | PASS |
| 13 | 2,053.75 | 72.933 | 0.89 | `RECOMMENDED` | 승리·왕좌 0·손실 1·도난 0 | PASS |
| 14 | 1,964.25 | 69.933 | 0.96 | `OPTIONAL_ADVANTAGE` | 승리·왕좌 0·손실 1·도난 0 | PASS |
| 15 | 1,778.70 | 71.733 | 0.79 | `REQUIRED_FOR_ONE_RESPONSE` | Stage 02 승리·왕좌 0·손실 1 | PASS |

DAY 15는 일반 웨이브 합계만으로 보지 않는다. 선발대 1,375.5 HP/48초와 셀렌 403.2 HP/23.733초로 분리하고 예고 3초, 집중 중단 기준 120, 소환 예산 0, 목표 압력 220, 회복 창 6초, 최종 위험 0.18을 별도 동결했다. 두 페이즈 HP 합계와 시간 합계도 실제 제품 웨이브·목표 시간 대비 ±10% gate에 포함된다.

## P12 B3 DAY 16~20

B2 승리 뒤 Stage 02와 1차 승급을 실제 fixture에 적용했다. 초기 DAY 16 표본이 원정 미확정 때문에 전투를 시작하지 못한 사실과, 단순 1차 승급 fixture가 Stage 01을 남기던 문제를 발견했다. 원정 선택을 확정하고 Stage 02 7-room 상태를 구성하는 순차 fixture로 DAY 16~20 대표 경로를 다시 측정했다.

| DAY | 실제 E_HP | 목표·실측 초 | 복잡도 할인 | 성 단계 | 실제 대표 결과 | 판정 |
|---:|---:|---:|---:|---|---|---|
| 16 | 1,744.5 | 57.4 | 0.89 | Stage 02 | 정찰 경로 승리·왕좌 0·손실 1 | PASS |
| 17 | 1,321.0 | 41.6 | 0.89 | Stage 02 | 승리·왕좌 0·손실 0·도난 0 | PASS |
| 18 | 1,496.5 | 44.4 | 0.89 | Stage 02 | 가짜 장부 승리·왕좌 0·손실 0 | PASS |
| 19 | 1,491.5 | 55.6 | 0.96 | Stage 02 | 선택 계승 승리·왕좌 0·손실 1 | PASS |
| 20 | 1,704.1 | 82.0 | 0.79 | Stage 02→03 | 승리·공병 2/시설 2 방어·손실 1 | PASS |

DAY 20은 선발대·공병 1,454.5 HP/56초와 로만 249.6 HP/26초로 분리했다. 예고 3.5초, 집중 기준 100, 공병 소환 예산 378, 목표 압력 240, 회복 창 6초, 최종 위험 0.20을 별도 gate로 고정했다. 승리 뒤 Stage 03 9-room/왕좌 2,100 상태까지 실제 결과에서 확인했다.
