# V1.2.2 릴리스 폴리시 핸드오프 — A4 Stage 04 승격 후 테스트 계약 정렬

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `v1.2.2`
- 패킷 ID: `A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치와 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 작업 결과: `TARGETED_PASS`

## 2. 목표와 완료 내용

Stage 04 source/runtime 승격 뒤 남아 있던 테스트 계약 불일치를 해소했다. Stage 04 자산은 이미 이전 패킷에서 승격됐으며, 이번 패킷은 테스트 파일과 문서만 변경했다.

- stale planned 테스트를 active runtime 테스트로 정렬했다.
- Lyria 파이프라인 단위 테스트 16/16을 통과했다.
- v1.2.2 manifest 80개 coverage 검증을 통과했다.
- 추가 API 호출·오디오 자산 변경·게임 연결은 하지 않았다.

## 3. 변경 경로

- `tools/audio/test_lyria_pipeline.py`
- `docs/qa/V122_A4_STAGE04_LOOP_PROMOTE_TEST_ALIGNMENT_2026-08-05.md`
- `docs/handoff/V122_RELEASE_POLISH_A4_STAGE04_LOOP_PROMOTE_TEST_ALIGNMENT_2026-08-05.md`
- `docs/handoff/CURRENT.md`

## 4. 테스트와 검수

- `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` — PASS (16/16)
- `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` — PASS (`assets=80`, `coverage=all-current-wav`)
- `git diff --check` — PASS (기존 줄바꿈 경고만 출력)
- 전체 회귀·전체 플레이·검수 에이전트 — `NOT_REQUESTED`

### 정책 CI용 최종 확인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 5. 자산과 연결 상태

- Stage 04 runtime/source/`SOURCE.md`/generation 기록: 이전 승격 패킷에서 완료.
- 이번 패킷에서는 source/runtime·manifest를 다시 쓰지 않았다.
- Stage 04 event catalog, GameRoot·AudioDirector, 대표 화면: 아직 연결하지 않았다.

## 6. 다음 단일 패킷

`A4-STAGE-04-LOOP-CATALOG-CONNECT`

- 목표: Stage 04 환경음 event catalog 항목 하나를 등록하고 catalog 계약 테스트를 통과시킨다.
- 금지: 추가 음원 생성·source/runtime 변경·manifest 변경·GameRoot·AudioDirector·대표 화면·다음 패킷 자동 실행.
- 다음 세션은 `docs/handoff/CURRENT.md`의 `NEXT_PACKET_ID`를 기준으로 시작한다.

## 7. 작업 트리

- 혼합 작업 트리이며 기존 사용자·Luna 변경을 보존했다.
- 이번 패킷은 커밋·스테이징·푸시하지 않았다.
