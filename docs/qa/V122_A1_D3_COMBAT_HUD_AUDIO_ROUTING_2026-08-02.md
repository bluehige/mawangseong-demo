# v1.2.2 A1-D3 전투·HUD AudioDirector 라우팅 검수

검수일: 2026-08-02
대상 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

전투 컨트롤러의 일반·스킬 효과음과 상층 HUD의 숨은 층 경보를 A1-D1에서 만든 voice budget 및 A1-D2의 `AudioDirector`로 이관했다. 새 음원, 버스 구조, A1-E suite 등록, 전체 출시 검수와 빌드는 이 패킷 범위가 아니다.

## 구현 결과

- `scripts/game/CombatSceneController.gd`
  - 기존 `AudioStreamPlayer` 직접 생성을 제거했다.
  - stream의 실제 파일명에서 catalog asset ID를 판별하고 `AudioDirector.play_asset`을 호출한다.
  - 기존 키별 최소 간격과 공격 pitch 변화를 유지하면서 voice 수명·상한은 공통 allocator가 관리한다.
- `scenes/ui/hud/MultiFloorHUD.gd`
  - `FloorAlertSound` 직접 플레이어를 제거했다.
  - `setup`으로 전달받은 AudioDirector의 `update4.floor_intrusion.alarm` event를 사용한다.
  - 반복 경보는 자기 voice token만 교체하고 HUD 제거 시 해당 voice만 release한다.
- `scripts/game/GameRoot.gd`
  - 상층 HUD 생성 시 AudioDirector를 주입한다.

## 검증 결과

- `godot --headless --path . --scene res://tools/tests/CombatAudioDirectorRoutingTest.tscn --quit-after 2200`: 9/9 PASS
  - 일반 피격음 catalog voice 연결
  - 기존 cooldown 중복 방지
  - 스킬 event 연결
  - 층 경보 연결·반복 교체·HUD 제거 release
- `godot --headless --path . --scene res://tools/tests/SkillAudioPaletteTest.tscn --quit-after 2500`: 126/126 PASS
- `godot --headless --path . --scene res://tools/tests/AudioVoiceAllocatorTest.tscn --quit-after 1200`: 55/55 PASS
- `godot --headless --path . --scene res://tools/tests/AudioBusContractTest.tscn --quit-after 1000`: 9/9 PASS
- `godot --headless --path . --scene res://tools/tests/MusicStateAudioTest.tscn --quit-after 1800`: 27/27 PASS
- `python -m unittest tools.audio.test_audio_event_catalog -q`: 6/6 PASS
- `python -m json.tool data/audio/audio_event_catalog.json`: PASS
- 전체 회귀, 전체 플레이, Windows export와 빌드는 실행하지 않았다.

Related tests: `CombatAudioDirectorRoutingTest.tscn` 9/9 PASS; `SkillAudioPaletteTest.tscn` 126/126 PASS; `AudioVoiceAllocatorTest.tscn` 55/55 PASS; `AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 27/27 PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: HUD 레이아웃과 경보 문구는 변경하지 않고 headless에서 경보 voice 연결·수명만 확인했다. 1280×720 화면 검수는 이 패킷 범위에서 실행하지 않았다.
Unresolved issues: A1-E 핵심 검증 suite 등록, 새 음원 생성·승격, 실제 소유자 청취, 전체 회귀·출시 후보 빌드는 남아 있다.
