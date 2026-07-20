# 제품 2.0 Phase 5 시설 재설계 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p05-facility-rework`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `b6a8d7b43e047ec74896f573c16b1a598e2c737e`
- 마지막 제품 커밋 SHA: `d25e3655a592be74bdc0c4149d8750f0c6116183`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #49

## 2. 이번 세션 목표

- 요청 사항: 시설을 단순 수치 보너스가 아니라 경로·전투·몬스터 역할과 결합된 전략 도구로 재설계한다.
- 완료 조건: 다섯 시설의 강점·카운터·시너지·결산 지표를 선언하고, 활성화·무력화·경로 비용·목표 선호가 결정 증거로 남는다.
- 범위에서 제외한 사항: 몬스터 역할 AI, 전술 명령, DAY 1~5 encounter 연결, 최종 밸런스.

## 3. 완료한 작업

- 구현: 시설 전투 상태, 활성화·무력화, 경로 문맥, 목표 편향, 전투 효과와 결산 요약을 제공하는 deterministic 서비스를 추가했다.
- 스토리 및 데이터: 바리케이드·병영·미끼 보물·감시 초소·회복 둥지 다섯 시설을 v2 전용 catalog로 선언했다.
- 밸런스: 각 시설은 비용, 경로/목표 효과, 활성 효과, counter와 monster synergy를 별도 값으로 가진다.
- UI/UX: 변경 없음. Phase 3 배치판과 Phase 4 경로 preview가 소비할 데이터 계약만 추가했다.
- 저장 및 호환성: 저장 변경 없음. 기존 시설 catalog와 시뮬레이션을 대체하지 않고 `data/v20/` namespace로 분리했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/facilities.json` | 다섯 시설의 비용·효과·counter·synergy·metric 계약 | 완료 |
| `scripts/v20/facilities/V20FacilityService.gd` | 전투 상태·활성화·무력화·경로/목표/결산 계산 | 완료 |
| `scripts/core/DataRegistry.gd` | v2 시설 catalog 별도 로드 | 완료 |
| `tools/tests/V20FacilityReworkTest.*` | 시설 전략 차이와 결정 증거 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: UI 변경이 없어 별도 캡처를 만들지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20FacilityReworkTest.tscn` | PASS, 27 assertions | catalog·route·goal·activation·disable·summary·synergy/counter |
| 2 | `V20StrategicRoutingTest.tscn` | PASS, 14 assertions | Phase 4 경로 회귀 |
| 3 | `BalanceSimulation.tscn -- --assert-facility-choices` | PASS | 기존 시설 선택 회귀 |
| 4 | JSON/suite parse, `git diff --check` | PASS | 변경 파일 |
| 5 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `d25e3655a592be74bdc0c4149d8750f0c6116183` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: d25e3655a592be74bdc0c4149d8750f0c6116183
- Review range: b6a8d7b43e047ec74896f573c16b1a598e2c737e..d25e3655a592be74bdc0c4149d8750f0c6116183
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: Phase 6 역할 서비스와 Phase 8 encounter가 선언된 synergy/counter를 실제 의사결정에 연결해야 한다.
- 밸런스 관찰 항목: 초기 설치 비용, 문 봉쇄 비용과 목표 편향은 Phase 9에서 함께 조정한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 자동 A/B 차이는 사람의 재미·이해도 검증이 아니다.

## 8. 다음 작업 순서

1. Phase 6에서 슬라임·고블린·임프의 기존 양자 특화를 전투 역할 계약으로 연결한다.
2. 각 역할이 이동·목표·시설 synergy·결산 지표를 다르게 만들게 한다.
3. 기존 specialization 선택 회귀를 함께 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
