# v1.2.2 정식 출시 마무리 순서 재시작 — F0 기준선 재조정 핸드오프

## 메타데이터

- 작성일: 2026-08-02
- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (V1-A~V1-D 변경은 미커밋)
- 작업 방식: 기존 변경 보존, 복구·삭제·커밋·푸시 없음

## 재시작 사유

Luna 계획의 정식 순서(`F0 → V1 → V2 → V3 → V4 → A0 → A1 → C1 → V5 ...`)와 실제 작업 기록(A0·A1·C1·V5 선행)이 어긋났다. 사용자는 기존 변경을 되돌리지 않고 계획의 처음부터 다시 점검하며, 혼선은 각 패킷에서 분리·수정하도록 결정했다.

## F0 재검증 결과

| 패킷 | 현재 근거 | 재검증 결과 | 판정 |
|---|---|---|---|
| F0-V | `tmp/v122_release_polish/f0_v/f0_v_inventory.json` | 활성 44개, 고유 경로 37개, `PASS 19 / NEEDS_NORMALIZATION 25 / DISCONNECTED 0`, 비행 불일치 2개, 정적 참조 누락 0개 | 정적 기준 PASS, 실제 캡처는 현재 headless dummy renderer에서 viewport texture empty로 실패 |
| F0-A | `tmp/v122_release_polish/f0_a/f0_a_inventory.json` 및 `build_inventory.py` | WAV 76개, Lyria 28개, procedural 48개, listening pending 76개. 기존 기록 54/12/10에서 현재 혼합 트리 재생성 결과 actual runtime 53/data-only 23/unconnected 0으로 변동 | 기준선 오염 발견, A1 변경이 정적 분류에 영향을 줌 |
| F0-R | `tmp/v122_release_polish/f0_r/f0_r_inventory.json` | Q1-S/I/L/P/R 공백 5개 유지, 모두 OWNER 또는 SOURCE gate 대기 | 목록 PASS, 다음 순서 문구는 V1로 정정 필요 |

## 확인한 꼬임과 수정 방향

- F0-A 문서의 최초 수치와 현재 혼합 트리 수치가 다르므로, 이후 A1 결과를 F0 baseline으로 사용하지 않는다.
- F0-V의 기존 캡처 파일은 현재 런타임 승인 근거로 재사용하지 않는다. 실제 화면 캡처는 별도 실행 환경에서 다시 확인한다.
- F0-R의 “다음 Q1” 연결은 계획표와 맞지 않아 `V1-A`로 정정한다. Q1은 A5 뒤의 출시 공백 페이즈다.
- A0·A1·C1·V5 변경은 삭제하지 않지만, 새 순서의 완료 게이트로 인정하지 않는다.

## 다음 작업

다음 구현 패킷은 `V2-P4 DAY 6~30 반복 노출 아군·적 6개 정규화`다. V1-A 계약·registry, V1-B capture·감사, V1-C/D 공통 전처리와 6개 시트, V2-P1 Update 4 runtime 연결, V2-P2 핵심 아군·첫 승급 6개 연결, V2-P3 일반 적·도둑 및 초기 일반 적 풀 6개 연결을 완료한 뒤 후보 자산 범위 게이트를 먼저 통과해야 한다. 현재 P4는 `SCOPE_BLOCKED`다.

1. V1-A 변경: `data/v122/combat_visual_profiles.json`, `DataRegistry` 연결, V1-A 전용 테스트가 이번 패킷에서 완료됐다.
2. V1-A 검증: `V122CombatVisualProfileContractTest.tscn` PASS, schema·누락 프로필·맵 비례 수치 검증 PASS
3. 금지 범위: 캐릭터 자산 교체, V2 크기 수정, V3 접지 구현, V4 벽/UI, 오디오·VFX·빌드
4. V1-B 변경: `tools/V122CombatPolishCapture.gd`, 전용 장면, `docs/qa/V122_COMBAT_VISUAL_NORMALIZATION_AUDIT.md`를 추가하고 런타임·원본 자산은 변경하지 않았다.
5. V1-B 검증: 비헤드리스 OpenGL 캡처 PASS, 헤드리스는 예상된 `CAPTURE_BLOCKED`; 44개 roster와 `1280×720` manifest/image 생성
6. V1-C 변경: `tools/prepare_v122_combat_runtime_sprites.py`와 normalized runtime sheet 3개, 출처·QA·핸드오프를 추가했다.
7. V1-C 검증: 생성과 `--check --packet v1-c` 결정론 검사 모두 PASS; `768×768` RGBA·192×192 셀 계약을 확인했다.
8. V1-D 변경·검증: 같은 변환 로직으로 나머지 3개를 처리하고 `--check --packet v1-d`를 PASS했다. V1-C/D manifest를 별도 보관한다.
9. V2-P1 변경·검증: Update 4 지역 적 6개에 normalized path·size/motion profile·map-relative render scale을 연결하고 계약 테스트·`1280×720` 비교판을 PASS했다.
10. V2-P2 변경·검증: DAY1~5 핵심 아군 3종과 DAY12 첫 승급 3종에 원본 프레임 중앙값 기반 profile·맵 비례 배율을 연결하고, 등록 종족 한정 승급 경로 선택·미등록 재사용 fallback·`1280×720` 비교판을 PASS했다.
11. V2-P3 변경·검증: DAY1~5 직접 등장 3종과 초기 일반 적 풀 3종에 원본 프레임 중앙값 기반 profile·맵 비례 배율을 연결하고, 전투 목표 경고가 자산 비교를 가리지 않는 비헤드리스 `1280×720` 비교판을 PASS했다.
12. V2-P4 후보 감사에서 `kobold_scout`가 원정·정찰 지원 전용이며 `1254×1254` 전체 불투명 원본임을 확인했다. 해당 임시 전투 profile·비교 도구를 제거했고, 실제 DAY6~30 방어 전투 ID와 `moon_tracker` 전투 원본 결정을 먼저 고정한다.
13. V2-P4 범위 게이트가 끝나기 전에는 Update 3/4 지역·보스·비행형, V3 접지, V4 벽/UI, 오디오·VFX·빌드를 시작하지 않음

## V1~V4 실제 상태 재분류 (2026-08-02)

F0 재검증 뒤 관련 파일과 최소 테스트를 다시 대조했다. 기존 시각 개편·통로·벽 핸드오프에 완료라고 적힌 항목이 있어도, 이번 출시 폴리시 계획의 V1~V4 계약을 충족하는지와는 별도로 판정한다.

| 페이즈 | 현재 파일 근거 | 현재 판정 | 다음 처리 |
|---|---|---|---|
| V1 맵 비례 스케일 계약 | `data/v122/combat_visual_profiles.json`, `DataRegistry` loader, V1-B capture/manifest, V1-C/D 공통 전처리 도구와 normalized sheet 6개가 존재함. | V1-A·V1-B·V1-C·V1-D 완료 | V2에서 normalized 경로를 runtime에 연결 |
| V2 전체 roster 크기 정규화 | `Unit.gd`에 Update 4 6개와 핵심 아군·첫 승급 6개, 일반 적·도둑 및 초기 풀 6개 profile·경로·배율이 연결됐다. P4 후보 감사에서 원정 지원용 opaque 자산 연결 위험을 발견해 임시 P4 등록은 제거했다. | V2-P1·V2-P2·V2-P3 완료, P4 범위 게이트 미완료 | 실제 DAY6~30 방어 전투 ID와 전투용 원본을 고정한 뒤 P4 재개 |
| V3 바닥 root·body·발 앵커 | `Unit.gd`에 sprite 위치·그림자·bob은 있으나 별도 ground root/body 계층이나 profile 기반 발 앵커 없음. | 부분 구현 | V2 최종값을 입력으로 공통 계층을 다시 설계 |
| V4 가림·UI 앵커 | `UnitYSortLayer`/`FrontWallLayer`/전면 wall canvas는 실제 런타임에 존재하고 관련 통로 테스트가 통과함. 반면 이름·HP·피해 숫자의 통합 anchor 계약 파일/테스트는 없음. | V4-A 부분 통과, V4-B 미구현 | V1~V3 이후 V4-A/B를 각각 계약화 |

재실행한 최소 테스트:

- `V122CombatVisualHierarchyTest.tscn`: PASS. 기존 정보량·draw 순서만 확인하며 V1 프로필·V3 root·V4-B anchor를 검증하지 않는다.
- `V122Stage01SpatialVisualRuntimeTest.tscn`: PASS. Stage 01 공간 자산·레이어 계약만 확인하며 전투 roster 정규화를 검증하지 않는다.
- `V122CorridorTopologyLayoutMatrixTest.tscn`: PASS. Stage 01~04 통로 topology·구조 벽·전면 wall layer를 확인하며 UI anchor를 검증하지 않는다.

따라서 위 PASS를 V1~V4 전체 완료로 승격하지 않는다.

## V1-A 패킷 결과

- 추가 파일: `data/v122/combat_visual_profiles.json`, `tools/tests/V122CombatVisualProfileContractTest.gd`, `tools/tests/V122CombatVisualProfileContractTest.tscn`
- 연결 파일: `scripts/core/DataRegistry.gd`가 catalog를 로드하고 기본·명시 프로필을 깊은 복사로 조회한다.
- 계약: 128×64 쿼터뷰 타일, 1280×720 기준 화면, small/normal/large/boss 4등급, grounded/flying 2모드, 8개 조합 프로필, 감사 상태와 발 흔들림 한도를 고정했다.
- 범위 준수: Unit·그래픽·벽·UI·오디오·VFX·빌드는 변경하지 않았다.
- 완료 판정: V1-A 전용 계약 테스트 PASS. V1-B capture·감사와 V1-C/D 전처리도 완료했으며, 다음은 V2 runtime 연결이다.

## V1-B 패킷 결과

- 추가 파일: `tools/V122CombatPolishCapture.gd`, `tools/V122CombatPolishCapture.tscn`, `docs/qa/V122_COMBAT_VISUAL_NORMALIZATION_AUDIT.md`
- 캡처 조건: F0-V inventory의 동일 ID 44개, `v122_cave_combat_visual_v1` profile, `1280×720`, 7열 deterministic contact sheet
- 비헤드리스 검증: `godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatPolishCapture.tscn --quit-after 20000` → `PASS records=44 image=(1280, 720)`
- 헤드리스 경계: `godot.cmd --headless --path . --scene res://tools/V122CombatPolishCapture.tscn --quit-after 15000` → `CAPTURE_BLOCKED records=44 image=(0, 0)` (dummy viewport가 비어 실제 비교판으로 승격하지 않음)
- 산출물: `tmp/v122_release_polish/v1_b/v1_b_combat_visual_contact_sheet_1280x720.png`, `tmp/v122_release_polish/v1_b/v1_b_capture_manifest.json`
- roster 결과: `PASS 19 / NEEDS_NORMALIZATION 25`, 크기 `192×192 28개 / 1254×1254 14개 / 768×768 2개`; 큰 단일 프레임 원본이 셀을 침범하는 현상은 V1-C/D·V2의 수정 근거로 남겼다.
- 완료 판정: V1-B 캡처·감사 게이트 PASS. V1-C/D 전처리와 V2 크기 수정·V3 접지·V4 UI는 별도 순서로 잠갔다.

## V1-C 패킷 결과

- 추가 파일: `tools/prepare_v122_combat_runtime_sprites.py`, `docs/qa/V122_V1_C_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 추가 자산: `assets/sprites/enemies/update4/region/normalized/enemy_coal_spark_sheet.png`, `enemy_dusk_courier_sheet.png`, `enemy_bronze_automaton_sheet.png`
- 출처 갱신: `assets/source/imagegen/update4_region_enemies/SOURCE.md`에 V1-C 후처리와 source/runtime 경로를 기록했다.
- 변환 계약: border-connected chroma 제거, 정수 4×4 crop, premultiplied LANCZOS, 768×768 RGBA sheet, 192×192 셀, alpha 모서리 0
- 검증: `python tools/prepare_v122_combat_runtime_sprites.py --packet v1-c` PASS, `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-c` PASS
- 범위 준수: 원본 PNG, 기존 runtime 경로, Unit·DataRegistry lookup, V1-D·V2·V3·V4는 변경하지 않았다.
- 완료 판정: V1-C 공통 도구·첫 3개 시트 게이트 PASS. V1-D에서 나머지 3개를 처리한 뒤 V2로 넘겼다.

## V1-D 패킷 결과

- 추가 파일: `docs/qa/V122_V1_D_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_V1_D_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 변경 도구: `tools/prepare_v122_combat_runtime_sprites.py`에 packet별 입력 묶음과 manifest 경로를 분리했다. chroma 제거·crop·resize 공통 로직은 V1-C와 동일하다.
- 추가 자산: `assets/sprites/enemies/update4/region/normalized/enemy_shadow_duelist_sheet.png`, `enemy_spore_doll_sheet.png`, `enemy_root_tender_sheet.png`
- 출처 갱신: `assets/source/imagegen/update4_region_enemies/SOURCE.md`에 V1-D 후처리와 source/runtime 경로를 기록했다.
- 변환 계약: border-connected chroma 제거, 정수 4×4 crop, premultiplied LANCZOS, 768×768 RGBA sheet, 192×192 셀, alpha 모서리 0
- 검증: `--packet v1-d` 생성과 `--check --packet v1-d` 결정론 검사가 PASS했다. `--check --packet v1-c`도 재실행해 기존 묶음이 보존됨을 확인했다.
- 범위 준수: 원본 PNG, 기존 runtime 경로, Unit·DataRegistry lookup, V2·V3·V4는 변경하지 않았다.
- 완료 판정: V1-C/D 6개 Update 4 sheet 전처리 게이트 PASS. 다음은 V2 runtime 연결·전체 크기 정규화다.

## V2-P1 패킷 결과

- 추가 파일: `docs/qa/V122_V2_UPDATE4_RUNTIME_NORMALIZATION_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_V2_P1_UPDATE4_RUNTIME_NORMALIZATION_2026-08-02.md`
- 변경 데이터: `data/v122/combat_visual_profiles.json`에 F0 중앙값 기반 `normalization_contract`와 Update 4 6개 `unit_overrides`를 추가했다.
- 변경 코드: `scripts/core/DataRegistry.gd`의 unit별 profile 합성, `scripts/units/Unit.gd`의 normalized path·profile scale·foot anchor·flying mode 연결
- 검증: `V122CombatVisualProfileContractTest.tscn` PASS, `V122CombatVisualRuntimeProfileContractTest.tscn` PASS, 비헤드리스 OpenGL `1280×720` 비교판 PASS
- 크기 기준: F0 core median art height `68.04px × 1.15`, normal target `78.246px`, large target은 V1 large/normal 비율 적용
- 범위 준수: Update 4 6개 외 roster, V3 접지, V4 벽/UI, 오디오·VFX·빌드는 변경하지 않았다.
- 완료 판정: V2-P1 완료. V2 전체 roster와 누락 0 판정은 아직 보류하며 다음은 V2-P2다.

## V2-P2 패킷 결과

- 추가 파일: `docs/qa/V122_V2_P2_CORE_ALLY_NORMALIZATION_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_V2_P2_CORE_ALLY_NORMALIZATION_2026-08-02.md`, `tools/V122CombatAllyPacketCapture.gd`, `tools/V122CombatAllyPacketCapture.tscn`
- 변경 데이터: `data/v122/combat_visual_profiles.json`에 DAY1~5 핵심 아군 3종과 DAY12 첫 승급 3종의 source/runtime 경로, 프레임 알파 높이 중앙값, profile, 상태를 추가했다.
- 변경 코드: `DataRegistry`는 등록된 종족에 한해서만 정확한 sprite path 기반 승급 profile을 선택하고 inventory 상태를 전달한다. `Unit`은 stats sprite 경로를 lookup에 전달해 승급 경로가 기본 종족 profile로 덮어써지지 않게 한다.
- 측정값: `slime 118.5`, `goblin 150.0`, `imp 143.5`, `slime_gate_bulwark 152.0`, `goblin_ambush_captain 149.0`, `imp_flame_adept 159.0` px. 일반 목표는 `78.246px`, 소형 목표는 `59.302px`다.
- 검증: `V122CombatVisualProfileContractTest.tscn` PASS, `V122CombatVisualRuntimeProfileContractTest.tscn` PASS, 비헤드리스 OpenGL `V122CombatAllyPacketCapture.tscn`에서 6개 기록·`1280×720` 비교판 PASS
- 범위 준수: 기존 192×192 프레임을 재생성·재저장하지 않았고 일반 적·도둑 이후 roster, V3 접지, V4 벽/UI, 오디오·VFX·빌드는 변경하지 않았다.
- 완료 판정: V2-P2 완료. V2 전체 roster와 누락 0 판정은 아직 보류하며 다음은 V2-P3 DAY1~5 일반 적과 도둑 6개다.

## V2-P3 패킷 결과

- 추가 파일: `docs/qa/V122_V2_P3_REGULAR_ENEMY_THIEF_NORMALIZATION_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_V2_P3_REGULAR_ENEMY_THIEF_NORMALIZATION_2026-08-02.md`, `tools/V122CombatRegularEnemyPacketCapture.gd`, `tools/V122CombatRegularEnemyPacketCapture.tscn`
- 변경 데이터: `data/v122/combat_visual_profiles.json`에 `explorer·thief·trainee_hero·investigator·shieldbearer·engineer` 6개 source/runtime 경로, 프레임 알파 높이 중앙값, `normal_grounded` profile, 상태를 추가했다.
- ID 근거: DAY1~5 wave/parity 직접 등장 3종과 초기 일반 적 풀 3종으로 고정했다. 지역 적·보스·Update 3/4 전용 적은 섞지 않았다.
- 검증: 두 visual profile 계약 테스트 PASS, 비헤드리스 OpenGL `V122CombatRegularEnemyPacketCapture.tscn`에서 6개 기록·`1280×720` 비교판 PASS
- 범위 준수: 게임 enemy goal/웨이브/스탯은 변경하지 않았고 비교판 복제 stats의 role만 `visual_audit`로 설정했다. 기존 프레임을 재생성·재저장하지 않았다.
- 완료 판정: V2-P3 완료. V2 전체 roster와 누락 0 판정은 아직 보류하며 다음은 V2-P4 DAY6~30 반복 노출 아군·적 6개다.

## V2-P4 범위 게이트 결과

- 추가 문서: `docs/qa/V122_V2_P4_RECURRING_ASSET_SCOPE_GATE_2026-08-02.md`, `docs/handoff/V122_RELEASE_POLISH_V2_P4_RECURRING_ASSET_SCOPE_GATE_2026-08-02.md`
- 확인: `kobold_scout` 원본은 `1254×1254` 전체 불투명 이미지이며, `data/campaign_days.json`은 로로를 방어전이 아닌 원정·정찰 지원으로 제한한다.
- 제거: 이번 세션에서 임시로 추가한 P4 6개 override, 잘못된 runtime 계약 기대값, opaque 후보 비교 도구.
- 부분 연결: `spore_healer·stone_sentinel·war_drummer·mimic_porter` 4개를 투명한 기존 원본 기반 profile로 연결하고 runtime 계약·`1280×720` 비교판을 PASS했다. 공유 원본 정체성은 승인하지 않았다.
- 판정: P4 `PARTIAL_PASS`(4/6)·전체 `SCOPE_BLOCKED`; opaque 후보 비교판은 시각 승인 자료가 아니다.
- 다음: `moon_tracker` 전투 원본과 공유 원본 정체성 결정을 고정한 뒤 P4를 재개하며, 그 전에는 다음 V2 패킷으로 이동하지 않는다.

## Related tests

- F0-V 정적 참조 경로 검사: PASS, 누락 0개
- F0-A inventory 재생성: PASS, 결과 수치 변동 기록
- F0-R JSON 구조·5개 record 확인: PASS
- 실제 `1280×720` F0-V 캡처: FAIL, 현재 headless dummy renderer의 빈 viewport texture
- `V122CombatVisualProfileContractTest.tscn`: PASS, V1-A schema·registry·비례 수치 계약
- `V122CombatPolishCapture.tscn`: 비헤드리스 PASS, 44개 roster·`1280×720` PNG/manifest 생성
- `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-c`: PASS, V1-C 3개 runtime sheet 해시·크기·alpha 계약
- `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-d`: PASS, V1-D 3개 runtime sheet 해시·크기·alpha 계약
- `python -m py_compile tools/prepare_v122_combat_runtime_sprites.py`: PASS
- `V122CombatVisualRuntimeProfileContractTest.tscn`: PASS, 핵심 아군·첫 승급 6개, V2-P1 적 6개, 미등록 재사용 sprite fallback의 path·profile·배율·발 앵커 계약
- 비헤드리스 `V122CombatPolishCapture.tscn`: PASS, 44개 roster·`1280×720` 비교판
- 비헤드리스 `V122CombatAllyPacketCapture.tscn`: PASS, 핵심 아군·첫 승급 6개·`1280×720` 비교판
- 비헤드리스 `V122CombatRegularEnemyPacketCapture.tscn`: PASS, DAY1~5 직접 등장·초기 일반 적 풀 6개·`1280×720` 비교판

## UI check

V1-B 비교판을 `1280×720` 비헤드리스 OpenGL 실행으로 확인했고, V1-C/D normalized sheet 6개를 원본 해상도로 확인했다. V1-C/D 출력은 192×192 셀과 투명 배경을 갖지만 게임 런타임에는 아직 연결하지 않았다.

## Unresolved issues

- F0-A 최초 baseline 54/12/10과 혼합 트리 재생성 53/23/0의 차이를 A1 변경과 분리해 추적해야 한다.
- V1-B에서 25개가 `NEEDS_NORMALIZATION`으로 남았다. 실제 원본 교체·시트 전처리·Unit 런타임 정규화는 V1-C/D와 V2에서만 진행한다.
- 헤드리스에서는 viewport texture가 비어 실제 화면 승인 근거로 사용할 수 없다. 동일 비헤드리스 실행을 사용자 화면 검수에 사용해야 한다.
- V1-D까지 6개 시트 전처리와 V2-P1·V2-P2·V2-P3 runtime lookup 연결은 끝났지만, V2-P4 범위 게이트가 막혀 전체 roster 크기 비교·누락 0은 판정하지 않았다.
- 현재 브랜치에는 기존 미커밋 변경과 이번 V1-A/B/C/D·V2-P1 변경이 함께 있으므로 커밋·스테이징 없이 다음 패킷의 허용 파일을 별도로 유지한다.
