# v1.2.2 UI 이식 대응표

| U5 화면·컴포넌트 | U5 source | 필요 view state | 1.2.1 공급자·기존 기능 | 처리 | 보존/숨김 | PC·모바일 계약 | 실제 검증 |
|---|---|---|---|---|---|---|---|
| 타이틀 | `5ed1d5f:V20TitleEntryPanel` | 저장 검사, 새 게임/이어하기 | 기존 `GameRoot` 타이틀·`CampaignSaveStore` | `DO_NOT_PORT` | 기존 이름 입력·이어하기 보존; v20 테스트·SHA badge 숨김 | 기존 반응형·회전 안내 | title action test |
| 침입 브리핑 | `V20InformationHUD._build_intrusion_brief` | DAY, 적 편대·목표·route·새 패턴 | `campaign_days`, `waves`, encounter adapter | `ADAPT_TO_121` | 기존 스토리 대사·배치 시작 보존 | 1280×720~1920×1080, 844×390 | briefing UI test |
| 중앙 배치 보드 | `V20PlacementBoard`, drag buttons | battle plan·room/slot·roster·시설 | ModuleGraph, 기존 건설·monster roster | `ADAPT_TO_121` | 실제 제품 ID와 전체 보유 몬스터 | mouse click/drag, touch click→click | management placement test |
| 관리 상단·주 행동 | `V20InformationHUD._build_management` | DAY·재화·배치 유효성 | 기존 관리 controller | `ADAPT_TO_121` | 성장·진화·성 확장·심장·합동기 보존 | 해상도별 안전 영역 | management action test |
| context drawer | `set_context_drawer/_build_context_drawer` | 선택 room/facility/monster 문맥 | 기존 관리 패널 | `PORT_RULE` | 원정·연대기·의회·전초·상층은 안전 화면 연결 | 빈 drawer 금지 | all management actions |
| 전투 HUD | `V20InformationHUD._build_combat` | 목표 HP·활성 구간·threat·속도 | `HUDController`, combat controller | `ADAPT_TO_121` | 기존 보스·심장·합동기·pause/x1~x3 | 1280×720, 1366×768, 1920×1080, 844×390 | combat HUD test |
| 명령 targeting | `set_command_state/set_targeting_state` | 비용·cooldown·대상·feedback | `V122CommandService`, 실제 object target | `PORT_RULE` | 네 명령, 실제 건물·unit 강조 | mouse/keyboard/touch | command UI test |
| 위협 예고·구간 | `_threat_active/_build_threat_panel/_build_defense_stage_strip` | 실제 encounter telegraph | encounter adapter·battle plan | `PORT_RULE` | 위협이 있을 때만 표시 | HUD 겹침 0 | telegraph test |
| 결과 원인 | `V20ResultScreen._primary_cause/_metrics` | ledger·승패·피해·손실 | 기존 `build_result_ui`, 성장·보상 | `ADAPT_TO_121` | 성장·특화·스토리·엔딩·다음 DAY 보존 | PC·모바일 스크롤/포커스 | result UI test |
| U5 theme | `V20UITheme` | 색·간격·font role | `UIFont`, 기존 UI setting | `PORT_RULE` | 디버그 badge 제외 | 사용자 UI 배율 보존 | visual contract |
| v20 별도 scene | `scenes/v20/*` | v20 test state | 정식 GameRoot scene | `REMOVE_TEST_ONLY` | 정식 진입점 없음 | 해당 없음 | static closure |

## action 폐쇄 조건

기존 기능 진입 불가, dead button, 빈 drawer, 개발자 문구, handler 없는 action을 각각 0으로 만든다. UI는 제품 view model만 읽고 전투 수치나 저장 schema를 직접 소유하지 않는다.

## P6 관리·배치 UI 결합 결과

- `V122ManagementViewModel`이 현재 제품 runtime에서 중앙 성 지도, 선택 room inspector, 주 행동과 상황별 context action을 구성한다.
- 건설·몬스터·전투 시작·연대기는 항상 유지하고 합동기·원정·전초기지·상층은 실제 제품 해금 상태에서만 노출한다.
- 기존 `ManagementSceneController`의 연대기와 합동기 버튼이 같은 view model의 label·callback·tooltip을 소비하므로 UI 계약이 테스트 전용으로 분리되지 않는다.
- 1920×1080, 1366×768, 1280×720, 844×390에서 지도·room 목록·context drawer·주 행동이 화면 안에서 겹치지 않는다.
- 390×844 세로 화면은 조작면 대신 회전 안내 계약을 사용한다.
- 제품 callback이 없는 visible action, 중복 action ID, 빈 drawer와 개발자 문구는 0이다.
