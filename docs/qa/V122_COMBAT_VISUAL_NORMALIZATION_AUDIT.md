# v1.2.2 V1-B 전투 시각 정규화 캡처·감사

## 범위

- 대상: F0-V가 고정한 활성 전투 roster 44개
- 목적: V1-A 프로필을 사용해 같은 ID 순서·1280×720 캔버스·고정 격자 조건의 비교판을 재현하고, V2 크기 정규화 전에 현재 상태를 분리 기록
- 금지: 런타임 Unit 코드, 그래픽 원본·import, 벽·UI·오디오·VFX·빌드 변경
- 출력 위치: `tmp/v122_release_polish/v1_b/` (소스 브랜치에 커밋하지 않음)

## 캡처 계약

| 항목 | 고정값 |
|---|---|
| 프로필 | `v122_cave_combat_visual_v1` |
| 기준 화면 | `1280×720` |
| 입력 목록 | `tmp/v122_release_polish/f0_v/f0_v_inventory.json` |
| 셀 배치 | 7열, 셀 `182×90`, 원점 `(94,88)` |
| 자산 처리 | 원본 경로를 그대로 로드, 크기·프레임 재생성 없음 |
| 판정 분리 | F0 상태(`PASS/NEEDS_NORMALIZATION/DISCONNECTED`)와 V1-B 캡처 상태를 별도 기록 |

## 실행

```powershell
godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatPolishCapture.tscn --quit-after 20000
godot.cmd --headless --path . --scene res://tools/V122CombatPolishCapture.tscn --quit-after 15000
```

실제 화면 비교판은 headless가 아닌 `1280×720` 실행 환경에서 같은 장면을 실행해야 한다. headless renderer가 빈 viewport를 반환하면 캡처 실패를 PASS로 바꾸지 않고 `CAPTURE_BLOCKED`로 기록한다.

## 결과

- 비헤드리스 실행 결과: `PASS records=44 image=(1280, 720)`
- 헤드리스 실행 결과: `CAPTURE_BLOCKED records=44 image=(0, 0)` (dummy viewport texture empty)
- 이미지: `tmp/v122_release_polish/v1_b/v1_b_combat_visual_contact_sheet_1280x720.png`
- manifest: `tmp/v122_release_polish/v1_b/v1_b_capture_manifest.json`
- roster 결과: `PASS 19 / NEEDS_NORMALIZATION 25`; 원본 크기 `192×192 28개 / 1254×1254 14개 / 768×768 2개`
- V2 승격 여부: 이 문서의 캡처만으로 크기 정규화 완료를 선언하지 않음. V1-C/D와 V2에서 실제 비례값·발 앵커를 확정한다.

## Related tests

- V1-A `V122CombatVisualProfileContractTest.tscn`: PASS
- V1-B `V122CombatPolishCapture.tscn`: 비헤드리스 PASS, 헤드리스 `CAPTURE_BLOCKED` 경계 확인

## UI check

`1280×720` 실제 화면 비교판을 비헤드리스 OpenGL로 생성하고 원본 해상도로 확인했다. 일부 1254×1254 단일 프레임 자산이 셀 경계를 넘어서는 현상은 정상화 전 감사 결과로 남겼다.

## Unresolved issues

- 헤드리스 dummy renderer에서는 viewport texture가 비어 실제 비교판으로 사용할 수 없다. 사용자 화면 확인에는 비헤드리스 OpenGL 실행이 필요하다.
- F0 상태가 `NEEDS_NORMALIZATION`인 25개 자산의 교체·전처리는 V1-C/D 이후에만 진행한다.
