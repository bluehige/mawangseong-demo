# v0.5 Lyria 3 오디오 교체 파이프라인 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 오디오 전면 교체 준비
- 작업 브랜치: `codex/v05-steam-release-readiness`
- 기준 브랜치 및 SHA: 최신 `main` / `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 작업 시작 SHA: `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 오디오 구현 직전 SHA: `856440c525fec8d82ce5a10d7dc25e3e160cb31c` (동시 진행된 Steam 준비 커밋)
- 마지막 구현 커밋 SHA: `63d1242624d3d0fff27b53c84fe286de4f372156`
- 원격 푸시 여부: 미실행, 현재 브랜치 upstream 없음
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: Lyria 3 Clip/Pro와 Interactions API 기반의 게임 BGM·타격음·전반 SFX 교체 환경을 세팅하고, 후속 제공된 키로 최초 BGM·타격음 후보를 생성한다.
- 완료 조건: 키를 저장소에 남기지 않고 현재 런타임 WAV 전체를 계획하며, 비용을 쓰는 호출과 게임 파일 덮어쓰기를 분리하고, 최초 후보 4개의 생성·WAV 렌더·무결성을 검증한다.
- 범위에서 제외한 사항: 생성 후보 청취와 선택, 런타임 WAV 교체, 게임 오디오 믹스 검수, 나머지 48개 자산 생성, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 공식 사양: 현재 유효 모델 ID를 `lyria-3-clip-preview`와 `lyria-3-pro-preview`로 고정하고 Gemini Interactions API `interactions.create`를 사용한다.
- 전체 범위: `assets/audio/`의 현재 WAV 50개를 매니페스트에 50/50 연결했다. BGM 1곡은 Pro, 짧은 모티프·타격·스킬·경고음 49개는 Clip을 사용한다.
- 프롬프트: 게임의 코지 다크 판타지·코미디 정체성을 공통으로 유지하면서 각 캐릭터, 심장, 합동기, 적, 왕관과 전투 행위에 맞춘 원본 오디오 brief를 정의했다.
- SFX 추출: Clip의 30초 결과에 2·7·12·17·22·27초마다 분리된 후보를 요청하고, 첫 후보의 onset을 찾아 현재 자산 길이의 44.1kHz mono WAV로 렌더한다.
- BGM 처리: Pro 결과를 120초 stereo WAV로 변환하고 2초 루프 크로스페이드를 적용한다.
- 키 보안: API 키를 파일이나 인자로 받지 않는다. PowerShell 래퍼가 유료 실행 시에만 가려진 입력으로 받아 자식 프로세스에서 사용한 뒤 제거한다.
- 최초 API 검증: `20260715_initial_audition` 실행에서 `combat_dungeon_pressure`와 `combat_hit`을 각 2테이크 생성했다. Pro 2회와 Clip 2회, 총 예상 비용은 USD 0.24다.
- 비용 안전: `generate`는 기본 dry-run이며 `--execute` 없이는 호출하지 않는다. 기본 2테이크 전체 계획은 현재 공식 단가 기준 약 USD 4.08이다.
- 데이터 최소화: 모든 Interactions 요청에 `store=false`를 설정한다. SDK나 로컬 메타데이터에 API 키를 기록하지 않는다.
- 승인 게이트: API 응답은 ignored `tmp/lyria_audio/` 후보로만 저장한다. 실제 WAV 덮어쓰기는 한 자산·한 테이크를 지정한 `promote --confirm`만 허용한다.
- 출처 보존: 승격 시 선택한 원본 MP3, 프롬프트, 모델, Interaction ID, 생성일, SHA-256, 후처리 계약과 SynthID 고지를 `assets/source/audio/lyria/v0.5/<asset>/`에 기록한다.
- Windows 한글 경로: 파일명 기반 디코딩 대신 바이트 기반 디코딩을 사용해 현재 한글 저장소 경로에서도 WAV 렌더가 동작하도록 했다.
- 스토리·밸런스·게임 데이터·런타임 오디오: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `tools/audio/lyria_pipeline.py` | Interactions 생성, 비용 계획, MP3/WAV 렌더, 승인 승격, 출처 기록 | 완료 |
| `tools/audio/lyria_v05_manifest.json` | 현재 WAV 50개 모델·프롬프트·렌더 계약 | 완료 |
| `tools/audio/setup_lyria.ps1` | ignored venv 생성과 고정 의존성 설치·검증 | PASS |
| `tools/audio/run_lyria.ps1` | 키의 프로세스 한정 보안 입력과 파이프라인 실행 | PASS |
| `tools/audio/requirements-lyria.txt` | `google-genai==2.11.0`, `miniaudio==1.71` 고정 | 완료 |
| `tools/audio/test_lyria_pipeline.py` | 매니페스트·비용·프롬프트·렌더·승격·키 비노출 회귀 | 7/7 PASS |
| `docs/audio/LYRIA3_INTERACTIONS_WORKFLOW.md` | 설치, 비용, 생성, 청취, 재렌더, 승격, 한계 | 완료 |
| `assets/audio/README.md` | Lyria 워크플로 진입점과 키·후보 비추적 정책 | 완료 |
| `docs/handoff/V05_LYRIA3_AUDIO_PIPELINE_2026-07-15.md` | 이번 세션 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니요
- 실제 Lyria 오디오 생성 여부: 예. 최초 후보 4개를 생성했으며 아직 승인·승격하지 않았다.
- 생성 모델: `lyria-3-clip-preview` 2회, `lyria-3-pro-preview` 2회
- 생성 원본 경로: ignored `tmp/lyria_audio/20260715_initial_audition/<asset-id>/take-*/source.mp3`
- `SOURCE.md` 경로: 아직 없음. 후보 승인 승격 시 `assets/source/audio/lyria/v0.5/<asset-id>/SOURCE.md`가 생성된다.
- 런타임 최종 자산 경로: 현재 `assets/audio/`의 기존 WAV 50개 유지, 변경 없음.
- 후처리 요약: MP3 메모리 디코드, 44.1kHz 변환, mono/stereo 계약, onset 추출, 페이드·피크 정규화, 루프 크로스페이드가 후보 렌더 단계에 준비됨.
- 게임 연결 및 실제 재생 확인 결과: 런타임 자산을 바꾸지 않아 기존 연결은 그대로다. 실제 생성·청취·게임 믹스 확인은 후속 필수 작업이다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `powershell -ExecutionPolicy Bypass -File tools/audio/setup_lyria.ps1` | PASS | ignored venv, `google-genai 2.11.0`, `miniaudio 1.71` 설치 |
| 2 | `python tools/audio/lyria_pipeline.py validate` | PASS | `assets=50`, `coverage=all-current-wav` |
| 3 | venv Python `-m unittest tools.audio.test_lyria_pipeline -v` | PASS, 7/7 | 전체 매핑, 비용, 프롬프트, onset, 루프, 승인 게이트, 키 literal 검사 |
| 4 | venv Python `-m py_compile tools/audio/lyria_pipeline.py tools/audio/test_lyria_pipeline.py` | PASS | Python 구문 검사 |
| 5 | `run_lyria.ps1 doctor` | PASS | SDK·디코더·매니페스트 확인, 키 미설정, 네트워크 호출 0 |
| 6 | `run_lyria.ps1 generate --asset combat_hit --takes 1` | DRY-RUN PASS | 1회·USD 0.04 계획만 출력, API 호출 0 |
| 7 | `run_lyria.ps1 plan --takes 1` 및 기본 2테이크 계획 | PASS | 전체 1테이크 USD 2.04, 2테이크 USD 4.08 |
| 8 | 기존 `combat_hit.wav`를 한글 경로의 임시 run으로 복사 후 `render` | PASS | 44.1kHz mono `preview.wav`, 12,392 bytes |
| 9 | SDK 요청 타입에서 `model`, `input`, `store` 필드 확인 | PASS | `google-genai 2.11.0` 로컬 타입 검사 |
| 10 | `git diff --check HEAD^..HEAD` | PASS | 구현 커밋 공백 오류 0 |
| 11 | 실제 Lyria API로 BGM·타격음 각 2테이크 생성 | PASS | Pro 2회, Clip 2회, 오류 0, 예상 USD 0.24 |
| 12 | 후보 파일·JSON·WAV 길이·샘플레이트·채널·비무음·키 패턴 검사 | PASS | BGM 약 115~117초 stereo, 타격음 0.14초 mono, 44.1kHz, 후보 메타데이터 키 패턴 0건 |
| 13 | 후보 청취·선택·게임 재생 | NOT_RUN | 사람의 청취 승인 전 런타임 승격을 금지 |
| 14 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 미실행 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 실제 API·청취·게임 재생은 키와 생성 후보가 있어야 하므로 후속 작업이다. 현재 세팅 단계의 필수 정적·로컬 렌더 검사는 완료했다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 구현 SHA 이후에는 `docs/handoff/` 문서만 변경했다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 63d1242624d3d0fff27b53c84fe286de4f372156
- Review range: d5a2d24457edcb919ae3ae4fe1d642552097f9c8..63d1242624d3d0fff27b53c84fe286de4f372156
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- Gemini 앱 Ultra 구독은 Gemini API 유료 프로젝트와 별도다. 이번 키의 Lyria 3 유료 모델 접근과 4개 요청 성공은 검증했다.
- 사용자가 API 키를 채팅에 직접 붙였으므로 해당 키는 노출된 것으로 간주하고 폐기·재발급해야 한다. 키 문자열은 저장소와 후보 메타데이터에 기록되지 않았다.
- Lyria 3는 음악 생성 모델이며 전용 Foley/SFX 모델이 아니다. 짧은 타격음은 30초 소스 릴에서 추출하므로 모델이 음악을 섞거나 정확한 타임스탬프를 따르지 않은 테이크는 폐기해야 한다.
- 생성은 비결정적이고 멀티턴 편집을 지원하지 않는다. 자동 재시도는 중복 과금을 막기 위해 구현하지 않았다.
- 자동 렌더는 피크·길이·기본 루프 경계만 맞춘다. 지각 음량, 반복 피로, 타격 타이밍과 음악적 루프 자연스러움은 반드시 사람이 듣고 게임에서 확인해야 한다.
- 전체 WAV 50개의 2테이크 생성은 100개 요청이다. 전체 호출 전 단일 BGM·단일 SFX의 응답 포맷과 품질을 먼저 확인한다.

## 8. 다음 작업 순서

1. `tmp/lyria_audio/20260715_initial_audition/`의 두 자산·각 2테이크를 직접 청취해 프롬프트 준수, 선행 무음, 잔향, 반복 피로와 BGM 루프를 확인한다.
2. 채팅에 노출된 기존 키를 폐기하고 새 키를 발급한다. 이후 키는 채팅이나 파일에 붙이지 않고 `run_lyria.ps1 ... --execute`의 가려진 입력창에만 넣는다.
3. 승인 테이크만 한 자산씩 `promote --confirm`으로 승격한다. 완료 조건은 원본·`SOURCE.md`·generation metadata와 런타임 WAV가 정확히 연결되는 것이다.
4. 승격한 자산의 관련 Godot 테스트와 실제 전투 장면을 실행해 타격 동기·음량·버스·루프를 확인한다. 이후에만 나머지 48개 후보 생성을 확대한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v05-steam-release-readiness`
- 기준 SHA: `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 마지막 구현 SHA: `63d1242624d3d0fff27b53c84fe286de4f372156`
- 미커밋 파일: 최종 문서 커밋 뒤 없음. 동시 Steam 작업의 핸드오프도 같은 문서 커밋에 보존한다.
- 의도하지 않은 기존 변경: 작업 중 Steam 준비 구현이 별도 세션에서 `856440c`로 커밋됐으며 수정하지 않았다.
- 스태시 또는 별도 작업공간: 없음. 의존성 venv와 최초 오디오 후보는 ignored `tmp/`만 사용했다.
- 빌드/캡처 산출물: 없음. ignored `tmp/lyria_audio/20260715_initial_audition/`에 승인 전 오디오 후보 4개가 있다.
- 스테이징·커밋: 오디오 구현 파일만 명시적으로 스테이징해 `63d1242`로 커밋했다.
- 원격 푸시·PR·태그: 미실행, upstream 없음.

## 10. 종료 체크리스트

- [x] 공식 모델 ID와 Interactions API 사양 확인
- [x] 현재 런타임 WAV 50/50 매핑
- [x] API 키 비추적·프로세스 한정 입력
- [x] 유료 호출 명시적 `--execute` 게이트
- [x] 후보와 런타임 승격 분리
- [x] 승인 승격 시 원본·프롬프트·해시·Interaction ID 기록
- [x] 관련 정적 테스트와 한글 경로 WAV 렌더 통과
- [x] 최초 API 호출 4회와 후보 무결성 검증 기록
- [x] 런타임 자산 교체 미실행 사실 기록
- [x] 전체 회귀·검수 에이전트 미요청 사실 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 구현 파일만 커밋
- [x] 원격 미푸시 상태 기록
