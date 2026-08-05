# v1.2.2 V5 전투 VFX catalog·런타임 연결 검증 결과

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 결론

자동 계약 기준으로 V5 구현을 완료했다. 활성 전투 VFX 34개가 catalog에서 실제 프레임으로 해석되고, 미해결 ID는 0개다. Update 4 스킬·왕관·경쟁 보스 효과도 같은 경로로 연결했으며, 지면·몸·공중 앵커, 유닛/전면 벽 깊이, 일반·결정타·보스 강도, 섬광 감소와 강도 축소 설정을 런타임에 적용했다.

실제 Windows `1280×720` 전투 화면 비교와 소유자 시각 승인은 아직 실행하지 않았다. 이 항목은 `I1-5-OWNER-01`/V6 착수 전 시각 gate로 남긴다.

## 구현 내용

- `data/v122/combat_vfx_catalog.json`에 활성 VFX ID 34개와 실제 파일/프레임 패턴, 앵커, 깊이, 강도, fps, 반복, 섬광 감소 메타데이터를 등록했다.
- `scripts/v122/combat/V122CombatVfxCatalog.gd`가 catalog와 프레임 경로를 읽고, 파일 존재·메타데이터·활성 ID 미해결 여부를 검사한다.
- `scripts/game/GameRoot.gd`가 catalog를 시작 시 로드하고 모든 프레임을 기존 효과 캐시에 연결한다. Update 4 스킬·왕관·보스 VFX 재생 helper와 접근성 설정 API를 추가했다.
- `scripts/game/CombatSceneController.gd`가 catalog의 앵커·깊이·강도·재생 속도를 사용한다. 유닛 뒤 `unit_fx`, 전면 벽 앞 `front_fx`, 공중 효과 `aerial_fx` 슬롯을 분리하고 섬광 감소 시 크기·불투명도·유지 시간을 함께 낮춘다.
- `tools/tests/V122CombatVfxCatalogTest.gd/.tscn`을 추가하고 `tools/tests/core_verification_suite.json`의 quick/full에 `combat_vfx_catalog`을 등록했다.

## 검증 결과

| 검증 | 결과 |
|---|---|
| `python -m json.tool data/v122/combat_vfx_catalog.json` | PASS |
| `python -m json.tool tools/tests/core_verification_suite.json` | PASS |
| Godot editor headless parse/import | PASS |
| `V122CombatVfxCatalogTest` | 57/57 assertions PASS |
| `ContactFeedbackSyncTest` | 23/23 assertions PASS |
| `V122ContentCompatibilityTest` | coverage 85/85, 501 assertions PASS |
| `Update4ContractMonsterPresentationPhase30Test` | 37 assertions PASS |
| `Update4CrownAssetsPhase29Test` | 61 assertions PASS |
| `Update4RivalPresentationPhase31Test` | 42 assertions PASS |
| `git diff --check` | PASS (기존 CRLF 경고만 표시) |

## Related tests

`V122CombatVfxCatalogTest` 57/57, `ContactFeedbackSyncTest` 23/23, `V122ContentCompatibilityTest` coverage 85/85·501 assertions, Update 4 관련 37/61/42 assertions가 PASS했다.

## UI check

실제 Windows `1280×720` 전투 화면 비교는 실행하지 않았다. headless 계약 검증으로 프레임 연결·앵커·깊이·강도·접근성 동작만 확인했으며, 최종 시각 체감은 `I1-5-OWNER-01`에서 확인한다.

## Unresolved issues

- VFX 자체의 미해결 ID는 0개다.
- 실제 화면에서 전면 벽 가림과 일반/결정타/보스 강도의 체감 비교는 소유자 검수 대기다.
- 전체 DemoSmoke는 이번 V5 수용 기준으로 사용하지 않았다. 실수로 실행된 결과는 기존 설정 UI·raid loop 등 V5와 무관한 baseline 실패가 포함되어 있으므로 V5 실패로 해석하지 않는다.
