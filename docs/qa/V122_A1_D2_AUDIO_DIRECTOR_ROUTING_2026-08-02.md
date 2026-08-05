# v1.2.2 A1-D2 GameRoot·Update 3/4 AudioDirector 라우팅 검수

검수일: 2026-08-02
대상 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

GameRoot에서 직접 발생하는 Update 3 효과음·경보와 Update 4 데이터의 계약 스킬, 왕관 진화, 경쟁 보스 모티프를 `AudioDirector`와 오디오 event catalog로 연결했다. CombatSceneController의 일반·스킬 SFX와 MultiFloorHUD의 층 경보 이관, 새 음원 생성·승격, 전체 출시 검수와 빌드는 A1-D3 이후 범위다.

## 구현 결과

- `scripts/audio/AudioDirector.gd`를 추가했다.
  - event ID 해석 → 실제 runtime 파일 로드 → `AudioSettings` 버스 지정 → `AudioVoiceAllocator` 승인 → 플레이어 종료·축출 정리를 한 경로에서 처리한다.
  - 동일 instance token은 재생 중 중복 요청을 거부하고, 중요 경보·보스 모티프는 catalog의 Music 버스를 유지하면서도 일회성 voice 예산을 사용한다.
- `scripts/game/GameRoot.gd`에 공통 감독자를 생성하고 종료 시 모든 voice를 정리하도록 했다.
  - 기존 Update 3 cue는 asset catalog의 event를 통해 재생한다.
  - Update 4 계약 스킬 4개, 왕관 SFX 6개, 경쟁 보스 모티프 3개를 실제 데이터 ID별 메서드에 연결했다.
  - 왕관 진화는 `complete_crown_event`가 성공한 경우에만 효과음을 호출한다.
- `data/audio/audio_event_catalog.json`을 갱신했다.
  - 전체 76개 자산 중 실제 runtime 연결 66개, data-only 0개, 소비자 미확인 10개로 분류했다.
  - `sfx_popo_alarm`은 기존 층 경보와 Update 4 `echo_alarm` 사건이 공유한다.
- 기존 `SkillAudioPaletteTest` 입구를 확장해 파일 존재만 보지 않고 catalog event와 실제 voice 생성·중복 차단을 확인했다.

## 검증 결과

- `godot --headless --path . --scene res://tools/tests/SkillAudioPaletteTest.tscn --quit-after 2500`: 126/126 PASS
- `godot --headless --path . --scene res://tools/tests/AudioVoiceAllocatorTest.tscn --quit-after 1200`: 55/55 PASS
- `godot --headless --path . --scene res://tools/tests/AudioBusContractTest.tscn --quit-after 1000`: 9/9 PASS
- `godot --headless --path . --scene res://tools/tests/MusicStateAudioTest.tscn --quit-after 1800`: 27/27 PASS
- `python -m unittest tools.audio.test_audio_event_catalog -q`: 6/6 PASS
- `python -m json.tool data/audio/audio_event_catalog.json`: PASS
- `godot --headless --path . --editor --quit-after 1000`: 새 전역 클래스 등록 및 스크립트 초기화 PASS
- 전체 회귀, 전체 플레이, Windows export와 빌드는 실행하지 않았다.

Related tests: `SkillAudioPaletteTest.tscn` 126/126 PASS; `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 27/27 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: UI 배치·그래픽은 변경하지 않았고 GameRoot의 headless 런타임에서 AudioDirector 생성과 voice 수명만 확인했다. 1280×720 화면 검수는 이 패킷 범위에서 실행하지 않았다.
Unresolved issues: CombatSceneController 일반·스킬 SFX와 MultiFloorHUD 층 경보는 아직 직접 AudioStreamPlayer 경로이며 A1-D3에서 이관한다. 새 음원 승격, 실제 소유자 청취, 전체 출시 검수와 빌드는 후속 게이트다.
