# v1.2.2 V5 깊이·가림 화면 재검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (이번 검수 문서는 아직 미커밋)
- 패킷 ID: `V5-DEPTH-OCCLUSION-SCREEN-REVALIDATION`
- 결과: `V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_PASS`
- QA: `docs/qa/V122_V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_2026-08-05.md`

## 2. 완료 내용

- VFX live depth 계약 테스트를 다시 실행해 21개 단언을 통과했다.
- A03 이후 대표 보스 장면을 Vulkan 1280×720에서 1회 실행해 상태 단언 11개와 캡처 4개를 통과했다.
- 캐릭터 몸체는 구조 벽 뒤에 묻히지 않고, 지면 효과는 바닥면에, 공중·전면 효과는 의도된 앞 계층에 표시되는 것을 확인했다.
- 코드·데이터·그래픽·오디오 자산은 수정하지 않았다.

## 3. 실제 변경 경로

- `docs/qa/V122_V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_V5_DEPTH_OCCLUSION_SCREEN_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 4. 미해결 문제와 다음 작업 순서

- 종료 시 남을 수 있는 기존 CanvasItem/ObjectDB teardown 경고는 별도 항목으로 유지한다.
- 전체 회귀·전체 플레이·정식 빌드·커밋·푸시는 이번 패킷 범위가 아니므로 실행하지 않았다.
- 다음 잠금 패킷은 `V4-B-03-UI-ANCHOR-SCREEN-REVALIDATION`이다. 대표 1280×720에서 이름·HP·피해 숫자가 공통 `foot/body/head` 앵커에 맞고 캐릭터와 겹치지 않는지 읽기 전용으로 확인한 뒤 문서만 갱신한다.

## 5. 핸드오프 상태

- 작업 트리: 기존 Luna·사용자 미커밋 변경이 섞여 있다. 보존했다.
- 원격 푸시: 하지 않았다.
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
