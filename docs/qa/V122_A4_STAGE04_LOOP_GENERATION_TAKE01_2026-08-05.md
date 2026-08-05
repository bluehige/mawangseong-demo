# V1.2.2 Stage 04 환경 loop 생성 take 01 QA

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 생성 전 세션 HEAD: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷 ID: `A4-STAGE-04-LOOP-GENERATION-TAKE01`
- 결과: `A4_STAGE04_LOOP_GENERATION_TAKE01_PASS_PENDING_LISTENING`

## 2. 목표와 범위

- 목표: `ambience_stage04_citadel` 환경 loop 후보를 Lyria Pro로 take 01 한 개 생성한다.
- 실제 유료 요청: `lyria-3-pro-preview` 1회
- 예상 비용: `$0.08`
- CLI run ID: `20260805_stage04_loop_take01`
- 최종 실행 manifest: `tools/audio/lyria_v122_manifest.json`
- 제외 범위: 추가 take, 자동 재호출, source/runtime 승격, `SOURCE.md`, catalog 연결, GameRoot·AudioDirector 연결, 대표 화면 검수

## 3. 생성 결과

최종 실행은 v1.2.2 manifest를 명시한 보안 실행 래퍼에서 완료됐다. 앞선 두 번의 실행은 구형 기본 manifest를 읽는 사전검증에서 중단됐으며 API 요청은 발생하지 않았다. API 키는 파일·명령 인자·생성 기록에 저장하지 않았다.

| 경로 | 크기 | SHA-256 | 상태 |
|---|---:|---|---|
| `tmp/lyria_audio_v122/20260805_stage04_loop_take01/plan.json` | 211 bytes | `879d2bf1...` | PASS |
| `tmp/lyria_audio_v122/20260805_stage04_loop_take01/ambience_stage04_citadel/take-01/source.mp3` | 2,785,295 bytes | `1e074c81577eea8de9cc1172be4660e19c4b0be05fd212890b33d8bf3507a3b5` | PASS |
| `tmp/lyria_audio_v122/20260805_stage04_loop_take01/ambience_stage04_citadel/take-01/generation.json` | 1,480 bytes | `33d2a759...` | PASS |
| `tmp/lyria_audio_v122/20260805_stage04_loop_take01/ambience_stage04_citadel/take-01/preview.wav` | 20,074,508 bytes | `822931aba98163f27c685fe579afa56b5b127f1970573b3b41c67290a1bc9207` | PASS |
| `tmp/lyria_audio_v122/20260805_stage04_loop_take01/ambience_stage04_citadel/take-01/preview.json` | 508 bytes | `6c6a78a1...` | PASS |

생성 기록은 모델 `lyria-3-pro-preview`, API `v1beta/interactions`, `target_version=v1.2.2`, `store=false`, MIME `audio/mpeg`를 기록한다. 상호작용 ID는 응답에 없어 비어 있으며, 이는 파이프라인이 허용하는 preview 응답 상태다.

## 4. 기계 검증

| 검증 | 결과 | 근거 |
|---|---|---|
| 실제 유료 요청 1회·take 1개 | PASS | 최종 run 디렉터리와 `plan.json` |
| MP3 컨테이너·프레임·메타데이터 | PASS | ID3v2, MPEG-1 Layer III, 192 kbps, 44.1 kHz, stereo, 4,433 frames, 약 115.801초 |
| WAV 메타데이터 | PASS | PCM 16-bit, 2 channels, 44,100 Hz, 5,018,616 frames, 실제 113.800816초 |
| WAV render 계약 | PASS | 목표 120초의 80% 이상이며 preview render 계약과 일치 |
| source SHA와 `generation.json` 일치 | PASS | `1e074c81577eea8de9cc1172be4660e19c4b0be05fd212890b33d8bf3507a3b5` |
| preview SHA와 `preview.json` 일치 | PASS | `822931aba98163f27c685fe579afa56b5b127f1970573b3b41c67290a1bc9207` |
| 민감정보 패턴 검사 | PASS | 후보 폴더의 JSON·문서에서 API 키 패턴 0건 |
| take 수 정확성 | PASS | `take-01`만 존재 |

실제 WAV는 render 목표 120초보다 짧은 113.800816초다. 파이프라인의 최소 길이 계약은 통과했지만 loop seam과 반복감은 다음 사용자 청취 게이트에서 최종 판단한다.

## 5. 게임 자산 상태

- runtime 최종 자산: 아직 없음. `assets/audio/ambience/stage04_citadel.wav`로 승격하지 않았다.
- 출처 원본 경로: 아직 없음. `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/`로 복사하지 않았다.
- `SOURCE.md`, catalog, GameRoot·AudioDirector 연결: 변경하지 않았다.
- 이번 단계의 후보는 `tmp/`에만 보관한다.

## 6. 테스트와 검수

| 순서 | 검증 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | 보안 래퍼에서 v1.2.2 manifest를 명시한 Lyria Pro `generate --execute` 1회 | PASS | 후보 run 디렉터리 |
| 2 | MP3/WAV 메타데이터·SHA-256·민감정보 패턴 직접 검사 | PASS | 본 문서 3~4절 |
| 3 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS, 16/16 | 테스트 출력 |
| 4 | `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS | `manifest=OK assets=80 coverage=all-current-wav` |
| 5 | `git diff --check` | PASS | 공백 오류 없음; 기존 줄바꿈 경고만 출력 |
| 6 | 사용자 청취 | PENDING | 다음 `A4-STAGE-04-LOOP-LISTENING-GATE` |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 이번 요청 범위 아님 |

### 정책 CI 최종 확인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 문제와 위험

- 후보의 실제 loop seam과 청취 품질은 아직 승인되지 않았다.
- 실제 preview 길이는 113.800816초로 manifest 목표 120초보다 짧다. 다음 청취 게이트에서 반복 시 이음새와 전투 중 공간감을 확인한다.
- 청취 승인 전에는 runtime 승격·source 기록·게임 연결을 진행하지 않는다.

## 8. 다음 작업 순서

1. `A4-STAGE-04-LOOP-LISTENING-GATE`: 사용자가 `preview.wav`를 직접 듣고 `승인`·`재생성`·`반려` 중 하나를 결정한다.
2. 승인 시 별도 `A4-STAGE-04-LOOP-PROMOTE` 패킷에서 source/runtime 승격과 `SOURCE.md`를 처리한다.
3. 재생성 시 별도 유료 생성 패킷으로 새 take 승인을 먼저 받는다.

## 9. 작업 트리 상태

- `git status --short --branch`: `codex/v122-ui-simplification...origin/codex/v122-ui-simplification [ahead 2]`
- 이번 패킷 신규 결과: 위 `tmp/lyria_audio_v122/20260805_stage04_loop_take01/` 후보와 본 QA 문서
- 미커밋 상태: 유지한다. 사용자·Luna의 기존 변경은 되돌리거나 정리하지 않았다.
- 커밋·푸시·PR: 실행하지 않았다.

## 10. 종료 체크리스트

- [x] Lyria 3 Pro 유료 요청 1회 완료
- [x] take 01 후보 MP3/WAV 생성
- [x] MP3/WAV 메타데이터와 SHA-256 확인
- [x] 민감정보 패턴 확인
- [x] 관련 단위 테스트와 manifest 검증 통과
- [x] runtime·source·catalog·GameRoot 미변경 확인
- [x] `docs/handoff/CURRENT.md` 다음 패킷 갱신
- [ ] 사용자 청취 승인
