# 3차 업데이트 Phase 0 기준선 감사

- 감사 일자: 2026-07-13 (KST)
- 대상 계획: `UPDATE3_LIVING_CASTLE_THREE_FRONTS_PLAN_2026-07-12.md`
- 현재 브랜치: `v.02`
- 현재 HEAD·작업 기준 커밋: `11769401b9237a4f7f928aa5365729c77b81133b`
- 원격 `main` 기준 커밋: `ab2d445da35ee087dc29bd01e1e740ff4a5769a3`
- 2차 완료 상태: 위 HEAD 위의 현재 작업 트리
- 2차 완료 계약: `docs/design/UPDATE2_RECONSTRUCTION_CONTRACT_2026-07-13.md`
- 2차 완료 재감사: `docs/design/UPDATE2_COMPLETION_AUDIT_2026-07-13.md`

## 결론

**Phase 0 기준선 재감사를 완료했다. 2차 업데이트 완료 조건은 모두 충족하며 3차 Phase 1 진입 차단 항목은 0건이다.**

과거 Phase 0 감사에서 확인했던 저장 v3·계약 로스터·대응군·적응형 레온·E00~E11 누락은 2차 재구성 R0~R9에서 모두 닫혔다. 전체 Full 통합 검증도 21/21 PASS다. Phase 1부터 이 문서의 ID와 서비스 경로를 기준으로 기존 책임을 확장하고 같은 책임의 클래스를 중복 생성하지 않는다.

## 1. 실제 저장 버전

| 버전 | 구현 위치 | 상태 |
|---|---|---|
| v1 | `scripts/core/CampaignSaveStore.gd`, `user://campaign_save_v1.json` | 기존 런타임 체크포인트 유지 |
| v2 | `scripts/core/CampaignSaveMigratorV1ToV2.gd`, `scripts/core/CampaignSaveV2Store.gd` | 이전 보조 저장 호환 유지 |
| v3 | `scripts/core/CampaignSaveMigratorV2ToV3.gd`, `scripts/core/CampaignSaveV3Store.gd`, `user://campaign_save_v3.json` | 최신 프로필·회차 저장, PASS |

- 최신 저장 봉투 버전: `3`
- 최신 프로필 버전: `2`
- v2→v3 변환: 원본 v2 보존, 임시 파일 재검증, 백업·복구, 최종 재검증
- DAY 30 승리 뒤 다음 회차의 v1 체크포인트와 v2·v3 보조 저장을 전용 검사에서 함께 확인했다.

## 2. 실제 서비스와 레지스트리 위치

| 책임 | 실제 클래스·위치 |
|---|---|
| 전체 JSON 등록·조회 | `DataRegistry` — `scripts/core/DataRegistry.gd` |
| 정규 체크포인트 저장 v1 | `CampaignSaveStore` — `scripts/core/CampaignSaveStore.gd` |
| v1→v2 변환·v2 저장 | `CampaignSaveMigratorV1ToV2`, `CampaignSaveV2Store` — `scripts/core/` |
| v2→v3 변환·v3 저장 | `CampaignSaveMigratorV2ToV3`, `CampaignSaveV3Store` — `scripts/core/` |
| 계약 게시판·출전/예비 | `ContractRosterService` — `scripts/systems/contracts/ContractRosterService.gd` |
| seed 사건·웨이브 변형 | `Update2SeededCampaignService` — `scripts/systems/campaign/Update2SeededCampaignService.gd` |
| 레온 적응 태세 | `LeonAdaptationService` — `scripts/systems/campaign/LeonAdaptationService.gd` |
| 엔딩 조건·회차 지표 | `EndingConditionEvaluator`, `RunMetricsTracker` — `scripts/systems/endings/` |
| 새 회차·계승·엔딩 도감 | `NewCycleService` — `scripts/systems/legacy/NewCycleService.gd` |
| 화면·캠페인 조정 | `GameRoot` — `scripts/game/GameRoot.gd` |
| 관리 화면 | `ManagementSceneController` — `scripts/game/ManagementSceneController.gd` |
| 전투 조정 | `CombatSceneController` — `scripts/game/CombatSceneController.gd` |

3차 서비스는 위 책임을 재사용한다. 특히 새 저장소, 새 엔딩 평가기, 새 계약 서비스는 같은 책임으로 중복 생성하지 않는다.

## 3. 실제 ID 목록

### 3.1 계약 몬스터 5종

| 종 ID | 개체 ID |
|---|---|
| `spore_healer` | `mon_contract_mori` |
| `stone_sentinel` | `mon_contract_dolkong` |
| `war_drummer` | `mon_contract_dudum` |
| `moon_tracker` | `mon_contract_lumi` |
| `mimic_porter` | `mon_contract_mimi` |

기존 핵심 종은 `slime`, `goblin`, `imp`, `kobold_scout`이며 계약 2종 선택 수에 포함되지 않는다.

### 3.2 2차 대응군 6종과 에블린

- `royal_scout`
- `monster_binder`
- `ward_breaker`
- `supply_raider`
- `anti_magic_archer`
- `royal_field_medic`
- `royal_strategist_evelyn`

기존 적 9종은 `explorer`, `thief`, `trainee_hero`, `investigator`, `shieldbearer`, `engineer`, `selen_trainee_paladin`, `roman`, `official_hero_leon`이다.

### 3.3 왕국 교리 6종

- `royal_supply_lock`
- `royal_mana_watch`
- `royal_bounty_decree`
- `royal_contract_registry`
- `royal_fortification_audit`
- `royal_adaptive_command`

### 3.4 마왕 칙령 6종

- `decree_open_pantry`
- `decree_arcane_rationing`
- `decree_family_watch`
- `decree_mobile_reserve`
- `decree_trap_maintenance`
- `decree_rival_protocol`

### 3.5 도전 인장 6종

- `seal_no_throne_damage`
- `seal_no_monster_down`
- `seal_low_mana`
- `seal_no_facility_disable`
- `seal_contract_vanguard`
- `seal_adaptive_rival`

### 3.6 레온 적응 자세 4종

- `leon_stance_siege`
- `leon_stance_pursuit`
- `leon_stance_purification`
- `leon_stance_duelist`

### 3.7 엔딩 E00~E11

| 코드 | 엔딩 ID |
|---|---|
| E00 | `true_demon_castle` |
| E01 | `monster_family_castle` |
| E02 | `impregnable_demon_citadel` |
| E03 | `dread_overlord_rises` |
| E04 | `demon_hero_rival_pact` |
| E05 | `contract_monster_alliance` |
| E06 | `royal_doctrine_broken` |
| E07 | `challenge_seal_legend` |
| E08 | `evelyns_counterledger` |
| E09 | `adaptive_rival_mastery` |
| E10 | `castle_without_reserves` |
| E11 | `twelve_endings_chronicle` |

## 4. 3차 예정 ID 충돌 감사

| 3차 예정 범위 | 현재 직접 충돌 | 판정·연결 기준 |
|---|---|---|
| `front_hero_oath`, `front_holy_purification`, `front_guild_repossession` | 없음 | 새 ID로 사용 가능. 레온 전선은 기존 `official_hero_leon`과 적응 태세 서비스를 참조한다. |
| `heart_stonebone`, `heart_hungry_maw`, `heart_dream_lantern`, `heart_chamber` | 없음 | 새 ID로 사용 가능. 기존 방 ID와 충돌 없음. |
| `link_spore_jelly_shelter` 등 합동 기억 6종 | 없음 | 새 ID로 사용 가능. 모리·돌콩·두둠·루미·미미 실제 종 ID를 위 표대로 참조한다. |
| 3차 신규 몬스터 베베·코코·톡톡 | 없음 | 기존 9종 몬스터 종 ID와 충돌 없음. Phase 1에서 예정 ID를 고정한다. |
| 성광·길드 신규 적 6종 | 없음 | 2차 대응군 7종과 별도 namespace로 고정한다. |
| `official_paladin_selen`, `guild_commissioner_roman` | 없음 | 기존 `selen_trainee_paladin`, `roman`을 삭제하지 않고 최종 형태로 별도 연결한다. |
| E12~E16 | 없음 | E00~E11이 모두 사용 중이므로 다음 연속 코드로 사용 가능하다. |
| `ending_holy_open_gate`, `ending_off_ledger_independence`, `ending_living_castle_voice`, `ending_linked_corridors`, `ending_three_front_armistice` | 없음 | 엔딩 ID와 코드 모두 사용 가능하다. |

## 5. 전체 테스트 결과

실행 명령:

```powershell
.\tools\tests\RunCoreVerification.ps1 -Mode Full -GodotPath <Godot 4.5.2 console>
```

- 실행 시각: 2026-07-13 01:56:47~02:09:32 KST
- 전체 결과: **PASS, 21/21**
- 실패: **0**
- 총 소요: 765.06초
- 보고서: `tmp/core_verification/latest.json`, `tmp/core_verification/latest.md`
- R8 전용: 383개 단언 PASS
- 정규 DAY 28~30 저장·이어하기·재도전·후일담: 233개 단언 PASS

포함 범위는 프로젝트 불러오기, 핵심 게임, 공병 성능, v1/v2/v3 저장, 2차 R1~R8, 튜토리얼, 일반 DAY 5 전환, 전체 밸런스, 다중 seed, UI·전투 캡처다.

## 6. 해상도 캡처 기준선

Full 검증에서 2026-07-13 02:09 KST 이전에 새로 생성되고 최신성 검사를 통과했다.

- 1920×1080 대표 UI: `tmp/ui_regression_review/03_result_screen.png`
- 1920×1080 대표 전투: `tmp/action_feel_review/04_live_combat.png`
- 1366×768 목표 UI: `tmp/ui_regression_review/12_result_1366_scale_115.png`
- 1366×768 목표 전투: `tmp/action_feel_review/11_live_combat_1366_scale_115.png`
- 1366×768 밀집 전투: `tmp/action_feel_review/13_dense_combat_1366_scale_115.png`

## 7. 차단 목록

없음.

다음 단계 금지 조건을 재확인한 결과 저장 v3 존재, E00~E11 완성, 계약 로스터 완성, 적응형 레온 완성, 전체 테스트 P1 오류 0건이다. Phase 1을 시작할 수 있다.

## 8. Phase 0 결정 로그

| ID | 결정 | 이유 |
|---|---|---|
| U3-P0-D001 | 코드 기준선 SHA는 `11769401...`로 고정 | 현재 브랜치 HEAD이며 2차 재구성은 그 위 작업 트리에 존재한다. |
| U3-P0-D002 | 최신 저장 버전은 v3, 프로필 버전은 2 | 실제 마이그레이터·저장소·왕복 검사 기준이다. |
| U3-P0-D003 | E00~E11과 기존 엔딩 ID를 모두 유지 | 저장 호환과 3차 E12~E16 연속 코드 계약을 보존한다. |
| U3-P0-D004 | 2차 대응군과 3차 성광·길드 적을 분리 | 역할과 제작 수량 계약의 혼선을 막는다. |
| U3-P0-D005 | 기존 서비스를 확장하고 동책임 서비스를 만들지 않음 | 계획의 중복 책임 금지 조건을 따른다. |
| U3-P0-D006 | Phase 1 진입 차단 0건 | Full 21/21 PASS와 2차 완료 감사 기준이다. |
