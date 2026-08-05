# V122 출시 마무리 핸드오프 — V3-GROUNDING-PROFILES-22

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-22`
- 결과: `PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING`
- QA: `docs/qa/V122_V3_GROUNDING_PROFILES_22_2026-08-05.md`

## 2. 목표와 실제 변경

`moon_tracker` 한 캐릭터의 4×4 전투 시트에서 idle `(0,0)`과 down `(2,0)`의 알파 bbox를 확인하고 비행 앵커를 `combat_visual_profiles.json`에 연결했다. 런타임 소비자는 기존 공통 `DataRegistry`·`Unit` 경로를 그대로 사용하며, 이번 패킷에서는 공통 코드를 수정하지 않았다.

실제 변경 경로:

- `data/v122/combat_visual_profiles.json`
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
- `docs/qa/V122_V3_GROUNDING_PROFILES_22_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_22_2026-08-05.md`
- `docs/handoff/CURRENT.md`

측정값:

- idle bbox `[29, 38, 162, 183]`, anchor `[0.5, 1.0]`
- down bbox `[24, 60, 167, 183]`, anchor `[0.5, 0.94]`

## 3. 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30
V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS
```

JSON 조회, runtime 파일 존재, small flying render scale, `VisualBody` 계층, idle/down 비행 앵커 위치, 투명 시트 재크로마 방지, 두 프레임 bbox·앵커 일치가 모두 통과했다.

## 4. 상태와 다음 순서

이번 결과는 `PROFILE_CONNECT_PASS_WITH_SOURCE_PENDING`이다. 즉 프로필 연결과 직접 계약은 통과했지만, 원본 상태를 최종 정규화 승인으로 승격하거나 대표 화면·전체 회귀를 완료했다는 뜻은 아니다. 다음 패킷은 `docs/handoff/CURRENT.md`의 잠금된 `NEXT_PACKET_ID`만 실행한다.

## 5. 정책 및 작업 트리

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 실행하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
