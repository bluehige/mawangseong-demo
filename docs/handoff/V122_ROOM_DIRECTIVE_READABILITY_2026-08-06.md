# V1.2.2 방 지침 가독성 확대

## 1. 메타데이터

- 작성일: 2026-08-06
- 목표 버전: 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `origin/main` / `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `a0973152132b725d7dc4631c1837386fce3244b4`
- 원격 푸시 여부: 미푸시. 현재 브랜치는 원격 작업 브랜치보다 4커밋 앞서며 이번 수정은 미커밋이다.
- 관련 PR 또는 태그: 기존 Draft PR #80. 사용자 화면 승인 전에는 커밋·푸시·PR 갱신·병합·태그·Release를 진행하지 않는다.
- 현재 사용자 테스트 빌드: `tmp/v122_room_directive_readable_fix3/20260806_013913/MawangCastle-v1.2.2-DirectiveReadable-Fix3-Windows.zip`

## 2. 이번 세션 목표

- 요청 사항: 튜토리얼에서 오른쪽 방 지침 선택 글자와 펼침 목록이 지나치게 작고 읽기 어렵다는 문제를 확인하고, 가능한 공간을 사용해 실사용 크기로 확대한다.
- 완료 조건: 1280×720에서 선택값과 네 개 펼침 항목이 읽히고, 튜토리얼 강조 링·설명·아래 시설 영역과 겹치지 않으며, 관련 관리·튜토리얼·터치 테스트와 새 Windows 빌드가 통과한다.
- 범위에서 제외한 사항: 다른 공통 `OptionButton`의 일괄 변경, 정식 출시 전체 회귀 156개, 전체 플레이, 별도 검수 에이전트, 커밋·푸시·PR·병합·태그·Release.

## 3. 완료한 작업

- 원인 재현: 관리 UI가 1920 가상 좌표계에서 구성된 뒤 1280 화면에 축소되는데, 방 지침은 글자 13px·버튼 높이 36px로 설정돼 체감 약 9px가 됐다. 패널 폭 306px에는 현재 문구를 키울 공간이 충분했다.
- 테스트 우선 보정: 1280×720 전용 펼침 목록 캡처와 `버튼 높이 >= 46`, `선택 글자 >= 20`, `목록 글자 >= 20` 계약을 먼저 추가했다. 기존 구현이 `36/13/13`으로 실패하는 것을 확인한 뒤 구현했다.
- UI/UX: 전체 전술과 선택 방 지침의 선택 글자·펼침 목록을 13px에서 20px, 버튼 높이를 36px에서 46px로 확대했다.
- UI/UX: 두 구역 제목을 17px, 설명을 14px로 확대했다. 지침 패널 높이를 220px에서 252px로 늘리고 아래 시설 및 추가 작전 영역을 32px 내려 겹침을 막았다.
- 검증 도구: 튜토리얼 UX 캡처가 실제 1280×720에서 방 지침 팝업을 열고 크기·표시 여부를 검사한 뒤 화면을 저장하도록 확장했다.
- 기존 전투 수정 포함: Fix3는 같은 작업 트리의 `바닥 0 < 유닛 1..44 < 전면 벽 50` 깊이 보정과 N/W 0.94·E/S 0.46 벽 투명도도 포함한다.
- 스토리·데이터·밸런스·저장 형식·그래픽·오디오: 이번 가독성 보정으로 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/ManagementSceneController.gd` | 방 지침 선택값·펼침 목록·제목·설명 확대와 세로 재배치 | PASS |
| `tools/TutorialUxCapture.gd` | 1280×720 방 지침 팝업 가독성 계약 및 실제 캡처 | PASS |
| `docs/handoff/CURRENT.md` | Fix3를 현재 유일 테스트본으로 지정 | 완료 |
| `docs/handoff/V122_UNIT_ABOVE_FLOOR_DEPTH_CORRECTION_2026-08-06.md` | Fix2를 SUPERSEDED로 표시하고 Fix3 연결 | 완료 |
| `docs/handoff/V122_ROOM_DIRECTIVE_READABILITY_2026-08-06.md` | 이번 변경·검증·빌드 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 없음
- 생성 모델: 해당 없음
- 생성 원본 경로: 변경 없음
- `SOURCE.md` 경로: 변경 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: PNG·오디오 파일을 변경하지 않았다.
- 게임 연결 및 실제 렌더 확인 결과: 실제 Vulkan 1280×720 캡처 `tmp/tutorial_ux_verification/08b_day2_trap_lure_popup_1280x720.png`에서 확대된 선택값과 네 개 목록, 강조 링, 설명, 아래 시설 패널이 겹침 없이 표시됐다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 수정 전 `TutorialUxCapture.tscn` 1280×720 가독성 계약 | 기대대로 FAIL, `height=36`, `button_font=13`, `popup_font=13` 재현 | `tmp/v122_room_directive_readability_repro.log` |
| 2 | 수정 후 `TutorialUxCapture.tscn` 실제 Vulkan | PASS, 1280×720 버튼·팝업·강조 링 확인 | `tmp/v122_room_directive_readability_fix.log` |
| 3 | 1280×720 방 지침 펼침 목록 화면 | PASS, 네 항목 및 주변 UI 겹침 없음 | `tmp/tutorial_ux_verification/08b_day2_trap_lure_popup_1280x720.png` |
| 4 | `V122ManagementInteractionTest.tscn` | PASS | `tmp/v122_room_directive_management_interaction.log` |
| 5 | `MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS, 84 assertions | `tmp/v122_room_directive_mobile_touch_ui.log` |
| 6 | `TutorialFlowSmokeTest.tscn` | PASS | `tmp/v122_room_directive_tutorial_flow.log` |
| 7 | Windows Desktop release export | PASS, EXE/PCK 생성 | `tmp/v122_room_directive_readable_fix3/20260806_013913/export.log` |
| 8 | 새 EXE 1280×720 10초 실제 부팅 | PASS, 프로세스 생존·조기 종료 없음·오류 0건 | `tmp/v122_room_directive_readable_fix3/20260806_013913/boot.log` |
| 9 | ZIP 엔트리·SHA-256 | PASS, EXE/PCK 2개 | SHA-256 `31751D1CCFFA99A2C43636194E34E7ABDF73CC790E4F46924C497F1C54EC40DF` |
| 10 | `git diff --check` | PASS | 로컬 명령 결과 |
| 11 | 전체 회귀 테스트 | NOT_REQUESTED | 실행하지 않음 |
| 12 | 전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A. 전체 검수는 요청되지 않았다.
- 실행하지 못한 필수 검수와 이유: 없음. 현재 가독성 결함에 직접 관련된 코드·화면·빌드 검증은 완료했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 핸드오프 문서만 갱신했다.
- 참고: headless 테스트 종료 시 나온 인증서·sandbox 저장 경로·리소스 정리 메시지는 테스트 본문의 실패가 아니며 각 suite 최종 판정은 PASS다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: 7ee0b50965dd3944a7ab737c0eca76d2df2a82ad..UNCOMMITTED_WORKTREE
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 자동 검사와 실제 1280×720 화면에서는 해결됐다. 사용자가 실제 빌드에서 체감 크기를 승인하는 단계가 남았다.
- 밸런스 관찰 항목: 없음.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 없음. headless sandbox 저장 경고는 제품 실행 경로와 무관하다.
- 사용 금지 빌드: `tmp/v122_wall_fix_test/20260805_235830/`과 `tmp/v122_wall_transparency_test/20260806_004048/`은 REJECTED다. `tmp/v122_unit_above_floor_fix2/20260806_012035/`는 깊이 수정은 유효하지만 작은 방 지침 때문에 SUPERSEDED됐다.

## 8. 다음 작업 순서

1. 사용자가 Fix3 ZIP을 새 폴더에 풀고 튜토리얼의 방 지침 선택값·펼침 목록과 초반 전투의 유닛·벽 깊이를 함께 확인한다. 완료 조건은 글자가 편하게 읽히고 네 항목이 잘림 없이 보이며 유닛이 바닥 위·전면 벽 아래에 표시되는 것이다.
2. 화면 승인을 받으면 현재 코드·데이터·도구·핸드오프 파일만 명시적으로 스테이징하고 기능 커밋을 만든다.
3. 사용자의 출시 진행 지시에 따라 기능 SHA에서 공식 Full 검수, 푸시, PR merge commit, `v1.2.2` 태그와 GitHub Release를 재개한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: `codex/v122-ui-simplification`이 원격보다 4커밋 앞서며 이번 수정은 미커밋이다.
- 미커밋 파일: 이번 관리 UI·튜토리얼 캡처·핸드오프와 직전 벽·깊이 수정의 코드·데이터·테스트 파일.
- 의도하지 않은 기존 변경: 없음. 직전 벽·깊이 수정과 이번 UI 수정이 같은 사용자 검수 흐름에 포함된다.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `tmp/v122_room_directive_readable_fix3/20260806_013913/`, `tmp/tutorial_ux_verification/` (Git 비추적).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 수정 전 작은 글자 결함 재현
- [x] 관련 테스트 통과
- [x] 실제 Vulkan 1280×720 팝업 화면 확인
- [x] 요청받지 않은 전체 회귀·검수 에이전트 미실행 사실 기록
- [x] 검수 대상이 미커밋 작업 트리임을 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 새 Windows 사용자 테스트 빌드·부팅·ZIP 완료
- [ ] 사용자 시각 승인
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
