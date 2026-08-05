# V122 V4-B-01 UI Anchor Discovery QA

- 검수일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 패킷: `V4-B-01-UI-ANCHOR-DISCOVERY`
- 결과: **UI_ANCHOR_DISCOVERY_PASS_WITH_IMPLEMENTATION_PENDING**

## 패킷 범위

이 패킷은 이름·HP·피해 숫자의 현재 부모, 좌표, 계층, 겹침 원인을 읽기 전용으로 조사했다. 코드·데이터·자산·UI 구현은 하지 않았다.

## 발견 결과

| 표시 요소 | 현재 소유자·부모 | 현재 기준 | 발견된 위험 |
|---|---|---|---|
| 이름 | `Unit.gd`가 만든 `Label`을 `Unit`에 직접 추가 | `position=(-55,-96)`, `size=(110,24)` | 프로필 발 앵커·체격·비행 여부와 분리된 고정 위치라 머리나 벽과 겹칠 수 있다. |
| HP 바 | `Unit._draw()` | `y=-73`, 폭 `48`, 높이 `6` | 이름과 동일하게 `VisualBody`의 실제 발·몸 높이를 읽지 않는다. 큰 유닛·쓰러짐 상태에서 간격이 달라진다. |
| 피해 숫자 | `CombatSceneController.spawn_damage_number()`가 `root.effect_root`에 추가 | `target.global_position + (-width/2, -112) + lane offset`, `z_index=3100` | Unit 프로필 앵커를 사용하지 않고 고정 월드 오프셋을 사용한다. 모든 피해 숫자가 `FxLayer=70` 아래에 있어 `FrontWallLayer=50`보다 항상 앞에 나온다. |
| 공통 앵커 소유자 | 없음 | `WorldOverlayLayer`는 `GameRoot._draw_world_overlay()`만 위임 | 이름·HP·피해 숫자가 서로 다른 좌표 체계를 사용한다. |

## 원인

1. 유닛의 실제 sprite는 `VisualBody` 아래에서 `profile_anchor`, `source_frame_px`, `render_scale`로 위치가 계산된다. 캐릭터별 idle/down 앵커와 체격 프로필이 다르지만 이름·HP는 Unit 원점의 고정 픽셀값을 사용한다.
2. 피해 숫자는 Unit 원점의 전역 좌표를 받아 별도 `FxLayer`에 배치한다. 따라서 캐릭터 머리 기준이 아니며, V4-A의 유닛 슬롯·전면 벽 경계와도 연결되어 있지 않다.
3. 결과적으로 작은/큰/비행/쓰러짐 캐릭터마다 표시 간격이 달라지고, 전면 벽 근처에서는 이름·HP는 가려질 수 있지만 피해 숫자는 벽 위에 남는 계층 불일치가 생긴다.

## 근거 경로

- `scripts/units/Unit.gd:1211-1219` — HP 바 고정 사각형
- `scripts/units/Unit.gd:1252-1263` — 이름 Label 생성·고정 위치·Unit 직접 부모
- `scripts/units/Unit.gd:1400-1475` — 프로필 발 앵커가 `VisualBody` 위치에만 적용
- `scripts/game/CombatSceneController.gd:6743-6769` — 피해 숫자 고정 오프셋·FxLayer 부모·z 값
- `scripts/game/GameRoot.gd:3941-3953` — `UnitYSortLayer=0`, `FxLayer=70`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd:791-805` — `FrontWallLayer=50`, `UiDebugLayer=200`
- `scripts/game/WorldOverlayLayer.gd:1-22` — 공통 표시 앵커를 소유하지 않고 draw 위임만 수행
- `data/v122/combat_visual_profiles.json:35-72, 137-1025` — 공통 발 앵커와 캐릭터별 idle/down 앵커·체격 프로필

## 구현 경계 제안

후속 패킷에서만 공통 `foot/body/head` 앵커를 정의하고 이름·HP·피해 숫자가 같은 기준점을 사용하도록 연결한다. 피해 숫자의 표시 계층을 V4-A depth 계약과 연결할지는 별도 구현·검수 범위로 분리한다. 이번 패킷에서는 어떤 코드도 변경하지 않았다.

## 직접 검수

```text
V122_V4_B_UI_ANCHOR_DISCOVERY_STATIC_AUDIT: PASS (12 checks)
```

검수 항목은 이름·HP 고정 좌표, 프로필 sprite 앵커 분리, 피해 숫자 고정 월드 오프셋·부모·z 값, Unit/FrontWall/Fx 계층, WorldOverlay 비소유를 확인했다. 대표 화면과 UI 구현은 다음 패킷으로 넘겼다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
