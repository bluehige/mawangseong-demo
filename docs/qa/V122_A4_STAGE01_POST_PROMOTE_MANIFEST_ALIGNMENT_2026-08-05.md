# v1.2.2 A4 Stage 01 승격 후 manifest 정렬 QA

- 검수일: 2026-08-05
- 목표 버전: `v1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 패킷: `A4-STAGE-01-POST-PROMOTE-MANIFEST-ALIGNMENT`

## 목적

Stage 01 환경음 `ambience_stage01_cave` 승격 뒤 기존 Lyria 단위 테스트가 구버전 기본 manifest를 읽어 새 runtime을 누락시키던 문제를 정렬했다. 이번 패킷은 테스트 fixture만 현재 v1.2.2 manifest에 맞추며, 음원·runtime·catalog는 변경하지 않는다.

## 변경 및 직접 검증

- `tools/audio/test_lyria_pipeline.py`의 공통 fixture를 `tools/audio/lyria_v122_manifest.json`으로 변경했다.
- 현재 runtime coverage 기대값을 77개로 갱신했다.
- Lyria Pro 자산 수와 2회 생성 예상 비용을 현재 manifest 기준인 4개·`$6.48`로 갱신했다.
- 승격된 `ambience_stage01_cave`가 `active`이고 runtime 파일을 갖는지 검증하도록 테스트를 갱신했다.

| 검증 | 결과 |
|---|---|
| `tmp/lyria_audio_venv/Scripts/python.exe -m unittest tools.audio.test_lyria_pipeline -v` | PASS — 13개 테스트 |
| `tmp/lyria_audio_venv/Scripts/python.exe tools/audio/lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — `manifest=OK assets=77 coverage=all-current-wav` |
| UI/청취 확인 | NOT_REQUESTED — 테스트 정렬 패킷 |
| 전체 회귀/별도 검수 에이전트 | NOT_REQUESTED |

## 범위 밖 및 미해결

- 이번 패킷에서는 `assets/audio/ambience/stage01_cave.wav`, source 원본, `tools/audio/lyria_v122_manifest.json`, event catalog를 수정하지 않았다.
- Stage 01 음원을 event catalog에 등록하고 게임 runtime 재생에 연결하는 작업은 다음 패킷이다.
- 작업 트리는 기존 사용자 변경과 이번 패킷의 미커밋 변경이 섞여 있으며, 커밋·푸시는 하지 않았다.

Review task ID: `NOT_REQUESTED`
Reviewed SHA: `N/A`
Remaining P1/P2: `N/A`
Final review result: `TARGETED_PASS`
