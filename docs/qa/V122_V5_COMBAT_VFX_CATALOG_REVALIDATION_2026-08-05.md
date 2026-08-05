# v1.2.2 V5 전투 VFX catalog·런타임 연결 재검증 결과

작성일: 2026-08-05
대상 버전: 제품 `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 결론

현재 런타임의 전투 VFX catalog 계약을 재검증했다. 활성 VFX 34종이 실제 프레임으로 해석되고 미해결 ID가 0건이며, 기본·특수·Update 4 스킬·왕관·경쟁 보스 효과가 같은 경로로 연결된다. 지면·몸·공중 anchor, 유닛/전면 벽 depth, 일반·보스 강도, 섬광 감소와 크기 축소 계약도 모두 통과했다.

이번 패킷에서는 코드·데이터·그래픽 자산을 수정하지 않았다. 실제 Windows 화면 비교와 소유자 시각 승인은 별도 검수로 남긴다.

## 직접 검수

실행 명령:

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVfxCatalogTest.tscn --quit-after 1800
```

결과:

```text
V122_COMBAT_VFX_CATALOG_TEST: PASS (57 assertions)
```

확인 범위:

- catalog JSON과 실제 프레임 경로, 활성 ID 34종, 미해결 ID 0건
- 기본 VFX 및 `stitch_stairway`, `emergency_thread_pull`, `night_relay`, `echo_alarm` 연결
- Update 4 왕관·경쟁 보스 ID와 런타임 대표 텍스처 연결
- 일반 근접 효과의 몸통 anchor·전면 벽 아래 depth
- 보스 효과의 공중 anchor·보스 강도·전면 레이어
- 비행 위치 기반 공중 anchor 기본 오프셋
- 섬광 감소 시 크기·효과 축소
- Update 4 스킬·보스 런타임 호출 연결

테스트 출력에는 오류, 경고, 리소스 teardown 경고가 없었다.

## 변경 경로

- `docs/qa/V122_V5_COMBAT_VFX_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_CATALOG_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

기존 `data/v122/combat_vfx_catalog.json`, `scripts/v122/combat/V122CombatVfxCatalog.gd`, `tools/tests/V122CombatVfxCatalogTest.gd` 및 씬은 읽기만 했다.

## 미해결 및 범위 밖

- 실제 Windows `1280×720` 화면에서 전면 벽 가림과 효과 강도를 비교하지 않았다.
- 소유자 시각 승인과 장시간 배속 플레이는 남아 있다.
- 새 VFX 생성·승격, 오디오, 전체 Quick/Full 회귀, 빌드, 다음 패킷은 실행하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
