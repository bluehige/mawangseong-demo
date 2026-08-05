# v1.2.2 I1-5 캐릭터 표시 원인 발견 검수

- 작성일: 2026-08-05
- 대상 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `I1-5-ACTOR-VISIBILITY-DISCOVERY`
- 범위: 코드·렌더 계층·대표 캡처의 읽기 전용 원인 감사

## 목표

V5 live depth 보정 뒤에도 대표 보스 화면에서 캐릭터 몸체가 전면 벽에 묻히는 현상을, 스프라이트 로딩 문제가 아니라 실제 그리기 계층과 벽 가림 범위 문제로 분리해 확인한다.

## 직접 실행

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
```

결과:

```text
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
CAPTURE: .../i1_5_boss_final_ready_1280x720.png size=(1280, 720)
CAPTURE: .../i1_5_boss_final_inspection_telegraph_1280x720.png size=(1280, 720)
CAPTURE: .../i1_5_boss_final_consecrated_floor_1280x720.png size=(1280, 720)
CAPTURE: .../i1_5_boss_final_mercy_barrier_1280x720.png size=(1280, 720)
```

Vulkan 1280×720 실행과 4개 캡처 저장은 통과했다. 종료 시 `CanvasItem` RID 1개와 ObjectDB 인스턴스 누수 경고가 반복되지만, 이번 패킷의 캐릭터 가림 원인과는 별도 후속 항목이다.

## 소스 계층 감사

1. `scripts/units/Unit.gd`의 `setup()`은 `VisualBody`와 `AnimatedSprite2D`를 만들고, `DataRegistry.combat_visual_profile_for_unit()`의 런타임 PNG를 `warm_animation_frames()`로 프레임에 연결한 뒤 `idle_down`을 재생한다. 대표 실행에서 스프라이트 로딩 실패·빈 캡처·초기화 중단은 발생하지 않았다.
2. `GameRoot._create_layers()`는 `UnitYSortLayer`를 z=0으로 만들고, 전투 화면에서 `unit_root.visible = true`로 유지한다. 대표 스크립트도 세 유닛에 `visible = true`를 명시했다. 따라서 노드 비가시화가 1차 원인은 아니다.
3. `Unit.refresh_depth_slot()`은 캐릭터를 `-40..44`의 깊이 슬롯으로 배치한다. `FrontWallLayer`는 z=50이므로 E/S 전면 벽의 낮은 앞가림 자체는 캐릭터보다 앞에 있는 것이 계약상 맞다.
4. 그러나 `GameRoot._draw()`가 `quarter_renderer.draw()`를 호출하고, `QuarterDungeonRenderer._draw_back_wall_layer()`의 전체 벽 본체를 `root.draw_texture_rect()`로 `GameRoot`의 부모 CanvasItem에 직접 그린다. 이 본체는 선언된 `BackWallLayer` z=-70 캔버스에 그려지지 않는다.
5. 같은 시점에 유닛은 `UnitYSortLayer` 자식의 z=-40..44를 사용한다. Godot CanvasItem 계층상 부모의 z=0 draw와 비교할 때 음수 슬롯 유닛은 부모가 그린 전체 벽 본체보다 뒤로 밀린다. 이 때문에 전면 벽의 낮은 `front_occluder`만 가려야 할 위치에서도 몸체가 거의 전부 사라질 수 있다.
6. `FrontWallLayer/CorridorFrontWallCanvas`는 `wall_edges` 중 E/S만 골라 `front_occluder` PNG를 그린다. 자산의 front bbox는 256px 캔버스 중 대략 y=142..233인 낮은 띠다. 이 자산 자체가 전체 벽을 가리는 것이 아니라, 부모 z=0에 잘못 그려진 전체 벽 본체와 합쳐질 때 과도한 가림이 발생한다.

## 대표 캡처 픽셀 감사

- 1280×720 네 장 모두 UI, 방 바닥, 전투 상태 표식, Selen 선택 정보, 분홍색 `front_fx` 방벽 고리는 정상적으로 보인다.
- 중앙 전투 유닛은 이름/표식 일부와 작은 상단 조각만 남고 몸체 대부분이 벽 뒤로 사라진다.
- 캡처는 대표 스크립트의 16프레임 settle 뒤 저장됐으므로 단순 캡처 타이밍 문제로 볼 근거가 없다.
- `front_fx` 고리가 벽 위에 분리되어 보이는 것은 V5 VFX live depth가 `FrontWallLayer + 1`로 동작한 결과이며, 캐릭터 몸체 가림과는 다른 계층 문제다.

## 발견 결론

`I1_5_ACTOR_VISIBILITY_DISCOVERY_PASS`.

주원인은 캐릭터 스프라이트나 VFX catalog가 아니라 **전체 구조벽 본체가 `BackWallLayer`가 아닌 GameRoot 부모 draw(z=0)에 그려지고, 유닛 깊이 슬롯이 그보다 낮은 음수 범위를 사용해 부모 벽 뒤로 들어가는 계층 불일치**다. 그 위에 의도된 E/S `front_occluder`가 z=50으로 추가되어, 현재 장면에서는 벽 가림이 시각적으로 더 강해진다.

이번 패킷에서는 코드·데이터·자산을 수정하지 않았다. 수정은 전체 벽 본체의 실제 BackWallLayer 소유권과 E/S 앞가림의 국소 범위를 분리 검증하는 다음 단일 패킷에서만 진행한다.

## 다음 패킷 제안(실행하지 않음)

- `PACKET_ID`: `V4-A-03-FRONT-OCCLUDER-SCOPE`
- `GOAL`: 전체 벽 본체는 유닛 뒤의 BackWallLayer에, E/S 낮은 앞가림만 FrontWallLayer에 남겨 대표 통로에서 캐릭터 몸체가 보이게 한다.
- `ALLOWED_WRITE_PATHS`: `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`, `tools/tests/V122FrontWallActorVisibilityTest.gd`, 이 패킷의 QA·핸드오프·`CURRENT.md`
- `FORBIDDEN`: `scripts/game/*`, `scripts/units/*`, VFX catalog, 오디오, 실제 자산 생성, 전체 검증, 빌드
- `DIRECT_TEST`: 전용 FrontWall actor visibility 테스트 1종과 대표 1280×720 캡처 1회
- `STOP_AFTER`: 벽 본체/앞가림 계층 수정과 직접 테스트 결과 기록 후 중단

## 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
