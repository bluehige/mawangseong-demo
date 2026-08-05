# v1.2.2 출시 마무리 A1-B 오디오 버스 계약 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A1-B-AUDIO-BUS-CONTRACT`
QA: `docs/qa/V122_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`

## 완료 내용

선행 A1-B 구현을 현재 런타임에서 다시 확인했다. Music/SFX는 Master로, UI/Ambience는 SFX로 연결되고 Master limiter는 한 개만 유지된다. SFX 설정은 세 효과음 계층에 전달되며 0% 음소거와 Music 독립 유지도 확인했다.

## 실제 변경 경로

- `tools/tests/AudioBusContractTest.gd`
- `docs/qa/V122_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A1_B_AUDIO_BUS_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

AudioSettings 구현과 오디오 자산은 수정하지 않았다. 테스트에 limiter 중복 방지와 SFX→UI/Ambience 전파 단언을 보강했다.

## 실행한 직접 테스트

- `AudioBusContractTest.tscn` — 12/12 PASS
- `MusicStateAudioTest.tscn` — 27/27 PASS

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드: 버스 계약 테스트만 보강했다.
- 데이터/스토리/밸런스/그래픽: 변경 없음.
- 오디오: WAV·import·catalog·routing은 변경 없음.

## 미해결 문제와 다음 작업 순서

- 실제 130초 loop seam 청취와 소유자 청취는 아직 남아 있다.
- 다음 잠금 후보는 `A1-C-BGM-TRANSPORT` 재검증이다. 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 커밋·푸시: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
