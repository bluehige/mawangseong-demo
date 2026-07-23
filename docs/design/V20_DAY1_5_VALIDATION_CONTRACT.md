# 마왕성 DAY 1~5 검증 제품 계약

- 문서 상태: 구현 전 상위 제품 계약
- 작성일: 2026-07-22
- 검증 브랜치: `release/v2.0`
- 검증 기준 SHA: `cd4be74bcd34c9ae9b1260fd84ada30b0b6537d3`
- 안정판 기준: `origin/main` `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 불변 출시 태그: `v1.2.1`의 commit `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 구현 순서: `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md`
- 검증 절차: `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md`

## 1. 이 문서가 바꾸는 제품 목표

`release/v2.0`의 목적은 제품 2.0을 직접 출시하는 것이 아니다. 이 브랜치는 DAY 1~5에서 아래 세 가설을 검증하는 실험선이다.

1. 플레이어가 하루 진행 순서를 외부 설명 없이 이해하고 실행한다.
2. 시설과 몬스터를 어느 구역에 배치했는지가 실제 이동, 첫 교전, 피해와 목표 결과를 바꾸며, 그 차이가 다시 배치하고 싶은 재미를 만든다.
3. 보통 난이도의 DAY 1~5가 각 DAY의 두 대응으로 실제 승리 가능하고, 오답 배치에는 실제 불이익이 있으며, 전투 시간이 정한 범위 안에 있다.

세 가설을 같은 수용 SHA에서 모두 통과하기 전에는 제품 행동 계약이 검증됐다고 기록하지 않는다. `release/v2.0`을 `main` 또는 새 출시 브랜치에 병합하지 않는다.

검증이 끝난 뒤에는 `origin/main`의 `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`에서 새 출시 브랜치 `release/v2.0-product`를 만들고, 수용 패키지에 열거된 행동 계약만 PR별로 다시 이식한다. 이 기준 SHA는 `v1.2.1` 출시 commit의 후손이며, 두 SHA 사이의 변경은 출시 workflow, validator와 문서뿐이다. `scripts/`, `scenes/`, `data/`, `assets/`, `project.godot`, `export_presets.cfg`의 런타임 차이는 0개다.

`git diff --name-only v1.2.1..7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`로 확인한 차이는 아래 6개뿐이다.

- `.github/workflows/build-windows-steam.yml`
- `docs/handoff/CURRENT.md`
- `docs/handoff/V12_1_PUBLIC_RELEASE_2026-07-20.md`
- `docs/handoff/V12_1_RELEASE_WORKFLOW_LFS_2026-07-20.md`
- `tools/ci/test_validate_steam_release.py`
- `tools/release/validate_steam_release.py`

## 2. 우선순위와 폐기되는 이전 결정

이 문서는 다음 파일의 충돌 항목을 대체한다.

- `docs/design/V20_CORE_REBUILD_MASTER_SPEC.md`
- `docs/design/V20_KEEP_REWORK_DEFER_MATRIX.md`
- Phase 0~11T 핸드오프의 `다음 작업 순서`

Phase 핸드오프는 당시 구현과 테스트의 감사 기록으로 보존한다. 다음 결정은 더 이상 현재 계획이 아니다.

- `release/v2.0 → main` 전체 병합
- 사람 테스트 Go 뒤 DAY 6~30 이식
- 북·남 두 경로 또는 시설에 따른 경로 전환
- 준비 화면의 추상 구역과 전투 방 사이 adapter를 비차단 기술부채로 남기는 것
- response tag 두 개, 예상 점수 또는 서비스 출력만으로 두 대응과 밸런스를 PASS 처리하는 것

## 3. 현재 판정

| 제품 가설 | 현재 상태 | 이미 있는 증거 | 부족한 필수 증거 |
|---|---|---|---|
| 단순 진행 | `PENDING` | 관리·전투 UI 렌더, DAY 1 일부 Web 조작 | 다섯 상태 실제 완주, 수동 DAY 1~5, 초회 사용자 10명 |
| 배치 승리 재미 | `PENDING` | 배치 서비스, 시설·몬스터 role tag, UI drag | 실제 좌표 기반 A/B 전투, 실제 결과 차이, 초회 사용자의 인과 설명과 재미 응답 |
| 전투 밸런스 | `PENDING` | Encounter schema, 적 수치, 예상 시간 | x1 60 Hz 실제 물리 70전, 숙련 QA 공식 성공 20전+C 패배 4전, DAY별 두 대응의 실제 승리 |

기존 `TARGETED_PASS`, 462 assertions, 공개 PCK/WASM 해시와 오류 0건은 코드·데이터·배포 증거다. 세 제품 가설의 PASS 증거가 아니다.

## 4. 범위

### 4.1 이번 검증에서 허용하는 것

- 기존 슬라임, 고블린, 임프와 기존 탐험가, 도둑, 공병, 방패병, 대마법 궁수, 수련생 용사 사용
- 기존 시설 5종의 위치 규칙과 수치 조정
- DAY 1~5 적 수, 생성 시각, 목표, 특수 행동과 수치 조정
- PC 1280×720 이상에서 다섯 상태를 실행하는 데 필요한 UI 수정
- 실제 물리 전투 계측, 수동 검수 도구와 비식별 플레이테스트 기록
- `user://v20/` 안의 실험 저장 schema 변경과 이전 v20 실험 저장의 명시적 1회 변환

### 4.2 금지하는 것

- 신규 스토리, 신규 몬스터, 신규 적, 신규 시설
- DAY 6 이후 콘텐츠, 엔딩, 원정, 의회, 전초기지, 상층, 합동기 이식
- 모바일 전면 개편
- 신규 최종 그래픽과 신규 최종 오디오
- `v1.2.1` 태그, GitHub Release, Release 자산, 현재 PC·모바일 공개 루트 변경
- `campaign_save_v1.json`을 포함한 기존 제품 저장의 읽기·쓰기·이름 변경
- `release/v2.0`의 merge commit 또는 전체 디렉터리를 새 출시 브랜치에 이식

금지 범위가 필요한 문제가 발견되면 현재 구현을 확장하지 않고 `NO_GO` 또는 새 docs 전용 계약 변경 PR로 돌린다.

## 5. DAY 진행 상태 계약

하루는 아래 다섯 상태만 사용한다.

```text
INTRUSION_BRIEF → PLACEMENT → DEFENSE_START → COMBAT → RESULT
```

| 상태 | 플레이어가 보는 정보 | 허용 행동 | 종료 조건 |
|---|---|---|---|
| `INTRUSION_BRIEF` 침입 확인 | DAY, 적 종류와 수, 고정 침입 순서, 보호 목표, 특수 행동 예고, x1 목표 시간 | `배치 시작` | 버튼 1회 입력 |
| `PLACEMENT` 배치 | 네 구역, 구역당 시설 슬롯 1개, 몬스터 슬롯 2개, 시설 설치 총비용 상한 10과 남은 용량, 시설 5종, 몬스터 3종 | 시설 drag 또는 click→click, 몬스터 drag 또는 click→click, 마지막 배치 1회 Undo, `방어 시작` | 시설 설치 총비용 10 이하이고 몬스터 3종이 서로 다른 유효 슬롯을 하나씩 차지할 때 `방어 시작` 입력 |
| `DEFENSE_START` 방어 시작 | 확정된 시설·몬스터 위치, 저장 성공 또는 오류 | 추가 확인창 없음. 3초 카운트다운 중 취소 1회만 허용 | 배치 snapshot 저장과 런타임 좌표 해석 성공 |
| `COMBAT` 전투 | 현재 방어 구역, 다음 구역, 양측 유닛, 시설 상태, 목표 HP, 다음 특수 행동, 최대 4개 명령, 속도·일시정지 | 집결, 적 집중, 시설 발동, 비상 후퇴, x1~x3, 일시정지 | 적 전멸·도주 또는 왕좌 파괴 |
| `RESULT` 결과 | 승패, 첫 교전 구역, 돌파 구역, 시설·몬스터 실제 기여, 목표 손실, 전투 시간, 실제 사건으로 만든 원인 1줄 | DAY 1~4 승리: `다음 침입 확인`; DAY 5 승리: 결과 기록 뒤 종료; 패배: `배치 수정` 또는 `같은 배치 재도전` | DAY 1~4의 다음 `INTRUSION_BRIEF`, 같은 DAY의 `PLACEMENT`·`DEFENSE_START`, 또는 DAY 5의 terminal `RESULT` |

허용 edge는 아래 8개뿐이다.

1. `INTRUSION_BRIEF → PLACEMENT`
2. `PLACEMENT → DEFENSE_START`
3. `DEFENSE_START → COMBAT`
4. `DEFENSE_START → PLACEMENT`: 3초 countdown 취소 또는 snapshot·공간 해석 오류일 때만
5. `COMBAT → RESULT`
6. `RESULT → INTRUSION_BRIEF`: DAY 1~4 승리일 때만
7. `RESULT → PLACEMENT`: 패배 뒤 `배치 수정`일 때만
8. `RESULT → DEFENSE_START`: 패배 뒤 `같은 배치 재도전`일 때만

DAY 5 승리의 `RESULT`는 terminal이다. `PLACEMENT → RESULT`, `INTRUSION_BRIEF → COMBAT`, 결과 없이 다음 DAY 진입을 포함한 나머지 edge는 자동 테스트에서 실패해야 한다.

`DEFENSE_START`는 별도 메뉴가 아니다. `방어 시작` 입력 뒤 snapshot을 저장하고 3초 후 전투로 넘어가는 짧은 전이 상태다. 저장 또는 공간 해석에 실패하면 전투를 시작하지 않고 `PLACEMENT`에 오류가 난 구역과 슬롯을 표시한다.

유효 배치에서는 슬라임, 고블린, 임프가 각각 정확히 하나의 몬스터 슬롯을 차지한다. 한 슬롯에 둘을 놓거나 한 구역의 두 슬롯을 넘겨 세 마리를 놓을 수 없다. 시설은 구역당 0개 또는 1개다.

### 5.1 DAY 자원과 재도전

밸런스 비교를 흔드는 숨은 성장과 반복 패배 보상을 제거한다.

- 보통 난이도의 각 DAY는 시설 설치 총비용 상한 10, 명령력 3/3, 충전 진행 0초, 몬스터 level 1·EXP 0과 각 catalog의 max HP·mana로 시작한다.
- DAY 1~5 검증에서는 몬스터 EXP와 level이 증가하지 않는다. 성장 선택 화면도 노출하지 않는다.
- 건설 점수는 누적 재화가 아니다. `사용 가능 건설 점수 = 10 - 현재 설치된 시설 비용 합계`로 매번 계산한다. 시설 제거는 그 비용만큼 용량을 되돌리고, 이동은 비용을 바꾸지 않으며, 교체는 새 시설 비용으로 다시 계산한다. 몬스터 배치는 이 상한을 소비하지 않는다.
- 새 DAY에는 직전 배치를 보존하고 같은 설치 총비용 상한 10 안에서 수정한다. 승리, 패배, DAY 전환으로 별도 건설 점수를 지급하거나 이월하지 않는다.
- 새 DAY의 모든 명령 cooldown과 몬스터 skill cooldown은 0초, 시설 charge는 catalog의 최대치, 시설 active·disable 남은 시간과 몬스터 상태이상은 0초로 초기화한다. 이전 DAY의 command recharge 진행률, 시설 활성·무력화와 전투 피해는 이월하지 않는다.
- 패배 뒤 `배치 수정`과 `같은 배치 재도전`은 모두 시설·몬스터 배치, 시설 charge, command, HP, mana, cooldown, `encounter_seed`와 전투 첫 physics frame 직전 RNG state를 같은 전투 직전 snapshot으로 복원하고 사용 가능 건설 점수를 위 식으로 다시 계산한다.
- `배치 수정`은 복원 뒤 `PLACEMENT`에서 시설·몬스터를 편집할 수 있고, `같은 배치 재도전`은 편집 없이 `DEFENSE_START`로 간다. 두 경로의 차이는 배치 편집 허용 여부뿐이다.
- 실패 salvage와 승리 income은 DAY 1~5 검증선에서 0이다. 반복 승패로 시설 상한이나 사용 가능 건설 점수를 늘릴 수 없다.
- 기존 `GameState.gold`, 제품 mana와 몬스터 roster EXP는 v20 검증 결과에 읽거나 쓰지 않는다.
- `gold_stolen`은 전투 시작 때 0인 일회성 목표 event counter다. `GameState.gold`, settlement, 건설 점수 또는 다음 DAY 상태를 바꾸지 않는다.

수용 패키지가 동결된 뒤 새 출시 브랜치에서 경제·성장을 추가하려면 이 DAY 1~5 가설과 별도의 제품 계약과 실제 테스트가 필요하다.

## 6. 단일 공간 모델 계약

### 6.1 고정 전투선

침입 순서는 하나로 고정한다.

```text
Z1 성문 전초 → Z2 가시 회랑 → Z3 중앙 전투실 → Z4 왕좌 전실 → 왕좌
```

적은 현재 구역의 수비대와 교전하고, 구역을 돌파한 뒤 1.25초 동안 다음 구역 진입을 예고한 다음 이동한다. 시설 비용, seed와 적 종류가 이 순서를 바꾸지 않는다.

### 6.2 새 canonical ID

| 순서 | canonical `zone_id` | 표시 이름 | 폐기할 준비 ID | 폐기할 전투 ID |
|---:|---|---|---|---|
| 1 | `gate_outpost` | 성문 전초 | `north_gate` | `entrance` |
| 2 | `spike_corridor` | 가시 회랑 | `south_gate` | `spike_corridor` |
| 3 | `central_battle_room` | 중앙 전투실 | `treasure` | `barracks` |
| 4 | `throne_anteroom` | 왕좌 전실 | `fallback` | `fallback` |
| 5 | `throne` | 왕좌 | `throne` | `throne` |

이전 placement·route·runtime ID `north_gate`, `north_cross`, `south_gate`, `south_cross`, placement 의미의 `treasure`, placement 의미의 `fallback`, `entrance`, runtime room 의미의 `barracks`는 v20 실험 저장 schema 변환기 안에서만 입력으로 허용한다. 변환 뒤 session, 배치, 전투, 명령, 결과의 `zone_id`, `home_zone`, `target_zone`, `slot_zone`에는 canonical ID만 남아야 한다.

### 6.3 하나의 레코드가 소유할 값

네 `defense_zone`은 `data/v20/dungeon_layouts.json`의 한 레코드에서 다음 값을 모두 소유한다. `throne`은 경로 종점과 목표 bounds만 가진 `goal_zone`이며 배치 슬롯과 수비대 수를 갖지 않는다.

- `zone_id`, `display_name`, `order`
- 논리 grid origin과 `tile_size [128, 64]`
- 준비 보드 normalized anchor
- 실제 전투 world anchor와 실제 교전 bounds
- route entry·exit
- 시설 슬롯 ID와 world anchor
- 몬스터 슬롯 2개의 ID와 world anchor
- 최대 수비대 수

`logical_grid_v2`의 공통 header는 active grid 28×26, isometric tile 128×64, room cell 5×5, gap 2, stride 7로 고정한다. canonical module origin은 아래와 같다.

| zone | logical origin | module footprint |
|---|---:|---:|
| `gate_outpost` | `[2, 14]` | 5×5 |
| `spike_corridor` | `[9, 14]` | 5×5 |
| `central_battle_room` | `[9, 7]` | 12×5 |
| `throne_anteroom` | `[23, 7]` | 5×5 |
| `throne` | `[23, 0]` | 5×5 |

같은 JSON이 위 module을 잇는 corridor origin·socket connection과 route entry·exit cell도 소유한다. `V20SpatialModel.to_module_graph_layout()`은 이 값에서 `ModuleGraph.load_layout()` 입력을 만들며 다른 JSON이나 controller 상수를 좌표 원본으로 읽지 않는다.

slot ID는 아래 값으로 고정한다.

| zone | facility slot | monster slots |
|---|---|---|
| `gate_outpost` | `gate_outpost_facility` | `gate_outpost_monster_1`, `gate_outpost_monster_2` |
| `spike_corridor` | `spike_corridor_facility` | `spike_corridor_monster_1`, `spike_corridor_monster_2` |
| `central_battle_room` | `central_battle_room_facility` | `central_battle_room_monster_1`, `central_battle_room_monster_2` |
| `throne_anteroom` | `throne_anteroom_facility` | `throne_anteroom_monster_1`, `throne_anteroom_monster_2` |
| `throne` | 없음 | 없음 |

`V20SessionService.SECTION_DEFINITIONS`, `V20PlacementBoard.SECTION_OFFSETS`, `CombatSceneController._v20_runtime_room()`, `GameRoot._v20_runtime_facilities()`, `GameRoot._v20_inject_fallback_runtime_room()`의 별도 ID·좌표·slot 매핑과 호출은 제거한다. `data/dungeon_quarter/test_layouts/role_driven_combat_layout_test_01.json`은 v20 production runtime의 좌표 원본으로 읽지 않는다.

준비 화면 drag 결과, 저장된 슬롯, 전투 spawn, 집결 대상, 시설 효과 구역과 결과의 첫 교전 구역이 모두 같은 `zone_id`를 사용해야 한다. 화면 좌표는 canonical world 좌표에서 하나의 projection 함수로 만들며, 반대 변환 뒤 logical cell 오차는 x·y 각각 0.5칸 이하여야 한다.

## 7. 배치가 실제 결과를 바꾸는 규칙

### 7.1 몬스터

- 전투 시작 시 몬스터는 저장된 `monster_slot_id`의 world anchor에서 생성된다.
- 기본 표적 탐색은 자기 `home_zone` 안의 적을 우선한다. 적이 다음 구역으로 넘어가면 일반 추격은 한 구역까지만 허용하고, 그보다 멀어지면 home slot으로 돌아간다.
- `집결`과 `비상 후퇴`만 일시적으로 home zone을 덮어쓴다. 명령 종료 뒤 생존 몬스터는 home slot으로 복귀한다.
- 성문 파수 슬라임은 자기 구역의 첫 적과 돌파 적을 우선한다.
- 도둑 사냥꾼 고블린은 도둑이 같은 구역 또는 인접 구역에 있을 때 도둑을 우선한다.
- 장거리 화염술 임프는 자기 구역의 후방 anchor를 유지하고 공병·궁수·지원 적을 우선한다.
- 위치를 바꾸면 실제 spawn 좌표, 이동 거리와 첫 교전 구역 중 하나 이상이 바뀌어야 한다. display label 또는 `manual_anchor_node` 문자열만 바뀌면 실패다.

### 7.2 시설

아래 값은 구현 시작값이다. 최종 값은 실제 물리·수동·초회 검증을 통과한 수용 패키지에서 동결한다.

| 시설 | 비용 | 설치 구역에서만 적용되는 passive | 발동 |
|---|---:|---|---|
| 바리케이드 | 3 | 적 이동 속도 ×0.78 | 6초 동안 ×0.48, 1회 |
| 병영 | 4 | 몬스터 피해 ×1.12, 받는 피해 ×0.88 | 7초 동안 ×1.18 / ×0.82, 1회 |
| 미끼 보물실 | 3 | 도둑 속도 ×0.82, 약탈 준비 시간 ×1.5 | 8초 동안 ×0.55 / ×2.0, 1회 |
| 감시 초소 | 4 | 적 속도 ×0.82, 몬스터 피해 ×1.08 | 6초 동안 적 속도 ×0.68. 시설 중심 420px 안의 후열·지원 적은 구역 bounds 밖의 직전 접근 구간에 있어도 전열 보호를 무시하고 targetable, 2회 |
| 회복 둥지 | 4 | 같은 구역 아군 초당 8 회복 | 5초 동안 초당 14, 집결 속도 ×1.35, 2회 |

- 시설 효과는 실제 유닛 world position이 그 시설의 `combat_bounds` 안에 있을 때만 적용한다. 단, 감시 초소 발동의 `reveal_radius=420` 판정만 시설 중심과 적 world position의 직선거리로 계산하며 bounds를 요구하지 않는다. 감시 초소의 둔화·피해 배율은 계속 bounds 안에서만 적용한다.
- 보호받는 후열은 살아 있는 방패병과 같은 고정 경로 구간 또는 바로 인접한 구간에 있을 때 `protected=true`다. 발동 중인 감시 초소가 후열을 노출하면 `imp_artillery`는 그 적을 같은 시간 동안 직전 인접 구간에서도 표적으로 삼고, 공격 사거리 안에서는 다른 전열 적보다 먼저 선택한다.
- 바리케이드는 해당 구역 entry를 통과하는 적에게만 적용한다.
- 미끼가 없는 도둑은 Z3에서 5초 약탈 뒤 입구 방향으로 도주한다. 미끼가 있으면 설치된 구역에서 약탈 준비와 둔화가 적용된다.
- 공병이 시설을 무력화한 동안 passive와 active를 모두 0으로 만든다. 무력화 종료 뒤 남은 충전과 원래 효과를 복구한다.
- 결과 지표는 실제 effect event에서 누적한다. 설치 정보에서 예상 기여를 계산해 결과에 넣지 않는다.

### 7.3 전술 명령

명령력은 3에서 시작하고 12초마다 1씩 3까지 회복한다. 일시정지 중에는 충전·지속·cooldown이 진행되지 않는다.

| command ID / 표시 | 비용 | 대상 | 실제 효과 | 개별 cooldown |
|---|---:|---|---|---:|
| `v20_rally` / 집결 | 1 | 방어 구역 1개 | 모든 생존 몬스터를 대상 구역으로 강제 이동, 6초 동안 이동 속도 ×1.35·받는 피해 ×0.90 | 10초 |
| `v20_focus` / 적 집중 | 1 | 화면에 spawn된 생존 적 1명. 전열 보호 중인 적도 선택 가능 | 5초 동안 표적 우선순위 +100·받는 몬스터 피해 ×1.18·전열 보호 무시, 시전 중이면 interrupt power 1 적용 | 8초 |
| `v20_activate_facility` / 시설 발동 | 1 | charge가 남은 시설 1개 | charge 1을 소비하고 7.2 표의 시설별 active를 즉시 시작 | 3초 |
| `v20_emergency_fallback` / 비상 후퇴 | 2 | 방어 구역 1개 | 모든 생존 몬스터를 대상 구역으로 강제 이동, 5초 동안 이동 속도 ×1.50·받는 피해 ×0.65 | 14초 |

`집결`과 `비상 후퇴`는 특정 몬스터 하나만 고르는 명령이 아니다. 공식 fixture는 명령 요청 event, 입력 시각, 대상 ID, 소비 명령력과 적용 actor 목록을 모두 기록한다.

### 7.4 event ledger 지표

| metric | 시작·증가 event | 종료·계산 규칙 |
|---|---|---|
| `first_engagement_zone` | 첫 몬스터↔적 damage event가 발생한 physics frame | 같은 frame이면 route order가 앞선 zone 하나를 기록 |
| `movement_path_fingerprint` | 이동 actor의 rounded logical cell이 바뀔 때 `(frame, cell_x, cell_y, zone_id)` 추가 | 연속 중복 cell을 제거한 순서 배열을 SHA-256. A/D 비교에는 hash와 총 이동 cell 수를 함께 사용 |
| `target_history` | actor의 combat target instance 또는 goal zone이 바뀔 때 추가 | `(frame, actor_id, target_id, goal_zone)` 순서 배열로 보존 |
| `frontline_hold_seconds` | 첫 교전 zone에서 적과 몬스터가 모두 살아 있고 서로 공격 가능한 첫 frame | 한쪽이 0명, 모든 적이 다음 zone에 진입, 또는 combat 종료까지의 frame union. actor별 시간을 합산하지 않음 |
| `facility_disabled_seconds` | 공병의 `facility_disable_started(facility_id)` | 같은 ID의 `facility_disable_ended`까지. 시설별 interval과 최대 연속 시간을 기록하고 겹친 시설 interval은 각각 보존 |
| `rear_pressure_seconds` | 살아 있는 궁수가 살아 있는 방패병의 보호를 받으며 몬스터에게 첫 attack을 실행 | 보호 해제, 궁수 사망·zone 이탈 또는 combat 종료까지의 frame union |
| `protection_bypass_seconds` | 감시 초소 reveal 또는 적 집중으로 보호받던 적이 targetable이 되는 frame | 해당 active·focus 종료나 적 사망까지. 같은 적의 겹친 interval은 union |
| `shield_breaks` | 보호받던 적의 `protected=true → targetable=true` 전이 | 적·효과 window당 최초 1회만 증가 |
| `fallback_breaches` | 적이 `throne_anteroom` exit를 넘어 `throne` 진입선에 들어감 | enemy instance당 최초 1회만 증가 |
| `second_phase_leaks` | DAY 5의 45초 증원 group 적이 `throne_anteroom`에 진입 | enemy instance당 최초 1회만 증가 |
| `gold_stolen` | 도둑의 5초 loot cast가 완료돼 loot event가 발생 | 도주 성공과 무관하게 event당 1회 증가 |
| `throne_damage` | 왕좌 damage event | `throne_max_hp - throne_end_hp`; 두 run 비교는 최대 HP 대비 percentage point 사용 |

damage, heal, slow, reveal과 시설 active는 actor ID, zone ID, world position, 시작·종료 physics frame을 기록한다. duration은 physics frame 수를 60으로 나누며 같은 actor의 겹치는 interval은 union으로 계산한다.

### 7.5 한 항목 배치 인과 차이

DAY별 대응 A와 인과군 D를 짝지어 비교한다. D는 A에서 몬스터 한 마리의 `monster_slot_id` 하나만 바꾸며 시설, 나머지 몬스터, 난이도, seed와 명령 event·대상은 A와 같아야 한다. A/B는 여러 배치와 명령을 함께 바꾸므로 두 유효 대응의 성립 여부에는 쓰되 단일 배치 인과 증거로 쓰지 않는다.

각 A/D pair는 다음 두 조건을 모두 만족해야 한다.

1. 첫 교전 구역, 적 목표 또는 몬스터 실제 이동 경로 중 하나가 달라진다.
2. 다음 중 하나가 달라진다.
   - 교전 또는 지연 시간 2.0초 이상
   - 두 run의 종료 왕좌 HP 차이가 왕좌 최대 HP의 10%p 이상
   - 보물 도난 1회 이상
   - 시설 비활성 시간 2.0초 이상
   - 후열 압박 시간 2.0초 이상
   - 후퇴선 돌파 1회 이상
   - 두 run의 몬스터 누적 실제 피해 또는 종료 잔여 HP 차이가 해당 scenario의 몬스터 시작 max HP 합계의 10%p 이상

둘 중 하나만 만족하거나 fixture diff가 몬스터 슬롯 하나를 넘으면 배치 인과 PASS가 아니다. DAY별 D의 정확한 변경은 수용 프로토콜 4.5에 고정한다.

## 8. DAY 1~5 전투 계약

모든 수치는 `보통`(`v20_tactician`: 시설 설치 총비용 상한 10, 명령 3/3, 충전 12초, HP·ATK ×1.0, 예고 ×1.0)에서 검증한다. 쉬움·어려움 결과는 이 계약의 실패를 상쇄하지 않는다.

전투 시간은 `DEFENSE_START` 카운트다운 종료부터 `RESULT` 생성까지의 x1 게임 시간이다. 일시정지 시간은 제외한다.

| DAY | 플레이어가 답해야 할 전략 질문 | 적·특수 행동 | x1 목표 / PASS 범위 | 실패 지표 |
|---:|---|---|---|---|
| 1 | 첫 전선을 Z1에 둘지 Z2에 둘지, 슬라임 앞과 임프 뒤 간격을 어떻게 만들 것인가? | 3초 뒤 탐험가 3, 2.8초 간격 | 55초 / 45~65초 | 왕좌 피해, 전열 유지 시간 |
| 2 | 왕좌 전선과 도둑을 병력 분리로 막을지, 미끼로 한곳에 묶을 것인가? | 4초 예고, 탐험가 2 + 도둑 1 | 65초 / 52~78초 | 금화 도난, 왕좌 피해 |
| 3 | 공병을 먼저 끊을지, 시설 분산과 예비선으로 무력화를 견딜 것인가? | 5초 예고, 공병 1 + 탐험가 2, 시설 무력화 7초 | 72초 / 58~86초 | 시설 비활성 시간, 왕좌 피해 |
| 4 | 감시 초소·임프로 후열을 노릴지, 적 집중으로 보호를 깨고 궁수를 먼저 제거할 것인가? | 4.5초 예고, 방패병 4 + 대마법 궁수 1, 후열 압박 6초 | 78초 / 62~94초 | 후열 압박 시간, 방패 파괴, 왕좌 피해 |
| 5 | 용사의 첫 돌파를 후퇴선에서 받을지, Z2에서 막고 45초 증원 때 병력을 다시 나눌 것인가? | 6초에 용사 1, 5초 예고·대시 3초; 45초부터 탐험가 4 + 도둑 1, 6초 예고 | 88초 / 70~106초 | 왕좌 전실 돌파, 2차 누수, 왕좌 피해 |

PR 4가 시작할 보통 난이도 적 후보값은 아래와 같다. 이 값은 현재 코드에서 계산된 초기값이지 측정 PASS가 아니며, 공식 70전 전에 바뀌면 같은 docs 전용 계약 변경 PR에서 표도 먼저 갱신한다.

| DAY | 자연 spawn 게임 시각 | 해당 spawn의 HP / ATK |
|---:|---|---|
| 1 | 탐험가 3.0, 11.0, 19.0, 27.0, 35.0, 43.0초 | 각 139 / 14 (`max_hp_bonus=40`, HP ×1.10, ATK ×2.00) |
| 2 | 도둑 4.0초; 탐험가 5.0, 19.7, 34.4, 49.1초 | 도둑 81 / 8; 탐험가 104 / 8 |
| 3 | 공병 5.0초; 탐험가 15.0, 28.5, 42.0, 55.5초 | 공병 116 / 4; 탐험가 108 / 14 |
| 4 | 첫 방패병 5.0초; 궁수 9.4초; 후속 방패병 23.3, 41.6, 59.9초 | 첫 방패병 339 / 6 (`max_hp_bonus=170`); 후속 방패병 각 169 / 6; 궁수 93 / 14 |
| 5 | 수련생 용사 6.0초; 탐험가 45.0, 53.0, 61.0, 69.0초; 도둑 77.0초 | 용사 345 / 20; 탐험가 104 / 6; 도둑 76 / 5 |

모든 scenario의 `primary_success`는 `RESULT.win == true`, `throne_end_hp > 0`, 예정된 모든 적이 자연 spawn 뒤 `defeated` 또는 `escaped` terminal state에 도달, `STUCK == false`, `TIMEOUT == false`를 모두 만족할 때만 true다.

DAY별 `secondary_success`와 `full_objective_success`는 아래 식으로 계산한다.

| DAY | `secondary_success` | `full_objective_success` |
|---:|---|---|
| 1 | `throne_damage == 0` | `primary_success && secondary_success` |
| 2 | `gold_stolen == 0` | `primary_success && secondary_success` |
| 3 | `throne_damage == 0 && installed_facility_count >= 1 && max_contiguous_facility_disabled_seconds <= 7.5 && (facility_disable_count == 0 \|\| other_facility_effect_events_during_disable >= 1)` | `primary_success && secondary_success` |
| 4 | `rear_pressure_seconds < 6.0 && archer_terminal_state == defeated` | `primary_success && secondary_success` |
| 5 | `fallback_breaches == 0 && second_phase_leaks == 0 && gold_stolen == 0` | `primary_success && secondary_success` |

제품 결과의 `win`은 적 전멸만으로 정하지 않는다. DAY 2에서 `gold_stolen > 0`, DAY 3에서 시설 무력화 interval 중 다른 시설의 실제 effect event가 0, DAY 4에서 `rear_pressure_seconds >= 6.0`, DAY 5에서 `fallback_breaches > 0` 또는 `second_phase_leaks > 0` 또는 `gold_stolen > 0`이면 각각 `protect_treasure`, `keep_one_facility_active`, `break_rear_pressure`, `hold_fallback_line` 또는 `stop_reinforcement_leaks` 실패로 기록하고 `RESULT.win=false`로 만든다.

어떤 전투도 120초 안에 `RESULT`에 도달하지 못하면 실패다.

## 9. DAY별 두 대응

아래 A와 B는 문자열 tag 후보가 아니라 실제 전투가 성립시켜야 하는 수용 시나리오다. 구역을 적은 시설만 설치하며, 적지 않은 구역의 시설 슬롯은 비워도 된다. 한 구역에 몬스터를 하나만 적으면 `_monster_1`, 둘을 적으면 서술 순서대로 `_monster_1`, `_monster_2`에 놓는다.

### DAY 1

- 대응 A — Z1 지연선: Z1 바리케이드 + 슬라임, Z2 임프, Z3 고블린. 탐험가는 Z1에서 처음 교전하고 바리케이드 지연과 임프 후방 피해가 각각 0보다 커야 한다.
- 대응 B — Z2 교전선: Z2 병영 + 슬라임·고블린, Z3 임프. 탐험가는 Z2에서 처음 주 교전을 하고 병영의 실제 추가 피해 또는 피해 감소가 0보다 커야 한다.

### DAY 2

- 대응 A — 유인·추격: Z1 바리케이드 + 슬라임, Z3 미끼 보물실 + 도둑 사냥꾼 고블린, Z4 임프. 도둑이 Z3을 목표로 잡는 mechanism은 3/3이어야 하며, 금화 도난 0인 `secondary_success`는 2/3 이상이어야 한다.
- 대응 B — 병력 분리: Z2 병영 + 슬라임·임프, Z3 고블린. 명령을 사용하지 않는다. 슬라임·임프가 Z2의 탐험가와 교전하는 동안 고블린이 Z3에서 도둑과 교전하는 mechanism은 3/3이어야 하며, 금화 도난 0인 `secondary_success`는 2/3 이상이어야 한다.

### DAY 3

- 대응 A — 공병 선제 차단: Z2 감시 초소 + 임프, Z3 병영 + 슬라임·고블린. 공병 spawn이 끝나 targetable이 된 event 뒤 1초 안에 공병을 `적 집중` 대상으로 지정하고 무력화가 시작되지 않거나 최대 연속 2초 안에 중단돼야 한다.
- 대응 B — 시설 분산·예비선: Z1 바리케이드 + 슬라임, Z3 병영 + 고블린, Z4 임프. 한 시설이 7초 무력화돼도 다른 시설 구역에서 실제 교전이 이어지고 왕좌가 생존해야 한다.

### DAY 4

- 대응 A — 노출·포격: Z2 감시 초소 + 임프, Z3 병영 + 슬라임·고블린. 궁수 world position이 감시 초소 중심 420px 안에 처음 들어온 physics frame 뒤 1초 안에 감시 초소를 발동한다. `protection_bypass_seconds > 0`과 노출 interval 중 임프의 궁수 실제 피해 > 0인 mechanism은 3/3이어야 하며, `rear_pressure_seconds < 6.0 && archer_terminal_state == defeated` 전체 `secondary_success`는 2/3 이상이어야 한다.
- 대응 B — 전열 고정·집중 파괴: Z1 바리케이드 + 슬라임, Z2 임프, Z3 고블린. 방패병이 Z1에 묶인 동안 궁수에게 `적 집중`을 사용해 보호 상태를 5초 동안 무시하고 궁수를 먼저 격퇴해야 한다. 고정 1경로와 모순되는 `flank_route`는 사용하지 않는다.

### DAY 5

- 대응 A — 후퇴선·회복: Z1 바리케이드 + 슬라임, Z3 고블린, Z4 회복 둥지 + 임프. 용사 대시 예고 시작 event 뒤 1초 안에 `비상 후퇴`로 Z4에 모이고 도착 뒤 회복 둥지를 발동해 실제 회복을 만드는 mechanism은 3/3이어야 한다. `fallback_breaches == 0 && second_phase_leaks == 0 && gold_stolen == 0` 전체 `secondary_success`는 2/3 이상이어야 한다.
- 대응 B — 중간 저지·2차 분리: Z2 병영 + 슬라임·임프, Z3 미끼 보물실 + 고블린. 명령을 사용하지 않는다. 용사를 Z2에서 격퇴하고, 45초 증원 탐험가는 Z2, 도둑은 Z3에서 실제로 분리 교전하는 mechanism은 3/3이어야 한다. `fallback_breaches == 0 && second_phase_leaks == 0 && gold_stolen == 0` 전체 `secondary_success`는 2/3 이상이어야 한다.

### 9.1 PR 4 첫 seed 후보 기록

아래 20개는 `v20_tactician`, x1, 물리 60 Hz, seed `2000+DAY`에서 direct HP 수정·teleport·직접 result 호출 없이 얻은 PR 4 수치 탐색 기록이다. 자동 후보 gate를 통과했다는 뜻일 뿐 `PHYSICAL_COMBAT_PASS`, 재미 PASS 또는 전투 밸런스 PASS가 아니다. 공식 판정은 PR 5의 70전·수동 24전·초회 사용자 10명 결과가 같은 source SHA에서 끝난 뒤에만 한다.

| DAY | scenario | 결과 | 초 | 첫 교전 | 왕좌 피해 | 도난 | 무력화 초 | 후열 압박 초 | 2차 누수 | 종료 몬스터 HP | 실제 추가 지표·필수 실패 |
|---:|---|---|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1 | A | 승 | 51.88 | Z1 | 0 | 0 | 0 | 0 | 0 | 130 | 바리케이드 slow·임프 피해 발생 |
| 1 | B | 승 | 46.57 | Z2 | 0 | 0 | 0 | 0 | 0 | 358 | 병영 실제 기여 발생 |
| 1 | C | 패 | 62.28 | Z3 | 1500 | 0 | 0 | 0 | 0 | 0 | 왕좌 파괴 |
| 1 | D | 승 | 47.77 | Z2 | 0 | 0 | 0 | 0 | 0 | 334 | A 대비 임프 slot 1건 변경 |
| 2 | A | 승 | 57.50 | Z1 | 0 | 0 | 0 | 0 | 0 | 179 | 미끼 유인·고블린 도둑 피해 발생 |
| 2 | B | 승 | 52.13 | Z2 | 0 | 0 | 0 | 0 | 0 | 428 | 탐험가 Z2·도둑 Z3 교전 |
| 2 | C | 패 | 51.82 | Z1 | 0 | 100 | 0 | 0 | 0 | 362 | `protect_treasure` 실패 |
| 2 | D | 패 | 51.82 | Z1 | 0 | 100 | 0 | 0 | 0 | 362 | `protect_treasure` 실패, A 대비 임프 slot 1건 변경 |
| 3 | A | 승 | 58.60 | Z2 | 0 | 0 | 0 | 0 | 0 | 478 | 공병 집중 0.033초, 무력화 0초 |
| 3 | B | 승 | 62.27 | Z1 | 0 | 0 | 7.00 | 0 | 0 | 183 | 무력화 중 다른 시설 effect 발생 |
| 3 | C | 패 | 58.22 | Z1 | 0 | 0 | 7.00 | 0 | 0 | 312 | `keep_one_facility_active` 실패 |
| 3 | D | 패 | 64.32 | Z3 | 0 | 0 | 7.00 | 0 | 0 | 271 | 같은 필수 목표 실패, A 대비 임프 slot 1건 변경 |
| 4 | A | 승 | 65.45 | Z2 | 0 | 0 | 0 | 3.58 | 0 | 373 | 보호 무시 6.00초, 노출 중 임프→궁수 피해 88 |
| 4 | B | 승 | 64.22 | Z1 | 0 | 0 | 0 | 1.37 | 0 | 399 | 보호 무시 1.33초, 궁수 선격퇴 |
| 4 | C | 패 | 65.20 | Z1 | 0 | 0 | 0 | 6.83 | 0 | 371 | `break_rear_pressure` 실패 |
| 4 | D | 패 | 98.87 | Z3 | 1500 | 0 | 0 | 44.92 | 0 | 0 | 같은 필수 목표 실패, A 대비 임프 slot 1건 변경 |
| 5 | A | 승 | 83.17 | Z1 | 0 | 0 | 0 | 0 | 0 | 156 | 비상 후퇴 0.033초, 회복 20 |
| 5 | B | 승 | 83.17 | Z2 | 0 | 0 | 0 | 0 | 0 | 367 | 명령 0회, 탐험가 Z2·도둑 Z3 첫 교전 |
| 5 | C | 패 | 89.98 | Z1 | 0 | 100 | 0 | 0 | 0 | 390 | `stop_reinforcement_leaks` 실패 |
| 5 | D | 패 | 63.13 | Z1 | 1500 | 0 | 0 | 0 | 1 | 0 | 같은 필수 목표 실패, A 대비 임프 slot 1건 변경 |

각 대응의 `mechanism_assertions`는 아래와 같다.

| DAY | 대응 | `mechanism_assertions` |
|---:|---|---|
| 1 | A | `first_engagement_zone == gate_outpost && barricade.slowed_seconds > 0 && imp.enemy_damage > 0` |
| 1 | B | `first_engagement_zone == spike_corridor && any(barracks.bonus_damage > 0, barracks.damage_reduced > 0)` |
| 2 | A | `thief.goal_zone == central_battle_room && decoy.lured_count >= 1 && goblin.damage_to_thief > 0` |
| 2 | B | `decoy.installed == false && slime_or_imp.damage_to_explorer_in_spike_corridor > 0 && goblin.damage_to_thief_in_central_battle_room > 0` |
| 3 | A | `focus.target == engineer && focus.input_delay_from_targetable <= 1.0 && max_contiguous_facility_disabled_seconds <= 2.0 && any(focus.cast_interrupts >= 1, engineer.disable_started == false)` |
| 3 | B | `between(max_contiguous_facility_disabled_seconds, 6.5, 7.5) && other_facility.effect_seconds_during_disable > 0` |
| 4 | A | `watch.revealed_seconds_on_archer > 0 && imp.damage_to_archer_during_reveal > 0` |
| 4 | B | `focus.target == archer && focus.input_delay_from_spawn <= 1.0 && protection_bypass_seconds > 0 && archer.defeat_frame < first_shieldbearer.defeat_frame` |
| 5 | A | `fallback.input_delay_from_dash_telegraph <= 1.0 && fallback.target == throne_anteroom && recovery.healing_done > 0` |
| 5 | B | `command_uses == 0 && hero.defeat_zone == spike_corridor && reinforcement_explorer.first_engagement_zone == spike_corridor && reinforcement_thief.first_engagement_zone == central_battle_room` |

적이 combat 종료까지 쓰러지지 않았으면 `defeat_frame`은 비교에서 `+∞`로 취급한다.

각 대응은 실제 물리 전투 3 seed에서 `primary_success` 3/3, `secondary_success` 2/3 이상, 해당 행의 모든 `mechanism_assertions` 3/3을 요구한다. 하나라도 성립하지 않으면 그 DAY는 PASS가 아니다.

## 10. 검증 등급

| 등급 | 반드시 확인할 것 | 이 등급만으로 판정할 수 없는 것 |
|---|---|---|
| `AUTOMATED_CONTRACT_PASS` | schema, 참조, ID, 저장 왕복, 상태 전이, 동일 seed 결정론 | 실제 전투, 배치 재미, 밸런스 |
| `PHYSICAL_COMBAT_PASS` | 자연 spawn부터 이동·교전·피해·돌파·결과까지 x1 60 Hz 실제 물리 프레임 | 초회 이해도와 재미 |
| `MANUAL_PLAY_PASS` | 사람이 Windows와 Web에서 실제 입력으로 DAY 1~5 A/B 실행 | 초회 사용자 반응 |
| `FIRST_USER_PASS` | 초회 사용자 10명의 무설명 행동, 원문 답변과 5점 응답 | 자동 회귀 안정성 |
| `HYPOTHESIS_PASS` | 위 네 등급과 각 가설의 수치 기준을 같은 수용 SHA에서 모두 통과 | 해당 없음 |

다음 항목은 `HYPOTHESIS_PASS` 근거로 사용하지 않는다.

- 서비스가 출력한 `success: true`
- response tag, 문자열 ID, HUD 문구 존재
- 예상 전투 시간 또는 점수
- screenshot 한 장, console 오류 0건, build hash
- 자동 대리, 다중 seed 계산만 실행한 결과

세부 실행 수와 사용자 기준은 수용 프로토콜을 따른다.

## 11. 가설별 합격 기준

### 11.1 가설 1 — 진행이 간단하다

초회 사용자 10명 중 다음을 모두 만족한다.

- 8명 이상이 외부 도움 없이 90초 안에 첫 시설 또는 몬스터 배치를 완료한다.
- 8명 이상이 외부 도움 없이 `방어 시작`을 눌러 DAY 1 결과 화면에 도달한다.
- 7명 이상이 test-only 다음 DAY fixture 없이 30분 안에 DAY 1~5 결과 화면을 모두 본다. 패배 뒤 재도전 시간도 30분에 포함한다.
- 7명 이상이 session 종료 질문에서 `침입 확인 → 배치 → 방어 시작 → 전투 → 결과` 중 네 단계 이상을 순서대로 말한다.
- DAY 2~5의 배치 화면 체류 시간 중앙값이 DAY당 120초 이하다.
- crash, hard lock, 진행 불가와 기존 저장 변경은 0건이다.

### 11.2 가설 2 — 배치로 승리하는 재미가 있다

실제 물리와 초회 사용자 결과가 다음을 모두 만족한다.

- DAY 1~5 각각에서 대응 A와 B가 실제 물리 조건을 통과한다.
- 각 DAY의 A/D 비교가 7.5의 두 조건을 모두 만족한다.
- 초회 사용자 10명 중 7명 이상이 DAY 3까지 `시설 또는 몬스터`, `배치 구역`, `보인 이동·교전·피해·목표 변화`를 포함한 인과 문장을 자기 말로 설명한다.
- 7명 이상이 session 종료 질문에서 바꿀 배치 하나와 옮길 구역을 말하고 이전에 실제 재도전했거나, `배치를 바꿔 다시 싸워 보고 싶다`에 4~5점을 준다.
- 7명 이상이 `내 배치 때문에 결과가 달라졌다고 느꼈다`와 `배치를 바꿔 다시 싸워 보고 싶다` 두 문항 모두 4~5점을 준다.
- DAY 2~5 각각에서 서로 다른 두 대응 계열의 실제 성공 사례가 사용자 표본에 각각 1건 이상 있다.

게임이 결과 화면에 출력한 문장을 그대로 읽은 답변은 인과 설명 성공으로 세지 않는다.

### 11.3 가설 3 — 전투 밸런스가 맞다

- 70개 실제 물리 전투가 수용 프로토콜을 통과한다.
- 대응 A/B는 각 seed 3/3 primary 승리, secondary 2/3 이상을 달성한다.
- 오답 대조군 C는 seed 3/3에서 `primary_success == false`이고 수용 프로토콜 4.5의 DAY별 불이익도 만든다.
- DAY별 A/B 전투 시간 중앙값이 8절의 PASS 범위 안에 있고 개별 전투는 120초를 넘지 않는다.
- 초회 사용자 첫 시도 `full_objective_success`는 DAY 1 8~10명, DAY 2~4 각각 4~8명, DAY 5 3~7명이다. 한 번의 배치 수정 재도전까지 포함하면 DAY 2~5 각각 7명 이상이 `primary_success`를 완료한다.
- 같은 위치를 향해 이동해야 하는 유닛이 12초 동안 누적 4px 미만 이동하면 정체 실패로 기록한다.

## 12. 완료, 중단과 롤백

### 12.1 완료

아래가 모두 있어야 `DAY1_5_ACCEPTED`로 기록한다.

- 단일 공간 모델과 다섯 상태 흐름이 구현된 source SHA
- 자동 계약 결과
- 실제 물리 70전 원본과 요약
- 숙련 QA 공식 A/B 성공 20전과 선행 C 패배 4전, 총 24전 기록
- 초회 사용자 10명의 비식별 원본, 집계와 질문 답변 코딩 결과
- Windows와 Web 빌드 hash
- 세 가설 각각의 PASS 계산
- 기존 저장 hash 불변 결과

하나라도 없으면 `PENDING`이다. 기준 미달이면 `NO_GO`다.

### 12.2 즉시 중단

- `v1.2.1` 태그·Release·공개 루트 또는 기존 저장을 변경함
- 준비와 전투의 `zone_id`, slot 또는 좌표가 다름
- crash, hard lock, 결과 화면 미도달
- 12초 물리 정체가 재현됨
- 배치 A/D가 3 seed 모두 7.5의 두 조건을 만들지 못함
- 한 DAY에서 대응 A 또는 B가 3/3 primary 승리를 만들지 못함
- 초회 사용자 첫 3명이 연속으로 90초 안에 첫 배치를 하지 못함
- 같은 진행 차단이 초회 사용자 2명에게 재현됨

중단 뒤에는 다음 PR을 시작하지 않는다. 원인 소유 PR로 돌아가 수정하고, 변경된 기능 SHA에서 필요한 하위 등급부터 다시 실행한다.

### 12.3 롤백

- `git reset --hard`, 강제 푸시와 태그 이동을 사용하지 않는다.
- 마지막 승인 SHA 뒤의 문제 PR merge commit을 새 롤백 PR에서 `git revert -m 1`로 되돌린다.
- PR 1 공간 모델이 롤백되면 그 모델에 의존한 PR 2 이후도 역순으로 롤백한다.
- 기능, 데이터 또는 자산이 바뀌면 이전 물리·수동·초회 PASS는 무효다.
- 문서 오탈자만 바뀌고 수용 source tree와 build hash가 동일할 때만 기존 실행 증거를 유지한다.

## 13. 수용 패키지와 출시 이식 경계

수용 패키지는 다음을 SHA-256과 함께 고정한다.

- `release/v2.0` 수용 source SHA와 정확한 base SHA
- canonical 공간·흐름·시설·몬스터·Encounter·경제 데이터
- 실제로 사용된 함수와 데이터 key 목록
- 자동, 물리, 수동, 초회 사용자 결과
- 금지 파일과 기존 저장 hash
- Windows/Web build manifest
- 불변 `v1.2.1` tag object·peeled commit, Release 자산명·byte·SHA-256, PC·모바일 공개 Pages commit·PCK byte 수

수용 패키지를 만든 뒤에도 다음 작업은 하지 않는다.

- `release/v2.0 → main` PR
- `v2.0.0` 태그 또는 GitHub Release 생성
- DAY 6 이후 구현

새 `release/v2.0-product`에서는 수용 패키지에 이름이 있는 행동만 다시 구현한다. `release/v2.0` merge, merge commit cherry-pick, 범위 cherry-pick과 `git checkout release/v2.0 -- .`를 금지한다. 각 이식 PR은 `origin/main...HEAD` 변경 파일 allowlist와 함수·데이터 대응표를 남긴다.

출시선의 모든 PR과 L7 동결에서 아래 계보 검사를 실행한다.

1. `git merge-base <product-head> <accepted-v20-sha>`의 출력이 고정 기준 `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`와 정확히 같아야 한다.
2. `git rev-list 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..<accepted-v20-sha>`가 출력한 모든 commit에 대해 `git merge-base --is-ancestor <commit> <product-head>`가 실패해야 한다.
3. `git merge-base --is-ancestor c483d135b13cf9771ee43b045ba2c3dde51573ee <product-head>`는 성공해야 한다.
4. 각 PR diff는 그 PR의 수용 allowlist 밖 runtime 파일이 0개여야 한다.

1~3은 실험선 commit 계보가 섞이지 않았음을 검사하고, 4는 범위 복사·덮어쓰기를 차단한다. 하나라도 실패하면 해당 이식 PR을 병합하지 않는다.

이식된 구현은 기반과 통합 코드가 달라졌으므로 자동·물리·수동·초회 사용자 검증을 다시 통과해야 한다. 실험선의 PASS를 출시선의 PASS로 복사하지 않는다.

## 14. 변경 통제

이 계약의 수치, DAY 적 구성, 두 대응, 공간 ID, PASS 기준 또는 출시 이식 방식을 바꾸려면 코드 PR보다 먼저 docs 전용 PR을 병합한다. 대화 합의, issue 댓글 또는 구현 편의만으로 기준을 바꾸지 않는다.
