# v1.2.2 시각 개편 26단계 Stage 12 누적 UI 통합 검수 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 마지막 커밋 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 관련 PR 또는 태그: 없음
- 작업 단위: 시각 개편 12단계 1차

## 2. 이번 세션 목표

- 요청 사항: 최신 핸드오프의 다음 작업인 누적 UI 통합 검수와 사용자 최종검수 진입 준비
- 완료 조건:
  - 설정→관리→침입→원정→전투→결산→튜토리얼/저장 흐름을 하나의 실제 화면 경로로 검증
  - 1920 Standard와 1366/1280 Compact 대표 화면 확인
  - 공통 회귀만 최소 수정
  - 사용자 최종검수 체크리스트와 다음 진입점 동기화
- 범위에서 제외:
  - 전체 회귀와 전체 플레이
  - Windows/Web 빌드·export
  - 커밋·푸시·태그·Release

## 3. 완료한 작업

### 3.1 통합 검수에서 발견한 공통 공백

확정 사양은 타이틀뿐 아니라 관리·전투 중에도 `ESC → 일시정지 메뉴 → 환경 설정`으로 진입하는 것이다. 실제 런타임에서는 다음 상태였다.

- 설정 버튼은 타이틀 화면에만 있었다.
- 관리 화면에서 취소할 작업이 없는 상태로 ESC를 눌러도 아무 변화가 없었다.
- 전투의 일시정지 버튼은 `combat_paused`만 토글하고 설정 진입점을 제공하지 않았다.

화면별 규칙이나 전투 밸런스가 아니라 공통 화면 전환 계약의 누락으로 분류했다.

### 3.2 관리·전투 일시정지 메뉴

- 관리 화면에서 활성 배치 작업·드로어가 없을 때 ESC로 `마왕성 메뉴`를 연다.
- 전투에서 일시정지 버튼 또는 안전한 ESC 경로로 `전투 일시정지` 메뉴를 연다.
- 메뉴는 현재 지도·전장을 어둡게 남겨 맥락을 보존하고 중앙 modal 하나만 사용한다.
- `계속`만 primary, `환경 설정`은 utility로 고정했다.
- 관리 화면은 배치·DAY·플레이어·방어 몬스터 위치를 유지한다.
- 전투 화면은 유닛 physics를 멈추고 기존 전투 음악 stream과 일시정지 상태를 유지한다.

### 3.3 설정 왕복 안전성

- 일시정지 메뉴에서 설정을 열면 진입한 관리 또는 전투 화면을 return screen으로 기록한다.
- 적용 또는 취소 뒤 설정을 열었던 일시정지 메뉴로 돌아온다.
- 전투 설정 진입은 Update 4 의회 전투 완료로 처리하지 않는다.
- 설정을 여는 동안 전투 음악 fade-out과 Update 3 심장 loop 종료를 발생시키지 않는다.
- 설정 취소는 언어·레이아웃·안내 기록 snapshot을 기존대로 복원한다.
- 튜토리얼 연습을 거쳐도 현재 캠페인 상태와 저장 payload 의미는 바뀌지 않는다.

### 3.4 Stage 12 통합 감사

`V122Stage12IntegrationAudit`를 추가하고 각 해상도에서 다음 9개 상태를 실제 순서로 렌더했다.

1. DAY 5 관리
2. 관리 일시정지 메뉴
3. 관리에서 연 환경 설정
4. 별도 튜토리얼 연습
5. 침입 정보
6. 원정
7. 전투 일시정지 메뉴
8. 전투에서 연 환경 설정
9. 승리 결산

총 27장을 생성하고 다음을 검사한다.

- Standard/Compact 판정
- 지도·로스터·주 행동 분리
- 일시정지 modal과 버튼 계층
- 설정 return screen과 적용/취소 영역
- 한국어→English 미리보기→취소 복원
- 기존 `TUT_030_SELECT_SLIME` ID 유지
- 침입 정보·원정·전투·결산 연결
- 전투 유닛 physics 정지와 음악 stream 유지
- DAY·플레이어·layout fingerprint·방어 몬스터 위치 불변
- 현재 checkpoint와 일치하는 유효 저장 payload

첫 감사에서는 원정 화면이 코볼트 척후대장을 raid-only 지원으로 정상 해금하는 상태와 결산 화면에서 관리 checkpoint를 강제로 검사한 fixture가 실패했다. 제품 회귀가 아님을 실제 차이로 확인하고, 방어 배치 불변과 현재 결산 checkpoint를 검사하도록 감사 기준만 교정했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 관리·전투 일시정지 메뉴, 설정 왕복·전투 상태 보존 | 완료 |
| `data/localization/v122_stage10_ui.json` | 일시정지 메뉴 한국어·영어 문구 | 완료 |
| `tools/V122Stage12IntegrationAudit.gd` | 누적 화면 전환·입력·저장 통합 감사 | 완료 |
| `tools/V122Stage12IntegrationAudit.gd.uid` | Godot 스크립트 UID | 완료 |
| `tools/V122Stage12IntegrationAudit.tscn` | 통합 감사 실행 scene | 완료 |
| `tools/DirectiveCombatUIVisualCheck.gd` | 전투 HUD 정지 fixture를 새 사용자 메뉴와 분리 | 완료 |
| `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md` | 자동 선행 증빙과 1280·일시정지 설정 수동 항목 추가 | 완료 |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | Stage 12 1차 완료와 사용자 검수 진입 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 현재 상태와 다음 작업 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 신규 그래픽·오디오 자산: 없음
- 게임 연결 및 실제 렌더 확인 결과:
  - 기존 지도·전장을 pause modal 뒤의 시각 맥락으로 유지
  - 기존 combat/management 음악 자산은 교체하지 않고 stream 보존만 수정

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | Godot editor 로드·스크립트 파싱 | PASS | exit code 0 |
| 2 | `V122Stage12IntegrationAudit.tscn` | PASS, 243 assertions / 27 PNG | `tmp/v122_stage12_integration_audit/` |
| 3 | 1920/1280 대표 캡처 육안 확인 | PASS | 관리·전투 pause, 설정, 연습, 결산 |
| 4 | `V122Stage10LocalizationTest.tscn` | PASS, 42 assertions | 한국어·영어 설정 scope 누락 0 |
| 5 | `V122TutorialGuidanceLevelTest.tscn` | PASS | 전체/핵심/끄기 |
| 6 | `V122TutorialPracticeTest.tscn` | PASS, 22 assertions | 캠페인 비의존 연습 |
| 7 | `V122ManagementInteractionTest.tscn` | PASS | 관리·설정 행동 계층 |
| 8 | `V122PrecombatFlowTest.tscn` | PASS, 40 assertions | 침입 정보·배치 전환 |
| 9 | `V122CombatUISimplificationTest.tscn` | PASS | 전투 HUD·명령 |
| 10 | `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | 결산·행동 |
| 11 | `V122SaveProgressionTest.tscn` | PASS | DAY·retry·legacy·Update 4 저장 |
| 12 | `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 튜토리얼 흐름 |
| 13 | `UIInputLayerSmokeTest.tscn` | PASS, 35 assertions | 표시/입력 레이어 |
| 14 | `DirectiveCombatUIVisualCheck.tscn` | PASS | 최대 글자 1920/1366/1280 전투 HUD |
| 15 | `git diff --check` | PASS | 줄바꿈·공백 오류 없음 |
| 16 | 전체 회귀·전체 플레이 | NOT_REQUESTED | 수행하지 않음 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `UNCOMMITTED_WORKTREE`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 사용자의 DAY 1~30·1.2.1 저장·Update 2~4·실기 화면/입력 최종검수는 아직 시작하지 않았다.
- 사용자 최종검수에 기록할 고정 `source_sha`가 필요하지만 이번 요청은 커밋을 포함하지 않아 작업 트리는 미커밋 상태다.
- Windows 물리 한국어 IME, 실제 Android/iOS, 저사양 장시간 성능, 실제 오디오 반복 피로는 자동검증으로 대체하지 않는다.
- 일반 캠페인 전체 문구의 영어화는 Stage 10 카탈로그 범위 밖으로 남아 있다.
- 기존 Phase 3~26 누적 변경과 대량 `.import` 변경을 보존했다.

## 8. 다음 작업 순서

1. 사용자가 원하면 현재 범위를 커밋해 최종검수용 `source_sha`를 고정한다.
2. 사용자가 `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`에 따라 DAY 1~30·1.2.1 저장·Update 2~4·1920/1366/1280·Windows 입력을 직접 검수한다.
3. FAIL이 전달되면 해당 재현 범위만 최소 수정하고 관련 테스트와 수동 항목을 다시 확인한다.
4. 사용자 최종검수 PASS 뒤에만 Full 검증과 Windows/Web 후보 export, 실행·SHA-256, 태그·Release·배포를 진행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `49388876d50009ed87655fffb2bf6974098b2f6c`
- Phase 3~26 누적 미커밋 변경을 보존한다.
- 기존 사용자 변경과 대량 `.import` 갱신을 되돌리거나 분리하지 않았다.
- 캡처 산출물: `tmp/v122_stage12_integration_audit/`, 커밋 대상 아님
- 빌드·커밋·푸시는 진행하지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 1920/1366/1280 대상 통합 렌더 통과
- [x] 관리·전투 설정 왕복과 상태 보존 확인
- [x] 사용자 최종검수 체크리스트 갱신
- [x] 전체 회귀·전체 플레이 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 검수 대상 source SHA 고정
- [ ] 사용자 최종검수
- [ ] Full 검증·빌드·커밋·푸시·태그·Release
