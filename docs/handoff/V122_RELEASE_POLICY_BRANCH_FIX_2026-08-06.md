# v1.2.2 릴리스 브랜치 정책 정합 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-release-policy`
- 기준 브랜치 및 SHA: `release/v1.2.2` / `45feecfecacd5ca745050bd195a9dd0395137eb7`
- 마지막 기능 커밋 SHA: `e4100f9120479a69d67790c5af15184394637136`
- 원격 푸시 여부: 이 문서 작성 시점에는 미푸시. 기준 릴리스 브랜치보다 기능·테스트 2커밋 앞선다.
- 관련 PR 또는 태그: 작업 PR은 아직 생성 전이다. PR `#80`은 `release/v1.2.2`에 merge commit `45feecfecacd5ca745050bd195a9dd0395137eb7`로 병합됐다. `v1.2.2` 태그와 Release는 아직 없다.

## 2. 이번 세션 목표

- 요청 사항: 최종 검수와 정식 출시 절차를 끝까지 진행한다.
- 발견한 출시 차단 원인: 저장소와 버전 문서가 공식 브랜치로 지정한 `release/v1.2.2`를 정책 검사기의 브랜치 허용식이 거부했다.
- 완료 조건: SemVer patch 릴리스 브랜치를 허용하고 잘못된 네 자리 버전·구분자 없는 접미사는 계속 거부하며, 자체 회귀와 독립 검수에서 P1/P2/P3 0건을 확인한다.
- 범위에서 제외한 사항: 제품 코드·데이터·자산·씬·빌드 프리셋 변경.

## 3. 완료한 작업

- 구현: `release/v1.2`와 `release/v1.2.2`를 모두 허용하도록 릴리스 브랜치 정규식에 선택적 patch 숫자를 추가했다.
- 회귀 방지: `release/v1.2.2` 허용, `release/v1.2.2.3` 거부, `release/v1.2.2foo` 거부를 자체 테스트에 고정했다.
- 기존 규칙 보존: `main`, `codex/*`, `test/*`, 3자리 `hotfix/*`, `dependabot/*` 판정은 변경하지 않았다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX: 변경 없음.
- 저장 및 호환성: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/ci/ValidateRepositoryPolicy.ps1` | SemVer patch 릴리스 브랜치 허용 | 완료 |
| `tools/ci/TestRepositoryPolicy.ps1` | 정상 1개·비정상 2개 브랜치 회귀 고정, 총 12개 시나리오 | 완료 |
| `docs/handoff/V122_RELEASE_POLICY_BRANCH_FIX_2026-08-06.md` | 원인·검수·다음 출시 절차 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 최우선 상태 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음.
- 생성 모델: 해당 없음.
- 생성 원본 경로: 변경 없음.
- `SOURCE.md` 경로: 변경 없음.
- 런타임 최종 자산 경로: 변경 없음.
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음.
- 게임 연결 및 실제 렌더 확인 결과: 제품 렌더 변경이 없어 재확인 대상이 아니다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `tools/ci/TestRepositoryPolicy.ps1` | PASS, 12/12 | 자체 테스트 출력 |
| 2 | 허용·거부 브랜치 수동 정규식 행렬 | PASS, 12/12 | 로컬 PowerShell 출력 |
| 3 | `git diff --check` | PASS | 로컬 Git 출력 |
| 4 | 독립 읽기 전용 검수 1차 | PASS, P1/P2 0·P3 1 | 검수 에이전트 `019fd2d3-6398-7d50-a0c2-1ce3068de487` |
| 5 | P3 거부 회귀 보강 후 재검수 | PASS, P1/P2/P3 0 | 같은 검수 에이전트 |
| 6 | 제품 Full core verification | PASS, 156/156 | 제품 검수 SHA `d14be429115558a2e65c1575305b07da06c3aef7`, `tmp/core_verification/runs/20260806_033754/report.json` |

제품 Full 이후 제품 코드·데이터·자산·씬은 바뀌지 않았다. 이번 변경은 PR 브랜치명 판정과 그 자체 테스트뿐이며, 최종 `main` 병합 SHA에서는 Full 156개와 Windows 후보를 다시 검증한다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `019fd2d3-6398-7d50-a0c2-1ce3068de487` | `45feecfecacd5ca745050bd195a9dd0395137eb7..5429cb920b5672829a2d2df34a3438f2e9dd7284` | `5429cb920b5672829a2d2df34a3438f2e9dd7284` | 잘못된 patch 릴리스 이름 거부 테스트가 없다는 P3 1건 | 네 자리 버전과 구분자 없는 접미사 거부 테스트 추가 | `tools/ci/TestRepositoryPolicy.ps1` | PASS, P1/P2 0·P3 1 |
| 2 | `019fd2d3-6398-7d50-a0c2-1ce3068de487` | `45feecfecacd5ca745050bd195a9dd0395137eb7..e4100f9120479a69d67790c5af15184394637136` | `e4100f9120479a69d67790c5af15184394637136` | 없음 | P3 회귀 테스트 보강 확인 | 두 정책 파일과 자체 테스트 출력 | PASS, P1/P2/P3 0 |

- 남은 P1/P2 지적: 0건.
- 실행하지 못한 필수 검수와 이유: 없음. 최종 병합 SHA 전체 회귀와 재빌드는 태그 전 단계로 남아 있다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. `e4100f9` 이후 이 핸드오프와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: 019fd2d3-6398-7d50-a0c2-1ce3068de487
- Reviewed SHA: e4100f9120479a69d67790c5af15184394637136
- Review range: 45feecfecacd5ca745050bd195a9dd0395137eb7..e4100f9120479a69d67790c5af15184394637136
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동·독립 검수 범위에서 출시 차단 사항 없음.
- 밸런스 관찰 항목: 제품 변경이 없어 새 관찰 항목 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 코드 서명 인증서는 여전히 없어 최종 Windows EXE는 `NotSigned`다.

## 8. 다음 작업 순서

1. `codex/v122-release-policy`를 푸시하고 `release/v1.2.2` 대상 PR을 merge commit으로 병합한다.
2. `release/v1.2.2 → main` PR의 필수 정책 체크를 통과시켜 merge commit으로 병합한다.
3. 최종 `main` SHA에서 Full 156개, Windows export·부팅·manifest·해시를 재검증한 뒤 주석 태그 `v1.2.2`와 GitHub Release를 게시한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 기능 SHA `e4100f9`에서 깨끗했으며 현재는 이 핸드오프 2개만 문서 변경이다.
- 미커밋 파일: `docs/handoff/V122_RELEASE_POLICY_BRANCH_FIX_2026-08-06.md`, `docs/handoff/CURRENT.md`.
- 의도하지 않은 기존 변경: 없음.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 기존 최종검수 후보 `tmp/v122_final_review_candidate/d14be42/`와 Full 보고서 `tmp/core_verification/runs/20260806_033754/`를 유지한다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 전체 회귀·검수 에이전트 완료
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
