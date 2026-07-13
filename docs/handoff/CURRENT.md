# 현재 작업 핸드오프

최종 갱신: 2026-07-13

이 파일은 다음 세션의 단일 진입점이다. 새 작업이 끝날 때마다 현재 기준 SHA, 최신 핸드오프 링크, 미해결 항목과 다음 작업 순서를 갱신한다.

## 현재 GitHub 기준

| 브랜치 | SHA | 의미 |
|---|---|---|
| `main` | `66d418dea29b7f9e586211722b0f248420ce6bff` | 현재 기본 브랜치, Pages 배포 워크플로 포함 |
| `v.02` | `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69` | v0.2 완성 계보 |
| `v.03` | `199d2d0347e78f9c62b1c15e9369231384235900` | v0.2를 포함한 v0.3 통합 계보 |

문서 기준 브랜치 운영 규칙은 `docs/GIT_VERSIONING_WORKFLOW.md`, 에이전트 필수 규칙은 `AGENTS.md`에 있다.

## 확인된 검수 근거

- v0.2 문서상 전체 자동 검증: 35/35 PASS
- v0.3 문서상 전체 자동 검증: 57/57 PASS
- v0.3은 v0.2보다 2커밋 앞서고 뒤처진 커밋은 없다.
- 위 결과는 로컬 검수 기록이며 현재 GitHub 필수 CI로 강제되고 있지 않다.

## 보존해야 할 별도 로컬 변경

2026-07-13 저장소 점검 당시 `codex/v03-integration` 작업공간에 다음 미커밋 변경이 있었다. 계보 정리 과정에서 삭제하거나 다른 문서 커밋과 섞지 않는다.

- `scripts/ui/HUDController.gd`
- `tools/TutorialFlowSmokeTest.gd`
- `web_Demo/index.html`
- `web_Demo/index.pck`

내용은 튜토리얼 대상 등록 보강, 관련 검수 추가와 Web 재빌드다. 별도 패치 브랜치에서 검수하여 `v0.3.1` 또는 v0.4 반영 여부를 결정한다.

## 미해결 저장소 정리 항목

- `main`이 아직 최신 v0.3 계보를 포함하지 않는다.
- `v0.2.0`, `v0.3.0` 정식 SemVer 태그가 없다.
- `main`, `v.02`, `v.03` 브랜치 보호가 꺼져 있다.
- GitHub 병합 방식은 merge commit만 허용하도록 설정했지만 PR 필수 Ruleset과 필수 CI 지정은 아직 적용되지 않았다.
- 이 문서 PR은 `repository-policy` 체크와 정책·매니페스트 검사기의 영구 회귀 테스트를 추가하지만, 실제 게임 검증인 `core-verification`, `web-export-smoke`와 GitHub Ruleset은 아직 미적용이다.
- 기존 `update3-web-20260713` Release에는 빌드 매니페스트가 없다. 배포 호환 예외는 자산 이름과 기존 ZIP SHA-256을 고정한다. 이후 SemVer Release는 태그 SHA, 정식 전체 검증 카탈로그, 보고서와 ZIP의 모든 파일을 검증한다.
- 저장소가 대형 그래픽 원본과 빌드 이력으로 계속 커질 수 있다.
- 기존 Git이 추적하는 `output/imagegen/` 46개 파일은 가치 있는 GPT 원본을 `assets/source/imagegen/`으로 이전한 뒤 별도 PR에서 정리해야 한다.

## 다음 작업 순서

1. 이 저장소 운영 문서를 `main`에 병합한다.
2. 별도 로컬 미커밋 변경 4개를 전용 패치 브랜치에 보존한다.
3. `main`에서 통합 브랜치를 만들고 `v.03`을 병합하여 Pages 워크플로를 유지한다.
4. v0.3 전체 자동 검증, 저장 호환성, Web 내보내기와 실제 브라우저 검수를 다시 실행한다.
5. 검수 에이전트 지적을 수정하고 재검수하여 통과 상태를 만든다.
6. RC1 명칭, README 버전, 정식 릴리스 노트와 핸드오프를 먼저 확정한 뒤 검수된 통합 커밋을 `main`에 병합한다.
7. `v0.2.0`은 `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`에 생성한다. `v0.3.0`은 v.03과 Pages 계보를 모두 포함한 새 검수 완료 `main` 통합 커밋에 생성하고 전체 SHA를 이 문서에 기록한다.
8. 미커밋 후속 수정은 별도 패치로 검수하여 `v0.3.1` 또는 v0.4에 반영한다.
9. `repository-policy`, `core-verification`, `web-export-smoke` 실행을 확인하고 `main`, `release/v*`, 태그 `v*` Ruleset을 설정한 뒤 최신 `main`에서 `release/v0.4`를 시작한다.

## 정책 적용 상태

| 항목 | 현재 상태 |
|---|---|
| 운영 규칙과 핸드오프 양식 | 이 문서 PR에서 추가, `main` 병합 전 |
| `repository-policy` CI | 이 문서 PR에서 정책 검사와 영구 회귀 테스트 추가, 첫 원격 실행 확인 전 |
| `core-verification` CI | 미적용 |
| `web-export-smoke` CI | 미적용 |
| `github-pages` Environment 배포 브랜치 | `main`만 허용, 2026-07-13 적용 |
| GitHub 병합 방식 | merge commit만 허용, squash/rebase merge 비활성화, 2026-07-13 적용 |
| `main`, `release/v*` Ruleset | 미적용 |
| 태그 `v*` 삭제·재지정 보호 | 미적용 |

## 다음 세션 완료 조건

- 기존 v0.2/v0.3 커밋을 삭제하거나 재작성하지 않는다.
- `main`이 최신 검수 완료 버전을 가리킨다.
- 버전 태그와 Release 빌드의 SHA가 일치한다.
- 미커밋 사용자 변경이 별도 브랜치에 안전하게 보존된다.
- 검수 결과와 다음 작업이 새 핸드오프 문서에 기록된다.
