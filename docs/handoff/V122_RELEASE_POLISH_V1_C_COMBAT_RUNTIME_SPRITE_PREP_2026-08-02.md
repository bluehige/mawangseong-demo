# v1.2.2 V1-C Update 4 전투 시트 전처리 핸드오프

## 메타데이터

- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 범위: V1-C 첫 3개 Update 4 시트의 결정론 전처리

## 구현 내용

- `tools/prepare_v122_combat_runtime_sprites.py`를 추가했다.
- `coal_spark`, `dusk_courier`, `bronze_automaton`을 1254×1254 4×4 chroma 원본에서 768×768 RGBA sheet로 변환했다.
- 각 셀은 192×192 정수 크기이며, border-connected chroma 제거·premultiplied resize·alpha 모서리 검사를 거친다.
- 원본 PNG와 기존 runtime 경로는 보존하고, 새 normalized 경로는 V2 전까지 게임 lookup에 연결하지 않았다.

## 변경 파일 및 산출물

- 도구: `tools/prepare_v122_combat_runtime_sprites.py`
- 출력 자산: `assets/sprites/enemies/update4/region/normalized/enemy_coal_spark_sheet.png`, `enemy_dusk_courier_sheet.png`, `enemy_bronze_automaton_sheet.png`
- 출처 기록: `assets/source/imagegen/update4_region_enemies/SOURCE.md`
- QA: `docs/qa/V122_V1_C_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 기계 manifest(무추적): `tmp/v122_release_polish/v1_c/v1_c_runtime_sprite_manifest.json`

## Related tests

- `python tools/prepare_v122_combat_runtime_sprites.py`: PASS
- `python tools/prepare_v122_combat_runtime_sprites.py --check`: PASS
- V1-A `V122CombatVisualProfileContractTest.tscn`: PASS

## UI check

세 normalized sheet를 원본 해상도로 확인했다. 마젠타 배경은 투명해졌고 192×192 셀 경계가 맞는다. 실제 전투 화면 연결은 의도적으로 보류했다.

## Unresolved issues

- V1-D에서 남은 3개 sheet를 처리해야 V1 시트 전처리가 완료된다.
- V2에서만 normalized 경로를 profile·Unit lookup에 연결하고 전체 roster 크기를 다시 비교한다.
- 원본 가장자리 색 번짐과 `dusk_courier` 비행 태그는 V2/V3 계약에서 별도 판정한다.
- 작업 트리는 기존 사용자 변경 및 V1-A/B 변경과 혼합되어 있으며, 이번 V1-C는 스테이징·커밋·푸시하지 않았다.

## 다음 작업

V1-D에서 도구를 변경하지 않고 `shadow_duelist`, `spore_doll`, `root_tender` 3개만 같은 방식으로 처리한다. V1-D 완료 전에는 V2·V3·V4를 시작하지 않는다.
