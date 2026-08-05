# V1.2.2 Stage 04 승격 후 테스트 계약 정렬 QA

## 1. 패킷과 범위

- 패킷 ID: `A4-STAGE-04-LOOP-PROMOTE-TEST-ALIGNMENT`
- 목표 버전: `v1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 작업 시작 기준 HEAD/마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 결과: `A4_STAGE04_LOOP_PROMOTE_TEST_ALIGNMENT_PASS`

이번 패킷은 이미 승격된 Stage 04 자산을 변경하지 않고, `planned` 상태를 기대하던 stale 테스트 1개를 `active` runtime 계약에 맞게 정렬했다.

## 2. 변경 내용

- `tools/audio/test_lyria_pipeline.py`
  - Stage 04 테스트 이름을 `test_v122_active_stage04_ambience_has_runtime_after_promotion`으로 정렬했다.
  - manifest 상태 기대값을 `active`로 바꿨다.
  - runtime WAV 존재 단언을 `is_file()` 기준으로 바꿨다.
  - Stage ID·모델·프롬프트·render·비용 계약은 유지했다.
- 오디오 파일, source 기록, manifest, catalog, GameRoot, AudioDirector는 변경하지 않았다.

## 3. 검증 결과

| 검증 | 명령 | 결과 |
|---|---|---|
| Lyria 파이프라인 단위 테스트 | `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 16/16 |
| v1.2.2 manifest | `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — `assets=80`, `coverage=all-current-wav` |
| 변경 범위 공백 검사 | `git diff --check` | PASS — 기존 줄바꿈 경고만 출력 |
| 전체 회귀·전체 플레이·검수 에이전트 | 이번 패킷에서 실행하지 않음 | `NOT_REQUESTED` |

실패했던 `test_v122_planned_stage04_ambience_has_generation_contract`는 active 승격 상태를 반영한 이름과 단언으로 교체됐고, 전체 16개가 다시 통과했다.

## 4. 범위 경계

- Stage 04 runtime/source를 재복사하거나 재생성하지 않았다.
- 추가 유료 API 호출은 없었다.
- catalog, GameRoot, AudioDirector, 대표 화면은 변경하지 않았다.
- 커밋·스테이징·푸시는 하지 않았다.

## 5. 다음 작업

다음 단일 패킷은 `A4-STAGE-04-LOOP-CATALOG-CONNECT`다. Stage 04 환경음 event catalog 항목 하나와 해당 catalog 계약 테스트만 처리한다. 게임 runtime 연결과 대표 화면 검수는 이후 별도 패킷으로 분리한다.

## 6. 정책 기록

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`
