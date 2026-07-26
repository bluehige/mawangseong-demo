# V20 최소 검수 정책 전환 핸드오프

## 메타데이터

- 작성일: 2026-07-26
- 목표 버전: 제품 2.0 실험선
- 작업 브랜치: `codex/v20-important-revision`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `b63a5f13476f7d28ffa974dacc9a3186e76b67b7`
- 마지막 커밋 SHA: 이 핸드오프를 포함한 커밋
- 원격 푸시 여부: 하지 않음

## 요청과 범위

- 요청 사항: 과도한 검수를 줄이고 커밋 전에 필요한 핵심 확인만 남김
- 완료 조건: 활성 정책·계획·템플릿·정책 CI가 같은 최소 기준을 사용함
- 이번에 하지 않은 일: 사용자가 시안을 고르기 전 UI 코드·씬·런타임 자산 수정

## 완료한 작업

- `docs/TESTING_POLICY.md`를 새 단일 기준으로 추가했다.
- 문서, UI, 전투·데이터, 저장, 빌드, 정책 변경의 최소 확인을 구분했다.
- Quick/Full 전체 검수, 전체 플레이, 모든 플랫폼·해상도, 별도 검수 에이전트와 고정 대량 표본을 일상 작업 기본값에서 제외했다.
- 핸드오프와 PR 템플릿을 세 개의 필수 기록으로 줄였다.
- 정책 CI의 검수 ID·SHA·범위·P1/P2·최종 판정 강제를 제거하고 `Related tests`, `UI check`, `Unresolved issues`만 확인하도록 바꿨다.
- DAY 1~5 활성 계획과 친구 테스트 절차를 현재 필요한 내용만 남도록 줄였다.
- 2026-07-23 이전 상세 기준과 실행 기록은 과거 핸드오프와 Git 이력에 그대로 보존했다.

## 변경 파일

- `AGENTS.md`
- `.github/pull_request_template.md`
- `docs/TESTING_POLICY.md`
- `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md`
- `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md`
- `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md`
- `docs/handoff/CURRENT.md`
- `docs/handoff/HANDOFF_TEMPLATE.md`
- `docs/handoff/V20_MINIMAL_VERIFICATION_POLICY_2026-07-26.md`
- `tools/ci/ValidateRepositoryPolicy.ps1`
- `tools/ci/TestRepositoryPolicy.ps1`

## UI와 자산

- 현재 게임 화면을 예시 제작을 위해 한 번 확인했다.
- A/B/C 시안은 선택용 미리보기이며 저장소 밖의 Codex 생성 이미지 경로에 있다.
- 게임 UI 코드, 씬, 데이터와 런타임 그래픽 자산 변경은 없다.
- 새 런타임 자산과 `SOURCE.md`: 없음

## 최소 검수

- Related tests: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/ci/TestRepositoryPolicy.ps1` 9개 시나리오 PASS
- UI check: 현재 화면과 A/B/C 선택용 예시 확인 완료, 게임 UI 구현 변경 없음
- Unresolved issues: 사용자 A/B/C 또는 혼합 방향 선택 대기

추가 전체 회귀·전체 플레이·검수 에이전트는 요청되지 않아 실행하지 않았다.

## 다음 작업

1. 사용자가 A/B/C 또는 혼합 방향을 고른다.
2. 선택한 화면 한 곳부터 단순화한다.
3. 관련 UI 테스트 1종과 `1280×720` 대표 화면 1회만 확인한다.
4. 사용자가 원하면 친구 테스트용 Web 빌드를 갱신한다.
