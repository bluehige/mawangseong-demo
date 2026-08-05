# v1.2.2 V2-P4 반복 노출 자산 범위 게이트

## 판정

`V2-P4 DAY6~30 반복 노출 아군·적 6개 정규화`는 이번 실행에서 완료 처리하지 않는다. 후보를 런타임 profile에 등록하기 전에 자산의 실제 전투 사용 여부와 투명 영역을 확인했으며, 코볼트 척후대장 `kobold_scout`가 전투 자산이 아니라 원정·정찰 지원 자산이라는 충돌을 확인했다.

이번 패킷의 전체 상태는 `SCOPE_BLOCKED`이며, 투명한 기존 전투 원본을 가진 4개 후보만 부분 연결했다. P1~P3의 유효한 변경은 그대로 보존한다.

## 확인한 원인

- `assets/sprites/monsters/monster_kobold_scout_idle_down_00.png`는 `1254×1254`이고 알파 최솟값과 최댓값이 모두 `255`다. 즉 전체 이미지가 불투명하며, 알파 bbox도 전체 이미지다.
- `data/monsters.json`의 `kobold_scout`는 `원정대장 / 교란 보조`, `raid_role: expedition_captain`으로 정의돼 있다.
- `data/campaign_days.json`은 DAY8·DAY11·DAY12 등에서 로로를 방어전에 배치하지 않고 원정·정찰 지원으로 제한한다. DAY8에는 방어 애니메이션 자산이 부족하므로 raid/scout support를 유지한다는 결정이 고정돼 있다.
- 같은 이미지를 쓰는 `moon_tracker`까지 전투 profile에 연결하면, 투명한 전투 캐릭터가 아니라 불투명한 대형 정사각형을 전투 화면에 넣게 된다. 실제 비교판에서 작은 어두운 사각형으로 보이는 현상을 확인했다.

따라서 원본 크기만 줄이거나 기존 다른 캐릭터의 그림을 임시로 재사용하는 것은 이번 문제를 해결하지 않는다. `kobold_scout`는 전투 roster 후보에서 제외하고, `moon_tracker`는 별도의 전투용 원본/런타임 자산 결정 없이는 등록하지 않는다.

## 후보 분류표

| ID | 실제 역할·노출 | 원본 상태 | P4 판정 |
|---|---|---|---|
| `spore_healer` | 계약 아군·방어 전투 사용 | 슬라임 192×192 투명 | 등록 가능 후보 |
| `stone_sentinel` | 계약 아군·방어 전투 사용 | 슬라임 192×192 투명 | 등록 가능 후보 |
| `war_drummer` | 계약 아군·방어 전투 사용 | 고블린 192×192 투명 | 등록 가능 후보 |
| `mimic_porter` | 계약 아군·방어 전투 사용 | 고블린 192×192 투명 | 등록 가능 후보 |
| `moon_tracker` | 계약 아군·방어 전투 사용 | 코볼트 지원 원본 1254×1254 불투명 | 전용 전투 원본 결정 전 보류 |
| `kobold_scout` | 원정대장·정찰 지원, 방어 배치 제한 | 1254×1254 전체 불투명 | 전투 profile에서 제외 |

즉 P4는 네 개의 투명 후보를 연결할 수 있지만, 고정 6개를 채우려고 `moon_tracker`나 `kobold_scout`를 억지로 포함하지 않는다. 네 후보는 아래 부분 소패킷에서 profile을 등록했고, 두 ID의 자산 결정 전에는 P4 전체 완료를 선언하지 않는다.

## 되돌린 잘못된 연결

- `data/v122/combat_visual_profiles.json`에 임시로 넣었던 P4 후보 6개 override를 제거했다.
- 같은 파일에 투명한 기존 원본을 가진 4개 계약 아군의 P4 profile을 등록했다.
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`의 P4 후보 기대값을 제거했다.
- 같은 테스트에 네 계약 아군의 path·profile·배율 기대값을 추가했다.
- `tools/V122CombatRecurringAllyPacketCapture.gd`와 `.tscn` 비교 도구를 제거했다.
- `tools/V122CombatRecurringTransparentAllyPacketCapture.gd`와 `.tscn`에 네 후보 전용 비교판을 추가했다.
- P4 비교판 PNG는 원인 확인용 `tmp/v122_release_polish/v2_p4/`에만 남기며 승인 자료로 사용하지 않는다.

이 정리는 사용자 기존 변경 복구가 아니라, 이번 세션에서 추가한 잘못된 전투 연결을 같은 세션 안에서 제거한 것이다.

## 부분 연결 결과

opaque 지원 원본을 사용하는 두 ID를 제외하고, 투명한 기존 전투 원본을 가진 네 계약 아군을 `normal_grounded`/`large_grounded` profile에 연결했다.

| ID | 원본 | 알파 높이 중앙값(px) | profile | 배율 | 상태 |
|---|---|---:|---|---:|---|
| `spore_healer` | slime idle | 118.5 | `normal_grounded` | 0.660 | `NEEDS_NORMALIZATION` |
| `stone_sentinel` | slime idle | 118.5 | `large_grounded` | 0.820 | `NEEDS_NORMALIZATION` |
| `war_drummer` | goblin idle | 150.0 | `normal_grounded` | 0.522 | `NEEDS_NORMALIZATION` |
| `mimic_porter` | goblin idle | 150.0 | `normal_grounded` | 0.522 | `NEEDS_NORMALIZATION` |

비헤드리스 `1280×720` 비교판은 네 기록과 PNG 저장을 통과했다. 다만 비교판에서 공유 원본의 실루엣 중복이 보이므로, 이 결과를 캐릭터 정체성 승인으로 해석하지 않는다. 이번 P4의 크기·알파 연결만 통과한 것이다.

## 다음 허용 작업

1. `data/waves.json`과 방어 배치 계약에서 DAY6~30 실제 전투 노출 ID를 다시 고정한다.
2. 투명한 전투 자산이 이미 있는 ID만 V2-P4 profile에 등록한다. 원정·정찰 지원 ID는 전투 profile에 등록하지 않는다.
3. `moon_tracker` 전용 전투 원본을 만들기로 결정하는 경우에만 별도 이미지 자산 패킷으로 분리한다. 생성 모델·원본·후처리·런타임 경로를 `SOURCE.md`에 먼저 기록하고, 승인된 자산만 V2에 연결한다.
4. 네 후보의 공유 원본 정체성 문제와 두 opaque ID의 전투 원본 결정이 해소되기 전에는 V2-P5 Update 3, V3 접지, V4 벽/UI, 오디오·VFX·빌드로 이동하지 않는다.

## Related tests

- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualProfileContractTest.tscn` → PASS
- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn` → PASS
- `godot.cmd --headless --path . --scene res://tools/tests/V122CombatVisualProfileContractTest.tscn` → PASS
- P4 scope 검사(opaque 후보 profile 부재·투명 4개 profile·비교 도구) → `P4_SCOPE_SAFE: PASS`
- `godot.cmd --path . --rendering-method gl_compatibility --scene res://tools/V122CombatRecurringTransparentAllyPacketCapture.tscn --quit-after 20000` → `PASS records=4 image=(1280, 720)`
- Python 알파 검사 → `kobold_scout` 전체 불투명 확인

## UI check

P4 전체 후보 비교판은 코볼트·문 트래커가 불투명 사각형으로 보였으므로 승인하지 않는다. 부분 연결 비교판은 `tmp/v122_release_polish/v2_p4/v2_p4_transparent_contract_ally_contact_sheet_1280x720.png`이며, 네 기록의 크기·알파 계약만 확인한다. 공유 원본의 실루엣 중복은 승인하지 않은 미해결 항목이다.

## Unresolved issues

- DAY6~30의 전투 roster와 원정·정찰 지원 roster가 한 후보 목록에 섞이지 않도록 선택표를 별도로 고정해야 한다.
- `moon_tracker`의 전투용 그래픽 원본이 없다. 새 생성 또는 기존 자산의 정식 대체 여부는 별도 자산 결정이 필요하다.
- 네 계약 아군은 서로 다른 역할인데 slime/goblin 원본을 공유한다. 정체성 분리 자산은 V2 크기 패킷 밖의 별도 자산 결정이 필요하다.
- P4는 부분 완료(4/6 후보)이며 전체 완료가 아니다. 전체 회귀·플레이·빌드·커밋·푸시는 실행하지 않았다.
