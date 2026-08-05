# v1.2.2 시각 개편 22단계 Stage 10 한국어·영어 카탈로그 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `codex/v122-ui-simplification` / `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- Phase 21의 다음 순서에 따라 시각 개편 10단계 2차를 진행한다.
- 설정 전체, 이름 등록, DAY 1~3 튜토리얼의 한국어·영어 직접 문자열을 안정적인 키와 카탈로그로 옮긴다.
- 검증 범위의 두 언어 누락 키가 0인 상태에서 `한국어/English` 선택기를 일반 설정에 노출한다.
- 기존 튜토리얼 단계 ID, 필수 선택, 설정 적용·취소 계약을 유지한다.
- 1920 full-canvas와 1366/1280 compact에서 두 언어의 잘림·겹침을 실제 GUI로 확인한다.
- 전체 회귀·전체 플레이·빌드·커밋·푸시는 수행하지 않는다.

## 3. 조사 결과

### 기존 언어 기반

- `LanguageSettings`에는 운영체제 언어 감지, `ko/en` 정규화, `settings.cfg` 저장, 설정 snapshot·복원과 `TranslationServer` locale 반영이 이미 있었다.
- 설정 열기·적용·취소에도 언어 snapshot과 save 호출이 이미 포함돼 있었다.
- 실제 문자열 카탈로그, 키 조회 API, 일반 설정의 언어 선택기만 비어 있었다.

### 현지화 대상

- 이번 단계의 검증 범위는 설정 `일반/화면/오디오`, 이름 등록 폼·검증·비차단 도움말, DAY 1~3 튜토리얼 단계와 실제 오버레이 문구다.
- `TUT_010_NAME`부터 `TUT_240_BOSS_HP`까지 기존 단계 ID와 순서는 저장 호환 때문에 바꾸지 않았다.
- 범위 밖 타이틀·일반 캠페인·전체 대사·관리/전투 본문은 아직 직접 한국어 문자열이 남아 있다. 이번 완료는 전체 게임 영어 번역 완료를 뜻하지 않는다.

## 4. 구현 계약

### 키와 카탈로그

- `data/localization/v122_stage10_ui.json`을 Stage 10 전용 `ko/en` 카탈로그로 추가했다.
- 키는 `settings.`, `name.`, `tutorial.` 범위로 나눴다.
- `LanguageSettings.text()`는 현재 locale을 우선 조회하고, 누락 시 한국어, 마지막에는 키 자체로 안전하게 대체한다.
- `catalog_keys()`와 `missing_keys()`로 각 검증 범위의 키 선언과 locale 누락을 자동 검사한다.
- 이름·튜토리얼 데이터에는 `text_key`만 추가하고 기존 한국어 `text`는 호환 fallback으로 유지했다.

### 설정의 언어 선택

- 일반 설정에 `한국어/English` 두 항목을 고정 순서로 노출한다.
- 선택 즉시 현재 설정 화면 전체를 다시 구성해 일반·화면·오디오·미리보기 문구를 같은 locale로 표시한다.
- `적용`은 기존 `LanguageSettings.save()`로 저장하고, `취소`는 설정을 열 때의 locale snapshot으로 되돌린다.
- 일반 카테고리 기본값 복원은 운영체제 기본 locale과 튜토리얼 전체 안내를 함께 복원한다.

### 이름 등록

- 제목, 질문, placeholder, 무작위 이름, 확인 버튼, 바티 이름·첫 안내·검증 문구, 도움말과 닫기 버튼을 키화했다.
- 영어 무작위 이름 후보도 별도로 제공한다.
- 바티 문장은 word-smart 줄바꿈을 사용해 Compact에서도 단어 중간 절단 없이 표시한다.
- 기존 `LineEdit`, IME 조합, 12자 검증, 플레이어 이름 저장 흐름은 바꾸지 않았다.

### DAY 1~3 튜토리얼

- 단계 설명, 실제 행동 지시, 행동 제목, 클릭/탭 배지를 모두 키화했다.
- PC의 `Click here!`, 터치의 `Tap here!`를 locale에 맞게 표시한다.
- DAY 3 회복 둥지 안내는 실제 선택 영역을 덮지 않는 안전 배치 후보를 사용한다.
- 클릭 배지는 실제 대상·안내 카드뿐 아니라 우측 상세 서랍도 가리지 않는다.
- 안내 수준 `전체/핵심만/끄기`와 필수 선택 진행 계약은 그대로다.

## 5. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/localization/v122_stage10_ui.json` | 설정·이름 등록·DAY 1~3 `ko/en` 키 카탈로그 | 신규 |
| `scripts/core/LanguageSettings.gd` | 카탈로그 로드·키 조회·범위별 누락 검사 | 완료 |
| `data/onboarding_flow_dialogue_v0.4.json` | 기존 단계·이름 대사에 호환 `text_key` 추가 | 완료 |
| `scripts/game/GameRoot.gd` | 언어 선택기, 설정·등록·튜토리얼 키 연결, 배지·DAY 3 안전 배치 | 완료 |
| `tools/tests/V122Stage10LocalizationTest.gd` | 카탈로그 완전성, 설정 취소, 등록, 단계 ID, DAY 1~3 렌더 계약 | 신규 |
| `tools/tests/V122Stage10LocalizationTest.tscn` | Stage 10 현지화 테스트 scene | 신규 |
| `tools/V122Stage10LocalizationCapture.gd` | 두 언어 × 세 해상도 실제 GUI 캡처·비겹침 검사 | 신규 |
| `tools/V122Stage10LocalizationCapture.tscn` | Stage 10 GUI 캡처 scene | 신규 |
| `tools/OnboardingFlowSmokeTest.gd` | 기존 한국어 단언의 결정적 locale 고정 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 기존 한국어 DAY 1~3 흐름의 결정적 locale 고정 | 완료 |
| `tools/TutorialUxCapture.gd` | 기존 한국어 UX 캡처의 결정적 locale 고정 | 완료 |
| `tools/tests/V122TutorialGuidanceLevelTest.gd` | 안내 수준 테스트 locale 고정 | 완료 |
| `tools/V122TutorialGuidanceCapture.gd` | 안내 수준 캡처 locale 고정 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 10단계 2차 완료와 다음 단위 기록 | 완료 |
| `docs/handoff/V122_VISUAL_OVERHAUL_PHASE22_STAGE10_LOCALIZATION_2026-07-30.md` | 이번 세션 구현·검증·후속 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 최신 진입점과 다음 작업 갱신 | 완료 |

## 6. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 신규 런타임 그래픽·오디오 자산: 없음
- 기존 설정 배경, 이름 등록 배경·바티 초상, 관리 지도·몬스터 카드만 사용했다.
- 최종 실제 렌더 근거: `tmp/v122_stage10_localization/*.png`
- 캡처 구성은 `2개 언어 × 3개 해상도 × 7개 화면 = 42장`이다.
  - 설정 일반·화면·오디오
  - 이름 등록 전체 안내
  - DAY 1 곱 선택
  - DAY 2 고블린 관찰
  - DAY 3 회복 둥지 선택

## 7. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | Godot 스크립트 로드·scene 실행 | PASS | 대상 테스트·캡처 exit code 0 |
| 2 | `V122Stage10LocalizationTest.tscn` | PASS, 42 assertions | 카탈로그·설정·등록·튜토리얼 전용 계약 |
| 3 | `V122TutorialGuidanceLevelTest.tscn` | PASS, 20 assertions | 전체/핵심만/끄기 회귀 |
| 4 | `V122ManagementInteractionTest.tscn` | PASS, 18 assertions | 설정 기본 진입·버튼 등급·선택 상태 |
| 5 | `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 실제 진행·기존 단계 ID·필수 선택 |
| 6 | `V122Stage10LocalizationCapture.tscn` | PASS, 126 checks / 42 PNG | `tmp/v122_stage10_localization/` |
| 7 | 1920/1366/1280 한국어·영어 육안 확인 | PASS | 잘림·오버레이 오염·대상/서랍 겹침 없음 |
| 8 | 전체 작업 트리 `git diff --check` | PASS | 명령 exit code 0 |
| 9 | 전체 회귀·전체 플레이·빌드 | NOT_REQUESTED | 저장소 정책에 따라 실행하지 않음 |

- 최초 headless 실행은 sandbox가 Godot `user://logs` AppData 쓰기를 막아 엔진이 충돌했다. 같은 테스트를 쓰기 권한이 있는 환경에서 재실행해 PASS를 확인했다.
- 개발 중 도구 스크립트의 추론 불가 지역 변수 두 곳은 명시적 `Rect2/bool` 타입으로 수정한 뒤 재실행했다.
- Godot root certificate와 종료 시 resource 잔류 메시지는 기존 환경 관찰이며 최종 대상 scene의 exit code는 0이었다.
- 최초 영어 캡처에서 이전 DAY 3 오버레이가 설정 화면에 남은 것은 캡처 fixture 상태 오염이었다. 화면별 tutorial 상태를 초기화하도록 고친 뒤 최종 캡처를 다시 만들었다.
- 최종 육안 검수에서 발견한 한국어 고정 클릭 배지, 영어 바티 줄바꿈, DAY 3 카드·상세 서랍 겹침을 수정하고 42장을 모두 다시 생성했다.
- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음
- PASS 이후 기능 변경 여부: 문서만 변경

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 8. 다음 작업 순서

1. 시각 개편 10단계 3차로 안내 기록 초기화를 캠페인 저장과 분리한다.
2. 튜토리얼 다시 하기는 현재 캠페인·세이브를 건드리지 않는 별도 연습 흐름으로 연결한다.
3. 연습 흐름에서도 `전체/핵심만/끄기`, 현재 locale, 기존 단계 ID를 그대로 사용한다.
4. 기록 초기화·연습 흐름의 설정·취소·재진입과 1920/1366/1280 배치를 집중 검증한다.
5. 10단계 완료 뒤 11단계 DAY 2 이후 파급 수정으로 넘어간다.
6. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 기준 `codex/v122-ui-simplification...origin/codex/v122-ui-simplification`이며 Phase 3~22 누적 미커밋 변경이 존재한다.
- 대량 `.import` 갱신과 이전 Phase 누적 변경을 그대로 보존했다.
- 이번 단계의 코드·테스트·문서는 미커밋 상태다.
- 빌드·커밋·푸시는 진행하지 않았다.
- PNG는 `tmp/v122_stage10_localization/`에 있으며 커밋 대상이 아니다.

## 10. 종료 체크리스트

- [x] 기존 `LanguageSettings` 저장·취소 기반 확인
- [x] 설정·이름 등록·DAY 1~3 문자열 키 범위 고정
- [x] 한국어·영어 카탈로그와 누락 키 검사
- [x] 일반 설정의 `한국어/English` 선택기와 즉시 미리보기
- [x] 설정 적용·취소·기본값 계약 유지
- [x] 기존 튜토리얼 단계 ID와 필수 선택 보존
- [x] 클릭/탭 배지 현지화
- [x] DAY 3 안내 카드·실제 대상·상세 서랍 비겹침
- [x] 두 언어 × 세 해상도 42장 실제 GUI 캡처·육안 확인
- [x] 관련 설정·등록·DAY 1~3 테스트 통과
- [x] 요청받지 않은 전체 회귀·전체 플레이·빌드 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
