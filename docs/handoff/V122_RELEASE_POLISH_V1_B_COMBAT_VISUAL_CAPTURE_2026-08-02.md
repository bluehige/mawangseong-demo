# v1.2.2 V1-B 전투 시각 비교판·감사 핸드오프

## 메타데이터

- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 작업 범위: V1-B 캡처 도구·감사 문서만 추가

## 구현 내용

- F0-V inventory의 동일 ID 44개를 `v122_cave_combat_visual_v1` profile과 함께 deterministic 7열 contact sheet로 배치했다.
- `1280×720` 비헤드리스 OpenGL 실행에서 PNG와 JSON manifest를 생성했다.
- 헤드리스 dummy renderer는 viewport texture가 비어 있으므로 `CAPTURE_BLOCKED`로 기록하며 성공으로 우회하지 않는다.
- Unit·전투 런타임·원본 그래픽·오디오·VFX·빌드는 변경하지 않았다.

## 산출물

- 도구: `tools/V122CombatPolishCapture.gd`, `tools/V122CombatPolishCapture.tscn`
- 감사 문서: `docs/qa/V122_COMBAT_VISUAL_NORMALIZATION_AUDIT.md`
- 실행 산출물(소스 브랜치 미추적): `tmp/v122_release_polish/v1_b/v1_b_combat_visual_contact_sheet_1280x720.png`
- 실행 산출물(소스 브랜치 미추적): `tmp/v122_release_polish/v1_b/v1_b_capture_manifest.json`

## 검증 결과

### Related tests

- `godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatPolishCapture.tscn --quit-after 20000`: PASS, 44개·`1280×720` PNG 생성
- `godot.cmd --headless --path . --scene res://tools/V122CombatPolishCapture.tscn --quit-after 15000`: 예상된 `CAPTURE_BLOCKED`, 44개 manifest 기록
- V1-A `V122CombatVisualProfileContractTest.tscn`: PASS

### UI check

생성된 contact sheet를 `1280×720` 원본 해상도로 확인했다. `PASS 19 / NEEDS_NORMALIZATION 25`가 표시되며 1254×1254 단일 프레임 원본이 셀 경계를 넘는 현상이 감사판에서 재현된다.

### Unresolved issues

- 25개 자산의 시트·프레임·크기 정규화는 V1-C/D와 V2 범위이며 이 패킷에서 수정하지 않는다.
- `imp`와 `dusk_courier`의 데이터/런타임 비행 판정 차이는 F0-V 기록을 유지하며 별도 결정이 필요하다.
- 헤드리스 viewport는 비어 있으므로 실제 화면 승인에는 비헤드리스 OpenGL 실행이 필요하다.
- 작업 트리는 기존 오디오/UI 등 미커밋 변경과 V1-A/V1-B 변경이 혼합된 상태이며, 이번 패킷은 스테이징·커밋·푸시하지 않았다.

## 다음 작업

V1-C에서 Update 4 지역 적 시트 최대 3개를 처리하는 결정론적 전처리 도구와 계약 테스트를 만든다. V1-C가 통과하기 전에는 V1-D·V2·V3·V4를 시작하지 않는다.
