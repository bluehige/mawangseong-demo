# v1.2.2 시각 개편 25단계 Stage 11 DAY 4~5 파급 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니오
- 작업 단위: 시각 개편 11단계 2차

## 2. 일정 브리핑과 이번 작업 범위

남은 순서는 다음과 같이 고정한다.

1. Stage 11 2차에서 DAY 4~5 파급을 실제 진행 순서대로 확인한다.
2. Stage 12에서 누적 UI 통합 검수와 사용자 최종검수 진입 준비를 한다.
3. 사용자가 DAY 1~30, v1.2.1 저장 호환, Update 2~4, 화면·입력을 직접 확인한다.
4. 사용자 최종검수 PASS 뒤에만 Full 검증과 Windows/Web 후보 export, 실행·hash·태그·Release·배포를 진행한다.

이번 작업은 DAY 4 원정 미리보기부터 DAY 5 패배 결산까지 다음 13개 실제 상태를 대상으로 했다.

1. DAY 4 원정 미리보기
2. DAY 4 원정
3. DAY 4 관리
4. DAY 4 관리 원정 서랍
5. DAY 4 침입 정보
6. DAY 4 전투
7. DAY 4 승리 결산
8. DAY 5 관리
9. DAY 5 관리 원정 서랍
10. DAY 5 원정
11. DAY 5 침입 정보
12. DAY 5 전투
13. DAY 5 패배 결산

각 상태를 `1920×1080 Standard`, `1366×768 Compact`, `1280×720 Compact`에서 확인해 총 39장을 캡처했다.

## 3. 시각 기준

- 성 지도와 전장을 계속 주 작업면으로 유지한다.
- DAY 4 원정 미리보기와 침입 정보는 다음 행동을 설명하는 보조 계층으로 둔다.
- 관리 화면은 지도·상세·로스터 열을 유지하고 한 번에 하나의 주 행동만 강조한다.
- DAY 5의 원정은 선택 행동이므로 관리 주 행동 rail이 아니라 `전술·상세` 문맥 서랍에 둔다.
- 전투는 상단 위협·침입 rail과 하단 지침·명령·상태 rail이 전장을 침범하거나 서로 겹치지 않게 한다.
- 결산은 결과, 핵심 수치, 성장, 다음 행동의 인과 순서를 유지한다.

## 4. 공통 UI 파급과 DAY 전용 분류

| 분류 | 재현 상태 | 원인 | 처리 |
|---|---|---|---|
| 공통 원정 미리보기 | DAY 4, 세 해상도 | 오른쪽 설명이 일반 `Label`의 제한 폭 안에서 한국어 장문을 안정적으로 줄바꿈하지 못해 우측 글자가 잘림 | 고정 영역의 `RichTextLabel`로 바꾸고 의미 단위 줄바꿈과 word-smart wrap을 함께 적용 |
| 관리 행동 구조 | DAY 4~5, 세 해상도 | 첫 감사가 원정 버튼을 하단 주 행동 rail에서 찾도록 잘못 가정 | 실제 view model 계약인 `raid/context`를 확인하고 `전술·상세` 서랍의 `ManagementContextAction_raid`를 검사하도록 감사 수정. 제품 구조 변경 없음 |
| DAY 4 전용 | 원정·관리·침입·전투·승리 결산 | 추가 파손 없음 | DAY 4 규칙·밸런스·상태를 유지 |
| DAY 5 전용 | 관리·원정·침입·전투·패배 결산 | 추가 파손 없음 | DAY 5 규칙·밸런스·상태를 유지 |

## 5. 구현 내용

### DAY 4 원정 미리보기 설명

- `GameRoot._build_onboarding_raid_preview_ui()`의 오른쪽 설명을 이름 있는 `RichTextLabel` `RaidPreviewBriefingText`로 교체했다.
- 설명 영역은 `452×390`, 본문 22px, 상단 정렬, word-smart wrap을 사용한다.
- 한국어 문장은 의미 단위의 안전한 줄바꿈을 포함해 1920/1366/1280에서 마지막 글자까지 표시한다.
- 설명의 의미, 원정 규칙, 보상, 튜토리얼 단계는 바꾸지 않았다.

### DAY 4~5 전용 감사

- `V122Stage11Day04_05CascadeAudit`를 추가했다.
- 실제 화면 상태, 반응형 mode, 지도·상세·로스터 열, 원정 문맥 행동, 침입 모델과 일정, 전투 rail 분리, 결산 수치·성장·행동, 캡처 크기와 세로 적합성을 검사한다.
- 감사 출력은 `tmp/v122_stage11_day04_05_cascade_audit/`에 생성되며 커밋 대상이 아니다.

## 6. 변경 파일

| 파일 | 역할 |
|---|---|
| `scripts/game/GameRoot.gd` | DAY 4 원정 미리보기 한국어 설명의 줄바꿈·영역 보정 |
| `tools/V122Stage11Day04_05CascadeAudit.gd` | DAY 4~5 실제 상태 3해상도 감사 |
| `tools/V122Stage11Day04_05CascadeAudit.gd.uid` | Godot 스크립트 UID |
| `tools/V122Stage11Day04_05CascadeAudit.tscn` | 전용 감사 실행 scene |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 11단계 완료와 12단계 진입 기록 |
| `docs/handoff/CURRENT.md` | 현재 상태와 다음 작업 갱신 |

## 7. 테스트와 검증

| 검증 | 결과 | 범위 |
|---|---|---|
| Godot editor 로드·스크립트 파싱 | PASS | 최종 변경 로드 |
| `V122Stage11Day04_05CascadeAudit.tscn` | PASS, 417 assertions / 39 PNG | DAY 4~5 13개 상태, 1920/1366/1280 |
| 대표 1920/1280 캡처 육안 확인 | PASS | 원정 미리보기, 원정, 관리·원정 서랍, 침입, 전투, 승리·패배 결산 |
| `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3에서 DAY 4 원정 미리보기까지 |
| `V122PrecombatFlowTest.tscn` | PASS, 40 assertions | 침입 전 흐름 |
| `V122ManagementUIContractTest.tscn` | PASS | 관리 view model·UI 계약 |
| `V122ManagementInteractionTest.tscn` | PASS | 관리 문맥 서랍과 행동 |
| `V122CombatUISimplificationTest.tscn` | PASS, 85 assertions | 전투 HUD·명령 rail |
| `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | 승패 결산·행동 |
| `V122Day01To05ParityTest.tscn` | PASS | DAY 1~5 상태 일치 |
| `V122DualFrontDay01To05WaveTest.tscn` | PASS | DAY 1~5 이중 전선 웨이브 |
| `git diff --check` | PASS | 줄바꿈·공백 오류 없음 |

- 창 렌더 환경의 결과 UI 테스트에서는 실제 frame 진행 때문에 정확히 3초인 순간을 확인하는 assertion이 먼저 경과할 수 있었다. 동일 테스트의 의도된 headless 논리 검증은 37 assertions 모두 PASS했고 제품 코드는 바꾸지 않았다.
- 제한된 sandbox에서 Godot가 `user://logs`를 열지 못해 종료된 실행은 권한이 있는 동일 환경으로 다시 실행해 PASS했다. 제품 회귀로 분류하지 않는다.
- Godot 종료 시 기존 ObjectDB/resource 정리 경고가 일부 남지만 대상 테스트의 exit code는 모두 0이다.
- 전체 회귀, 전체 플레이, Windows/Web 빌드는 수행하지 않았다.

### 정확 CI 및 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `UNCOMMITTED_WORKTREE`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 8. 미해결 항목과 제약

- Stage 11의 DAY 2~5 파급 조사는 완료했다. 다음은 Stage 12 누적 통합 검수다.
- Stage 10 카탈로그 밖 일반 캠페인 전체 문구의 영어화는 이번 범위 밖이다.
- 기존 튜토리얼 단계 ID, 저장 호환, DAY 규칙, 전투 밸런스는 유지했다.
- Phase 3~25 누적 미커밋 변경과 대량 `.import` 변경을 그대로 보존했다.
- 사용자 최종검수 전에는 Full 검증이나 출시 승인으로 판정하지 않는다.

## 9. 다음 작업 순서

1. Stage 12 1차로 설정·관리·침입·원정·전투·결산·튜토리얼·저장 흐름의 누적 대상 통합 검수를 구성한다.
2. 1920 Standard와 1366/1280 Compact에서 대표 상태를 다시 렌더해 화면 간 전환과 입력 계약을 확인한다.
3. 재현되는 공통 회귀만 최소 수정하고 콘텐츠 규칙·밸런스·저장 ID는 유지한다.
4. `docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md`를 최신 상태와 맞추고 사용자 최종검수 진입점을 정리한다.
5. 사용자 최종검수 PASS 전에는 Full 검증·빌드·export·커밋·푸시·태그·Release를 진행하지 않는다.

## 10. 작업 트리 상태

- `codex/v122-ui-simplification`의 Phase 3~25 누적 미커밋 변경을 보존한다.
- 기존 사용자 변경과 대량 `.import` 갱신을 되돌리거나 분리하지 않았다.
- 빌드·커밋·푸시는 진행하지 않았다.

## 11. 종료 체크리스트

- [x] 남은 일정 브리핑
- [x] DAY 4~5 실제 상태 목록화
- [x] 1920 Standard·1366/1280 Compact 39장 캡처
- [x] 공통 UI 파급과 DAY 전용 문제 분리
- [x] DAY 4 원정 미리보기 설명 잘림 최소 수정
- [x] 관리 원정 문맥 서랍 계약 확인
- [x] 기존 튜토리얼 ID·규칙·밸런스·저장 호환 유지
- [x] 직접 관련 테스트 통과
- [x] `docs/handoff/CURRENT.md`와 순차 계획 갱신
- [ ] 사용자 최종검수
- [ ] Full 검증·빌드·커밋·푸시·태그·Release
