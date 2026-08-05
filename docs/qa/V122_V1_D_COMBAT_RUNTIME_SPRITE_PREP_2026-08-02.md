# v1.2.2 V1-D Update 4 전투 시트 전처리 감사

## 범위

- 대상: `shadow_duelist`, `spore_doll`, `root_tender` 3개
- 입력: `assets/source/imagegen/update4_region_enemies/`의 승인 원본 1254×1254 4×4 sheet
- 출력: `assets/sprites/enemies/update4/region/normalized/`의 768×768 RGBA 4×4 sheet
- 금지: V2 profile·Unit lookup 연결, V2 크기 정규화, V3 접지, V4 가림/UI, 오디오·VFX·빌드

## 변환 계약

- V1-C에서 만든 공통 도구의 변환 로직을 유지하고, V1-D는 나머지 3개만 처리한다.
- border-connected magenta 배경을 제거하고 원본 4×4 경계를 `round(column * 1254 / 4)` 규칙으로 자른다.
- 각 셀을 premultiplied LANCZOS로 `192×192`에 맞춘다. 결과는 RGBA `768×768` sheet이며 모든 셀은 빈 셀이 아니고 네 모서리 alpha가 0이다.
- V1-C와 V1-D manifest를 별도 보관해 한 묶음이 다른 묶음의 검증 기록을 덮어쓰지 않게 한다.

## 실행 및 결과

```powershell
python tools/prepare_v122_combat_runtime_sprites.py --packet v1-c
python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-c
python tools/prepare_v122_combat_runtime_sprites.py --packet v1-d
python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-d
```

- V1-C 재생성 및 검증: `PASS packet=V1-C records=3`
- V1-D 생성: `PASS packet=V1-D records=3`
- V1-D 결정론 검사: `PASS packet=V1-D records=3`
- V1-C manifest: `tmp/v122_release_polish/v1_c/v1_c_runtime_sprite_manifest.json`
- V1-D manifest: `tmp/v122_release_polish/v1_d/v1_d_runtime_sprite_manifest.json`
- 출력: `enemy_shadow_duelist_sheet.png`, `enemy_spore_doll_sheet.png`, `enemy_root_tender_sheet.png`

## Related tests

- `python tools/prepare_v122_combat_runtime_sprites.py --packet v1-d`: PASS, 3개 sheet 생성
- `python tools/prepare_v122_combat_runtime_sprites.py --check --packet v1-d`: PASS, source/runtime 해시·크기·alpha 계약 재현
- V1-C `--check --packet v1-c`: PASS, 묶음 manifest 분리 후 기존 3개 결과 보존
- `python -m py_compile tools/prepare_v122_combat_runtime_sprites.py`: PASS

## UI check

세 V1-D normalized sheet를 원본 해상도로 확인했다. 세 시트 모두 투명 배경, 4×4 정수 셀, 캐릭터 프레임을 확인했다. 아직 게임 runtime lookup에는 연결하지 않았으므로 실제 전투 화면 승인 검수는 V2 이후로 남긴다.

## Unresolved issues

- V1-D는 자산 전처리만 완료했으며 V2에서 6개 normalized 경로를 profile·Unit lookup에 연결해야 한다.
- 원본 가장자리 색 번짐과 캐릭터별 실제 맵 비례 크기·발 위치는 V2/V3 비교판에서 판정한다. 이 단계에서 임의 재생성하지 않는다.
- 작업 트리는 기존 사용자 변경과 V1-A/B/C/D 변경이 혼합되어 있으며, 이번 패킷은 스테이징·커밋·푸시하지 않았다.
