# v1.2.2 출시 마무리 A1-D2 AudioDirector 라우팅 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

GameRoot와 Update 3·4의 데이터 기반 오디오 사건을 공통 `AudioDirector`로 연결했다. 호출부는 WAV 경로를 직접 열지 않고 catalog event ID를 사용하며, 감독자가 실제 파일·버스·voice 예산·중복 토큰·플레이어 종료를 맡는다. Update 4 스킬·왕관·경쟁 보스 대표 사건은 파일이 존재하는지만 확인하지 않고 실제 AudioStreamPlayer가 하나 만들어지는지와 동일 instance token 재호출이 차단되는지를 검증했다.

## 변경 파일

- `scripts/audio/AudioDirector.gd`
- `scripts/game/GameRoot.gd`
- `data/audio/audio_event_catalog.json`
- `tools/audio/test_audio_event_catalog.py`
- `tools/tests/AudioVoiceAllocatorTest.gd`
- `tools/tests/SkillAudioPaletteTest.gd`
- `docs/qa/V122_A1_D2_AUDIO_DIRECTOR_ROUTING_2026-08-02.md`
- `docs/plans/V122_RELEASE_POLISH_LUNA_EXECUTION_PLAN_2026-08-02.md`
- `docs/handoff/CURRENT.md`

## 코드·데이터·사운드·그래픽 변경

- 코드: `AudioDirector`와 GameRoot Update 3/4 호출 연결을 추가했다.
- 데이터: 13개 Update 4 event를 catalog에 추가하고, 76개 중 66개 runtime 연결·0개 data-only·10개 unconnected 상태로 갱신했다.
- 사운드: 새 WAV를 만들거나 교체하지 않았다. 기존 Update 4 WAV와 Update 3 cue를 승인된 catalog 경로로만 연결했다.
- 그래픽: 변경하지 않았다.

## 검증

직접 라우팅 테스트 126 assertions, voice allocator 55 assertions, 버스 9 assertions, BGM 27 assertions, Python catalog 6개와 JSON·Godot editor 초기화를 통과했다. 테스트가 의도적으로 요청한 미등록 ID의 `AUDIO_CATALOG_MISSING_*` 로그 외에 라우팅 실패는 없었다.

Related tests: `SkillAudioPaletteTest.tscn` 126/126 PASS; `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 27/27 PASS; `python -m unittest tools.audio.test_audio_event_catalog -q` 6/6 PASS.
UI check: 화면·레이아웃 변경 없음. 1280×720 OWNER 화면 확인은 남아 있다.
Unresolved issues: CombatSceneController의 일반·스킬 SFX와 MultiFloorHUD의 층 경보는 A1-D3에서 공통 경로로 이관해야 한다. A1-E suite 등록, 새 음원 생성·승격, 실제 소유자 청취, 전체 검수와 빌드는 아직 하지 않았다.

## 다음 작업

1. A1-D3에서 전투·HUD의 직접 AudioStreamPlayer 생성을 AudioDirector와 voice budget으로 옮긴다.
2. A1-E에서 A1-A~D3 직접 테스트를 핵심 검증 suite에 등록한다.
3. 이후 C1 접촉 동기화와 A2~A5 오디오 자산·믹스 패킷을 계획 순서대로 진행한다.

## 작업 트리·Git

- 이번 패킷에서는 stage·commit·push·PR을 실행하지 않았다.
- 사용자가 남긴 기존 `.import`, `V122ResultUISimplificationTest.gd`, `.uid` 변경은 건드리지 않았다.
- 새 코드·데이터·문서 변경은 현재 작업 트리에 있으며 다음 세션에서 의도한 파일만 명시적으로 검토한다.
