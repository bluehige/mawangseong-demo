# 저장소 버전·커밋 운영 정리

## 메타데이터

- 작성일: 2026-07-13
- 목표: 버전 계보, 커밋, 빌드, 핸드오프 운영 규칙을 GitHub 저장소에 고정
- 작업 브랜치: `codex/repository-governance`
- 기준 브랜치 및 SHA: `origin/main` / `66d418dea29b7f9e586211722b0f248420ce6bff`
- 검증 기준 구현 SHA: `cfc1af686e18e7bcd49aca20ff46faa87e70a32d`
- 원격 브랜치: `origin/codex/repository-governance` / `c173aeb3e0ba0819cf067ca7c764a4a044bc8f40`
- Pull Request: `https://github.com/bluehige/mawangseong-demo/pull/1`
- 게시 상태: 로컬 커밋과 동일 SHA로 원격 브랜치 게시 완료, `main` 병합 대기

## 완료한 작업

- `main`=최신 안정판, `v0.N.P`=불변 출시 스냅샷, `release/v0.N`=버전 통합, `codex/*`=구현, `test/*`=실험으로 역할을 문서화했다.
- `AGENTS.md`, 버전 운영 문서, 현재 핸드오프, 핸드오프 템플릿, PR 템플릿과 Release 빌드 매니페스트 규격을 추가했다.
- GitHub는 merge commit만 허용하고 squash/rebase merge를 비활성화했다.
- 브랜치 Ruleset `18864533`은 `main`, `release/v*`에 PR, merge 방식, `repository-policy`, 삭제·강제 푸시 금지를 우회자 없이 적용한다.
- 태그 Ruleset `18864535`은 `v*` 태그 삭제와 재지정을 우회자 없이 금지한다.
- Pages Environment와 배포 워크플로는 `main`만 허용한다.
- 배포는 SemVer 태그가 현재 `main` 계보인지 먼저 확인하고, 정식 Full 러너 원본 보고서·카탈로그·ZIP 전체 파일과 해시를 검증한다.
- 이미지 변경은 GPT 내부 이미지 생성 모델과 실제 존재하는 SOURCE/Runtime 필드의 1:1 매핑을 정책 CI가 확인한다.
- 전체 회귀, 전체 플레이와 검수 에이전트는 사용자가 현재 작업에서 명시적으로 요청한 경우에만 실행하도록 규칙을 수정했다.

## 관련 테스트

| 항목 | 결과 |
|---|---|
| `python tools/ci/test_validate_build_manifest.py` | 12/12 PASS |
| `powershell -File tools/ci/TestRepositoryPolicy.ps1` | 7/7 PASS |
| 두 GitHub Actions YAML 파싱 | PASS |
| `git diff --check origin/main...HEAD` | PASS |
| GitHub Ruleset API 재조회 | 두 Ruleset active, bypass 0 |
| 전체 게임 Full 검증 | NOT_REQUESTED, 사용자 지시에 따라 중단 |
| 최종 검수 에이전트 | NOT_REQUESTED |

중단한 Full 검증은 마지막 액션 시각 검사 단계까지 진행됐지만 완료 결과가 아니므로 검증 근거로 사용하지 않는다. 중단 과정에서 Godot이 바꾼 `.import` 668개는 이 별도 작업 트리의 원래 커밋 상태로 복원했다.

## 정책 CI용 최종 결과

- Review task ID: NOT_REQUESTED
- Reviewed SHA: cfc1af686e18e7bcd49aca20ff46faa87e70a32d
- Review range: 66d418dea29b7f9e586211722b0f248420ce6bff..cfc1af686e18e7bcd49aca20ff46faa87e70a32d
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 미해결 항목

- `main`은 아직 `v.03` 계보를 포함하지 않는다.
- `v0.2.0`, `v0.3.0` 정식 태그는 아직 만들지 않았다.
- 실제 게임 `core-verification`, `web-export-smoke`는 사용자 요청 없는 기본 작업에서 실행하거나 필수 체크로 추가하지 않는다.
- 기존 `codex/v03-integration` 작업공간의 미커밋 4개 파일은 이 작업에 섞지 않았다.

## 다음 작업

1. 이 문서 PR의 `repository-policy` 원격 성공을 확인하고 merge commit으로 `main`에 병합한다.
2. 기존 미커밋 4개를 별도 패치 브랜치에 보존한다.
3. `v.03`과 Pages 계보를 통합하고 RC1 문서를 정식 v0.3 문서로 정리한다.
4. 사용자가 정식 출시 검증을 명시적으로 요청하면 그때만 전체 게임·Web·브라우저 검증을 실행하고 태그를 만든다.
