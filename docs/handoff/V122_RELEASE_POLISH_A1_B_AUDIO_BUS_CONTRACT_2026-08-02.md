# v1.2.2 출시 마무리 A1-B 오디오 버스·limiter·설정 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

오디오 공통 버스를 기존 3개에서 5개로 확장했다. `Music`과 `SFX`는 `Master`로, `UI`와 `Ambience`는 `SFX`로 전송한다. Master에는 limiter를 한 번만 붙이고 ceiling을 `-1.0 dBFS`로 설정했다. SFX 설정값은 세 효과음 계층에 같이 전파된다.

- 변경 파일: `scripts/core/AudioSettings.gd`, `tools/tests/AudioBusContractTest.gd`, `tools/tests/AudioBusContractTest.tscn`
- `AudioBusContractTest` 9 assertions PASS
- 기존 `MusicStateAudioTest` 12 assertions PASS
- 새 오디오 파일 생성·승격·catalog event 연결은 하지 않음

Related tests: `godot --headless ... AudioBusContractTest.tscn` 9/9 PASS; `MusicStateAudioTest.tscn` 12/12 PASS.
UI check: 화면·입력 UI는 변경하지 않았고 버스·설정 런타임만 확인했다.
Unresolved issues: 다음은 A1-C BGM transport다. loop seam·crossfade와 data-only Update 4 사건 연결은 별도 패킷으로 남아 있다.

## 다음 작업

A1-C에서 BGM과 loop cue의 stream loop, 종료 후 재시작 금지, 상태 전환 crossfade와 설정 preview event를 작은 계약으로 검증한다.

## Git 상태

- 커밋·푸시: 수행하지 않음
- 기존 사용자 변경과 이전 패킷 문서를 보존함
