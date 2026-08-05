# v1.2.2 V2-P4C `war_drummer` 런타임 연결 검수

## 패킷 카드

- `PACKET_ID`: `V2-P4C-CONNECT-WAR`
- `GOAL`: 두둠 전용 전투 런타임 시트 1개를 제품 데이터와 전투 visual profile에 연결
- `ALLOWED_WRITE_PATHS`: `data/monsters.json`, `data/v122/combat_visual_profiles.json`, 이 QA 문서, 패킷 핸드오프, `CURRENT.md`
- `FORBIDDEN`: 두둠 자산 재생성, 다른 캐릭터, 공통 코드·씬·초상화·VFX·오디오, V3 정규화, 다음 패킷
- `DIRECT_TEST`: 두둠 데이터/profile/runtime 경로, 140.0px 중앙값, 배율, 접지 앵커, profile contract
- `UI_OR_AUDIO_CHECK`: Godot OpenGL 호환 렌더러의 `1280×720` 대표 화면에서 두둠 시트와 기준선 확인
- `STOP_AFTER`: 두둠 연결과 직접 검수만 완료하고 중단

## 결과

`CONNECT_PASS_WITH_NORMALIZATION_PENDING`.

`war_drummer`의 데이터 sprite를 두둠 전용 4×4 런타임 시트로 바꾸고, `unit_overrides`에 동일한 원본·런타임 경로와 `RUNTIME_PREP_PASS`, 투명 시트 설정을 연결했다. 런타임 시트의 측정 중앙값은 `140.0px`이고 `normal_grounded` 목표 높이 `78.246px`에 따라 배율 `0.5589`가 계산된다. 최종 동작별 발 접지와 공통 V3 정규화 판정은 별도 범위이므로 `NEEDS_NORMALIZATION`을 유지한다.

## 변경 경로

| 경로 | 변경 내용 |
|---|---|
| `data/monsters.json` | `war_drummer.sprite`를 `res://assets/sprites/monsters/update4/monster_dudum_sheet.png`로 연결 |
| `data/v122/combat_visual_profiles.json` | 두둠 원본·런타임 경로, `RUNTIME_PREP_PASS`, `requires_chroma_key=false`, `median_art_height_px=140.0` 연결 |
| `assets/sprites/monsters/update4/monster_dudum_sheet.png` | 이전 `V2-P4C-ASSET-WAR` 패킷에서 검수 완료한 768×768 RGBA 4×4 시트 사용(이번 패킷에서는 수정하지 않음) |

## 직접 검수

- JSON UTF-8 파싱: PASS
- 런타임 시트: `768×768`, RGBA, `192×192` 셀 16개, 셀 외곽 침범 0, 발 바닥선 편차 0px, 중앙값 `140.0px`: PASS
- 두둠 전용 직접 Godot 검사(`V122_P4C_WAR_CONNECT_DIRECT_TEST`): PASS
- `V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST`: PASS
- 정상 배율: `78.246 / 140.0 = 0.5589`: PASS
- 접지 앵커: `normal_grounded` 발 앵커와 Unit 렌더 위치 일치: PASS

실행한 대표 화면 검수:

```text
godot.cmd --path . --display-driver windows --rendering-method gl_compatibility --scene C:/Users/blueh/AppData/Local/Temp/v122_p4c_war_connect_check.tscn --quit-after 120
```

결과는 `1280×720` 화면에서 두둠이 기준선에 접지된 상태로 보이는 것까지 PASS다.

- 캡처: `C:/Users/blueh/AppData/Local/Temp/v122_p4c_war_connect_1280x720.png`
- Godot import 확인 뒤 생성된 임시 `.png.import` sidecar는 저장소에 남기지 않았다.

## 미해결 및 다음 패킷

- 최종 프레임별 높이 정규화와 동작별 흔들림 판정은 V3 범위로 남긴다.
- 다음 제안은 `V2-P4D-DISCOVER-MIMIC` 하나이며, 이번 turn에서는 실행하지 않는다.

Review task ID: NOT_REQUESTED
Reviewed SHA: N/A
Remaining P1/P2: N/A
Final review result: TARGETED_PASS
