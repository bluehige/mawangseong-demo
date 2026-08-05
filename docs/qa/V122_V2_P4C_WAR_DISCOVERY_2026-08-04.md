# v1.2.2 V2-P4C `war_drummer` 원본 발견 조사

## 패킷 카드

- `PACKET_ID`: `V2-P4C-DISCOVER-WAR`
- `GOAL`: 두둠(`war_drummer`)이 현재 공유 중인 그림과 저장소 안의 전용 전투 원본 후보를 읽기 전용으로 판정
- `ALLOWED_WRITE_PATHS`: 이 QA 문서, 패킷 핸드오프, `docs/handoff/CURRENT.md`
- `FORBIDDEN`: 돌콩 후속 연결·다른 캐릭터 구현·제품 코드·데이터·씬·초상화·VFX·오디오·이미지 생성·다음 패킷 실행
- `DIRECT_TEST`: `war_drummer` 참조 경로·원본 후보·파일 형식 교차 검사
- `UI_OR_AUDIO_CHECK`: 없음 — 읽기 전용 발견 패킷
- `STOP_AFTER`: 두둠 조사 결과와 다음 패킷 제안만 남기고 중단

## 결론

`DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

두둠은 현재 `goblin`과 `mimic_porter`가 함께 사용하는 `monster_goblin_idle_down_00.png`를 전투 그림으로 공유한다. 두둠 전용 전투 원본·출처 기록·전용 런타임 시트는 현재 작업 트리에서 찾지 못했다. 예전 계획서에 남은 `monster_skeleton_drummer_down_01.png`와 `assets/source/imagegen/dudum/SOURCE.md`도 실제 파일로 존재하지 않는다.

따라서 이번 발견 패킷에서는 제품을 수정하지 않고, 다음 패킷을 `V2-P4C-ASSET-WAR` 하나로 제안한다. 이 패킷에서 두둠 전용 4×4 전투 시트를 만들기 전에는 공유 고블린 그림을 두둠의 정체성으로 승인하지 않는다.

## 현재 연결 확인

| 확인 위치 | 값 | 판정 |
|---|---|---|
| `data/monsters.json` → `war_drummer.sprite` | `res://assets/sprites/monsters/monster_goblin_idle_down_00.png` | `goblin`·`mimic_porter`와 공유하는 일반 고블린 그림 |
| `data/monsters.json` → `goblin.sprite` | 같은 경로 | 공유 원인 확인 |
| `data/monsters.json` → `mimic_porter.sprite` | 같은 경로 | 공유 원인 확인 |
| `data/v122/combat_visual_profiles.json` → `unit_overrides.war_drummer` | `contract_war_drummer`, `normal_grounded`, 중앙값 `150.0px`, source/runtime 모두 같은 고블린 경로 | `NEEDS_NORMALIZATION`, 전용 정체성 미승인 |
| `data/characters.json` → `CHR_DUDUM.portrait.base` | `res://assets/sprites/portraits/onboarding/portrait_gob.png` | 초상화 fallback이며 전투 원본 후보가 아님 |
| `data/monster_instances.json` → `mon_contract_dudum` | `species_id=war_drummer`, `character_id=CHR_DUDUM` | 계약·저장 식별자는 정상, 그래픽만 공유 상태 |
| `data/update2_contracts.json` → `war_drummer` | `mon_contract_dudum`, 표시명 두둠, 전투 북잡이 | 계약 역할 확인 |

## 기존 원본 후보 분류

| 후보 | 출처·런타임 | 읽기 결과 | 결정 |
|---|---|---|---|
| 현재 공유 고블린 idle | `assets/sprites/monsters/monster_goblin_idle_down_00.png` | 192×192 RGBA, 세 계약 ID 공유, 두둠 전용 `SOURCE.md` 없음 | 기본 자산 후보 아님 |
| 옛 계획의 해골 북잡이 | `assets/sprites/monsters/monster_skeleton_drummer_down_01.png` | 파일 없음 | 후보 아님, 신규 생성 필요 |
| 옛 계획의 두둠 출처 기록 | `assets/source/imagegen/dudum/SOURCE.md` | 파일 없음 | 후보 아님, 신규 출처 기록 필요 |
| 고블린 매복대장 진화 | `assets/source/imagegen/evolutions/sheet_goblin_ambush_captain_4x4_chroma.png` → `assets/sprites/monsters/monster_goblin_ambush_captain_idle_down_00.png` | `SOURCE.md`가 매복대장 곱의 진화형으로 명시 | 두둠 전투에 재사용 금지 |
| 고블린 금고지기 진화 | `assets/source/imagegen/evolutions/sheet_goblin_vault_keeper_4x4_chroma.png` → `assets/sprites/monsters/monster_goblin_vault_keeper_idle_down_00.png` | `SOURCE.md`가 금고지기 곱의 진화형으로 명시 | 두둠 전투에 재사용 금지 |
| `CHR_DUDUM` 초상 fallback | `assets/sprites/portraits/onboarding/portrait_gob.png` | 512×512 RGB 초상화 | 전투 시트 후보 아님 |

## 파일 해시 및 형식 검사

직접 검사는 이미지를 승인하는 렌더 검수가 아니라 JSON 참조와 파일 소유·형식이 서로 맞는지 확인하는 읽기 전용 검사다.

| 파일 | 크기/형식 | SHA-256 앞 16자 | 출처 대응 |
|---|---:|---|---|
| `assets/sprites/monsters/monster_goblin_idle_down_00.png` | 192×192 RGBA / 63,399 bytes | `e5ee8576e82644eb` | `goblin`·`war_drummer`·`mimic_porter`의 현재 sprite와 두둠 profile source/runtime이 모두 가리킴; 알파 bbox `(23,22)-(163,179)` |
| `assets/source/imagegen/evolutions/sheet_goblin_ambush_captain_4x4_chroma.png` | 1254×1254 RGB / 2,188,025 bytes | `3ed177261cee9971` | `evolutions/SOURCE.md`의 매복대장 곱 진화 전용 |
| `assets/sprites/monsters/monster_goblin_ambush_captain_idle_down_00.png` | 192×192 RGBA / 44,998 bytes | `86058927f950a567` | 같은 진화의 런타임 |
| `assets/source/imagegen/evolutions/sheet_goblin_vault_keeper_4x4_chroma.png` | 1254×1254 RGB / 2,275,161 bytes | `3326d2f38f74c912` | `evolutions/SOURCE.md`의 금고지기 곱 진화 전용 |
| `assets/sprites/monsters/monster_goblin_vault_keeper_idle_down_00.png` | 192×192 RGBA / 50,544 bytes | `10b0a4dcf7239904` | 같은 진화의 런타임 |
| `assets/sprites/portraits/onboarding/portrait_gob.png` | 512×512 RGB / 387,491 bytes | `7b842d2318cfa811` | `CHR_DUDUM` 초상화 fallback |

`assets/source/imagegen`과 `assets/sprites/monsters`에서 `dudum`, `drummer`, `skeleton_drummer`, `war_drummer` 토큰을 포함하는 두둠 전용 파일은 0개였다. 예전 계획서의 파일명은 설계 기록일 뿐 현재 자산으로 확인할 수 없다.

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4C-ASSET-WAR`
- 목표: 두둠 기본 계약 전투 자산 1개만 GPT 내부 이미지 생성 모델로 만들고, 생성 원본·`SOURCE.md`·192×192 셀 16프레임 런타임 시트를 기록
- 다음 패킷 허용 경로: `assets/source/imagegen/update4_contract_monsters/dudum/dudum_combat_sheet_chroma_2026-08-04.png`, 같은 폴더의 `SOURCE.md`, `assets/sprites/monsters/update4/monster_dudum_sheet.png`, 이 패킷의 QA·핸드오프·`CURRENT.md`
- 실행하지 않은 항목: 이미지 생성, 크로마 제거, 런타임 연결, 데이터·코드 수정, 화면 확인
- 이 제안은 다음 turn의 카드일 뿐이며, 현재 turn에서는 실행하지 않는다.

## 검수 상태

- `DIRECT_TEST`: JSON의 세 데이터셋·profile 참조 교차 확인, 공유 파일 존재·SHA-256·이미지 형식·전용 토큰 검색 PASS
- `UI_OR_AUDIO_CHECK`: 없음 — 읽기 전용 발견 패킷
- `Related tests`: `war_drummer`·`goblin`·`mimic_porter` 경로, 계약/초상 fallback, 옛 계획 경로, 진화 후보 소유권 검사 PASS
- `UI check`: 실행하지 않음
- `Unresolved issues`: 두둠 전용 기본 전투 원본이 없고 현재는 고블린 그림을 공유하므로 `V2-P4C-ASSET-WAR` 전에는 전투 정체성을 승인할 수 없음
