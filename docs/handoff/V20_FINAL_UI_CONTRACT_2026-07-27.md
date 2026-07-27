# 제품 2.0 최종 UI·정식 출시 이식 U0 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-contract`
- 기준 브랜치 및 SHA: `release/v2.0@b63a5f13476f7d28ffa974dacc9a3186e76b67b7`
- 문서 Reviewed SHA: `a0faec32b0e029f17742b6d507f39addfba8e0e8`
- 마지막 커밋 SHA: handoff·`CURRENT.md` 종료 커밋 전 기준 `a0faec32b0e029f17742b6d507f39addfba8e0e8`
- 원격 푸시 여부: 작성 시점 미푸시
- 관련 PR 또는 태그: U0 PR 생성 전, 태그·Release 변경 없음

## 2. 이번 세션 목표

- 요청 사항: 제공된 `마왕성 v2.0 최종 UI 수정 및 정식 출시 이식 실행계획서`에 따라 첫 단계 U0 문서 PR을 수행한다.
- 완료 조건: 계획서 저장소 보존, 검수 시점과 사용자 승인 게이트 고정, 기존 PR 5/full verification을 F1으로 이동, 수용 프로토콜을 UI 승인 테스트와 출시 직전 전체 검수로 분리, runtime·data·scene·asset 변경 0건, 문서 정책 검사 PASS.
- 범위에서 제외한 사항: UI 코드, 전투 밸런스, AI, spawn, HP/ATK, 시설·몬스터 효과, 전체 회귀·전체 플레이·검수 에이전트, build·배포·태그·Release.

## 3. 완료한 작업

- 구현: 코드 변경 없음.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음. `release/v2.0`의 밸런스 후보와 fixture를 수정하지 않았다.
- UI/UX: 런타임 변경 없이 U1~U5의 화면별 목표·테스트·게이트와 G1 사용자 승인 형식을 문서로 고정했다.
- 저장 및 호환성: 변경 없음.
- 출시 절차: G1 전 정식 출시선 이식 금지, P0~P4 선별 재구현, F0 RC 동결, F1 전체 검수 1회, F2 동일 source tree 빌드 순서를 고정했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | U0~U5·P0~P4 전체 검수 금지, G1 사용자 승인, F1 단일 전체 검수와 이식 금지 규칙 | 완료 |
| `docs/design/V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md` | 사용자가 제공한 최종 UI·정식 출시 이식 실행계획 원문 저장소 보존 | 완료 |
| `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md` | 과거 PR 5/PR 6/L0~L7을 U0~U5·G1·P0~P4·F0~F2로 개정 | 완료 |
| `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md` | v2.0 사용자 UI 승인 테스트와 정식 출시 직전 F1 전체 검수 분리 | 완료 |
| `docs/handoff/V20_FINAL_UI_CONTRACT_2026-07-27.md` | U0 세션 근거와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업을 U0/U1 기준으로 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: N/A
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: U0는 문서 전용이므로 실행하지 않음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 필수 문서와 제공 계획서 UTF-8 전체 확인 | PASS | `AGENTS.md`, `CURRENT.md`, 구현 계획, 수용 프로토콜, 밸런스 후보 핸드오프, 제공 계획서 |
| 2 | U0 변경 경로 allowlist와 runtime·data·scene·asset 변경 검사 | PASS | Reviewed SHA 기준 비-handoff 변경 4개 문서, 금지 경로 0건 |
| 3 | `git diff --check b63a5f1..a0faec3` | PASS | whitespace 오류 0건 |
| 4 | `ValidateRepositoryPolicy.ps1 -BaseRef b63a5f1 -HeadRef codex/v20-final-ui-contract` | PASS | `4 final files, 2 commits inspected` |
| 5 | `TestRepositoryPolicy.ps1` | PASS | 9 scenarios |
| 6 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 계획에 따라 F1 전 실행 금지 |

외부 계획서의 의미와 문장은 저장소 계획서에 보존했다. 정책 검사 통과를 위해 Markdown hard break의 행 끝 공백 4개와 EOF의 추가 빈 줄만 정규화했다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | 문서 U0 | `a0faec32b0e029f17742b6d507f39addfba8e0e8` | N/A | N/A | 로컬 직접 정책 검사 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 F1 전 실행 금지 항목이다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 이 handoff와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: a0faec32b0e029f17742b6d507f39addfba8e0e8
- Review range: b63a5f13476f7d28ffa974dacc9a3186e76b67b7..a0faec32b0e029f17742b6d507f39addfba8e0e8
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: U0는 런타임을 변경하지 않아 새 런타임 회귀는 없다.
- 밸런스 관찰 항목: 밸런스는 동결했다. PR 4 후보 수치는 F1 전체 검수 전까지 공식 PASS가 아니다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 원격 `repository-policy`는 PR 생성 뒤 확인해야 한다.

## 8. 다음 작업 순서

1. U0 PR을 `release/v2.0` 대상으로 열고 원격 `repository-policy` PASS 뒤 merge commit으로 병합한다.
2. U0 merge SHA에서 `codex/v20-final-ui-foundation`을 만들고 `V20UITheme`, 타이틀과 침입 확인 UI만 구현한다.
3. U1에서는 관련 UI 테스트와 1280×720·1366×768·1920×1080 실제 렌더만 수행하고 전체 검수는 실행하지 않는다.
4. U1 merge 전 U2를 시작하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: handoff·`CURRENT.md` 종료 변경만 존재
- 미커밋 파일: `docs/handoff/V20_FINAL_UI_CONTRACT_2026-07-27.md`, `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: U0 worktree에는 없음. 원래 `게임소스/` worktree의 사용자 미추적 파일은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 별도 worktree `v20-u0`
- 빌드/캡처 산출물 위치: 없음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 문서 정책 검사 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 — 요청되지 않았고 계획상 F1 전 금지
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 — 자산 변경 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
