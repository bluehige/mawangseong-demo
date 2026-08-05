# v1.2.2 A1-B 오디오 버스·limiter·설정 계약 재검증

검수일: 2026-08-05
대상 브랜치: `codex/v122-ui-simplification`
기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

현재 런타임에서 `Music / SFX / UI / Ambience` 버스의 전송 계층, Master limiter, SFX 설정 전파를 재검증했다. BGM transport, event catalog, Update 3/4 routing, 새 음원 생성과 승격은 이번 패킷에서 다루지 않았다.

## 검증 결과

```text
godot.cmd --headless --path . --scene tools/tests/AudioBusContractTest.tscn --quit-after 600
AUDIO_BUS_CONTRACT_TEST: PASS (12 assertions)

godot.cmd --headless --path . --scene tools/tests/MusicStateAudioTest.tscn --quit-after 600
MUSIC_STATE_AUDIO_TEST: PASS (27 assertions)
```

확인한 조건:

- Music/SFX는 Master로 전송
- UI/Ambience는 SFX로 전송
- Master limiter ceiling은 `-1.0 dBFS`
- 버스 재확인 뒤 limiter가 중복되지 않음
- SFX 0%에서 SFX·UI·Ambience만 무음이고 Music은 유지
- SFX 설정값 `0.35`가 SFX·UI·Ambience에 같은 값으로 전파
- 관리·일반 전투·보스 음악의 loop, 상태 전환 crossfade, 미리듣기 동작 유지

## 실제 변경 경로

- `tools/tests/AudioBusContractTest.gd`
- `docs/qa/V122_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

`scripts/core/AudioSettings.gd`는 재검증만 수행하고 수정하지 않았다. catalog·GameRoot·WAV·import 설정도 변경하지 않았다.

## 미해결 및 다음 순서

- 실제 소유자 청취와 130초 loop seam 청취는 남아 있다.
- 다음 패킷은 `A1-C-BGM-TRANSPORT` 재검증이며, BGM loop·crossfade·설정 preview만 다룬다.
- 76개 음원의 청취·권리 승인은 별도 gate다.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
