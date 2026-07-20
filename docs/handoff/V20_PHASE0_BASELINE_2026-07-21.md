# 제품 2.0 Phase 0 핵심 재구축 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p00-core-rebuild-contract`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 제품 계약 커밋 SHA: `ca2324eaddac6ccdf72fb533523e8c25543f1b60`
- 원격 푸시 여부: 미푸시
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 공유 대화의 게임 개선안을 원문과 최신 저장소 기준으로 다시 확인하고 전체 재구축을 시작한다.
- 완료 조건: 1.2.1 공개판을 보존하면서 2.0 DAY 1~5 제품 계약, 개발 Phase, 유지·재설계·숨김·연기 경계를 문서로 확정한다.
- 범위에서 제외한 사항: 코드, 데이터, 수치, 씬, 자산, 빌드, 배포와 Phase 1 이후 구현.

## 3. 완료한 작업

- 공유 대화를 끝까지 확인하고 UI/UX, 재미, 건물 배치, 적 패턴, 난이도 지적과 제안된 Phase 0~12를 추출했다.
- 원격을 다시 fetch해 공유 답변의 기준 SHA `7ee0b509...`가 최신 `origin/main`과 동일함을 확인했다.
- 최신 1.2.1 출시 핸드오프와 제품 버전 정책을 읽고 불변 태그·Release·저장 보존 경계를 고정했다.
- `GameRoot.gd`, 관리·전투 컨트롤러, HUD, `RoomGraph.gd`, `WaveManager.gd`, 방·웨이브·적·특화 데이터와 2026-07-10 핵심 재미 감사를 직접 대조했다.
- 공유 답변의 한 부분을 보정했다. 현재 저장소에는 시설 A/B, 지침 차이, DAY 1~3 자동 대리, 다중 seed와 몬스터·시설 기여 계측이 이미 있다. Phase 1은 이를 새로 중복 구현하지 않고 경로·목표·명령 계약으로 확장한다.
- PC DAY 1~5를 먼저 만들고 모바일, DAY 6~30, 연대기·원정·합동기·의회·전초기지·상층은 판매 가능성 게이트 뒤로 연기했다.
- 직접 유닛 이동·공격·수동 스킬은 다시 도입하지 않고 집결·집중·시설 발동 중심의 제한 명령 계약을 채택했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/design/V20_CORE_REBUILD_MASTER_SPEC.md` | 제품 루프, DAY 1~5, UI, 경로, 시설, 명령, 데이터 계약과 Phase 0~12 확정 | 완료 |
| `docs/design/V20_KEEP_REWORK_DEFER_MATRIX.md` | 현재 기능과 자산의 유지·재설계·숨김·연기 경계 | 완료 |
| `docs/handoff/V20_PHASE0_BASELINE_2026-07-21.md` | 이번 기준 조사와 다음 작업 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 제품 2.0 Phase 0을 다음 세션 진입점으로 연결 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: 자산·씬·UI를 변경하지 않아 실행 검수 대상이 아니다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `git fetch origin` 후 `origin/main` SHA 확인 | PASS | `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad` |
| 2 | 공유 대화 본문 전체 확인 | PASS | 사용자 제공 공유 URL |
| 3 | 기준 코드·데이터·감사·핸드오프 대조 | PASS | 마스터 명세 2절과 매트릭스 |
| 4 | 문서 경로·링크·13개 Phase·기준 SHA 검사 | PASS | 콘솔 기록 |
| 5 | `ValidateRepositoryPolicy.ps1` (`base..Reviewed SHA`) | PASS, 2 files / 1 commit | 콘솔 기록 |
| 6 | 전체 회귀 테스트 | NOT_REQUESTED | 문서 전용 Phase 0 |
| 7 | 시각/실플레이 검수 | NOT_REQUESTED | 코드·씬·자산 변경 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | N/A | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 문서 전용 Phase 0이며 전체 검수는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ca2324eaddac6ccdf72fb533523e8c25543f1b60
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..ca2324eaddac6ccdf72fb533523e8c25543f1b60
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 제품 계약은 아직 사용자 승인 전이다. 승인 없이 Phase 1 코드 작업으로 넘어가지 않는다.
- weighted path, 명령력, 시설 수치와 Encounter의 세부 수치는 Phase 1 계약 검증과 Phase 4~9에서 정한다.
- 기존 자동 대리와 A/B 계측은 선택 차이를 보여 주지만 재미·이해도·피로도를 증명하지 않는다.
- DAY 6~30의 방대한 기존 콘텐츠는 삭제하지 않지만, 새 계약에 맞춘 이식 비용이 크다.
- 사용자 소유 미추적 UID 5개가 작업 트리에 있으며 수정·스테이징하지 않았다.

## 8. 다음 작업 순서

1. 사용자가 `V20_CORE_REBUILD_MASTER_SPEC.md`와 유지·재설계 매트릭스의 DAY 1~5 제품 계약을 승인한다.
2. 기준 SHA에서 `release/v2.0` 통합 브랜치를 준비하고 Phase 0 문서를 반영한다.
3. 승인된 `release/v2.0`에서 `codex/v20-p01-decision-contracts`를 만들고 기존 계측을 v2 Encounter·Facility·Command·weighted path 계약으로 확장한다.
4. Phase 1은 UI·실제 경로·시설 수치·밸런스·자산을 바꾸지 않고 validator와 고정 seed 결과 계약만 구현한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 최종 핸드오프 커밋 뒤 로컬 브랜치는 원격 미푸시 상태이며 사용자 소유 미추적 UID 5개만 남긴다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개 외 없음
- 의도하지 않은 기존 변경:
  - `tools/tests/FinaleEveHardeningTest.gd.uid`
  - `tools/tests/Update3BaselineContractTest.gd.uid`
  - `tools/update3_baseline/Update3BaselineSpec.gd.uid`
  - `tools/update3_baseline/Update3BaselineSummary.gd.uid`
  - `tools/update3_baseline/Update3BaselineTrial.gd.uid`
- 스태시 또는 별도 작업공간: 없음
- 빌드/캡처 산출물 위치: 새 산출물 없음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 문서 검증 범위 정의
- [x] 전체 회귀·검수 에이전트가 요청되지 않았음을 기록
- [x] 그래픽·오디오 자산 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 문서 경로·링크·공백 검사 통과
- [x] 의도한 문서만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
