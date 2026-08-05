# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 03 loop 청취 승인

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-03-LOOP-LISTENING-GATE`
- 결과: `A4_STAGE03_LOOP_LISTENING_GATE_PASS`
- QA: `docs/qa/V122_A4_STAGE03_LOOP_LISTENING_GATE_2026-08-05.md`

## 2. 이번 패킷 목표

- 요청 사항: Stage 03 `ambience_stage03_keep` 후보 take 01을 사용자 청취 승인 gate에서 확인한다.
- 완료 조건: 후보 파일 재확인, 사용자 `승인` 결정 기록, 승격 전 경계 유지
- 범위에서 제외: 추가 생성·재생성·`promote --confirm`·source/runtime 복사·manifest/catalog/GameRoot 변경·Stage 01/02/04·발소리

## 3. 완료한 작업

- 사용자가 Stage 03 preview WAV를 청취하고 `승인`했다.
- 승인 대상은 `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/`의 take 01 후보 한 개로 한정했다.
- preview WAV는 2채널·44.1kHz·16-bit·112.285714초로 재확인했다.
- preview/source SHA-256과 각 JSON 메타데이터의 SHA-256 일치를 재확인했다.
- 후보 파일에서 API 키·`GEMINI_API_KEY` 패턴 0건을 재확인했다.
- 코드·데이터·manifest·catalog·GameRoot·source/runtime은 변경하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE03_LOOP_LISTENING_GATE_2026-08-05.md` | 사용자 승인과 후보 재확인 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_LISTENING_GATE_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 승격 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- 생성 모델: Google `lyria-3-pro-preview` — 이전 생성 패킷에서 생성
- 승인 후보 source: `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/source.mp3`
- 승인 preview: `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/preview.wav`
- 원본 SHA-256: `e0a9292ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348`
- preview SHA-256: `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9`
- 최종 source/runtime: 아직 없음
- 게임 연결·실제 runtime 재생: 아직 없음
- 실제 길이와 계약: 112.285714초 / render 기록 120.0초. 승인 후보로 보존하고 다음 승격 패킷에서 값을 변경하지 않는다.

## 6. 테스트와 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 후보 WAV 존재·메타데이터 read-only 판독 | PASS — 2ch, 44.1kHz, 16-bit, 112.285714초 | 터미널 실행 결과, QA 문서 |
| 2 | preview/source SHA-256과 JSON 메타데이터 비교 | PASS | 후보 `preview.json`·`generation.json` |
| 3 | 후보 민감정보 패턴 검사 | PASS — 0건 | 후보 디렉터리 |
| 4 | 사용자 후보 청취 | PASS — 사용자 `승인` | 이번 대화 승인 기록 |
| 5 | 전체 회귀·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | N/A | 없음 | 없음 | QA 문서 | NOT_REQUESTED |

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 전체 회귀·게임 연결·별도 검수 에이전트는 사용자 요청 범위가 아님
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 문서만 추가·수정

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 승인 후보는 아직 제품 source/runtime 경로로 복사하지 않았다.
- 120초 render 계약과 실제 112.285714초 반환 길이 차이는 남아 있으며, 승인 후보의 실제 결과로 보존한다.
- 다음 승격 패킷에서 `SOURCE.md`, source MP3, generation 기록, runtime WAV와 manifest 상태를 정렬해야 한다.
- 승격 후 event catalog와 Stage 03 GameRoot 연결은 별도 패킷이다.

## 8. 다음 작업 순서

다음 단일 패킷만 제안한다.

`A4-STAGE-03-LOOP-PROMOTE`

- 목표: 승인된 `ambience_stage03_keep` take 01 하나만 source/runtime으로 승격하고 출처·생성 기록과 manifest 상태를 정렬한다.
- 허용 경로:
  - `assets/audio/ambience/stage03_keep.wav`
  - `assets/source/audio/lyria/v1.2.2/ambience_stage03_keep/` 안의 `source.mp3`, `SOURCE.md`, `generation.json`
  - `tools/audio/lyria_v122_manifest.json`
  - `tools/audio/test_lyria_pipeline.py`
  - `docs/qa/V122_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md`
  - `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_PROMOTE_2026-08-05.md`
  - `docs/handoff/CURRENT.md`
- 금지: 추가 음원 생성, 추가 take, catalog, GameRoot, AudioDirector, Stage 01/02/04, 발소리, 다음 패킷 자동 실행

## 9. 작업 트리

- 혼합 작업 트리이며 기존 사용자·Luna 변경을 보존했다.
- 이번 패킷은 QA·핸드오프·`CURRENT.md`만 추가·수정했다.
- 후보 산출물은 `tmp/lyria_audio_v122/20260805_stage03_loop_take01/`에 있다.
- 이번 패킷에서 커밋·스테이징·푸시는 하지 않았다.

## 10. 종료 체크리스트

- [x] 승인 후보 take 01 파일 재확인
- [x] 사용자 청취 `승인` 기록
- [x] source/runtime 승격 전 경계 유지
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] source/runtime 승격
- [ ] event catalog·GameRoot 연결
- [ ] 커밋·푸시·PR
