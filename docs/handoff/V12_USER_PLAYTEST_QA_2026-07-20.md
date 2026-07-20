# 제품 1.2 실제 사용자 플레이 검수·수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-20
- 목표 버전: 제품 1.2 / 기술 버전 1.2.0, 후속 수정판 후보 1.2.1
- 작업 브랜치: `codex/v12-playtest-fixes`
- 기준 브랜치 및 SHA: `origin/main` / `508441704d64e8e7082f1ed35307d7f99c1021bf`
- 마지막 기능·테스트 커밋 SHA: `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`
- 원격 푸시 여부: `origin/codex/v12-playtest-fixes` 푸시 완료
- 관련 이슈·PR: [이슈 #39](https://github.com/bluehige/mawangseong-demo/issues/39), [draft PR #40](https://github.com/bluehige/mawangseong-demo/pull/40)

## 2. 이번 세션 목표

- 이슈 #39의 이전 Computer Use 플레이 결과와 사용자 추가 지적 3건을 합쳐 제품 1.2의 P1/P2를 수정한다.
- 튜토리얼의 실제 클릭 대상과 설명을 일치시키고, 대화 UI의 의도하지 않은 겹침을 제거하며, 자동전투 유닛 정체를 자가 복구하게 한다.
- DAY 3 패배·승리 결산 및 저장 복원에서 확인된 진행 불가를 함께 수정한다.
- 전체 자동 회귀와 수정 Windows export의 실제 사용자 경로를 재검증한다.
- 신규 콘텐츠, 대규모 밸런스 조정, 기존 `v1.2.0` 태그 이동, Release 교체는 범위에서 제외했다.

## 3. 발견 사항과 완료한 작업

| ID | 심각도 | 발견 내용 | 수정 및 재검증 |
|---|---:|---|---|
| QA-001 | P1 | DAY 3 승리 결산을 저장·재실행하면 v2 개체 ID와 구형 종족 ID가 섞여 성장 버튼이 반응하지 않음 | 복원 경계에서 개체 ID를 종족 ID로 정규화하고 저장·이어하기 회귀를 추가해 PASS |
| QA-002 | P1 | DAY 3 보스 HP 50% 안내 전에 패배하면 재도전 시 전투 시작이 튜토리얼 게이트에 영구 차단됨 | 해당 단계의 DAY 3 재도전에만 시작 우회를 허용하고 초기 튜토리얼 게이트는 유지, 패배→관리→재전투 회귀 PASS |
| QA-003 | P2 | `chronicle`, `outpost`, `upper_floor`의 안전 저장 판단이 GameRoot와 저장소에서 불일치 | 안전 화면 판단을 `CampaignSaveStore.is_safe_screen()` 하나로 통합하고 저장 회귀 PASS |
| QA-004 | P3 | Windows 실행 파일 속성이 Godot 기본 제품명·설명·아이콘으로 보임 | Windows export의 제품명, 설명, 버전, 아이콘 리소스를 제품 1.2 값으로 지정하고 실제 파일 속성 확인 |
| QA-005 | P2 | DAY 2 안내가 노란 가시 복도를 가리키지만 실제 클릭 대상의 노란 테두리가 불명확하고 문장이 복잡함 | 실제 방 중심에 큰 노란 마름모·점·클릭 배지를 표시하고 문장을 짧게 변경. 선택 뒤 오른쪽 `[방 지침]`의 `[함정 유도]`로 단계 연결 |
| QA-006 | P2 | 대화 패널이 캐릭터 초상화 패널과 미묘하게 겹쳐 잘못 배치된 것처럼 보임 | 초상화와 대화 패널 사이에 28px 설계 간격을 두고 패널에 안정적인 이름을 부여. 1280×720 계열 실제 export에서 겹침·잘림 없음 확인 |
| QA-007 | P1 | 자동전투 중 유닛의 경로점이 맵 밖이나 이동 불가 지점에 남으면 계속 갇힐 수 있음 | 모든 경로점을 던전 경계로 보정하고 0.75초 동안 이동 진전이 없으면 오래된 경로점을 폐기해 다음 AI 주기에 재탐색. 경계·정체 회귀와 실제 DAY 1 전투 종료 확인 |
| OBS-001 | 관찰 | 중단된 검수 과정에서 `Godot_v4.5.2-stable_win64.exe` 접근 위반 창이 1회 표시됨 | 출시 실행 파일이 아니라 검수용 Godot 프로세스 종료 시점의 단발 현상으로 분리. 전체 검증 89개와 수정 Windows export 실행·정상 종료에서 재현되지 않음 |

추가 UI 용어는 실제 행동과 맞도록 `집중 방어`를 `입구 봉쇄`, `후퇴 지점`을 `후퇴선 유지`로 통일했다. 신규 그래픽과 밸런스 변경은 없다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/GameRoot.gd` | 튜토리얼 표식·문구, 대화 UI 간격, DAY 3 재도전, 구저장 ID 정규화, 안전 저장 위임 | 완료 |
| `scripts/core/CampaignSaveStore.gd` | 안전 저장 화면 단일 판정 | 완료 |
| `scripts/units/Unit.gd` | 경로점 경계 보정과 정체 복구 | 완료 |
| `scripts/ui/HUDController.gd` | 방 지침 용어 통일 | 완료 |
| `data/onboarding_flow_dialogue_v0.4.json` | 온보딩 표시 용어 통일 | 완료 |
| `export_presets.cfg` | Windows 제품 메타데이터와 아이콘 | 완료, 코드 서명 인증서는 별도 필요 |
| `tools/CampaignSaveLoadSmokeTest.gd` | 결과 화면 개체 ID 복원·안전 화면 회귀 | 완료 |
| `tools/TutorialFlowSmokeTest.gd` | 대화 패널 간격, 가시 복도 표식, DAY 3 패배 재도전 회귀 | 완료 |
| `tools/DemoSmokeTest.gd` | 맵 밖 경로점과 정체 경로 복구 회귀 | 완료 |
| `tools/DirectiveCombatUIVisualCheck.gd` | 변경된 지침 용어 기대값 | 완료 |
| `tools/MobileTouchUISmokeTest.gd` | 변경된 지침 용어 기대값 | 완료 |
| `tools/TutorialUxCapture.gd` | DAY 2 가시 복도 직접 표식 캡처 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 기존 자산만 사용
- 게임 연결 및 실제 렌더 확인 결과: 노란 표식은 런타임 벡터 드로잉으로 구현했고 `tmp/tutorial_ux_verification/08a_day2_spike_corridor_target.png`와 Windows export에서 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `godot --headless --path . --import` | PASS | 콘솔 기록 |
| 2 | `TutorialFlowSmokeTest` | PASS | DAY 1~3 튜토리얼·패배 재도전 회귀 |
| 3 | `CampaignSaveLoadSmokeTest` | PASS, 252 assertions | 결과 화면 저장·이어하기 및 안전 화면 회귀 |
| 4 | `DemoSmokeTest` | PASS | 자동전투 경계·정체 복구 회귀 |
| 5 | `MobileTouchUISmokeTest -- --mobile-touch-ui` | PASS | 모바일 지침 용어 회귀 |
| 6 | `UIRegressionVisualReview`, `TutorialUxCapture` | PASS | `tmp/ui_regression_review/04_dialogue_screen.png`, `tmp/tutorial_ux_verification/08a_day2_spike_corridor_target.png` |
| 7 | `tools/tests/RunCoreVerification.ps1 -Mode Full` | PASS, 89/89 | 작업 트리 1차 `tmp/core_verification/latest.md`; 고정 SHA 재검수 `tmp/review_6a2dd174/tmp/core_verification/latest.md` |
| 8 | 수정 Windows export 생성 및 파일 속성 확인 | PASS | `tmp/windows_playtest/MawangCastle_v1.2.0.exe`, SHA-256 `0529793C5E2E3CB3DDC600B9BF3D873652E2392BD99EF70F9CF551CDD8126820` |
| 9 | Windows Computer Use: 콜드 스타트→새 게임→대화→DAY 1 전투·성장→DAY 2 가시 복도·함정 유도 | PASS | 격리 프로필 `tmp/computer_use_appdata_20260720_001/`, 첫 플레이 기록 `first_play_observation/latest.md` |
| 10 | 기존 이슈 #39 Computer Use: DAY 1~3 보스 50% 단계까지 실제 사용자 경로 | 발견 사항 반영 | `tmp/issue39_qa_profile_20260720_001/first_play_observation/latest.md` |

Windows Computer Use는 1284×748 창에서 진행했다. 기존 사용자 저장 `campaign_save_v1.json`의 SHA-256 `28C157C9DF84776A37D61ECE1A7C58E70465212E2589D84C845D955FEF22196C`과 수정 시각은 검수 전후 동일하다.

### 검수 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 | 주요 지적 | 수정 내용 | 근거 | 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `FULL_USER_PLAYTEST_2026-07-20_V12` | 이슈 #39 출시본·기존 실제 사용자 경로 | 공개 v1.2 및 기준 `5084417` | DAY 3 결산·재도전 P1, 사용자 UI·AI 지적 | 위 QA-001~007 | 이슈 #39 프로필·자동 회귀 | 수정 완료 |
| 2 | `FULL_USER_PLAYTEST_2026-07-20_V12` | `508441704d64e8e7082f1ed35307d7f99c1021bf..6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54` | `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54` | 수정 후 회귀·실기동 확인 | 전체 89/89 및 Windows export 재검수 | `tmp/review_6a2dd174/tmp/core_verification/latest.md`, 격리 프로필 | PASS |

- 남은 P1/P2 지적: 0건
- 실행하지 못한 필수 검수와 이유: 물리 한/영 키 조합 중 IME 상태는 Computer Use가 물리 키보드 조합을 증명할 수 없어 수동 실기 확인이 필요하다. 최종 Windows 코드 서명은 인증서가 없다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 이 핸드오프 문서와 `CURRENT.md`뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: FULL_USER_PLAYTEST_2026-07-20_V12
- Reviewed SHA: 6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54
- Review range: 508441704d64e8e7082f1ed35307d7f99c1021bf..6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- 기능상 남은 재현 P1/P2는 없으며, 불변 검수 SHA `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54`에서 전체 89/89를 통과했다.
- Windows 실행 파일은 제품 메타데이터와 아이콘을 갖지만 코드 서명 인증서가 없어 서명되지 않았다.
- 물리 Microsoft 한국어 IME의 한/영 전환·조합 중 Backspace는 수동 키보드 실기 확인이 남아 있다.
- 이 세션에서는 새 Web export·공개 URL 재배포와 `v1.2.1` 태그·Release를 만들지 않았다.
- Godot 검수 프로세스 접근 위반은 수정 export에서 재현되지 않았지만, 같은 엔진 프로세스 단발 재발 시 Windows 이벤트 로그와 덤프를 보존해야 한다.

## 8. 다음 작업 순서

1. draft PR #40의 필수 상태 검사를 확인한다.
2. 리뷰가 끝나면 merge commit 방식으로 `main`에 통합할 준비를 한다.
3. 물리 한국어 IME와 코드 서명 인증서 적용을 확인한 뒤 `v1.2.1` 출시 여부를 결정한다. 기존 `v1.2.0` 태그는 이동하지 않는다.

## 9. 작업 트리 상태

- 브랜치: `codex/v12-playtest-fixes`
- 원격 상태: `origin/codex/v12-playtest-fixes` 푸시 및 draft PR #40 생성 완료
- 의도하지 않은 기존 변경: 아래 미추적 UID 5개는 사용자 소유로 보존하고 수정·스테이징하지 않았다.
  - `tools/tests/FinaleEveHardeningTest.gd.uid`
  - `tools/tests/Update3BaselineContractTest.gd.uid`
  - `tools/update3_baseline/Update3BaselineSpec.gd.uid`
  - `tools/update3_baseline/Update3BaselineSummary.gd.uid`
  - `tools/update3_baseline/Update3BaselineTrial.gd.uid`
- 빌드·캡처 산출물 위치: `tmp/windows_playtest/`, `tmp/core_verification/`, `tmp/tutorial_ux_verification/`, `tmp/ui_regression_review/`, `tmp/computer_use_appdata_20260720_001/` (소스 브랜치에 커밋하지 않음)

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 전체 자동 회귀 통과
- [x] 수정 Windows export의 실제 사용자 경로 재검수
- [x] 검수 대상 불변 커밋 SHA 기록
- [x] 그래픽 생성 없음 및 기존 자산 사용 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 기능·테스트 파일만 커밋
- [x] 원격 푸시 및 draft PR #40
