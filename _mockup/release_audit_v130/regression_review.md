> 2026-10-18 B02/B03 수정 후 재판정: [원래 지적 1~5·콘텐츠 연결·출시 게이트별 결과와 직접 검증](../../docs/handoff/V130R_FIX_B02_B03_2026-10-18.md). 아래 본문은 0112 당시의 독립 감사 기록으로 보존합니다. 후속 표적 통과는 전체 출시 PASS가 아닙니다.

**담당 범위에서는 1.3.0 출시 보류를 권고합니다.** 새 Approved 경로에서 기존 회차·전선·의회 기능을 우회하는 코드가 확인됐습니다. 도전과제의 **조건 판정 100개 검사와 실제 플레이 획득 가능성은 별개**입니다.

기준은 `codex/v130r-defense-layout` / `a61404b8e38f659275f591eab0000f481325d81a`입니다. 감사 대상 코드·JSON·씬·설정에는 HEAD 대비 추적 변경이 없었습니다. 로컬 `main` 부재와 원격 조회 금지로 최신 main 권위는 확정하지 않았습니다. 파일 쓰기·Godot 실행·원격 조회·다른 worktree 및 archive 탐색은 수행하지 않았습니다.

**출시 차단 근거**

1. **P1 — 다음 회차가 이전 DAY 30 지도·자원·편성을 재사용할 수 있습니다.**
   엔딩의 다음 회차 처리는 게임을 초기화하고 `GameState.day=4`로 설정하지만 Approved 지도 세션을 초기화하지 않습니다. 의회를 선택하면 날짜만 다시 1로 바꿉니다. 지도는 남아 있는 세션을 우선 로드하며, 전투 시작 때 그 지도의 날짜·자원을 게임 상태에 덮어씁니다. 따라서 회차 시작 날짜와 실제 지도·전투 날짜가 어긋납니다.
   근거: [회차 전환 GameRoot.gd:10077](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:10077), [의회 시작 날짜:6046](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:6046), [세션 재사용:147](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/map_builder/ApprovedGradeProgression.gd:147), [날짜·자원 덮어쓰기:62](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/ApprovedBattleController.gd:62).
   **예상:** 수정·경계 검사 0.5~1일.

2. **P1 — 다음 날 이동과 전투 버튼이 기존 필수 준비·날짜 진입 절차를 우회합니다.**
   Approved 결과 진행은 날짜를 증가시키고 바로 관리 화면을 엽니다. 기존 `_enter_campaign_management_day()`의 전선 날짜 처리, 심장 유지비, 의회 확장 해금·수리 등을 호출하지 않습니다. 전투 버튼 역시 기존 `_request_combat_start()`의 준비 상태 검사를 거치지 않습니다. 원정 선택·의회 필수 행동·DAY 29 선언의 기존 요구사항이 실제 사용자 경로에서 빠집니다.
   근거: [Approved 날짜 진행:159](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/map_builder/ApprovedGradeProgression.gd:159), [기존 날짜 진입:9446](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:9446), [Approved 전투 버튼:784](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/map_builder/ApprovedPlacementView.gd:784), [기존 준비 검사:12175](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:12175).
   **예상:** 연결 복구·원정/전선/의회 경계 검사 1~2일.

3. **P1 — 원정·전선의 전투 변화와 기존 성장·칙령 능력치가 새 전투에 온전히 적용되지 않습니다.**
   Approved는 `DataRegistry.waves`를 직접 사용합니다. 기존의 의회 웨이브 선택 및 원정·전선·작전·회차 변형 적용 절차를 생략합니다. 아군도 기본 종족 능력치에 전문화만 적용해 생성하므로 기존 `_scaled_monster_stats()`의 레벨·전직·집중 준비·칙령 배율·왕관 능력치 처리를 우회합니다. 칙령 선택 화면이 존재하는 것만으로 효과 보존을 인정할 수 없습니다.
   근거: [기본 웨이브 직접 사용:85](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/ApprovedBattleController.gd:85), [기존 웨이브·변형 적용:645](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/CombatSceneController.gd:645), [기본 아군 생성:101](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/ApprovedBattleController.gd:101), [누락되는 성장·칙령·왕관 계산:12828](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:12828).
   **예상:** 적용 계층 연결·대표 비교 검사 1~2일.

4. **P2 — 기록실·엔딩 아카이브의 일반 진입 동선이 사라졌습니다.**
   Approved 관리 화면으로 조기 반환하므로 기존 기록실 버튼을 만들지 않습니다. 새 지도와 일시정지 메뉴에도 대응 진입이 없습니다. **몬스터별 유대 기억은 별도 버튼으로 연결되어 있습니다.**
   근거: [기존 관리 UI 대체:130](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/ui/ManagementWorkspaceUI.gd:130), [생략되는 기록실 버튼:199](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/ui/ManagementWorkspaceUI.gd:199), [현재 메뉴 행동:198](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/ui/PlayerContinuityUI.gd:198).
   **예상:** 진입 복구·왕복 검사 2~4시간.

5. **P2 — Steam 저장 확인 응답 누락 시 같은 실행에서 전송이 계속 막힐 수 있습니다.**
   서비스는 15초 뒤 `inflight`만 비웁니다. Steam 브리지의 `store_pending` 또는 `progress_pending`은 응답을 받아야 해제되며, 둘 중 하나가 남으면 다음 전송을 거절합니다. 로컬 큐는 보존되지만 **같은 실행의 재전송 복구는 보장되지 않습니다.** 기존 테스트는 응답을 직접 호출하므로 누락 상황을 검증하지 않습니다.
   근거: [서비스 제한시간 처리:64](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/achievements/AchievementService.gd:64), [전송 차단 조건:80](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/achievements/SteamAchievementBridge.gd:80), [기존 응답 검사:193](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/V130RStep13AchievementTest.gd:193).
   **예상:** 복구 처리·응답 누락/지연 검사 0.5일.

**도전과제 검사 범위**

정적 확인 결과는 **카탈로그 100개, 판정 규칙 100개, 8세트, 숨김 8개, stat 20개**입니다.

| 항목 | 기존 검사가 증명하는 범위 | 남은 출시 확인 |
|---|---|---|
| 100개 판정 | 합성 이벤트의 양성·음성·조건 누락·중복 검사 | 실제 사용자 행동에서 해당 이벤트 발생 |
| 실제 전투 | 고정 시드 DAY 1 승리→첫날 업적 연결 | 보스·전선·의회·엔딩·장기 누계 경로 |
| 오프라인 | 실제 Steam 초기화 실패 후 타이틀, 모의 전송 실패·재전송 | 실제 Steam 계정의 오프라인→온라인 동기화 |
| 구세이브 소급 | DAY 2 v1/v5 사본과 합성 완료 기록 | 실제 후기 전선·의회·엔딩 저장을 Continue로 로드 |
| DLL/export | 과거 Windows Desktop export의 DLL·PCK 및 Steam 없는 60프레임 실행 기록 | 현재 HEAD의 **Windows Steam** 최종 산출물 |
| Steam 없는 안정성 | singleton 부재·초기화 실패를 빠져나오는 코드, 기존 부팅 기록 | 현재 출시 EXE에서 새 게임·저장·재실행 |

위 범위의 근거는 [Step13 테스트:80](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/V130RStep13AchievementTest.gd:80), [소급 검사:153](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/V130RStep13AchievementTest.gd:153), [DAY 1 실제 전투 검사:284](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/V130RStep13AchievementTest.gd:284)입니다. **이번 감사에서 재실행한 결과는 아닙니다.**

추가 출시 게이트가 두 가지 있습니다.

- Steamworks 정의 등록·게시와 실제 계정 해제는 저장소 기록상 미실행입니다. 원격 조회를 하지 않았으므로 현재 서버 상태도 미확인입니다. [등록 상태 README:3](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/data/v130r/achievements/README.md:3)
- 기존 Step13 export는 `Windows Desktop` 프리셋입니다. 정식 준비 도구는 EXE/PCK만 필수 검사하고, 출시 검증기도 Steam DLL 두 개의 존재·해시를 필수로 검사하지 않습니다. **DLL 누락을 놓치는 검증 공백**입니다. [Step13 export:28](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/run_v130r_step13.ps1:28), [정식 필수 파일:89](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/release/PrepareSteamBuild.ps1:89)

**기존 콘텐츠의 실제 연결 판정**

| 콘텐츠 | Approved 사용자 경로 판정 |
|---|---|
| 원정 | 기존 화면·보상 코드는 남아 있으나 새 관리 화면의 일반 진입 누락. 전투 변화도 우회됨 |
| 칙령 | 다음 회차 설정 흐름의 선택 UI는 연결. 아군 능력치 배율 등 일부 효과 누락 |
| 전선 | 다음 회차 선택 흐름은 연결. 날짜별 진행·전투 변형·심장 처리는 불완전 |
| 의회 | 모드 선택·일부 지역/전초기지 화면 전환은 연결. 날짜 진행·전투 시작·웨이브·목표 연결은 불완전 |
| 엔딩 | 공통 결산→최종 승리 판정→엔딩 버튼은 연결. 분기 조건을 쌓는 경로와 다음 회차가 문제 |
| 기억·아카이브 | 지도 몬스터 정보→유대 기억은 연결. 기록실·전체 엔딩 아카이브 진입 누락 |
| 기존 합동기 6개 | 편성→게이지→J/K/자동 발동→기존 효과 처리기는 연결. 새 지도에서 6개 효과 전수 검증은 없음 |

합동기 연결은 [새 지도 기억·편성 버튼:301](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/map_builder/ApprovedMonsterPlacementUI.gd:301), [Approved 발동 분기:12416](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:12416), [기존 6개 효과 분기:12487](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/scripts/game/GameRoot.gd:12487)에서 확인했습니다.

**후속 실행에 사용할 직접 테스트**

| 대상 | 기존 테스트 | 보완할 사용자 경로 |
|---|---|---|
| 도전과제 | `V130RStep13AchievementTest`, `V130RStep13BAchievementUITest` | 실제 후기 이벤트, 응답 누락·지연, 후기 저장 Continue |
| 원정·칙령 | `tools/UIUXRaidChoiceTest.gd`, `tools/Update2CycleChoicesSmokeTest.gd`, `tools/Update2SeededCampaignSmokeTest.gd` | Approved 버튼→선택→다음 전투의 변화 |
| 전선 | `FrontSelectionPhase3Test`, `HeroOathPhase23Test`, `HolyPurificationPhase19Test`, `GuildRepossessionPhase21Test` | 새 지도에서 날짜 진입·변형·클리어 기록 |
| 의회 | `CampaignModePhase3Test`, `CouncilSeasonPhase4Test`, `CouncilAgendaPhase21Test`, `V130Council1FTest` | 실제 모드 선택→Approved 날짜·전투·목표·엔딩 |
| 엔딩·기록 | `EndingPhase27Test`, `EndingPhase28Test`, `Update4EndingsPhase32Test/33Test`, `ChroniclePhase26Test` | DAY 30 결과→엔딩→다음 회차→저장·재실행 |
| 기존 합동기 | `DuoLinkPhase9Test`, `DuoLinksPhase10Test`, `DuoLinksPhase24Test`, `SkillActionDuoTest` | Approved에서 기존 6개 각각 충전·발동·효과·행동 제한 |

테스트 이름만으로 실제 사용자 경로 검사라고 분류하면 안 됩니다. 예를 들어 `V130Council1FTest`는 `GameRoot`를 직접 만들고 의회 상태를 주입하며, 옛 합동기 테스트는 효과 함수를 직접 호출합니다. Step11의 실제 효과 반복 검사는 **신규 10개** 대상입니다.

또한 옛 합동기 테스트의 `catalog.size()==6` 조건은 현재 **기존 6+신규 10=16개**와 충돌합니다. 먼저 기존 6개 ID·효과 보존 조건으로 갱신해야 합니다. [옛 조건:30](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/DuoLinksPhase24Test.gd:30), [현재 16개 및 신규 검사:62](/C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action/tools/tests/V130RStep11StoryTest.gd:62)

**예상 작업량은 구현·직접 회귀 합계 4~7인일**입니다. 위 항목 간 공통 수정은 합쳐 산정했으며, 전체 캠페인 플레이와 실제 Steam 계정 검증 시간은 별도입니다. 이번 결과는 **정적 독립 감사이며 출시 PASS 판정이 아닙니다.**
