# 2차 업데이트 재구성 구현 계약

- 작성일: 2026-07-13 (KST)
- 근거: `UPDATE3_LIVING_CASTLE_THREE_FRONTS_PLAN_2026-07-12.md` 1.1
- 사용자 승인: 3차 문서 1.1 조건을 기준으로 누락된 2차 업데이트 재구성
- 기준 커밋: `11769401b9237a4f7f928aa5365729c77b81133b`

## 1. 재구성 원칙

1. 3차 계획이 직접 참조하는 이름과 역할은 변경하지 않는다.
2. 기존 저장 v1·v2와 기존 5개 엔딩 ID를 삭제하거나 이름만 바꿔 복제하지 않는다.
3. 2차 기능은 저장 v3의 `profile`과 `active_run`을 기준으로 저장한다.
4. DAY 30 최종일, Stage 01~04, 기존 레온 최종전, 기존 몬스터 4개체를 유지한다.
5. 각 R 단계의 전용 검사가 통과하기 전에는 다음 R 단계로 넘어가지 않는다.
6. 3차 Phase 1은 R0~R9와 Phase 0 재감사가 모두 끝난 뒤 시작한다.

## 2. 고정 ID 계약

### 2.1 계약 몬스터 5종

3차 합동기 조합에서 이름과 역할을 역추적했다.

| 종 ID | 개체 ID | 이름 | 핵심 역할 | 3차 연결 |
|---|---|---|---|---|
| `spore_healer` | `mon_contract_mori` | 모리 | 포자 회복·정화 | 푸딩과 L01 |
| `stone_sentinel` | `mon_contract_dolkong` | 돌콩 | 위치 고정·방 수호 | 두둠과 L05 |
| `war_drummer` | `mon_contract_dudum` | 두둠 | 사기·방어 지원 | 돌콩과 L05 |
| `moon_tracker` | `mon_contract_lumi` | 루미 | 표식·추적 | 미미와 L06 |
| `mimic_porter` | `mon_contract_mimi` | 미미 | 가짜 보물·유인 | 루미와 L06 |

회차당 정확히 2종을 계약한다. 핵심 몬스터는 계약 수에 포함하지 않는다.

### 2.2 2차 대응 적 6종과 에블린

| ID | 이름 | 역할 |
|---|---|---|
| `royal_scout` | 왕실 정찰병 | 후열 위치 노출 |
| `monster_binder` | 마물 구속병 | 이동·구조 효율 약화 |
| `ward_breaker` | 결계 파쇄병 | 보호막·회복 효율 약화 |
| `supply_raider` | 보급 약탈병 | 시설·보물 압박 |
| `anti_magic_archer` | 파마 궁수 | 원거리 시전자 견제 |
| `royal_field_medic` | 왕실 야전의무관 | 적 회복·정화 |
| `royal_strategist_evelyn` | 왕실 전략가 에블린 | 전술 분석·레온 자세 예고 |

대응 적은 특정 몬스터를 금지하지 않고 핵심 효율을 최대 35%까지만 낮춘다.

### 2.3 왕국 교리 6종

기존 3종을 유지하고 3종을 추가한다.

- `royal_supply_lock`
- `royal_mana_watch`
- `royal_bounty_decree`
- `royal_contract_registry`
- `royal_fortification_audit`
- `royal_adaptive_command`

### 2.4 마왕 칙령 6종

- `decree_open_pantry`
- `decree_arcane_rationing`
- `decree_family_watch`
- `decree_mobile_reserve`
- `decree_trap_maintenance`
- `decree_rival_protocol`

### 2.5 도전 인장 6종

- `seal_no_throne_damage`
- `seal_no_monster_down`
- `seal_low_mana`
- `seal_no_facility_disable`
- `seal_contract_vanguard`
- `seal_adaptive_rival`

한 회차에 교리·칙령·인장을 각각 하나 선택한다.

### 2.6 레온 적응 자세 4종

| ID | 예고 분석 | DAY 30 적용 방향 |
|---|---|---|
| `leon_stance_siege` | 시설 의존이 높음 | 시설 압박 |
| `leon_stance_pursuit` | 후열 화력이 높음 | 후열 추격 |
| `leon_stance_purification` | 회복·보호가 높음 | 강화 해제·회복 억제 |
| `leon_stance_duelist` | 직접 화력이 높음 | 결투·반격 |

DAY 24에는 선택된 자세와 약점을 함께 예고하고 DAY 30 재도전에서는 같은 자세를 유지한다.

### 2.7 엔딩 E00~E11

기존 엔딩 ID는 유지하고 `catalog_code`만 부여한다.

| 코드 | 엔딩 ID | 상태 |
|---|---|---|
| E00 | `true_demon_castle` | 기존 |
| E01 | `monster_family_castle` | 기존 |
| E02 | `impregnable_demon_citadel` | 기존 |
| E03 | `dread_overlord_rises` | 기존 |
| E04 | `demon_hero_rival_pact` | 기존 |
| E05 | `contract_monster_alliance` | 신규 |
| E06 | `royal_doctrine_broken` | 신규 |
| E07 | `challenge_seal_legend` | 신규 |
| E08 | `evelyns_counterledger` | 신규 |
| E09 | `adaptive_rival_mastery` | 신규 |
| E10 | `castle_without_reserves` | 신규 |
| E11 | `twelve_endings_chronicle` | 신규 메타 엔딩 |

E11은 현재 회차 조건과 프로필 누적 조건을 함께 사용하며, E00~E10 도감 기록 뒤 다음 회차에서 도달 가능하게 한다.

## 3. 저장 v3 최소 계약

### 3.1 envelope

- `version = 3`
- `campaign_final_day = 30`
- `summary`
- `profile`
- `active_run`
- 임시 파일 기록 → 재검증 → 기존 파일 백업 → 안전 교체 → 최종 재검증

### 3.2 profile 추가 필드

- `profile_version = 2`
- `unlocked_contract_ids`
- `contract_history`
- `ending_archive`
- `ending_catalog_codes`
- `active_doctrine_id`, `doctrine_history`
- `active_decree_id`, `decree_history`
- `active_challenge_seal_id`, `challenge_seal_history`
- `leon_stance_history`
- `completed_cycles`

### 3.3 active_run 추가 필드

- `cycle_seed`
- `contract_board_offer_ids`
- `selected_contract_ids`
- `deployed_instance_ids`
- `reserve_instance_ids`
- `stage_deployment_limit`
- `event_deck_order`
- `wave_variant_ids`
- `leon_adaptation`
- `run_metrics`
- `legacy_payload`

## 4. 재구성 단계와 통과 게이트

| 단계 | 범위 | 필수 증거 |
|---|---|---|
| R0 | 본 계약과 ID 고정 | 문서·충돌 검사 |
| R1 | 저장 v3·v2→v3 | 무손실 왕복·손상 복구 검사 |
| R2 | 계약 게시판·5종·출전/예비 | 회차당 2종·Stage 한도 전투 적용 검사 |
| R3 | 대응 적 6종·에블린 | 데이터·행동·그래픽·소프트 카운터 검사 |
| R4 | 교리·칙령·인장 각 6종 | 새 회차 선택·적용·저장 검사 |
| R5 | seed 이벤트 덱·웨이브 변형 | 동일 seed 동일 결과·다른 seed 변화 검사 |
| R6 | 레온 자세 4종 | DAY 24 예고·DAY 30 적용·재도전 유지 검사 |
| R7 | E00~E11·도감 | 조건식·우선순위·도달성·도감 저장 검사 |
| R8 | 30일 저장·그래픽 계약 | 자동 저장·이어하기·새 회차·SOURCE·프레임 검사 |
| R9 | 전체 통합·재감사 | 전체 핵심 검증 PASS·차단 목록 0 |

## 5. 결정 로그

| ID | 결정 | 이유 |
|---|---|---|
| U2R-D001 | 3차 문서 1.1을 2차 완료 계약으로 사용 | 원본 2차 문서가 없고 사용자가 재구성을 승인 |
| U2R-D002 | 모리·돌콩·두둠·루미·미미를 계약 5종으로 고정 | 3차 합동기 데이터가 이름과 역할을 직접 참조 |
| U2R-D003 | 기존 5개 엔딩 ID 유지 | 저장 v2 도감과 기존 테스트 호환 |
| U2R-D004 | 신규 7개 엔딩을 더해 E00~E11 구성 | 3차 문서의 기존 엔딩 12개 계약 충족 |
| U2R-D005 | v3를 profile/active_run 분리 구조로 구현 | 3차 저장 v4 마이그레이션 전제와 일치 |
| U2R-D006 | 신규 대응 적은 3차의 성광·길드 적 6종과 분리 | 3차 신규 적 수량 계약 보존 |
