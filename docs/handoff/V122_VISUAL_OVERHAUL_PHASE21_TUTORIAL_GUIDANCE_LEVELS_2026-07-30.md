# v1.2.2 시각 개편 21단계 튜토리얼 안내 수준·비차단 등록 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- Phase 20의 다음 순서에 따라 시각 개편 10단계 `튜토리얼·등록·문구`의 현재 연결 상태를 조사한다.
- 튜토리얼 안내 수준 `전체/핵심만/끄기`, 이름 등록, 한국어/영어 문구 가운데 가장 작은 공통 기능 공백 하나를 구현한다.
- 1920 full-canvas와 1366/1280 compact에서 안내가 실제 클릭 대상을 가리지 않는지 확인한다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 수행하지 않는다.

## 3. 조사 결과

### 튜토리얼 안내 수준

- 작업 전에는 `전체/핵심만/끄기` 설정값, 설정 UI, 런타임 분기 모두 없었다.
- 튜토리얼 단계 진행과 필수 선택 게이트는 `TutorialManager`와 캠페인 저장에 이미 연결돼 있었다.
- 따라서 캠페인 단계 ID와 필수 선택을 바꾸지 않고 시각 안내의 양만 기기 설정으로 분리할 수 있었다.

### 이름 등록

- `LineEdit`, 한글 IME 조합 보존, 길이 검증, 무작위 이름, 확인, 플레이어 이름 저장과 대사·결과 연결은 이미 구현돼 있었다.
- 다만 최초 안내 카드가 입력창과 버튼을 숨겨, 10단계의 비차단 안내 계약과 맞지 않았다.

### 한국어/영어

- `LanguageSettings`에는 운영체제 언어 감지, `ko/en` 정규화, `settings.cfg` 저장 기반이 있다.
- 실제 설정 페이지에는 언어 선택기가 없고 현재 노출 화면 대부분은 한국어 직접 문자열이다.
- 반쪽 번역 상태로 언어 선택기만 노출하지 않고, 후속 10단계에서 표시 문자열 키와 카탈로그를 먼저 완성하기로 유지했다.

### 후속 기능

- 안내 기록 초기화와 캠페인 비의존 튜토리얼 연습 흐름은 아직 없다.
- 이번 단계는 가장 작은 공통 공백인 안내 수준·등록 안내·실제 대상 강조 연결까지만 구현했다.

## 4. 구현 계약

### 기기 설정

- `UISettings`의 `interface/tutorial_guidance_level`로 저장한다.
- 값은 `full`, `core`, `off` 세 개다.
- 설정이 없거나 잘못된 값이면 최초 기본값 `full`로 복구한다.
- 환경설정 snapshot, 적용, 취소, 카테고리 기본값 복원에 포함한다.
- 설정 페이지에는 실제 연결된 `일반` 카테고리만 추가하고 미구현 언어·연습·기록 초기화 항목은 노출하지 않았다.

### 안내 수준별 동작

| 수준 | 이름 등록 도움말 | 필수 조작·선택 강조 | 자동전투 관찰 설명 | 스토리·필수 선택 진행 |
|---|---|---|---|---|
| 전체 | 표시 | 표시 | 표시 | 유지 |
| 핵심만 | 숨김, 바로 입력 | 표시 | 숨김 | 유지 |
| 끄기 | 숨김, 바로 입력 | 숨김 | 숨김 | 유지 |

- `끄기`에서도 필수 곱 선택과 전열·후열 배치 단계는 건너뛰지 않으며 올바른 선택으로 정상 진행된다.
- 잘못된 필수 선택은 기존 규칙대로 막지만 튜토리얼 오버레이를 다시 열지 않는다.
- 모바일의 튜토리얼 전용 자동 선택·보조 탭도 안내가 보이는 단계에서만 동작하도록 맞췄다.

### 비차단 이름 등록

- `전체` 도움말은 입력창과 두 버튼 오른쪽의 별도 카드로 옮겼다.
- 입력창, 무작위 이름, 시작 버튼은 처음부터 보이고 사용할 수 있다.
- 도움말 닫기는 설명만 제거하며 같은 `LineEdit` 인스턴스를 유지하므로 IME 조합 계약을 보존한다.
- `핵심만/끄기`는 별도 도움말 없이 곧바로 입력한다.

### 살아 있는 클릭 대상

- 실제 1280 캡처에서 문구는 곱을 지시하지만 강조 링이 첫 푸딩 카드에 남는 문제를 발견했다.
- 원인은 `HBoxContainer`가 배치되기 전의 좌표를 `tutorial_targets`에 저장한 것이었다.
- 컨트롤 기반 대상은 고정 `Rect2` 대신 살아 있는 `Control`과 grow 값을 보관하고, 오버레이를 한 프레임 뒤 다시 구성해 현재 `global_rect`를 사용한다.
- 따라서 1920/1366/1280에서 강조 링이 실제 `MonsterCard_goblin`을 감싼다.

## 5. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/core/UISettings.gd` | 안내 수준 상수·기본값·snapshot·저장·복원 | 완료 |
| `scripts/game/GameRoot.gd` | 일반 설정 페이지, 이름 등록 비차단 도움말, 수준별 오버레이, 살아 있는 대상 좌표 | 완료 |
| `tools/tests/V122TutorialGuidanceLevelTest.gd` | 세 수준·설정 취소·등록·필수 진행·실제 곱 카드 대상 계약 | 완료 |
| `tools/tests/V122TutorialGuidanceLevelTest.tscn` | 안내 수준 테스트 scene | 완료 |
| `tools/V122TutorialGuidanceCapture.gd` | 1920/1366/1280 설정·등록·핵심 안내와 끄기 캡처 | 완료 |
| `tools/V122TutorialGuidanceCapture.tscn` | GUI 캡처 scene | 완료 |
| `tools/OnboardingFlowSmokeTest.gd` | 비차단 이름 도움말·IME 계약과 결정적 전체 안내 설정 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 결정적 전체 안내 설정과 live target 검증 경로 | 완료 |
| `tools/TutorialUxCapture.gd` | 기존 캡처의 전체 안내 수준 고정 | 완료 |
| `tools/UIRegressionVisualReview.gd` | live target의 현재 rect 기준 검사 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 10단계 1차 완료와 후속 작업 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE21_TUTORIAL_GUIDANCE_LEVELS_2026-07-30.md` | 이번 세션 구현·검증·후속 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 최신 진입점과 다음 작업 갱신 | 완료 |

## 6. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 신규 런타임 그래픽·오디오 자산: 없음
- 기존 설정 배경, 이름 등록 배경·바티 초상, 관리 지도·몬스터 카드만 사용했다.
- 최종 실제 렌더 근거:
  - `tmp/v122_tutorial_guidance/settings_general_1920x1080.png`
  - `tmp/v122_tutorial_guidance/settings_general_1366x768.png`
  - `tmp/v122_tutorial_guidance/settings_general_1280x720.png`
  - `tmp/v122_tutorial_guidance/name_full_1920x1080.png`
  - `tmp/v122_tutorial_guidance/name_full_1366x768.png`
  - `tmp/v122_tutorial_guidance/name_full_1280x720.png`
  - `tmp/v122_tutorial_guidance/core_required_choice_1920x1080.png`
  - `tmp/v122_tutorial_guidance/core_required_choice_1366x768.png`
  - `tmp/v122_tutorial_guidance/core_required_choice_1280x720.png`
  - `tmp/v122_tutorial_guidance/off_required_choice_1280x720.png`

## 7. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V122TutorialGuidanceLevelTest.tscn` | PASS, 20 assertions | `tmp/phase21_guidance_level_recheck.log` |
| 2 | `V122ManagementInteractionTest.tscn` | PASS | `tmp/phase21_management_settings_recheck.log` |
| 3 | `OnboardingFlowSmokeTest.tscn` | PASS | `tmp/phase21_onboarding_escalated.log` |
| 4 | `TutorialFlowSmokeTest.tscn` | PASS | `tmp/phase21_tutorial_flow_recheck.log` |
| 5 | `V122TutorialGuidanceCapture.tscn` GUI 실제 렌더 | PASS | `tmp/phase21_visual_layout_debug.log`, `tmp/v122_tutorial_guidance/*.png` |
| 6 | 1920/1366/1280 설정·등록·핵심 안내 육안 확인 | PASS | 위 PNG |
| 7 | 관련 파일 `git diff --check` | PASS | 명령 출력 |
| 8 | 전체 회귀·전체 플레이·빌드 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 최초 workspace-only `OnboardingFlowSmokeTest` 실행은 Godot `user://`가 있는 AppData에 쓸 수 없어 DAY 05 저장 단언이 실패했고 스크립트 오류 뒤 종료하지 않았다. 이번 세션이 만든 정확한 테스트 프로세스만 종료한 뒤 쓰기 권한을 허용한 동일 테스트를 다시 실행해 PASS를 확인했다.
- Godot root certificate와 종료 시 resource 잔류 메시지는 기존 환경 관찰이며 최종 대상 scene의 exit code는 0이었다.
- 최종 GUI 캡처에서 일반 설정 문구 잘림, 이름 도움말 겹침, 곱 카드 오지정이 없음을 확인했다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능 변경 여부: 설정 상단 설명 문구를 실제 일반 카테고리에 맞춘 뒤 GUI 캡처를 다시 실행해 PASS를 확인했다. 이후 변경은 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 8. 다음 작업 순서

1. 시각 개편 10단계 2차로 이어서 한국어/영어 노출 문구의 실제 키·카탈로그 연결 범위를 정한다.
2. 우선 설정·이름 등록·DAY 1~3 튜토리얼처럼 이번 단계에서 직접 검증한 화면만 좁게 번역하고, 누락 키가 없는 상태에서 언어 선택기를 노출한다.
3. 안내 기록 초기화는 캠페인 저장과 분리하고, 튜토리얼 다시 하기는 본 저장을 건드리지 않는 별도 연습 흐름으로 구현한다.
4. 10단계의 문구·기록·연습 연결이 끝난 뒤 11단계 DAY 2 이후 파급 수정으로 넘어간다.
5. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 기준 `codex/v122-ui-simplification...origin/codex/v122-ui-simplification`이며 Phase 3~21 누적 미커밋 변경이 존재한다.
- 대량 `.import` 갱신과 이전 Phase 누적 변경을 그대로 보존했다.
- 이번 단계의 코드·테스트·문서는 미커밋 상태다.
- 빌드·커밋·푸시는 진행하지 않았다.
- PNG와 테스트 로그는 `tmp/`에 있으며 커밋 대상이 아니다.

## 10. 종료 체크리스트

- [x] 튜토리얼·이름 등록·한국어/영어 현재 연결 상태 조사
- [x] 안내 수준 전체/핵심만/끄기 저장·설정 UI 연결
- [x] 스토리·필수 선택 진행 유지
- [x] 이름 등록 도움말 비차단화와 IME 인스턴스 보존
- [x] 실제 곱 카드 live target 좌표 수정
- [x] 1920/1366/1280 실제 GUI 캡처·육안 확인
- [x] 관련 설정·등록·DAY 1~3 튜토리얼 테스트 통과
- [x] 요청받지 않은 전체 회귀·전체 플레이·빌드 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
