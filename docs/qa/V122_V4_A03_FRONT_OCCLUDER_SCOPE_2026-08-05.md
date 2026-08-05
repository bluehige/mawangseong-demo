# v1.2.2 V4-A-03 전면 앞가림 범위 검수

- 작성일: 2026-08-05
- 대상 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `V4-A-03-FRONT-OCCLUDER-SCOPE`
- 범위: 구조 벽 본체와 E/S 낮은 앞가림의 CanvasItem 소유권 분리

## 목표

전체 구조 벽 본체는 `BackWallLayer`에서 그려 유닛보다 뒤에 두고, E/S 방향의 낮은 `front_occluder`만 `FrontWallLayer`에 남긴다. 이렇게 하면 통로 벽은 유지하면서 캐릭터 몸체가 벽 본체 뒤로 통째로 사라지지 않는다.

## 구현 확인

- `BackWallLayer/CorridorBackWallCanvas`를 만들고 `wall_back` 드로잉 경로를 연결했다.
- renderer 부모의 직접 전체 벽 본체 그리기를 제거하고, BackWall canvas가 구조 벽 본체와 꼭짓점 몸체를 그리도록 바꿨다.
- `FrontWallLayer/CorridorFrontWallCanvas`와 `wall_front` 경로는 유지했다. 이 경로는 E/S 낮은 `front_occluder`만 그린다.
- back/front canvas의 redraw 요청과 가시성 전파를 함께 연결했다.
- 제품 코드·Unit·GameRoot·VFX catalog·오디오·실제 그래픽 자산은 이 패킷에서 수정하지 않았다.

## 직접 테스트

### 전용 계약 테스트

```text
godot.cmd --headless --path . --script tools/tests/V122FrontWallActorVisibilityTest.gd --quit-after 30
V122_FRONT_WALL_ACTOR_VISIBILITY_TEST: PASS (16 assertions)
```

16개 정적 계약 단언으로 back canvas 생성, `wall_back`/`wall_front` 분기, draw target 전달, 부모 직접 벽 본체 draw 제거, debug scope 문자열을 확인했다.

### 대표 화면

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
CAPTURE: 1280x720 4 stages
```

Vulkan으로 대표 보스 장면을 1280×720에서 1회 실행했다. 중앙의 파란 슬라임과 갈색·흰색 캐릭터 몸체가 다시 보이며, 분홍색 `front_fx`와 E/S 낮은 앞가림은 앞 계층에 남아 있다. 전체 회귀·전체 플레이·빌드는 실행하지 않았다.

대표 캡처:

`tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_mercy_barrier_1280x720.png`

## 판정

`V4_A03_FRONT_OCCLUDER_SCOPE_PASS`.

구조 벽 본체와 국소 앞가림의 소유 계층이 분리됐고, 전용 테스트와 대표 화면 실행이 통과했다. 다만 실제 출시 승인 SHA는 아직 없으며, 다음 패킷에서 V5 깊이·가림 화면을 읽기 전용으로 재확인한다.

## 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
