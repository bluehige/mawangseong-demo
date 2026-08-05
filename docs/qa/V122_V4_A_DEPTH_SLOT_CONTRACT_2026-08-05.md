# V122 V4-A-02 Depth Slot Contract QA

- 검수일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 패킷: `V4-A-02-DEPTH-SLOT-CONTRACT`
- 결과: **DEPTH_SLOT_CONTRACT_PASS**

## 패킷 범위

이번 패킷은 UnitYSortLayer 내부의 유한 depth 슬롯과 FrontWallLayer 경계·occlusion 조회 계약만 처리했다. VFX ID 연결, UI 앵커, 오디오, 자산 재생성, 다음 패킷과 빌드는 범위에서 제외했다.

## 구현 결과

- `QuarterDungeonRenderer`가 Unit 슬롯을 `-40..44`로 제한하고, 실제 walkable 타일의 월드 Y 범위를 기준으로 위치를 정규화한다.
- `FrontWallLayer`의 계층값 `50`을 유닛 슬롯 상한보다 앞에 고정해 남·동쪽(`E/S`) 저층 occluder가 유닛보다 앞에 그려지는 계약을 보장한다.
- `Unit`은 이동 후 renderer API로 슬롯을 갱신하며, renderer가 아직 준비되지 않은 초기화·독립 테스트 순간에도 같은 상한을 쓰는 fallback을 적용한다.
- `CorridorFrontWallCanvas`는 `wall_front` 전용 draw 범위와 V4-A 계약을 읽기 전용으로 노출한다.
- VFX 연결 상태는 `PENDING_V5`로 명시해 이번 패킷에서 조기 연결하지 않았다.

## 직접 검수

```text
godot.cmd --headless --path . --script tools/tests/V122V4ADepthSlotContractTest.gd --quit-after 30
V122_V4_A_DEPTH_SLOT_CONTRACT_TEST: PASS

godot.cmd --headless --path . --check-only --quit
PASS
```

계약 테스트는 standalone headless 실행에서 코드 경계를 직접 읽어 depth 하한·상한, N/W 후면, E/S 전면 occluder, VFX 보류, raw Y 대입 제거를 확인한다. 대표 화면 가림 검수는 V4-A 완료 조건에 포함되지 않으므로 실행하지 않았다.

## 변경 경로

- `scripts/units/Unit.gd`
- `scripts/dungeon_quarter/QuarterDungeonRenderer.gd`
- `scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd`
- `tools/tests/V122V4ADepthSlotContractTest.gd`

정책상 전체 회귀·전체 플레이 검수·빌드·커밋·푸시는 요청되지 않아 실행하지 않았다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` (미커밋 혼합 작업 트리)
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
