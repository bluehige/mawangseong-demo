# v1.2.2 release polish handoff — A4 Stage 03 loop manifest contract

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-03-LOOP-MANIFEST-CONTRACT`
- 결과: `A4_STAGE03_LOOP_MANIFEST_CONTRACT_PASS`
- QA: `docs/qa/V122_A4_STAGE03_LOOP_MANIFEST_CONTRACT_2026-08-05.md`

## 2. 이번 패킷 목표와 범위

Stage 03 환경 loop 1개를 `planned` manifest 항목으로 등록하고 기존 Lyria 생성·비용·coverage 계약을 검증한다. 이번 패킷에서는 유료 생성, API 키 사용, source/runtime 승격, event catalog, GameRoot, Stage 01·02·04, 발소리, 다음 패킷 실행을 제외한다.

## 3. 완료 내용

- `ambience_stage03_keep`를 `stage_03_keep`에 연결된 `ambience_loop` planned 항목으로 등록했다.
- 모델은 `lyria-3-pro-preview`, 예정 runtime은 `assets/audio/ambience/stage03_keep.wav`로 고정했다.
- 렌더 계약은 스테레오 44.1kHz, 120초, 2초 crossfade, -8dBFS다.
- 높은 석조 성채의 차가운 공기·먼 깃발과 사슬·드문 석조 잔향을 prompt brief로 기록했다.
- manifest는 79개 항목, active runtime coverage는 기존 78개를 유지하며, Lyria Pro 계획 수는 6개, 기본 2-take 예상 비용은 `$6.80`이 된다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_v122_manifest.json` | Stage 03 planned ambience 1개 등록 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 수량·비용·Stage 03 planned 계약 테스트 | 완료 |
| `docs/qa/V122_A4_STAGE03_LOOP_MANIFEST_CONTRACT_2026-08-05.md` | 직접 검수와 결과 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_MANIFEST_CONTRACT_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 단일 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델 호출: 없음. 계획 모델만 `lyria-3-pro-preview`로 고정
- 생성 원본·SOURCE.md·runtime 최종 자산: 없음
- 게임 연결 및 실제 청취: 실행하지 않음. planned 계약 패킷 범위 밖이다.

## 6. 테스트 및 검수

| 순서 | 검수 | 결과 |
|---:|---|---|
| 1 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 15개 |
| 2 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — 79개 항목, active runtime coverage 일치 |
| 3 | Stage 03 `generate --asset ambience_stage03_keep --takes 1 --run-id 20260805_stage03_contract_dryrun` | PASS — 유료 호출 없음, 예상 `$0.08` |
| 4 | 전체 회귀·검수 에이전트 | NOT_REQUESTED |
| 5 | UI·실플레이·사람 청취 | NOT_REQUESTED — runtime 자산 생성 전 계약 패킷 |

정책 필드:

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 및 다음 작업

- Stage 03 후보 음원과 source/runtime 승격은 아직 없다.
- 다음 단일 패킷은 `A4-STAGE-03-LOOP-GENERATION-TAKE01`이며 take 1개 생성만 처리한다.
- 생성 후보의 사용자 청취·승인은 생성 패킷 이후 별도 gate로 둔다.
- 혼합 작업 트리의 기존 변경은 보존했고, 커밋·푸시는 실행하지 않았다.

## 8. 종료 체크리스트

- [x] Stage 03 planned manifest 항목 1개 등록
- [x] active runtime coverage 유지 확인
- [x] 관련 단위 테스트·manifest validate·dry-run 통과
- [x] 유료 API 호출·음원 생성·runtime 승격·게임 연결 미실행
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] Stage 03 후보 생성·사람 청취·승인
- [ ] 의도한 파일만 커밋 및 원격 푸시
