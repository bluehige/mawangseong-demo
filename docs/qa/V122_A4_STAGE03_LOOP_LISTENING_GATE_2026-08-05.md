# V1.2.2 Stage 03 환경음 loop 청취 승인 QA

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷 ID: `A4-STAGE-03-LOOP-LISTENING-GATE`
- 결과: `A4_STAGE03_LOOP_LISTENING_GATE_PASS`

## 2. 패킷 목표와 범위

- 목표: 생성된 `ambience_stage03_keep` take 01을 사용자 청취 승인 게이트에서 판정한다.
- 승인 기록: 사용자가 이번 대화에서 `승인했고 다음거 진행해`라고 명시했다.
- 완료 조건: 승인된 후보 한 개 재확인, source/runtime 승격 전 경계 유지, 다음 승격 패킷 제안
- 범위에서 제외: 추가 생성·재생성·`promote --confirm`·source/runtime 복사·manifest/catalog/GameRoot 변경·Stage 01/02/04·발소리

## 3. 승인 후보

| 구분 | 경로 | 상태 |
|---|---|---|
| 승인 source 후보 | `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/source.mp3` | 승인 |
| 승인 preview 후보 | `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/preview.wav` | 승인 |
| 생성 기록 | `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/generation.json` | 재확인 |
| preview 기록 | `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/preview.json` | 재확인 |

승인 범위는 `take-01` 하나로 한정한다. 추가 take나 자동 재호출은 실행하지 않았다.

## 4. 재확인 결과

| 검증 | 결과 | 세부 결과 |
|---|---|---|
| 후보 take 수 | PASS | `take-01` 디렉터리 1개, 파일 4개 |
| source MP3 SHA-256 | PASS | `e0a9292ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348` |
| preview WAV SHA-256 | PASS | `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9` |
| source/preview 메타데이터 연결 | PASS | 두 JSON의 source SHA와 실제 MP3 일치 |
| WAV 형식 | PASS | stereo, 44,100 Hz, 16-bit |
| WAV 실제 길이 | 확인 기록 | `112.285714초`; render 기록 계약 `120.0초` |
| 민감정보 패턴 | PASS | 후보 4개 파일에서 API 키·`GEMINI_API_KEY` 0건 |
| runtime/source 정식 경로 | PASS | `assets/audio/ambience/stage03_keep.wav` 및 Stage 03 source 경로가 아직 없음 |

120초 계약과 실제 Lyria 반환 길이의 차이는 생성·청취 기록에 남기며, 승인 결정으로 후보를 선택하되 임의 패딩이나 재생성은 하지 않는다.

## 5. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE03_LOOP_LISTENING_GATE_2026-08-05.md` | 사용자 승인·후보 재확인 기록 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE03_LOOP_LISTENING_GATE_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 승격 패킷 갱신 | 완료 |

코드·데이터·manifest·catalog·GameRoot·source/runtime 자산은 변경하지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 후보 WAV 존재·WAV 메타데이터 read-only 판독 | PASS — 2ch, 44.1kHz, 16-bit, 112.285714초 | 터미널 실행 결과 |
| 2 | source/preview SHA-256과 JSON 메타데이터 비교 | PASS | 후보 `generation.json`·`preview.json` |
| 3 | 후보 파일 민감정보 패턴 검사 | PASS — 0건 | 후보 디렉터리 |
| 4 | 사용자 후보 청취 | PASS — 사용자 `승인` | 이번 대화 승인 기록 |
| 5 | 전체 회귀·검수 에이전트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 다음 순서

- 승인 후보는 아직 제품 source/runtime 경로로 복사하지 않았다.
- 다음 단일 패킷 `A4-STAGE-03-LOOP-PROMOTE`에서 승인된 take 01만 승격한다.
- 승격 후 event catalog와 GameRoot 연결은 별도 패킷으로 분리한다.
