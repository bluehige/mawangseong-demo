# V1.2.2 F0-V 시각 인벤토리 (2026-08-02)

## 목적과 판정 기준

이번 문서는 루나 작업의 첫 번째 패킷인 `F0-V` 결과다. 게임 실행 코드와 원본 그래픽은 바꾸지 않고, 현재 전투에 실제로 등록된 유닛 44개의 스프라이트 연결·프레임 크기·투명 여백·발 위치 추정·비행 판정을 읽기 전용으로 확인했다.

- 런타임 기준값: 지상 `scale 0.42 / sprite Y -37`, 비행 `scale 0.44 / sprite Y -44` (`scripts/units/Unit.gd`). 192×192 프레임을 기준 셀 `1.00×`로 삼아 맵 상대 크기를 기록했다.
- `PASS`: 파일이 존재하고 192 셀·투명 영역·런타임 판정이 기준과 연결된다.
- `NEEDS_NORMALIZATION`: 파일은 연결되지만 프레임 크기, 불투명 크로마키 원본, 중복 ID 공유 또는 비행 판정 중 하나가 정규화 패킷에서 해결되어야 한다.
- `DISCONNECTED`: 참조 파일이 없거나 읽을 수 없는 경우. 이번 인벤토리에서는 0개였다.
- `FAIL_REGEN`은 이 단계에서 사용하지 않았다. 재생성 여부는 F1 이후 별도 승인 항목이다.

## 확인 산출물

읽기 전용 산출물은 소스 브랜치에 커밋하지 않는 지정 임시 폴더에 만들었다.

- 활성 로스터 연락판: [f0_v_active_roster_contact_sheet.png](../../tmp/v122_release_polish/f0_v/f0_v_active_roster_contact_sheet.png)
- DAY 3 대표 1280×720 캡처: [f0_v_day3_1280x720.png](../../tmp/v122_release_polish/f0_v/f0_v_day3_1280x720.png)
- 기계 판독 원본: `tmp/v122_release_polish/f0_v/f0_v_inventory.json`, `f0_v_inventory.tsv`

![F0-V 활성 로스터 연락판](../../tmp/v122_release_polish/f0_v/f0_v_active_roster_contact_sheet.png)

![DAY 3 대표 전투 캡처](../../tmp/v122_release_polish/f0_v/f0_v_day3_1280x720.png)

## 요약

| 항목 | 결과 |
|---|---:|
| 전투 활성 레코드 | 44개 |
| 고유 스프라이트 경로 | 37개 |
| 원본 크기 | 192×192 28개 · 1254×1254 14개 · 768×768 2개 |
| 상태 | `PASS` 19개 · `NEEDS_NORMALIZATION` 25개 · `DISCONNECTED` 0개 |
| 비행 판정 불일치 | `imp`(데이터 태그 없음/런타임 비행), `dusk_courier`(데이터 비행/런타임 지상) |
| 중복 경로 | 5개 경로가 12개 레코드에서 공유 |

## 순서 재시작 재검증

정적 inventory의 활성 44개·고유 경로 37개·파일 누락 0개는 다시 확인했다. 다만 현재 혼합 작업 트리에서 기존 `F0VDay3Capture.tscn`을 headless로 재실행했을 때 dummy renderer의 viewport texture가 비어 `F0-V DAY 3 capture viewport is empty`로 종료됐다. 기존 PNG를 현재 런타임의 승인 근거로 재사용하지 않으며, 실제 화면 확인은 V1 이후 별도 대표 검수에서 다시 수행한다.

## 전체 활성 로스터 인벤토리

`alpha bbox`는 원본 이미지 좌표의 `[왼쪽, 위, 오른쪽, 아래]`이고, `발끝 추정`은 그 박스의 아래쪽 중앙이다. `opaque`는 알파 투명 영역을 계산할 수 없는 RGB 원본이라 크로마키 제거 전까지 발끝을 확정하지 않았다는 뜻이다. `프레임`은 시트라면 현재 런타임의 4×4 분할 셀, 일반 이미지라면 전체 이미지 크기다. `효과 셀`은 현재 스케일을 곱한 맵 상대 참고값이다.

| ID | 현재 스프라이트 | 원본 → 프레임 / 192셀 대비 / 효과 셀 | 투명 영역 / 발끝 추정 | 데이터 비행 / 런타임 비행 | 상태 |
|---|---|---|---|---|---|
| `slime` | `monsters/monster_slime_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[29,71,169,181]` / `[98.5,180]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `goblin` | `monsters/monster_goblin_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[23,22,163,179]` / `[92.5,178]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `imp` | `monsters/monster_imp_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[25,27,163,170]` / `[93.5,169]` | N / Y | **NEEDS_NORMALIZATION** · 데이터/런타임 불일치 |
| `kobold_scout` | `monsters/monster_kobold_scout_idle_down_00.png` | 1254×1254 → 1254×1254 / 6.531× / 526.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 1프레임 대형 원본, 2개 ID 공유 |
| `spore_healer` | `monsters/monster_slime_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[29,71,169,181]` / `[98.5,180]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `stone_sentinel` | `monsters/monster_slime_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[29,71,169,181]` / `[98.5,180]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `war_drummer` | `monsters/monster_goblin_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[23,22,163,179]` / `[92.5,178]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `moon_tracker` | `monsters/monster_kobold_scout_idle_down_00.png` | 1254×1254 → 1254×1254 / 6.531× / 526.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 1프레임 대형 원본, 2개 ID 공유 |
| `mimic_porter` | `monsters/monster_goblin_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[23,22,163,179]` / `[92.5,178]` | N / N | **NEEDS_NORMALIZATION** · 3개 ID 공유 |
| `explorer` | `enemies/enemy_explorer_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[38,23,161,188]` / `[99.0,187]` | N / N | **PASS** |
| `thief` | `enemies/enemy_thief_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[35,24,155,173]` / `[94.5,172]` | N / N | **PASS** |
| `trainee_hero` | `enemies/enemy_trainee_hero_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[25,17,162,179]` / `[93.0,178]` | N / N | **PASS** |
| `investigator` | `enemies/enemy_investigator_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[47,12,144,178]` / `[95.0,177]` | N / N | **PASS** |
| `shieldbearer` | `enemies/enemy_shieldbearer_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[23,20,166,171]` / `[94.0,170]` | N / N | **PASS** |
| `engineer` | `enemies/enemy_engineer_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[39,15,152,170]` / `[95.0,169]` | N / N | **PASS** |
| `selen_trainee_paladin` | `enemies/enemy_selen_paladin_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[18,18,156,180]` / `[86.5,179]` | N / N | **NEEDS_NORMALIZATION** · 2개 ID 공유 |
| `roman` | `enemies/enemy_roman_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[48,12,144,180]` / `[95.5,179]` | N / N | **NEEDS_NORMALIZATION** · 2개 ID 공유 |
| `official_hero_leon` | `enemies/enemy_official_hero_leon_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[6,22,186,187]` / `[95.5,186]` | N / N | **PASS** |
| `royal_scout` | `enemies/enemy_royal_scout_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[22,7,170,181]` / `[95.5,180]` | N / N | **PASS** |
| `monster_binder` | `enemies/enemy_monster_binder_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[15,11,177,181]` / `[95.5,180]` | N / N | **PASS** |
| `ward_breaker` | `enemies/enemy_ward_breaker_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[19,7,173,181]` / `[95.5,180]` | N / N | **PASS** |
| `supply_raider` | `enemies/enemy_supply_raider_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[22,7,169,181]` / `[95.0,180]` | N / N | **PASS** |
| `anti_magic_archer` | `enemies/enemy_anti_magic_archer_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[31,7,160,181]` / `[95.0,180]` | N / N | **PASS** |
| `royal_field_medic` | `enemies/enemy_royal_field_medic_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[28,7,163,181]` / `[95.0,180]` | N / N | **PASS** |
| `royal_strategist_evelyn` | `enemies/enemy_royal_strategist_evelyn_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[28,7,164,181]` / `[95.5,180]` | N / N | **PASS** |
| `ghost_housemaid` | `monsters/monster_ghost_housemaid_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[41,35,150,182]` / `[95.0,181]` | N / N | **PASS** |
| `graveyard_hound` | `monsters/monster_graveyard_hound_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[30,10,162,182]` / `[95.5,181]` | N / N | **PASS** |
| `armored_beetle` | `monsters/monster_armored_beetle_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[17,26,174,182]` / `[95.0,181]` | N / N | **PASS** |
| `seal_chainbearer` | `enemies/update3_atlas/enemy_seal_chainbearer_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `reliquary_guard` | `enemies/update3_atlas/enemy_reliquary_guard_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `choir_exorcist` | `enemies/update3_atlas/enemy_choir_exorcist_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `bounty_tracker` | `enemies/update3_atlas/enemy_bounty_tracker_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `combat_alchemist` | `enemies/update3_atlas/enemy_combat_alchemist_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `guild_commissioner_roman` | `enemies/enemy_roman_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[48,12,144,180]` / `[95.5,179]` | N / N | **NEEDS_NORMALIZATION** · `roman`과 경로 공유 |
| `official_paladin_selen` | `enemies/enemy_selen_paladin_idle_down_00.png` | 192×192 → 192×192 / 1.000× / 80.6px | transparent / `[18,18,156,180]` / `[86.5,179]` | N / N | **NEEDS_NORMALIZATION** · `selen_trainee_paladin`과 경로 공유 |
| `ledger_binder` | `enemies/update3_atlas/enemy_ledger_binder_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `spider_tailor` | `monsters/update4/monster_spider_tailor_sheet.png` | 768×768 → 192×192 / 1.000× / 80.6px | transparent / `[9,36,759,759]` / `[95.5,182]` | N / N | **PASS** |
| `bat_courier` | `monsters/update4/monster_bat_courier_sheet.png` | 768×768 → 192×192 / 1.000× / 80.6px | transparent / `[9,9,759,759]` / `[95.5,182]` | N / N | **PASS** · 비행 태그 미정이라 F0에서 확정하지 않음 |
| `coal_spark` | `enemies/update4/region/enemy_coal_spark_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `dusk_courier` | `enemies/update4/region/enemy_dusk_courier_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | Y / N | **NEEDS_NORMALIZATION** · 데이터/런타임 비행 불일치 |
| `bronze_automaton` | `enemies/update4/region/enemy_bronze_automaton_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `shadow_duelist` | `enemies/update4/region/enemy_shadow_duelist_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `spore_doll` | `enemies/update4/region/enemy_spore_doll_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |
| `root_tender` | `enemies/update4/region/enemy_root_tender_sheet.png` | 1254×1254 → 313.5×313.5 / 1.633× / 131.7px | opaque / 발끝 미확정 | N / N | **NEEDS_NORMALIZATION** · 4×4 셀 비정수, 크로마키 후보 |

## F0-V에서 확인한 구조적 원인

1. **프레임 기준이 섞여 있다.** `Unit._build_sheet_animation_frames()`는 모든 `*_sheet.png`를 4×4로 나눈다. 그래서 1254 시트는 셀 하나가 313.5px이고, 768 시트만 정확히 192px이다. 기본 `kobold_scout`·`moon_tracker`는 시트 접미사도 없는 1254 단일 이미지라서 1프레임 전체가 들어간다. 맵 기준으로는 같은 `scale 0.42`라도 80.6px과 131.7px/526.7px가 섞여 보일 수 있다.
2. **크로마키 원본이 런타임에 남아 있다.** 1254 시트 12개와 기본 1254 이미지 2개는 알파가 불투명하다. 현재 런타임 셰이더가 마젠타를 제거하지만, 투명 여백·발 위치를 이미지 파일 자체에서 확정할 수 없다. 이 단계에서 임의로 지우거나 재생성하지 않았다.
3. **서로 다른 ID가 같은 그림을 공유한다.** 슬라임·고블린·코볼트·셀렌·로만 계열에서 5개 경로를 12개 레코드가 공유한다. 데이터상 다른 캐릭터인데 전투에서 같은 실루엣이 나오는 이유다. F1에서 원본/대체 연결을 분리할지 결정해야 한다.
4. **비행 규칙이 데이터와 코드에 따로 있다.** 런타임은 `_is_flying_unit()`에서 `imp`만 비행으로 하드코딩한다. 데이터에는 `dusk_courier`가 `flying` 태그지만 런타임은 지상 프로필이고, 반대로 `imp`는 데이터 태그 없이 비행 프로필이다. `bat_courier`는 이름만으로 비행을 확정하지 않고 다음 패킷에서 기획 태그를 확인한다.

## 다음 순서

F0-V는 완료했지만 런타임 수정은 하지 않았다. 다음은 `F0-A`(BGM·타격음·UI/환경음 인벤토리), 그 뒤 `F0-R`(출시 공백 인벤토리)다. F0 세 패킷을 다시 닫은 뒤에야 `V1-A` 맵 비례 스케일 계약·registry를 시작하며, V1-A 통과 전에는 V1-B/C/D·V2 이후 패킷을 시작하지 않는다.
