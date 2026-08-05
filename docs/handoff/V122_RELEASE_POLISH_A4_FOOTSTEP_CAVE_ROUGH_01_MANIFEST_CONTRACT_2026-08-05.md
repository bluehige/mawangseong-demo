# v1.2.2 A4 거친 동굴석 발소리 01 manifest 계약 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 실행하지 않음 (`HEAD`가 upstream보다 2커밋 앞섬)
- 관련 PR 또는 태그: 없음
- 패킷: `A4-FOOTSTEP-CAVE-ROUGH-01-MANIFEST-CONTRACT`
- 결과: `A4_FOOTSTEP_CAVE_ROUGH_01_MANIFEST_CONTRACT_PASS_PENDING_GENERATION_APPROVAL`

## 2. 이번 세션 목표

- 요청 사항: 정식판 완성 목표를 시작하고 현재 잠긴 첫 발소리 manifest 패킷을 완료한다.
- 완료 조건: 첫 cue 한 개의 planned 계약, 대상 테스트, manifest coverage, 무료 dry-run이 통과한다.
- 범위에서 제외한 사항: 유료 API 호출, 후보·source/runtime 생성, catalog·게임 코드·scheduler, 다른 발소리, 전체 회귀, 빌드, 커밋, 푸시.

## 3. 완료한 작업

- 구현: `footstep_cave_rough_01` planned manifest 항목을 추가했다.
- 테스트: 항목 상태·경로·모델·prompt·render·비용 계약을 단위 테스트로 고정했다.
- manifest snapshot: 81 assets, clip 74/pro 7, 2-take 전체 계획 `$7.04`로 정렬했다.
- 유료 호출: 0회. `plan`과 `generate` 기본 dry-run만 수행했다.
- 스토리·밸런스·UI·저장: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_v122_manifest.json` | 첫 동굴석 발소리 planned 계약 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 81개 snapshot·첫 cue·비용 계약 검증 | 완료 |
| `docs/qa/V122_A4_FOOTSTEP_CAVE_ROUGH_01_MANIFEST_CONTRACT_2026-08-05.md` | 직접 테스트와 비용 없는 실행 증빙 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_FOOTSTEP_CAVE_ROUGH_01_MANIFEST_CONTRACT_2026-08-05.md` | 세션 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 유료 생성 승인 gate 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 오디오 생성 모델 계약: Google `lyria-3-clip-preview`
- 생성 원본 경로: 없음
- `SOURCE.md` 경로: 없음
- 런타임 최종 자산 경로: 아직 없음; planned 경로만 `assets/audio/sfx/footsteps/footstep_cave_rough_01.wav`
- 프롬프트/후처리 요약: 거친 동굴석 한 걸음, 0.28초 mono, -6 dBFS; 실제 생성·후처리는 하지 않음
- 게임 연결 및 실제 확인: 아직 없음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python tools/audio/test_lyria_pipeline.py` | PASS, 17 tests | `tools/audio/test_lyria_pipeline.py` |
| 2 | v1.2.2 manifest `validate` | PASS, 81 assets/coverage 일치 | `tools/audio/lyria_v122_manifest.json` |
| 3 | 첫 cue `plan --takes 1` | PASS, 1 request/`$0.04` | 명령 출력 |
| 4 | 첫 cue `generate` dry-run | PASS, API 호출 0회 | 명령 출력 |
| 5 | `git diff --check` | PASS | 기존 줄바꿈 경고만 있음 |
| 6 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 정식 후보 단계 대기 |

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A — 현재 작업 트리 미커밋`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 실제 후보는 아직 생성되지 않아 소리 품질·transient·반복 피로를 판단할 수 없다.
- 다음 생성은 Lyria clip 유료 요청 1회, 예상 `$0.04`이며 사용자 별도 승인이 필요하다.
- 승인 후보가 생겨도 청취 승인 전 source/runtime 승격과 catalog·scheduler 연결을 금지한다.
- 기존 대량 혼합 작업 트리는 그대로 보존돼 있으며 출시 전 선별 통합이 필요하다.

## 8. 다음 작업 순서

1. 사용자 승인 후 `A4-FOOTSTEP-CAVE-ROUGH-01-GENERATION-TAKE01`에서 유료 요청 1회만 실행한다.
2. MP3/WAV 메타데이터·해시·민감정보 패턴·take 수를 검증한다.
3. 후보를 사용자에게 재생하고 승인·재생성·반려를 받는다.
4. 승인 뒤에만 별도 패킷으로 source/runtime 승격과 catalog 연결을 진행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- HEAD: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- upstream: 2커밋 앞섬
- 미커밋 파일: 기존 사용자·Luna 수정·신규 파일이 대량으로 섞여 있음
- 의도하지 않은 기존 변경: 보존, 수정·되돌림하지 않음
- 스태시·별도 작업공간: 사용하지 않음
- 커밋·푸시·PR: 실행하지 않음

## 10. 종료 체크리스트

- [x] 현재 NEXT 패킷만 실행
- [x] planned manifest 계약 추가
- [x] 단위 테스트 17개 통과
- [x] manifest 81개 coverage 통과
- [x] 무료 dry-run과 `$0.04` 계획 확인
- [x] 유료 호출·후보 생성 0회 확인
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 다음 패킷 자동 실행 금지
- [ ] 사용자 유료 생성 승인
- [ ] 커밋·푸시
