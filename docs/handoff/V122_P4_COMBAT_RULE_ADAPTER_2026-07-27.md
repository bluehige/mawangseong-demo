# v1.2.2 P4 전투 규칙 adapter

## 1. 메타데이터

- 작성일: 2026-07-27
- 작업 브랜치: `codex/v122-combat-rule-adapter`
- 기준 브랜치 및 SHA: `codex/v122-spatial-placement-adapter@8d0844a06d6e4f428207a749baca1b546e8473a2`
- 기능 커밋 SHA: `4a69bc44d21687660c76e9af0ac70f6183ce7b2c`
- 원격 푸시: 미실행

## 2. 완료한 작업

- 제품 명령 `rally`, `focus`, `activate_facility`, `emergency_fallback`에 비용, 대상, 지속시간, cooldown, AI 우선권, 이동 중 공격 정책, 실제 강조 anchor, ledger와 결과 기여를 정의했다.
- 각 명령은 기존 제품 global·room directive에 적용 가능한 patch를 반환한다.
- 시설 효과는 P3 제품 object anchor와 실제 범위에서만 적용되고 무력화 timer가 남으면 기능이 0이다.
- 기존 몬스터 스킬과 보스·특수 행동을 배치 역할보다 앞에 유지하는 AI 우선순위를 구현했다.
- 공병·도둑 telegraph가 실제 barracks·watch post·recovery와 treasure를 목표로 삼는다.
- 돌파를 entrance object damage, interrupt, progress, complete event, next route, 시각·음향 feedback 상태로 구현했다.
- event ledger가 명령·시설·도난·왕좌 피해·돌파 기여를 결과 metric으로 요약한다.
- v20 actor·room·저장 ID와 독립 경제는 추가하지 않았다.

## 3. 변경 범위

- 데이터: `data/v122/command_rules.json`
- 코드: `scripts/v122/combat/*`, 제품 room type 정규화를 위한 `V122PlacementSlotAdapter`
- 테스트: `V122CombatRuleAdapterTest`, Quick·Full catalog
- 문서: 전투 이식 대응표, 현재 핸드오프
- 신규 그래픽·오디오: 없음

## 4. 테스트

| 방법 | 결과 |
|---|---|
| P3 spatial 직접 회귀 | PASS |
| P4 DAY 1 제품 fixture 직접 실행 | PASS |
| 명령 비용·대상·duration·cooldown·recharge | PASS |
| 실제 anchor 시설 범위·무력화 기능 0 | PASS |
| 기존 스킬·보스 우선 AI | PASS |
| 공병·도둑 목표·object 돌파·ledger | PASS |
| `RunCoreVerification.ps1 -Mode Quick` | PASS, 75/75 |
| JSON parse·`git diff --check` | PASS |
| repository policy | PASS |
| Full·전체 플레이 | NOT_RUN, RC 이전 정책에 따라 제외 |

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 4a69bc44d21687660c76e9af0ac70f6183ce7b2c
- Review range: 8d0844a06d6e4f428207a749baca1b546e8473a2..4a69bc44d21687660c76e9af0ac70f6183ce7b2c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 5. 다음 작업

1. P5 DAY 1~5 캠페인 초기 상태 fixture와 A/B/C/D parity suite를 만든다.
2. 전투 시간, 도난, 무력화, 후열, 돌파, 명령 효과를 product ledger로 기록한다.
3. DAY 5 승리 뒤 기존 보상·성장·저장·DAY 6 진행을 검증한다.
