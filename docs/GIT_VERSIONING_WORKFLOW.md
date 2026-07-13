# Git 버전 및 릴리스 운영 규칙

최종 갱신: 2026-07-13

이 문서는 v0.2 이후의 버전 계보를 보존하면서 `main`을 최신 안정판으로 유지하고, 개발·검수·배포 산출물이 섞이지 않게 하는 저장소 운영 기준이다.

## 1. 저장소의 기준점

| 구분 | 이름 예시 | 역할 | 수명 |
|---|---|---|---|
| 최신 안정판 | `main` | 전체 검수를 통과한 최신 버전 | 영구 |
| 정확한 출시본 | `v0.4.0` | 이동하지 않는 출시 스냅샷 | 영구 |
| 마이너 통합 | `release/v0.4` | v0.4 기능을 모아 검수하는 브랜치 | 출시 후 동결 또는 유지보수 |
| 구현 작업 | `codex/v04-monsters` | 한 가지 기능, 데이터 또는 자산 작업 | 병합 후 삭제 가능 |
| 테스트·실험 | `test/v04-balance` | 밸런스, Web, UX 실험 | 검증 후 삭제 가능 |
| 패치 | `hotfix/v0.4.1` | 출시판의 긴급 수정 | 출시 후 삭제 가능 |

브랜치는 이동할 수 있으므로 백업 기준이 아니다. 각 완성본의 기준은 반드시 SemVer 태그다. 기존 `v.02`, `v.03` 브랜치는 삭제하지 않지만 이후 정확한 출시 지점은 각각 `v0.2.0`, `v0.3.0` 같은 태그로 고정한다.

## 2. 권장 계보

```text
main (최신 안정판)
  └─ release/v0.4
       ├─ codex/v04-story
       ├─ codex/v04-monsters
       ├─ codex/v04-art
       └─ test/v04-balance
             ↓ 구현·검수 완료
       release/v0.4 → main PR
             ↓
       tag v0.4.0
             ↓
       GitHub Release에 Web/Windows 빌드 첨부
             ↓
       release/v0.5를 최신 main에서 시작
```

다음 버전은 항상 최신 `main`에서 만든다. `v.03`에서 바로 `v.04`, `v.04`에서 바로 `v.05`로 이어 붙이는 방식은 사용하지 않는다. 모든 완성판이 `main`으로 돌아온 뒤 다음 버전을 시작해야 계보가 한 줄로 유지된다.

## 3. 버전 개발 절차

### 시작

1. `main`이 원격 최신 상태이며 작업 트리가 정리되어 있는지 확인한다.
2. `docs/handoff/CURRENT.md`와 대상 버전의 요구사항을 확인한다.
3. `release/v0.N`을 최신 `main`에서 만든다.
4. 스토리, 몬스터, 밸런스, UI, 그래픽처럼 독립 검수가 가능한 단위로 `codex/vNN-*` 작업 브랜치를 만든다.

### 구현과 검수

1. 작업 브랜치에서 기능과 관련 테스트를 함께 구현한다.
2. 관련 스모크 테스트, 전체 검증, 시각 검수와 실제 플레이 검수를 실행한다.
3. 별도 검수 에이전트가 코드, 데이터 계약, 밸런스, UI, 자산 연결과 회귀 위험을 검토한다.
4. 지적 사항을 수정한 뒤 동일 검수와 회귀 테스트를 다시 실행한다.
5. 필수 검수가 통과할 때까지 3~4단계를 반복한다.
6. 핸드오프 문서를 갱신하고 작업 브랜치를 `release/v0.N`에 PR로 병합한다.

### 출시

1. `release/v0.N`에서 전체 자동 검증과 출시 해상도 시각 검수를 실행한다.
2. 저장 마이그레이션, DAY 진행, 엔딩 도달, 콘텐츠 누락, Web 부팅을 확인한다.
3. P1/P2 미해결 항목이 0인지 확인한다.
4. README 버전, 정식 릴리스 노트와 `docs/handoff/CURRENT.md`를 최종 상태로 갱신하고 다시 검수한다.
5. `release/v0.N`을 `main`에 PR로 병합한다.
6. 병합된 `main` 커밋에 주석 태그 `v0.N.0`을 만든다.
7. 태그에서 Web/Windows 빌드를 생성하여 같은 태그의 GitHub Release에 첨부한다.
8. Release 자산의 `build-manifest.json`을 검증하고 배포한다.

## 4. 패치와 과거 버전 유지보수

- 과거 버전의 긴급 수정은 해당 출시 태그에서 `hotfix/v0.N.P`를 만든다.
- 수정 후 동일 버전 검수와 회귀 테스트를 실행한다.
- 패치를 `main`과 현재 활성 `release/v0.M`에 모두 반영하여 다음 버전에서 수정이 사라지지 않게 한다.
- 새 태그 `v0.N.P`를 만들고 이전 태그를 이동시키지 않는다.
- 기존 `v.02`, `v.03` 브랜치는 해당 계열 유지보수 브랜치로 남길 수 있지만, 정확한 출시본은 태그로 식별한다.

## 5. Web 및 테스트 버전

- Web/Windows 실행 파일과 PCK는 소스 버전 백업 수단이 아니다.
- 빌드는 소스 태그에서 재생성할 수 있어야 하며 GitHub Release 또는 Actions artifact에 둔다.
- 현재 `.github/workflows/deploy-web-demo.yml`처럼 Release 자산을 Pages로 배포하는 흐름을 유지한다.
- Release 자산 이름에는 버전을 포함한다. 예: `mawangseong-v0.4.0-web.zip`.
- 빌드 ZIP 루트에 `build-manifest.json`을 포함한다. 고정 형식과 검증 절차는 `docs/release/BUILD_MANIFEST.md`를 따른다.
- `build-manifest.json`에는 태그, 전체 SHA, Godot 버전, UTC 생성 시각, 실제 Full 러너 원본 보고서 경로·해시와 ZIP 전체 파일의 SHA-256 및 바이트 크기를 기록한다.
- 배포할 SemVer 태그 커밋은 현재 `main`의 조상이어야 한다. 태그 내부의 정식 카탈로그와 실제 Full 러너 보고서가 모두 일치해야 배포한다.
- 브라우저, Web 성능 또는 배포 파이프라인 실험은 `test/web-*`에서 진행한다. 실험 결과물 자체를 장기 브랜치로 보존하지 않는다.

## 6. 그래픽 자산 규칙

- 신규 그래픽은 기본적으로 GPT 내부 이미지 생성 모델을 사용한다.
- 생성 원본과 프롬프트는 `assets/source/imagegen/<asset>/`에 두고 `SOURCE.md`에 모델, 날짜, 목적, 대상 버전, 후처리와 런타임 경로를 기록한다.
- 정책 CI가 읽을 수 있도록 `SOURCE.md`에는 다음 고정 필드를 모두 쓴다.

~~~text
- Generation model: GPT internal image generation
- Generated date: YYYY-MM-DD
- Target version: v0.N 또는 v0.N.P
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

현재 `repository-policy` 워크플로는 운영 정책 검사기와 두 검사기의 영구 회귀 테스트를 실행한다. 실제 게임 전체 검증인 `core-verification`, `web-export-smoke`는 v0.3 통합 검증 단계에서 워크플로를 추가하고 실제 성공 이력을 만든 뒤 Ruleset 필수 체크에 추가한다.

GitHub의 `github-pages` Environment는 배포 브랜치를 `main`으로 제한한다. 워크플로의 `github.ref` 조건도 함께 유지하며, 둘 중 하나만으로 배포 보호가 완료됐다고 보지 않는다.

2026-07-13 현재 GitHub 저장소 설정은 merge commit만 허용하고 squash merge와 rebase merge는 비활성화했다. 브랜치 Ruleset은 관리자 포함 우회자를 두지 않으므로 직접 푸시도 차단한다. 이 설정은 검수 기준 SHA와 실제 병합 이력의 관계를 보존한다.

## 9. 현재 계보 정리 계획

2026-07-13 기준 GitHub 상태는 다음과 같다.

- `main`: `66d418dea29b7f9e586211722b0f248420ce6bff`
- `v.02`: `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`
- `v.03`: `199d2d0347e78f9c62b1c15e9369231384235900`
- `v.03`은 `v.02`를 완전히 포함한다.
- `main` 고유 변경은 GitHub Pages 배포 워크플로다.

태그 대상은 다음과 같이 고정한다.

- `v0.2.0` → `98eb6e666fe1d933f9121bc83fb41ba75ed2ca69`
- `v0.3.0` → `199d2d0...`과 `66d418d...`를 모두 조상으로 포함하고, RC1 문서를 정식 릴리스 문서로 정리한 뒤 전체 검수를 통과한 새 `main` 통합 커밋

`v0.3.0`의 최종 전체 SHA는 통합 검수 후 `docs/handoff/CURRENT.md`에 기록한다. 후보 SHA `199d2d0...`에 미리 태그하거나 v0.2와 v0.3 태그를 같은 커밋에 붙이지 않는다.

정리 순서는 `v.03` 통합, RC1 명칭과 릴리스 문서 정리, 전체 검증, `main` 병합, 위 매핑에 따른 태그 생성, 미커밋 후속 수정의 패치 분리, 게임 CI 필수 체크 추가 순이다. 브랜치·태그 Ruleset은 이미 적용됐으며 세부 진행 상태는 `docs/handoff/CURRENT.md`를 따른다.
