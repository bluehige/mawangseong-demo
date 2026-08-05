# v1.2.2 A1-B 오디오 버스·limiter·설정 계약

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

오디오 공통 버스와 설정 전파만 연결했다. 새 음원, catalog event, 환경음 scheduler는 이번 범위에 넣지 않았다.

## 변경 내용

- `scripts/core/AudioSettings.gd`에 `UI`·`Ambience` 버스와 `Master` limiter 추가
- 전송 계층을 `Music / SFX → Master`, `UI / Ambience → SFX`로 고정
- SFX 음량을 SFX·UI·Ambience에 함께 적용
- Master limiter ceiling을 `-1.0 dBFS`로 고정하고 중복 효과 추가를 방지
- `tools/tests/AudioBusContractTest.gd`와 `.tscn` 추가

## 검증 결과

- `godot --headless --path . --scene res://tools/tests/AudioBusContractTest.tscn --quit-after 600`: 9/9 PASS
- `godot --headless --path . --scene res://tools/tests/MusicStateAudioTest.tscn --quit-after 600`: 12/12 PASS
- SFX 0%에서 SFX·UI·Ambience 무음, Music 유지 확인
- 버스 전송 계층과 Master limiter ceiling 확인
- 런타임 WAV·import 설정·catalog event·빌드는 변경하지 않음

Related tests: `AudioBusContractTest` 9/9 PASS; `MusicStateAudioTest` 12/12 PASS.
UI check: UI 화면 변경 없음. 오디오 설정·버스 계약만 headless로 확인했다.
Unresolved issues: A1-C BGM loop/crossfade transport, A1-D voice cap·Update 3/4 routing, A4 환경음·발소리와 76개 청취 승인이 남아 있다.
