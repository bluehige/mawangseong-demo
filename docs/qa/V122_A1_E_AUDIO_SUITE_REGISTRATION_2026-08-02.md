# v1.2.2 A1-E 오디오 핵심 검증 suite 등록 검수

검수일: 2026-08-02
대상 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

A1-A부터 A1-D3까지 이미 통과한 오디오 계약 테스트를 `tools/tests/core_verification_suite.json`의 `quick`·`full` 목록에 등록했다. 등록된 입구 확인과 suite coverage만 검사했으며 Quick/Full 전체 검증, 새 음원·런타임·그래픽 변경, 빌드는 실행하지 않았다.

## 등록 목록

- `audio_bus_contract` → `res://tools/tests/AudioBusContractTest.tscn`
- `music_state_audio` → `res://tools/tests/MusicStateAudioTest.tscn`
- `audio_voice_allocator` → `res://tools/tests/AudioVoiceAllocatorTest.tscn`
- `skill_audio_palette` → `res://tools/tests/SkillAudioPaletteTest.tscn`
- `combat_audio_director_routing` → `res://tools/tests/CombatAudioDirectorRoutingTest.tscn`

## 검증 결과

- `python -m json.tool tools/tests/core_verification_suite.json`: PASS
- `godot --headless --path . --scene res://tools/tests/V122ContentCompatibilityTest.tscn --quit-after 1800`: coverage 85/85, 499/499 PASS
- 등록 입구 직접 실행:
  - AudioBusContract 9/9
  - MusicStateAudio 27/27
  - AudioVoiceAllocator 55/55
  - SkillAudioPalette 126/126
  - CombatAudioDirectorRouting 9/9
- `python -m unittest tools.audio.test_audio_event_catalog -q`: 6/6 PASS
- Quick/Full 전체 검증과 출시 빌드는 실행하지 않았다.

Related tests: `V122ContentCompatibilityTest.tscn` 499/499 PASS; 등록 오디오 5개 입구 총 226 assertions PASS; `tools.audio.test_audio_event_catalog` 6/6 PASS.
UI check: suite JSON만 변경했으며 화면·레이아웃·그래픽은 확인 대상이 아니었다. 1280×720 화면 검수는 실행하지 않았다.
Unresolved issues: 오디오 자산의 실제 소유자 청취·권리 승인, 전체 Quick/Full 검증, C1 접촉 동기화와 A2~A5 자산·믹스 작업은 남아 있다.
