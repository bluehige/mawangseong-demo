# V1.2.2 release polish handoff — A4 Stage 01 Lyria API smoke

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: v1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: `main@7ee0b50965dd3944a7ab737c0eca76d2df2a82ad`
- 세션 시작 및 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 푸시 여부: 하지 않음
- 관련 PR 또는 태그: 없음
- 패킷 ID: `A4-STAGE-01-LYRIA-API-SMOKE`
- 결과: `A4_STAGE01_LYRIA_API_SMOKE_PASS`

## 2. 이번 세션 목표

- 요청 사항: 로그인된 Chrome Google Ultra 계정의 AI Studio API 키로 Lyria 3 실제 음원을 한 번 생성하고, 성공하면 Luna가 이어받을 다음 작업을 핸드오프에 고정한다.
- 완료 조건: 올바른 계정·프로젝트 확인, 전용 환경 준비, 실제 유료 호출 1회 성공, 후보 파일·보안 검증, `CURRENT.md`의 다음 단일 패킷 갱신.
- 범위에서 제외: Stage 01 runtime 자산 생성·승격, manifest·catalog·라우팅 변경, 게임 내 청취, 전체 회귀·빌드·커밋·푸시.

현재 manifest에는 Stage 01 환경 loop가 없으므로 기존 `management_castle_bustle` 항목을 API smoke 대상으로 사용했다. 생성된 곡은 API 작동 증명용 후보이며 Stage 01용 자산으로 승격하면 안 된다.

## 3. 완료한 작업

- 구현: Git에서 무시되는 `tmp/lyria_audio_venv/`에 Lyria 전용 Python 환경을 준비했다.
- 오디오: `lyria-3-pro-preview`로 `management_castle_bustle` take 1개를 생성했다.
- 비용: 실제 요청 1회, manifest 기준 예상 `$0.08`.
- 보안: API 키는 파일에 저장하지 않고 생성 프로세스에서만 사용했다. 결과 폴더 비밀 패턴 검사는 0건이며 생성 뒤 클립보드를 덮어썼다.
- 제품 변경: runtime WAV, manifest, event catalog, 라우팅은 건드리지 않았다.
- 문서: 기술 검증 근거와 Luna의 다음 단일 패킷을 기록했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/qa/V122_A4_STAGE01_LYRIA_API_SMOKE_2026-08-05.md` | 실제 API 호출·후보 파일·보안 검증 근거 | 완료 |
| `docs/handoff/V122_RELEASE_POLISH_A4_STAGE01_LYRIA_API_SMOKE_2026-08-05.md` | 세션 핸드오프와 향후 순서 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 Luna 단일 패킷 갱신 | 완료 |
| `tmp/lyria_audio_v122/20260805_stage01_api_smoke/` | 생성 원본·미리듣기 후보, Git 무시 | 청취 필요 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 해당 없음
- 생성 모델: Google `lyria-3-pro-preview`
- 생성 원본 경로: `tmp/lyria_audio_v122/20260805_stage01_api_smoke/management_castle_bustle/take-01/source.mp3`
- 미리듣기 경로: `tmp/lyria_audio_v122/20260805_stage01_api_smoke/management_castle_bustle/take-01/preview.wav`
- `SOURCE.md` 경로: 없음. 제품 승격 전 후보이므로 작성하지 않음
- 런타임 최종 자산 경로: 없음
- 프롬프트/후처리 요약: 기존 manifest의 따뜻하고 분주한 마왕성 관리 BGM brief를 사용했고, 2채널·44.1kHz·16bit WAV로 변환했다.
- 게임 연결 및 실제 렌더 확인 결과: 연결하지 않음. 사람 청취·loop seam·게임 믹스는 미완료

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `tools/audio/setup_lyria.ps1` 및 `doctor` | PASS | QA 보고서 |
| 2 | `generate` 사전 점검 | PASS — Pro 1회·예상 `$0.08` | QA 보고서 |
| 3 | `generate --execute` | PASS — 실제 요청 1회 | 후보 디렉터리 |
| 4 | WAV 메타데이터·SHA-256·API 키 패턴 검사 | PASS | QA 보고서 |
| 5 | 전체 회귀 테스트 | NOT_REQUESTED | 사용자 요청 범위 아님 |
| 6 | 사람 청취·실플레이 | NOT_REQUESTED | 다음 승인 gate로 남김 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: `N/A`
- 실행하지 못한 필수 검수와 이유: 없음. 전체 검수는 요청되지 않음
- PASS 이후 기능·데이터·자산 변경 여부: 제품 자산 변경 없음

### 정책 CI용 최종 승인 필드

- Review task ID: `NOT_REQUESTED`
- Reviewed SHA: `N/A`
- Review range: `N/A`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 이번 곡은 기존 관리 BGM의 API smoke 후보이며 Stage 01 환경 loop가 아니다.
- Stage 01 환경 loop는 manifest에 항목이 없고 runtime·출처 경로·event 연결도 없다.
- 현재 manifest 검증은 모든 항목의 runtime WAV가 이미 존재해야 통과한다. 새 자산을 생성하기 전에 `planned` 상태를 안전하게 표현할 계약이 필요하다.
- 후보는 `tmp/`에 있으므로 정리 작업에서 사라질 수 있다. 제품 승격 전에는 원본으로 간주하지 않는다.
- 사람 청취, loop 이음새, 타격음을 덮지 않는 음량, x3 재생 체감은 확인하지 않았다.

## 8. 다음 작업 순서

1. `A4-STAGE-01-LOOP-MANIFEST-CONTRACT`: Stage 01의 “바람·먼 물방울·석재 울림” 환경 loop 한 개를 `planned` 상태로 manifest에 정의하고, 기존 76개 runtime coverage를 깨뜨리지 않으면서 선택 자산의 생성 사전 점검이 가능하도록 파이프라인과 단위 테스트를 보정한다. 유료 생성은 하지 않는다.
2. `A4-STAGE-01-LOOP-GENERATION-TAKE01`: 계약된 Stage 01 항목만 Lyria 3 Pro take 1개로 생성한다. 예상 유료 요청은 1회이며 생성 뒤 멈춘다.
3. `A4-STAGE-01-LOOP-LISTENING-GATE`: 사용자가 후보를 듣고 분위기·반복 이음새·피로도를 승인하거나 재생성 여부를 결정한다. 자동 재생성하지 않는다.
4. `A4-STAGE-01-LOOP-PROMOTE`: 승인된 후보만 `assets/source/audio/lyria/v1.2.2/` 출처 기록과 runtime WAV로 승격한다.
5. `A4-STAGE-01-LOOP-CATALOG-CONNECT`와 `A4-STAGE-01-LOOP-RUNTIME-CONNECT`: event catalog 등록과 Stage 01 재생 연결을 서로 다른 패킷으로 처리하고 실제 게임에서 청취한다.
6. Stage 01 완료 뒤에만 Stage 02~04 환경 loop와 재질별 발소리를 각각 한 자산 단위로 진행한다.

## 9. 작업 트리 상태

- `git status --short --branch`: 기존부터 다수의 수정·미추적 파일이 있는 혼합 작업 트리
- 이번 세션의 미커밋 파일: 위 문서 3개
- 의도하지 않은 기존 변경: 모두 보존했고 되돌리거나 스테이징하지 않음
- 스태시 또는 별도 작업공간: 사용하지 않음
- 빌드/캡처 산출물 위치: 빌드 없음, 오디오 후보는 `tmp/lyria_audio_v122/20260805_stage01_api_smoke/`

## 10. 종료 체크리스트

- [x] 요청한 Lyria API 실제 생성 1회 완료
- [x] 관련 기술 검증 통과
- [x] API 키 미저장·후보 폴더 비밀 패턴 0건 확인
- [x] 요청받지 않은 전체 회귀·검수 에이전트는 실행하지 않음
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 사람 청취와 Stage 01 자산 승인
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그
