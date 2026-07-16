# 제품 버전 1.2 체계 전환 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-16
- 목표 버전: 표시 1.2 / 기술 SemVer 1.2.0
- 작업 브랜치: `codex/v12-directive-combat`
- 기준 브랜치 및 SHA: `origin/main` / `7131110245bc9ea45e4603fe32fdf38e5c2363d9`
- 마지막 기능·테스트 커밋 SHA: `e0da9591d0e317104f0d021509b6a9ba2b958e75`
- 관련 PR 또는 태그: [PR #35](https://github.com/bluehige/mawangseong-demo/pull/35), 태그 생성 안 함

## 2. 전환 기준

- 제품 출시 순서는 `1.0 → 1.1 → 1.2 → 2.0 → 3.0 → 4.0`이다.
- `1.1`, `1.2`는 1.0 출시선 수정판이며 `2.0` 이후는 확장판이다.
- 화면·일반 문서에는 두 자리 버전, 프로젝트·manifest·Git 태그에는 `1.2.0` 같은 SemVer를 쓴다.
- 기존 `v0.*` 태그, GitHub Release, 브랜치, 원문 기획 디렉터리와 날짜별 핸드오프는 공개·감사 기록이므로 이름을 바꾸거나 이동하지 않는다.
- 새 빌드·태그·릴리스에는 기존 `v0.*` 이름을 재사용하지 않는다.

## 3. 반영 파일

- `docs/PRODUCT_VERSIONING.md`: 새 제품 버전과 구 표기 매핑의 단일 기준
- `AGENTS.md`, `docs/GIT_VERSIONING_WORKFLOW.md`: 브랜치·태그·출시 작업 규칙
- `docs/design/plans/README.md`: 구 기획 번호와 제품 확장 버전 분리
- `README.md`, `docs/release/BUILD_MANIFEST.md`, `steam/README.md`: 현재 표기와 빌드 예시
- `project.godot`, `export_presets.cfg`: 1.2.0 프로젝트·Windows 파일 버전
- `tools/ci/test_validate_build_manifest.py`, `tools/ci/validate_build_manifest.py`, `tools/ci/test_validate_steam_release.py`: 새 SemVer 예시와 회귀 fixture
- `docs/handoff/CURRENT.md`와 지시 전용 전투 계획·구현 핸드오프: 현재 1.2 작업선과 브랜치

## 4. 기존 태그 처리

원격에는 이미 `v0.2.0`, `v0.2.1`, `v0.2.2`, `v0.2.3`, `v0.3.0`과 관련 GitHub Release가 있다. 이들은 구 버전 체계 기록으로 보존한다. 이번 전환에서 삭제·재지정·강제 푸시하지 않는다.

## 5. 검수 상태

- 문서·메타데이터 일관성 검사: PASS
- CI 도구 자체 회귀: Python 19/19 PASS
- 전체 게임·밸런스·UI·플랫폼 검수: 89/89 PASS
- Review task ID: FULL_REVIEW_2026-07-16_DIRECTIVE_COMBAT
- Reviewed SHA: e0da9591d0e317104f0d021509b6a9ba2b958e75
- Review range: 7131110245bc9ea45e4603fe32fdf38e5c2363d9..e0da9591d0e317104f0d021509b6a9ba2b958e75
- Remaining P1/P2: 0
- Final review result: PASS

## 6. 작업 트리와 원격

- 미커밋 파일: 사용자 소유 미추적 `.uid` 5개만 보존
- 사용자 기존 미추적 `.uid` 파일: 보존
- 원격 푸시 여부: `origin/codex/v12-directive-combat` 푸시, PR #35 생성 완료
