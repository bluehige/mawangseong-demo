# V1.2.2 release polish handoff — A4 Stage 01 loop manifest contract

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-01-LOOP-MANIFEST-CONTRACT`
- 결과: `A4_STAGE01_LOOP_MANIFEST_CONTRACT_PASS`

## 2. 이번 패킷 목표

- 요청 사항: Stage 01 환경 loop 한 개를 생성 가능한 `planned` 자산으로 등록하고, runtime WAV가 아직 없어도 Lyria 사전 점검이 가능하게 한다.
- 완료 조건: 환경음 전용 kind와 planned 상태 검증, Stage 01 항목 1개 등록, 기존 runtime coverage 유지, 직접 테스트 통과.
- 범위에서 제외: 실제 유료 생성, API 키 사용, runtime WAV·출처 원본·event catalog·게임 연결·다음 패킷.

## 3. 완료한 작업

- `ambience_loop` kind를 추가해 음악 loop와 환경 loop의 프롬프트를 분리했다.
- manifest 자산 상태에 `active`와 `planned`를 추가했다. active 자산은 runtime WAV를 요구하고, planned 자산은 생성 전 runtime 부재를 허용한다.
- planned 자산도 runtime 경로 형식·중복·렌더 규격·모델·brief를 계속 검증한다.
- v1.2.2 manifest에 `ambience_stage01_cave`를 등록했다.
  - Stage: `stage_01_cave`
  - 계획 내용: 바람·먼 물방울·석재 울림
  - 모델: `lyria-3-pro-preview`
  - 렌더: 스테레오 44.1kHz, 120초, 2초 crossfade, -8dBFS
  - 상태: `planned`
  - runtime 예정 경로: `assets/audio/ambience/stage01_cave.wav`
- 기존 76개 runtime WAV와 v0.5 테스트 계약은 유지했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_pipeline.py` | `ambience_loop`와 `active/planned` manifest 검증·프롬프트·렌더 지원 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | planned Stage 01 항목 계약 테스트 추가 및 환경 loop 프롬프트 조건 정렬 | 완료 |
| `tools/audio/lyria_v122_manifest.json` | Stage 01 환경 loop 계획 항목 1개 등록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_MANIFEST_CONTRACT_2026-08-05.md` | 패킷 결과와 다음 단일 패킷 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 Luna 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델: 아직 호출하지 않음. 계획 모델만 `lyria-3-pro-preview`로 고정
- 생성 원본 경로: 없음
- `SOURCE.md` 경로: 없음
- 런타임 최종 자산 경로: 없음. `assets/audio/ambience/stage01_cave.wav`는 다음 생성·승격 뒤에만 생김
- 프롬프트 요약: 멜로디·리듬·음성 없이 동굴 바람, 먼 물방울, 석재 반향을 중심으로 한 환경 loop
- 게임 연결 및 실제 렌더 확인 결과: 연결하지 않음. 이번 패킷은 계약만 다룸

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 13개 | 터미널 실행 결과 |
| 2 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — 77개 항목, 현재 runtime coverage 유지 | 터미널 실행 결과 |
| 3 | `generate --asset ambience_stage01_cave --takes 1 --run-id 20260805_stage01_contract_dryrun` | PASS — 네트워크·유료 호출 없음, 예상 `$0.08` | 터미널 실행 결과 |
| 4 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 5 | 시각/실플레이·사람 청취 | NOT_REQUESTED | 다음 자산 승인 gate에서 수행 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않음
- PASS 이후 기능·데이터·자산 변경 여부: 이 핸드오프 이후 해당 패킷 범위의 기능·데이터·자산 변경 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- `ambience_stage01_cave`는 계획 상태이며 실제 음원·출처 기록·runtime 파일이 없다.
- planned 항목을 실제로 생성할 때도 `--execute`는 별도 사용자 승인 범위로 취급한다.
- 생성 뒤에는 사람 청취로 분위기, 반복 이음새, 전투 효과음과의 충돌, x3 밀도를 확인해야 한다.
- 승인 전에는 `promote --confirm`을 실행하지 않는다.
- 기존 작업 트리는 혼합 상태이므로 이번 패킷의 세 파일 외 변경은 스테이징하지 않는다.

## 8. 다음 작업 순서

1. `A4-STAGE-01-LOOP-GENERATION-TAKE01`: 계획된 `ambience_stage01_cave`만 Lyria 3 Pro take 1개로 생성한다. 예상 요청은 1회·`$0.08`이며, 실패 시 자동 재호출하지 않는다.
2. 생성 후보를 남기고 중단한다. runtime 승격과 출처 문서 작성은 다음 승인 패킷으로 분리한다.
3. 사용자가 후보를 청취해 승인·재생성·폐기 중 하나를 결정한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존부터 다수의 수정·미추적 파일이 있는 혼합 작업 트리
- 이번 패킷의 의도한 변경: 위 코드·테스트·manifest·핸드오프·CURRENT
- 의도하지 않은 기존 변경: 보존했고 되돌리거나 스테이징하지 않음
- 스태시 또는 별도 작업공간: 사용하지 않음
- 빌드/캡처 산출물 위치: 빌드 없음. dry-run은 `tmp/`에 파일을 만들지 않음

## 10. 종료 체크리스트

- [x] planned Stage 01 manifest 계약 구현
- [x] 관련 단위 테스트 13개 통과
- [x] 유료 API 호출 없이 Stage 01 1개 dry-run 통과
- [x] 전체 회귀·검수 에이전트는 요청되지 않아 실행하지 않음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] Stage 01 후보 생성·사람 청취·승인
- [ ] runtime 승격·event catalog·게임 연결
- [ ] 의도한 파일만 커밋 및 원격 푸시
