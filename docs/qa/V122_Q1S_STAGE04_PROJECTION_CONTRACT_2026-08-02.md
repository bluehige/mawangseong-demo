# V1.2.2 Q1-S P2 재현 — Stage 04 구역 계약과 시각 투영 수

## 목적과 범위

- 감사일: 2026-08-02
- 대상 버전: 제품 1.2.2
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 재현 ID: `Q1-S-INTEGRATION-01`
- 범위: Stage 04 `area_room_count`와 쿼터뷰 renderer의 full-grid 시각 object 투영 수 대조
- 변경: 런타임 0, 데이터 0, 그래픽·오디오 자산 0, 빌드 0

## 실행 결과

실행 명령:

```text
godot.cmd --headless --path . --scene res://tmp/v122_release_polish/q1_s_projection/Q1SProjectionContractRepro.tscn
```

재현 결과는 종료 코드 0이며 다음 값을 얻었다.

| 지표 | 관찰값 | 근거 |
|---|---:|---|
| Stage 04 `area_room_count` | 11 | `data/castle_evolution_stages.json:70` |
| Stage 04 `unlocked_room_grid_ids` | 11개 | 동일 설정 및 재현 report |
| 제품 기본 layout | `stage01_dual_front_candidate_01` | 재현 report |
| Graph object slots | 13개 | `q1_s_projection_contract_report.json` |
| full-grid 투영 슬롯 | 12개 | `QuarterDungeonRenderer.debug_full_grid_room_projection_count()` |

full-grid 12개 중 `service_entrance`가 두 번째 `room_entrance_01`·`entrance_gate_f` 슬롯으로 포함된다. `spike_corridor`는 6셀 footprint와 `spike_floor` ID 때문에 renderer의 full-grid 판정에서 제외된다. 따라서 현재 값은 “Stage 04 구역 계약 11개”와 “실제 화면에 그릴 full-grid object 12개”가 서로 다른 집계임을 보여 준다.

## 원인 분리

`tools/CampaignSaveLoadSmokeTest.gd:642`는 `area_room_count == 11`과 `debug_full_grid_room_projection_count() == 11`을 한 assertion으로 묶는다. 그러나 renderer의 판정은 `footprint.size() >= 25`이고 `spike_floor`만 제외한다(`scripts/dungeon_quarter/QuarterDungeonRenderer.gd:2868-2870`). 이 규칙은 `service_entrance`를 정상적인 full-grid object로 센다.

즉 이번 실패는 저장 payload가 Stage 04 값을 잃은 증거가 아니라, 다음 두 계약을 하나의 숫자로 비교한 통합 계약 공백이다.

- 진행·해금 계약: `castle_evolution_stages.json`의 11개 room grid
- 시각 투영 계약: 현재 dual-front 기본 layout의 12개 full-grid object slot

## 결정이 필요한 사항

1. `service_entrance`를 실제 화면의 별도 입구 시각 object로 계속 포함해 시각 투영 수를 12로 인정할지 결정한다.
2. 11개를 제품의 시각 투영 기준으로 유지한다면 `service_entrance`를 별도 entry visual로 분류하거나 renderer 집계에서 제외한다.
3. 결정 후 저장 payload와 무관한 전용 계약 테스트를 만들고, 기존 smoke assertion을 구역 계약과 시각 투영 계약으로 분리한다.

이번 단계에서는 제품 계약을 임의로 선택하거나 renderer·데이터·테스트를 수정하지 않았다.

## 기계 산출물

- `tmp/v122_release_polish/q1_s_projection/Q1SProjectionContractRepro.gd` (임시)
- `tmp/v122_release_polish/q1_s_projection/Q1SProjectionContractRepro.tscn` (임시)
- `tmp/v122_release_polish/q1_s_projection/q1_s_projection_contract_report.json`
- `tmp/v122_release_polish/q1_s_projection/q1_s_projection_contract_repro.log`
- `tmp/v122_release_polish/q1_s_projection/q1_s_projection_inventory.json`
- `tmp/v122_release_polish/q1_s_projection/q1_s_projection_inventory.tsv`

## 결론과 다음 순서

Q1-S의 두 P2 재현을 완료했다. story autosave 경계는 실제 흐름 PASS·harness gap으로 재분류했고, Stage 04 투영은 제품 계약 결정이 필요한 P2로 남겼다. 다음 계획 패킷은 Q1-I 입력·IME 읽기 전용 감사이며, 이 투영 항목은 계약 결정 전까지 임의 수정하지 않는다.

Related tests: `Q1SProjectionContractRepro` 종료 코드 0, `area_room_count=11`·`full_grid_projection_count=12` 확인
UI check: renderer 화면을 수정하지 않은 headless 구조 재현이며 별도 캡처는 실행하지 않음
Unresolved issues: service_entrance의 시각 투영 포함 여부 제품 계약 결정, 기존 smoke assertion 분리, 실제 1.2.1 hash/mtime·이어하기 소유자 검수
