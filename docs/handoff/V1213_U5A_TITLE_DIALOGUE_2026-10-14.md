# U5-A 타이틀·대화 완료 인계

## 1. 메타데이터

- 작성일: 2026-10-14
- 목표 버전: v1213_uiux 작업 이름; 제품 1.2.12 유지, 새 출시 번호 발급 없음
- 작업 브랜치: codex/v1213-fix-plan (변경하지 않음)
- 기준 브랜치 및 SHA: 같은 브랜치의 미검증 WIP cd9cd8fec60d1b0b5c20e2823bf4c8df11ef758b
- 마지막 커밋 SHA: 58124ebce2cc5afdc203bfe4c0e2817b67e748aa (제품·검증 기준; 이후 인계 문서만 변경)
- 구현 커밋: 3cf3b2b1a9937155429dc56d4b32d2080bdef4f3
- 원격 푸시 여부: 없음
- 관련 PR 또는 태그: 생성하지 않음
- 권위 확인: 로컬 main 참조 없음. origin/main 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b의 AGENTS/CURRENT를 읽었고 git ls-remote의 main SHA와 일치 확인. 로컬 main과의 tuple은 미확정이며 이 브랜치 CURRENT를 공개 제품 상태로 간주하지 않는다.

## 2. 이번 세션 목표

- 0022/0023의 큰 이미지 요청 실패 뒤 cd9cd8f WIP를 이어, 사용자가 지정한 타이틀·대화 마감 9항목과 직접 검증을 완성한다.
- 기준: UIUX_OVERHAUL_PLAN §4, UIUX_IA_FLOW, U4_UI_KIT, u3/01_title.png·02_dialogue.png 및 사용자 대화 기준 그림.
- 범위 제외: project.godot, 다른 브랜치/작업트리, docs/design/v20_map_builder/, 게임 규칙·밸런스·새 스토리, 새 이미지 생성, 전체 캠페인·전체 회귀·검수 에이전트·export·배포.

## 3. 완료한 작업

- 타이틀: 군집 배경 입력 무반응, 중앙 메뉴 폭520·기본 글자36·아이콘56 논리 px, 기존 콜백/이어하기 조건과 초점 유지. 지구본+세 언어 한 묶음에서 즉시 적용·settings.cfg 저장. 업데이트 내역은56px 아이콘/툴팁으로 축소하고 버전은18px·명도 완화.
- 대화 3계통: StoryDialoguePresenter 공유. 본문40px(하한32), 이름28px(하한26), 좌우 자리 유지, 화자1.0/청자0.5. 바티의 상단0.26~하단0.77 영역을 사용해 가슴 높이 마스코트 크기로 축소, 상단 도구와 겹침0. 전투는 별도 입상 위치와 기존 전투 배경/일시정지 소유권 유지.
- 장식/조작: 전체 폭에 가까운24px 안전 여백의 반투명 띠, 상단 중앙·양쪽 보석. 로그/자동/넘기기/메뉴에 큰 아이콘과 짧은 라벨, 자동 활성 보라 강조, 미독 넘기기 자물쇠.
- 긴 네 묶음: 기본 수동, 선택형 자동, 마지막 줄 정지, 로그/메뉴/설정 중 일시정지, 수동 입력 시 해제, 미독 스킵 제한·중복 완료 방지 검증. 실제 오프닝4줄+관리8줄, 전투 직전/승리 후 및 온보딩 대체 계통도 검증.
- WIP 연결 검증: 바티 입상4+compact초상4, 감정 별칭·모든 런타임 사용처의 구 바티 참조0. 왕좌 기본 배경과 씬 지정 배경 우선순위, 도달한 엔딩에만 배경 ID 훅 적용.
- 종료 수정: GameRoot와 키트 버튼의 compile-time preload를 함께 사용하면 script/RID 잔존 진단을 재현했다. U5-A의 버튼 스크립트만 인스턴스 생성 시 load하도록 바꿔 S1/S2/실제 GUI의 종료 진단을 없앴다. 공통 키트 코드 변경 없음. 숨겨지거나 제거된 타이틀의 지연 초점도 검사하고, Quit 입력 검사에는 종료 뒤 남는 coroutine을 만들지 않는다.
- 참고: [Godot 유사 반환형/로드 문제 보고](https://github.com/godotengine/godot/issues/122022)는 진단 단서이며, 동일 엔진 결함이라는 확정은 하지 않는다. 채택 근거는 이 저장소의 이전 화면 대조·실행 시점 로드 대조·최종 검사 결과다.
- 스토리/데이터/밸런스: 기존 WIP의 표현 자산 연결을 검증했으며 이번 마감에서 내용·전투 수치·저장 스키마 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| scripts/ui/TitleWorkspaceUI.gd | 메뉴/언어/업데이트 크기와 로드·초점 수정 | 완료 |
| scripts/story/StoryDialoguePresenter.gd | 본문/화자/바티·도구 라벨·자동/잠금 상태 | 완료 |
| scripts/story/DialogueStrip.gd | 대화 전용 모서리 보석; 공통 패널 보존 | 생성 |
| tools/tests/V1213U5ATest.gd | 3계통 표시·실제 입력·업데이트 콜백·종료 검사 | 완료 |
| tools/ui_kit/RunU5A.ps1 | 선택형 상세 진단; 단일 Godot/종료 확인 유지 | 완료 |
| tools/ui_kit/ScanU5A.py | 글자 하한/교차 부모 입상·도구 겹침/축소 JPG | 완료 |
| docs/plans/V1213_FIX_CHECKLIST_2026-10-14.md | S2-07~13와 U5-A 기록의 깨진 한글 수정·결과 반영 | 완료 |
| docs/design/v1213_uiux/U5A_PORTRAIT_FALLBACKS.md | 별도 입상 미보유29개 ID·이름·실제 자산 목록 | 생성 |
| docs/handoff/V1213_U5A_TITLE_DIALOGUE_2026-10-14.md, CURRENT.md | 이번 완료·제한·다음 작업 | 완료 |

cd9cd8f에 이미 포함된 GameRoot 대화 연결, StoryDirector/CombatStoryFeed, characters.json, data/ui/, UI/바티 런타임과 title 원본47경로는 새로 생성했다고 보고하지 않는다. 기존 WIP 위에서 검증·마감했다.

## 5. 그래픽 및 오디오 자산

- 이번 신규 생성: 없음. 기존 승인 GPT 내부 생성 원본과 WIP 런타임을 사용한다.
- 생성 모델/출처: GPT internal image generation. assets/source/imagegen/v1213_title_monster_court/SOURCE.md, v1213_bati_cute/SOURCE.md, v1213_u5_reuse/SOURCE.md.
- 원본: assets/source/imagegen/v1213_title_monster_court/ 및 v1213_bati_cute/.
- 런타임: assets/ui/v1213/ 및 assets/sprites/portraits/v1213_bati_cute/.
- 바티8PNG의 실제 알파 extrema (0,255), compact512×512/standing1080×1080 확인. 이번 배경 제거·원본 재생성·크롭·리샘플링 없음.
- 그림 확인: tmp/v1213_u5a/view/의 가로1280 이하 JPG만 12장 열었다. 한 호출 최대2장. 큰 PNG 직접 열기/대화 첨부0. 비교 제작은 원본1920×1080을 사용했다.
- 비교 원본: tmp/v1213_u5a/compare_title.png, compare_dialogue.png (3840×1080, 시안 왼쪽/실제 오른쪽).
- 확인용: tmp/v1213_u5a/view/compare_title.jpg, compare_dialogue.jpg. 실제1920 한국어, 1280 간체 대화, 2560 영어 타이틀, 터치 타이틀/대화도 축소본으로 확인.

## 6. 테스트 및 검수

모든 실행은 격리 APPDATA, 확인된 Godot4.6.3 경로, 동시1프로세스 및 종료 확인으로 수행했다. 아래 최종 실행에 script/RID/resource 종료 오류 없음. S1 후속의 기존 can_process7건만 이전 인계와 동일하게 구분한다.

| 명령/방법 | 결과 | 근거 |
|---|---|---|
| RunU5A.ps1 -Mode contract | 281검사/실패0; 실제 Quit 입력으로 exit0 | tmp/v1213_u5a/contract_result.json, contract/run.log |
| RunU5A.ps1 -Mode s1 | 41검사 PASS | tmp/v1213_u5a/s1/ |
| RunU5A.ps1 -Mode s1fu | 131검사 PASS, 기존 can_process7건 | tmp/v1213_u5a/s1fu/ |
| RunU5A.ps1 -Mode s2 | 919검사 PASS | tmp/v1213_u5a/s2/ |
| RunU5A.ps1 -Mode kit | 75계약 PASS, 의도한 빈 툴팁 경고 검사 | tmp/v1213_u5a/kit/ |
| RunU5A.ps1 -Mode capture + ScanU5A.py | 3해상도×3언어×5상태=45캡처, 실패0·구 바티 참조0 | tmp/v1213_u5a/capture_result.json, scan_result.json |
| RunU5A.ps1 -Mode sweep_desktop / sweep_touch + tools/ux_audit/scan.py | 각각29화면/49·50캡처, 0줄·겹침·지역 넘침·마스크 오류 모두0 | tmp/v1213_u5a/sweep_desktop/scan.json, sweep_touch/scan.json |
| 새 게임→DAY1 관리 진입 | 마우스 누름/해제 InputEvent 실제 입력8클릭 | contract_result.json의 new_game_to_day1_management |
| UTF-8 문서/JSON·git diff --check·금지 경로 차이·프로세스 확인 | PASS | 체크리스트/입상 목록 한글 확인, project.godot/.import 차이0, Godot 종료 |
| 전체 캠페인·전체 회귀·별도 검수 에이전트·export | NOT_REQUESTED | 이번 U5-A 표적 범위만 수행 |

- 클릭8은 새 게임/랜덤 이름/확인/오프닝 자동/마지막 계속/관리 자동/마지막 계속/배치 진입이다. 자동 시간만 결정적으로 전진했고 pressed 신호를 직접 호출하지 않았다. 계약 결과의 baseline17은 IA 이전 참고값이며 이번 동일 경로 수동 재측정값은 아니다. 전체 첫DAY 루프28클릭 달성으로 확대하지 않는다.
- 해상도: 1920×1080, 2560×1080, 1280×720; 언어 ko/en/zh_CN. 2560은 기존 keep-aspect의 실제1920 콘텐츠+좌우320 검은 여백이다. 화면을 넓게 늘리는 개편은 하지 않았다.
- 1920 타이틀/대화 안정 표본 각각120프레임 약2초·60fps. 별도 성능 작업이나 장시간 성능 보증으로 해석하지 않는다.
- 수정 과정의 초기 실패/진단 로그는 tmp에 남아 있다. 최종 검사 로그와 위 결과로 대체하며 실패를 통과로 숨기지 않는다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 58124ebce2cc5afdc203bfe4c0e2817b67e748aa
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..58124ebce2cc5afdc203bfe4c0e2817b67e748aa
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- U5-A의 요청된 기능/표시 검증에서 남은 실패 없음. 픽셀 동일성이나 전체 출시 승인으로 기록하지 않는다.
- 별도 입상 미보유29개는 [캐릭터 목록](../design/v1213_uiux/U5A_PORTRAIT_FALLBACKS.md) 참조. 마왕/골딘/침입자 등의 기존 초상과 일부 전신 몬스터 그림을 재사용한다. 골딘은 onboarding/portrait_goldin.png; 없는 uiux3d/goldin_base.png 참조0.
- 엔딩별 훅은 준비됐지만 개별 신규 엔딩 배경 데이터/그림은 아직 없다. 도달하지 않은 엔딩 공개 없이 기본 배경으로 유지한다.
- 실제 터치 기기·Steam 배포·전체30일은 이번 검증 아님. 로컬 main 부재는 원격 일치 확인으로 숨기지 않았다.

## 8. 다음 작업 순서

1. 헤드가 U5-A의 두 비교 PNG와 이 인계를 사용해 통합한다. 추가 UI 변경 시 해당 계약/캡처만 재검증한다.
2. IA 순서의 다음 U5 관리 화면을 별도 writer 작업으로 진행한다. 기존 튜토리얼·배치/건설·게임 규칙 경계를 유지한다.
3. 별도 입상 제작 필요 여부 및 엔딩별 배경 후보는 후속 자산 작업에서 정한다. 이번 작업에서 추가 비용/생성/출시를 수행하지 않는다.

## 9. 작업 트리 상태

- 의도한 파일만 명시적으로 스테이징·영어 메시지 커밋. 기존 WIP 이력과 브랜치 보존.
- Reviewed SHA 이후 변경은 docs/handoff/ 두 문서뿐.
- 기존 미추적 docs/design/v20_map_builder/ 보존·읽기/수정/스테이징0.
- 새 tmp 캡처/로그/축소본/진단 스크립트는 로컬 증거이며 커밋하지 않는다.
- project.godot 및 .import 파일 변경0; 따라서 줄바꿈만 바뀐 .import를 커밋한 건 없음.
- push/PR/tag/Release/Steam 작업 없음. 개인 세이브 대신 격리 APPDATA 사용.
