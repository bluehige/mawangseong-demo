# v1.2.2 시각 개편 19단계 DAY 1 곱 선택 반응형 검증 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Phase 18 다음 작업인 1920 full-canvas와 1366/1280 compact에서 곱 카드, 전열·후열 표식과 안내 UI 배치를 실제 렌더로 확인한다.
- 완료 조건: 세 해상도에서 곱 카드와 두 선택 대상이 보이고, 안내 카드와 강조 프레임이 선택 표식을 가리지 않으며, 관련 튜토리얼·결산 테스트가 다시 통과한다.
- 범위에서 제외한 사항: 전열·후열 체감 비교 플레이, 밸런스·경로·spawn timing 조정, 전체 회귀·전체 플레이, Windows/Web 빌드, 커밋·푸시.

## 3. 완료한 작업

- 구현:
  - `DAY1_GOBLIN_FORMATION`의 통합 focus rect 하단에 28px 여백을 추가했다.
  - 기존 focus·클릭·선택 로직은 유지하고 강조 프레임이 `후열 화력` 표식 위를 지나가던 문제만 수정했다.
- 스토리 및 데이터: 변경 없음.
- 밸런스: 변경 없음.
- UI/UX:
  - 1920×1080 full-canvas, 1366×768 compact, 1280×720 compact의 실제 Godot 렌더를 생성했다.
  - 곱 카드, `전열 봉쇄`, `후열 화력`, 행동 안내 카드가 세 해상도에서 서로 가리지 않는 것을 확인했다.
  - 1366×768 창은 Godot의 16:9 aspect-fit으로 콘텐츠 텍스처가 1365×768이 되는 1px 차이를 원본 그대로 기록했다.
- 저장 및 호환성: 튜토리얼 단계 ID, 저장 payload, 전열·후열 zone 저장을 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | DAY 1 두 선택 focus 프레임의 하단 표식 여백 확보 | 완료 |
| `tools/TutorialUxCapture.gd` | 1366/1280 반응형 캡처와 곱 카드·표식·안내 비겹침 검사 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE19_DAY1_GOBLIN_RESPONSIVE_2026-07-30.md` | 이번 세션 결과와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 최신 진입점과 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: 기존 Stage 01 공간·캐릭터·UI 자산 재사용
- 프롬프트/후처리/크롭/알파 처리 요약: N/A
- 게임 연결 및 실제 렌더 확인 결과: 세 해상도 모두 곱 카드·두 노란 대상·안내 카드가 노출되고 `후열 화력` 표식이 focus 프레임 안쪽에서 완전히 읽힌다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | Godot 4.5.2 GUI `TutorialUxCapture.tscn` | PASS | `tmp/phase18_responsive_capture_gui.log` |
| 2 | 1920×1080 full-canvas 육안 확인 | PASS | `tmp/tutorial_ux_verification/02_goblin_formation_task_card.png` |
| 3 | 1366×768 compact 육안 확인 | PASS | `tmp/tutorial_ux_verification/02a_goblin_formation_1366x768.png` |
| 4 | 1280×720 compact 육안 확인 | PASS | `tmp/tutorial_ux_verification/02b_goblin_formation_1280x720.png` |
| 5 | `TutorialFlowSmokeTest.tscn` | PASS | `tmp/phase18_tutorial_flow.log` |
| 6 | `V122CombatResultUIContractTest.tscn` | PASS | `tmp/phase18_result_contract.log` |
| 7 | `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | `tmp/phase18_result_ui.log` |
| 8 | 관련 파일 `git diff --check` | PASS | 명령 출력 |
| 9 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전열·후열 체감 비교는 다음 작업으로 명시된 별도 최소 플레이 단계다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 이 핸드오프와 `CURRENT.md`뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: focus rect 하단 여백은 DAY 1 곱 formation 단계에만 적용된다. 다른 튜토리얼 focus는 변경하지 않았다.
- 밸런스 관찰 항목: 전열과 후열의 실제 교전 위치·결산 문구는 연결돼 있지만 두 선택의 체감 차이는 아직 최소 플레이로 비교하지 않았다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 1366×768 창의 실제 Godot 콘텐츠 텍스처는 aspect-fit 때문에 1365×768이다. UI 배치 모드는 요청 창 너비 1366을 기준으로 compact가 적용됐다.

## 8. 다음 작업 순서

1. 전열·후열을 각각 한 번 선택해 최소 플레이하고 실제 첫 교전 위치와 결과 화면의 `전열`·`후열` 인과 문구를 기록한다.
2. 두 선택의 체감 차이가 약할 때만 기존 경로, 적 도착 시점 또는 배치 anchor를 조정한다. 튜토리얼 전용 능력치 보너스는 추가하지 않는다.
3. 재미 최소 게이트를 통과하면 보류 중인 시각 개편 순서로 돌아간다.
4. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification...origin/codex/v122-ui-simplification`, Phase 3~19 누적 미커밋 변경이 존재한다.
- 미커밋 파일: Phase 18 기존 변경 전체와 이번 세션의 `scripts/game/GameRoot.gd`, `tools/TutorialUxCapture.gd`, 두 핸드오프 문서.
- 의도하지 않은 기존 변경: 대량 `.import` 갱신과 이전 Phase 누적 변경을 그대로 보존했다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/tutorial_ux_verification/`, `tmp/phase18_*.log`; 모두 저장소 미추적·커밋 제외.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 기록
- [x] 검수 대상이 미커밋 작업 트리임을 기록
- [x] 신규 그래픽 생성 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
