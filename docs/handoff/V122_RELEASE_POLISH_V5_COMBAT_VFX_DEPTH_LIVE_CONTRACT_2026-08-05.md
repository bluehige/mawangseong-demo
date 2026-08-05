# v1.2.2 V5 전투 VFX live depth·전면 벽 연결 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: 변경 사항 미커밋
- 패킷: `V5-DEPTH-OCCLUSION-LIVE-CONTRACT`
- 결과: `V5_DEPTH_LIVE_CONTRACT_PASS_SCREEN_PENDING`
- QA: `docs/qa/V122_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- 원격 푸시: 실행하지 않음

## 2. 완료 내용

- VFX 고정 z 값을 renderer depth 슬롯 기반 계산으로 전환했다.
- `unit_fx`는 유닛 슬롯, `aerial_fx`는 전면 벽 아래, `front_fx`는 전면 벽 바로 위를 사용한다.
- `FxLayer` 부모 z를 보정한 상대 z와 전역 depth 메타데이터를 기록한다.
- 투사체·근접·피격·공통 burst의 실제 호출부를 live depth로 연결했다.

## 3. 검증

```text
godot.cmd --headless --path . --script tools/tests/V122CombatVfxDepthLiveContractTest.gd --quit-after 30
V122_COMBAT_VFX_DEPTH_LIVE_CONTRACT_TEST: PASS (21 assertions)

godot.cmd --path . --scene tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600
I1_5_BOSS_FINAL_REPRESENTATIVE: assertions=11, failures=0
```

대표 Vulkan 1280×720 캡처는 생성됐지만 중앙 캐릭터가 전면 벽에 대부분 가려져 anchor·가림 체감 승인은 보류했다. 종료 teardown의 `CanvasItem` RID/ObjectDB leak 경고도 기록했다.

## 4. 실제 변경 경로

- `scripts/game/CombatSceneController.gd`
- `tools/tests/V122CombatVfxDepthLiveContractTest.gd`
- `docs/qa/V122_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V5_COMBAT_VFX_DEPTH_LIVE_CONTRACT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

renderer·Unit·VFX catalog·오디오·그래픽 자산은 변경하지 않았다.

## 5. 미해결 문제와 다음 순서

- 캐릭터가 벽에 묻히는 원인을 별도 읽기 전용 발견 패킷으로 조사해야 한다.
- 조사 전에는 I1-5 소유자 시각 승인, V6 재제작, 빌드를 시작하지 않는다.
- 다음 잠금 후보는 `I1-5-ACTOR-VISIBILITY-DISCOVERY`이며 이 핸드오프에서는 실행하지 않는다.

## 6. 정책 상태

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS_WITH_SCREEN_PENDING`
- 커밋·푸시·빌드: 실행하지 않음
