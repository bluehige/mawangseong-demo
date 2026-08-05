# V1.2.2 release polish handoff — A4 Stage 01 loop listening gate

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-01-LOOP-LISTENING-GATE`
- 결과: `A4_STAGE01_LOOP_LISTENING_APPROVED_PENDING_PROMOTION`

## 2. 이번 패킷 목표

- 요청 사항: 생성된 Stage 01 환경 loop 후보를 사용자에게 청취 승인받고 결과를 기록한다.
- 완료 조건: 사용자의 `승인` 확인, 후보 파일 존재·무결성 재확인, runtime 승격 전 상태 유지.
- 범위에서 제외: 추가 생성·재생성·`promote --confirm`·runtime 복사·출처 문서·event catalog·게임 연결.

## 3. 완료한 작업

- 사용자가 `ambience_stage01_cave` 후보를 청취한 뒤 승인했다.
- 승인 결과: `approve`
- 승인 근거: 사용자가 채팅으로 “승인하고 다음거 진행해”라고 명시했다.
- 후보 디렉터리와 take 1개만 존재하는지 확인했다.
- MP3·WAV SHA-256과 WAV 형식을 재확인했다.
- runtime WAV와 `SOURCE.md` 출처 기록은 아직 만들지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_LISTENING_GATE_2026-08-05.md` | 사용자 청취 승인과 승격 전 경계 기록 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 승격 단일 패킷 갱신 | 완료 |
| `tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/` | 승인된 후보, Git 무시 | 승인 완료·승격 필요 |

## 5. 오디오 후보 검수

후보 경로:

`tmp/lyria_audio_v122/20260805_stage01_loop_take01/ambience_stage01_cave/take-01/`

| 파일 | 크기 | SHA-256 | 결과 |
|---|---:|---|---|
| `source.mp3` | 2,763,352 bytes | `499540007347C5454D53A4D7868446D423B1B9CB3BD6FC5BCEAC4952F2077711` | PASS |
| `preview.wav` | 19,913,228 bytes | `DDC51C7944BE024CFCB9576C8B712B4595D6ABEA2CE4D41A31F8D4C15449EA85` | PASS |

`preview.wav`는 2채널, 44.1kHz, 16bit, 112.887초다. 생성 폴더는 Google API 키 패턴 0건이며, runtime과 출처 기록은 아직 없다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 후보 디렉터리와 take 개수 확인 | PASS — take 1개 | 터미널 실행 결과 |
| 2 | MP3/WAV SHA-256 재계산 | PASS — 생성 핸드오프와 일치 | 터미널 실행 결과 |
| 3 | WAV 메타데이터 판독 | PASS — 2ch/44.1kHz/16bit/112.887s | 터미널 실행 결과 |
| 4 | 사용자 청취 승인 | PASS — `approve` | 사용자 메시지 |
| 5 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않음
- PASS 이후 기능·데이터·자산 변경 여부: runtime·출처·catalog 변경 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 승인된 후보는 아직 `tmp/`에만 있다.
- 다음 패킷에서 원본 MP3, 생성 JSON, `SOURCE.md`, runtime WAV를 제품 경로로 승격해야 한다.
- 승격할 때 manifest 상태를 `planned`에서 `active`로 바꾸고 runtime coverage를 다시 검증해야 한다.
- event catalog와 Stage 01 재생 연결은 승격 패킷 이후 별도 패킷으로 진행한다.

## 8. 다음 작업 순서

1. `A4-STAGE-01-LOOP-PROMOTE`: 승인된 take 1개만 제품 source/runtime 경로로 승격하고 manifest를 `active`로 전환한다.
2. 승격 직후 manifest coverage·source hash·WAV 형식을 직접 검증한다.
3. 승격 패킷이 끝난 뒤에만 event catalog와 Stage 01 runtime 연결을 별도 패킷으로 제안한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존부터 다수의 수정·미추적 파일이 있는 혼합 작업 트리
- 이번 패킷의 추적 대상 변경: 이 핸드오프와 `CURRENT.md`
- 후보 산출물: `tmp/lyria_audio_v122/20260805_stage01_loop_take01/`
- runtime/출처 변경: 없음
- 원격 푸시: 하지 않음

## 10. 종료 체크리스트

- [x] 사용자 청취 승인 기록
- [x] 후보 파일·해시·WAV 형식 재확인
- [x] 승인 전 runtime 승격 금지 유지
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] source/runtime 승격
- [ ] event catalog·게임 연결
- [ ] 의도한 파일만 커밋·원격 푸시
