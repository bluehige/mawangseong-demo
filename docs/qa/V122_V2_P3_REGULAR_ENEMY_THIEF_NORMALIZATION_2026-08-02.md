# v1.2.2 V2-P3 일반 적·도둑 및 초기 일반 적 풀 정규화 QA

## 범위와 ID 선정 근거

계획의 V2-P3 고정 상한은 profile 6개다. `data/waves.json`과 `tools/fixtures/v122/day01_05_parity.json`을 대조한 결과 DAY1~5에 직접 등장하는 고유 적은 `explorer`, `thief`, `trainee_hero` 3종이었다. 나머지 3개 슬롯은 임의의 지역 적이나 보스를 섞지 않고, `data/enemies.json`의 초기 일반 적 풀에서 바로 이어지는 `investigator`, `shieldbearer`, `engineer`로 채웠다.

- 직접 DAY1~5: `explorer`, `thief`, `trainee_hero`
- 초기 일반 적 풀: `investigator`, `shieldbearer`, `engineer`
- 이번 패킷에서 지역 적·보스·Update 3/4 전용 적은 다루지 않았다.
- 기존 192×192 프레임은 다시 저장하거나 새로 생성하지 않았다.

## 구현 계약

모든 대상은 `normal_grounded` profile을 사용하고 F0 기준 중앙값 `68.04px × 1.15 = 78.246px`을 목표로 맵 비례 배율을 계산했다. 상태 `PASS`는 기존 F0 visual inventory 상태를 운반한 값이며, 최종 `NORMALIZED_PASS` 확정은 V3 발·동작·root 계약 이후에만 한다.

| ID | 프레임 알파 높이 중앙값(px) | render scale | runtime 경로 |
|---|---:|---:|---|
| `explorer` | 160.0 | 0.489 | `enemy_explorer_idle_down_00.png` |
| `thief` | 140.0 | 0.559 | `enemy_thief_idle_down_00.png` |
| `trainee_hero` | 161.5 | 0.484 | `enemy_trainee_hero_idle_down_00.png` |
| `investigator` | 166.0 | 0.471 | `enemy_investigator_idle_down_00.png` |
| `shieldbearer` | 147.0 | 0.532 | `enemy_shieldbearer_idle_down_00.png` |
| `engineer` | 152.5 | 0.513 | `enemy_engineer_idle_down_00.png` |

## 변경 사항

- `data/v122/combat_visual_profiles.json`: 6개 enemy override에 source/runtime 경로, 중앙값, `normal_grounded`, 상태를 등록했다.
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`: P3 6개를 포함해 P2 아군·승급, P1 Update4 적, 미등록 fallback을 함께 검증한다.
- `tools/V122CombatRegularEnemyPacketCapture.gd`, `tools/V122CombatRegularEnemyPacketCapture.tscn`: 6개를 같은 1280×720 기준 화면에 배치한다. 비교판은 경고 배지가 자산을 가리지 않도록 복제 stats의 `role`만 `visual_audit`로 바꾸며, 게임 데이터는 변경하지 않는다.

## Related tests

- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn` → PASS
- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualProfileContractTest.tscn` → PASS

## UI check

- `godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatRegularEnemyPacketCapture.tscn --quit-after 20000` → `V122_COMBAT_REGULAR_ENEMY_CAPTURE: PASS records=6 image=(1280, 720)`
- 실제 비교판: `tmp/v122_release_polish/v2_p3/v2_p3_regular_enemy_contact_sheet_1280x720.png`
- 매니페스트: `tmp/v122_release_polish/v2_p3/v2_p3_regular_enemy_capture_manifest.json`
- 6개 모두 같은 일반 grounded 기준으로 표시되며 각 셀에 중앙값·목표·배율이 표시된다.

## Unresolved issues

- 이 패킷은 크기·경로·알파 상태만 다뤘다. 발 접촉 root·down 앵커·그림자·VFX/UI anchor는 V3/V4 범위다.
- DAY6~30 반복 노출 roster, Update 3, 대형·보스·비행형은 다음 V2 패킷 이후다.
- 전체 회귀, 전체 플레이, 빌드, 커밋·푸시는 사용자 요청 범위가 아니어서 실행하지 않았다.
