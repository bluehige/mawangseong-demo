# V1.2.2 V2-P4B `stone_sentinel` 원본 발견 조사

## 패킷 카드

- `PACKET_ID`: `V2-P4B-DISCOVER-STONE`
- `GOAL`: 돌콩(`stone_sentinel`)이 공유 중인 그림과 저장소 안의 전용 원본 후보만 읽기 전용으로 조사
- `ALLOWED_WRITE_PATHS`: 이 QA 문서, 패킷 핸드오프, `docs/handoff/CURRENT.md`
- `FORBIDDEN`: 제품 코드·데이터·씬·런타임 자산 수정, 이미지 생성·후처리·연결, 모리·다른 캐릭터 조사
- `DIRECT_TEST`: `stone_sentinel` 참조 경로·원본 후보·파일 형식 교차 검사
- `UI_OR_AUDIO_CHECK`: 없음 — 읽기 전용 발견 패킷
- `STOP_AFTER`: 돌콩 조사 결과와 다음 패킷 제안만 남기고 중단

## 결론

`DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

돌콩의 현재 전투 그림은 `slime`과 같은 슬라임 idle 파일이다. 모리 연결 패킷이 끝난 현재 기준으로는 예전 인벤토리의 “3개 ID 공유”가 아니라 `slime`·`stone_sentinel` 두 ID가 공유한다. 돌콩 전용 전투 원본·출처 기록·전용 런타임 시트는 저장소에서 찾지 못했다.

따라서 다음 패킷은 `V2-P4B-ASSET-STONE` 하나만 제안한다. 이 보고서에서는 자산 생성·후처리·제품 연결을 실행하지 않았다.

## 현재 연결 확인

| 확인 위치 | 값 | 판정 |
|---|---|---|
| `data/monsters.json` → `stone_sentinel.sprite` | `res://assets/sprites/monsters/monster_slime_idle_down_00.png` | 돌콩 전용이 아닌 슬라임 그림 |
| `data/monsters.json` → `slime.sprite` | 같은 경로 | 현재 공유 원인 확인 |
| `data/monsters.json` → `spore_healer.sprite` | `res://assets/sprites/monsters/update4/monster_mori_sheet.png` | P4A 연결 이후 모리 경로는 분리됨 |
| `data/v122/combat_visual_profiles.json` → `unit_overrides.stone_sentinel` | source/runtime 모두 `monster_slime_idle_down_00.png` | `NEEDS_NORMALIZATION`, 정체성 미승인 |
| `data/characters.json` → `CHR_DOLKONG.portrait.base` | `res://assets/sprites/portraits/onboarding/portrait_pudding.png` | 전투 원본이 아닌 초상 fallback; 이번 자산 후보에서 제외 |

## 기존 원본 후보 분류

| 후보 | 출처·런타임 | 읽기 결과 | 결정 |
|---|---|---|---|
| 현재 슬라임 idle | `assets/sprites/monsters/monster_slime_idle_down_00.png` | 192×192 RGBA, `slime`·`stone_sentinel` 공유, 돌콩 `SOURCE.md` 없음 | 기본 자산 후보 아님 |
| 성문 방벽 푸딩 진화 | `assets/source/imagegen/evolutions/sheet_slime_gate_bulwark_4x4_chroma.png` → `assets/sprites/monsters/monster_slime_gate_bulwark_idle_down_00.png` | `data/evolution_rules.json`의 `monster_id`가 `slime`; `SOURCE.md`도 푸딩 진화형으로 기록 | 종족·계약 정체성 불일치로 제외 |
| 왕관성벽 푸딩 | `assets/source/imagegen/update4_crowns/pudding/crown_pudding_combat_sheet_chroma_2026-07-14.png` → `assets/sprites/monsters/update4/crowns/monster_slime_crown_bastion_sheet.png` | `crown_evolutions.json`의 `monster_id`가 `slime`; 왕관 단계 전용 | 돌콩 기본 전투에 재사용 금지 |
| 계획서에만 남은 옛 돌콩 경로 | `assets/source/imagegen/dolkong/SOURCE.md`, `monster_gargoyle_hatchling_skill_down_03.png` | 현재 작업 트리와 Git 이력에 파일이 없음; 출처·원본·런타임 검증 불가 | 후보 아님, 신규 생성 필요 |

## 파일 해시 및 경로 검사

직접 검사는 이미지 내용을 승인하는 렌더 검수가 아니라 현재 참조와 원본 기록이 서로 어떤 파일을 가리키는지 확인하는 읽기 전용 검사다.

| 파일 | 크기/형식 | SHA-256 앞 16자 | 출처 대응 |
|---|---:|---|---|
| `assets/sprites/monsters/monster_slime_idle_down_00.png` | 192×192 RGBA / 52,209 bytes | `90b0242d0cac4bee` | `data/monsters.json`의 `slime`·`stone_sentinel`, stone profile의 source/runtime이 모두 가리킴 |
| `assets/source/imagegen/evolutions/sheet_slime_gate_bulwark_4x4_chroma.png` | 1254×1254 RGB / 2,389,406 bytes | `2f7545efda7b7fdd` | 진화 공통 `SOURCE.md`; `slime` 진화 전용 |
| `assets/source/imagegen/evolutions/sheet_slime_gate_bulwark_4x4_alpha.png` | 1254×1254 RGBA / 2,028,993 bytes | `a72fe9746ea80fb8` | 같은 진화 시트의 투명화 원본 |
| `assets/sprites/monsters/monster_slime_gate_bulwark_idle_down_00.png` | 192×192 RGBA / 58,053 bytes | `c01c0227157bdca6` | `evolution_rules.json`의 `slime_gate_bulwark` 런타임 |
| `assets/source/imagegen/update4_crowns/pudding/crown_pudding_combat_sheet_chroma_2026-07-14.png` | 1254×1254 RGB / 2,489,392 bytes | `e5caf8a0e09b80ae` | 푸딩 왕관 `SOURCE.md`; 돌콩과 무관 |
| `assets/sprites/monsters/update4/crowns/monster_slime_crown_bastion_sheet.png` | 768×768 RGBA / 806,649 bytes | `cc13909542eb3b17` | 푸딩 왕관 런타임 |

`assets/source/imagegen`과 `assets/sprites/monsters`에서 `stone`, `dolkong`, `gargoyle`, `sentinel` 토큰을 포함하는 파일을 별도로 찾지 못했다. 이는 돌콩 전용 후보가 없다는 결론을 보강한다.

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4B-ASSET-STONE`
- 목표: 돌콩 기본 계약 전투 자산 1개만 GPT 내부 이미지 생성 모델로 만들고, 생성 원본·`SOURCE.md`·192×192 셀 16프레임 런타임 시트를 기록
- 다음 패킷 허용 경로: `assets/source/imagegen/update4_contract_monsters/dolkong/dolkong_combat_sheet_chroma_2026-08-04.png`, 같은 폴더의 `SOURCE.md`, `assets/sprites/monsters/update4/monster_dolkong_sheet.png`, 이 패킷의 QA·핸드오프·`CURRENT.md`
- 실행하지 않은 항목: 생성, 크로마 제거, 런타임 연결, 데이터·코드 수정, 화면 확인
- 이 제안은 다음 turn의 카드일 뿐이며, 현재 turn에서는 실행하지 않는다.

## 검수 상태

- `DIRECT_TEST`: JSON 참조 경로·profile source/runtime 일치, 파일 존재·SHA-256·이미지 크기/알파 형식, 전용 토큰 파일 검색 PASS
- `UI_OR_AUDIO_CHECK`: 없음 — 읽기 전용 발견 패킷
- `Related tests`: `stone_sentinel`·`slime`·`spore_healer` 경로 교차 확인, 후보 파일 존재·SHA-256·형식 검사 PASS
- `UI check`: 실행하지 않음
- `Unresolved issues`: 돌콩 기본 전투 원본이 없고 현재는 슬라임 그림을 공유하므로 `V2-P4B-ASSET-STONE` 전에는 전투 정체성을 승인할 수 없음
