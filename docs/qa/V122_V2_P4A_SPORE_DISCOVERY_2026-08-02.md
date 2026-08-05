# V1.2.2 V2-P4A `spore_healer` 원본 발견 조사

## 패킷 카드

- `PACKET_ID`: `V2-P4A-DISCOVER-SPORE`
- `GOAL`: `spore_healer`가 공유 중인 이미지와 저장소 안의 기존 원본 후보만 읽기 전용으로 조사
- 제품 쓰기: 0
- 조사 범위: 현재 참조 경로·파일 해시·원본 출처 대응
- 금지: 제품 코드·데이터·씬·런타임 자산 수정, 이미지 생성·후처리·연결, 다른 캐릭터 조사

## 결론

`DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

`spore_healer`(표시명 모리)의 기본 전투 자산으로 승인할 기존 원본은 찾지 못했다. 현재 기본 전투 그림은 `slime`, `spore_healer`, `stone_sentinel`이 같은 슬라임 idle 파일을 공유한다. 모리 정체성이 확인되는 기존 그림은 왕관 진화형뿐이며, 기본 계약 전투에 바로 연결하면 왕관 단계와 기본 단계를 섞게 된다.

따라서 다음 패킷 제안은 `V2-P4A-ASSET-SPORE` 하나뿐이다. 이 보고서에서는 자산 생성·후처리·런타임 연결을 실행하지 않았다.

## 현재 연결 확인

| 확인 위치 | 값 | 판정 |
|---|---|---|
| `data/monsters.json` → `spore_healer.sprite` | `res://assets/sprites/monsters/monster_slime_idle_down_00.png` | 모리 전용이 아닌 공유 슬라임 그림 |
| `data/monsters.json` → `slime.sprite` | 같은 경로 | 공유 원인 확인 |
| `data/monsters.json` → `stone_sentinel.sprite` | 같은 경로 | 공유 ID 3개 확인 |
| `data/v122/combat_visual_profiles.json` → `unit_overrides.spore_healer` | `asset_id=contract_spore_healer`, `source_path`와 `runtime_path` 모두 같은 슬라임 idle | `NEEDS_NORMALIZATION`, 정체성 미승인 |
| `docs/qa/V122_F0V_VISUAL_INVENTORY_2026-08-02.md` | 모리 행에 `3개 ID 공유` | 기존 시각 감사와 일치 |

## 기존 원본 후보 분류

| 후보 | 출처·런타임 | 읽기 결과 | 결정 |
|---|---|---|---|
| 현재 슬라임 idle | `assets/sprites/monsters/monster_slime_idle_down_00.png` / 동일 런타임 경로 | 192×192 RGBA, 모리·슬라임·돌콩 공유, 별도 모리 `SOURCE.md` 없음 | 기본 자산 후보 아님 |
| 모리 왕관 전투 시트 | `assets/source/imagegen/update4_crowns/mori/crown_mori_combat_sheet_chroma_2026-07-14.png` → `assets/sprites/monsters/update4/crowns/monster_mori_crown_priest_sheet.png` | `SOURCE.md`가 모리 정체성을 명시한다. `crown_evolutions.json`에서 `crown_mori_grand_mycelial_priest`의 `monster_id`가 `spore_healer`다. 그러나 왕관 진화 전용 16프레임 시트다. | 정체성 참고로 보존, 기본 전투 연결 금지 |
| 구조 연금 젤 푸딩 진화 | `assets/source/imagegen/evolutions/sheet_slime_rescue_alchemy_gel_4x4_{chroma,alpha}.png` → `assets/sprites/monsters/monster_slime_rescue_alchemy_gel_*` | `assets/source/imagegen/evolutions/SOURCE.md`가 슬라임 진화형·구조 연금 젤 푸딩으로 기록한다. 모리 계약 ID와 무관하다. | 정체성 불일치로 제외 |
| `spore_doll` 지역 적 | `assets/source/imagegen/update4_region_enemies/spore_doll_combat_sheet_chroma_2026-07-27.png` | 적 캐릭터 원본이며 모리 계약 아군이 아니다. | 정체성·진영 불일치로 제외 |

## 파일 해시 및 경로 검사

직접 검사는 이미지 내용을 승인하기 위한 렌더 검수가 아니라, 현재 참조와 원본 기록이 서로 어떤 파일을 가리키는지 확인하는 읽기 전용 검사다.

| 파일 | 크기/형식 | SHA-256 앞 16자 | 출처 대응 |
|---|---:|---|---|
| `assets/sprites/monsters/monster_slime_idle_down_00.png` | 192×192 RGBA / 52,209 bytes | `90b0242d0cac4bee` | `data/monsters.json`와 profile의 현재 런타임·source 양쪽이 가리킴 |
| `assets/source/imagegen/update4_crowns/mori/crown_mori_combat_sheet_chroma_2026-07-14.png` | 1254×1254 RGB / 2,196,515 bytes | `c910630bf68bb808` | `assets/source/imagegen/update4_crowns/mori/SOURCE.md`에 기록 |
| `assets/sprites/monsters/update4/crowns/monster_mori_crown_priest_sheet.png` | 768×768 RGBA / 626,273 bytes | `43f49c2c8dcc6cfc` | 같은 `SOURCE.md`의 왕관 런타임 경로 |
| `assets/source/imagegen/evolutions/sheet_slime_rescue_alchemy_gel_4x4_chroma.png` | 1254×1254 RGB / 2,113,901 bytes | `8d363199dba633bd` | 진화 공통 `SOURCE.md`의 슬라임 진화 시트 |
| `assets/sprites/monsters/monster_slime_rescue_alchemy_gel_idle_down_00.png` | 192×192 RGBA / 44,330 bytes | `ec178747cec36c3d` | 진화 공통 `SOURCE.md`의 런타임 규칙 |

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4A-ASSET-SPORE`
- 목표: 모리 기본 계약 전투 자산 1개만 GPT 내부 이미지 생성 모델로 만들고, 생성 원본·`SOURCE.md`·런타임 시트 1개를 기록
- 실행하지 않은 항목: 생성, 크로마 제거, 런타임 연결, 화면 확인
- 이 제안은 다음 turn의 카드일 뿐이며, 현재 turn에서는 실행하지 않는다.

## 검수 상태

- `DIRECT_TEST`: 현재 참조 경로·파일 해시·원본 출처 대응 검사 PASS
- `UI_OR_AUDIO_CHECK`: 없음 — 읽기 전용 발견 패킷
- `Related tests`: JSON 경로 교차 확인, 파일 존재·SHA-256·이미지 크기/알파 형식 확인 PASS
- `UI check`: 실행하지 않음
- `Unresolved issues`: 모리 기본 전투 원본이 없으므로 `V2-P4A-ASSET-SPORE` 전에는 기본 전투 정체성 승인을 할 수 없음
