# 제품 2.0 최종 UI U4 결과 화면 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-27
- 목표 버전: 제품 2.0 / SemVer `2.0.0`
- 작업 브랜치: `codex/v20-final-ui-result`
- 기준 브랜치와 SHA: `release/v2.0@56dd5657962a72359a70fe110977f773d4317926`
- Reviewed SHA: `903ba65aa15da3d1aaaeb70fc9eb7a4f7cebc913`
- 마지막 커밋 SHA: handoff·`CURRENT.md` 종료 커밋은 Reviewed SHA 뒤에 추가
- 원격 푸시 여부: 작성 시점 미수행
- 관련 PR 또는 태그: U4 PR 생성 전, 태그·Release 변경 없음

## 2. 이번 세션 목표

- `V20_FINAL_UI_RELEASE_TRANSPLANT_PLAN.md`의 U4에 따라 결과 화면을 승패 요약과 다음 행동 중심으로 재설계한다.
- 승패, 핵심 원인 1개, 잘한 점 1개, 다음에 바꿀 점 1개, 왕좌 피해·첫 교전·정산 3개 지표를 즉시 읽을 수 있게 한다.
- 패배 시 `배치 수정`을 가장 큰 주 행동으로, `같은 배치 재도전`을 보조 행동으로 둔다. 승리 시에는 `다음 침입 확인`만 주 행동으로 둔다.
- 상세 기록은 기본 접힘으로 두고 전투 시간, 첫 교전, 시설 기여, 몬스터 피해, 명령 사용, 도난·시설 무력화·누수, 보상·수리·정산을 실제 결과 데이터로만 표시한다.
- 범위에서 제외한 사항: 밸런스·AI·spawn·HP/ATK·시설/몬스터 효과, 결과 계산, 신규 성장·콘텐츠·자산, 전체 회귀·전체 플레이·검수 에이전트, build·배포·태그·Release.

## 3. 완료된 작업

- `V20ResultScreen`을 U1 공통 테마 위에서 승패 헤더, 단일 핵심 원인, 잘한 점, 다음 변경점, 3개 1차 지표, 접힌 상세 기록, 행동 dock 구조로 재작성했다.
- 결과 원인은 기존 `metrics.v20_evidence`와 `v20_required_objective_failure`를 표시용으로만 매핑한다. 도난, 시설 무력화, 후열 압박, 후퇴선 돌파·누수, 왕좌 피해의 실제 수치를 사용한다.
- 왕좌 피해는 `v20_evidence.throne_damage`를 우선하고, 첫 교전 구역은 canonical zone ID만 한글 표시명으로 바꾸며, 정산은 기존 `v20.net_income`을 그대로 표시한다.
- 결과 화면에서 보상·수리·정산이나 전투 성과를 새로 계산하지 않는다.
- 패배 `배치 수정` 버튼을 `같은 배치 재도전`보다 크게 만들고 기존 `retry_edit`·`retry_same` signal을 유지했다. 승리의 `next_day`·`complete` signal도 유지했다.
- 실제 GameRoot 패배 경로에서 `v20_evidence` 왕좌 피해 1500이 핵심 원인과 1차 지표에 그대로 나타나는지 확인했다.
- 1280×720, 1366×768, 1920×1080에서 패배 기본·상세와 승리 상태를 검증했고, Windows OpenGL 실제 렌더와 실제 GameRoot 1280×720 렌더를 직접 확인했다.
- 신규 그래픽·오디오 자산은 추가하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/v20/ui/V20ResultScreen.gd` | 원인·학습·3개 지표·상세·다음 행동 중심 결과 화면 | 완료 |
| `tools/tests/V20ResultScreenTest.gd` | 3해상도 결과 UI, 실제 evidence 수치, 상세 접힘, 승패 signal 검증 | 완료 |
| `tools/tests/V20ResultScreenTest.tscn` | U4 타깃 테스트 진입 scene | 완료 |
| `tools/tests/V20OnboardingRetrySaveTest.gd` | 실제 GameRoot 결과 원인·행동 위계·헤더·재도전 경로와 캡처 검증 | 완료 |
| `docs/handoff/V20_FINAL_UI_RESULT_2026-07-27.md` | U4 검증 근거와 다음 단계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 단일 진입점과 U4/U5 기준 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본·`SOURCE.md`·편집본·최종 자산 경로: N/A
- 신규·수정 그래픽 또는 오디오 자산: 0건

## 6. 테스트 및 검증

| 순서 | 검사 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `V20ResultScreenTest.tscn` headless | PASS | 3해상도 패배·상세·승리·signal·실제 evidence 41 assertions |
| 2 | `V20OnboardingRetrySaveTest.tscn` headless, 격리 `user://` | PASS | 실제 GameRoot 결과·재도전·저장 경로 60 assertions |
| 3 | `V20ResultScreenTest.tscn -- --capture-v20-results`, Windows OpenGL | PASS | 패배 기본·상세·승리 3개 실제 GPU 렌더, 총 44 assertions |
| 4 | `V20OnboardingRetrySaveTest.tscn -- --capture-v20-result-root`, Windows OpenGL | PASS | 실제 GameRoot 패배 결과 1280×720 렌더, 총 61 assertions |
| 5 | 최신 실제 GameRoot 캡처 육안 확인 | PASS | 승패·DAY·안내·원인·학습·3지표·행동 잘림 0건 |
| 6 | `git diff --check`와 staged 범위 확인 | PASS | runtime/test 4개 파일만 Reviewed SHA에 포함 |
| 7 | 전체 회귀·전체 플레이·실제 물리 70전·검수 에이전트 | NOT_REQUESTED | U0 계약에 따라 F1 전 실행 금지 |

격리 로그와 PNG는 `.godot/v20-u4-*-appdata/`와 `.godot/*.log`에만 남겼으며 Git에는 포함하지 않는다.

### 검사 에이전트 반복 기록

| 회차 | 검사 작업 ID | 검사 범위 | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검사 결과 |
|---:|---|---|---|---|---|---|---|
| - | NOT_REQUESTED | U4 결과 화면 | `903ba65aa15da3d1aaaeb70fc9eb7a4f7cebc913` | N/A | N/A | 직접 관련 자동 테스트와 실제 렌더 | TARGETED_PASS |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 F1 전 실행 금지 항목이다.
- PASS 이후 기능·데이터·자산 변경 여부: 0건. Reviewed SHA 뒤에는 handoff와 `CURRENT.md`만 추가한다.

### 정책 CI와 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 903ba65aa15da3d1aaaeb70fc9eb7a4f7cebc913
- Review range: 56dd5657962a72359a70fe110977f773d4317926..903ba65aa15da3d1aaaeb70fc9eb7a4f7cebc913
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 원인 문구는 기존 evidence와 필수 목표 실패 ID의 표시 매핑이다. 결과 판정이나 수치 계산은 바꾸지 않았으며 이후 새 실패 ID가 추가되면 표시 매핑도 추가해야 한다.
- 상세 기록은 2열 구조다. 현재 최소 지원 해상도 1280×720에서는 검증됐지만 모바일 전면 개편은 이번 범위가 아니다.
- 결과 화면의 자동·실제 렌더 PASS는 실제 재미·밸런스·70전 물리 PASS가 아니다.
- U5 source SHA와 Windows/Web debug artifact hash는 아직 동결되지 않았다.

## 8. 다음 작업 순서

1. U4 문서 커밋만 추가하고 원격에 푸시한다.
2. `release/v2.0` 대상 U4 PR을 열어 원격 `repository-policy` PASS 뒤 merge commit으로 병합한다.
3. U4 merge SHA에서 `codex/v20-final-ui-candidate`를 만들고 U5 후보 동결만 수행한다.
4. U5에서 관련 UI 타깃 검사와 Windows/Web debug export를 수행하고 source SHA 및 artifact SHA-256을 고정한다.
5. 사용자가 그 고정 후보를 직접 테스트하고 명시적으로 `V20_UI_OWNER_ACCEPTED`를 남길 때까지 P0를 시작하지 않는다.

## 9. 작업 트리 상태

- 구현 Reviewed SHA: `903ba65aa15da3d1aaaeb70fc9eb7a4f7cebc913`
- handoff·`CURRENT.md`는 Reviewed SHA 뒤 문서 전용 커밋으로 분리한다.
- 원래 `게임소스/` worktree의 기존 미추적·수정 파일은 건드리지 않았다.
- 빌드·캡처 산출물은 `.godot/` 아래이며 커밋하지 않는다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 자동 테스트 통과
- [x] 3해상도 결과 화면 실제 렌더 확인
- [x] 실제 GameRoot 결과 화면과 재도전 경로 확인
- [x] 전체 검수·별도 검수 에이전트는 계획대로 F1까지 실행하지 않음
- [x] Reviewed SHA와 범위 기록
- [x] 신규 그래픽·오디오 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 문서 파일만 커밋
- [ ] 원격 푸시·PR·정책 검사·병합 상태 기록
