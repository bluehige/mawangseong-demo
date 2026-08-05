# V1.2.2 V2-P4B `stone_sentinel` 기본 전투 자산

## 패킷 카드

- `PACKET_ID`: `V2-P4B-ASSET-STONE`
- `GOAL`: 돌콩(`stone_sentinel`) 기본 계약 전투 자산 1개만 생성하고 출처·런타임 시트를 기록
- `ALLOWED_WRITE_PATHS`: 돌콩 원본 1개, `SOURCE.md` 1개, 런타임 시트 1개, 이 QA, 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 제품 데이터·코드 연결, 다른 캐릭터, 초상화·VFX·오디오, CONNECT 패킷, 공통 V3 정규화
- `DIRECT_TEST`: 4×4/16셀/행 계약, 투명도·크로마 잔류·파일 해시 검사
- `UI_OR_AUDIO_CHECK`: 없음 — 자산 생성 패킷
- `STOP_AFTER`: 자산과 직접 검수 기록 후 중단

## 결과

`ASSET_PASS_WITH_CONNECT_PENDING`.

돌콩 전용 기본 계약 전투 원본과 192×192 셀 16프레임 런타임 시트를 만들었다. 돌콩을 회색 현무암 석상 파수꾼으로 분리해 슬라임·푸딩·버섯·고블린과 실루엣이 겹치지 않도록 했으며, 초상화·VFX·오디오·제품 데이터 연결은 실행하지 않았다.

## 변경 자산

| 역할 | 경로 | 형식/크기 | SHA-256 앞 16자 |
|---|---|---:|---|
| 생성 원본 | `assets/source/imagegen/update4_contract_monsters/dolkong/dolkong_combat_sheet_chroma_2026-08-04.png` | RGB 1254×1254 / 2,067,198 bytes | `bb48c0743d11506e` |
| 런타임 시트 | `assets/sprites/monsters/update4/monster_dolkong_sheet.png` | RGBA 768×768, 셀 192×192 / 847,767 bytes | `2843186f68430475` |
| 출처 기록 | `assets/source/imagegen/update4_contract_monsters/dolkong/SOURCE.md` | 생성·후처리·검수 메타데이터 | — |

## 직접 검사

- 원본 크기 `1254×1254 RGB`, 런타임 크기 `768×768 RGBA` 통과.
- 런타임 4열×4행의 16셀 모두 visible pixel을 포함한다.
- 16개 셀의 런타임 프레임 해시가 모두 달라 중복 프레임이 없다.
- 네 모서리 알파가 모두 `0`이며, 셀별 투명 여백이 유지된다.
- 순수 크로마 잔류 검사(`alpha >= 24`, `green >= 100`, `red <= 25`, `blue <= 25`) 결과 `0개`.
- 녹색 우세 잔류 검사(`alpha >= 24`, `green - red >= 60`, `green - blue >= 60`) 결과 `0개`.
- 생성 원본과 투명 런타임 시트를 실제 이미지로 확인했다. 런타임에는 회색 석상 실루엣과 절제된 호박색 눈·스킬 광원이 남고 녹색 배경은 제거됐다.
- 제품 데이터와 `combat_visual_profiles.json` 연결은 다음 CONNECT 패킷으로 분리했다.

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4B-CONNECT-STONE`
- 목표: 돌콩 런타임 시트 1개만 `data/monsters.json`과 `data/v122/combat_visual_profiles.json`에 연결하고 직접 계약 검사
- 실행하지 않은 항목: 제품 연결, 렌더 배율·접지 앵커 계산, `1280×720` 대표 화면 확인
- 이 제안은 다음 turn의 카드일 뿐이며, 현재 turn에서는 실행하지 않는다.

## 검수 상태

- `Related tests`: 4×4/16셀/행 계약, RGBA 투명도, 순수 크로마 0, 녹색 우세 0, 중복 해시 0, SHA-256 검사 PASS
- `UI check`: CONNECT 패킷 전이라 실행하지 않음
- `Unresolved issues`: 제품 데이터와 visual profile이 아직 기존 슬라임 경로를 참조하므로, `V2-P4B-CONNECT-STONE` 전에는 게임에서 돌콩 전용 그림이 표시되지 않음
