# V1.2.2 Stage 03 환경음 loop 생성 take 01 QA

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 생성 전 세션 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷 ID: `A4-STAGE-03-LOOP-GENERATION-TAKE01`
- 결과: `A4_STAGE03_LOOP_GENERATION_TAKE01_PASS_PENDING_LISTENING`

## 2. 패킷 목표와 범위

- 목표: `ambience_stage03_keep` 후보를 Google `lyria-3-pro-preview`로 take 1개 생성한다.
- 실제 요청: Lyria Pro 유료 호출 1회
- 예상 비용: `$0.08`
- CLI run ID: `20260805_stage03_loop_take01`
- 프롬프트 범위: 고성의 높은 석조 공간, 차가운 높은 천장 공기, 먼 깃발·사슬 움직임, 드문 석재 잔향. 멜로디·보컬·리듬 베드 없음.
- 범위에서 제외: 추가 take, 자동 재호출, 사용자 청취, runtime/source 승격, `SOURCE.md`, event catalog, GameRoot 연결

## 3. 생성 산출물

| 경로 | 크기 | SHA-256 | 상태 |
|---|---:|---|---|
| `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/source.mp3` | 2,748,933 bytes | `e0a9292ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348` | PASS |
| `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/preview.wav` | 19,807,244 bytes | `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9` | PASS |
| `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/generation.json` | 1,417 bytes | 기록 파일 | PASS |
| `tmp/lyria_audio_v122/20260805_stage03_loop_take01/ambience_stage03_keep/take-01/preview.json` | 505 bytes | 기록 파일 | PASS |

생성 기록은 `lyria-3-pro-preview`, `v1beta/interactions`, `v1.2.2`를 기록한다. CLI `run ID`는 후보 디렉터리와 본 문서에 보존했으며 API 키는 파일이나 문서에 저장하지 않았다.

## 4. 기계 검증

| 검증 | 결과 | 근거 |
|---|---|---|
| `generate --execute` 실제 요청 1회 | PASS | `generation.json` 및 후보 디렉터리 |
| take 수가 정확히 1개인지 확인 | PASS | `take-01`만 존재, 파일 4개 |
| MP3 SHA-256과 `generation.json` 기록 일치 | PASS | `e0a929ca72fa882509b19df068913c05ead1880628e01409e39c991ef730348` |
| WAV SHA-256과 `preview.json` 기록 일치 | PASS | `6abaec6c11e9a152b0f161ab8a73dd2f4a7d4c1f1467c7e321f65e8088b436f9` |
| WAV 채널·샘플레이트·샘플 폭 | PASS | stereo, 44,100 Hz, 16-bit |
| 민감정보 패턴 검사 | PASS | 후보 4개 파일에서 API 키·`GEMINI_API_KEY` 패턴 0건 |
| 실제 WAV 길이 | 확인 필요 | 실제 `112.285714초`, 기록된 render 계약 `120.0초` |

실제 길이 차이는 Lyria가 반환한 원본 길이를 보존한 결과이며, 기존 Stage 01 후보에서도 같은 유형의 약 112초 출력이 확인됐다. 이번 패킷에서는 오디오를 임의로 늘리거나 재생성하지 않고, 다음 사람 청취 게이트에서 loop 감각과 길이 허용 여부를 결정한다.

## 5. 게임 자산 상태

- runtime 최종 자산: 아직 없음. `assets/audio/ambience/stage03_keep.wav`로 승격하지 않음.
- 출처 원본 정식 경로: 아직 없음. `assets/source/audio/lyria/v1.2.2/...`로 승격하지 않음.
- event catalog/GameRoot 연결: 변경 없음.
- 이번 단계는 후보 산출물만 `tmp/`에 보존한다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | Lyria `generate --execute --asset ambience_stage03_keep --takes 1 --run-id 20260805_stage03_loop_take01` | PASS | 후보 디렉터리 |
| 2 | MP3/WAV 파일 목록·메타데이터·SHA-256·민감정보 패턴 검사 | PASS, 길이 차이는 청취 gate로 이관 | 본 문서 3~4절 |
| 3 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 4 | 사람 청취 | PENDING | 다음 `A4-STAGE-03-LOOP-LISTENING-GATE` |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 다음 작업

1. `A4-STAGE-03-LOOP-LISTENING-GATE`: 사용자가 `preview.wav`를 직접 듣고 `승인`, `재생성`, `폐기` 중 하나를 결정한다.
2. 사용자 승인 전에는 추가 take와 `promote`를 실행하지 않는다.
3. 승인된 경우에만 별도 단일 패킷에서 source/runtime와 `SOURCE.md`를 승격한다.
