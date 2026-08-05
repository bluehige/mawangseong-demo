# v1.2.2 단일 기준 대응표

기준 SHA:

- 제품 기준: `7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 공개 런타임 기준: `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 전투·밸런스 참고: `7e61cc9762b5c157a52160ce7f13ad0bf0a7d358`
- UI 참고: `5ed1d5f0bd7f5fcb9b887c20d79749b79707dcc1`

| 영역 | 정식 기준 | runtime consumer | 처리 | v1.2.2 계약 | 확인 |
|---|---|---|---|---|---|
| DAY 1~30·스토리 | `data/campaign_days.json` | `GameRoot`, `WaveManager` | `KEEP_121` | 기존 DAY·대사·보상·DAY 5 이후 진행 보존 | `OnboardingFlowSmokeTest`, 캠페인 phase 테스트 |
| 기존 적·보스 | `data/enemies.json`, `data/waves.json`, `data/regular_version/update3`, `update4` | `CombatSceneController`, `scripts/systems/bosses` | `KEEP_121` | 모든 특수 행동·보스 페이즈 우선권 보존 | 적·보스 phase 테스트 |
| 몬스터 성장·진화 | `data/monsters.json`, `monster_instances.json`, `specializations.json`, `evolution_rules.json` | `GameRoot`, `MonsterInstanceValidator` | `KEEP_121` | 레벨·EXP·특화·진화 초기화 금지 | `MonsterLegacySystemsSmokeTest` |
| 성·방·경로 | `data/dungeon_quarter/*` | `ModuleGraph`, `QuarterDungeonRenderer` | `ADAPT_TO_121` | v20 가상 방 대신 실제 ModuleGraph snapshot 사용 | `QuarterModuleSmokeTest` |
| 건물·시설 | `room_blueprints.json`, `asset_manifest.json`, `rooms.json` | `DungeonModuleRegistry`, `QuarterDungeonRenderer`, `GameRoot` | `KEEP_121` | 제품 ID·해금·업그레이드·stage 외형 보존 | 건물 호환 매트릭스 |
| 배치 인과 | 실제 ModuleGraph와 캠페인 roster | 신규 `scripts/v122/spatial` adapter | `PORT_RULE` | 관리 slot과 전투 spawn/home을 동일 snapshot에서 파생 | 신규 spatial 테스트 |
| 시설 전투 효과 | `GameRoot.rooms`, 실제 world anchor | `CombatSceneController` | `PORT_RULE` | 실제 좌표·범위·상태에서만 효과 적용 | 신규 facility 테스트 |
| 제한 명령 | `DirectiveManager`, 기존 actor·room ID | 신규 v1.2.2 command adapter | `ADAPT_TO_121` | 집결·집중·시설 발동·비상 후퇴를 기존 AI 우선순위에 삽입 | 신규 command 테스트 |
| 전투 계측 | 기존 전투 결과·run metric | 신규 v1.2.2 event ledger | `PORT_RULE` | 배치·시설·명령 기여와 실패 원인을 실제 event로 계산 | 신규 evidence 테스트 |
| 저장·이어하기 | `CampaignSaveStore`와 v2~v5 migration chain | `GameRoot` | `ADAPT_TO_121` | v20 격리 저장 금지, 기존 저장 schema에 optional v122 확장 | 저장 호환 매트릭스 |
| 관리 UI | `ManagementSceneController` | 기존 GameRoot 데이터 | `ADAPT_TO_121` | U5 정보 우선순위만 사용하고 모든 기존 기능 진입 보존 | 신규 management UI 테스트 |
| 전투 HUD | `HUDController`, `CombatSceneController` | 기존 적·보스·심장·합동기 상태 | `ADAPT_TO_121` | 위협 예고·구간·명령을 기존 HUD에 결합 | 신규 combat HUD 테스트 |
| 결과 UI | `ManagementSceneController.build_result_ui` | 기존 성장·보상·스토리·엔딩 | `ADAPT_TO_121` | U5 원인 설명을 기존 결과 흐름에 결합 | 신규 result UI 테스트 |
| 밸런스 | DAY 1~5 검증 evidence + 실제 DAY 1~30 성장 | 신규 v1.2.2 balance model | `RECALCULATE` | DAY 6~30은 같은 공식으로 매 DAY 재계산 | balance 매트릭스 |
| Update 2~4·엔딩 | `data/regular_version`, `scripts/systems` | 기존 GameRoot/Combat controller | `KEEP_121` | 제거·숨김 금지, 신규 adapter보다 기존 특수 행동 우선 | 기존 update2~4 suite |
| Windows·Steam·Web | `project.godot`, `export_presets.cfg`, release tools | 기존 빌드 파이프라인 | `KEEP_121` | 기능 동결 뒤 1.2.2 기술 버전만 갱신 | P17 release readiness |

## 이식 금지

- `release/v2.0` merge 또는 commit-range cherry-pick
- `scripts/game/GameRoot.gd`, `CombatSceneController.gd` 통째 복사
- `data/v20/dungeon_layouts.json`을 제품 맵 기준으로 사용
- `V20SaveStore`를 정식 저장으로 사용
- level 1·EXP 0·DAY별 성장 초기화·DAY 5 terminal 조건
- 별도 v20 타이틀·debug acceptance 진입점

분류 미확정 행은 없다. 구현 중 사실이 달라지면 행을 추가하고 허용 처리 상태 중 하나로 재분류한다.
