# v1.2.2 V2-P4D `mimic_porter` 원본 발견 조사

## 패킷 카드

- `PACKET_ID`: `V2-P4D-DISCOVER-MIMIC`
- `GOAL`: 미미(`mimic_porter`)의 현재 공유 전투 그림과 저장소 안의 전용 원본 후보를 읽기 전용으로 판정
- `ALLOWED_WRITE_PATHS`: 이 QA 문서, 패킷 핸드오프, `docs/handoff/CURRENT.md`
- `FORBIDDEN`: 자산 생성·후처리·데이터/profile 연결, 공통 코드·씬·초상화·VFX·오디오, 다음 패킷
- `DIRECT_TEST`: `mimic_porter` 참조 경로·원본 후보·파일 형식 교차 검사
- `UI_OR_AUDIO_CHECK`: 없음(발견 전용 패킷)
- `STOP_AFTER`: 미미 조사 결과와 다음 패킷 제안만 남기고 중단

## 결론

`DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

미미는 현재 `goblin`과 같은 `monster_goblin_idle_down_00.png`를 전투 그림으로 공유한다. 계약·저장 식별자와 역할 데이터는 정상이나, 미미의 가짜 보물·유인 역할을 표현하는 전용 전투 원본과 `SOURCE.md`는 현재 작업 트리에서 찾지 못했다. 다음 패킷에서 미미 전용 4×4 전투 시트를 새로 만들 수 있으며, 이번 패킷에서는 어떤 자산도 생성하거나 연결하지 않았다.

## 현재 연결 상태

| 확인 위치 | 현재 값 | 판정 |
|---|---|---|
| `data/monsters.json` → `mimic_porter.sprite` | `res://assets/sprites/monsters/monster_goblin_idle_down_00.png` | `goblin`과 공유하는 일반 고블린 그림 |
| `data/monsters.json` → `goblin.sprite` | 같은 경로 | 공유 원인 확인 |
| `data/v122/combat_visual_profiles.json` → `unit_overrides.mimic_porter` | `contract_mimic_porter`, `normal_grounded`, 중앙값 `150.0px`, source/runtime 모두 같은 고블린 경로 | `NEEDS_NORMALIZATION`, 전용 정체성 미승인 |
| `data/monsters.json` → `war_drummer.sprite` | 두둠 전용 런타임 시트 | 두둠 연결 뒤 미미와의 3-way 공유는 해소됨 |
| `data/monster_instances.json` → `mon_contract_mimi` | `species_id=mimic_porter`, `character_id=CHR_MIMI` | 계약 식별자 정상 |
| `data/update2_contracts.json` → `mimic_porter` | 미미·미믹 짐꾼·가짜 보물·유인 | 전투 역할 정상 |
| `data/characters.json` → `CHR_MIMI` | `unit_ref.id=mimic_porter` | 캐릭터-유닛 연결 정상 |

## 후보 분류

| 후보 | 파일 형식·크기 | 소유권/충돌 | 결정 |
|---|---|---|---|
| `assets/source/imagegen/mimi/SOURCE.md` | 파일 없음 | 예정된 원본 기록이 현재 저장소에 없음 | 전용 자산 후보 아님, 새 출처 기록 필요 |
| `assets/sprites/monsters/monster_mimi_idle_down_00.png` | 파일 없음 | 전용 런타임 파일 없음 | 전용 자산 후보 아님, 새 시트 필요 |
| `assets/source/imagegen/update4_contract_monsters/mimi/` | 디렉터리 없음 | Update 4 계약 자산 원본 미등록 | 새 자산 패킷에서 생성 |
| `sheet_goblin_vault_keeper_4x4_chroma.png` → `monster_goblin_vault_keeper_idle_down_00.png` | 1254×1254 RGB → 192×192 RGBA | `data/evolution_rules.json`에서 `monster_id=goblin`인 금고지기 곱 진화 전용 | 미미에 재사용 금지 |
| `enemy_ledger_binder_sheet_2026-07-13.png` → `enemy_monster_binder_idle_down_00.png` | 1254×1254 RGB → 192×192 RGBA | `data/enemies.json`의 적 `monster_binder` 전용 | 아군 미미에 재사용 금지 |
| `assets/sprites/rooms/prop_treasure_pile_01.png` | 128×128 RGBA | 보물실 환경 소품, 유닛 애니메이션 시트 아님 | 런타임 유닛 후보 아님 |
| `assets/source/imagegen/castle_stage04/treasure_stage04_green.png` | 1402×1122 RGB | 성 보물실 환경 원본, 캐릭터 프레임 아님 | 런타임 유닛 후보 아님 |

## 현재 공유 파일 형식 검사

`assets/sprites/monsters/monster_goblin_idle_down_00.png`는 `192×192 RGBA`, 63,399바이트, SHA-256 앞 16자 `e5ee8576e82644eb`다. alpha `>32` 기준 전경 bbox는 `(23,22)-(162,178)`이며, 미미 전용 시트가 아니라 일반 고블린 단일 프레임이다.

파일명과 출처 경로에서 `mimi`, `mimic`, `porter`를 포함하는 전용 PNG·`SOURCE.md`는 0개였다. 오래된 설계 문서의 `assets/source/imagegen/mimi/SOURCE.md` 경로는 설계 기록일 뿐 실제 파일로 확인되지 않는다.

## 직접 검수

- JSON 파싱 및 `mimic_porter`·계약·캐릭터 참조 교차 검사: PASS
- 공유 고블린 파일 존재·192×192 RGBA·SHA-256·알파 bbox 검사: PASS
- 미미 전용 파일명·출처 경로 부재 확인: PASS
- 고블린 금고지기 진화 소유권 분류: PASS(미미에 재사용 금지)
- 적 `monster_binder` 소유권 분류: PASS(미미에 재사용 금지)
- 보물실 환경 소품·원본의 유닛 시트 부적합 분류: PASS
- 전체 회귀·UI 플레이·빌드: 사용자 요청 범위가 아니므로 실행하지 않음

## 다음 패킷

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4D-ASSET-MIMIC`
- 목표: 미미 기본 계약 전투 자산 1개만 GPT 내부 이미지 생성으로 만들고, 생성 원본·`SOURCE.md`·4×4 런타임 시트를 기록
- 제안 런타임 경로: `assets/sprites/monsters/update4/monster_mimi_sheet.png`
- 이번 turn에서는 제안만 남기고 실행하지 않는다.

Review task ID: NOT_REQUESTED
Reviewed SHA: N/A
Remaining P1/P2: N/A
Final review result: TARGETED_PASS
