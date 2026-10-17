# 수정 후 시작 순서

사용자 10/17 19:39 지시. 기준 `8d8d42f4`, 브랜치 `codex/v130r-defense-layout`. 최신 커밋과 검사 수는 인계 문서에 기록한다. 원격·main 권위 갱신이나 공개 배포가 아니다.

| 순서 | stage / 화면 | 소유자 | 대사·행동과 다음 조건 |
|---|---|---|---|
| 1 | LV00_TITLE_BOOT / title | TitleWorkspaceUI | 기존 그림·로고 위 시작 버튼과 한국어/English/简体中文만. 첫 설정은 OS 언어. 변경 즉시 반영·저장. |
| 2 | LV00_START_MENU / title | StartFlow + TitleWorkspaceUI | 새로 하기, 이어서 하기, 설정, 비활성 도전과제 자리, 나가기. 저장 없으면 이어서 비활성. 있으면 DAY·등급·시간. 옛 저장에 없는 시간은 미기록으로 표시. |
| 3 | 덮어쓰기 확인 | 기존 저장 처리 + StartFlow | 기존 저장이 있으면 새로 하기 확인. 취소는 파일 보존. |
| 4 | LV00_PROLOGUE / prologue | StartFlow | 검은 화면의 7문장, 클릭·스페이스·계속 버튼. 건너뛰면 바티 질문으로. 세 언어 내용 동일. 기존 동굴 물방울 환경음 재사용. |
| 5 | LV01_NAME_ENTRY / name_entry | StartFlow | 바티 질문 2턴. 이름 치환 토큰을 사용하지 않음. |
| 6 | LV01_NAME_ENTRY / name_entry | NameEntryUI | 이름 1~12자·금지 문자 안내, 기본 이름 제안, 입력 검증 후 확정. |
| 7 | LV02_NAME_CONFIRMED / dialogue | 기존 대사 표시기 | 바티 확인 1턴에 실제 이름 사용. 구 D_OP 오프닝은 새 게임 경로에서 호출하지 않음. |
| 8 | LV03_DAY01_MANAGEMENT_TUTORIAL / dialogue | 본편 StoryDirector | STORY_D01_MANAGEMENT_ENTRY 8행. 프롤로그와 겹치던 동굴 소개·마왕성 선언 2행은 회의 진입 문장으로 정리. |
| 9 | 같은 stage / dialogue | 0111 V130RStoryRuntime | 본편 전부 종료 뒤 실제 보유 화자 조건을 만족한 DAY1 오버레이만 재생. 기본 3인에서는 두 블록 모두 미해당. 별도 보유 조건 시험에서 S1·S2가 본편 뒤에 한 번씩 재생됨을 검증. |
| 10 | 같은 stage / management | StartFlow 안내 1 | 옥좌·입구·금고 실제 위치 표식. 확인 후 진행. |
| 11 | 같은 stage / management | 안내 2 | 건설 바에서 건물 하나 설치. 이미 가변 건물이 있으면 생략. 기본 F 지도는 이미 병영 등이 있어 정상 생략. `day1_guide_2.png`는 건물 없는 테스트 배치에서 실제 건설 분기를 촬영한 것. |
| 12 | 같은 stage / management | 안내 3 + 기존 배치 UI | 몬스터 배치 탭에서 푸딩·곱·핀을 빛나는 수비 칸에 배치. 세 명이 모두 놓여야 진행. |
| 13 | 같은 stage / management | 안내 4 | 전투 탭 선택. 준비 안내 미완료 상태에서는 시작 차단. |
| 14 | 같은 stage / dialogue | 본편 → 0111 | STORY_D01_PRECOMBAT 전부 재생 → 해당하는 신규 몬스터 첫 출전 대사 → 실제 전투. 각 읽음 ID로 중복 억제. |
| 15 | LV04_DAY01_BATTLE_EXPLORER / combat | ApprovedBattleController + StartFlow | 실제 전투를 잠시 멈추고 명령 바 한 번 안내. 확인/스페이스 후 재개. 설정의 기본 속도를 반영. |
| 16 | LV05_DAY01_RESULT / dialogue → result | 본편 | 실제 승리 → STORY_D01_RESULT_WIN → 결과. 패배 시 기존 RESULT_LOSS 경로 유지. 0111 승리 반응은 입력을 가로채지 않고 표시 후 사라짐. |

안내 단계·명령 안내 읽음·새 지도 배치·플레이 시간은 기존 저장의 onboarding.start_flow에 추가한다. 완료한 안내는 복원 후 재출력하지 않는다. 설정의 안내 다시 보기는 적용하면 관리 화면에서 재개하고 취소하면 원상 복원한다. 타이틀 설정에서 요청한 재보기는 이어서 하기까지 유지한다. 게임 안 오른쪽 위 메뉴로도 설정에 접근하며, 전투 중 설정을 열고 돌아오면 같은 전투를 유지한다.

구 저장은 프롤로그·이름 입력을 새로 거치지 않는다. 실제 옛 복사본의 저장 스키마 v1/v5를 v6으로 이관해 DAY·이름·지갑을 복원하고 원본 해시를 비교했다. 새 1.3.0 v6 저장의 안내 진행·배치도 이어서 하기로 확인했다. 옛 저장의 자유 배치 스냅샷이 없으면 저장된 DAY 등급에 맞는 안전한 지도를 만든다. 모든 과거 버전·모든 DAY 세이브를 전수 확인한 것은 아니다.

새 지도에서는 구 TutorialManager 안내를 표시하지 않는다. `onboarding_flow_dialogue_v0.4.json`의 구 데이터는 과거 저장 스키마·기록 호환을 위해 남기고, 활성 시작 순서와 소유자를 명시했다. 런타임에서 방 지침·곱 선택 구 안내가 겹쳐 나오지 않는 것을 확인했다.

## 검수 근거와 범위

- `before_trace.json` / `after_trace.json`: 수정 전·후 실제 대사·stage 순서. 뒤쪽에는 보유 화자를 주입한 오버레이 조건 시험이 별도로 이어진다.
- `direct_checks.json` / `capture_checks.json` / `artifact_checks.json`: 검사 수·실패 목록. 실제 자연 첫 전투 결과는 `tmp/v130r_step14/{direct,capture}.log`의 NATURAL_FIRST_BATTLE에 기록.
- 필수 PNG 11장은 모두 실제 Godot 렌더의 개별 1280×720 축소 캡처. `menu.png`의 01:02는 시간 표시 시험값이며 실제 플레이 시간을 주장하지 않는다.
- 추가 캡처: title_zh, day1_guide_en, day1_guide_zh, day1_commands, day1_battle_end. 영상 없음. 전체 캠페인·전체 회귀·성능·export·별도 검수 에이전트 미요청/미실행.
- Main 실제 실행에서 키보드 이어하기·스페이스 대사 진행·새 지도 첫 안내·격리 세이브 저장 후 정상 종료를 확인. 사용자 원본 세이브는 접근·수정하지 않음. Godot 동시 최대 1개.
- 신규 그림 생성 0, 기존 GPT 타이틀/로고/obsidian 프레임·초상·아이콘 재사용. 한글 NEXON Maplestory, 중국어는 기존 CJK 대체 글꼴.

**사용자 확인 대기:** 프롤로그 문장 호흡, 바티 말투, 안내 위치와 길이. 도전과제 실제 연결은 0113b 담당이다.
