# V122 출시 마무리 핸드오프 — V3-GROUNDING-PROFILES-21-IMPORT

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/현재 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V3-GROUNDING-PROFILES-21-IMPORT`
- 결과: `IMPORT_SIDECAR_PASS_PROFILE_PENDING`
- QA: `docs/qa/V122_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md`

## 2. 목표와 범위

이번 패킷은 `mimic_porter`의 runtime PNG가 Godot에서 읽히도록 import sidecar를 추가하고 텍스처 로드만 확인하는 단일 작업이었다. idle/down bbox·발 앵커를 JSON에 연결하거나 다른 캐릭터·공통 코드·빌드에 손대지 않았다.

## 3. 실제 변경 경로

- `assets/sprites/monsters/update4/monster_mimi_sheet.png.import`
- `tools/tests/V122CombatVisualRuntimeProfileContractTest.gd`
- `docs/qa/V122_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V3_GROUNDING_PROFILES_21_IMPORT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 4. 검증

```text
godot.cmd --headless --path . --scene tools/tests/V122CombatVisualRuntimeProfileContractTest.tscn --quit-after 30
V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS
```

Godot가 `monster_mimi_sheet.png`를 임포트하고 destination cache를 읽었으며 runtime 경로·VisualBody 계층·scale·투명 sheet 조건을 통과했다. 생성 cache는 저장소에 추가하지 않는다.

## 5. 다음 순서

다음 패킷은 `V3-GROUNDING-PROFILES-21`이다. 해당 패킷에서만 `data/v122/combat_visual_profiles.json`에 `mimic_porter`의 idle/down 4×4 alpha bbox와 foot anchor를 연결하고 계약 테스트를 확장한다. 이 핸드오프를 작성한 turn에서는 다음 패킷을 시작하지 않았다.

## 6. 정책 및 작업 트리

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 실행하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
