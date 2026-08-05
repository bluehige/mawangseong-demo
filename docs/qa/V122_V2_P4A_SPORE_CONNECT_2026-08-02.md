# v1.2.2 V2-P4A `spore_healer` 런타임 연결 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4A-CONNECT-SPORE`
- `GOAL`: 승인된 모리 런타임 시트 1개를 제품 데이터와 전투 시각 프로필에 연결
- `ALLOWED_WRITE_PATHS`: `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 이 QA, 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 다른 캐릭터·공통 코드·초상화·VFX·오디오·다음 패킷
- `DIRECT_TEST`: 모리 데이터/profile/runtime 경로 계약, 투명 시트·배율·접지 앵커 검사
- `UI_OR_AUDIO_CHECK`: 검수용 `1280×720` 화면에서 모리 크기와 바닥선 위치 확인
- `STOP_AFTER`: 모리 연결과 직접 검수 후 중단

## 결과

`CONNECT_PASS_WITH_NORMALIZATION_PENDING`

모리(`spore_healer`)가 더 이상 공유 슬라임 그림을 사용하지 않고 전용 런타임 시트를 사용하도록 연결했다. 최종 동작별 발끝 정규화는 공통 V3 범위이므로 `NEEDS_NORMALIZATION` 상태를 유지했다.

## 변경 경로

| 경로 | 변경 내용 |
|---|---|
| `data/monsters.json` | `spore_healer.sprite`를 모리 4×4 런타임 시트로 변경 |
| `data/v122/combat_visual_profiles.json` | 모리 원본·런타임 경로, 투명 처리, 161px 중앙값, 런타임 준비 통과 상태 연결 |
| `assets/sprites/monsters/update4/monster_mori_sheet.png` | 승인된 768×768 RGBA 런타임 시트 사용 |

## 직접 검수

- 두 JSON 파일 파싱: PASS
- 모리 런타임 시트: `768×768`, RGBA, 192×192 셀 16개: PASS
- 셀별 알파 경계 침범: 0개
- 셀별 그림 높이 중앙값: `161.0px`
- 순수 크로마 잔류 픽셀: `0개`
- 모리 렌더 배율: `78.246 / 161.0 = 0.486`
- `godot.cmd --headless --path . --scene C:/Users/blueh/AppData/Local/Temp/v122_p4a_spore_connect_check.tscn`: PASS

## 대표 화면

`1280×720` 검수 장면에서 모리 전용 런타임 시트를 `0.486` 배율로 표시하고 grounded 바닥 기준선에 맞춘 것을 확인했다. 캡처는 저장소 밖 임시 경로에만 남겼다.

- 캡처: `C:/Users/blueh/AppData/Local/Temp/v122_p4a_spore_connect_1280x720.png`
- 결과: PASS, 이미지 크기 `1280×720`

## 미해결 및 다음 패킷

- 최종 동작별 발 앵커·그림자 정규화는 공통 V3 검수 전까지 남겨 둔다.
- 다른 계약 몬스터·공통 코드·오디오·VFX·초상화는 변경하지 않았다.
- 다음 제안은 `V2-P4B-DISCOVER-STONE` 하나이며, 이 문서에서는 실행하지 않는다.

Related tests: JSON·profile/runtime 경로·161px 중앙값·RGBA/크로마 0·배율/접지 앵커 직접 검사 PASS
UI check: `1280×720` 대표 화면에서 모리 시트 크기와 grounded 기준선 확인 PASS
Unresolved issues: 최종 동작별 발 앵커 정규화는 V3 범위이며 이번 패킷에서는 보류
