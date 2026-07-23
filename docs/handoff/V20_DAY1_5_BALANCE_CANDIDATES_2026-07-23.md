# 제품 2.0 DAY 1~5 PR 4 밸런스 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-23
- 목표: DAY 1~5의 기존 적 구성과 실제 전투 규칙으로 PR 5 공식 수용에 넣을 밸런스 후보를 만든다.
- 작업 브랜치: `codex/v20-validation-day01-05-balance`
- 기준 브랜치: `release/v2.0@9607d26f883769f51c2a0bd977503e788f7d2532`
- 기능 Reviewed SHA: `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`
- Draft PR: `https://github.com/bluehige/mawangseong-demo/pull/71`
- 선행 수치 계약 PR: #70, merge SHA `9607d26f883769f51c2a0bd977503e788f7d2532`
- 선행 배치 인과 PR: #69, merge SHA `9c299c4d19eb83a0483638c99b13fcc9e94a3031`
- 새 태그·Release·저장 schema·공개 빌드: 변경 0건

## 2. 이번 PR의 완료 범위

- `data/v20/encounters.json`의 기존 적만 사용해 DAY별 자연 spawn 시각·수·HP·ATK 후보를 적용했다.
- DAY 1~5 A/B/C/D 20개 fixture를 만들었다. D는 같은 DAY A에서 계약이 지정한 몬스터 `monster_slot_id` 한 건만 바뀐다.
- acceptance seed와 RNG state를 `WaveManager.setup_v20()`까지 전달했다.
- facility·monster의 실제 world position과 고정 경로 구간을 이동·교전·표적·피해·회복·무력화·도난·후열 압박·돌파·결과에 연결했다.
- DAY 2 도난, DAY 3 무력화 중 대체 시설 effect 부재, DAY 4 후열 압박 6.0초 이상, DAY 5 돌파·2차 누수·도난을 실제 `RESULT.win=false`와 실패 코드에 연결했다.
- 실제 GameRoot, 실제 placement API, x1, 60 Hz, 최대 7200 physics frame으로 20개 후보를 실행했다. direct HP 변경, teleport, spawn·damage 직접 호출, 직접 result 호출은 사용하지 않았다.

다음 항목은 하지 않았다.

- 신규 스토리·몬스터·적·시설·DAY 6 이후 콘텐츠
- 모바일 전면 개편·신규 최종 그래픽·그래픽 또는 오디오 자산 생성
- `release/v2.0`의 `main`·1.2.1 기반 브랜치 병합 또는 전체 이식
- `v1.2.1` tag·Release·기존 저장·PC/Web 공개본 변경
- PR 5의 공식 70전·숙련 QA 24전·초회 사용자 10명 수용

## 3. 제품 전투 규칙

### 3.1 적 구성

| DAY | 자연 spawn 게임 시각 | 실제 후보 HP / ATK |
|---:|---|---|
| 1 | 탐험가 3.0, 11.0, 19.0, 27.0, 35.0, 43.0초 | 각 139 / 14 |
| 2 | 도둑 4.0초; 탐험가 5.0, 19.7, 34.4, 49.1초 | 도둑 81 / 8; 탐험가 104 / 8 |
| 3 | 공병 5.0초; 탐험가 15.0, 28.5, 42.0, 55.5초 | 공병 116 / 4; 탐험가 108 / 14 |
| 4 | 첫 방패병 5.0초; 궁수 9.4초; 후속 방패병 23.3, 41.6, 59.9초 | 첫 방패병 339 / 6; 후속 방패병 169 / 6; 궁수 93 / 14 |
| 5 | 수련생 용사 6.0초; 탐험가 45.0, 53.0, 61.0, 69.0초; 도둑 77.0초 | 용사 345 / 20; 탐험가 104 / 6; 도둑 76 / 5 |

### 3.2 배치·명령이 결과를 바꾸는 연결

- 시설 passive·active의 감속·피해·회복은 actor world position이 설치 zone `combat_bounds` 안일 때만 적용한다.
- 감시 초소 active reveal만 시설 anchor에서 420px 직선거리를 사용한다. 노출된 인접 구간 궁수는 보호를 무시하고, `imp_artillery`는 사거리 안에서 방패병보다 궁수를 먼저 공격한다.
- 보호받는 후열은 살아 있는 방패병과 같은 고정 경로 구간 또는 바로 인접한 구간에 있을 때 `protected=true`다.
- 도둑은 미끼가 없으면 Z3에서 약탈하며, 미끼가 있으면 설치 zone으로 실제 goal과 이동 경로를 바꾼다.
- 공병은 선택한 실제 시설을 7초 무력화한다. 그 interval의 passive·active effect는 0이고 종료 뒤 남은 charge와 effect가 복구된다.
- `비상 후퇴`를 받은 몬스터는 목표 zone 문자열만 바뀐 상태에서 멈추지 않고 실제 Z4 bounds 안까지 이동한다. active 5초 종료 뒤에도 수련생 용사가 살아 있으면 목표를 유지하고, 용사 사망 뒤 각 home slot으로 복귀한다.
- 수련생 용사의 breach dash는 3초 동안 실제 다음 방어 구간을 향해 이동하며, 직접 보정 피해를 추가하지 않는다.

## 4. 기능 Reviewed SHA 후보 실행 결과

아래 결과는 `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`과 같은 기능 내용에서 재실행한 PR 4 후보 gate다. 공식 `PHYSICAL_COMBAT_PASS`, 진행 단순성 PASS, 재미 PASS 또는 밸런스 PASS가 아니다.

| DAY | scenario | 결과 | 전투 초 | 첫 교전 | 왕좌 피해 | 도난 | 무력화 초 | 후열 압박 초 | 2차 누수 | 종료 몬스터 HP | 실제 실패·기여 |
|---:|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1 | A | 승 | 51.88 | Z1 | 0 | 0 | 0 | 0 | 0 | 130 | 바리케이드 effect 6건, 몬스터 피해 737 |
| 1 | B | 승 | 46.57 | Z2 | 0 | 0 | 0 | 0 | 0 | 358 | 병영 실제 기여, 몬스터 피해 750 |
| 1 | C | 패 | 62.28 | Z3 | 1500 | 0 | 0 | 0 | 0 | 0 | 왕좌 파괴 |
| 1 | D | 승 | 47.77 | Z2 | 0 | 0 | 0 | 0 | 0 | 334 | A 대비 slime slot 한 건 변경, 이동 fingerprint 변경 |
| 2 | A | 승 | 57.50 | Z1 | 0 | 0 | 0 | 0 | 0 | 179 | 미끼 유인과 고블린→도둑 피해 발생 |
| 2 | B | 승 | 52.12 | Z2 | 0 | 0 | 0 | 0 | 0 | 428 | 탐험가 Z2·도둑 Z3 분리 교전 |
| 2 | C | 패 | 51.82 | Z1 | 0 | 100 | 0 | 0 | 0 | 362 | `protect_treasure` 실패 |
| 2 | D | 패 | 51.82 | Z1 | 0 | 100 | 0 | 0 | 0 | 362 | 같은 실패, A 대비 goblin slot 한 건 변경 |
| 3 | A | 승 | 58.60 | Z2 | 0 | 0 | 0 | 0 | 0 | 478 | 공병 spawn 뒤 0.033초에 집중, 무력화 0초 |
| 3 | B | 승 | 62.27 | Z1 | 0 | 0 | 7.00 | 0 | 0 | 183 | 무력화 중 다른 시설 effect 발생 |
| 3 | C | 패 | 58.22 | Z1 | 0 | 0 | 7.00 | 0 | 0 | 312 | `keep_one_facility_active` 실패 |
| 3 | D | 패 | 64.32 | Z3 | 0 | 0 | 7.00 | 0 | 0 | 271 | 같은 실패, A 대비 imp slot 한 건 변경 |
| 4 | A | 승 | 65.45 | Z2 | 0 | 0 | 0 | 3.57 | 0 | 373 | reveal 6.00초, reveal 중 임프→궁수 피해 88 |
| 4 | B | 승 | 64.23 | Z1 | 0 | 0 | 0 | 1.37 | 0 | 399 | 집중 보호 무시 1.33초, 궁수 선격퇴 |
| 4 | C | 패 | 65.20 | Z1 | 0 | 0 | 0 | 6.83 | 0 | 371 | `break_rear_pressure` 실패 |
| 4 | D | 패 | 98.85 | Z3 | 1500 | 0 | 0 | 44.93 | 0 | 0 | 같은 실패, 왕좌 파괴, A 대비 imp slot 한 건 변경 |
| 5 | A | 승 | 83.17 | Z1 | 0 | 0 | 0 | 0 | 0 | 156 | 대시 예고 뒤 0.033초 후퇴, 실제 회복 20 |
| 5 | B | 승 | 83.17 | Z2 | 0 | 0 | 0 | 0 | 0 | 367 | 명령 0회, 탐험가 Z2·도둑 Z3 분리 교전 |
| 5 | C | 패 | 89.98 | Z1 | 0 | 100 | 0 | 0 | 0 | 390 | `stop_reinforcement_leaks` 실패 |
| 5 | D | 패 | 63.13 | Z1 | 1500 | 0 | 0 | 0 | 1 | 0 | 같은 실패, 왕좌 파괴, A 대비 imp slot 한 건 변경 |

DAY별 A/B 전투 시간은 각각 45~65, 52~78, 58~86, 62~94, 70~106초 후보 범위 안이다. C는 DAY별 실제 불이익과 `RESULT.win=false`를 만들었고, A/D는 slot 한 건 구조 차이와 실제 이동·결과 threshold를 함께 바꿨다.

## 5. 변경 파일

| 경로 | 구체적 변경 |
|---|---|
| `data/v20/encounters.json` | 위 spawn 수·시각·HP/ATK scale·flat HP, DAY 4 group offset, DAY 5 45초 증원 |
| `scripts/combat/WaveManager.gd` | acceptance seed·RNG state를 받는 `setup_v20()` adapter |
| `scripts/game/CombatSceneController.gd` | 실제 spawn 좌표, 구간 교전, 보호·reveal·후열 우선 공격, 후퇴 이동, 용사 dash, 공병 목표, 도둑 lure, 필수 목표 결과 연결 |
| `scripts/v20/encounters/V20EncounterService.gd` | group offset·flat stat schedule, 필수 목표 실패식, WaveManager entry 전달 |
| `tools/tests/fixtures/v20/day_response_scenarios.json` | DAY별 A/B/C/D의 시설·몬스터 slot·event 명령·기대 지표 |
| `tools/tests/V20PlacementCausalityTest.gd` | 실제 GameRoot x1 60 Hz 20전 runner와 후보 판정 |
| `tools/tests/V20DayOneToFiveEncountersTest.gd` | 정확한 schedule·stat·fixture·필수 목표 198 assertions |
| `tools/tests/V20DifficultyEconomyTest.gd` | DAY 5 spawn 6개 난이도·adapter 회귀 |
| `tools/tests/core_verification_suite.json` | 배치 인과 검사의 후보 20전 명칭과 900초 process timeout |

## 6. 테스트 및 검수

| 순서 | 명령 또는 검사 | 결과 | 판정 범위 |
|---:|---|---|---|
| 1 | UTF-8 `encounters.json`, fixture JSON parse | PASS | JSON 문법 |
| 2 | Godot headless import | PASS | GDScript·resource import |
| 3 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 198/198 | schedule·stat·fixture·실패식 |
| 4 | `V20FacilityReworkTest.tscn` | PASS, 33/33 | 시설 bounds·effect |
| 5 | `V20MonsterRoleGrowthTest.tscn` | PASS, 46/46 | 역할 표적·보호 targetable |
| 6 | `V20TacticalCommandsTest.tscn` | PASS, 27/27 | 명령 비용·대상·지속 |
| 7 | `V20DifficultyEconomyTest.tscn` | PASS, 29/29 | DAY 5 spawn 6개·난이도 adapter |
| 8 | `V20PlacementCausalityTest.tscn` 전체 | PASS, 234/234 | 선행 인과와 DAY 1~5 후보 실제 물리 20전 |
| 9 | 위 6개를 `-SkipCheckId`로 제외한 `RunCoreVerification.ps1 -Mode Quick` | PASS, 79/79 | import·DemoSmoke·공간·흐름·저장·기존 회귀 |
| 10 | `git diff --check` | PASS | whitespace 오류 0건 |

자동 test, 후보 runner 출력, 문자열 태그와 예상 시간은 세 제품 가설의 PASS 근거가 아니다. 숙련 QA·초회 사용자·공식 70전은 실행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 7e61cc9762b5c157a52160ce7f13ad0bf0a7d358
- Review range: 9607d26f883769f51c2a0bd977503e788f7d2532..7e61cc9762b5c157a52160ce7f13ad0bf0a7d358
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 남은 위험과 중단 기준

- 선행 계약 표의 첫 기록과 이번 전체 재실행 사이에 DAY 2 B `52.13→52.12초`, DAY 4 A 후열 압박 `3.58→3.57초`, DAY 4 B `64.22→64.23초`, DAY 4 D `98.87→98.85초`·후열 압박 `44.92→44.93초` 차이가 있었다. 승패·정수 지표·실패 코드·mechanism은 같지만 1~2 physics frame 차이는 PR 5 결정론 재실행 10전에서 별도 판정해야 한다.
- PR 5에서 같은 seed 원 run과 replay의 event fingerprint, 승패 또는 정수 지표가 하나라도 다르면 공식 실제 물리 판정을 중단한다. 원인을 수정할 경우 source SHA와 build hash를 새로 고정하고 70전을 처음부터 다시 실행한다.
- A/B가 한 seed라도 `primary_success`에 실패하거나 mechanism 3/3을 못 채우면 중단한다. C가 실제 불이익 없이 패배하거나 D가 구조·결과 threshold를 동시에 못 바꿔도 중단한다.
- 120초 `TIMEOUT`, 12초 동안 누적 4px 미만 `STUCK`, 직접 HP·spawn·result 조작이 한 건이라도 발견되면 해당 run을 폐기하는 것이 아니라 PR 5 전체 70전을 새 SHA에서 재시작한다.
- PR #71 merge 뒤 회귀가 생기면 별도 rollback PR에서 merge commit을 `git revert -m 1 <merge-sha>`로 되돌린다. reset, force push, tag 이동은 금지한다.

## 8. 다음 차례: PR 5 실제 수용

1. Draft PR #71의 `repository-policy`가 통과한 뒤 merge commit 방식으로만 `release/v2.0`에 병합한다. squash·rebase merge는 금지한다.
2. PR #71 merge SHA에서 PR 5 브랜치를 만들고 기능 source full SHA를 고정한다. 그 SHA로 Windows native와 Chromium Web debug acceptance build를 만들고 EXE·PCK·WASM·ZIP SHA-256을 manifest에 기록한다.
3. 실제 물리 70전을 실행한다: A 15전, B 15전, C 15전, D 15전, 첫 seed A/B 결정론 replay 10전. seed는 DAY별 `2000+d`, `3000+d`, `4000+d`다.
4. 매 run에 source SHA, raw log SHA-256, facility·monster slot, command frame·대상, 자연 spawn, zone entry·exit, 이동 fingerprint, target history, 피해·회복·도난·무력화·압박·돌파, 결과를 기록한다.
5. 숙련 QA 2명이 Windows 2개·Web 2개 캠페인에서 성공 20전과 선행 C 패배 4전, 합계 수동 24전을 mouse·keyboard·x1로 실행한다.
6. 기존 v2.0 개발·플레이 경험이 없는 10명이 동일 Windows build, fresh save, 무설명, 최대 30분으로 DAY 1~5를 플레이한다. 관찰자는 게임 방법을 말하지 않는다.
7. 세 검증 묶음이 모두 끝난 뒤에만 진행 단순성, 배치 승리 재미, 전투 밸런스의 PASS·FAIL을 계산한다. 하나라도 FAIL이면 `DAY1_5_ACCEPTED`를 만들지 않고 PR 4 또는 PR 5 수정점으로 되돌아간다.
8. 세 가설이 모두 PASS일 때만 raw evidence·manifest·hash·판정표를 기준 패키지로 동결하는 PR 6을 시작한다. 1.2.1 기반 새 출시선 이식은 PR 6 뒤 별도 L0부터 시작한다.

## 9. 작업 트리와 자산

- 이 문서 작성 전 기능 tree는 `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`에 고정했다.
- 이 SHA 뒤 변경은 `docs/handoff/V20_DAY1_5_BALANCE_CANDIDATES_2026-07-23.md`와 `docs/handoff/CURRENT.md`뿐이다.
- 신규 그래픽·오디오 자산과 이미지 생성 사용: 0건
- Godot import가 만든 무관 미추적 `.uid` 5개는 대상 경로를 확인하고 커밋 전에 제거했다.
- 검증 로그와 보고서는 `tmp/core_verification/` 아래에 있으며 ignore 상태다.
- `release/v2.0`을 `main`·1.2.1 기반 출시선에 전체 병합하거나 commit range cherry-pick하지 않는다.
