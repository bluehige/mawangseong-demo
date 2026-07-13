# v0.3 main 계보 통합

## 1. 메타데이터

- 작성일: 2026-07-13
- 목표 버전: v0.3 통합
- 작업 브랜치: `release/v0.3`
- 기준 브랜치 및 SHA: `origin/main` / `dc6fad5f2b7fd1bcbad6dd30d652c3ed7f4e453e`
- 마지막 구현 커밋 SHA: `af83c7feca8909c392489590d28e969d1fde9df0`
- 원격 푸시 여부: 핸드오프 작성 후 진행
- 관련 PR 또는 태그: PR 생성 전, 태그 미생성

## 2. 이번 세션 목표

- `codex/v03-integration`의 미커밋 4개를 조사해 의미 있는 소스 수정과 Web export를 분리한다.
- 최신 `main`의 Pages·저장소 정책 계보와 v0.3 게임 계보를 merge commit으로 통합한다.
- 테스트용 Web 데모를 별도 브랜치에서 커밋·푸시할 수 있도록 정책을 바로잡는다.
- 정식 `v0.3.0` 태그와 전체 출시 검수는 사용자 요청이 없어 범위에서 제외한다.

## 3. 완료한 작업

- `HUDController.gd`의 방 지침 드롭다운에 `ROOM_DIRECTIVE_TRAP_LURE`, `ROOM_DIRECTIVE_RETREAT_LINE` 등 실제 튜토리얼 타깃을 등록했다.
- `TutorialFlowSmokeTest.gd`에 함정 유도 타깃의 실제 컨트롤 등록, 포커스 링 포함, 배지 비가림 검사를 추가하고 `7112961`로 커밋했다.
- 최신 `main`과 `codex/v03-integration`을 부모로 갖는 merge commit `af83c7f`를 만들었다. 충돌은 `README.md` 한 건이었고 운영 문서와 v0.3 핸드오프 링크를 모두 보존했다.
- 소스 통합 트리에는 `web_Demo` export를 넣지 않았다. 정책 도입 전 v.03 계보는 고정 SHA `199d2d0...`의 기존 커밋과 동일 객체만 레거시로 인정한다.
- `test/web-*` 직접 push에서만 `web_Demo/**`와 그 안의 PCK/WASM을 허용하고, PR이나 소스 브랜치에서는 차단하도록 정책과 CI를 수정했다.
- GitHub Actions의 `actions/checkout`을 Node 24 기반 `v5`로 갱신했다.

## 4. 주요 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/ui/HUDController.gd` | 방 지침 튜토리얼 타깃 등록 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 실제 타깃 포커스 회귀 검사 | PASS |
| `README.md` | 운영 규칙과 v0.3 상태 통합 | 완료 |
| `AGENTS.md` | `test/web-*` Web 데모 허용 규칙 | 완료 |
| `docs/GIT_VERSIONING_WORKFLOW.md` | Web 데모 브랜치와 레거시 통합 규칙 | 완료 |
| `.github/workflows/repository-policy.yml` | `test/web-*` push 이벤트별 예외 | 완료 |
| `tools/ci/ValidateRepositoryPolicy.ps1` | Web 데모·고정 레거시 검사 | 완료 |
| `tools/ci/TestRepositoryPolicy.ps1` | 허용/차단 회귀 시나리오 | 9/9 PASS |

## 5. 그래픽·오디오·Web 자산

- 이번 세션에서 새 이미지를 생성하지 않았다.
- v0.3의 기존 GPT 내부 생성 자산과 SOURCE 기록은 `199d2d0...` 계보 그대로 통합했다.
- 조사한 최신 Web export는 삭제하지 않고 `stash@{0}`에 보존했다.
- stash 이름: `v0.3 web export before main integration (sha256 2b6d72f9)`
- `web_Demo/index.pck`: SHA-256 `2b6d72f9e9f4606b0b92e571c32ba35e49c85c71420ea3b29dd959d672478731`, 181,257,848바이트
- `web_Demo/index.html`: PCK 크기 181,257,848바이트를 가리키는 export 설정

## 6. 테스트 및 검수

| 검수 | 결과 |
|---|---|
| `TutorialFlowSmokeTest.tscn` | PASS |
| `Update3DataContractTest.tscn` | 17/17 PASS |
| `SaveV4MigrationTest.tscn` | 42/42 PASS |
| `TestRepositoryPolicy.ps1` | 9/9 PASS |
| 전체 회귀·전체 플레이 | NOT_REQUESTED |
| 별도 검수 에이전트 | NOT_REQUESTED |

- Review task ID: NOT_REQUESTED
- Reviewed SHA: af83c7feca8909c392489590d28e969d1fde9df0
- Review range: dc6fad5f2b7fd1bcbad6dd30d652c3ed7f4e453e..af83c7feca8909c392489590d28e969d1fde9df0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- `release/v0.3`은 아직 원격 PR로 `main`에 병합하지 않았다.
- 테스트용 export는 아직 `test/web-v0.3`에 복원·푸시하지 않았다.
- `v0.3.0` 태그는 전체 출시 검수가 요청되지 않아 만들지 않았다.
- `docs/release/UPDATE3_RELEASE_NOTES_RC1_2026-07-13.md`는 정식 태그 전 RC1 상태를 유지한다.
- 과거 `web_Demo` 이력은 재작성하지 않는다. 새 Web export만 전용 테스트 브랜치에서 LFS로 관리한다.

## 8. 다음 작업 순서

1. `release/v0.3`을 푸시하고 `main` PR의 `repository-policy`를 통과시킨 뒤 merge commit으로 병합한다.
2. 병합된 `main`에서 `test/web-v0.3`을 만들고 v.03의 `.gitattributes`와 `web_Demo` 기준 파일을 복원한다.
3. `stash@{0}`을 적용해 최신 `index.html`과 `index.pck`를 복원하고 LFS 상태를 확인한 뒤 커밋·푸시한다.
4. 사용자가 정식 출시 검증을 요청하면 전체 게임·Web·브라우저 검수 후 RC1 문서를 확정하고 `v0.3.0` 태그를 만든다.

## 9. 작업 트리 상태

- 소스 통합 merge commit: `af83c7feca8909c392489590d28e969d1fde9df0`
- 미커밋 소스 파일: 없음
- 보존 stash: `stash@{0}` Web export, `stash@{1}` 과거 `pre-v02-switch-20260713`
- Web export를 소스 통합 커밋에 섞지 않음
