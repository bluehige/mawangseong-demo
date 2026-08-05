# v1.2.2 저장 호환 대응표

정식 진입점은 `CampaignSaveStore`와 기존 v1→v2→v3→v4→v5 migration chain이다. `V20SaveStore`는 정식 제품에서 사용하지 않는다.

| fixture·영역 | 기존 근거 | v1.2.2 처리 | 검증 |
|---|---|---|---|
| v1.2.0 새 게임 | `CampaignSaveStore.SAVE_VERSION`, `write/inspect` | `KEEP_121`, optional v122 기본값 생성 | P8 PASS |
| v1.2.1 DAY 1 | campaign v1 payload | `ADAPT_TO_121`, battle plan 없음 허용 | P8 PASS |
| DAY 3 성장 전·후 | 성장 payload·checkpoint | `KEEP_121`, 성장 버튼·retry snapshot 분리 | P8·기존 저장 회귀 PASS |
| DAY 5 | campaign day/checkpoint | `ADAPT_TO_121`, 승리 뒤 DAY 6 | P8 PASS |
| DAY 12 진화 | monster instance·evolution | `KEEP_121` | P8 PASS |
| DAY 20 전선 | update3 front state | `KEEP_121` | P8 PASS |
| DAY 25 보스 | boss/checkpoint state | `KEEP_121` | P8 PASS |
| DAY 29 | final preparation flags | `KEEP_121` | P8 PASS |
| DAY 30 | final battle outcome | `KEEP_121`, 일반·최종전 retry에 확정 배치 복원 | P8·기존 저장 회귀 PASS |
| 엔딩 완료 | ending flags·postgame | `KEEP_121` | P8 PASS |
| Update 4 캠페인 | `CampaignSaveV5Store`, v5 migrator | `KEEP_121`, v5 `legacy_payload`에 optional 확장 보존 | P8·v5 migration PASS |
| corrupt | `CampaignSaveStore.inspect/mark_invalid` | `KEEP_121`, 원본 격리·사용자 안내 | P8 PASS |
| `.tmp` | `_recover_interrupted_write` | `KEEP_121`, 유효 임시본 복구 | P8 PASS |
| `.bak` | `_restore_backup_after_failed_write` | `KEEP_121`, 실패 시 원복 | P8 PASS |
| v20 격리 저장 | `V20SaveStore` | `REMOVE_TEST_ONLY`, 정식 consumer 0 | static closure |

## optional v122 payload

기존 payload 안에 `v122_battle_plan` dictionary를 optional로 추가한다. 필드는 `schema_version`, `battle_plan` snapshot, `facility_placements`, `monster_placements`, `last_confirmed_placements`, `retry_snapshot`, `command_settings`, `ui_state`다. `layout_id`와 `layout_fingerprint`는 `battle_plan`과 마지막 확정·retry snapshot 안에 보존한다.

- 누락 시 현재 ModuleGraph와 roster에서 생성한다.
- layout fingerprint가 달라도 기존 room ID·성장·보상은 폐기하지 않는다.
- retry snapshot은 전투 시작 전 확정 배치만 저장한다.
- 전투 중간 actor HP·cooldown 등 transient runtime은 저장하지 않는다.
- write는 기존 temp→검증→backup→rename 원자 절차를 그대로 사용한다.

P8 직접 fixture, 기존 `CampaignSaveLoadSmokeTest` 252 assertions, `SaveV5MigrationTest` 37 assertions와 전체 `DemoSmokeTest`가 통과했다. 완료 조건인 데이터 손실 0, 자동 backup, migration 실패 원복, DAY 5→6·DAY 30→엔딩, 성장·재도전 차단 재발 0을 충족한다.
