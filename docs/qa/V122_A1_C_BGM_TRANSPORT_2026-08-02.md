# v1.2.2 A1-C BGM transport 계약

검수일: 2026-08-02
대상 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

기존 관리·일반 전투·보스 전투 BGM의 반복 재생, 상태 전환, 설정 화면 미리듣기만 확인했다. 새 음원 생성·승격, A1-D의 효과음 allocator·Update 3/4 routing, 전체 출시 검수와 빌드는 이 패킷 범위가 아니다.

## 변경 내용

- `assets/audio/bgm/management_castle_bustle.wav.import`와 `assets/audio/bgm/combat_boss_council.wav.import`의 `edit/loop_mode`를 `2`(`AudioStreamWAV.LOOP_FORWARD`)로 고정했다. 기존 일반 전투곡도 같은 설정임을 확인했다.
- `scripts/game/GameRoot.gd`에 주·보조 BGM 플레이어를 추가했다. 곡이 바뀔 때만 두 플레이어가 교차 페이드하고, 같은 곡을 다시 요청하면 중복 재생·불필요한 페이드인을 만들지 않는다.
- 설정의 음악 슬라이더 변경 시 `MANAGEMENT_MUSIC`을 별도 preview player로 3초 재생한다. 미리듣기 중 연속 요청은 무시하며 설정을 닫거나 종료할 때 정리한다.
- `data/audio/audio_event_catalog.json`에 실제 런타임 호출인 `music.preview.settings`를 추가했다. manifest의 76개 자산과 기존 54개 실제 자산 분류는 그대로 두고 event 수만 55개로 늘렸다.

## 검증 결과

- `godot --headless --path . --scene res://tools/tests/MusicStateAudioTest.tscn --quit-after 1200`: 27/27 PASS
  - 관리·일반·보스 3곡의 forward loop
  - 동일 상태 재요청 시 player 유지
  - 상태 전환 시 보조 player를 이용한 crossfade와 종료
  - 설정 preview 시작·연속 요청 중복 방지·3초 후 정지
- `godot --headless --path . --scene res://tools/tests/AudioBusContractTest.tscn --quit-after 600`: 9/9 PASS
- `python -m unittest tools.audio.test_audio_event_catalog -v`: 6/6 PASS
- `python -m json.tool data/audio/audio_event_catalog.json`: PASS
- Full 검수, 전체 플레이, Windows export와 빌드는 실행하지 않았다.

Related tests: `MusicStateAudioTest` 27/27 PASS; `AudioBusContractTest` 9/9 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: 설정 화면 UI 레이아웃은 변경하지 않았고, slider callback에서 preview player 연결만 headless 런타임으로 확인했다. 1280×720 시각 검수는 A1-C 범위에서 실행하지 않았다.
Unresolved issues: 실제 130초 청취와 loop seam 클릭 여부, 오디오 소유자 청취·승격은 아직 대기다. A1-D1~D3의 voice cap·Update 3/4 routing, A4 환경음·발소리, 6상태 BGM 확장은 다음 패킷이다.
