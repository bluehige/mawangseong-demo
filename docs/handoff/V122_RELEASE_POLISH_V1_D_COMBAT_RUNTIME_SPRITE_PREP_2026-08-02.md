# v1.2.2 V1-D Update 4 전투 시트 전처리 핸드오프

## 메타데이터

- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 범위: V1-D 나머지 3개 Update 4 시트의 결정론 전처리

## 구현 내용

- V1-C 공통 도구에 `v1-c`·`v1-d` packet 선택과 별도 manifest 경로만 추가했다. chroma 제거·crop·resize 변환 규칙은 유지했다.
- `shadow_duelist`, `spore_doll`, `root_tender`를 1254×1254 4×4 chroma 원본에서 768×768 RGBA sheet로 변환했다.
- 각 셀은 192×192 정수 크기이며 border-connected chroma 제거·premultiplied resize·alpha 모서리 검사를 거친다.
- 원본 PNG와 기존 runtime 경로는 보존하고, normalized 경로는 V2 전까지 게임 lookup에 연결하지 않았다.

## 변경 파일 및 산출물

- 도구: `tools/prepare_v122_combat_runtime_sprites.py`
- 출력 자산: `assets/sprites/enemies/update4/region/normalized/enemy_shadow_duelist_sheet.png`, `enemy_spore_doll_sheet.png`, `enemy_root_tender_sheet.png`
- 출처 기록: `assets/source/imagegen/update4_region_enemies/SOURCE.md`
- QA: `docs/qa/V122_V1_D_COMBAT_RUNTIME_SPRITE_PREP_2026-08-02.md`
- 기계 manifest(무추적): `tmp/v122_release_polish/v1_d/v1_d_runtime_sprite_manifest.json`

## Related tests

- `python tools/prepare_v122_combat_runtime_sprites.py --packet v1-d`: PASS
- `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-d`: PASS
- `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-c`: PASS
- `python -m py_compile tools/prepare_v122_combat_runtime_sprites.py`: PASS

## UI check

세 V1-D normalized sheet를 원본 해상도로 확인했다. 마젠타 배경은 투명해졌고 192×192 셀 경계가 맞는다. 실제 전투 화면 연결은 의도적으로 보류했다.

## Unresolved issues

- V2에서 6개 normalized 경로를 profile·Unit lookup에 연결하고 전체 roster 크기를 다시 비교해야 한다.
- 원본 가장자리 색 번짐과 `dusk_courier` 비행 태그는 V2/V3 계약에서 별도 판정한다.
- 작업 트리는 기존 사용자 변경 및 V1-A/B/C/D 변경과 혼합되어 있으며, 이번 V1-D는 스테이징·커밋·푸시하지 않았다.

## 다음 작업

V2에서 최대 6개 프로필 단위로 normalized 자산과 맵 비례 크기 계약을 런타임에 연결한다. V1-D 범위 밖의 접지·가림·UI·오디오·VFX·빌드는 다음 페이즈 소유로 유지한다.
