# v1.2.2 V5 깊이·가림 화면 재검수

- 작성일: 2026-08-05
- 대상 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION`
- 범위: A03 이후 대표 1280×720의 캐릭터·지면/몸/공중 VFX·FrontWall 앞뒤 관계

## 목표

V5 live depth 계약과 V4-A-03 벽 계층 보정이 실제 화면에서도 함께 동작하는지 확인한다. 이번 패킷은 읽기 전용 화면 재검수만 수행하고 코드·데이터·자산은 수정하지 않는다.

## 직접 실행

### VFX 깊이 계약

```text
godot.cmd --headless --path . --script tools/tests/V122CombatVfxDepthLiveContractTest.gd --quit-after 30
V122_COMBAT_VFX_DEPTH_LIVE_CONTRACT_TEST: PASS (21 assertions)
```

유닛 슬롯, `wall_front` 경계, 몸통·공중·전면 VFX의 전역/부모 깊이, 투사체·근접·피격·burst 호출 연결을 모두 다시 통과했다.

### 대표 화면

```text
godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
CAPTURE: 1280x720 4 stages
```

Vulkan 1280×720으로 대표 보스 장면을 1회 실행했다. 생성된 캡처는 다음 네 장이다.

- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_ready_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_inspection_telegraph_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_consecrated_floor_1280x720.png`
- `tmp/v122_release_polish/i1_5_boss_final/i1_5_boss_final_mercy_barrier_1280x720.png`

## 화면 판정

- 캐릭터 몸체: 파란 슬라임과 아군·보스 몸체가 바닥 위에서 보이며, 전체 구조 벽 뒤로 통째로 묻히지 않는다.
- 지면 VFX: 축성 바닥 효과가 바닥면에 붙고 캐릭터 몸체를 불필요하게 덮지 않는다.
- 공중 VFX: 텔레그래프 효과가 바닥과 캐릭터 위에 표시되며 벽 본체에 잘려 사라지지 않는다.
- 전면 VFX: 자비의 방벽 ring이 `FrontWallLayer`보다 앞에 표시되고, 낮은 E/S 앞가림과 충돌해 끊기지 않는다.
- FrontWall: 국소적인 앞가림만 남고 전체 통로 벽이 캐릭터를 가리는 현상은 재현되지 않았다.

## 판정

`V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_PASS`.

V5 깊이 계약과 A03 벽 계층 보정이 대표 화면에서 일치함을 확인했다. 정식 출시 승인 SHA·전체 회귀·빌드는 아직 진행하지 않았다.

## 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
