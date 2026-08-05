# V122 A4 Stage 02 catalog 연결 QA

## 패킷과 범위

- 패킷 ID: `A4-STAGE-02-LOOP-CATALOG-CONNECT`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE02_LOOP_CATALOG_CONNECT_PASS`

승격된 `ambience_stage02_indoor`를 audio event catalog의 매니페스트 자산 목록에 추가했다. 아직 GameRoot의 실제 호출 owner가 없으므로 `runtime_connection=unconnected`, `events=[]`로 기록했다. catalog 정책이 실제 runtime 호출만 이벤트로 허용하므로 가짜 이벤트는 만들지 않았다.

## catalog 변경 결과

| 항목 | 결과 |
|---|---:|
| 매니페스트·catalog 자산 | 78 |
| 실제 runtime 연결 자산 | 67 |
| data-only 자산 | 0 |
| 미연결 자산 | 11 |
| catalog 실제 runtime 이벤트 | 69 |
| Lyria 출처 자산 | 30 |
| SFX 버스 자산 | 72 |

Stage 02 등록 정보:

- ID: `ambience_stage02_indoor`
- Runtime: `assets/audio/ambience/stage02_indoor.wav`
- 종류: `ambience_loop`
- 버스: `SFX`
- 출처: `lyria`
- 출처 기록: `assets/source/audio/lyria/v1.2.2/ambience_stage02_indoor/SOURCE.md`
- 연결 상태: `unconnected`
- 이벤트: `[]`
- 미해결 사유: 게임 호출 owner가 아직 없어 runtime 이벤트가 연결되지 않음

## 직접 검증

| 검사 | 명령 또는 방법 | 결과 |
|---|---|---|
| catalog 계약 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_audio_event_catalog -v` | PASS — 8/8 |
| Stage 02 전용 단언 | catalog 자산·runtime 경로·출처·unconnected·미해결 목록 확인 | PASS |
| JSON 구문 | `data/audio/audio_event_catalog.json` UTF-8 JSON 파싱 | PASS |
| UI·실제 청취 | catalog-only 패킷 | `NOT_REQUESTED` |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 요청되지 않음 | `NOT_REQUESTED` |

## 미해결과 다음 순서

Stage 02 WAV는 제품 runtime 경로와 catalog 자산 목록에 있지만 실제 게임 재생 이벤트는 아직 없다. 다음은 `A4-STAGE-02-LOOP-RUNTIME-CONNECT` 단일 패킷으로 GameRoot의 Stage 02 ambience 재생 경로, catalog 실제 이벤트 한 개, 관련 직접 테스트를 연결한다. 대표 화면·실제 청취는 runtime 연결 뒤 별도 확인 범위다.

## 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A` — 전체 검수 미요청
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
