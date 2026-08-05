# V1.2.2 Stage 04 환경 loop 승격 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-04-LOOP-PROMOTE`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE04_LOOP_PROMOTE_PASS_WITH_TEST_CONTRACT_ALIGNMENT_BLOCKED`

사용자가 청취 승인한 `ambience_stage04_citadel` take 01만 제품 source/runtime으로 승격했다. 추가 Lyria 호출·추가 take·다른 Stage 자산·catalog·GameRoot·AudioDirector 변경은 수행하지 않았다.

## 2. 승격 결과

| 구분 | 경로 | 상태 |
|---|---|---|
| 원본 | `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/source.mp3` | PASS |
| 출처 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/SOURCE.md` | PASS |
| 생성 기록 | `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/generation.json` | PASS |
| 런타임 | `assets/audio/ambience/stage04_citadel.wav` | PASS |
| 매니페스트 | `tools/audio/lyria_v122_manifest.json` | `ambience_stage04_citadel.status=active` |

- Source MP3: 2,785,295 bytes, SHA-256 `1e074c81577eea8de9cc1172be4660e19c4b0be05fd212890b33d8bf3507a3b5`
- Runtime WAV: 20,074,508 bytes, SHA-256 `822931aba98163f27c685fe579afa56b5b127f1970573b3b41c67290a1bc9207`
- Runtime WAV: stereo, 44,100 Hz, 16-bit, 113.800816초
- `SOURCE.md`: Lyria Pro 모델, 생성일, v1.2.2, source/runtime 경로, SHA-256, SynthID, 명시적 promote 승인 기록을 포함한다.
- `generation.json`: `store=false`, 모델·prompt SHA·source SHA를 포함한다.

## 3. 직접 실행 결과

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| 사전 대상 확인 | runtime/source/기록 미존재 및 manifest `planned` 확인 | PASS |
| 승격 1차 시도 | `promote --run 20260805_stage04_loop_take01 ... --confirm` | 경로 검증에서 중단, 파일 변경 없음 |
| 승격 재시도 | `promote --run tmp/lyria_audio_v122/20260805_stage04_loop_take01 --asset ambience_stage04_citadel --take 1 --confirm` | PASS |
| 매니페스트 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — `assets=80`, `coverage=all-current-wav` |
| 제품 파일 대조 | source/runtime SHA, WAV 메타데이터, manifest active | PASS |
| 출처 필드 | `SOURCE.md` 필수 고정 필드와 승인 기록 | PASS |
| 비밀값 점검 | source 기록·생성 기록 API 키 패턴 검사 | PASS — 0건 |

## 4. 테스트 상태와 차단 원인

기존 Lyria 파이프라인 단위 테스트 16개를 실행한 결과 15개는 통과했고 1개가 실패했다.

```text
FAIL: test_v122_planned_stage04_ambience_has_generation_contract
AssertionError: 'planned' != 'active'
```

실패 원인은 이번 승격으로 정상적으로 `active`가 된 Stage 04 manifest를 테스트가 아직 `planned`와 runtime 미존재 상태로 고정해 둔 것이다. 현재 패킷의 `ALLOWED_WRITE_PATHS`에는 `tools/audio/test_lyria_pipeline.py`가 없어 해당 테스트를 임의로 수정하지 않았다.

| 검수 | 결과 | 비고 |
|---|---|---|
| v1.2.2 manifest validate | PASS | 80개 coverage |
| source/runtime·출처·민감정보 직접 검증 | PASS | 본 문서 2~3절 |
| `python -m unittest tools.audio.test_lyria_pipeline -v` | BLOCKED | 16개 중 15개 통과, Stage 04 stale assertion 1개 실패 |
| 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

## 5. 범위 경계

- 추가 음원 생성 없음.
- catalog·AudioDirector·GameRoot·대표 화면 연결 없음.
- 테스트 파일은 허용 경로 밖이므로 변경하지 않았다.
- 커밋·스테이징·푸시는 하지 않았다.

## 6. 판정과 다음 순서

`A4_STAGE04_LOOP_PROMOTE_PASS_WITH_TEST_CONTRACT_ALIGNMENT_BLOCKED`

승인된 Stage 04 환경음의 제품 source/runtime 승격과 v1.2.2 coverage는 성공했다. 그러나 관련 단위 테스트의 stale assertion이 남아 있어 이번 패킷을 최종 PASS로 닫지 않는다. 다음 단일 패킷은 `A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT`이며, 테스트 계약을 active runtime 상태에 맞게 정렬하고 16/16을 재실행한다.

## 7. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 미커밋 혼합 작업 트리`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`
