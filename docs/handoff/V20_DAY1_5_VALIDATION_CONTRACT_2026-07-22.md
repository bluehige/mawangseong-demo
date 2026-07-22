# DAY 1~5 검증 제품 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-22
- 목표 버전: `release/v2.0` DAY 1~5 행동 계약 검증선
- 작업 브랜치: `codex/v20-day1-5-product-contract`
- 기준 브랜치 및 SHA: `origin/release/v2.0` `cd4be74bcd34c9ae9b1260fd84ada30b0b6537d3`
- 마지막 검토 대상 커밋 SHA: `cbd3bff2069c9967eee5a02e9a7c5fb5e7572b8c`
- 원격 푸시 여부: 예
- 관련 PR 또는 태그: Draft PR #66 `https://github.com/bluehige/mawangseong-demo/pull/66`; 불변 `v1.2.1` tag object `eca4d82d6d5820f807eb98ac33c3959220d8f603`, peeled commit `c483d135b13cf9771ee43b045ba2c3dde51573ee`

## 2. 이번 세션 목표

- 요청 사항: 코드 구현 전에 DAY 1~5 진행, 전략 질문, 배치 인과, 두 대응, 시간, 네 증거 묶음, 완료·중단·롤백과 후속 PR 순서를 docs 전용 PR로 고정한다.
- 완료 조건: 추상 표현 없이 플레이어 행동, 시스템 규칙, 수정 파일, 테스트, 지표와 합격 기준을 수치로 적고 `release/v2.0` 전체 병합을 금지한다.
- 범위에서 제외한 사항: 코드·data·scene·asset·workflow 구현, 신규 콘텐츠, DAY 6 이후, 모바일 전면 개편, 신규 최종 그래픽, build와 실플레이 실행, 기존 출시·저장·공개본 변경.

## 3. 완료한 작업

- 구현: 없음. PR 1~6의 수정 파일 allowlist, 선행 게이트와 rollback 책임만 작성했다.
- 스토리 및 데이터: 신규 스토리·몬스터·적·시설을 추가하지 않았다. 기존 적의 DAY별 초기 후보 HP·ATK·spawn은 측정 전 후보로만 문서화했다.
- 밸런스: DAY별 A/B 두 대응, 오답 C, A와 monster slot 하나만 다른 D, 45~106초 DAY별 중앙값 범위와 120초 timeout을 고정했다. 현재 판정은 `PENDING`이다.
- UI/UX: 하루를 `INTRUSION_BRIEF → PLACEMENT → DEFENSE_START → COMBAT → RESULT` 다섯 상태로 고정했다. UI 파일은 수정하지 않았다.
- 저장 및 호환성: 기존 제품 저장의 읽기·쓰기를 금지하고 v20 schema 3 migration, sentinel hash와 autosave 재활성 게이트를 PR 1 계획에 고정했다.
- 출시 경계: `release/v2.0` 전체 병합·범위 cherry-pick·덮어쓰기를 금지하고, 수용 뒤에만 `origin/main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`에서 새 출시선을 만들도록 고정했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | 검증선과 새 출시선 계보 규칙 | 완료 |
| `docs/design/V20_DAY1_5_VALIDATION_CONTRACT.md` | DAY 1~5 상위 제품 계약 | 완료 |
| `docs/design/V20_DAY1_5_IMPLEMENTATION_PR_PLAN.md` | PR 0~6과 L0~L7 순서·allowlist·게이트 | 완료 |
| `docs/playtest/v20/DAY1_5_ACCEPTANCE_PROTOCOL.md` | 자동·물리 70전·수동 24전·초회 10명 절차 | 완료 |
| `docs/design/V20_CORE_REBUILD_MASTER_SPEC.md` | 과거 Phase 0 문서 표시와 폐기 항목 안내 | 완료 |
| `docs/design/V20_KEEP_REWORK_DEFER_MATRIX.md` | 과거 매트릭스 표시와 현재 상위 계약 안내 | 완료 |
| `docs/PRODUCT_VERSIONING.md` | 검증선과 안정판 기반 출시 후보 분리 | 완료 |
| `docs/GIT_VERSIONING_WORKFLOW.md` | merge 금지와 ancestry 검사 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 단일 진입점과 PR 1 순서 | 완료 |
| `docs/handoff/V20_DAY1_5_VALIDATION_CONTRACT_2026-07-22.md` | 이번 docs-only 세션 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 해당 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 자산·UI를 수정하지 않아 실행하지 않음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `git diff --check`와 staged diff scope 확인 | PASS | Reviewed SHA `cbd3bff2069c9967eee5a02e9a7c5fb5e7572b8c` |
| 2 | 변경 Markdown table의 unescaped pipe 열 수 검사 | PASS | 계약·계획·프로토콜 |
| 3 | `v1.2.1..origin/main` 파일 목록과 runtime 경로 diff 확인 | PASS, 전체 6개·runtime 0개 | 제품 계약 1절 |
| 4 | 계약·runtime 파일 경로·수용 수치의 read-only 교차검사 3회 | P0 0, P1 0 | 계약·계획·프로토콜 |
| 5 | 전체 회귀 테스트 | NOT_REQUESTED | docs-only 변경 |
| 6 | 게임 build·시각·실플레이 검수 | NOT_REQUESTED | 사용자가 코드 구현을 금지함 |

read-only 교차검사는 문서 모순을 줄이기 위한 대상 검사였으며, 사용자 요청의 전체 회귀 또는 공식 검수 에이전트 PASS로 기록하지 않는다.

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: 공식 전체 검수는 NOT_REQUESTED이므로 N/A
- 실행하지 못한 필수 검수와 이유: 없음. 코드·build·실플레이는 현재 docs-only 범위가 아니다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: cbd3bff2069c9967eee5a02e9a7c5fb5e7572b8c
- Review range: cd4be74bcd34c9ae9b1260fd84ada30b0b6537d3..cbd3bff2069c9967eee5a02e9a7c5fb5e7572b8c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 문서만 고정했으며 PR 1~5 구현·실행은 시작하지 않았다.
- 밸런스 관찰 항목: DAY별 적 HP·ATK·spawn, A/B, C와 시간은 초기 후보다. 실제 물리 70전과 수동·초회 결과 전에는 PASS가 아니다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 숙련 QA 2명과 초회 사용자 10명 모집, Windows·Web debug acceptance build 보존이 필요하다.
- 출시 위험: `DAY1_5_ACCEPTED`와 별도 출시 승인이 없으므로 `release/v2.0-product`, `main` PR, `v2.0.0`, Release와 공개 URL 교체를 시작할 수 없다.

## 8. 다음 작업 순서

1. PR #66 병합 뒤 PR 1에서 `data/v20/dungeon_layouts.json`, spatial model과 adapter만 수정해 준비·전투 zone·slot·좌표를 통합하고 12개 slot 왕복·schema 3·save 격리를 통과한다.
2. PR 2~4를 순서대로 진행해 다섯 상태, 두 retry snapshot, 실제 placement 인과와 DAY 1~5 후보 20전을 통과한다.
3. PR 5에서 자동 계약, 실제 물리 70전, 숙련 QA 24전과 초회 사용자 10명을 같은 source SHA에서 실행한다.
4. PR 6이 `DAY1_5_ACCEPTED`를 동결한 뒤에만 안정판 기반 새 출시선에서 L0~L7을 다시 구현하고 네 증거 묶음을 다시 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 예상 최종 결과: `codex/v20-day1-5-product-contract...origin/codex/v20-day1-5-product-contract`, 변경 없음
- 미커밋 파일: 없음
- 의도하지 않은 기존 변경: 없음. 원본 `게임소스/` 작업트리의 사용자 변경은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 별도 linked worktree `마왕성_v20_day1_5_contract` 사용, stash 없음
- 빌드/캡처 산출물 위치: 생성하지 않음

## 10. 종료 체크리스트

- [x] 구현 전 계약과 사용자 요구사항 대조 완료
- [x] 관련 문서 무결성 검사 통과
- [x] 사용자 요청 범위의 docs-only 검사 통과
- [x] 요청되지 않은 전체 회귀·실플레이를 `NOT_REQUESTED`로 기록
- [x] 검수 대상 Reviewed SHA 기록
- [x] 그래픽·오디오 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋 대상으로 지정
- [x] 원격 브랜치와 Draft PR #66 생성
