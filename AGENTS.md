# Repository Working Agreement

이 문서는 저장소 전체에 적용되는 필수 작업 규칙이다. 사람과 자동화 에이전트는 작업을 시작하기 전에 이 문서와 `docs/handoff/CURRENT.md`를 먼저 확인한다.

## 기준 브랜치와 버전

- `main`은 항상 전체 검수까지 통과한 최신 안정판만 가리킨다.
- 정확한 출시본은 이동하지 않는 SemVer 태그(`v0.2.0`, `v0.3.0`, `v0.4.0`)로 보존한다.
- 다음 버전 통합은 `release/v0.N`에서 진행한다. 예: `release/v0.4`.
- 개별 구현은 `codex/vNN-<topic>`, 실험과 검수는 `test/vNN-<topic>`에서 진행한다.
- 기존 `v.02`, `v.03` 브랜치는 기록 보존 및 해당 마이너 버전 유지보수용이다. 강제 푸시하거나 과거 커밋을 다시 쓰지 않는다.
- 새 버전은 반드시 최신 `main`에서 시작한다. 이전 버전 브랜치에서 다음 버전을 직접 분기하지 않는다.

상세 절차는 `docs/GIT_VERSIONING_WORKFLOW.md`를 따른다.

## 필수 작업 순서

1. `git status`, 현재 브랜치, 기준 커밋과 원격 동기화 상태를 확인한다.
2. `docs/handoff/CURRENT.md`와 대상 버전의 최신 핸드오프 문서를 읽는다.
3. 구현 범위와 완료 조건을 정하고 관련 코드, 데이터, 자산만 수정한다.
4. 관련 자동 테스트와 수동 또는 시각 검수를 실행한다.
5. 구현자가 아닌 별도 검수 에이전트로 코드, 데이터, 밸런스, UI 및 회귀 위험을 검수한다.
6. 지적 사항을 수정하고 테스트와 검수 에이전트를 다시 실행한다. P1/P2 지적이 없고 요구 검수가 통과할 때까지 반복한다.
7. `docs/handoff/CURRENT.md`와 세션별 핸드오프를 갱신한다.
8. 의도한 파일만 명시적으로 스테이징하고 커밋, 푸시, PR을 진행한다.

검수 실패, 미해결 필수 항목, 미실행 필수 테스트가 있으면 완료로 기록하지 않는다.

## 그래픽과 대용량 자산

- 신규 게임 그래픽은 사용자가 다른 방식을 명시하지 않는 한 GPT 내부 이미지 생성 모델을 사용한다.
- 런타임 최종 자산과 생성 원본을 구분한다. 생성 원본, 프롬프트, 날짜, 대상 버전과 후처리 내역은 `assets/source/imagegen/<asset>/SOURCE.md`에 남긴다.
- `SOURCE.md`에는 정책 CI용 고정 필드 `Generation model`, `Generated date`, `Target version`, `Source image path`, `Runtime image path`를 채운다. 모델 값은 `GPT internal image generation`으로 쓰고, 경로가 여러 개면 경로 필드를 반복한다. 같은 변경의 각 이미지는 실제 존재하는 필드 값으로 정확히 한 문서에 한 번만 연결한다.
- 실제 게임에서 사용하는 최종 자산만 적절히 최적화하여 `assets/` 런타임 경로에 둔다.
- 승인 없이 외부 이미지 생성 서비스나 출처가 불명확한 자산으로 대체하지 않는다.
- 대형 원본은 필요할 때 Git LFS 또는 별도 자산 저장소를 사용한다. 기존 Git 이력을 임의로 재작성하지 않는다.

## 빌드와 테스트 산출물

- 새 `tmp/`, `output/`, `builds/`, `web_Demo/` 파일과 로컬 캡처는 커밋하지 않는다. PCK, WASM, 실행 파일과 압축 빌드는 경로와 무관하게 소스 Git에 추가하지 않는다.
- Web, Windows 및 친구 테스트 빌드는 버전 태그에서 생성하여 GitHub Release 또는 GitHub Actions artifact로 보관한다.
- 빌드 결과물을 보관하기 위한 장기 브랜치를 만들지 않는다. 웹 코드나 배포 파이프라인 자체를 실험할 때만 단기 `test/web-*` 브랜치를 사용한다.
- 기존 추적 중인 `output/imagegen/`의 가치 있는 GPT 원본은 출처 문서와 함께 `assets/source/imagegen/`으로 옮긴 뒤 추적을 해제한다.
- 기존 추적 중인 `output/`과 `web_Demo/`는 별도 마이그레이션 작업으로 정리하며, 검수 없이 삭제하거나 교체하지 않는다.

## 핸드오프 규칙

저장소 변경을 만든 모든 세션은 종료 전에 `docs/handoff/HANDOFF_TEMPLATE.md` 형식으로 다음 정보를 남긴다. 파일 수정이 금지된 읽기 전용 검수 세션은 저장소를 변경하지 않고 대화 보고로 대체한다.

- 목표 버전, 브랜치, 기준 SHA와 마지막 커밋 SHA
- 구현 완료 내용과 변경 파일
- 코드, 데이터, 스토리, 밸런스 및 그래픽 자산 변경
- 실행한 검수 명령, 결과, 검수 에이전트 지적과 수정 내역
- 미해결 문제와 다음 작업 순서
- 작업 트리의 미커밋 파일과 원격 푸시 여부

`docs/handoff/CURRENT.md`는 다음 세션의 단일 진입점이다. 새 핸드오프를 추가한 뒤 반드시 이 파일의 링크와 다음 작업을 갱신한다.

코드, 데이터, 자산, 씬, 도구 또는 워크플로를 변경한 PR은 날짜별 세션 핸드오프도 추가한다. 해당 문서의 정책 CI용 영문 키 `Review task ID`, `Reviewed SHA`, `Review range`, `Remaining P1/P2`, `Final review result`를 채운다. P1/P2는 0, 결과는 PASS여야 하며 검수 기준 SHA 이후에는 `docs/handoff/` 문서만 변경할 수 있다.

## Git 안전 규칙

- 사용자의 기존 변경을 되돌리거나 다른 작업과 섞지 않는다.
- 혼합 작업 트리에서는 `git add -A`를 사용하지 않고 대상 파일을 명시한다.
- `git reset --hard`, 강제 푸시, 태그 재지정, 공개 이력 재작성은 명시적 승인 없이 금지한다.
- `main`과 릴리스 브랜치에는 PR을 통해 merge commit으로 병합하고 필수 검수 상태가 통과한 뒤 출시 태그를 만든다. 검수 SHA 추적을 보존하기 위해 squash merge와 rebase merge는 사용하지 않는다.
- 검수 PASS는 핸드오프에 기록된 최종 SHA에만 유효하다. 해당 SHA 이후 기능, 데이터 또는 자산이 변경되면 이전 PASS는 무효이며 다시 검수한다.
- GitHub의 안정·릴리스 브랜치 Ruleset과 SemVer 태그 Ruleset은 적용돼 있다. `repository-policy`는 필수지만 실제 게임용 `core-verification`, `web-export-smoke` 필수 체크는 아직 적용 전이므로 `docs/handoff/CURRENT.md`의 상태를 확인한다.
