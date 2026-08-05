# V1.2.2 V2-P4A `spore_healer` 기본 전투 자산

## 패킷 카드

- `PACKET_ID`: `V2-P4A-ASSET-SPORE`
- `GOAL`: 모리(`spore_healer`) 기본 계약 전투 자산 1개만 생성하고 출처·런타임 시트를 기록
- `ALLOWED_WRITE_PATHS`: 모리 원본 1개, `SOURCE.md` 1개, 런타임 시트 1개, 이 QA, 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 제품 데이터·코드 연결, 다른 캐릭터, 초상화·VFX·오디오, CONNECT 패킷
- `DIRECT_TEST`: 4×4/16셀/행 계약, 투명도·크로마 잔류·파일 해시 검사
- `UI_OR_AUDIO_CHECK`: 없음 — 자산 생성 패킷
- `STOP_AFTER`: 자산과 직접 검수 기록 후 중단

## 결과

`ASSET_PASS_WITH_CONNECT_PENDING`.

모리 기본 전투 원본과 192×192 셀 16프레임 런타임 시트를 만들었다. 런타임 행 순서는 `Unit.gd`의 계약과 동일하게 1행 `idle_down 2 + down 2`, 2행 `move_down 4`, 3행 `attack_down 4`, 4행 `skill_down 4`다. 초상화·VFX·오디오와 제품 데이터 연결은 실행하지 않았다.

첫 번째 생성 결과는 불규칙한 배치라 폐기했고, 두 번째 결과는 4×4였지만 행별 의미가 런타임 계약과 어긋나 폐기했다. 세 번째 생성 결과만 배치·행 계약을 통과해 사용했다.

## 변경 자산

| 역할 | 경로 | 형식/크기 | SHA-256 앞 16자 |
|---|---|---|---|
| 생성 원본 | `assets/source/imagegen/update4_contract_monsters/mori/mori_combat_sheet_chroma_2026-08-02.png` | RGB 1254×1254 / 1,780,105 bytes | `50b729d38f28098a` |
| 런타임 시트 | `assets/sprites/monsters/update4/monster_mori_sheet.png` | RGBA 768×768, 셀 192×192 / 643,516 bytes | `675a6497ff47ea50` |
| 출처 기록 | `assets/source/imagegen/update4_contract_monsters/mori/SOURCE.md` | 생성·후처리·검수 메타데이터 | — |

## 직접 검사

- 원본 크기 `1254×1254`, 4열×4행 경계와 일치.
- 런타임 크기 `768×768`, 4열×4행 `192×192` 셀 계약 통과.
- 16개 셀 모두 보이는 픽셀을 포함한다.
- 런타임 시트는 RGBA이며 투명 배경이다.
- 순수 크로마 잔류 검사(`alpha >= 24`, `green >= 100`, `red <= 25`, `blue <= 25`) 결과 0개.
- 최종 런타임 이미지를 `1280×720` 게임 화면에 연결하는 작업은 다음 CONNECT 패킷으로 분리했다.

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4A-CONNECT-SPORE`
- 목표: 승인된 모리 런타임 시트 1개만 profile/runtime에 연결하고 직접 계약 검사
- 이번 패킷에서 실행하지 않은 항목: `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 씬, UI·실플레이 연결

## 검수 상태

- `Related tests`: 4×4/16셀/행 계약, 투명도, 크로마 잔류 0, 파일 해시 검사 PASS
- `UI check`: CONNECT 패킷 전이라 실행하지 않음
- `Unresolved issues`: 제품 데이터가 아직 기존 슬라임 경로를 참조하므로, CONNECT 패킷 전에는 모리 기본 전투 자산이 게임에 표시되지 않음
