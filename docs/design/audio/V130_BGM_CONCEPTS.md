# 1.3.0 BGM 15곡 생성 컨셉

작성일: 2026-10-15. 범위는 0041의 2~4단계 구성에 대한 **생성 준비**다. 컨셉 정교화 API·음악 생성·설치·네트워크 호출은 수행하지 않았다. 실행 매니페스트는 `tools/audio/lyria_v130_manifest.json`이며 제품 버전 메타데이터 1.2.12는 유지한다.

## 기존 곡 분석

`data/audio/music_playlists.json`은 장면별 목표 5곡을 선언한다. `MusicRotation.gd`는 이벤트를 카탈로그에서 실제 WAV 경로로 바꾸고, 같은 파일을 중복 제거해 순환한다. 따라서 새 이벤트만 늘리고 같은 기존 WAV를 재사용하는 방법으로는 부족분이 채워지지 않는다.

| 장면 | 현재 이벤트 / 서로 다른 곡 수 | 신규 | 연결 후 목표 |
|---|---|---:|---:|
| title | music.screen.title, music.screen.management / 2 | 3 | 5 |
| management | music.screen.management, music.screen.title / 2 | 3 | 5 |
| combat | music.combat.normal, music.combat.late_risk, music.combat.boss / 3 | 2 | 5 |
| result | music.screen.management, music.screen.title / 2 | 3 | 5 |
| final_ending | music.final.ending / 1 | 4 | 5 |

현재 BGM은 6개 고유 WAV다. 타이틀·관리·결과는 두 곡을 공유한다. 카탈로그의 Music 버스 9자산 중 나머지 3개는 라이벌 등장용 1.58초 단발 악구(22050Hz 모노 16비트)이며 장면 BGM에 세지 않는다. BGM 6개는 **44100Hz 스테레오 PCM 16비트 WAV**다. 아래 BPM·키·악기는 기존 v05/v122 프롬프트의 의도이며, 실제 음원의 박자/조성 분석이나 청취 판정은 아니다. 길이만 WAV 헤더로 측정했다.

| 파일 (`assets/audio/bgm/`) | 실측 길이 | 기존 프롬프트 톤 |
|---|---:|---|
| title_demon_castle_overture.wav | 107.636초 | 88 BPM G minor, 플럭·바순·프레임 드럼·말렛, 무게 70%와 캐릭터 코미디 30% |
| management_castle_bustle.wav | 115.081초 | 92 BPM G minor, 피치카토·바순·나무 말렛·작업장 클릭, 따뜻하고 바쁜 경영 |
| combat_dungeon_pressure.wav | 116.909초 | 128 BPM D minor, 전쟁 북·플럭·베이스·절제한 브라스·장난기 목관 |
| combat_boss_council.wav | 114.140초 | 132 BPM D minor, 프레임 드럼·청동·급한 저현·브라스, 더 의식적인 보스 방어 |
| combat_late_siege_pressure.wav | 115.708초 | 132 BPM D minor, 전쟁 북·저현·덜시머·브라스, 보스 행진과 구분되는 후반 압박 |
| final_ending_crown_of_ashes.wav | 115.081초 | 128 BPM D minor, 의식 북·저현·청동·바순, 결전과 에필로그 겸용의 씁쓸한 승리 |

기존 출처는 `assets/source/audio/lyria/v0.5/` 및 `v1.2.2/`의 원본·generation.json·SOURCE.md로 확인했다. 신규는 귀여운 다크 판타지, 마왕의 허당미, 몬스터 가족과 유능한 방어를 유지하면서 장조/선법·리듬·주악기를 다양하게 만든다.

## 공통 생성·렌더 계약

- 실존 아티스트·프랜차이즈·곡·저작권 멜로디 모방과 알아볼 수 있는 샘플을 금지한다. 보컬·대사·가사·합창 음절 없음. `build_prompt()`의 공통 규칙을 그대로 사용한다.
- 모두 `music_loop`, `lyria-3-pro-preview`, `status=planned`. BPM·키·길이는 요청 목표이며 생성 결과에서 보장된 실측값이 아니다.
- 요청 길이 112~144초(0041의 90~150초 안). 시작과 마지막 2초의 질감을 맞추고 단정적 종결을 피한다. 오디오 자체의 루프 크로스페이드(끝과 시작을 겹쳐 섞기)는 2초이며, 충분한 원본이면 최종 길이는 요청 길이에서 2초 짧아진다. 원본이 더 짧으면 실제 원본 길이에서 2초를 뺀다. 파이프라인은 요청 길이의 80% 미만 원본을 거부하지만, 90초 미만 최종 결과는 별도로 미채택한다.
- 런타임은 기존과 같은 44100Hz, 2채널, 16비트 WAV. 기존 파이프라인의 피크 정규화(관리 -4dBFS, 나머지 -5dBFS)를 사용한다. **-16 LUFS 체감 음량 정규화를 구현하거나 실행한 것은 아니다.** 후처리에서 기존 곡과의 체감 음량 또는 측정치를 맞추며, 그 처리를 출처에 남긴다.
- 음악 교체 시 게임의 0.65초 크로스페이드는 유지한다. 이는 파일 자체의 2초 루프 중첩과 다른 처리다.
- 후보 1개씩 15요청, 기존 매니페스트 단가 $0.08/요청으로 **예상 $1.20**. 최신 요금·모델 접근·약관은 네트워크 금지로 확인하지 않았다. 실행기/파이프라인의 재시도 루프는 없으며 SDK 내부 전송 재시도 정책은 오프라인에서 확인하지 않았다. 추가 후보는 별도 비용 판단이다.

## 신규 15곡

모든 곡은 루프 가능하도록 요청한다. 아래 길이는 `요청 → 충분한 원본 기준 렌더 목표`다. runtime 경로 공통 접두사는 `assets/audio/bgm/v130/`이며, 이벤트 ID는 후속 연결용으로만 예약했다.

| 장면/번호 · 곡명 | 분위기 | BPM / 키 | 악기 | 길이 / 루프 | 기존 곡과 차별점 |
|---|---|---|---|---|---|
| title 01 · 등불 켜진 성문 | 조심스럽게 반기는 포근함, 어둠 속 작은 장난 | 80 / E-flat major | 첼레스타·클라리넷·비올라 피치카토·부드러운 탬버린 | 120→118초 / 2초 중첩 | G단조 바순 중심 서곡과 달리 장조의 높은 종소리와 넓은 쉼표 |
| title 02 · 삐뚤어진 깃발 | 허당 마왕의 자신감, 가벼운 행진 | 96 / C Dorian | 오보에·만돌린·튜바의 가벼운 점음·브러시 소북 | 128→126초 / 2초 중첩 | 느린 G단조 서곡보다 빠른 도리아 선법과 엇박, 저음은 짧게 |
| title 03 · 달빛 시계탑 | 밤의 신비와 안전한 귀환 | 84 / E minor | 비브라폰·알토 플루트·하프·부드러운 현 드론 | 120→118초 / 2초 중첩 | 기존 플럭/바순 주선율 대신 말렛과 긴 호흡, 전투 저역 압력 제거 |
| management 01 · 설계도 뒤적이기 | 자유 배치의 호기심과 경쾌한 작업 | 104 / D Dorian | 마림바·베이스 클라리넷·뮤트 기타·셰이커 | 120→118초 / 2초 중첩 | 92 BPM G단조 바순/피치카토보다 빠른 말렛 리듬, 지도 편집의 손맛 |
| management 02 · 버섯차 휴식 | 휴식 중인 몬스터 가족, 느긋하고 따뜻함 | 78 / F major | 나일론 기타·클라리넷·하프·브러시 타악 | 112→110초 / 2초 중첩 | 기존 작업장 클릭과 바쁜 피치카토 대신 장조와 느슨한 기타 |
| management 03 · 장터와 영수증 | 행정 코미디와 거래의 소소한 활기 | 96 / B-flat Mixolydian | 작은 아코디언·목관·우드블록·업라이트 베이스 | 128→126초 / 2초 중첩 | 기존 G단조 작업장 질감 대신 믹솔리디안 민속 음색, 낮은 밀도 |
| combat 01 · 복도 역습 | 빠른 지휘와 반격, 초조함보다 유능함 | 144 / E minor | 스피카토 첼로·프레임 드럼·뮤트 호른·저음 플럭 | 128→126초 / 2초 중첩 | 128/132 BPM D단조 기존 전투군보다 빠른 E단조와 짧은 리듬 셀 |
| combat 02 · 수호석 릴레이 | 성장한 1층 부지의 유기적인 협력, 묵직한 추진 | 120 / C minor | 6/8 손북·해머드 덜시머·비올라·낮은 리드 목관 | 132→130초 / 2초 중첩 | 기존 D단조 의회 보스의 청동/브라스 의식 행진보다 흐르는 6/8 |
| result 01 · 결산과 비스킷 | 첫 방어 후 소박한 기쁨과 다음 준비 | 100 / G major | 플루트·피치카토 바이올린·나일론 기타·비브라폰 | 112→110초 / 2초 중첩 | 관리/타이틀 곡 재활용 대신 결산 전용 장조와 짧은 답가 |
| result 02 · 기운 깃발 다시 꿰매기 | 패배도 다음 회차로 잇는 다정함 | 76 / A minor | 펠트 피아노·베이스 클라리넷·비올라·가벼운 손 타악 | 120→118초 / 2초 중첩 | 기존 바순 작업장의 분주함 대신 피아노와 완만한 회복, 비극 과장 없음 |
| result 03 · 작은 훈장 수여식 | 웃음 섞인 성취와 소소한 성장 | 108 / F Lydian | 뮤트 코넷·오보에·오르골·라이트 베이스 | 120→118초 / 2초 중첩 | 기존 타이틀의 묵직함 대신 리디안 밝음과 짧은 코넷 응답 |
| final_ending 01 · 많은 길 하나의 왕좌 | 확장 부지의 결전, 성숙한 지휘관 | 112 / C minor | 낮은 스트링·호른·팀파니·청동의 드문 강조 | 144→142초 / 2초 중첩 | 128 BPM D단조 왕관/재 테마보다 느린 C단조, 1층 길의 교차 리듬 |
| final_ending 02 · 공성전 뒤의 집 | 몬스터 가족의 귀환, 조용한 해방감 | 72 / D major | 어쿠스틱 기타·잉글리시 호른·따뜻한 스트링·하프 | 132→130초 / 2초 중첩 | 전투와 겸용인 기존 최종곡과 달리 타악을 줄인 장조 가족 엔딩 |
| final_ending 03 · 휴전의 등불 | 라이벌과 맺은 평화, 낯설지만 다정한 균형 | 88 / A Dorian | 알토 플루트·덜시머·비올라·부드러운 프레임 드럼 | 128→126초 / 2초 중첩 | 기존 D단조 의식적 브라스 대신 선법적 목관 대화와 얇은 타악 |
| final_ending 04 · 마지막 촛불과 새벽 | 긴 여정의 여운, 쓸쓸함에서 희망으로 | 64 / E minor to G major | 그랜드 피아노·솔로 첼로·하프 하모닉스·얇은 스트링 | 144→142초 / 2초 중첩 | 왕관/재의 전쟁 북 대신 피아노 주도, 순환 가능한 관계조 이동 |

## 런타임·이벤트 예약표

| asset ID | 런타임 WAV | 예약 이벤트 |
|---|---|---|
| `v130_title_01_lantern_gate` | `assets/audio/bgm/v130/title_01_lantern_gate.wav` | `music.v130.title.01` |
| `v130_title_02_crooked_banner` | `assets/audio/bgm/v130/title_02_crooked_banner.wav` | `music.v130.title.02` |
| `v130_title_03_moon_clock` | `assets/audio/bgm/v130/title_03_moon_clock.wav` | `music.v130.title.03` |
| `v130_management_01_blueprint_shuffle` | `assets/audio/bgm/v130/management_01_blueprint_shuffle.wav` | `music.v130.management.01` |
| `v130_management_02_mushroom_tea` | `assets/audio/bgm/v130/management_02_mushroom_tea.wav` | `music.v130.management.02` |
| `v130_management_03_market_receipts` | `assets/audio/bgm/v130/management_03_market_receipts.wav` | `music.v130.management.03` |
| `v130_combat_01_corridor_counterattack` | `assets/audio/bgm/v130/combat_01_corridor_counterattack.wav` | `music.v130.combat.01` |
| `v130_combat_02_wardstone_relay` | `assets/audio/bgm/v130/combat_02_wardstone_relay.wav` | `music.v130.combat.02` |
| `v130_result_01_debrief_biscuits` | `assets/audio/bgm/v130/result_01_debrief_biscuits.wav` | `music.v130.result.01` |
| `v130_result_02_mended_flags` | `assets/audio/bgm/v130/result_02_mended_flags.wav` | `music.v130.result.02` |
| `v130_result_03_little_medals` | `assets/audio/bgm/v130/result_03_little_medals.wav` | `music.v130.result.03` |
| `v130_final_ending_01_one_throne_many_paths` | `assets/audio/bgm/v130/final_ending_01_one_throne_many_paths.wav` | `music.v130.final_ending.01` |
| `v130_final_ending_02_home_after_siege` | `assets/audio/bgm/v130/final_ending_02_home_after_siege.wav` | `music.v130.final_ending.02` |
| `v130_final_ending_03_truce_lanterns` | `assets/audio/bgm/v130/final_ending_03_truce_lanterns.wav` | `music.v130.final_ending.03` |
| `v130_final_ending_04_last_candle_dawn` | `assets/audio/bgm/v130/final_ending_04_last_candle_dawn.wav` | `music.v130.final_ending.04` |

## 생성 이후 연결 경계

현재 playlists·카탈로그·게임 코드에는 변경을 넣지 않는다. 원본과 preview를 만든 뒤 청취/품질 판단을 거쳐 `render → promote → catalog/events → playlists → 직접 검증` 순서로 진행한다. promote가 생성하는 곡별 권위 출처는 `assets/source/audio/lyria/v1.3.0/<asset-id>/SOURCE.md`다. 0041의 묶음 출처 `assets/source/audio/v130_bgm/SOURCE.md`는 채택 이후 실제 15개 출처/라이선스/후처리 링크를 담는 색인으로 작성하며, 아직 생성되지 않은 날짜·약관·승인을 미리 기록하지 않는다. 구체적 실행/실패 재개/검증은 `docs/handoff/V130_BGM_PREP_2026-10-15.md`를 따른다.
