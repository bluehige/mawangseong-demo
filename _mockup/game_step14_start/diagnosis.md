# 수정 전 시작 흐름 진단

기준: `codex/v130r-defense-layout` / `8d8d42f48e8beee6924d804afebe5b219b74314d`. 제품 수정 전에 Godot 4.6.3으로 실행하고 1280×720 축소 캡처를 저장했다. 사용자 APPDATA와 격리하고 캠페인 저장을 비활성화했다. `--fresh-grade-f`로 기존 테스트 배치도 불러오지 않았다. 로컬 main 참조 없음, 원격 조회 없음.

| 순서 | 실제 화면·stage | 소유자 | 관찰 |
|---|---|---|---|
| 1 | title / LV00_TITLE_BOOT | TitleWorkspaceUI | 새 게임·이어서·설정·도감·종료가 첫 화면에 함께 나옴. 별도 시작 메뉴·프롤로그 없음. |
| 2 | name_entry / LV01_NAME_ENTRY | NameEntryUI | 바티 대화 없이 입력 화면. 길이 안내는 한국어 고정, 금지 문자 검증 없음. |
| 3 | dialogue / LV02_OPENING_CUTSCENE | onboarding_flow_dialogue_v0.4 | D_OP 4행. 마왕성 선언, 축축한 원룸, 왕좌의 방 HP, 침입자가 벌써 입구에 있다는 설명. |
| 4 | dialogue / LV03_DAY01_MANAGEMENT_TUTORIAL | day_01 STORY_D01_MANAGEMENT_ENTRY | 본편 8행이 다시 동굴 소개와 마왕성 선언으로 시작. 긴급 경고 뒤 누수 회의로 되돌아감. |
| 5 | management / LV03… | 구 TutorialManager + ApprovedMap | TUT_030이 건설 팔레트에서 곱 선택/전열·후열 강화를 요구. 실제 바닥 건설바에는 곱 카드 없음. 주요 시설·건설·세 몬스터 배치 순차 안내 없음. |
| 6 | 전투 클릭 / LV04_DAY01_BATTLE_EXPLORER | ApprovedPlacementView.start_battle | 실제 추천 배치를 넣은 뒤 시작. 본편 STORY_D01_PRECOMBAT 8행을 거치지 않음. 구 안내 진행 조건도 시작을 막지 않음. |
| 7 | 첫 전투 종료 / STORY_D01_RESULT_LOSS | ApprovedBattleController → 본편 | 자연 실행은 패배 대사로 이동. TUT_030은 여전히 남아 있음. 승리 대사는 본편 result_win 경로에 별도 존재. |

## 꼬임 목록

- **재현:** D_OP_PLAYER_001과 STORY_D01_MANAGEMENT_ENTRY_002의 마왕성 선언 중복. 세계관 소개도 서로 다른 층에서 반복한다.
- **재현:** 이미 입구에 침입자가 있다는 경고 뒤 배달 기사·누수 회의로 돌아가는 순서 역전.
- **재현:** 건설바에서 곱을 고르라는 강조. 곱은 몬스터 배치 탭에 있어 강조 대상과 실제 행동이 다르다.
- **재현:** 방(room) HP·방 지침·전열/후열 설명과 자유 배치 지도가 혼재한다. 주요 시설·건설·세 몬스터 배치·전투 명령 안내가 빠졌다.
- **재현:** 새 지도 전투 버튼이 본편 precombat_confirmed를 호출하지 않아 전투 직전 대사가 누락된다.
- **코드 확인:** PlayerContinuityUI는 대사 기록·일시정지·업데이트·입력 차단 담당이다. 새 지도 마우스 입력은 구 월드 선택 경로를 차단하므로 기존 튜토리얼 조건이 맞지 않는다.
- **코드 확인:** 0111 management()는 본편 anchor를 먼저 재생하고 day_overlays를 삽입한다. check_recruits 지연 호출과 구 관리 진입 호출이 각각 순서를 소유한다. 이번 DAY1 실제 trace에서 오버레이가 안 나온 것은 조건 미충족이다. DAY1 두 블록은 spider_tailor/bat_courier 소유가 필요하므로 기본 세 몬스터에서는 정상 생략된다. 이를 중복 재현이라고 부풀리지 않았다. 조건을 충족한 경우의 순서 연결은 별도로 필요하다.
- **미재현:** 이름 입력 전 `{{player_name}}` 원문 노출. 기존 치환은 기본 이름을 사용한다. 새 프롤로그와 이름 질문에는 토큰을 쓰지 않고 확정 뒤에만 이름을 사용하는 검사가 필요하다.
- **추가 확인:** 기본 Main은 구 관리 화면이고 새 지도는 preview가 debug flag를 켜는 구조였다. 시작부터 새 지도를 쓰려면 Main 진입도 연결해야 한다. 기존 preview는 대사·캠페인 저장을 꺼 두므로 시작 흐름 검수의 대체물이 될 수 없다.

근거: `before_trace.json`, `before_title.png`, `before_name.png`, `before_dialogue_3.png`, `before_management.png`, `before_battle_end.png`. 수정 전 자연 승리는 확인하지 않았으며 패배를 승리로 기록하지 않는다.
