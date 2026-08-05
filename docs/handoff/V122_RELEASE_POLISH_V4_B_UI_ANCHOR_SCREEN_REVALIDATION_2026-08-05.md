# v1.2.2 V4-B UI 앵커 화면 재검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 검수 문서는 아직 미커밋)
- 패킷 ID: `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION`
- 결과: `V4_B_UI_ANCHOR_SCREEN_REVALIDATION_PASS`
- QA: `docs/qa/V122_V4_B_UI_ANCHOR_SCREEN_REVALIDATION_2026-08-05.md`

## 2. 완료 내용

- UI 앵커 계약 테스트 12개 검사를 통과했다.
- 보스 대표 장면을 Vulkan 1280×720에서 실행해 상태 단언 11개와 캡처 4개를 통과했다.
- 피해 숫자 이벤트가 발생하는 후반 전투 대표 장면을 Vulkan 1280×720에서 보완 실행해 상태 단언 13개와 캡처 5개를 통과했다.
- 이름·HP·피해 숫자가 공통 `head` 앵커를 따라가며 캐릭터·벽·바닥과 부자연스럽게 겹치지 않는 것을 확인했다.

## 3. 실제 변경 경로

- `docs/qa/V122_V4_B_UI_ANCHOR_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

코드·데이터·그래픽·오디오 자산은 수정하지 않았다. 기존 사용자·Luna 미커밋 변경은 보존했다.

## 4. 미해결 문제와 다음 작업 순서

- 종료 시 남을 수 있는 기존 CanvasItem/ObjectDB teardown 경고는 별도 항목으로 유지한다.
- 전체 회귀·전체 플레이·정식 빌드·커밋·푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.
- V4-A/B 화면 계약은 닫혔지만 정식 출시 승격과 실제 소유자 조작·청취 gate는 남아 있다. 다음 패킷은 `I1-5-OWNER-SCREEN-REVALIDATION` 후보로 제안한다. 사용자 조작 없이 대표 화면·상태만 다시 확인하는 단일 읽기 전용 검수로 범위를 좁힌다.

## 5. 핸드오프 상태

- 작업 트리: 기존 Luna·사용자 미커밋 변경이 섞여 있다. 보존했다.
- 원격 푸시: 하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
