# DAY 1~5 수용 테스트 프로토콜

- 작성일: 2026-07-22
- 상위 계약: `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md`
- 적용 대상: 하나의 고정 source SHA와 그 SHA에서 만든 Windows·Web build
- 표준 난이도: `v20_tactician` 보통
- 표준 속도: x1, `Engine.time_scale = 1.0`, 물리 60 Hz

## 1. 증거 등급과 판정 금지

수용 결과는 아래 네 묶음을 분리해 저장한다.

1. 자동 계약
2. 실제 물리 프레임 전투
3. 숙련 QA 수동 플레이
4. 초회 사용자 무설명 플레이

자동 계약만 통과하면 상태는 `AUTOMATED_CONTRACT_PASS`다. 실제 전투, 재미와 밸런스는 `PENDING`이다.

다음은 실제 전투 증거로 인정하지 않는다.

- `V20EncounterService.evaluate_strategy()` 반환값
- response tag 개수
- `estimated_duration()` 반환값
- 유닛 teleport 또는 current room 직접 변경
- HP·mana·목표 값을 직접 변경
- `_update_room_effects()`, checkpoint 통과 함수 또는 `_finish_combat()` 직접 호출
- debug spawn 뒤 일부 effect만 실행
- 결과 화면 문자열, screenshot, console 오류 0건

## 2. 수용 build 고정

실행 전 manifest에 다음을 기록한다.

- source full SHA
- base full SHA
- 변경 파일 목록
- Godot 버전
- Windows와 Web 모두 `debug acceptance export`인지 여부, export preset 이름과 export 명령. release export 또는 서로 다른 build flavor를 섞으면 `PENDING`
- Windows ZIP·EXE·PCK 각각의 SHA-256과 byte 수
- Web PCK·WASM SHA-256과 byte 수
- `data/v20/` 계약 파일별 SHA-256
- 격리 test OS profile에 복사한 `user://campaign_save_v1.json`~`campaign_save_v5.json` sentinel의 실행 전 SHA-256. 없는 버전은 `ABSENT`로 기록
- 실험 저장 경로
- 불변 tag object `eca4d82d6d5820f807eb98ac33c3959220d8f603`와 peeled commit `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- GitHub Release `마왕성 v1.2.1`의 자산 `MawangCastle-v1.2.1-Windows.zip`, 263,306,748 bytes, SHA-256 `63118100a3b304a1c10c904a6e6b5da2a368ee0d5721dcd9037b982f80f3cb3e`
- PC 공개 Pages commit `1d02f2912be8ce5bbc115e2d4980398c6ea73d41`과 PCK 231,380,996 bytes
- 모바일 공개 Pages commit `5a0461f4a896a3c1d6829f6d0410b531a0614b35`과 PCK 146,798,916 bytes

Windows와 Web가 다른 source SHA면 모든 수동·사용자 결과를 합치지 않고 `PENDING`으로 처리한다.

위 tag, Release 자산 metadata, 공개 Pages commit·PCK byte 수와 sentinel save hash를 PR 1 실행 전과 PR 6 동결 직전에 다시 읽는다. 하나라도 달라지면 즉시 `NO_GO`이며 v20 테스트를 계속하지 않는다. 기존 제품 저장을 실제 테스트 입력으로 쓰지 않는다.

기능, data, scene 또는 asset이 한 줄이라도 바뀌면 새 source SHA에서 물리·수동·초회 사용자 묶음을 다시 실행한다. 숫자, 판정식, scenario·fixture 정의, 절차 또는 분자·분모를 바꾸는 문서 변경은 영향받는 요약을 원본에서 다시 계산하며, 원본에 필요한 필드가 없으면 해당 증거를 무효화하고 다시 실행한다. 오탈자·링크만 바뀌고 수용 source tree와 build hash가 같을 때만 계산 없이 기존 실행 결과를 유지한다.

## 3. 자동 계약 테스트

### 3.1 필수 항목

- canonical zone 5개와 모든 slot ID가 유일함
- zone → slot → logical cell → world position → zone 왕복 일치
- 준비 배치 → save → load → combat spawn → result zone 일치
- 상태 전이가 `INTRUSION_BRIEF → PLACEMENT → DEFENSE_START → COMBAT → RESULT` 규칙만 따름
- 동일 seed·배치·명령 event는 동일 spawn schedule과 event fingerprint를 생성함
- retry 100회와 DAY 전환 100회 뒤 시설 총비용 상한이 10으로 유지되고 `available_build_points=10-sum(installed_facility.cost)`임
- 승리·패배 반복으로 gold, mana, EXP 또는 별도 건설 재화를 파밍할 수 없음
- DAY 전환 100회에서 command 3/3, recharge progress 0, 모든 command·monster cooldown 0, facility charge catalog max, active·disable 0, 몬스터 level 1·EXP 0·max HP·mana가 매번 같음
- 기존 `campaign_save_v*.json` 실행 전후 hash가 같음
- v20 저장은 `user://v20/` 안에서만 생성됨
- JSON schema, ID 참조, 실제 enemy·facility·command 참조가 유효함

### 3.2 실행 대상

기존 관련 V20 test와 아래 신규 test를 실행한다.

- `tools/tests/V20UnifiedSpatialModelTest.tscn`
- `tools/tests/V20DayFlowStateMachineTest.tscn`
- `tools/tests/V20PlacementCausalityTest.tscn`
- `tools/tests/V20DayOneToFiveEncountersTest.tscn`
- `tools/tests/V20FacilityReworkTest.tscn`
- `tools/tests/V20MonsterRoleGrowthTest.tscn`
- `tools/tests/V20TacticalCommandsTest.tscn`
- `tools/tests/V20DifficultyEconomyTest.tscn`
- `tools/tests/V20OnboardingRetrySaveTest.tscn`
- `tools/DemoSmokeTest.tscn`
- 수용 후보에서는 `tools/tests/RunCoreVerification.ps1 -Mode Full`

기존 test의 response tag와 예상 시간 assertion은 schema 회귀로 유지할 수 있다. 실제 전투 PASS 개수에는 포함하지 않는다.

## 4. 실제 물리 프레임 70전

### 4.1 실행 금지와 허용

runner는 실제 `GameRoot.tscn`을 열고 다음 DAY 상태를 UI action 또는 공개 runtime method로 진행한다. `COMBAT` 진입 뒤에는 `await get_tree().physics_frame`으로만 시간을 진행한다.

허용:

- 배치 fixture를 실제 placement API로 입력
- 정해진 event 조건에 command 입력
- 매 physics frame에서 위치·HP·state를 읽어 log 기록
- 결과 화면 생성 뒤 log 종료

금지:

- 적·몬스터 위치, HP, 방, target 강제 설정
- spawn·damage·facility effect·breach 함수 직접 호출
- 서비스 결과로 승패 덮어쓰기
- x2·x3 또는 engine time scale로 공식 run 가속

### 4.2 seed

각 DAY는 아래 세 seed를 사용한다.

| DAY | seed 1 | seed 2 | seed 3 |
|---:|---:|---:|---:|
| 1 | 2001 | 3001 | 4001 |
| 2 | 2002 | 3002 | 4002 |
| 3 | 2003 | 3003 | 4003 |
| 4 | 2004 | 3004 | 4004 |
| 5 | 2005 | 3005 | 4005 |

### 4.3 run 수

| 묶음 | 계산 | 전투 수 |
|---|---:|---:|
| 대응 A | 5 DAY × 3 seed | 15 |
| 대응 B | 5 DAY × 3 seed | 15 |
| 오답 C | 5 DAY × 3 seed | 15 |
| 한 항목 인과군 D | 5 DAY × 3 seed | 15 |
| 결정론 재실행 | 5 DAY × A/B × 첫 seed | 10 |
| 합계 |  | 70 |

### 4.4 명령 event

fixture는 wall-clock 초가 아니라 실제 전투 event를 조건으로 명령을 낸다.

인과군 D는 같은 DAY 대응 A의 명령 조건, 대상과 허용 입력 지연을 그대로 사용한다.

| DAY | 대응 | 명령 조건 |
|---:|---|---|
| 1 | A/B | 명령 없음 |
| 2 | A | 명령 없음 |
| 2 | B | 명령 없음 |
| 3 | A | 공병 spawn이 끝나 화면에서 선택 가능해진 뒤 1초 안에 공병에게 `적 집중` |
| 3 | B | 명령 없음 |
| 4 | A | 궁수가 Z2에 진입하면 1초 안에 감시 초소 발동 |
| 4 | B | 궁수 spawn 뒤 1초 안에 궁수에게 `적 집중` |
| 5 | A | 용사 대시 예고 시작 뒤 1초 안에 Z4로 `비상 후퇴`, 도착 뒤 회복 둥지 발동 |
| 5 | B | 명령 없음 |

명령 조건이 발생하지 않으면 runner가 대신 명령하지 않는다. `expected event missing`으로 실패한다.

### 4.5 오답 C와 한 항목 인과군 D

모든 C와 D도 몬스터 세 마리를 서로 다른 유효 슬롯에 배치하며 구역당 두 슬롯을 넘지 않는다.

#### 오답 C

| DAY | 오답 배치 | 기대하는 실제 불이익 |
|---:|---|---|
| 1 | 시설 없음, Z3 임프, Z4 슬라임·고블린 | `primary_success == false`이고 첫 교전이 Z3이며, 동일 seed A보다 왕좌 HP 10%p 이상 감소 또는 전투 시간 +2초 이상 |
| 2 | 시설 없음, Z1 슬라임·고블린, Z4 임프, 명령 없음 | `primary_success == false && gold_stolen >= 1` |
| 3 | Z1 바리케이드 + 슬라임·고블린, Z4 임프, 명령 없음 | `primary_success == false`, 시설 최대 연속 비활성 2초 이상, 동일 seed A보다 왕좌 HP 10%p 이상 감소 |
| 4 | 시설 없음, Z1 슬라임·고블린, Z4 임프, 궁수 집중 없음 | `primary_success == false`이고 후열 압박 2초 이상 또는 동일 seed A보다 종료 몬스터 HP 합계 10%p 이상 감소 |
| 5 | 시설 없음, Z1 슬라임·고블린, Z2 임프, 후퇴·집결 없음 | `primary_success == false`이고 왕좌 전실 돌파 1회 이상 또는 2차 누수 1회 이상 |

오답이 기대 불이익을 만들지 않으면 대응의 차이가 검증되지 않은 것이며 PASS가 아니다. 오답을 더 나쁘게 만들기 위해 별도 debuff를 주지 않는다.

#### 한 항목 인과군 D

D는 대응 A의 전체 fixture를 복사한 뒤 아래 한 항목만 바꾼다.

| DAY | A에서 D로 바꾸는 유일한 항목 | 고정되는 항목 |
|---:|---|---|
| 1 | 슬라임 `gate_outpost_monster_1 → spike_corridor_monster_2` | 바리케이드, 임프, 고블린, 명령 없음 |
| 2 | 고블린 `central_battle_room_monster_1 → gate_outpost_monster_2` | 바리케이드, 미끼 보물실, 슬라임, 임프, 명령 없음 |
| 3 | 임프 `spike_corridor_monster_1 → throne_anteroom_monster_1` | 감시 초소, 병영, 슬라임, 고블린, 공병 집중 명령 |
| 4 | 임프 `spike_corridor_monster_1 → throne_anteroom_monster_1` | 감시 초소, 병영, 슬라임, 고블린, 감시 초소 발동 명령 |
| 5 | 임프 `throne_anteroom_monster_1 → spike_corridor_monster_1` | 바리케이드, 회복 둥지, 슬라임, 고블린, 후퇴·시설 발동 명령 |

runner는 A/D fixture의 구조 diff가 정확히 위 `monster_slot_id` 한 개뿐인지 전투 전에 검사한다. 다르면 해당 DAY의 A/D 6전을 실행하지 않고 fixture 오류로 실패한다.

### 4.6 매 전투 기록

- `run_id=<source SHA 앞 12자>-d<DAY>-<scenario>-s<seed>-<purpose>-r<attempt>`, DAY, scenario ID, seed, source full SHA
- `purpose=PRIMARY|DETERMINISM_REPLAY`, `replay_of_run_id`와 원 run raw log SHA-256. 원 run의 `replay_of_run_id`는 `null`
- facility·monster `zone_id`와 slot ID
- command 시각, 대상과 결과
- 적별 자연 spawn 시각
- 매 unit의 zone entry·exit, logical cell 변경 배열, `movement_path_fingerprint`와 이동 거리
- target·goal 변경 `target_history`
- 첫 교전 zone과 시각
- zone별 교전 시간
- facility effect 시작·종료·대상 world position
- actor별 준 피해·받은 피해·회복
- 왕좌 HP, 도난, 비활성 시간, 후열 압박, 돌파와 2차 누수
- 게임 전투 시간과 physics frame 수
- 최종 승패와 result state

실제 이동 명령을 가진 unit이 12초 동안 누적 4px 미만 이동하면 `STUCK`이다. 120초 안에 결과가 없으면 `TIMEOUT`이다.

### 4.7 PASS 계산

- A와 B는 각 DAY·scenario에서 상위 계약 8절의 `primary_success` 3/3
- A와 B는 각 DAY·scenario에서 `secondary_success` 2/3 이상, 9절의 `mechanism_assertions` 3/3
- 오답 C는 seed 3/3에서 `primary_success == false`이고 4.5 표의 같은 행 전체 조건을 만족
- A/B는 각자 선언한 시설·몬스터·명령의 실제 event가 발생하고 두 scenario의 event fingerprint가 다름
- 같은 seed A/D 3/3에서 첫 교전 zone·적 목표·실제 이동 경로 중 하나가 다름
- 같은 seed A/D 3/3에서 상위 계약 7.5의 결과 차이 threshold를 하나 이상 넘음
- 시설·몬스터를 사용한 scenario의 해당 실제 기여 지표가 0보다 큼
- 결정론 재실행 10전의 event fingerprint, 승패와 정수 지표가 원 run과 같음
- 결정론 재실행 10전은 3/3, 2/3과 시간 중앙값의 분자·분모에 다시 넣지 않음
- DAY별 A 3전의 중앙값과 B 3전의 중앙값이 각각 아래 범위 안에 있음. C·D와 결정론 재실행 시간은 제외

| DAY | 중앙값 PASS 범위 |
|---:|---:|
| 1 | 45~65초 |
| 2 | 52~78초 |
| 3 | 58~86초 |
| 4 | 62~94초 |
| 5 | 70~106초 |

## 5. 숙련 QA 수동 플레이

### 5.1 표본

- QA 2명
- Windows native 1280×720 2개 캠페인
- Chromium Web 1280×720 2개 캠페인
- 각 캠페인 DAY 1~5 성공: 4 × 5 = 20개 공식 A/B 성공 기록
- QA 1은 Windows에서 A, Web에서 B를 사용한다.
- QA 2는 Windows에서 B, Web에서 A를 사용한다.
- 각 캠페인의 지정 DAY에서 공식 A/B 성공 전에 C를 한 번 실행한다. 배정은 `QA1 Windows=DAY2 seed 2002`, `QA1 Web=DAY3 seed 2003`, `QA2 Windows=DAY4 seed 2004`, `QA2 Web=DAY5 seed 2005`다.
- C는 `RESULT.loss`여야 한다. 그 결과에서 `배치 수정`을 눌러 해당 캠페인의 A 또는 B 전체 배치로 고친 뒤 성공한 재도전을 그 DAY의 공식 20개 기록 중 하나로 센다.
- 총 실제 수동 전투는 공식 성공 20전 + 선행 C 패배 4전 = 24전이다. C 패배 뒤 성공한 4전은 중복해서 더하지 않는다.

### 5.2 절차

- clean save와 보통 난이도로 시작
- 네 캠페인은 배치를 넣지 않는 `scenario_id=FREE`와 고정 seed map `1:2001,2:2002,3:2003,4:2004,5:2005`를 사용한다.
- Windows는 manifest에 기록한 debug acceptance export를 `MawangCastle.exe -- --v20-acceptance --v20-seed-map=1:2001,2:2002,3:2003,4:2004,5:2005 --v20-scenario=FREE`로 시작한다.
- Web은 debug Web export를 `http://127.0.0.1:8060/index.html?v20_acceptance=1&v20_seed_map=1%3A2001%2C2%3A2002%2C3%3A2003%2C4%3A2004%2C5%3A2005&v20_scenario=FREE`로 연다. 실제 export 경로, HTTP server 명령과 URL은 manifest에 기록한다.
- 개발 console·debug key·직접 scene 실행 금지
- mouse와 keyboard로 침입 확인부터 결과까지 실제 조작
- 공식 성공 전투는 x1 사용
- 지정 C는 실제 결과 화면에서 `primary_success == false`와 DAY별 불이익을 확인한 뒤에만 `배치 수정`
- C에서 A/B로 바꿀 때 여러 시설·몬스터를 편집할 수 있으나 `RESULT → PLACEMENT → DEFENSE_START` edge를 건너뛰지 않음
- `배치 수정`은 시설·몬스터 배치를 포함한 전투 직전 snapshot 전체를 먼저 복원한 뒤 편집을 허용한다. command·HP·mana·cooldown·facility charge를 C 종료값으로 유지하지 않는다.
- `DEFENSE_START`가 저장한 해당 DAY의 `encounter_seed`와 전투 첫 physics frame 직전 RNG state hash를 C와 재도전에서 같게 유지한다. C 뒤 재도전이 다른 seed 또는 RNG state로 시작하면 C와 성공 run을 모두 폐기하고 같은 campaign DAY를 처음부터 다시 기록한다.
- runtime `scenario_id`는 C 뒤에도 `FREE`다. 기록자가 raw placement·command event로 선행 run을 C, 재도전을 해당 A 또는 B로 분류하며 scenario 문자열이 승패나 목표식을 바꾸지 않는다.
- 각 DAY 종료 뒤 화면 표시와 video를 대조

### 5.3 PASS

- A와 B가 각 DAY에서 사람 조작으로 2회씩 primary 성공
- DAY 2~5 secondary는 A/B 각각 적어도 1회 성공
- 지정 C 4전이 모두 패배하고 `배치 수정` 뒤 해당 A/B가 같은 campaign에서 성공
- 준비 slot과 전투 spawn zone 불일치 0건
- 표시 전투 시간과 video wall-clock 차이 1초 이하. 일시정지 구간은 둘 다 제외
- command 대상 오선택, 버튼 dead state, 진행 불가 0건
- C 결과 원인과 실제 video 사건이 4건 모두 일치
- 각 Windows·Web run에서 화면의 승패·목표 boolean이 그 run의 raw event ledger 판정과 일치. 서로 다른 사람·대응인 Windows run과 Web run끼리 같은 boolean을 요구하지 않음

수동 플레이는 UI와 실제 조작 증거다. 재미 PASS로 세지 않는다.

## 6. 초회 사용자 10명 무설명 테스트

### 6.1 참가자

- `release/v2.0`과 `/v20-p11*`를 플레이하거나 개발한 적 없는 10명
- 한 명당 한 번의 독립 세션
- 참가자 ID는 `FU01`~`FU10`
- 이름, 연락처와 음성 같은 PII는 저장소에 기록하지 않음
- 녹화 장치 고장, 연구실 정전 또는 OS 업데이트처럼 게임 process 밖에서 combat 전 발생한 실패만 외부 기술 실패다. 최대 2명을 대체 모집해 유효 10명을 채운다.
- 게임 crash, hard lock, save 오류, 결과 미도달과 UI 진행 차단은 대체할 기술 실패가 아니라 해당 source SHA의 제품 실패다.

### 6.2 환경

- 모두 같은 source SHA와 같은 Windows native debug acceptance ZIP·EXE·PCK hash
- 각 session은 관찰자가 manifest에 기록한 debug acceptance export를 `MawangCastle.exe -- --v20-acceptance --v20-seed-map=1:2001,2:2002,3:2003,4:2004,5:2005 --v20-scenario=FREE`로 시작하고, 참가자에게는 title 화면부터 넘긴다. FREE는 배치·명령·승패를 주입하지 않는다.
- 보통 난이도
- fresh `user://v20/` 저장
- 1280×720 이상 PC, mouse와 keyboard
- 최대 30분
- 실행 방법 외 게임 설명 금지
- 관찰자는 외부 장치 고장 외에는 개입하지 않음

관찰자가 게임 방법을 말한 session은 모든 정량 분자·분모에서 제외하고 대체 모집한다. 정성 감사 기록에는 개입 문장과 시각만 남긴다.

### 6.3 진행

1. 참가자에게 title 화면을 넘긴다.
2. 침입 확인부터 자유롭게 플레이하게 한다.
3. DAY마다 최대 두 번 시도할 수 있다.
4. 한 DAY를 두 번 실패하면 활성 campaign을 종료하고 그 실패까지를 정량 기록한다. 참가자는 고정 10명 분모에 남고, 도달하지 못한 이후 DAY의 성공값은 0이다. DAY를 강제로 여는 fixture나 별도 session은 실행하지 않는다.
5. 진행 중에는 질문하지 않는다. 30분 종료, DAY 5 terminal RESULT 또는 두 번 실패로 campaign이 끝난 직후에만 아래 질문을 한 번 묻는다.

### 6.4 고정 질문

- `DAY 1~3 중 기억나는 한 결과를 고르세요. 그 결과를 바꾼 시설 또는 몬스터 위치는 무엇이며, 화면에서 어떤 변화가 보였습니까?`
- `같은 DAY를 다시 하면 무엇 하나를 어느 구역으로 옮기겠습니까?`
- `내 배치 때문에 결과가 달라졌다고 느꼈다.` 1~5점
- `배치를 바꿔 다시 싸워 보고 싶다.` 1~5점
- `하루가 어떤 순서로 진행됐습니까? 기억나는 순서대로 말해 주세요.`

질문 전에 정답, 시설명, 구역명과 대응 후보를 말하지 않는다.

### 6.5 관찰 기록

- 첫 시설 또는 몬스터 배치까지 wall-clock 초
- `방어 시작`까지 초
- 상태별 체류 시간
- invalid click 수와 20초 이상 무입력 구간
- 관찰자 도움 횟수와 정확한 문장
- DAY별 시도 수, `FAMILY_A`·`FAMILY_B`·`HYBRID`·`OTHER` 분류
- 실제 배치 변경과 재도전 여부
- 질문 원문 답변과 점수
- crash·soft lock·진행 불가

### 6.6 대응 계열 분류

분류는 UI 문자열이나 response tag가 아니라 raw event log에 아래 조건이 있는지로 계산한다. `primary_success && secondary_success`인 run만 성공 사례로 센다.

| DAY | `FAMILY_A` 필수 event | `FAMILY_B` 필수 event |
|---:|---|---|
| 1 | 바리케이드 실제 slow > 0, 첫 교전 `gate_outpost` | 병영 실제 bonus/reduction > 0, 첫 교전 `spike_corridor` |
| 2 | 미끼 설치, `decoy.lured_count >= 1`, 도난 0 | 미끼 미설치, 탐험가 Z2 교전과 고블린-도둑 Z3 교전 모두 발생, 도난 0 |
| 3 | targetable 1초 안 공병 집중, 최대 연속 무력화 ≤2초 | 조기 공병 집중 없음, 서로 다른 zone의 시설 ≥2개, 한 시설 무력화 6.5~7.5초 중 다른 시설 effect >0 |
| 4 | 감시 초소 reveal >0, reveal 중 임프의 궁수 피해 >0 | 궁수 spawn 1초 안 집중, 보호 무시 >0, 궁수가 첫 방패병보다 먼저 격퇴 |
| 5 | 대시 예고 1초 안 Z4 비상 후퇴, 회복 >0, 돌파 0 | 비상 후퇴·집결 없음, 용사 Z2 격퇴, 증원 탐험가 Z2·도둑 Z3 첫 교전, 도난·2차 누수 0 |

한 run이 두 열을 모두 만족하면 `HYBRID`, 어느 쪽도 만족하지 않으면 `OTHER`다. 둘은 A/B 성공 사례 수에 포함하지 않는다. 시설이나 몬스터의 정확한 slot이 fixture A/B와 달라도 위 실제 event를 모두 만족하면 해당 family로 분류한다.

### 6.7 인과 설명 코딩

답변은 아래 네 요소 중 모두를 포함해야 성공이다.

1. 실제 시설 또는 몬스터
2. 실제 배치 구역
3. 이동, 첫 교전, 피해, 회복, 무력화, 도난 또는 돌파 중 관찰한 사건
4. 승패 또는 목표 결과

두 평가자가 독립적으로 성공/실패를 분류한다. 10명 중 9명 이상에서 일치해야 하며, 불일치는 세 번째 평가자가 원본 video와 event log로 판정한다. 결과 화면의 원인 문구를 그대로 읽은 답변은 실패다.

### 6.8 PASS

- 8/10이 도움 없이 90초 안에 첫 배치
- 8/10이 도움 없이 DAY 1 결과 도달
- 7/10이 하나의 연속 campaign에서 30분 안에 DAY 1~5 결과를 모두 봄
- 7/10이 다섯 진행 상태 중 네 개 이상을 순서대로 설명
- 활성 campaign으로 자연 도달한 참가자만 계산한 DAY 2~5 배치 체류 시간 중앙값이 DAY당 120초 이하이고 각 DAY `n >= 7`
- 유효 참가자 10명 중 7명 이상이 6.7 인과 설명 성공. DAY 3 전에 연속 campaign이 끝난 참가자는 성공으로 세지 않음
- 7/10이 구체적 배치 수정 뒤 재도전하거나 재플레이 의향 4~5점
- 7/10이 두 5점 문항 모두 4~5점
- DAY 2~5 각각에서 `FAMILY_A`와 `FAMILY_B`의 실제 성공 사례가 각각 1건 이상 있음
- 상위 계약 8절 식으로 계산한 첫 시도 `full_objective_success` 인원: DAY 1 8~10명, DAY 2~4 각각 4~8명, DAY 5 3~7명
- 한 번의 배치 수정 재도전까지 포함한 `primary_success` 인원: DAY 2~5 각각 7명 이상

## 7. 완료·조기 중단·무효화

### 7.1 즉시 중단

- 기존 제품 저장 hash 변화
- crash, hard lock 또는 결과 화면 미도달
- 준비와 전투 zone·slot·좌표 불일치
- 12초 unit 정체
- A/D가 3 seed 모두 상위 계약 7.5의 두 조건을 만들지 못함
- 한 DAY에서 A 또는 B의 첫 primary 실패가 발생해 해당 scenario의 3/3이 불가능해짐
- 첫 초회 사용자 3명이 연속으로 90초 안에 첫 배치를 하지 못함
- 같은 진행 차단이 초회 사용자 2명에게 재현

### 7.2 상태

- 자동만 있거나 아직 모집 중임: `PENDING`
- 외부 기술 실패·관찰자 개입을 제외한 유효 사람 표본이 10명보다 적거나 build SHA가 섞임: `PENDING`
- 7.1의 제품 실패로 즉시 중단: 해당 source SHA는 `NO_GO`
- 네 증거 묶음이 있으나 기준 하나 이상 미달: `NO_GO`
- 네 증거 묶음과 세 가설 기준 전부 통과: `DAY1_5_ACCEPTED`

### 7.3 무효화

- 기능·data·scene·asset 변경: 기존 물리·수동·초회 결과 전부 무효
- 물리 runner 변경: 기존 물리 결과 전부 무효
- A/B/C/D placement·command·expected result fixture 변경: 기존 물리와 수동 A/B/C 결과 전부 무효. 초회 사용자 family 판정은 원본 event에서 다시 계산하고 필요한 event가 없으면 해당 초회 증거도 무효
- 판정식·threshold·분자·분모 문서 변경: 영향받는 summary를 원본에서 다시 계산하고 필요한 필드가 없으면 해당 증거 무효
- test runner가 금지 API를 호출한 것이 발견됨: 해당 물리 결과 전부 무효
- 참가자가 이전 build를 본 사실이 확인됨: 해당 first-user session 제외하고 대체 모집
- raw record와 summary가 다름: summary 무효, 원본에서 다시 계산

## 8. 수용 산출물

저장소에는 비식별 요약과 hash만 둔다.

- `manifest.json`: source/build/data hash
- `physical_summary.json`: 70전 결과와 원본 artifact hash
- `manual_summary.md`: 공식 A/B 성공 20전과 선행 C 패배 4전, 총 24전
- `first_user_summary.md`: FU01~FU10 집계와 비식별 원문 발췌
- `transplant_allowlist.json`: 검증된 함수, data key와 금지 경로

video, frame log와 build는 별도 artifact에 보관하고 URL, SHA-256, byte 수와 보존 기간을 manifest에 적는다. 동의받지 않은 영상·음성·개인정보를 저장소나 PR에 올리지 않는다.
