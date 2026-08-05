# v1.2.2 출시 마무리 A1-C BGM transport 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

관리·일반 전투·보스 전투 BGM 세 곡의 WAV import loop를 forward loop로 맞췄다. `GameRoot`는 주·보조 두 플레이어를 번갈아 사용해 곡이 바뀌는 상태 전환에서만 crossfade하고, 동일 상태 재요청에서는 기존 플레이어를 유지한다. 설정 음악 슬라이더에는 관리곡 3초 미리듣기를 연결하고 `music.preview.settings`를 catalog에 기록했다.

변경 파일:

- `assets/audio/bgm/management_castle_bustle.wav.import`
- `assets/audio/bgm/combat_boss_council.wav.import`
- `scripts/game/GameRoot.gd`
- `data/audio/audio_event_catalog.json`
- `tools/audio/test_audio_event_catalog.py`
- `tools/tests/MusicStateAudioTest.gd`

## 검증

`MusicStateAudioTest` 27 assertions, `AudioBusContractTest` 9 assertions, catalog 단위 테스트 6개와 JSON 문법 검사를 모두 통과했다. 테스트는 실제 GameRoot 런타임에서 loop 속성·player 교대·crossfade 종료·preview 중복 방지를 확인한다.

Related tests: `MusicStateAudioTest.tscn` 27/27 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `python -m unittest tools.audio.test_audio_event_catalog -v` 6/6 PASS.
UI check: 레이아웃 변경 없음. 설정 음악 slider callback과 preview player만 headless로 확인했으며 1280×720 OWNER 청취는 남아 있다.
Unresolved issues: 실제 소유자 청취와 130초 loop seam 확인, A1-D1~D3 효과음 제한·Update 3/4 routing, A4 Stage 환경음·발소리, A3의 새 BGM 3상태는 다음 작업이다.

## 다음 작업

1. A1-D1에서 효과음 동시 재생 상한과 중요도 allocator를 고정한다.
2. A1-D2~D3에서 Update 3/4 경보·모티프·HUD 호출을 catalog와 버스에 연결한다.
3. 각 패킷의 직접 테스트 후 `CURRENT.md`와 다음 핸드오프를 갱신한다.

## Git 상태

- 이번 핸드오프에서는 stage·commit·push·PR을 실행하지 않았다.
- 사용자가 남긴 기존 `.import`, `V122ResultUISimplificationTest.gd`, `.uid` 변경은 건드리지 않았다.
