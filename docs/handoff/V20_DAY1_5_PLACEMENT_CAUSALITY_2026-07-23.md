# 제품 2.0 DAY 1~5 PR 3 배치 실제 전투 인과 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-23
- 목표 버전: 제품 2.0 DAY 1~5 행동 계약 검증선
- 작업 브랜치: `codex/v20-validation-placement-causality`
- 기준 브랜치 및 SHA: `release/v2.0@6c6db3e63e7b89699c2d79d153ecbfe8f33691aa` (PR #68 merge commit)
- 마지막 기능 커밋 SHA: `32e759914484255973635054486e1feacb1ccafa`
- 원격 푸시 여부: 기능 SHA 푸시 완료. 이 문서 커밋도 같은 브랜치에 푸시한다.
- 관련 PR 또는 태그: Draft PR #69 `https://github.com/bluehige/mawangseong-demo/pull/69`; 새 태그·Release 없음

## 2. 이번 세션 목표

- 요청 사항: PR 2의 다섯 상태 흐름 위에서 시설·몬스터 배치가 실제 spawn, 이동, 첫 교전, 표적, 피해, 시설 효과, 약탈·도주, 돌파와 왕좌 결과를 바꾸게 한다.
- 완료 조건: DAY 1 seed 2001 A/D를 x1 60 Hz 자연 전투로 완주하고, 슬라임 slot 한 건만 다른 두 run에서 계약 7.5의 구조 차이와 결과 threshold를 동시에 만든다. 시설 bounds, 생존 몬스터 전체 명령, 공병 무력화, 미끼 유무의 도둑 행동도 실제 event로 확인한다.
- 범위에서 제외한 사항: DAY별 적 수·HP/ATK·spawn·telegraph 밸런스, 신규 스토리·몬스터·적·시설, DAY 6 이후, 모바일 전면 개편, 최종 그래픽, 제품 출시선 이식, 태그·Release·공개본 변경

## 3. 완료한 작업

- 구현:
  - `V20BattleEvidence`가 actor spawn, logical cell 이동, zone enter·exit, 목표 변경, 실제 damage·heal, 시설 effect·무력화, 보호 우회, 방패 파괴, 후열 압박, 약탈·탈출, 왕좌 피해, 후퇴선 돌파, DAY 5 증원 누수와 명령 적용 actor를 60 Hz physics frame으로 기록한다.
  - 시설 효과 조회를 `current_room` 문자열이 아니라 설치 zone의 `combat_bounds`와 actor `global_position` 비교로 바꿨다. 시설 이동 시 effect zone도 함께 이동하고, 공병 무력화 동안 passive·active effect가 모두 중단된다.
  - 슬라임·고블린·임프는 저장된 `monster_slot_id`의 canonical world coordinate에서 spawn하며 `v20_home_zone`과 다음 route zone을 기준으로 표적·이동한다. 도둑 사냥꾼은 인접 zone의 도둑을 추적할 수 있다.
  - DAY 1~5 기존 적 6종에 실제 role priority tag만 추가했다. 적 ID와 HP·ATK·방어·속도·spawn 수치에는 변경이 없다.
  - DAY 2 웨이브의 `central_battle_room` 좌표 key가 도둑의 `treasure` 행동 유형을 덮어쓰지 않게 분리했다. 설치된 `v20_decoy_treasure` zone은 저장된 `placement_state.rooms`에서 읽는다.
  - 집결·비상 후퇴 등 명령 event에 실제 생존 몬스터 전체 actor ID를 기록한다. 보호 중 후열 적은 감시 초소 reveal 또는 집중 명령 전에는 표적에서 제외한다.
  - 전투 종료 결과와 V20 결과 화면은 예상 점수나 response tag가 아니라 event ledger에서 계산한 첫 교전, 전선 유지, 실제 시설 effect, 몬스터 실제 피해, 왕좌 피해와 이동 cell을 사용한다.
- 스토리 및 데이터: 신규 콘텐츠 0건. `data/enemies.json`의 현재 DAY 1~5 기존 적 6종 tag만 보완했다.
- 밸런스: 적 수, 공용 적 수치, v20 HP·ATK scale, spawn 시각·간격, telegraph와 시설·명령 수치 변경 0건. 이번 run은 PR 3 인과 hook 검증이며 DAY 밸런스 PASS가 아니다.
- UI/UX: V20 결과 화면의 네 행을 전투 시간, 첫 교전 구역, 전선 유지 시간, 실제 시설·몬스터 기여로 교체했다. `V20PlacementCausalityTest`의 실제 GameRoot가 RESULT 화면까지 생성하는 경로에서 실행했다. 별도 픽셀 시각 검수는 요청되지 않아 실행하지 않았다.
- 저장 및 호환성: V20 격리 `user://tests/*.json`만 생성 후 삭제했다. 제품 저장 schema, `v1.2.1` tag·Release·저장·PC/모바일 공개본은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/enemies.json` | DAY 1~5 기존 적 6종의 실제 target priority tag | 완료 |
| `scripts/v20/combat/V20BattleEvidence.gd`, `.uid` | 60 Hz 실제 사건 ledger와 지표·A/D 인과 계산 | 완료 |
| `scripts/v20/facilities/V20FacilityService.gd` | 설치 zone world bounds 기반 effect·placement 조회 | 완료 |
| `scripts/v20/encounters/V20EncounterService.gd` | 실제 evidence metric 반영, response tag 판정 제거, 좌표 key·행동 유형 분리 | 완료 |
| `scripts/v20/monsters/V20MonsterRoleService.gd` | `targetable=false` 적을 실제 역할 표적에서 제외 | 완료 |
| `scripts/combat/TargetingService.gd` | V20 targetable·catalog tag 기반 표적 함수 | 완료 |
| `scripts/units/Unit.gd` | V20 home zone, slot, actor ID와 이동 사건 필드 | 완료 |
| `scripts/game/CombatSceneController.gd` | 실제 spawn·이동·표적·시설·damage·heal·loot·escape·breach·명령 hook | 완료 |
| `scripts/game/GameRoot.gd` | event ledger 기반 V20 결과 원인·강조·재시도 안내 합성 | 완료 |
| `scripts/v20/ui/V20ResultScreen.gd` | 실제 evidence 네 지표 표시 | 완료 |
| `tools/tests/V20PlacementCausalityTest.gd`, `.uid`, `.tscn` | 합성 ledger 단위 검사와 DAY 1~3 실제 물리 인과 검사 | 완료 |
| `tools/tests/V20FacilityReworkTest.gd` | 시설 5종 world bounds 이동 회귀 | 완료 |
| `tools/tests/V20MonsterRoleGrowthTest.gd` | 실제 적 tag와 보호/노출 targetable 회귀 | 완료 |
| `tools/tests/V20DayOneToFiveEncountersTest.gd` | 실제 지표 판정과 도둑 좌표 key 분리 회귀 | 완료 |
| `tools/tests/core_verification_suite.json` | PR 3 검사를 Quick·Full 목록에 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 신규 자산 없음. 실제 GameRoot의 관리→전투→RESULT 경로는 headless Godot 4.5.2에서 실행했으며 픽셀 시각 검수는 실행하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 구체적 근거 |
|---:|---|---|---|
| 1 | `godot --headless --path . tools/tests/V20PlacementCausalityTest.tscn` | PASS, 76/76 | DAY 1 A/D, DAY 2 미끼, DAY 3 공병, 명령·시설 bounds·ledger |
| 2 | DAY 1 seed 2001 A/D 자연 전투, x1, 최대 7200 physics frame | PASS | A 전선 4.2167초·71 cells·몬스터 피해 262, D 전선 0초·32 cells·몬스터 피해 258 |
| 3 | DAY 1 A/D fixture diff | PASS | D는 `slime` slot `gate_outpost_monster_1 → spike_corridor_monster_2`만 변경. 시설·imp·goblin·난이도·seed·명령 event 동일 |
| 4 | DAY 2 미끼 없음/있음 실제 물리 비교 | PASS | 미설치: 중앙 목표·약탈 0·탈출 0. gate 미끼: 목표 gate, frame 971에 실제 100 약탈·탈출 1 |
| 5 | DAY 3 공병 실제 무력화 | PASS | disable frame 301~721, 구간 내 시설 effect 0건, 종료 뒤 같은 회복 둥지 effect 33건 |
| 6 | 집결 명령 실제 적용 대상 | PASS | `monster:slime`, `monster:goblin`, `monster:imp` 생존 3개 actor ID 전부 기록 |
| 7 | `V20FacilityReworkTest.tscn` | PASS, 33/33 | 시설 5종 설치·이동 bounds와 effect 회귀 |
| 8 | `V20MonsterRoleGrowthTest.tscn` | PASS, 46/46 | 실제 catalog tag, 보호 targetable, 역할 이동·표적 회귀 |
| 9 | `V20TacticalCommandsTest.tscn` | PASS, 27/27 | 네 명령, 비용·지속·cooldown·HUD 계약 회귀 |
| 10 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 89/89 | DAY 1~5 schema·schedule·route·실제 지표 판정·adapter 회귀 |
| 11 | `git diff --check`, suite JSON UTF-8 parse | PASS | whitespace 오류 0건, JSON parse 성공 |
| 12 | 전체 회귀 테스트 | NOT_REQUESTED | 관련 V20 스위트만 실행 |
| 13 | 숙련 QA·초회 사용자·픽셀 시각 검수 | NOT_REQUESTED | PR 5 전에는 공식 수용 판정 금지 |

테스트의 PASS는 PR 3 배치 인과 hook과 관련 회귀에만 적용한다. 진행 단순성, 배치의 재미와 DAY 1~5 전투 밸런스는 세 가설 모두 `PENDING`이다. 자동 문자열, response tag, 예상 점수, 이번 단일 seed 결과를 공식 재미·밸런스 PASS로 사용하지 않는다.

### 검수 에이전트 반복 기록

- 별도 검수 에이전트는 요청되지 않아 실행하지 않았다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. PR 3 필수 관련 검사는 실행했다. 전체 회귀·숙련 QA·초회 사용자 수용은 현재 PR 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `32e759914484255973635054486e1feacb1ccafa` 이후에는 `docs/handoff/`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 32e759914484255973635054486e1feacb1ccafa
- Review range: 6c6db3e63e7b89699c2d79d153ecbfe8f33691aa..32e759914484255973635054486e1feacb1ccafa
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: `V20PlacementCausalityTest` 종료 시 Godot이 `ObjectDB instances leaked`와 `1 resources still in use` 경고를 남기지만 exit code는 0이고 76 assertions는 모두 완료된다. PR 4가 fixture runner를 확장할 때 test teardown의 queued node 정리를 다시 확인한다.
- 밸런스 관찰 항목: DAY 1 단일 seed A/D의 결과 차이는 전선 유지 시간 하나로 threshold를 넘었다. DAY 2~5 A/B/C/D와 세 seed 공식 판정은 아직 없다. 적 수·spawn·telegraph·특수 행동 지속은 PR 4에서만 조정한다.
- 임시 구현 또는 대체 자산: 없음
- 외부 환경/도구 제약: Godot 4.5.2의 깨끗한 headless import는 이 Windows 환경에서 첫 CJK font import 중 접근 위반이 재현되어, 선행 PR 2 worktree의 `.godot/imported` 로컬 캐시를 복사해 관련 scene을 실행했다. `.godot/`은 ignore 상태이며 커밋하지 않았다.

### 중단·롤백 기준

- PR #69에서 `response_tags`만으로 phase 성공이 다시 발생하거나, 시설 effect가 설치 bounds 밖에서 기록되거나, 공병 무력화 중 effect가 1건 이상 발생하거나, A/D가 경로와 결과 threshold를 함께 바꾸지 못하면 merge하지 않는다.
- PR #69 merge 뒤 같은 문제가 재현되면 PR 4를 중단하고 별도 rollback PR에서 PR #69 merge commit을 `git revert -m 1 <merge-sha>`로 되돌린다. reset, force push, tag 이동은 금지한다.
- `release/v2.0` 전체를 `main`, `release/v1.2` 또는 향후 제품 출시선에 merge·cherry-pick·덮어쓰기하지 않는다.

## 8. 다음 작업 순서

1. Draft PR #69의 `repository-policy`를 통과시키고 merge commit 방식으로 `release/v2.0`에 병합한다. 완료 조건은 base가 `release/v2.0`, merge 방식이 merge commit, 원격 필수 check PASS, merge SHA 기록이다.
2. #69 merge SHA에서만 `codex/v20-validation-day01-05-balance`를 만든다. `data/v20/encounters.json`, PR 4 fixture·adapter allowlist만 수정하며 공용 `data/enemies.json` 수치와 신규 ID·자산은 건드리지 않는다.
3. DAY 1~5 각각 A/B/C/D fixture를 만들고 첫 seed `2000+d`의 20개 x1 60 Hz 후보 run을 실행한다. A/B는 두 목표와 mechanism, C는 실패·DAY별 불이익, D는 A 대비 slot 한 건 diff와 계약 7.5 두 조건, A/B 시간 범위를 모두 만족해야 한다.
4. PR 4 결과는 밸런스 후보로만 기록한다. 공식 PASS는 PR 5의 자동 계약, 실제 물리 70전, 숙련 QA 24전, 초회 사용자 10명과 동일 source SHA/build hash가 모두 모인 뒤에만 계산한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 문서 커밋·푸시 뒤 `## codex/v20-validation-placement-causality...origin/codex/v20-validation-placement-causality`
- 미커밋 파일: 문서 커밋 뒤 0개
- 의도하지 않은 기존 변경: 0개. Godot이 만든 무관 UID 5개는 추적 전 삭제했다.
- 스태시 또는 별도 작업공간: linked worktree `마왕성_v20_placement_causality`, stash 없음
- 빌드/캡처 산출물 위치: 새 빌드·캡처 없음. 제품 공개본 변경 없음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트는 실행하지 않음
- [x] 검수 대상 최종 SHA와 정책 필드 기록
- [x] 신규 그래픽·오디오 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 명시 스테이징
- [x] 기능 브랜치 푸시 및 Draft PR #69 생성
