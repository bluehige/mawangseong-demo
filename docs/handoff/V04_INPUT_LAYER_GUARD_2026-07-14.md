# v0.4 UI 입력 레이어 방어 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-14
- 목표 버전: v0.4 입력 레이어 핫픽스
- 작업 브랜치: `codex/v04-input-layer-guard`
- 기준 브랜치 및 SHA: `origin/main` / `a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767`
- 마지막 구현 커밋 SHA: `af361d5c64b24e94896a6d31845d0e9fa6e4bda0`
- `main` 통합 merge SHA: `592b3a434fde5196d22ee1269e9009d667517264`
- 원격 푸시 여부: 완료, PR 병합 후 구현 원격 브랜치 삭제
- 관련 PR 또는 태그: PR #14 `https://github.com/bluehige/mawangseong-demo/pull/14` merge 완료

## 2. 이번 세션 목표

- 요청 사항: 레이어 순서 때문에 클릭 가능한 대상이 클릭되지 않는 유형을 UI 전반에서 감사하고 재발을 방지한다.
- 완료 조건: 표시 전용 `Control`은 입력을 무시하고, 버튼·스크롤·모달처럼 입력을 소유해야 하는 요소만 입력을 받으며, 실제 마우스 이벤트 회귀 검사와 직접 영향 테스트가 통과한 커밋을 PR merge commit으로 `main`에 통합한다.
- 범위에서 제외한 사항: Web 배포, 전체 게임 회귀, 전체 플레이, 별도 검수 에이전트, 신규 그래픽 생성.

## 3. 완료한 작업

- 공용 UI 계약: `HUDController.panel()`을 표시 전용 기본값 `MOUSE_FILTER_IGNORE`로 바꾸고, 입력 차단 화면과 모달은 호출부에서 `MOUSE_FILTER_STOP`을 명시하도록 했다.
- 입력 주체: 공용 버튼·슬라이더·옵션 버튼·체크 버튼과 독립 화면의 버튼은 `MOUSE_FILTER_STOP`을 명시했다.
- 온보딩: 화면 루트와 실제 확인 카드는 `STOP`을 유지하고, 일반 자식 패널은 `IGNORE`로 바꿨다.
- 독립 화면과 HUD: 전선·심장·합동기·연대기 화면 및 합동기 전투 HUD의 배경, 카드, 게이지와 디자인 캔버스를 표시 전용으로 고정했다.
- 최신 v0.4 UI: 캠페인 모드·지역·전초기지·상층 선택 화면, 상층 HUD, 전초기지 전투, 의회 결정·왕관 후보·투표 예상·지역 진행 패널에도 같은 입력 계약을 적용했다.
- 파싱 안정성: 왕관 후보 패널이 전역 클래스 캐시에 의존하지 않도록 왕관 진화 서비스를 명시적으로 preload했다.
- 전투 표시물: 유닛 이름표, 피해 숫자, 성장 준비 피드백이 GUI 클릭을 가로채지 않도록 했다.
- 회귀 도구: 더 높은 `z_index`로 나중에 추가된 장식 패널 아래 버튼을 실제 마우스 이벤트로 클릭하는 전용 스모크 테스트를 추가했다. 같은 테스트에서 전체 화면 확인 모달이 계속 입력을 차단하는지도 검증한다.
- 스토리·데이터·밸런스·저장·그래픽·오디오: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/ui/HUDController.gd` | 공용 표시 패널과 입력 컨트롤의 명시적 마우스 정책 | 완료 |
| `scripts/game/GameRoot.gd` | 온보딩 자식 패널을 표시 전용으로 변경 | 완료 |
| `scripts/game/CombatSceneController.gd` | 전투 피드백 레이블의 입력 무시 | 완료 |
| `scripts/units/Unit.gd` | 유닛 이름표의 입력 무시 | 완료 |
| `scenes/ui/hud/DuoLinkCombatHUD.gd` | 합동기 HUD 장식과 버튼 입력 분리 | 완료 |
| `scenes/ui/screens/FrontSelectionScreen.gd` | 전선 선택 화면 장식과 버튼 입력 분리 | 완료 |
| `scenes/ui/screens/HeartSelectionScreen.gd` | 심장 선택 화면 장식과 버튼 입력 분리 | 완료 |
| `scenes/ui/screens/DuoLinkLoadoutScreen.gd` | 합동기 편성 화면 장식과 버튼 입력 분리 | 완료 |
| `scenes/ui/screens/ChronicleScreen.gd` | 연대기 화면 장식과 버튼 입력 분리 | 완료 |
| `scenes/ui/screens/CampaignModeSelectionScreen.gd` | v0.4 캠페인 모드 화면 입력 분리 | 완료 |
| `scenes/ui/screens/RegionSelectionScreen.gd` | v0.4 지역 선택 화면 입력 분리 | 완료 |
| `scenes/ui/screens/OutpostManagementScreen.gd` | v0.4 전초기지 관리 화면 입력 분리 | 완료 |
| `scenes/ui/screens/UpperFloorScreen.gd` | v0.4 상층 선택 화면 입력 분리 | 완료 |
| `scenes/ui/hud/MultiFloorHUD.gd` | v0.4 다층 HUD 입력 분리 | 완료 |
| `scenes/outpost/OutpostBattleRoot.gd` | v0.4 전초기지 전투 표시 레이어 입력 무시 | 완료 |
| `scripts/ui/Update4CouncilDecisionOverlay.gd` | v0.4 의회 결정 오버레이 입력 분리 | 완료 |
| `scripts/ui/CrownCandidatePanel.gd` | 왕관 후보 패널 입력 분리 및 서비스 preload | 완료 |
| `scripts/ui/CouncilVoteForecastPanel.gd` | 투표 예상 패널 입력 무시 | 완료 |
| `scripts/ui/RegionSettlementProgressPanel.gd` | 지역 진행 패널 입력 무시 | 완료 |
| `tools/UIInputLayerSmokeTest.gd` | 실제 클릭 통과 및 모달 차단 회귀 검사 | PASS |
| `tools/UIInputLayerSmokeTest.gd.uid` | 전용 테스트 스크립트 UID | 완료 |
| `tools/UIInputLayerSmokeTest.tscn` | 전용 테스트 진입점 | PASS |
| `docs/handoff/V04_INPUT_LAYER_GUARD_2026-07-14.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 생성 모델·원본·`SOURCE.md`·런타임 자산: N/A
- 게임 연결 및 실제 렌더 확인 결과: 그래픽과 오디오 변경 없음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `UIInputLayerSmokeTest.tscn` | PASS, 35 assertions | 장식 패널 실제 클릭 통과, 15개 UI 컴포넌트의 수동·능동 입력 정책, 온보딩 패널, 확인 모달 |
| 2 | `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 튜토리얼 및 실제 적 우클릭 흐름 |
| 3 | `FrontSelectionPhase3Test.tscn` | PASS, 28 assertions | 전선 선택 UI와 1920×1080·1366×768 배치 |
| 4 | `HeartSelectionPhase8Test.tscn` | PASS, 63 assertions | 심장 선택 UI와 HUD, 1920×1080·1366×768 배치 |
| 5 | `DuoLinksPhase10Test.tscn` | PASS, 43 assertions | 합동기 편성과 전투 HUD |
| 6 | `ChroniclePhase26Test.tscn` | PASS, 37 assertions | 연대기 버튼·탭·스크롤과 1920×1080·1366×768 배치 |
| 7 | `CampaignModePhase3Test.tscn` | PASS, 20 assertions | 캠페인 모드 선택 화면 |
| 8 | `RegionRoutePhase5Test.tscn` | PASS, 24 assertions | 지역 선택 화면 |
| 9 | `OutpostPhase7Test.tscn` | PASS, 23 assertions | 전초기지 관리 화면 |
| 10 | `OutpostBattlePhase8Test.tscn` | PASS, 18 assertions | 전초기지 전투 화면 |
| 11 | `MultiFloorHudPhase12Test.tscn` | PASS, 21 assertions | 상층 선택·다층 HUD |
| 12 | `Update4ChronicleAccessibilityPhase35Test.tscn` | PASS, 24 assertions | 연대기 v0.4 접근성 입력 컨트롤 |
| 13 | `git diff --check` / `git diff --cached --check` | PASS | 공백 오류와 의도한 스테이징 확인 |
| 14 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청에 따라 미실행 |

- `DuoLinksPhase10Test`는 성공 종료 후 리소스 사용 경고를 출력했지만 exit code 0과 43개 단언은 모두 PASS였다. 입력 레이어 단언 실패는 없었다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 테스트 통과 뒤 핸드오프 문서만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: af361d5c64b24e94896a6d31845d0e9fa6e4bda0
- Review range: a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767..af361d5c64b24e94896a6d31845d0e9fa6e4bda0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 구현·문서 커밋과 원격 푸시를 완료했고 PR #14를 merge commit `592b3a4`로 `main`에 통합했다.
- 전체 회귀와 전체 플레이는 요청되지 않아 실행하지 않았다. 직접 영향받는 UI와 튜토리얼 회귀만 통과했다.
- Web 빌드와 공개 데모 갱신은 이번 요청에서 보류했다.

## 8. 다음 작업 순서

1. Web 빌드·배포는 별도 요청이 있을 때 최신 `main` 기준으로 진행한다.
2. 후속 v0.4 버그픽스·출시 검증 뒤 `v0.4.0` 태그를 만든다.
3. 다음 버전 작업은 최신 `main`에서 시작한다.

## 9. 작업 트리 상태

- 현재 기록 브랜치: `codex/v04-input-layer-merge-record` (`main`의 `592b3a4` 기준, 문서만 변경)
- 구현 기준 SHA: `a8b29e6ee176b96b0f910beb2d5cbf07dc2c4767`
- 마지막 구현 SHA: `af361d5c64b24e94896a6d31845d0e9fa6e4bda0`
- `main` 통합 SHA: `592b3a434fde5196d22ee1269e9009d667517264`
- 미커밋 파일: 최종 기록 커밋 완료 후 없음
- 의도하지 않은 기존 변경: 없음
- 스테이징·커밋·푸시: 구현과 1차 문서 완료, PR #14 merge commit으로 `main` 통합 완료, 최종 기록 문서 PR 진행 중
- 빌드/캡처 산출물: 없음

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 실제 마우스 이벤트 클릭 통과 검사 완료
- [x] 의도적 모달 차단 유지 확인
- [x] 그래픽 변경 없음 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 최종 구현 커밋 SHA 기록
- [x] 사용자 지시 후 명시적 스테이징·구현 커밋
- [x] 원격 푸시·PR 생성
- [x] PR #14 merge commit 및 로컬 `main` 동기화
- [x] Web 갱신은 이번 요청에서 제외
