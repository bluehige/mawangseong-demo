# Git 버전 및 릴리스 운영 규칙

최종 갱신: 2026-07-16

이 문서는 제품 `1.0` 이후의 버전 계보를 보존하면서 `main`을 최신 안정판으로 유지하고, 개발·검수·배포 산출물이 섞이지 않게 하는 저장소 운영 기준이다. 제품 번호와 구 `v0.*` 기록의 관계는 `docs/PRODUCT_VERSIONING.md`를 따른다.

## 1. 저장소의 기준점

| 구분 | 이름 예시 | 역할 | 수명 |
|---|---|---|---|
| 최신 안정판 | `main` | 전체 검수를 통과한 최신 버전 | 영구 |
| 정확한 출시본 | `v1.2.0`, `v2.0.0` | 이동하지 않는 출시 스냅샷 | 영구 |
| 버전 통합 | `release/v1.2`, `release/v2.0` | 한 출시선을 모아 검수하는 브랜치 | 출시 후 동결 또는 유지보수 |
| 구현 작업 | `codex/v12-combat`, `codex/v20-monsters` | 한 가지 기능, 데이터 또는 자산 작업 | 병합 후 삭제 가능 |
| 테스트·실험 | `test/v12-balance`, `test/v20-web` | 밸런스, Web, UX 실험 | 검증 후 삭제 가능 |
| 긴급 수정 | `hotfix/v1.2.1` | 출시판의 긴급 수정 | 출시 후 삭제 가능 |

브랜치는 이동할 수 있으므로 백업 기준이 아니다. 각 완성본의 기준은 반드시 SemVer 태그다. 화면 표기 `1.2`는 태그 `v1.2.0`에 대응한다. 기존 `v0.*` 태그와 `v.02`, `v.03`, `release/v0.*` 브랜치는 구 체계 기록으로 보존하고 새 제품 릴리스에 재사용하지 않는다.

## 2. 권장 계보

```text
main (최신 안정판)
  └─ release/v2.0
       ├─ codex/v20-story
       ├─ codex/v20-monsters
       ├─ codex/v20-art
       └─ test/v20-balance
             ↓ 구현·검수 완료
       release/v2.0 → main PR
             ↓
       tag v2.0.0
             ↓
       GitHub Release에 Web/Windows 빌드 첨부
             ↓
       release/v3.0을 최신 main에서 시작
```

다음 버전은 항상 최신 `main`에서 만든다. `release/v1.2`에서 바로 `release/v2.0`, `release/v2.0`에서 바로 `release/v3.0`으로 이어 붙이는 방식은 사용하지 않는다. 모든 완성판이 `main`으로 돌아온 뒤 다음 버전을 시작해야 계보가 한 줄로 유지된다.

## 3. 버전 개발 절차

### 시작

1. `main`이 원격 최신 상태이며 작업 트리가 정리되어 있는지 확인한다.
2. `docs/handoff/CURRENT.md`와 대상 버전의 요구사항을 확인한다.
3. `release/v1.2`, `release/v2.0`처럼 대상 표시 버전의 통합 브랜치를 최신 `main`에서 만든다.
4. 스토리, 몬스터, 밸런스, UI, 그래픽처럼 독립 검수가 가능한 단위로 `codex/v12-*`, `codex/v20-*` 작업 브랜치를 만든다.

### 구현과 검수

1. 작업 브랜치에서 기능과 관련 테스트를 함께 구현한다.
2. 변경 범위에 직접 관련된 테스트를 실행하고 UI 변경이면 해당 화면만 실제 확인한다.
3. 전체 회귀, 전체 플레이와 별도 검수 에이전트는 사용자가 현재 작업에서 명시적으로 요청한 경우에만 실행한다.
4. 요청된 검수에서 지적이 있으면 해당 범위만 수정하고 재검증한다.
5. 핸드오프에 실행한 테스트와 요청되지 않아 실행하지 않은 검수를 구분해 기록한다.
6. 핸드오프 문서를 갱신하고 작업 브랜치를 대상 통합 브랜치(예: `release/v1.2`, `release/v2.0`)에 PR로 병합한다.

### 출시

아래 전체 검증 절차는 사용자가 태그 생성이나 정식 출시를 명시적으로 요청한 작업에서만 실행한다.

1. 대상 통합 브랜치에서 전체 자동 검증과 출시 해상도 시각 검수를 실행한다.
2. 저장 마이그레이션, DAY 진행, 엔딩 도달, 콘텐츠 누락, Web 부팅을 확인한다.
3. P1/P2 미해결 항목이 0인지 확인한다.
4. README 버전, 정식 릴리스 노트와 `docs/handoff/CURRENT.md`를 최종 상태로 갱신하고 다시 검수한다.
5. 대상 통합 브랜치를 `main`에 PR로 병합한다.
6. 병합된 `main` 커밋에 주석 SemVer 태그(예: `v1.2.0`, `v2.0.0`)를 만든다.
7. 태그에서 Web/Windows 빌드를 생성하여 같은 태그의 GitHub Release에 첨부한다.
8. Release 자산의 `build-manifest.json`을 검증하고 배포한다.

## 4. 패치와 과거 버전 유지보수

- 과거 버전의 긴급 수정은 해당 출시 태그에서 `hotfix/v<major>.<minor>.<patch>`를 만든다.
- 수정 후 변경 범위 관련 테스트를 실행한다. 전체 회귀는 사용자가 패치 출시 검증을 명시적으로 요청한 경우에만 실행한다.
- 패치를 `main`과 현재 활성 `release/v*`에 모두 반영하여 다음 버전에서 수정이 사라지지 않게 한다.
- 새 SemVer 태그를 만들고 이전 태그를 이동시키지 않는다.
- 기존 `v0.*`, `v.02`, `v.03` 브랜치는 구 체계 기록으로 남기며 새 제품 계열 유지보수에 재사용하지 않는다.

## 5. Web 및 테스트 버전

- Web/Windows 실행 파일과 PCK는 소스 버전 백업 수단이 아니다.
- 빌드는 소스 태그에서 재생성할 수 있어야 하며 GitHub Release 또는 Actions artifact에 둔다.
- 현재 플레이테스트용 Web 데모는 `test/web-v12`, `test/web-v20` 같은 브랜치의 `web_Demo/`에 커밋·푸시할 수 있다. PCK/WASM 같은 대형 파일은 그 브랜치에서 Git LFS로 추적한다.
- `test/web-*` 브랜치는 실행 가능한 데모 배포용이며 `main`이나 `release/*`로 병합하지 않는다. 소스가 바뀌면 해당 안정 SHA에서 다시 export해 브랜치를 갱신한다.
- 정책 CI는 `test/web-*` 직접 push에서만 `web_Demo/` 산출물을 허용한다. 같은 브랜치를 소스 브랜치로 PR하면 산출물 검사가 다시 실패한다.
- 현재 `.github/workflows/deploy-web-demo.yml`처럼 Release 자산을 Pages로 배포하는 흐름을 유지한다.
- Release 자산 이름에는 버전을 포함한다. 예: `mawangseong-v1.2.0-web.zip`, `mawangseong-v2.0.0-web.zip`.
- 빌드 ZIP 루트에 `build-manifest.json`을 포함한다. 고정 형식과 검증 절차는 `docs/release/BUILD_MANIFEST.md`를 따른다.
- `build-manifest.json`에는 태그, 전체 SHA, Godot 버전, UTC 생성 시각, 실제 Full 러너 원본 보고서 경로·해시와 ZIP 전체 파일의 SHA-256 및 바이트 크기를 기록한다.
- 배포할 SemVer 태그 커밋은 현재 `main`의 조상이어야 한다. 태그 내부의 정식 카탈로그와 실제 Full 러너 보고서가 모두 일치해야 배포한다.
- 브라우저, Web 성능 또는 배포 파이프라인 실험도 `test/web-*`에서 진행한다. 과거 데모의 영구 보존은 브랜치가 아니라 같은 버전의 GitHub Release가 담당한다.

## 6. 그래픽 자산 규칙

- 신규 그래픽은 기본적으로 GPT 내부 이미지 생성 모델을 사용한다.
- 생성 원본과 프롬프트는 `assets/source/imagegen/<asset>/`에 두고 `SOURCE.md`에 모델, 날짜, 목적, 대상 버전, 후처리와 런타임 경로를 기록한다.
- 정책 CI가 읽을 수 있도록 `SOURCE.md`에는 다음 고정 필드를 모두 쓴다.

~~~text
- Generation model: GPT internal image generation
- Generated date: YYYY-MM-DD
- Target version: v1.2.0 또는 v2.0.0
- Source image path: assets/source/imagegen/<asset>/<file>
- Runtime image path: assets/<runtime-path>/<file>
~~~

- 원본과 런타임 파생본이 여러 개면 `Source image path`와 `Runtime image path` 줄을 반복한다. 같은 변경의 각 PNG, JPEG, WebP, GIF는 실제 존재하는 필드 값으로 정확히 한 `SOURCE.md`에 한 번만 연결한다. 일반 설명에 경로를 적는 것만으로는 매핑으로 인정하지 않는다.
- 게임에는 최종 선택·정리·최적화된 런타임 자산만 연결한다.
- 동일 이미지의 원본, 크로마키, 알파, 아틀라스 파생본이 모두 필요한지 검토하여 불필요한 중복을 피한다.
- 대형 원본과 빌드는 일반 Git에 반복 커밋하지 않는다. LFS 사용 여부는 저장소 용량과 월간 전송량을 확인한 뒤 결정한다.
- 이미 공개된 대형 파일 이력은 별도 승인 없는 `filter-repo`나 강제 푸시로 정리하지 않는다.
- 현재 Git이 추적하는 `output/imagegen/` 원본은 즉시 삭제하지 않는다. 가치 있는 원본과 출처를 `assets/source/imagegen/`으로 옮기고 런타임 연결을 검수한 다음 별도 PR에서 추적을 해제한다.

## 7. 문서와 핸드오프 구조

```text
AGENTS.md
docs/
  GIT_VERSIONING_WORKFLOW.md
  handoff/
    CURRENT.md
    HANDOFF_TEMPLATE.md
    V04_<TOPIC>_<YYYY-MM-DD>.md
  release/
    BUILD_MANIFEST.md
    V04_RELEASE_NOTES.md
assets/
  source/imagegen/<asset>/SOURCE.md
.github/
  pull_request_template.md
  workflows/repository-policy.yml
tools/
  ci/ValidateRepositoryPolicy.ps1
  ci/core_verification_evidence.py
  ci/prepare_release_evidence.py
  ci/validate_build_manifest.py
```

- `CURRENT.md`는 다음 세션이 가장 먼저 읽는 단일 진입점이다.
- 세션별 문서는 완료 기록과 검수 근거를 보존한다.
- `CURRENT.md`에는 최신 세션별 문서 링크, 다음 작업, 미해결 위험과 기준 SHA만 요약한다.
- 릴리스 노트는 사용자에게 보이는 변경과 호환성, 알려진 문제를 기록한다.

## 8. GitHub 보호 설정

`main`과 활성 릴리스 브랜치에는 다음 규칙을 적용한다.

- PR을 통한 병합
- 필수 자동 검수 통과
- 강제 푸시와 브랜치 삭제 금지
- 가능하면 관리자도 동일 규칙 적용
- 태그 `v*` 삭제 및 재지정 제한
- 검수 SHA 이후 핸드오프만 추가하는 계약을 보존하기 위해 merge commit만 허용하고 squash merge와 rebase merge는 사용하지 않음

혼자 작업하더라도 리뷰 승인 인원 강제보다 자동 검수와 강제 푸시 방지를 우선한다. 검수 에이전트 결과는 PR 설명과 핸드오프에 남긴다.

Ruleset 적용 대상과 필수 체크 이름은 다음과 같다.

| 대상 | 보호 규칙 | 필수 체크 |
|---|---|---|
| `main` | PR + merge commit, 강제 푸시·삭제 금지 | 현재 `repository-policy`; 추후 `core-verification`, `web-export-smoke` 추가 |
| `release/v*` | PR + merge commit, 강제 푸시·삭제 금지 | 현재 `repository-policy`; 추후 `core-verification` 추가 |
| 태그 `v*` | 삭제·재지정 금지 | 출시 체크리스트 완료 후 생성 |

브랜치 Ruleset `18864533`은 2026-07-13 활성화됐으며 우회자는 없다. `main`과 `release/v*`에 PR, merge 방식, `repository-policy`, 삭제·강제 푸시 금지를 강제한다. 태그 Ruleset `18864535`도 우회자 없이 `v*` 삭제와 재지정을 막는다.

현재 `repository-policy` 워크플로는 운영 정책 검사기와 두 검사기의 짧은 자체 회귀 테스트를 실행한다. 실제 게임 전체 검증인 `core-verification`, `web-export-smoke`는 사용자가 전체 검증 자동화를 명시적으로 요청한 경우에만 추가하고, 실제 성공 이력을 확인한 뒤 Ruleset 필수 체크에 넣는다.

정책 도입 전에 만들어진 `v.03` 기준 SHA `199d2d0347e78f9c62b1c15e9369231384235900`과 그 조상에는 과거 `web_Demo`와 이미지 원본 관리 방식이 포함돼 있다. 통합 검사기는 이 고정 SHA의 기존 커밋과 동일 객체만 레거시로 인정한다. 최종 소스 통합 트리의 `web_Demo`는 `main` 버전을 유지하며, 이후 새 Web export는 `test/web-*`에서만 허용한다.

GitHub의 `github-pages` Environment는 배포 브랜치를 `main`으로 제한한다. 워크플로의 `github.ref` 조건도 함께 유지하며, 둘 중 하나만으로 배포 보호가 완료됐다고 보지 않는다.

2026-07-13 현재 GitHub 저장소 설정은 merge commit만 허용하고 squash merge와 rebase merge는 비활성화했다. 브랜치 Ruleset은 관리자 포함 우회자를 두지 않으므로 직접 푸시도 차단한다. 이 설정은 검수 기준 SHA와 실제 병합 이력의 관계를 보존한다.

## 9. 구 `v0.*` 계보 기록

이 절은 2026-07-13 당시의 통합·태그 이력을 재현하기 위한 역사 기록이다. 아래 이름을 새 제품 버전에 재사용하지 않는다.

2026-07-13 v0.3 통합 시작 기준은 다음과 같다.

- `main`: `dc6fad5f2b7fd1bcbad6dd30d652c3ed7f4e453e`
- `v.02`: `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`
- `v.03`: `199d2d0347e78f9c62b1c15e9369231384235900`
- `codex/v03-integration`: `7112961...` 튜토리얼 포커스 수정 포함
- `release/v0.3`: 최신 `main`과 `codex/v03-integration`을 merge commit으로 통합하며 최종 SHA는 세션 핸드오프에 기록
- `v.03`은 `v.02`를 완전히 포함한다.
- `main` 고유 변경은 GitHub Pages 계보와 저장소 운영 정책이다.

태그 대상은 다음과 같이 고정한다.

- `v0.2.0` → `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`
- `v0.3.0` → `199d2d0...`과 `66d418d...`를 모두 조상으로 포함하고, RC1 문서를 정식 릴리스 문서로 정리한 뒤 전체 검수를 통과한 새 `main` 통합 커밋

`v0.3.0`의 최종 전체 SHA는 통합 검수 후 `docs/handoff/CURRENT.md`에 기록한다. 후보 SHA `199d2d0...`에 미리 태그하거나 v0.2와 v0.3 태그를 같은 커밋에 붙이지 않는다.

정리 순서는 `v.03` 통합, RC1 명칭과 릴리스 문서 정리, `main` 병합, 위 매핑에 따른 태그 생성, 미커밋 후속 수정의 패치 분리 순이다. 전체 검증과 게임 CI 필수 체크 추가는 사용자가 명시적으로 요청한 출시 작업에서만 진행한다. 브랜치·태그 Ruleset은 이미 적용됐으며 세부 진행 상태는 `docs/handoff/CURRENT.md`를 따른다.
