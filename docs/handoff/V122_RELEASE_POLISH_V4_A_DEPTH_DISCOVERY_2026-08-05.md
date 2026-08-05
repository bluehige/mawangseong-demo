# V122 출시 마무리 핸드오프 — V4-A-01-DISCOVERY

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V4-A-01-DISCOVERY`
- 결과: `DEPTH_DISCOVERY_PASS_WITH_IMPLEMENTATION_PENDING`
- QA: `docs/qa/V122_V4_A_DEPTH_DISCOVERY_2026-08-05.md`

## 2. 목표와 실제 변경

V4-A 구현 전에 현재 Unit 깊이, 전면 벽 Canvas, 방향별 벽 draw 경로를 읽기 전용으로 조사했다. 이번 패킷은 문서만 수정했으며 제품 코드·데이터·자산은 변경하지 않았다.

핵심 발견:

- `Unit.gd`가 이동 후 월드 Y를 그대로 `z_index`에 대입한다.
- `UnitYSortLayer`는 `z_index=0`, `y_sort_enabled=true`이고 `FrontWallLayer`는 `z_index=50`이다.
- 구조 벽 본체는 root의 back draw에서 한 번 그려지고, E/S 방향의 낮은 front occluder만 `FrontWallLayer/CorridorFrontWallCanvas`에서 다시 그려진다.
- N/W→`wall_back`, E/S→`wall_front` 방향 분리는 `CorridorTopologyBuilder`와 `QuarterDungeonRenderer` 양쪽에 일치한다.
- VFX는 `FxLayer=70` 아래에서 `unit_fx=-30`, `aerial_fx=100` 고정 자식 깊이를 사용하며 Unit·벽 슬롯과의 조회 계약은 없다.

실제 변경 경로:

- `docs/qa/V122_V4_A_DEPTH_DISCOVERY_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V4_A_DEPTH_DISCOVERY_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 3. 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/V122CorridorTopologyLayoutMatrixTest.tscn --quit-after 30
V122_CORRIDOR_TOPOLOGY_LAYOUT_MATRIX_TEST: PASS

V122_V4_A_DEPTH_DISCOVERY_STATIC_AUDIT: PASS (7 checks)
```

행렬 테스트는 Stage 01~04와 custom 맵의 topology·구조 벽 자산·N/W·E/S 계층·FrontWallLayer canvas 존재를 확인했다. 정적 감사는 Unit의 raw Y z-index, Unit y-sort, FrontWallLayer 계층, front canvas 연결, E/S 필터, 방향 매핑, VFX 고정 슬롯을 확인했다.

## 4. 구현 경계와 다음 순서

다음 구현에서는 `UnitYSortLayer` 안의 유한 depth 슬롯과 `FrontWallLayer`를 넘지 않는 유효 깊이를 만든다. 기존 벽 자산·방향 매핑은 유지하고 E/S의 낮은 occluder만 앞에 둔다. V5에서 사용할 depth/occlusion 조회 계약은 정의하되, 실제 VFX ID 연결·UI 앵커·오디오·이름/HP/피해 숫자 변경은 하지 않는다.

다음 잠금 패킷은 `V4-A-02-DEPTH-SLOT-CONTRACT`다. 제안된 후보 경로는 `Unit.gd`, `QuarterDungeonRenderer.gd`, `QuarterDungeonWallCanvas.gd`, 전용 계약 테스트와 해당 QA·핸드오프·CURRENT 문서이며, 이 패킷에서는 실행하지 않았다.

## 5. 정책 및 작업 트리

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 실행하지 않았다.
- 실제 `1280×720` 전면 벽 가림 화면은 다음 구현 패킷의 gate다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
