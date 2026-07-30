# v1.2.2 시각 개편 23단계 Stage 10 안내 기록·독립 연습 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 시각 개편 10단계 3차로 말풍선·도움말 닫기 기록을 캠페인 저장과 분리한다.
- 일반 설정에 되돌릴 수 있는 `안내 기록 초기화`와 `튜토리얼 다시 하기`를 연결한다.
- 다시 하기는 현재 캠페인·세이브를 건드리지 않는 DAY 1~3 전용 연습 흐름으로 제공한다.
- 연습에서도 현재 `한국어/English`, `전체/핵심만/끄기`, 기존 `TUT_*` 단계 ID를 그대로 사용한다.
- 적용·취소·재진입과 1920/1366/1280 실제 배치를 집중 검증한다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 수행하지 않는다.

## 3. 구현 계약

### 기기별 안내 기록

- `TutorialGuidanceHistory`를 자동 로드하고 `user://settings.cfg`의 `tutorial_guidance_history` 섹션에 닫은 도움말 ID만 저장한다.
- 현재 첫 기록 대상은 비차단 이름 등록 도움말 `HELP_NAME_ENTRY_GUIDE`다.
- 이름 도움말 닫기는 더 이상 캠페인의 legacy `name_entry_tip_dismissed` 값을 바꾸지 않는다.
- 기존 캠페인 payload 필드는 삭제하지 않아 구저장 검증·복원을 유지하되, 새 도움말 표시 여부에는 사용하지 않는다.
- 일반 설정의 기록 초기화는 미리보기 상태에서만 기록을 비운다. `적용`은 기기 설정에 저장하고 `취소`는 설정 진입 snapshot으로 복원한다.
- 기록 초기화는 캠페인 튜토리얼 단계, 대화, DAY, 배치, 전투 상태와 저장 파일을 변경하지 않는다.

### 캠페인 비의존 연습

- `TutorialPracticeSession`은 원본 튜토리얼 데이터를 복제해 별도 index와 완료 상태만 가진다.
- 연습 대상은 현지화된 DAY 1~3 기존 12개 ID `TUT_010_NAME`~`TUT_240_BOSS_HP`다.
- `전체`는 12개를 모두 사용하고, `핵심만`은 자동전투 관찰 3개를 제외한 9개를 사용한다.
- `끄기`는 단계를 억지로 표시하지 않고 현재 안내 수준을 바꾸라는 현지화 빈 상태를 보여 준다.
- 연습 화면은 단계 진행률, legacy ID, DAY/유형, 설명, 실제 연습 포인트, 이전·다음·완료·재시작을 제공한다.
- 연습 종료는 일반 설정으로 돌아가 locale·안내 수준·기록 초기화의 미적용 상태를 유지한다. 설정 취소 시 셋을 함께 원래 snapshot으로 되돌린다.
- 연습 재진입은 항상 첫 단계의 새 세션으로 시작한다.
- `SCREEN_TUTORIAL_PRACTICE`는 캠페인 안전 저장 화면 목록에 추가하지 않았다. live `TutorialManager`와 안내 오버레이도 연습 화면에서 동작하지 않는다.

### UI와 현지화

- 일반 설정 하단에 `튜토리얼 다시 하기`와 `안내 기록` 두 utility 행을 추가했다.
- 연습 화면은 기존 full-canvas 배경과 한 개의 주 학습 카드, 하단 탐색 행동만 사용한다.
- Stage 10 카탈로그를 `v122-stage10-phase3`로 올리고 설정·연습의 한국어/영어 키와 세 기존 단계 제목을 추가했다.
- 최초 1280 English 캡처에서 우상단 저장 비침범 문구의 마지막 글자 잘림을 발견해 영역을 400px에서 580px로 넓힌 뒤 18장을 다시 생성했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/core/TutorialGuidanceHistory.gd` | 기기별 도움말 닫기 기록·snapshot·저장 | 신규 |
| `scripts/systems/tutorial/TutorialPracticeSession.gd` | 캠페인 비의존 DAY 1~3 연습 index·필터·완료 상태 | 신규 |
| `scripts/core/Constants.gd` | 독립 연습 화면 ID | 완료 |
| `project.godot` | 안내 기록 자동 로드 | 완료 |
| `scripts/game/GameRoot.gd` | 설정 기록 transaction, 이름 도움말 분리, 연습 화면·탐색·재진입 | 완료 |
| `data/localization/v122_stage10_ui.json` | phase3 설정·연습 `ko/en` 키 | 완료 |
| `tools/tests/V122TutorialPracticeTest.gd/.tscn` | 적용·취소·재진입·안내 수준·단계 ID·캠페인 비침범 계약 | 신규 |
| `tools/V122TutorialPracticeCapture.gd/.tscn` | 두 언어 × 세 해상도 × 세 상태 실제 GUI 캡처 | 신규 |
| `tools/OnboardingFlowSmokeTest.gd` | 이름 도움말 기기 기록 결정성·복원 | 완료 |
| `tools/tests/V122TutorialGuidanceLevelTest.gd` | 안내 기록 fixture 결정성 | 완료 |
| `tools/tests/V122Stage10LocalizationTest.gd` | 이름 도움말 fixture 결정성 | 완료 |
| `tools/V122Stage10LocalizationCapture.gd` | 기존 이름 캡처 fixture 결정성 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 10단계 완료·11단계 진입 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE23_STAGE10_PRACTICE_2026-07-30.md` | 이번 구현·검증·후속 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 최신 진입점과 다음 작업 갱신 | 완료 |

Godot가 생성한 신규 `.gd.uid`는 각 신규 GDScript 옆에 존재한다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 신규 런타임 그래픽·오디오 자산: 없음
- 기존 설정/온보딩 배경과 공통 UI 프레임만 재사용했다.
- 최종 실제 렌더 근거: `tmp/v122_tutorial_practice/*.png`
- 캡처 구성: `2개 언어 × 3개 해상도 × 3개 상태 = 18장`
  - 닫은 도움말 1개가 있는 일반 설정
  - 안내 기록 초기화 적용 대기 상태
  - DAY 1 곱 선택 연습 단계

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | Godot 프로젝트 editor 로드·스크립트 파싱 | PASS | exit code 0 |
| 2 | `V122TutorialPracticeTest.tscn` | PASS, 22 assertions | 적용·취소·재진입·Full/Core/Off·12개 ID·payload/파일 불변 |
| 3 | `V122Stage10LocalizationTest.tscn` | PASS, 42 assertions | 카탈로그·설정·등록·DAY 1~3 현지화 회귀 |
| 4 | `V122TutorialGuidanceLevelTest.tscn` | PASS, 20 assertions | 전체/핵심만/끄기 회귀 |
| 5 | `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 실제 진행·기존 단계 ID·필수 선택 |
| 6 | `OnboardingFlowSmokeTest.tscn` | PASS | 이름 등록부터 DAY 5 저장 호환 |
| 7 | `V122TutorialPracticeCapture.tscn` | PASS, 54 checks / 18 PNG | `tmp/v122_tutorial_practice/` |
| 8 | 1920/1366/1280 한국어·영어 대표 캡처 육안 확인 | PASS | 설정 행·상태·연습 카드·탐색·영문 보존 문구 잘림 없음 |
| 9 | 전체 작업 트리 `git diff --check` | PASS | exit code 0, 기존 줄바꿈 경고만 출력 |
| 10 | 전체 회귀·전체 플레이·빌드 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 첫 전용 테스트에서 테스트 스크립트의 동적 값 타입 두 곳을 추론하지 못해 명시적 `bool/String/int`로 고친 뒤 재실행했다.
- 첫 payload 비교는 설정 취소로 실제 현재 화면이 바뀐 차이만 검출했다. 같은 설정 화면 시점으로 비교 위치를 보정한 최종 테스트에서 전체 payload가 동일했다.
- Godot root certificate와 종료 시 resource 잔류 메시지는 기존 환경 관찰이다. 대상 테스트와 캡처의 최종 exit code는 0이다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능 변경 여부: 문서만 변경

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- Stage 10 카탈로그 범위 밖 타이틀·일반 캠페인·관리/전투 본문의 전체 영어화는 아직 완료되지 않았다.
- 현재 기기 기록 대상은 실제로 반복 노출 가능한 이름 등록 도움말 하나다. 후속 도움말은 같은 안정 ID 계약으로 추가할 수 있다.
- 연습은 캠페인을 복제 실행하는 전투 sandbox가 아니라 기존 단계 설명·행동 포인트를 순서대로 복습하는 완결된 walkthrough다.
- Phase 3~23의 누적 미커밋 변경과 대량 `.import` 변경을 그대로 보존했다.

## 8. 다음 작업 순서

1. 시각 개편 11단계 1차로 DAY 2 이후 화면을 실제 진행 순서대로 조사하고 공통 UI 파급과 DAY 전용 문제를 분리한다.
2. 우선 DAY 2~3 관리·전투·결산을 1920/1366/1280에서 확인해 깨진 배치·상태 언어·클릭 대상을 목록화한다.
3. 재현되는 문제만 공통 원인부터 최소 수정하고 DAY 전용 규칙·밸런스·기존 저장 ID는 유지한다.
4. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 기준 `codex/v122-ui-simplification...origin/codex/v122-ui-simplification`이며 Phase 3~23 누적 미커밋 변경이 존재한다.
- 기존 사용자 변경과 대량 `.import` 갱신을 되돌리거나 분리하지 않았다.
- 이번 단계의 코드·데이터·테스트·문서는 미커밋 상태다.
- 빌드·커밋·푸시는 진행하지 않았다.
- PNG는 `tmp/v122_tutorial_practice/`에 있으며 커밋 대상이 아니다.

## 10. 종료 체크리스트

- [x] 캠페인 저장과 분리된 기기 도움말 기록
- [x] 기록 초기화 적용·취소·재진입
- [x] 이름 도움말 legacy 캠페인 필드 비변경
- [x] 캠페인 비의존 DAY 1~3 연습 세션
- [x] 현재 locale·Full/Core/Off 반영
- [x] 기존 12개 튜토리얼 단계 ID·순서 보존
- [x] 연습 완료·재시작·설정 복귀
- [x] 캠페인 payload·튜토리얼 진행·DAY·지정 저장 파일 불변
- [x] 2개 언어 × 3개 해상도 × 3개 상태 실제 GUI 캡처·육안 확인
- [x] 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·전체 플레이·빌드 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
