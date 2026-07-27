# 제품 2.0 최종 UI U3 전투 HUD 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-combat-hud`
- 기준 브랜치 및 SHA: `release/v2.0@88cd1fef30da61d317e434ac9a0e844b42ef8fb2`
- Reviewed SHA: `59e4fe5246414b05bdabcb24b8a4866c61c2019a`
- 마지막 커밋 SHA: handoff·`CURRENT.md` 종료 커밋 전 기준 `59e4fe5246414b05bdabcb24b8a4866c61c2019a`
- 원격 푸시 여부: 작성 시점 미푸시
- 관련 PR 또는 태그: U3 PR 생성 전, 태그·Release 변경 없음

## 2. 이번 세션 목표

- 요청 사항: `V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md`의 U3에 따라 전장을 가장 넓게 유지하고, 목표·방어 구간·실제 위협·전술 명령·속도만 남기는 전투 HUD를 완성한다.
- 완료 조건: 기본 명령은 표식·이름·비용·사용 가능 여부만 표시하고, 대상 선택 중에만 대상 종류·예상 효과·취소 안내와 유효 대상 강조를 노출한다. 성공은 실제 대상·지속 또는 완료·포인트 차감을, 실패는 사유와 포인트 불변을 표시한다.
- 범위에서 제외한 사항: 결과 화면, 밸런스·AI·spawn·HP/ATK·시설/몬스터 효과, 신규 콘텐츠·자산, 전체 회귀·전체 플레이·별도 검수 에이전트, build·배포·태그·Release.

## 3. 완료한 작업

- 전장 우선 배치: 기존 왼쪽 대형 목표 패널과 전장 안의 중복 설명을 제거하고 투명 workspace를 화면 가로폭 전체에 배치했다. 초기 선택 유닛이 있어도 우측 상세 드로어를 자동으로 열지 않는다.
- 상단 상태: `DAY`, 방어 목표, 왕좌 HP와 진행 막대, encounter·phase를 왼쪽 헤더에 압축했다. 오른쪽 속도는 작은 `x1 / x2 / x3 / 정지` segmented control로 유지하고 실제 속도·일시정지 상태를 즉시 반영한다.
- 방어 구간: 성문 전초 → 가시 회랑 → 중앙 전투실 → 왕좌 전실을 한 줄 strip으로 만들고 `교전 / 돌파 / 저지 / 대기`를 표식과 색으로 구분한다.
- 조건부 위협: 실제 telegraph가 존재하고 시작까지 시간이 남은 동안에만 위협 패널을 만든다. 적 행동·남은 시간·권장 명령·권장 대상만 보여 주고, 예고 전과 시작 뒤에는 자동 제거한다.
- 전술 명령: 하단 네 명령을 한 줄로 압축했다. 평상시에는 표식·이름·비용·사용 가능 상태만 표시하며 tooltip의 기존 설명과 모든 명령 동작은 유지한다.
- 대상 선택: 선택 중에만 대상 종류·예상 효과·`ESC 취소`를 보여 준다. 실제 GameRoot 전장에서는 살아 있는 적, 방어 구역, 충전이 남고 무력화되지 않은 설치 시설만 해당 명령의 대상 강조를 받는다.
- 결과 피드백: 성공 시 명령·실제 대상·적용 시간 또는 완료·명령력 전후를 표시한다. 무효 대상과 service 실패는 사용자 사유를 표시하고 명령력과 선택 상태를 보존한다.
- 전장 중복 제거: 방어 구간의 큰 수비/적/시설 텍스트 상자를 제거하고 경로·구역 outline만 남겼다.
- 밸런스 및 콘텐츠: 변경 없음. 명령 비용·쿨다운·지속·효과, encounter 시간, 적/몬스터 수치와 전투 판정은 그대로다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/ui/V20InformationHUD.gd` | 전장 우선 layout, 상단 목표, 단계 strip, 조건부 위협, 압축 명령, 대상/결과 피드백 | 완료 |
| `scripts/game/CombatSceneController.gd` | 실제 속도·목표 갱신, 대상 선택 redraw, 성공·실패 피드백, 기본 드로어 닫힘 | 완료 |
| `scripts/game/GameRoot.gd` | 대형 단계 설명 제거와 유효 대상 전장 강조 | 완료 |
| `scripts/v20/commands/V20CommandService.gd` | 표시 전용 비용·사용 가능·쿨다운 row 필드 | 완료 |
| `scripts/v20/encounters/V20EncounterService.gd` | 실제 telegraph 수명주기와 권장 명령 label의 표시 전용 상태 | 완료 |
| `tools/tests/V20InformationArchitectureTest.gd` | 3해상도 전장 우선·조건부 위협·단계·명령·실시간 상태 계약 | 완료 |
| `tools/tests/V20TacticalCommandsTest.gd` | 명령 불변성·선택·적용 피드백과 3상태 실제 렌더 | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.gd` | 실제 GameRoot 대상 선택·무효 클릭 불변성·전장 렌더 | 완료 |
| `docs/handoff/V20_FINAL_UI_COMBAT_HUD_2026-07-27.md` | U3 검수 근거와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 다음 작업을 U3/U4 기준으로 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: N/A
- 기존 자산 재사용: 실제 렌더 검수 배경에 기존 마왕성 map을 사용
- 신규·수정 그래픽/오디오 asset: 0건

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20InformationArchitectureTest.tscn` headless | PASS | 1280×720·1366×768·1920×1080 IA와 위협 수명주기 115 assertions |
| 2 | `V20TacticalCommandsTest.tscn` headless | PASS | 명령 비용·상태·쿨다운·대상·포인트 불변성 29 assertions |
| 3 | `V20DayOneToFiveEncountersTest.tscn` headless | PASS | encounter schedule·telegraph·결과 계약 198 assertions |
| 4 | `V20OnboardingRetrySaveTest.tscn` headless, 격리 `user://` | PASS | 실제 GameRoot 진행·저장·대상 선택·무효 클릭 58 assertions |
| 5 | `V20TacticalCommandsTest.tscn -- --capture-v20-commands`, Windows OpenGL | PASS | 기본·위협/대상 선택·적용 결과 3개 실제 GPU 렌더, 총 32 assertions |
| 6 | `V20OnboardingRetrySaveTest.tscn -- --capture-v20-combat-root`, Windows OpenGL | PASS | 실제 GameRoot의 전장 전체 폭·살아 있는 적 강조, 총 59 assertions |
| 7 | 실제 캡처 육안 확인 | PASS | 1280×720 겹침·잘림·전장 차단 0건, 조건부 위협과 대상/결과 피드백 위계 확인 |
| 8 | `git diff --check`와 staged 범위 확인 | PASS | Reviewed SHA의 의도한 runtime/test 8개 파일만 포함 |
| 9 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | U0 계약에 따라 F1 전 실행 금지 |

첫 실제 GameRoot 렌더에서 초기 선택 유닛 때문에 우측 대형 상세 드로어가 자동으로 열려 전장 폭을 줄이는 문제를 발견했다. 전투 진입 기본값을 닫힘으로 바꾸고 실제 Windows OpenGL 캡처를 다시 생성해 전장이 전체 폭을 사용하는지 확인했다. 로컬 로그와 캡처는 `.godot/`에만 두고 커밋하지 않았다.

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | U3 전투 HUD | `59e4fe5246414b05bdabcb24b8a4866c61c2019a` | N/A | N/A | 직접 관련 자동 테스트와 실제 렌더 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 F1 전 실행 금지 항목이다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 이 handoff와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 59e4fe5246414b05bdabcb24b8a4866c61c2019a
- Review range: 88cd1fef30da61d317e434ac9a0e844b42ef8fb2..59e4fe5246414b05bdabcb24b8a4866c61c2019a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 전술 명령의 방 target은 기존 서비스 계약대로 문자열 room ID를 허용한다. UI는 현재 네 방어 구역만 강조하며 명령 효과 수치와 이동 판정은 바꾸지 않았다.
- 위협 패널은 가장 최근 telegraph의 ETA가 0보다 큰 동안만 표시한다. 향후 겹치는 telegraph가 추가되면 단일 `last_telegraph` 계약을 별도 확장해야 한다.
- 전투 상세 드로어는 기본 닫힘이다. 현재 U3 범위에는 별도 “상세 열기” 행동을 추가하지 않았다.
- 밸런스는 동결했다. 기존 PR 4 후보는 F1 전체 검수 전까지 공식 PASS가 아니다.
- source SHA·Windows/Web debug build hash 동결은 U5에서 수행한다.

## 8. 다음 작업 순서

1. U3 PR을 `release/v2.0` 대상으로 열고 원격 `repository-policy` PASS 뒤 merge commit으로 병합한다.
2. U3 merge SHA에서 `codex/v20-final-ui-result`를 만들고 U4 결과 화면만 수정한다.
3. U4에서는 승패 제목·핵심 원인·3개 이하 지표·보상/손실·다음 행동과 실제 렌더만 직접 검증한다.
4. U4 merge 전 U5 후보 동결을 시작하지 않는다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: handoff·`CURRENT.md` 종료 변경만 존재
- 미커밋 파일: `docs/handoff/V20_FINAL_UI_COMBAT_HUD_2026-07-27.md`, `docs/handoff/CURRENT.md`
- 의도하지 않은 기존 변경: U3 worktree에는 없음. 원래 `게임소스/` worktree의 사용자 미추적 파일은 건드리지 않았다.
- 스태시 또는 별도 작업공간: 별도 worktree `v20-u0`
- 빌드/캡처 산출물 위치: `.godot/v20-u3-render-appdata/`와 `.godot/*.log`, Git 미추적·미커밋

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 자동 테스트 통과
- [x] 실제 GameRoot 전투 HUD와 대상 선택 렌더 통과
- [x] 요청받은 경우에만 전체 회귀·검수 에이전트 완료 — 요청되지 않았고 계획상 F1 전 금지
- [x] 검수 대상 최종 SHA와 작업 ID 기록
- [x] 그래픽 생성 출처와 런타임 연결 기록 완료 — 신규 자산 없음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR 상태 기록
