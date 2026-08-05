# v1.2.2 release polish handoff — A4 Stage 02 loop manifest contract

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-02-LOOP-MANIFEST-CONTRACT`
- 결과: `A4_STAGE02_LOOP_MANIFEST_CONTRACT_PASS`
- QA: `docs/qa/V122_A4_STAGE02_LOOP_MANIFEST_CONTRACT_2026-08-05.md`

## 2. 이번 패킷 목표

- 요청 사항: Stage 02 환경 loop 1개를 생성 가능한 `planned` 자산으로 등록하고 기존 manifest 계약을 검증한다.
- 완료 조건: `ambience_stage02_indoor` 항목 등록, active runtime coverage 유지, 환경 loop prompt/render 계약 통과, 유료 없는 1개 dry-run 통과.
- 범위에서 제외: `--execute` 유료 생성, API 키 사용, source/runtime 승격, event catalog, GameRoot 연결, Stage 01 수정, Stage 03~04, 발소리, 다음 패킷 실행.

## 3. 완료한 작업

- `ambience_stage02_indoor`를 v1.2.2 manifest에 등록했다.
  - Stage: `stage_02_indoor`
  - 계획 내용: 낮은 실내 공기, 드문 목재 삐걱임, 절제된 목재·금속 장치음
  - 모델: `lyria-3-pro-preview`
  - 렌더: 스테레오 44.1kHz, 120초, 2초 crossfade, -8dBFS
  - 상태: `planned`
  - runtime 예정 경로: `assets/audio/ambience/stage02_indoor.wav`
- planned 항목은 runtime 파일이 없어도 manifest를 통과시키고, active 항목만 현재 WAV coverage와 비교하도록 테스트를 정렬했다.
- 전체 manifest는 78개 항목, 현재 실제 WAV는 77개이며 coverage 검증은 통과했다.
- 전체 기본 2-take 예상 비용은 `$6.64`, Stage 02 1-take 예상 비용은 `$0.08`이다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_v122_manifest.json` | Stage 02 planned ambience 1개 등록 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | planned coverage·수량·비용·Stage 02 계약 테스트 | 완료 |
| `docs/qa/V122_A4_STAGE02_LOOP_MANIFEST_CONTRACT_2026-08-05.md` | 직접 검수와 결과 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE02_LOOP_MANIFEST_CONTRACT_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 단일 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델: 아직 호출하지 않음. 계획 모델만 `lyria-3-pro-preview`로 고정
- 생성 원본 경로: 없음
- `SOURCE.md` 경로: 없음
- 런타임 최종 자산 경로: 없음. `assets/audio/ambience/stage02_indoor.wav`는 생성·승격 전이다.
- 게임 연결 및 실제 렌더 확인 결과: 연결하지 않음. 이번 패킷은 manifest 계약만 다룬다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 14개 | 터미널 실행 결과, QA 문서 |
| 2 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — 78개 항목, 현재 WAV coverage 일치 | 터미널 실행 결과 |
| 3 | `generate --asset ambience_stage02_indoor --takes 1 --run-id 20260805_stage02_contract_dryrun` | PASS — 유료 호출 없음, 예상 `$0.08` | 터미널 실행 결과 |
| 4 | 전체 회귀 테스트·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 5 | UI·실플레이·사람 청취 | NOT_REQUESTED | runtime 자산 생성 전 계약 패킷 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- Stage 02 planned 항목은 실제 음원·출처 기록·runtime 파일이 없다.
- 다음 생성 패킷에서만 Lyria Pro 1회 호출을 별도로 승인받는다. 자동 재호출은 하지 않는다.
- 생성 후보는 사람 청취와 loop seam·전투 효과음 충돌·x3 밀도 확인 전까지 제품 자산으로 승격하지 않는다.
- 승인 전 `promote --confirm`, source/runtime 복사, catalog·GameRoot 연결을 실행하지 않는다.
- 혼합 작업 트리의 기존 변경은 보존했으며, 이번 패킷 허용 경로 밖 파일은 수정하지 않았다.

## 8. 다음 작업 순서

1. `A4-STAGE-02-LOOP-GENERATION-TAKE01`: `ambience_stage02_indoor`만 Lyria 3 Pro take 1개로 생성한다. 예상 요청은 1회·`$0.08`이며 자동 재호출하지 않는다.
2. 후보 MP3·preview WAV·generation 기록만 남기고 중단한다. runtime 승격과 출처 문서 작성은 다음 승인 패킷으로 분리한다.
3. 사용자가 후보를 청취해 승인·재생성·폐기 중 하나를 결정한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존 사용자·Luna 변경이 섞인 혼합 작업 트리
- 이번 패킷의 의도한 변경: manifest, pipeline 단위 테스트, QA·핸드오프·CURRENT
- 의도하지 않은 기존 변경: 보존했고 되돌리거나 스테이징하지 않음
- 원격 푸시: 하지 않음
- 빌드·캡처 산출물: 없음

## 10. 종료 체크리스트

- [x] Stage 02 planned manifest 항목 1개 등록
- [x] active runtime coverage 77개 유지 확인
- [x] 관련 단위 테스트 14개 통과
- [x] 유료 API 호출 없이 Stage 02 1개 dry-run 통과
- [x] runtime·source·catalog·게임 연결 미변경
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] Stage 02 후보 생성·사람 청취·승인
- [ ] runtime 승격·event catalog·게임 연결
- [ ] 의도한 파일만 커밋 및 원격 푸시
