# 제품 2.0 Phase 10 온보딩·재도전·격리 저장 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p10-onboarding-retry`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `c5af46adf1eb0c3a757d79b79b47921ec40070fe`
- 마지막 제품 커밋 SHA: `3dcd79747869b2682983ee5166f8d6406cb8b4e0`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #54

## 2. 이번 세션 목표

- 요청 사항: 타이틀에서 제품 2.0을 명시적으로 시작하고, 90초 안의 첫 의미 있는 선택, 원인 중심 결산, 배치 보존 재도전, 1.2와 분리된 2.0 저장을 실제 DAY 1~5 흐름에 연결한다.
- 완료 조건: 실제 GameRoot에서 2.0 진입→관리→배치→DAY 1 전투→결산→같은 배치 재도전이 이어지고, 저장 왕복 중 1.2 저장은 변하지 않는다.
- 범위에서 제외한 사항: 6~10명 실제 사람 블라인드 테스트, 판매성 Go/No-Go 판정, DAY 6~30 이식, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 구현: 2.0 session service로 DAY 1~5 상태, 난이도·경제·배치·온보딩·재도전 snapshot·결산을 하나의 저장 가능한 계약으로 연결했다.
- 온보딩: 관리 화면 체류 시간만 계측하고 시설 설치·교체, 몬스터 배치, 교리 선택 중 첫 의미 있는 행동이 90초 안에 발생했는지 기록한다. 단계 안내는 0·30·60·90초에 바뀐다.
- UI/UX: PC 타이틀에 2.0 전용 난이도 세 개·새 시작·이어하기를 추가했고, 결과 화면은 패배 원인과 다음 수정 한 가지를 먼저 보여준다.
- 재도전: 전투 직전 시설·몬스터 배치를 snapshot으로 저장하고 패배 뒤 같은 배치를 유지한다. 결산으로 바뀐 경제 잔액은 유지한다.
- 저장 및 호환성: schema 2 envelope를 `user://v20/campaign_v20.json`에 임시 파일→재검증→백업→교체 순서로 저장한다. 최종 재검증 실패 시 백업을 복구하며 1.2 저장 경로는 읽거나 쓰지 않는다.
- runtime 연결: 실제 GameRoot, 관리 배치 board, DAY 1~5 encounter, 명령·시설 상태와 결과 화면을 v2 gate에서만 연결했다. 기존 1.2 흐름은 gate가 꺼진 상태에서 그대로 유지한다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/onboarding.json` | 90초 첫 선택·단계 안내·재도전 약속 계약 | 완료 |
| `scripts/v20/onboarding/V20OnboardingService.gd` | 온보딩 시간·행동·외부 도움·내부 관찰 기록 | 완료 |
| `scripts/v20/session/V20SessionService.gd` | DAY 1~5 session·배치 snapshot·결산·복원 | 완료 |
| `scripts/v20/save/V20SaveStore.gd` | 2.0 namespace atomic 저장·검증·복구 | 완료 |
| `scripts/v20/ui/V20TitleEntryPanel.gd`, `scenes/v20/ui/V20TitleEntryPanel.tscn` | 타이틀의 명시적 2.0 진입 | 완료 |
| `scripts/v20/ui/V20ResultScreen.gd`, `scenes/v20/ui/V20ResultScreen.tscn` | 원인·수정 후보·배치 보존 결과 화면 | 완료 |
| `scripts/game/GameRoot.gd` | 실제 v2 진입·저장·전투·결산·재도전 흐름 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 실제 placement board와 v2 결과 UI 연결 | 완료 |
| `scripts/game/CombatSceneController.gd` | v2 room adapter·시설·결산 metrics 연결 | 완료 |
| `scripts/core/DataRegistry.gd` | v2 onboarding catalog 별도 로드 | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.*` | service·UI·save·실제 GameRoot 통합 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | Phase 10 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 폰트와 색상 체계를 사용하는 코드 기반 UI만 추가했다.
- 게임 연결 및 실제 렌더 확인 결과: `user://v20_phase10_title_entry_1280x720.png`, `user://v20_phase10_retry_result_1280x720.png`에서 텍스트 잘림·패널 겹침 없이 타이틀 진입과 원인 중심 재도전 화면을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20OnboardingRetrySaveTest.tscn` headless | PASS, 35 assertions | 온보딩·session·격리 저장·실제 GameRoot 전투/결산/재도전 |
| 2 | 동일 test `--capture-v20-onboarding` | PASS, 37 assertions | 1280×720 타이틀·결과 실제 렌더 |
| 3 | `V20PlacementUxTest.tscn` | PASS, 29 assertions | 배치 board·Undo·저장 회귀 |
| 4 | `V20InformationArchitectureTest.tscn` | PASS, 33 assertions | 1280·1366·1920 PC HUD 계약 |
| 5 | `V20TacticalCommandsTest.tscn` | PASS, 26 assertions | Phase 7 명령 회귀 |
| 6 | `V20DayOneToFiveEncountersTest.tscn` | PASS, 69 assertions | Phase 8 DAY 1~5 encounter 회귀 |
| 7 | `V20DifficultyEconomyTest.tscn` | PASS, 26 assertions | Phase 9 난이도·경제 회귀 |
| 8 | `DemoSmokeTest.tscn` | PASS | 기존 데모 core loop 회귀 |
| 9 | Godot editor import와 `git diff --check` | PASS | 변경 파일 |
| 10 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `3dcd79747869b2682983ee5166f8d6406cb8b4e0` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: Phase 10 범위의 필수 검수는 모두 실행했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 3dcd79747869b2682983ee5166f8d6406cb8b4e0
- Review range: c5af46adf1eb0c3a757d79b79b47921ec40070fe..3dcd79747869b2682983ee5166f8d6406cb8b4e0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: DAY 1~5 계약과 자동 회귀는 통과했지만 실제 처음 보는 사람의 이해·재미·재도전 의향은 아직 측정하지 않았다.
- 밸런스 관찰 항목: 90초 자동 기록은 내부 계측일 뿐 사람의 설명 없는 성공을 증명하지 않는다.
- 임시 구현 또는 대체 자산: 신규 자산 없음. 기존 1.2 runtime 방과 v2 추상 node 사이에는 명시적 adapter를 사용한다.
- 외부 환경/도구 제약: Phase 11 완료에는 실제 사람 6~10명의 독립 블라인드 플레이 결과가 필요하다.

## 8. 다음 작업 순서

1. `test/v20-p11-sellability`에서 6~10명 블라인드 플레이 프로토콜·기록 양식·Go/No-Go 집계를 준비한다.
2. 실제 참가자에게 사전 설명 없이 DAY 1을 플레이하게 하고 첫 선택 시간, 외부 도움, DAY 1 완료, 재도전 의향, 이해도·재미 응답을 원본 그대로 기록한다.
3. Phase 11 기준이 Go일 때만 최신 `main`에서 Phase 12 DAY 6~30 선택 이식으로 진행한다. Pending 또는 No-Go면 Phase 0~10으로 돌아가 병목만 수정한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase10_title_entry_1280x720.png`, `user://v20_phase10_retry_result_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·수정 후 1280×720 렌더 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
