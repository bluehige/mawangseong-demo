# v1.2.2 V2-P1 Update 4 지역 적 runtime 정규화 감사

## 범위

- 대상 프로필 6개: `coal_spark`, `dusk_courier`, `bronze_automaton`, `shadow_duelist`, `spore_doll`, `root_tender`
- 목적: V1에서 만든 normalized sheet를 전투 `Unit`에 연결하고, 맵 타일 비례 크기와 이동 모드를 적용
- 금지: DAY 1~30 나머지 roster, V3 접지 root/body, V4 벽 가림·UI anchor, 오디오·VFX·빌드

## 크기 계약

- 기준 투영 타일은 `128×64`이며 화면 절대 픽셀 배율을 직접 저장하지 않는다.
- F0 코어 roster의 median 비투명 art 높이 `68.04px`에 일반 체격 목표 `1.15`를 곱해 normal 목표 `78.246px`을 만든다.
- `small / normal / large / boss`의 의도된 높이 비율은 V1 size class 값으로 계산한다. 이 패킷의 `bronze_automaton`·`root_tender`는 `large`다.
- 실제 sheet의 16개 셀 비투명 alpha bbox 중앙값을 측정값으로 사용해 `render_scale = 목표 art 높이 / 측정 중앙값`을 계산한다.
- `dusk_courier`는 데이터 `flying` 태그와 일치하는 `normal_flying` profile을 사용한다. 나머지 다섯 개는 grounded다.

## 연결 계약

- `data/v122/combat_visual_profiles.json`의 `unit_overrides`에 6개 asset ID, source/runtime 경로, `NORMALIZED_PASS`, size/motion profile, alpha bbox 중앙값을 고정했다.
- `DataRegistry.combat_visual_profile_for_unit()`은 등록되지 않은 ID에 공통 profile을 자동 상속하지 않고 빈 결과를 반환한다.
- `Unit.setup()`은 등록된 ID에만 normalized runtime path를 적용한다.
- `Unit._apply_visual_pose()`는 profile의 render scale과 foot anchor를 사용하고, 미등록 기존 roster는 기존 fallback 상수를 유지한다.

## 실행 및 결과

```powershell
godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualProfileContractTest.tscn
godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn
godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatPolishCapture.tscn --quit-after 20000
```

- V1-A profile schema test: `PASS`
- V2 runtime profile contract: `V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS`
- 비헤드리스 비교판: `V122_COMBAT_POLISH_CAPTURE: PASS records=44 image=(1280, 720)`
- 비교 이미지(무추적): `tmp/v122_release_polish/v2_p1/v2_p1_update4_runtime_contact_sheet_1280x720.png`

## Related tests

- `V122CombatVisualProfileContractTest.tscn`: PASS
- `V122CombatVisualRuntimeProfileContractTest.tscn`: PASS, 6개 경로·profile·배율·발 앵커·미등록 fallback 차단
- `git diff --check`: PASS

## UI check

`1280×720` OpenGL 비교판에서 6개 Update 4 자산이 normalized sheet로 그려지고, 기존 1254px 셀을 그대로 0.42배로 그리던 과대 표시가 사라졌는지 확인했다. normal 적은 코어 roster의 목표 art 높이 근처, large 적은 의도된 대형 등급으로 표시된다. 실제 DAY 전투 소유자 검수와 V3 발 흔들림 판정은 아직 남아 있다.

## Unresolved issues

- V2-P1은 Update 4 지역 적 6개만 연결했다. 전체 roster 누락 0은 남은 V2 패킷을 완료한 뒤 판정한다.
- alpha bbox 중앙값은 크기 기준용이며 발 위치·프레임별 흔들림의 최종 승인 값이 아니다. V3가 root/body와 발 anchor를 확정한다.
- 현재 작업 트리는 기존 사용자 변경과 V1/V2 변경이 혼합되어 있으며, 이번 패킷은 스테이징·커밋·푸시·출시 빌드를 하지 않았다.
