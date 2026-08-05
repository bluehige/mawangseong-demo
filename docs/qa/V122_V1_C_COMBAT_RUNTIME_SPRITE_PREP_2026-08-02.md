# v1.2.2 V1-C Update 4 전투 시트 전처리 감사

## 범위

- 대상: `coal_spark`, `dusk_courier`, `bronze_automaton` 3개
- 입력: `assets/source/imagegen/update4_region_enemies/`의 승인 원본 1254×1254 4×4 sheet
- 출력: `assets/sprites/enemies/update4/region/normalized/`의 768×768 RGBA 4×4 sheet
- 금지: V1-D 나머지 3개, Unit/DataRegistry lookup 연결, V2 크기·V3 접지·V4 가림/UI 수정

## 변환 계약

- border-connected magenta 배경만 제거해 캐릭터 내부의 고립된 색상은 보존한다.
- 원본 4×4 경계는 `round(column * 1254 / 4)` 규칙으로 자른다.
- 각 셀을 premultiplied LANCZOS로 `192×192`에 맞추고, 네 모서리 alpha 0·빈 셀 없음·RGBA를 검사한다.
- 결과 sheet는 런타임 lookup에 아직 연결하지 않는다. V2가 최종 profile·경로 승격을 소유한다.

## 실행 및 결과

```powershell
python tools/prepare_v122_combat_runtime_sprites.py
python tools/prepare_v122_combat_runtime_sprites.py --check
```

- 생성: `V122_COMBAT_RUNTIME_SPRITE_PREP: PASS records=3`
- 결정론 검사: `V122_COMBAT_RUNTIME_SPRITE_PREP: PASS records=3`
- manifest: `tmp/v122_release_polish/v1_c/v1_c_runtime_sprite_manifest.json`
- 출력: `assets/sprites/enemies/update4/region/normalized/enemy_{coal_spark,dusk_courier,bronze_automaton}_sheet.png`

## Related tests

- `python tools/prepare_v122_combat_runtime_sprites.py`: PASS, 3개 sheet 생성
- `python tools/prepare_v122_combat_runtime_sprites.py --check`: PASS, 해시·크기·alpha 계약 재현

## UI check

세 출력 sheet를 원본 해상도로 확인했다. 보라색 chroma 배경은 제거되고 각 프레임이 투명 192×192 셀 안에 들어온다. 아직 게임 런타임에 연결하지 않았으므로 실제 전투 화면 검수는 V2 이후에 수행한다.

## Unresolved issues

- `shadow_duelist`, `spore_doll`, `root_tender`는 V1-D에서 같은 도구로 처리해야 한다.
- 일부 생성 원본의 가장자리 색 번짐은 V2/V3 비교판에서 확인하며, `FAIL_REGEN` 판정 없이 임의 재생성하지 않는다.
- `dusk_courier` 데이터 비행 태그와 현재 Unit 하드코딩은 별도 런타임 계약에서 결정한다.
