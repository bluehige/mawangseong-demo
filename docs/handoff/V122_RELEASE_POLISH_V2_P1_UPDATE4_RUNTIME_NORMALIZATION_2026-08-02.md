# v1.2.2 V2-P1 Update 4 지역 적 runtime 정규화 핸드오프

## 메타데이터

- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 범위: V2 첫 패킷, Update 4 지역 적 6개 runtime 연결·맵 비례 크기 정규화

## 구현 내용

- `combat_visual_profiles.json`에 `normalization_contract`와 Update 4 6개 `unit_overrides`를 추가했다.
- `DataRegistry.combat_visual_profile_for_unit()`이 profile·size class·motion mode·runtime path·render scale을 합성한다. 미등록 ID는 빈 결과로 남겨 공통값 자동 상속을 막는다.
- `Unit.setup()`이 6개 normalized sheet 경로를 사용하고, `Unit._apply_visual_pose()`가 profile render scale과 foot anchor를 적용한다. `dusk_courier`는 profile을 통해 flying으로 판정한다.
- 기존 6개 원본 PNG와 기존 경로는 보존했다. 이번 패킷은 자산을 다시 생성하지 않았다.

## 변경 파일 및 산출물

- 데이터: `data/v122/combat_visual_profiles.json`
- 연결 코드: `scripts/core/DataRegistry.gd`, `scripts/units/Unit.gd`
- 계약 테스트: `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`, `tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn`
- QA: `docs/qa/V122_V2_UPDATE4_RUNTIME_NORMALIZATION_2026-08-02.md`
- 비교 이미지(무추적): `tmp/v122_release_polish/v2_p1/v2_p1_update4_runtime_contact_sheet_1280x720.png`

## Related tests

- `V122CombatVisualProfileContractTest.tscn`: PASS
- `V122CombatVisualRuntimeProfileContractTest.tscn`: PASS
- `git diff --check`: PASS

## UI check

`1280×720` OpenGL 비교판에서 Update 4 6개가 normalized runtime path로 로드되고, normal/large/flying profile에 따른 크기·높이 배율이 적용되는 것을 확인했다. 실제 전투 흐름에서의 발 접지와 전면 벽 가림은 이번 패킷의 완료 조건이 아니다.

## Unresolved issues

- V2 전체 roster는 아직 미완료다. 다음 패킷은 DAY 1~5 핵심 아군 6개이며, 이후 일반 적·도둑과 나머지 roster를 순서대로 처리한다.
- V3에서 profile 발 anchor와 body/root를 분리하고 프레임별 발 흔들림 2px 계약을 검증해야 한다.
- 작업 트리는 기존 사용자 변경과 V1/V2 변경이 혼합되어 있으며, 이번 V2-P1은 스테이징·커밋·푸시하지 않았다.

## 다음 작업

V2-P2에서 DAY 1~5 핵심 아군 최대 6개만 같은 profile 계약에 추가한다. 공통 코드 결함이 발견되면 자산 추가를 중단하고 V2 보정 패킷으로 돌아간다.
