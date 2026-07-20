# 제품 2.0 Phase 1 결정 데이터 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p01-decision-contracts`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `b0b285e76e287dc2d3d7dd4d424f7519336b6c7a`
- 마지막 제품 커밋 SHA: `bf4edecf3324ad4c5868e6980709805aef34f89a`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #45

## 2. 이번 세션 목표

- 요청 사항: 승인된 2.0 핵심 재구축의 Phase 1을 완료하고 다음 Phase가 의존할 데이터·결과 경계를 고정한다.
- 완료 조건: Encounter, Facility, Command, weighted path의 유효·무효 계약과 동일 seed 동일 결과 형식을 Godot 테스트로 검증한다.
- 범위에서 제외한 사항: UI, 실제 경로 선택, 시설 수치, 적 행동, 밸런스, 저장, 그래픽·오디오 자산.

## 3. 완료한 작업

- 구현: 네 catalog validator와 canonical SHA-256 fingerprint를 포함한 고정 seed evidence builder를 추가했다.
- 스토리 및 데이터: `data/v20/`을 레거시 catalog와 분리해 로드하고 Phase 1 계약 버전·weighted path 6개 비용 항·자동 결과 해석 한계를 선언했다.
- 밸런스: 변경하지 않았다. 기존 시설 A/B 대리 검사를 그대로 통과했다.
- UI/UX: 변경하지 않았다.
- 저장 및 호환성: 저장 파일과 migrator를 변경하지 않았고 1.2 catalog를 대체하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/decision_contracts.json` | v2 계약 namespace, schema 버전, 경로 비용 항, evidence 해석 한계 | 완료 |
| `scripts/core/DataRegistry.gd` | v2 계약만 별도 dictionary로 로드 | 완료 |
| `scripts/v20/contracts/V20ContractValidator.gd` | 네 catalog 구조·범위·참조 검증 | 완료 |
| `scripts/v20/contracts/V20DecisionEvidence.gd` | 고정 seed 선택과 canonical 결과 fingerprint | 완료 |
| `tools/fixtures/v20/*.json` | 유효 bundle과 종류별 무효 fixture | 완료 |
| `tools/tests/V20DecisionContractsTest.*` | registry·fixture·재현·변조 회귀 21개 assertion | 완료 |
| `tools/tests/core_verification_suite.json` | Phase 1 검사를 quick/full 목록에 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: UI·씬·자산을 변경하지 않아 시각 검수 대상이 아니다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20DecisionContractsTest.tscn` | PASS, 21 assertions | `tools/tests/V20DecisionContractsTest.gd` |
| 2 | `DemoSmokeTest.tscn` | PASS | 기존 핵심 부팅 smoke |
| 3 | `Update3DataContractTest.tscn` | PASS, 21 assertions | 기존 누적 catalog 회귀 |
| 4 | `BalanceSimulation.tscn -- --assert-facility-choices` | PASS | 기존 시설 A/B 대리 유지 |
| 5 | JSON parse, `git diff --check` | PASS | 변경 JSON·작업 트리 |
| 6 | 전체 회귀 테스트 | NOT_REQUESTED | Phase 1 관련 검사만 실행 |
| 7 | 시각/실플레이 검수 | NOT_REQUESTED | UI·전투 동작 변경 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `bf4edecf3324ad4c5868e6980709805aef34f89a` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 요청 범위의 관련 테스트는 모두 통과했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: bf4edecf3324ad4c5868e6980709805aef34f89a
- Review range: b0b285e76e287dc2d3d7dd4d424f7519336b6c7a..bf4edecf3324ad4c5868e6980709805aef34f89a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: validator는 구조 계약만 고정하며 실제 경로·시설·명령 결과는 후속 Phase에서 연결해야 한다.
- 밸런스 관찰 항목: HP 상한 1.35는 계약으로만 고정됐고 Encounter 수치 조정은 Phase 8~9 범위다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 자동 evidence는 재미·이해도 검증이 아니며 Phase 11 실제 사용자 관찰을 대체하지 않는다.

## 8. 다음 작업 순서

1. `codex/v20-p02-ui-information-architecture`에서 PC 관리·전투 상시 정보와 컨텍스트 드로어를 분리하고 1280×720 계약을 검증한다.
2. 상시 관리 주 행동을 5개 이하, 전투 명령 자리를 4개 이하로 줄이되 Phase 2에서는 명령 효과를 구현하지 않는다.
3. 실제 관리·전투 화면을 실행해 겹침과 전장 가림을 확인한 뒤 Phase 3 직접 배치 UX로 넘어간다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 의도한 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0 핸드오프에 기록된 UID 5개이며 수정·스테이징하지 않았다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 관련 테스트의 로컬 `tmp/` 산출물만 있으며 커밋하지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 그래픽·오디오 자산 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
