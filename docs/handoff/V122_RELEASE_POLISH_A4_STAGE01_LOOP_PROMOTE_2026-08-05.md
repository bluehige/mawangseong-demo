# V1.2.2 release polish handoff — A4 Stage 01 loop promote

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 기준 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-01-LOOP-PROMOTE`
- 결과: `A4_STAGE01_LOOP_PROMOTE_PASS_WITH_LEGACY_MANIFEST_TEST_ALIGNMENT_BLOCKED`

## 2. 이번 패킷 목표

- 요청 사항: 승인된 Stage 01 환경 loop take 1개를 source/runtime으로 승격한다.
- 완료 조건: source 원본·`SOURCE.md`·generation 기록·runtime WAV 생성, v1.2.2 manifest `active` 전환, coverage·hash 검증.
- 범위에서 제외: 추가 생성·다른 asset 승격·event catalog·AudioDirector·게임 연결·전체 회귀·빌드·커밋·푸시.

## 3. 완료한 작업

- 승인된 후보 source MP3를 `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/source.mp3`로 복사했다.
- 승인된 preview WAV를 `assets/audio/ambience/stage01_cave.wav`로 복사했다.
- `SOURCE.md`와 `generation.json`을 source 디렉터리에 기록했다.
- `tools/audio/lyria_v122_manifest.json`의 `ambience_stage01_cave.status`를 `active`로 바꿨다.
- v1.2.2 manifest coverage 77개를 통과했다.
- 기존 전체 단위 테스트는 v0.5 기본 manifest가 새 runtime을 모르는 문제로 `setUpClass`에서 막혔다. 관련 파일이 이번 패킷 허용 경로 밖이라 수정하지 않았다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/source.mp3` | 승인된 Lyria 원본 | 완료 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/SOURCE.md` | 생성·출처·승격 기록 | 완료 |
| `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/generation.json` | 생성 메타데이터 | 완료 |
| `assets/audio/ambience/stage01_cave.wav` | 게임 runtime 후보 승격본 | 완료 |
| `tools/audio/lyria_v122_manifest.json` | planned → active 전환 | 완료 |
| `docs/qa/V122_A4_STAGE01_LOOP_PROMOTE_2026-08-05.md` | 승격·검증·테스트 차단 근거 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LOOP_PROMOTE_2026-08-05.md` | 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 정렬 패킷 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델: Google `lyria-3-pro-preview`
- 생성 원본 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/source.mp3`
- `SOURCE.md` 경로: `assets/source/audio/lyria/v1.2.2/ambience_stage01_cave/SOURCE.md`
- 런타임 최종 자산 경로: `assets/audio/ambience/stage01_cave.wav`
- 프롬프트/후처리 요약: 바람·먼 물방울·석재 반향 환경 loop, 2채널 44.1kHz, 2초 loop crossfade, -8dBFS
- 게임 연결 및 실제 렌더 확인 결과: 파일 승격과 manifest coverage만 확인. event catalog·게임 재생 연결은 다음 단계

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `promote --run tmp/lyria_audio_v122/20260805_stage01_loop_take01 --asset ambience_stage01_cave --take 1 --confirm` | 첫 시도는 runtime 폴더 부재로 중단 | QA 보고서 |
| 2 | 동일 승격 명령 + `--force` | PASS — source/runtime/records 생성 | QA 보고서 |
| 3 | `lyria_pipeline.py --manifest tools/audio/lyria_v122_manifest.json validate` | PASS — 77개 coverage | 터미널 실행 결과 |
| 4 | source/runtime SHA-256·`SOURCE.md`·키 패턴 검사 | PASS | QA 보고서 |
| 5 | 기존 `python -m unittest tools.audio.test_lyria_pipeline -q` | BLOCKED — v0.5 manifest coverage mismatch | QA 보고서 |
| 6 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 전체 회귀는 요청되지 않음. 관련 단위 테스트는 legacy v0.5 manifest 정렬 문제로 차단
- PASS 이후 기능·데이터·자산 변경 여부: 승격 파일과 v1.2.2 manifest를 변경했으며 event/runtime 연결은 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_BLOCKED`

## 7. 미해결 항목과 위험

- `tools/audio/test_lyria_pipeline.py`는 기본 v0.5 manifest를 읽어 새 runtime을 누락으로 판정한다.
- v0.5 manifest는 현재 runtime 76개만 알고 있어 전체 단위 테스트가 시작 단계에서 중단된다.
- 다음 패킷에서 테스트가 v1.2.2 manifest를 기준으로 77개 coverage를 검증하도록 정렬해야 한다. v0.5 source record fixture 검증은 기존 경로를 유지한다.
- event catalog, Ambience bus 재생, Stage 01 실제 게임 청취는 아직 하지 않았다.

## 8. 다음 작업 순서

1. `A4-STAGE-01-POST-PROMOTE-MANIFEST-ALIGNMENT`: `test_lyria_pipeline.py`가 v1.2.2 manifest와 현재 77개 runtime을 검증하도록 정렬하고 전체 13개 단위 테스트를 통과시킨다. 음원·catalog·게임 연결은 금지한다.
2. 테스트 정렬 통과 뒤 `A4-STAGE-01-LOOP-CATALOG-CONNECT`에서 event catalog에 한 개를 등록한다.
3. catalog 통과 뒤 `A4-STAGE-01-LOOP-RUNTIME-CONNECT`에서 Stage 01 Ambience 재생 연결과 실제 게임 청취를 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존부터 다수의 수정·미추적 파일이 있는 혼합 작업 트리
- 이번 패킷의 의도한 변경: 승인 source/runtime, v1.2.2 manifest, QA·핸드오프·CURRENT
- 의도하지 않은 기존 변경: 보존했고 되돌리거나 스테이징하지 않음
- 원격 푸시: 하지 않음
- 후보 원본: `tmp/lyria_audio_v122/20260805_stage01_loop_take01/`도 보존

## 10. 종료 체크리스트

- [x] 승인 후보 source/runtime 승격
- [x] `SOURCE.md`·generation 기록 생성
- [x] v1.2.2 manifest `active` 전환
- [x] v1.2.2 coverage·hash 검증
- [ ] legacy manifest·단위 테스트 정렬
- [ ] event catalog·게임 runtime 연결
- [ ] 의도한 파일만 커밋·원격 푸시
