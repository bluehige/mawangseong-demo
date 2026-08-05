# v1.2.2 V2-P4B `stone_sentinel` 런타임 연결 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4B-CONNECT-STONE`
- `GOAL`: 승인된 돌콩 런타임 시트 1개를 제품 데이터와 전투 시각 프로필에 연결
- `ALLOWED_WRITE_PATHS`: `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 이 QA, 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 다른 캐릭터·공통 코드·씬·초상화·VFX·오디오·V3 정규화·다음 패킷
- `DIRECT_TEST`: 돌콩 데이터/profile/runtime 경로, 투명 시트·배율·접지 앵커 검사
- `UI_OR_AUDIO_CHECK`: 검수용 `1280×720` 화면에서 돌콩 크기와 바닥선 위치 확인
- `STOP_AFTER`: 돌콩 연결과 직접 검수 후 중단

## 결과

`CONNECT_PASS_WITH_NORMALIZATION_PENDING`.

돌콩(`stone_sentinel`)이 더 이상 공유 슬라임 그림을 사용하지 않고 전용 런타임 시트를 사용하도록 연결했다. 전용 시트의 측정 중앙값은 `170.5px`, large grounded 목표 높이는 `97.1898px`, 렌더 배율은 `0.570028`이다. 최종 동작별 발끝 정규화는 공통 V3 범위이므로 `NEEDS_NORMALIZATION` 상태를 유지했다.

## 변경 경로

| 경로 | 변경 내용 |
|---|---|
| `data/monsters.json` | `stone_sentinel.sprite`를 `res://assets/sprites/monsters/update4/monster_dolkong_sheet.png`로 변경 |
| `data/v122/combat_visual_profiles.json` | 돌콩 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `170.5px` 중앙값 연결 |
| `assets/sprites/monsters/update4/monster_dolkong_sheet.png` | 앞선 ASSET 패킷에서 만든 승인된 768×768 RGBA 런타임 시트 사용 |

## 직접 검수

- 두 JSON 파일 파싱 및 `stone_sentinel` sprite/profile/runtime 경로 일치: PASS
- 돌콩 런타임 시트: `768×768`, RGBA, 192×192 셀 16개: PASS
- 셀별 알파 경계 침범: `0개`
- 셀별 그림 높이 중앙값: `170.5px`
- 순수 크로마 잔류 픽셀: `0개`
- 녹색 우세 잔류 픽셀: `0개`
- 돌콩 렌더 배율: `97.1898 / 170.5 = 0.570028`
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS
- `godot.cmd --headless --path . --scene C:/Users/blueh/AppData/Local/Temp/v122_p4b_stone_connect_check.tscn`: PASS

## 대표 화면

실제 OpenGL 호환 렌더링으로 `1280×720` 검수 장면을 실행했다. 돌콩 전용 시트가 `large grounded` 배율로 표시되고, 접지 기준선과 발·그림자 위치가 맞는 것을 확인했다.

- 캡처: `C:/Users/blueh/AppData/Local/Temp/v122_p4b_stone_connect_1280x720.png`
- 결과: PASS, 이미지 크기 `1280×720`
- Godot import 검사를 위해 만든 `.png.import` sidecar는 검수 후 저장소에서 제거했다.

## 미해결 및 다음 패킷

- 최종 동작별 발끝·그림자 정규화는 공통 V3 검수 전까지 남겨 둔다.
- 다른 계약 몬스터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 제안은 `V2-P4C-DISCOVER-WAR` 하나이며, 이 문서에서는 실행하지 않는다.

Related tests: JSON·profile/runtime 경로·170.5px 중앙값·RGBA/크로마 0·배율/접지 앵커·profile contract 직접 검사 PASS
UI check: `1280×720` 대표 화면에서 돌콩 전용 시트 크기와 grounded 기준선 확인 PASS
Unresolved issues: 최종 동작별 발 앵커 정규화는 V3 범위이며 다음 패킷은 `V2-P4C-DISCOVER-WAR` 하나로 잠금
