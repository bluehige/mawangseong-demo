# v1.2.2 V2-P4D `mimic_porter` 자산 직접 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4D-ASSET-MIMIC`
- `GOAL`: 미미 전용 기본 전투 자산 1개를 만들고 출처와 런타임 시트를 기록
- `ALLOWED_WRITE_PATHS`: 미미 원본 폴더, 미미 런타임 PNG, 이 QA 문서, 패킷 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 제품 데이터/profile 연결, 다른 캐릭터, 공통 코드, 씬, 초상화, VFX, 오디오, 다음 패킷
- `DIRECT_TEST`: 생성 원본·SOURCE.md·4×4 16프레임 RGBA 런타임 시트의 셀 경계·중앙값·공통 발 기준선 검사
- `UI_OR_AUDIO_CHECK`: 없음(자산 생성 패킷)
- `STOP_AFTER`: 미미 자산 1개와 직접 검수 문서화 후 중단

## 결과

`ASSET_PASS_WITH_CONNECT_PENDING`

미미를 기존 고블린 공유 이미지와 분리된 보물상자형 캐릭터로 생성했다. 원본은 1254×1254 RGB, 런타임은 768×768 RGBA이며, 192×192 셀 16개를 모두 채웠다. 기술 행의 효과는 캐릭터에 밀착된 황금 방어막으로 제한해 셀 경계를 침범하지 않는다.

## 변경 자산

| 역할 | 경로 | 형식/크기 | SHA-256 앞 16자리 |
|---|---|---:|---|
| 생성 원본 | `assets/source/imagegen/update4_contract_monsters/mimi/mimi_combat_sheet_chroma_2026-08-04.png` | RGB 1254×1254 / 1,780,131 bytes | `92db92e6d77d1b84` |
| 런타임 시트 | `assets/sprites/monsters/update4/monster_mimi_sheet.png` | RGBA 768×768, 셀 192×192 / 746,989 bytes | `b9cec0d3405d76e6` |
| 출처 기록 | `assets/source/imagegen/update4_contract_monsters/mimi/SOURCE.md` | 생성·후처리·연결 범위 | - |

## 직접 검수 결과

- 원본 `RGB 1254×1254`, 런타임 `RGBA 768×768`: PASS
- 4×4 셀의 16프레임 모두 visible: `16/16`, PASS
- 16프레임 고유성: `16/16`, PASS
- 런타임 셀 외곽(알파 > 32) 침범: `0`, PASS
- 공통 발 기준선: 모든 셀 `bottom=183`, spread `0px`, PASS
- 런타임 중앙값 캐릭터 높이: `146.5px`
- 크로마키 잔류 검사(`alpha >= 24`, `green >= 100`, `red <= 25`, `blue <= 25`): `0px`, PASS
- 시각 확인: 보물상자형 미미, idle/down·이동·벌림 공격·황금 방어막 기술 행을 확인, PASS

## 실행한 직접 테스트

Pillow 기반 단일 자산 검사로 원본/런타임 모드·크기, 셀별 alpha bbox, 고유 프레임 수, 외곽 알파, 공통 발 기준선, 초록색 잔류 픽셀을 확인했다.

`MIMI_ASSET_DIRECT_TEST: PASS`

## 다음 패킷 제안

- `NEXT_PACKET_ID_PROPOSAL`: `V2-P4D-CONNECT-MIMIC`
- 목표: 미미 런타임 시트를 `data/monsters.json`과 `data/v122/combat_visual_profiles.json`에 1개 항목만 연결하고 직접 계약 검사를 수행
- 이번 turn에서는 다음 패킷을 실행하지 않는다.

## 검수 상태

- 전체 회귀/전체 플레이 검수: `NOT_REQUESTED` (자산 단일 패킷)
- 미해결: 제품 데이터 연결 전이므로 실제 전투 표시 확인은 다음 CONNECT 패킷에 남음
- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
