# v1.2.2 출시 마무리 A0 오디오 manifest 계약 재검증 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-05
패킷: `A0-AUDIO-MANIFEST-CONTRACT`
QA: `docs/qa/V122_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`

## 완료 내용

선행되어 있던 A0 manifest 작업을 출시 승인으로 간주하지 않고 다시 확인했다. v1.2.2 manifest는 현재 `assets/audio`의 WAV 76개를 빠짐없이 선언하며, 기본 2회 생성 계획과 모델별 요청 수·예상 비용을 재현한다. `generate`는 `--execute` 없이는 계획만 출력하고, 승격은 `--confirm` 없이는 런타임 파일을 덮어쓰지 못한다.

## 실제 변경 경로

- `tools/tests/V122A0AudioManifestContractTest.gd`
- `docs/qa/V122_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A0_AUDIO_MANIFEST_CONTRACT_REVALIDATION_2026-08-05.md`
- `docs/handoff/CURRENT.md`

`tools/audio/lyria_v122_manifest.json`과 `tools/audio/lyria_pipeline.py`는 재검증만 수행하고 수정하지 않았다.

## 실행한 직접 테스트

- manifest `validate` — 76/76 coverage PASS
- manifest `plan` — 146 clip + 6 pro requests, estimated `$6.32` PASS
- `python -m json.tool tools/audio/lyria_v122_manifest.json` — PASS
- `godot.cmd --headless --path . --script tools/tests/V122A0AudioManifestContractTest.gd --quit-after 30` — `PASS (13 checks)`
- `python -m py_compile tools/audio/lyria_pipeline.py` — PASS

## 코드·데이터·스토리·밸런스·그래픽·오디오

- 코드: 새 A0 계약 테스트만 추가했다. 오디오 파이프라인 코드는 변경하지 않았다.
- 데이터: v1.2.2 manifest와 기존 v0.5 manifest는 변경하지 않았다.
- 음원: 생성·승격·청취·런타임 덮어쓰기를 실행하지 않았다.
- 스토리·밸런스·그래픽: 변경 없음.

## 미해결 문제와 다음 작업 순서

- 실제 생성 비용 승인과 사람 청취 승인이 없으므로 음원 상태는 출시 승인 상태가 아니다.
- 다음 잠금 후보는 `A1-A-AUDIO-EVENT-CATALOG` 재검증이다. 이번 turn에는 시작하지 않는다.

## 작업 트리 및 원격 상태

- 기존 사용자/Luna 미커밋 변경은 보존했으며 되돌리거나 정리하지 않았다.
- 커밋·푸시: 수행하지 않음.

## 정책 판정

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
