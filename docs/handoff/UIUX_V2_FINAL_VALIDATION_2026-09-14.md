# UIUX V2 최종 완성도 수정·검증 — 2026-09-14

**합의한 범위의 구현·최종 검증 완료.** 현재 캐릭터 그림을 유지하고 방향별 미술은 사용자 지시로 후속 확정했다. 전체161항목 실행은160 PASS/1 FAIL이었으며 마지막 검사 결함을 수정한 직접 재검증177항목이 PASS다. 단일 실행161/161 PASS나 공개 출시 승인으로 기록하지 않는다.

## 1. 메타데이터

- WORKSTREAM_ID: UIUX-V2-FINAL-20260914
- 작성일: 2026-09-14
- 목표 버전: 공개 안정판 1.2.6 보존. 다음 제품 버전 미확정.
- 작업 브랜치: codex/v126-uiux-u0-u3
- 기준 브랜치 및 SHA: main / origin/main / 실제 원격 main `69a75970b1f8c030aa3a6956e5ca0f5bf15b2112`. 2026-09-14 ls-remote 재확인.
- 시작 HEAD: `6dda1bfcd5b498c6ba96d6fa5e850adcb8fc4050`
- 구현·검증 최종 소스 SHA: `7fd2401e01fdb7fc9872c2c777ab3ea93939c7e4`
- 로컬 구현 커밋: 7fbd940 → b138d17 → f58639e → 61f05ac(검사만 수정) → 7fd2401(출처 문서 형식만 수정). 기존 사용자 변경·과거 v20·태그 보존.
- 원격 푸시·PR·태그·Release: 없음.
- 사용자 최신 요청은 전체 완성 판정까지 수정·검증이다. 이전 ‘전체 검수는 마지막’ 순서를 지켜 구현 후 최종 검사에서 발견한 실패를 수정·재검증했다. 전체 DAY 1~30 자동 실행도 이번 명시적 전체 요청에 근거한다. 검수 에이전트는 사용자 금지에 따라 사용하지 않았다.
- main의 역사적 1.2.5 문구보다 최신 사용자 지시와 CURRENT의 안정판1.2.6을 적용. 제품 버전은 변경하지 않았다.

## 2. 목표와 완료 경계

- 게임 이동·UI 가독성·조작·밸런스·스토리의 누적 지적을 실제 실행으로 대조하고 발견한 기능 결함을 수정한다.
- 검은 벽/밝은 돌바닥, 원래 높이의 벽과 앞벽 반투명 가림, 성장 단계별 준비된 미궁, 적 목표별 진입로, 지정 건설 구역을 유지한다.
- 카드→드래그→유효/불가 고스트→검토→확정/취소→기존 Undo 및 클릭·키보드 대안 보존.
- 기존 콘텐츠·비용·보상·적 전투 수치·성장·세이브 형식은 유지한다. 직접 발견한 시설 범위와 사수 AI 회귀만 의도된 기존 규칙으로 복구했다.
- 최종 공개 출시, 8인/사람 사용성, Web·모바일 실기기·저사양 장시간 검증은 수행하지 않았다.

## 3. 완료한 수정

1. **시설 효과가 미궁 입구에서 누락되던 실제 결함**: 동일 경로를 두 전선이 공유할 때 공통 경로 전체를 왕좌 합류 구역으로 분류하던 코드를 수정했다. 명시된 합류 기준점과 그 이후 구간만 합류 구역으로 처리한다. 병영·감시·회복의 기존 수치와 적용 방식은 유지한다.
2. **사수 전술의 원거리 추격 회귀**: 수비대 샛문이 열렸다는 이유만으로 먼 목표까지 사수가 추격하던 분기를 제거했다. 기존 배치/현재/인접 방 방어와 위급 아군 지원 예외는 보존. 샛문 비용1000금화/100마력과 아군 전용 경로는 그대로다.
3. **의회 새 회차 편성 덮어쓰기**: 의회 전투 편성이 초반 미궁의 DAY 1~3 편성으로 덮이지 않도록 카탈로그 반환 경로를 분리했다.
4. **시설 설명과 실제 효과 일치**: 준비된 미궁은 구역 효과 카탈로그에서 설명을 만든다. 병영 공격10%/피해감소8%, 감시 이동감소18%/받는피해12%, 수호핵10%를 실제 범위와 함께 표시. 회복은 실제 성 단계 배율까지 반영(최종단계12/초). 기존 일반 지도 설명은 유지. 전투 효과 목록도 같은 구역 규칙의 기본 효과를 표시한다.
5. **안내와 터치 가독성**: 튜토리얼이 실제 수비대 카드/건설 도구함/하단 행동바를 가리지 않도록 배제 영역을 계산. 어두운 스킨에 묻히던 클릭 안내 글자는 밝은 색으로 수정. 터치 전술 탭·방 상세·닫기·교체·강화 입력 영역 확보. 예비 몬스터의 긴 저장 위치를 2줄로 읽을 수 있게 카드 높이를 확장.
6. **입력 계층**: 전초기지·상층의 수동 장식 패널이 입력을 잡아먹지 않도록 수정. 실제 버튼의 입력은 유지한다.
7. **실제 자산 연결 기록**: 정책 검사에서 발견한 진화/왕관 초상 SOURCE.md 세 문서의 목록 접두사·버전 표기를 고정 필드 형식으로 맞췄다. 이미지 픽셀·프롬프트·생성 날짜·제품 버전은 그대로다.  후반 적6종 manifest가 현재 사용하는 uiux3d 자산/SOURCE를 가리키도록 정정.
8. **검증 도구 복구**: 옛 UI 버튼/성장 선택/미술 경로 기대값을 현재 활성 경로로 갱신. 셰이더 자체를 금지하던 검사는 앞벽 가림 셰이더를 허용하되 크로마키가 꺼져 있는지 검증. 512px 독립 초상 atlas를 작은 전투 아이콘과 구분하고 왕관 부상 초상을 실제 새 자산으로 검사. 스크립트 오류가 exit0으로 묻히지 않도록 전체 검사 실행기도 수정.

## 4. 변경 파일

이번 소스 변경은 35경로다. 정확한 전체 목록과 로컬 빌드 해시는 `tmp/uiux_final_20260914/summary.json`, `windows/verification-manifest.json`에 남긴다.

| 경로 | 변경 목적 |
|---|---|
| scripts/game/CombatSceneController.gd | 시설 구역 매핑·사수 추격 회귀 수정 |
| scripts/game/GameRoot.gd | 의회 편성·튜토리얼 배치/대비·시설 실제 설명 |
| scripts/ui/FacilityEffectText.gd | 구역 카탈로그를 표시 설명으로 변환 |
| scripts/ui/ManagementWorkspaceUI.gd | 터치 탭·선택 상세의 큰 조작 영역 |
| scripts/ui/MonsterWorkspaceUI.gd | 예비 동료 위치명 잘림 수정 |
| scenes/ui/screens/OutpostManagementScreen.gd, UpperFloorScreen.gd, scenes/outpost/OutpostBattleRoot.gd | 수동 패널 입력 통과 |
| data/regular_version/update4/asset_manifest.json | 후반 적 실제 런타임 자산 경로 |
| tools/tests/UIUXFacilityRouteScopeTest.* | 공통 입구/합류 기준점·효과 설명 회귀 |
| tools/tests/RunCoreVerification.ps1, core_verification_suite.json | 스크립트 오류 감지와 범위 검사 등록 |
| tools/BalanceSimulation.gd, DayOneToThreePlaytestRecorder.gd | 새 미궁에서 실제 전선을 사용하는 비교 fixture·시간 예산 분리 |
| 나머지 tools/*Test.gd 및 UIRegressionVisualReview.gd | 현재 입력·새 그림·효과 규칙에 맞춘 검사 갱신 |

## 5. 그래픽·오디오

- 이번 세션 신규 이미지 생성·픽셀 편집·음원 생성 없음. 이전의 유효한 GPT 내부 생성 자산을 사용했다.
- 현재 호출 가능한 내부 이미지 도구는 prompt/reference만 노출한다. 이전 투명 요청3회 결과는 알파 없는 RGB 체크무늬여서 미채택. 이것을 모델 일반의 투명 생성 불가로 해석하지 않는다.
- 사용자 승인 후속 범위: 앞/뒤/좌/우 캐릭터 미술. 이번 완성 조건과 남은 P1/P2에서는 제외한다. [제작 요청·실패 근거](../design/UIUX_DIRECTIONAL_ASSET_REQUEST_2026-09-13.md). 실제 새 방향 그림이 없는 것을 좌우 반전으로 완료 처리하지 않는다.
- 사용자 최종 답변: **“현재 캐릭터 그림을 유지하고 방향별 미술은 후속 작업으로 확정”**. 현재 유효한 캐릭터 그림을 그대로 사용하며, 방향별 그림을 제작했다고 주장하지 않는다. 투명화 방법의 추가 승인 대기는 종료했다.
- 오디오 기능/믹스 자동 계약은 전체 검사에 포함. 사람 청취 피로도 판정은 수행하지 않았다.

## 6. 검증과 증거

### 전체 검사

| 회차 | 소스/상태 | 결과 | 근거 |
|---|---|---|---|
| 최초 전체 | 시작 HEAD6dda1bf | 136/160, 24 FAIL — 실패 원본 보존 | tmp/core_verification/runs/20260914_004931/report.json |
| 수정 후 전체 | 7fbd940 시작, 후반 시설 표시 수정 발생 | 160/161, DemoSmokeTest FAIL. 다음 행의 직접 재검사로 보완 | tmp/core_verification/runs/20260914_014406/report.json |
| 후반 표시 재검사 | b138d17와 동일 제품 소스 | DemoSmokeTest PASS, 구역/회복 설명13 PASS, 터치84 PASS | tmp/uiux_final_20260914/demo_final_repair.log, scope_text_final.log, touch_verified.log |
| 최종 전체 | f58639e · 독립 APPDATA, 아래 검사만 후속 수정 | FAIL {'total': 161, 'passed': 160, 'failed': 1} | tmp/core_verification/runs/20260914_053800/report.json |

최종 전체의 tutorial_flow 실패는 동시 실행 게임이 공유하는 dev/latest 보고서를 읽은 검사 경쟁 조건이었다. 해당 세션 원본에는 차단 횟수2가 정상 보존되어 있었다. 61f05ac에서 전용 세션 JSON/Markdown을 읽고 현재 게임의 session_id·메모리 횟수까지 대조하도록 수정했다. `tutorial_session_repaired.log`에서 모든 항목 PASS/exit0. f58639e 이후 제품 코드·데이터·자산은 같고 `tools/TutorialFlowSmokeTest.gd`와 위 출처 문서 형식만 달라 전체 게임 검사를 다시 반복하지 않았다. 재검증 실행 SHA는61f05ac, 최종 검증 SHA는출처 형식 정정7fd2401이며 저장소 정책을 별도로 재확인한다. 전체 원본 FAIL은 보존하며, 단일 실행161/161 PASS라고 표현하지 않는다.

첫 전체의 24실패를 그냥 지우지 않았다. 실제 범위/사수/의회/입력/터치 결함은 제품에서 수정했고, 새 UI/자산에 맞지 않는 검사는 현재 활성 경로로 변경했다. BGM 시작 실패는 별도 재현77항목 및 후속 전체에서 통과했으며 음원 코드를 임의 변경하지 않았다.

자체 점검(SelfTest)은 의도된 산출물 누락과 시간초과를 **각각 FAIL로 감지**했다. 이것을 제품 실패 또는 모든 검사 PASS로 표현하지 않는다. 손상 세이브 JSON의 의도된 파싱 오류와 일부 검사 종료 시 리소스 정리 경고는 실행 로그에 보존한다.

### 누적 UIUX 검사

Windows/Godot4.6.3/Forward+/RTX3060Ti. 1920×1080·1280×720, 기존90/100/115% 글자 및 일부 구형1366×768 행렬. 순수 함수/통제된 게임 상태/실제 Input 입력/네이티브 캡처가 섞여 있으므로 모든 assertion을 사람 조작으로 부르지 않는다. 동시 실행 구간의 시간은 성능 벤치마크로 쓰지 않는다.

| 검사 | 최종 기록 | 로그 |
|---|---|---|
| UIUXBuildPlacementTest | UIUX_BUILD_PLACEMENT_TEST: PASS (344 checks) | `tmp/uiux_final_20260914/UIUXBuildPlacementTest_current.log` |
| UIUXPreparedMazeTest | UIUX_PREPARED_MAZE_TEST: PASS (19224 assertions, 98 captures) | `tmp/uiux_final_20260914/UIUXPreparedMazeTest_current.log` |
| UIUXU4InteractionTest | UIUX_U4_INTERACTION_TEST: PASS (517 assertions) | `tmp/uiux_final_20260914/UIUXU4InteractionTest_repaired.log` |
| UIUXU5InteractionTest | UIUX_U5_INTERACTION_TEST: PASS (474 assertions) | `tmp/uiux_final_20260914/UIUXU5InteractionTest_current.log` |
| UIUXSecondaryInteractionTest | UIUX_SECONDARY_INTERACTION_TEST: PASS (3284 assertions) | `tmp/uiux_final_20260914/UIUXSecondaryInteractionTest_current.log` |
| UIUXCombatInteractionTest | UIUX_COMBAT_INTERACTION_TEST: PASS (210 assertions) | `tmp/uiux_final_20260914/UIUXCombatInteractionTest_current.log` |
| UIUXCouncilInteractionTest | UIUX_COUNCIL_INTERACTION_TEST: PASS (138 assertions) | `tmp/uiux_final_20260914/UIUXCouncilInteractionTest_current.log` |
| UIUXPolishIntegrationTest | UIUX_POLISH_INTEGRATION_TEST: PASS (120 assertions) | `tmp/uiux_final_20260914/UIUXPolishIntegrationTest_current.log` |
| UIUXCrowdMotionTest | UIUX_CROWD_MOTION_TEST: PASS (34 assertions) | `tmp/uiux_final_20260914/UIUXCrowdMotionTest_current.log` |
| UIUXActorWallDepthTest | UIUX_ACTOR_WALL_DEPTH_TEST: PASS (975 assertions, 32 captures) | `tmp/uiux_final_20260914/UIUXActorWallDepthTest_current.log` |
| UIUXInspectorReadabilityTest | UIUX_INSPECTOR_READABILITY_TEST: PASS (132 assertions) | `tmp/uiux_final_20260914/UIUXInspectorReadabilityTest_current.log` |
| UIUXPreparationRouteTest | UIUX_PREPARATION_ROUTE_TEST: PASS (128 assertions) | `tmp/uiux_final_20260914/UIUXPreparationRouteTest_current.log` |
| UIUXRosterStateTest | UIUX_ROSTER_STATE_TEST: PASS (695 assertions, 45 captures) | `tmp/uiux_final_20260914/UIUXRosterStateTest_repaired.log` |
| UIUXEconomyFlowTest | UIUX_ECONOMY_FLOW_TEST: PASS (109 checks) | `tmp/uiux_final_20260914/UIUXEconomyFlowTest_current.log` |
| UIUXResourceResultTest | UIUX_RESOURCE_RESULT_TEST: PASS (65 checks) | `tmp/uiux_final_20260914/UIUXResourceResultTest_current.log` |
| UIUXRaidChoiceTest | UIUX_RAID_CHOICE_TEST: PASS (320 checks) | `tmp/uiux_final_20260914/UIUXRaidChoiceTest_current.log` |
| UIRegressionVisualReview | UI_REGRESSION_VISUAL_REVIEW: C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2/tmp/ui_regression_review | `tmp/uiux_final_20260914/UIRegressionVisualReview_current.log` |
| UIUXActorArtTest | UIUX_ACTOR_ART_TEST: PASS (590 assertions) | `tmp/uiux_final_20260914/UIUXActorArtTest_final.log` |
| UIUXPortraitArtTest | UIUX_PORTRAIT_ART_TEST: PASS (2314 assertions, 138 captures, after) | `tmp/uiux_final_20260914/UIUXPortraitArtTest_repaired.log` |
| UIUXEmotionPortraitTest | UIUX_EMOTION_PORTRAIT_TEST: PASS (206 assertions) | `tmp/uiux_final_20260914/UIUXEmotionPortraitTest_final.log` |
| UIUXContractArtTest | UIUX_CONTRACT_ART_TEST: PASS (1769 assertions, 120 flow captures) | `tmp/uiux_final_20260914/UIUXContractArtTest_final.log` |
| UIUXCompletionArtTest | UIUX_COMPLETION_ART_TEST: PASS (15583 assertions, 582 captures) | `tmp/uiux_final_20260914/UIUXCompletionArtTest_repaired.log` |
| UIUXCompletionScreensTest | UIUX_COMPLETION_SCREENS_TEST: PASS (588 assertions, 114 captures) | `tmp/uiux_final_20260914/UIUXCompletionScreensTest_final.log` |
| UIUXGrowthEvidenceTest | UIUX_GROWTH_EVIDENCE_TEST: PASS (601 checks) | `tmp/uiux_final_20260914/UIUXGrowthEvidenceTest_final.log` |
| UIUXStageFacilityArtTest | UIUX_STAGE_FACILITY_ART_TEST: PASS (1887 checks; 66 placements) | `tmp/uiux_final_20260914/UIUXStageFacilityArtTest_final.log` |
| UIUXLandmarkTest | UIUX_LANDMARK_TEST: PASS (2014 checks) | `tmp/uiux_final_20260914/UIUXLandmarkTest_repaired.log` |
| UIUXBarracksArtTest | UIUX_BARRACKS_ART_TEST: PASS (214 checks) | `tmp/uiux_final_20260914/UIUXBarracksArtTest_final.log` |
| UIUXWardDirectionalTest | UIUX_WARD_DIRECTIONAL_TEST: PASS (612 checks) | `tmp/uiux_final_20260914/UIUXWardDirectionalTest_final.log` |
| UIUXFacilityArtTest | UIUX_FACILITY_ART_TEST: PASS (1365 checks) | `tmp/uiux_final_20260914/UIUXFacilityArtTest_final.log` |
| UIUXMapNavigationTest | UIUX_MAP_NAVIGATION_TEST: PASS (1062 checks; 24 scenarios) | `tmp/uiux_final_20260914/UIUXMapNavigationTest_final.log` |
| UIUXMapLabelsTest | UIUX_MAP_LABELS_TEST: PASS (5927 assertions, 66 captures) | `tmp/uiux_final_20260914/UIUXMapLabelsTest_final.log` |
| UIUXMasonryTest | UIUX_PREPARED_MAZE_TEST: PASS (31170 assertions, 100 captures) | `tmp/uiux_final_20260914/UIUXMasonryTest_final.log` |

### 실제 연속 캠페인과 밸런스

- 실제 새 게임→DAY30 엔딩 **COMPLETE**, 739.7초 자동 실행. 29개 실제 전투와 DAY29 관리/선언, 30개 결산 기록. 날짜 이동·자원 지급·강제 승리 없음. 초기 안내만 별도 검사에 맡기고 비활성화, 대사는 빠르게 넘기며 능동 스킬을 자동 사용. 사람 완주·초보자 승률/독해 시험이 아니다.
- 금화·마력·식량·악명은 실제 경로로 유지. DAY12 푸딩120금화/60마력/20악명, DAY23 고블린120/50/20, DAY29 임프100/100/20 승급 비용 지출.
- 같은 성장·원정 선택에서 능동 스킬을 끈 비교: **COMPLETE / DAY 30**. `tmp/uiux_final_20260914/no_active_skills/campaign_run.json`. 두 조건 모두 엔딩에 도달했고 DAY30 스킬사용63.7초/아군1129HP, 미사용63.9초/1142HP였다. 이 성장 경로에서 능동 스킬이 필수는 아니며 기존 기본 난이도는 관대한 편으로 관찰했다. 비용·보상·적 수치를 임의로 올리지 않았다. 사람 체감 난이도·승률 모집단으로 일반화하지 않는다.
- 초반5프로필×3시작값은 15전 모두 완료. 최소 행동에도 특화/집중 성장 선택은 포함되므로 ‘아무것도 안 해도 승리’라고 표현하지 않는다.
- 같은 전력/상태에서 시설 위치를 실제 전선에 놓은 비교: 중립36.8초·잔여HP415/451, 감시35.1초·425/451·추가피해68, 병영35.2초·423/451·추가피해66, 회복35.8초·451/451·회복34. fixture 비교이며 일반 승률이나 최적 빌드 주장이 아니다.
- 준비된 미궁의 긴 이동 구간에 맞춰 **검사 시간 예산만** DAY1 20~40초, DAY2함정25~55초, DAY3보조20~60초로 분리. 기존 일반 지도9~14/31~41/40~50초는 보존. 아군 쓰러짐/스킬 사용 하한과 실제 게임 비용/스탯은 변경하지 않았다. 초반 학습 전투의 약1분 이내 예산이며 사람 체감 적정성의 증명은 아니다.

| DAY | 실제 전투 시간 | 왕좌 잔여HP | 아군 잔여/최대HP |
|---|---:|---:|---:|
| 1 | 26.2초 | 1500 | 398/440 |
| 2 | 38.2초 | 1500 | 435/491 |
| 3 | 38.8초 | 1500 | 384/530 |
| 10 | 42.8초 | 1500 | 616/737 |
| 20 | 63.4초 | 2100 | 992/1020 |
| 30 | 63.7초 | 2500 | 1129/1198 |

### Windows 패키지

- 공식 Godot4.6.3 Windows release 템플릿 SHA256 `3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8` 확인. [공식 릴리스](https://github.com/godotengine/godot-builds/releases/tag/4.6.3-stable).
- 실제 Windows Desktop release export 성공. `tmp/uiux_final_20260914/windows/MawangCastle_UIUX_Local.exe` + 동일 폴더PCK. 버전은1.2.6, 로컬 검증용이며 공개 출시 아님.
- 동일 실행 파일에서 Godot 자체 MovieWriter로 타이틀1920×1080 렌더 확인. `windows_capture/title00000029.png`. package 소스SHA는f58639e이며61f05ac은 검사 파일만 달라 제품 내용은 동일하다. 처음1280×720 창 옵션을 주었지만 녹화 내부 해상도는1920×1080이므로720p 캡처라고 표시하지 않는다.
- Computer Use 앱 접근 승인 시간초과로 export 창 직접 클릭/키보드 검사는 미완료. 외부 ExportInputAudit script 시도도 exit0만 있고 입력·캡처 증거가 없어 NOT_EXECUTED/EVIDENCE_MISSING으로 제외했다. source 게임의 네이티브 입력 검사와 구분. 이를 우회하는 OS 입력 도구는 사용하지 않았다.
- [증거 페이지](../../tmp/uiux_final_20260914/index.html): 튜토리얼 같은 장면 전후, 건물 카드/드래그/확정/취소/Undo, 앞벽 가림, 실제 결산/원정 화면. `evidence_manifest.json`에 원본 경로·해시 기록.

### 정책 필드

- Review task ID: 01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3
- Reviewed SHA: 7fd2401e01fdb7fc9872c2c777ab3ea93939c7e4
- Review range: 69a75970b1f8c030aa3a6956e5ca0f5bf15b2112..7fd2401e01fdb7fc9872c2c777ab3ea93939c7e4
- Remaining P1/P2: 0
- Final review result: PASS

판정 방식: 전체 실행160 PASS와 마지막 tutorial_flow 수정 후177항목 PASS를 결합한 최종 검증. `tmp/uiux_final_20260914/validation_closure.json`에 원본 검사·후속 SHA·로그 해시를 연결했다. 방향별 미술은 사용자 승인 후속이며 공개 출시·사람 사용성·미실행 환경은 이 PASS에 포함하지 않는다.

검수 에이전트 없음(사용자 금지). 이 문서 이후 기능·데이터·자산·도구 변경이 있으면 해당 소스의 검사 결과를 다시 연결해야 한다.

## 7. 후속 범위·해석 제한

1. 방향별 캐릭터 미술은 사용자 요청으로 후속 확정. 현재 그림 유지가 이번 완료 기준이며 미제작 사실을 그대로 남긴다.
2. export 직접 입력, 실제 사람의 재미/스토리 독해/청취 피로, Web·모바일 실기기·저사양 장시간은 미검증. 수행한 것으로 기록하지 않는다.
3. 현 자동 운용은 초보자보다 빠른 대사 진행과 계획된 성장·스킬을 사용한다. 전체 캠페인 완료와 시설 효과 차이는 확인했지만 최종 체감 난이도를 단정하지 않는다.
4. 임의의 새 그래픽 서비스·과금·공개 배포·태그·main 병합 없음.

## 8. 다음 작업

1. 이번 합의 범위의 수정을 마감한다. 방향별 미술은 별도 후속 요청 때 현재 그림을 기준으로 진행한다.
2. 필요 시 Computer Use 앱 접근을 허용받아 현재 export에서 새 게임·설정·입력 확인. 엔진 렌더 확인과 혼동하지 않는다.
3. 공개 출시/태그/배포는 별도 사용자 결정. 사람 플레이의 재미·난이도·스토리 독해 판단과 배포 대상 환경 확인을 출시 판단에서 구분한다.

## 9. 작업 트리

- 구현 커밋은 로컬만 유지. tmp 캡처/빌드/다운로드/임시 driver는 소스에 커밋하지 않는다.
- 원래 main·출시 태그·v20실험 브랜치 변경 없음. 별도 에이전트 없음.
- 최종 검증 SHA 이후 변경은 이 핸드오프와 CURRENT 문서만이다. 소스 작업 트리를 정리하고 로컬 커밋으로 마무리한다.

## 10. 종료 상태

- [x] 관련 실제 결함 수정 및 직접 재검증
- [x] 최종 전체 종료 확인 및 실패 원인 수정·직접 재검증
- [x] 연속 DAY1~30 자동 캠페인 기록
- [x] Windows release export·실제 타이틀 렌더
- [x] 현재 그림 유지·방향별 미술 후속 사용자 확정
- [x] 합의 범위 최종 검증 결과 확정 (공개 출시 승인과 구분)
- [x] CURRENT 최종 결과 갱신 (문서 로컬 커밋으로 종료)

출처 문서 형식 정정의 검증은 `tmp/uiux_final_20260914/repository_policy_final.log`에 별도로 기록한다. 최종 게임 검증 뒤에는 런타임 변경이 없다.
