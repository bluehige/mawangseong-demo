# v1.2.2 V2-P4E `moon_tracker` 전투 자산 발견 조사

## 패킷 카드

- `PACKET_ID`: `V2-P4E-DISCOVER-MOON`
- `GOAL`: 루미(`moon_tracker`)의 현재 공유 자산, 전투 전용 원본 후보, 출전 차단 조건을 읽기 전용으로 판정
- `ALLOWED_WRITE_PATHS`: 이 QA 문서, 패킷 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 루미 제품 데이터/profile 연결, 자산 생성·후처리, 다른 캐릭터, 공통 코드·씬·초상화·VFX·오디오, 다음 패킷
- `DIRECT_TEST`: 루미 데이터·계약·캐릭터 참조, 공유 자산 형식·해시, 전용 파일 존재 여부, 출전 차단 조건 교차 검사
- `UI_OR_AUDIO_CHECK`: 없음(읽기 전용 발견 패킷)
- `STOP_AFTER`: 발견 결과와 다음 자산 패킷 제안 문서화 후 중단

## 결과

`DISCOVERY_PASS_WITH_ASSET_REQUIRED`.

루미는 아직 전투용 정식 자산이 없다. `data/monsters.json`의 `moon_tracker`는 코볼트 핵심 종 `kobold_scout`와 같은 경로를 가리키며, 해당 PNG는 실제 전투 시트가 아니라 로로 초상 원본과 동일한 1254×1254 RGB 불투명 이미지다. 따라서 루미를 방어전에 내보내면 안 된다는 기존 차단 게이트가 올바르게 작동한다.

## 현재 참조와 계약 상태

| 항목 | 현재 값 | 판정 |
|---|---|---|
| `data/monsters.json` → `moon_tracker.sprite` | `res://assets/sprites/monsters/monster_kobold_scout_idle_down_00.png` | `kobold_scout`와 공유, 잘못된 정체성 |
| `data/monster_instances.json` → `mon_contract_lumi` | `species_id=moon_tracker`, `character_id=CHR_LUMI` | 계약 참조 정상 |
| `data/characters.json` → `CHR_LUMI` | `unit_ref.id=moon_tracker`, `combat_side=castle` | 캐릭터 참조 정상 |
| `data/update2_contracts.json` → `moon_tracker` | `mon_contract_lumi`, `CHR_LUMI`, `BLOCKED_WRONG_IDENTITY_SOURCE` | 출전 차단 상태 정상 |
| `data/v122/combat_visual_profiles.json` | `unit_overrides.moon_tracker` 없음 | 전용 profile 미등록, 연결 보류 |

## 원본·후보 조사

| 후보 | 측정/소유 | 판정 |
|---|---|---|
| `assets/sprites/monsters/monster_kobold_scout_idle_down_00.png` | RGB 1254×1254, 전체 불투명, SHA `fab1870a10b61da9`; `portrait_rolo.png`와 동일 파일 | 로로 초상/지원 자산. 루미 전투 자산으로 사용 금지 |
| `assets/source/imagegen/update3_enemy_atlases/enemy_bounty_tracker_sheet_chroma_2026-07-13.png` 및 적 런타임 | 인간 현상금 추적자, 적 진영 4×4 시트 | 계약 아군 루미와 정체성·소유권 불일치 |
| `assets/sprites/enemies/enemy_royal_scout_*` | 인간 왕실 척후 적 프레임 | 적 캐릭터를 루미로 재사용할 수 없음 |
| `assets/ui/regions/update4/emblem_moonbat_aerie.png`, `card_moonbat_aerie.png` | 문박쥐 지역 UI/환경 자산 | 전투 캐릭터가 아님 |
| `assets/source/imagegen/lumi/SOURCE.md`, 루미 전용 시트 파일명 | 저장소에서 찾지 못함 | 새 자산 생성 필요 |

## 직접 검수

- JSON 파싱 및 `moon_tracker`·`mon_contract_lumi`·`CHR_LUMI` 참조 교차 검사: PASS
- 현재 루미 sprite와 `kobold_scout` sprite 경로 일치 확인: PASS (문제 재현)
- 공유 PNG 형식: `RGB 1254×1254`, 알파 전체 `255`, 초상 원본과 SHA 일치: PASS (잘못된 자산 증거)
- `combat_visual_profiles.unit_overrides.moon_tracker` 부재 확인: PASS
- `moon_tracker`·`lumi_combat`·`lumi_sheet` 전용 파일명 탐색: `0개`, PASS
- 적/환경 후보 3종의 소유권·역할 불일치 판정: PASS
- `V122_P4E_MOON_DISCOVERY_DIRECT_TEST`: PASS
- `V122_MOON_TRACKER_COMBAT_ASSET_GATE_TEST`: PASS

Godot 직접 게이트 검사:

```text
godot.cmd --headless --path . --scene tools/tests/V122MoonTrackerCombatAssetGateTest.tscn --quit-after 30
V122_MOON_TRACKER_COMBAT_ASSET_GATE_TEST: PASS
```

## 결론과 다음 패킷

루미의 정체성을 보존하려면 GPT 내부 이미지 생성으로 루미 전용 4×4 전투 시트와 출처 기록을 먼저 만들어야 한다. 기존 로로 초상, 인간 척후 적, 현상금 추적자, 문박쥐 지역 자산을 대체품으로 연결하지 않는다.

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4E-ASSET-MOON`
- 목표: 루미 전용 기본 전투 자산 1개 생성·후처리·출처 기록
- 이번 turn에서는 자산 생성이나 제품 연결을 실행하지 않았다.

## 검수 상태

- 전체 회귀·전체 플레이·정식 빌드: `NOT_REQUESTED`
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
