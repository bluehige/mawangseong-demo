# v1.2.2 V2-P2 핵심 아군·DAY12 1차 승급 정규화 QA

## 범위

이번 패킷은 계획표의 V2 순서 1번만 처리했다.

- DAY1~5 실제 핵심 방어 아군: `slime`, `goblin`, `imp`
- DAY12 첫 정식 승급 선택지: `slime_gate_bulwark`, `goblin_ambush_captain`, `imp_flame_adept`
- 기존 192×192 프레임은 다시 저장하거나 새로 생성하지 않았다.
- 일반 적·도둑, DAY6~30 roster, V3 접지 계층, V4 벽/UI, 오디오·VFX·빌드는 이번 패킷에서 제외했다.

## 구현 계약

`DataRegistry.combat_visual_profile_for_unit(unit_id, sprite_path)`가 등록된 종족의 기본 ID를 유지하면서, 해당 종족이 사용하는 승급 runtime 경로와 정확히 일치할 때만 승급 profile을 선택한다. 미등록 계약 몬스터가 기본 이미지를 재사용해도 다른 종족의 크기 profile을 상속하지 않는다.

측정 기준은 `median_nontransparent_cell_alpha_bbox_height_px`이며 F0 기준 중앙값 `68.04px`, 일반 목표 `68.04 × 1.15 = 78.246px`, 소형 목표 `78.246 × (0.72 / 0.95) = 59.302px`를 사용했다.

| ID | 중앙값(px) | profile | 동작 | 상태 전달 | map-relative render scale |
|---|---:|---|---|---|---:|
| `slime` | 118.5 | `small_grounded` | grounded | `NEEDS_NORMALIZATION` | 0.500 |
| `goblin` | 150.0 | `normal_grounded` | grounded | `NEEDS_NORMALIZATION` | 0.522 |
| `imp` | 143.5 | `small_flying` | flying | `NEEDS_NORMALIZATION` | 0.413 |
| `slime_gate_bulwark` | 152.0 | `normal_grounded` | grounded | `PASS` | 0.515 |
| `goblin_ambush_captain` | 149.0 | `normal_grounded` | grounded | `PASS` | 0.525 |
| `imp_flame_adept` | 159.0 | `normal_flying` | flying | `PASS` | 0.492 |

`PASS`와 `NEEDS_NORMALIZATION`은 이번 패킷에서 운반한 기존 inventory 상태다. 최종 `NORMALIZED_PASS` 또는 `FAIL_REGEN` 판정은 V3의 발·동작·root 계약 이후에만 확정한다.

## 변경 사항

- `data/v122/combat_visual_profiles.json`: 핵심 아군 3종과 1차 승급 3종의 source/runtime 경로, 알파 높이 중앙값, profile, 상태를 등록했다.
- `scripts/core/DataRegistry.gd`: 등록된 종족에 한해서만 sprite path 기반 승급 profile 선택을 허용하고, inventory 상태를 합성 profile에 전달한다.
- `scripts/units/Unit.gd`: stats의 sprite 경로를 lookup 입력으로 사용해 승급 runtime 경로가 기본 종족 profile로 덮어써지지 않게 했다.
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`: 핵심 아군·승급 6종, V2-P1 적 6종, 미등록 재사용 sprite fallback을 한 계약으로 고정했다.
- `tools/V122CombatAllyPacketCapture.gd`, `tools/V122CombatAllyPacketCapture.tscn`: 6개를 같은 1280×720 기준 화면에 배치하는 비헤드리스 비교판을 추가했다.

## 관련 검수

### Related tests

- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualProfileContractTest.tscn` → PASS
- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn` → PASS

### UI check

- `godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatAllyPacketCapture.tscn --quit-after 20000` → `V122_COMBAT_ALLY_PACKET_CAPTURE: PASS records=6 image=(1280, 720)`
- 실제 비교판: `tmp/v122_release_polish/v2_p2/v2_p2_core_ally_contact_sheet_1280x720.png`
- 매니페스트: `tmp/v122_release_polish/v2_p2/v2_p2_core_ally_capture_manifest.json`
- 화면에서 기본 3종은 소형/일반/소형 비행 등급으로, 승급 3종은 일반 등급으로 구분되고 각 셀의 profile·상태·측정값이 표시된다.

### Unresolved issues

- 기본 3종은 원본 192×192 프레임을 유지하므로 최종 픽셀 재생성·정규화는 V3 이후 결정한다.
- 모든 활성 roster의 크기 누락 0 판정은 V2-P3 이후다.
- 발 접촉 root·down 앵커·그림자·VFX/UI anchor는 V3/V4 범위다.
- 전체 회귀, 전체 플레이, 빌드, 커밋·푸시는 사용자 요청 범위가 아니어서 실행하지 않았다.
