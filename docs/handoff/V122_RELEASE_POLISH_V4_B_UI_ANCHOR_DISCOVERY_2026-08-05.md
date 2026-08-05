# V122 Release Polish Handoff — V4-B-01 UI-ANCHOR-DISCOVERY

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: 제품 `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d` (미커밋 혼합 작업 트리)
- 패킷: `V4-B-01-UI-ANCHOR-DISCOVERY`
- 결과: `UI_ANCHOR_DISCOVERY_PASS_WITH_IMPLEMENTATION_PENDING`
- QA: `docs/qa/V122_V4_B_UI_ANCHOR_DISCOVERY_2026-08-05.md`

## 2. 완료 내용

이름·HP·피해 숫자의 표시 소유자와 좌표 체계를 읽기 전용으로 추적했다.

- 이름은 `Unit` 직속 Label의 `(-55,-96)` 고정 위치다.
- HP 바는 `Unit._draw()`의 `y=-73` 고정 사각형이다.
- sprite만 `VisualBody`의 profile foot anchor와 render scale을 사용한다.
- 피해 숫자는 `FxLayer`에 `target.global_position` 기준 `-112` 및 lane offset으로 추가되고 `z_index=3100`을 사용한다.
- `UnitYSortLayer=0`, `FrontWallLayer=50`, `FxLayer=70`이라 이름·HP와 피해 숫자의 벽 가림 계층이 일관되지 않다.

## 3. 변경 파일

이번 패킷은 문서만 변경했다.

| 경로 | 내용 |
|---|---|
| `docs/qa/V122_V4_B_UI_ANCHOR_DISCOVERY_2026-08-05.md` | 발견·근거·직접 감사 기록 |
| `docs/handoff/V122_RELEASE_POLISH_V4_B_UI_ANCHOR_DISCOVERY_2026-08-05.md` | 세션 핸드오프 |
| `docs/handoff/CURRENT.md` | 다음 패킷과 권위 상태 갱신 |

## 4. 검수

```text
V122_V4_B_UI_ANCHOR_DISCOVERY_STATIC_AUDIT: PASS (12 checks)
```

UI 코드 수정, 대표 화면, 전체 회귀, 빌드, 커밋·푸시는 요청 범위가 아니어서 실행하지 않았다.

## 5. 미해결 및 다음 순서

- 공통 `foot/body/head` 앵커 API 구현과 실제 화면 비교가 남아 있다.
- 피해 숫자를 V4-A 깊이 계약과 어떻게 연결할지는 구현 패킷에서 별도 결정해야 한다.
- 다음 제안 패킷: `V4-B-02-UI-ANCHOR-CONTRACT`.

## 6. 작업 트리

- 기존 Luna·사용자 미커밋 변경은 보존했다.
- 이번 패킷은 문서 3개만 추가·수정했고 코드·데이터·자산은 변경하지 않았다.
- 빌드 산출물·캡처·`output/`·`web_Demo/`는 생성하지 않았다.
- 원격 푸시: 없음.

## 7. 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
