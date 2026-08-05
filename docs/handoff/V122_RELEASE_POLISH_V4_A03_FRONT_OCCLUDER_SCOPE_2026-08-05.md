# v1.2.2 V4-A-03 전면 앞가림 범위 보정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 보정은 아직 미커밋)
- 패킷 ID: `V4-A-03-FRONT-OCCLUDER-SCOPE`
- 결과: `V4_A03_FRONT_OCCLUDER_SCOPE_PASS`
- QA: `docs/qa/V122_V4_A03_FRONT_OCCLUDER_SCOPE_2026-08-05.md`

## 2. 완료 내용

- 전체 구조 벽 본체를 `BackWallLayer/CorridorBackWallCanvas`의 `wall_back` 경로로 이동했다.
- renderer 부모의 직접 벽 본체 draw를 제거해 UnitYSort의 음수 깊이 슬롯이 구조 벽 뒤로 밀리지 않도록 했다.
- E/S 낮은 `front_occluder`는 기존 `FrontWallLayer/CorridorFrontWallCanvas`의 `wall_front` 경로에 유지했다.
- back/front canvas redraw, 가시성 전파와 디버그 계약을 연결했다.

## 3. 실제 변경 경로

- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- `tools/tests/V122FrontWallActorVisibilityTest.gd`
- `docs/qa/V122_V4_A03_FRONT_OCCLUDER_SCOPE_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V4_A03_FRONT_OCCLUDER_SCOPE_2026-08-05.md`
- `docs/handoff/CURRENT.md`

기존 사용자·Luna 미커밋 변경은 되돌리거나 정리하지 않았다.

## 4. 실행한 직접 테스트와 화면 확인

```text
godot.cmd --headless --path . --script tools/tests/V122FrontWallActorVisibilityTest.gd --quit-after 30
V122_FRONT_WALL_ACTOR_VISIBILITY_TEST: PASS (16 assertions)

godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
CAPTURE: 1280x720 4 stages
```

대표 보스 화면에서 캐릭터 몸체가 다시 보이는 것을 확인했다. `front_fx`와 E/S 낮은 앞가림은 앞에 남고, 전체 구조 벽은 뒤 계층으로 내려갔다.

## 5. 미해결 문제와 다음 작업 순서

- 전체 회귀·전체 플레이·정식 빌드·커밋·푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.
- 기존 기록에 있는 CanvasItem/ObjectDB 종료 경고는 별도 후속 항목으로 남긴다.
- 다음 잠금 패킷은 `V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION`이다. A03 이후 대표 1280×720에서 캐릭터·지면/몸/공중 VFX·FrontWall의 앞뒤 관계를 읽기 전용으로 확인하고, 결과 문서만 갱신한 뒤 멈춘다.

## 6. 핸드오프 상태

- 작업 트리: 기존 Luna·사용자 미커밋 변경이 섞여 있다. 보존했다.
- 원격 푸시: 하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
