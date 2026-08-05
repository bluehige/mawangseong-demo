# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 04 loop 승격

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-04-LOOP-PROMOTE`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 작업 결과: `TARGETED_BLOCKED`

## 2. 목표와 완료 내용

사용자가 청취 승인한 Stage 04 환경음 take 01을 제품 source/runtime으로 승격하고 출처·생성 기록과 v1.2.2 manifest를 정렬했다. 승격 산출물과 직접 자산 검증은 성공했지만, 기존 테스트의 Stage 04 `planned` 고정 단언 1개가 남아 있어 테스트 계약 보정 패킷으로 넘긴다.

- `promote --confirm` 승격 성공.
- source MP3, `SOURCE.md`, `generation.json`, runtime WAV 생성.
- manifest의 `ambience_stage04_citadel` 상태를 `planned`에서 `active`로 전환.
- source/runtime SHA, WAV 메타데이터, 출처 필드, 민감정보 패턴 검증 PASS.
- 추가 생성 및 게임 연결 없음.

## 3. 변경 경로

- `assets/audio/ambience/stage04_citadel.wav`
- `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/source.mp3`
- `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/SOURCE.md`
- `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/generation.json`
- `tools/audio/lyria_v122_manifest.json`
- `docs/qa/V122_A4_STAGE04_LOOP_PROMOTE_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_PROMOTE_2026-08-05.md`
- `docs/handoff/CURRENT.md`

이번 패킷에서는 `tools/audio/test_lyria_pipeline.py`를 허용 경로 밖이라 변경하지 않았다.

## 4. 오디오 자산과 출처

- 자산 ID: `ambience_stage04_citadel`
- 생성 모델: `lyria-3-pro-preview`
- 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage04_citadel/source.mp3`
- 런타임 경로: `assets/audio/ambience/stage04_citadel.wav`
- 원본 SHA-256: `1e074c81577eea8de9cc1172be4660e19c4b0be05fd212890b33d8bf3507a3b5`
- 런타임 SHA-256: `822931aba98163f27c685fe579afa56b5b127f1970573b3b41c67290a1bc9207`
- 런타임 형식: stereo / 44,100 Hz / 16-bit / 113.800816초
- `SOURCE.md`: 생성 모델·생성일·대상 버전·source/runtime 경로·SHA-256·SynthID·명시적 promote 승인 기록을 포함한다.
- `generation.json`: `store=false`와 prompt/source SHA를 포함한다.

## 5. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` — PASS (`assets=80`, `coverage=all-current-wav`)
- 제품 파일 대조 — PASS (source/runtime 해시, WAV 메타데이터, manifest active)
- 출처 필드와 비밀값 점검 — PASS (API 키 패턴 0건)
- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` — BLOCKED (15/16 통과, `test_v122_planned_stage04_ambience_has_generation_contract`가 `planned`를 기대)
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`

### 정책 CI용 최종 확인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`

## 6. 다음 단일 패킷

`A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT`

- 목표: Stage 04 active runtime 상태에 맞게 `tools/audio/test_lyria_pipeline.py`의 stale assertion을 정렬하고 전체 Lyria 파이프라인 단위 테스트 16/16을 통과시킨다.
- 금지: source/runtime 재복사, 추가 생성, catalog, GameRoot, AudioDirector, 대표 화면, 다음 패킷 자동 실행.
- 현재 제품 자산은 이미 승격됐으며, 다음 패킷은 테스트 계약만 보정한다.

## 7. 작업 트리

- 혼합 작업 트리이며 기존 사용자·Luna 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
- `docs/handoff/CURRENT.md`는 테스트 계약 보정 패킷을 다음 작업으로 가리킨다.
