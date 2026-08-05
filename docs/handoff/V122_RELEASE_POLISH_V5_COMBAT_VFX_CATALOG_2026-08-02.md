# v1.2.2 V5 전투 VFX catalog·런타임 연결 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-02
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: 변경 사항 미커밋
- 원격 푸시: 실행하지 않음

## 2. 이번 패킷의 목표

- 요청 사항: 전투 VFX ID를 실제 프레임과 연결하고, 캐릭터 기준점·벽 가림·효과 강도·접근성 축소를 하나의 데이터 계약으로 통합한다.
- 완료 조건: 활성 ID 미해결 0개, Update 4 효과 연결, 앵커·깊이·강도·접근성 자동 검증 PASS.
- 범위 밖: 새 이미지 생성·외부 자산 교체, 전체 회귀, 실제 출시 빌드, 커밋·푸시.

## 3. 완료 내용

- `data/v122/combat_vfx_catalog.json`에 활성 VFX 34개를 등록했다.
- `V122CombatVfxCatalog` loader가 실제 파일/프레임 패턴과 메타데이터를 검증하고 런타임 프레임을 캐시에 연결한다.
- `GameRoot`에 Update 4 스킬·왕관·경쟁 보스 VFX helper와 `reduce_flash`/강도 배율 API를 연결했다.
- `CombatSceneController`가 지면·몸·공중 앵커와 `unit_fx`/`front_fx`/`aerial_fx` 깊이 슬롯, `normal`/`finisher`/`boss` 강도 등급을 실제 이펙트 생성에 적용한다.
- VFX catalog 전용 테스트를 suite quick/full에 등록했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v122/combat_vfx_catalog.json` | 활성 ID·프레임·앵커·깊이·강도 catalog | 완료 |
| `scripts/v122/combat/V122CombatVfxCatalog.gd` | catalog loader·경로·메타데이터 검증 | 완료 |
| `scripts/game/GameRoot.gd` | catalog 로드, Update 4 helper, 접근성 API | 완료 |
| `scripts/game/CombatSceneController.gd` | catalog 기반 앵커·깊이·강도·재생 적용 | 완료 |
| `tools/tests/V122CombatVfxCatalogTest.gd` | 57개 전용 계약 검증 | 완료 |
| `tools/tests/V122CombatVfxCatalogTest.tscn` | 전용 테스트 씬 | 완료 |
| `tools/tests/core_verification_suite.json` | quick/full suite 등록 | 완료 |

## 5. 코드·데이터·그래픽 자산 영향

- 코드: 모든 활성 VFX 생성이 catalog를 우선 조회하며, 존재하지 않는 ID는 오류로 기록한다.
- 데이터: 기존 실제 프레임을 재사용하고 `holy`/`heal`은 유효한 공통 펄스 프레임 alias로 정규화했다.
- 그래픽 자산: 새 이미지 생성이나 원본 교체는 하지 않았다. 기존 프레임의 표시 기준과 깊이만 런타임에서 통일했다.
- 접근성: 섬광 감소 시 효과 크기·불투명도·유지 시간을 함께 낮추고, 강도 배율을 `0.45~1.25` 범위로 제한한다.

## 6. 테스트 및 검증

| 순서 | 검증 | 결과 | 근거 |
|---:|---|---|---|
| 1 | catalog JSON 문법 | PASS | `python -m json.tool` |
| 2 | suite JSON 문법 | PASS | `python -m json.tool` |
| 3 | Godot editor headless parse/import | PASS | 에디터 종료 코드 0 |
| 4 | `V122CombatVfxCatalogTest` | PASS, 57/57 | catalog·런타임 계약 |
| 5 | `ContactFeedbackSyncTest` | PASS, 23/23 | C1 접촉 회귀 |
| 6 | `V122ContentCompatibilityTest` | PASS, coverage 85/85·501 assertions | 기존 콘텐츠 호환 |
| 7 | Update 4 phase 30/29/31 tests | PASS, 37/61/42 | Update 4 연결 회귀 |
| 8 | `git diff --check` | PASS | 공백 오류 없음, CRLF 경고만 |

## Related tests

V5 전용 57/57, C1 23/23, 콘텐츠 호환 85/85·501 assertions, Update 4 37/61/42 assertions가 PASS했다.

## UI check

실제 Windows `1280×720` 화면 비교는 실행하지 않았다. headless 검증은 통과했으며, 전면 벽 가림·효과 강도 체감·소유자 청취는 `I1-5-OWNER-01`에서 확인해야 한다.

## Unresolved issues

- 구현·자동 검증 기준 미해결 VFX ID: `0`.
- 실제 1280×720 화면 비교와 최종 소유자 시각 승인이 남아 있다.
- 전체 DemoSmoke는 V5 수용 기준이 아니다. 실수로 실행된 결과에는 기존 설정 UI·raid loop 등 범위 밖 baseline 실패가 포함되어 있어 수정하지 않았다.

## 7. 작업 트리와 인계

- 작업 트리에는 V5 변경과 이전 A1/C1 및 사용자 기존 변경이 함께 있다. 기존 변경을 되돌리거나 정리하지 않았다.
- V5 파일만 별도 커밋하지 않았으며, 사용자의 명시적 승인 전에는 스테이징·커밋·푸시하지 않는다.
- 다음 순서: 소유자 `1280×720` VFX 대표 비교(`I1-5-OWNER-01`) 후, 승인된 `FAIL_REGEN` 자산만 V6 선별 재제작으로 이관한다.
