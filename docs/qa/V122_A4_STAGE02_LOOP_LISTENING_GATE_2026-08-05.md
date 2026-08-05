# v1.2.2 A4 Stage 02 ambience loop listening gate QA

검수일: 2026-08-05
목표 버전: `1.2.2`
작업 브랜치: `codex/v122-ui-simplification`
패킷: `A4-STAGE-02-LOOP-LISTENING-GATE`

## 목적

생성된 `ambience_stage02_indoor` 후보를 소유자가 직접 청취하고 승인·재생성·폐기 중 하나를 결정한다. 이번 패킷은 후보 승인 기록과 기계적 파일 재확인만 다루며 source/runtime 승격은 하지 않는다.

## 후보 및 사용자 결정

- 후보 경로: `tmp/lyria_audio_v122/20260805_stage02_loop_take01/ambience_stage02_indoor/take-01/preview.wav`
- 원본 후보: `source.mp3`
- 사용자 결정: `승인`
- 청취 결과: 사용자가 후보를 청취한 뒤 승인했다.
- 승인 범위: 현재 take 01 후보 1개만 승인. 추가 take·다른 Stage·runtime 승격까지 자동 승인한 것은 아니다.

## 직접 재확인

```text
candidate=ambience_stage02_indoor
channels=2
sample_rate=44100
sample_width=2
duration_seconds=114.428
preview_hash_matches=True
source_hash_matches=True
```

- preview WAV 존재·구조: PASS
- preview/source SHA-256 메타데이터 일치: PASS
- 후보 폴더 API 키 패턴: 0건
- 코드·manifest·catalog·source/runtime·GameRoot: 변경 없음
- 전체 회귀·검수 에이전트·빌드·커밋·푸시: NOT_REQUESTED

## 결과

`A4_STAGE02_LOOP_LISTENING_GATE_PASS`

사용자 청취 승인을 기록했다. 후보는 다음 별도 `PROMOTE` 패킷에서만 제품 source/runtime으로 승격할 수 있다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`

## 미해결 및 다음 순서

- 후보는 승인됐지만 아직 `assets/source/` 원본·`SOURCE.md`·generation 기록·runtime WAV가 없다.
- 다음 단일 패킷은 `A4-STAGE-02-LOOP-PROMOTE`다.
- 다음 패킷은 승인된 take 01 한 개만 source/runtime으로 승격하고 manifest를 `active`로 전환한다.
- 승격 뒤 event catalog와 Stage 02 실제 게임 연결은 별도 패킷으로 분리한다.
