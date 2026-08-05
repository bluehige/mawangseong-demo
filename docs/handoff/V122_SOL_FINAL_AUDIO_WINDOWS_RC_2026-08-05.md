# v1.2.2 SOL 최종 오디오·Windows 출시 후보 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-05
- 목표 버전: `1.2.2`
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 브랜치 및 SHA: 현재 브랜치 기준 `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 마지막 커밋 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 동기화: `origin/codex/v122-ui-simplification`보다 2커밋 앞, 0커밋 뒤
- 원격 푸시 여부: 이번 SOL 마무리 작업은 미푸시
- 관련 PR 또는 태그: 없음. `v1.2.2` 태그와 GitHub Release는 생성하지 않음

## 2. 이번 세션 목표

- 요청 사항: Luna 소형 패킷 제한을 SOL 연속 실행 방식으로 전환하고, 남은 오디오·시각·UI·성능·검증·Windows 후보 작업을 승인 지점까지 연속 마무리한다.
- 완료 조건: 최종 오디오를 생성·승격·연결하고 전체 검증을 통과한 뒤, 부팅 가능한 Windows `1.2.2` 후보와 SHA-256을 만든다.
- 범위에서 제외한 사항: 사용자의 물리 키보드 한국어 IME 실기 확인, 코드 서명 인증서 적용, 커밋·푸시·PR·병합·태그·공개 Release.

## 3. 완료한 작업

- 작업 규칙: `AGENTS.md`에 SOL이 여러 잔여 항목을 연속 처리할 수 있는 예외 규칙을 추가했다. Luna 소형 패킷 규칙은 Luna에게 다시 넘길 때만 적용한다.
- 오디오 생성: Google AI Studio의 사용자 승인 키로 Lyria 3 유료 요청 11회를 성공시켰다. 재시도는 없었고 이번 묶음 최대 비용은 USD 0.56이다.
- 오디오 승격: 최종 묶음 31개를 런타임과 `assets/source/audio/lyria/v1.2.2/` 출처 기록으로 승격했다. 구성은 타이틀·후반전·최종전 음악 3개, 전투 공격 12개, 충돌·결과 6개, UI 6개, 기존 Update 4 효과음 교체 4개다.
- 기존 오디오 마무리: 앞선 Stage 01~04 환경음과 지형별 발소리 9개, normal/heavy 스케줄러 및 버스·voice·라우팅 계약까지 함께 최종 검증했다.
- 오디오 카탈로그: manifest와 catalog를 116개 자산으로 정렬했다. catalog는 108개 이벤트, 실제 런타임 106개, 의도적으로 남긴 구형 미연결 항목 10개다. 출처 분류는 Lyria 72개, 절차적 합성 44개다.
- 비밀값 처리: 생성이 끝난 뒤 프로세스 환경과 클립보드에서 키를 제거했고, 저장소 텍스트 검색에서 Google API 키 패턴 0건을 확인했다.
- Windows 내보내기 결함 수정: 내보낸 PCK에는 원본 파일 대신 Godot import 자원이 들어가므로 `FileAccess.file_exists()`가 오디오·VFX를 누락으로 오판하던 문제를 고쳤다. 런타임 자원 검사는 `ResourceLoader.exists()`를 사용한다.
- 회귀 방지: 위 내보내기 결함을 `tools/audio/test_audio_event_catalog.py`와 `tools/tests/V122CombatVfxCatalogTest.gd`에 고정했다.
- Windows 후보: `1.2.2.0` 버전 정보가 들어간 EXE/PCK를 내보내고 1920×1080 숨김 부팅 스모크에서 오류 0건을 확인했다.
- 배포 묶음: EXE와 PCK만 포함한 `MawangCastle-v1.2.2-Windows.zip`을 만들고 압축 내부 파일을 끝까지 다시 읽어 원본 SHA-256과 일치함을 확인했다.

## 4. 변경 파일

작업 트리는 여러 이전 세션의 승인된 시각·UI·밸런스·오디오 변경을 함께 포함한다. 아래는 이번 최종 상태의 주요 묶음이다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | SOL 연속 실행 규칙 | 완료 |
| `assets/audio/` | 환경음·발소리·전투·UI·BGM 최종 런타임 WAV | 완료 |
| `assets/source/audio/lyria/v1.2.2/` | Lyria 생성 원본·프롬프트·해시·출처 | 완료 |
| `data/audio/` | 116개 오디오 자산·108개 이벤트 catalog | 완료 |
| `tools/audio/lyria_v122_manifest.json` | v1.2.2 생성·승격 계약 | 완료 |
| `scripts/audio/` | catalog API, director, voice allocator, footstep scheduler | 완료 |
| `scripts/audio/AudioCatalogApi.gd` | export PCK 오디오 자원 탐색 수정 | 완료 |
| `scripts/v122/combat/V122CombatVfxCatalog.gd` | export PCK VFX 자원 탐색 수정 | 완료 |
| `scripts/game/`, `scripts/combat/`, `scripts/ui/`, `scripts/units/` | 실제 런타임 오디오·VFX·UI·전투 연결 | 완료 |
| `data/v122/`, `assets/sprites/` | 전투 VFX catalog·시각 정규화 자산 | 완료 |
| `tools/tests/`, `tools/audio/test_*.py` | 직접·전체 회귀·export 결함 방지 검사 | 완료 |
| `docs/qa/`, `docs/handoff/` | 단계별 검수와 최종 인계 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이전 승인 작업의 그래픽 자산에 사용됨. 이번 최종 오디오 묶음에서는 신규 이미지 생성 없음.
- 오디오 생성 모델: `lyria-3-clip-preview`, `lyria-3-pro-preview`
- 생성 작업 경로: `tmp/lyria_audio_v122/v122-final-audio-20260805-01/`
- 생성 원본 및 `SOURCE.md`: `assets/source/audio/lyria/v1.2.2/<asset>/`
- 런타임 최종 자산: `assets/audio/ambience/`, `assets/audio/footsteps/`, `assets/audio/sfx/`, `assets/audio/ui/`, `assets/audio/bgm/`
- 후처리: mono/stereo, 44.1kHz, 길이·fade·peak 계약에 맞춘 WAV 승격. 음악 3개는 모두 96초 이상이며 loop 계약을 통과했다.
- 게임 연결: 음악 상태, Stage 환경음, normal/heavy 발소리, 전투 공격·충돌·결과, Update 3/4 스킬, HUD·UI 라우팅을 자동 검증했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | Python 오디오 manifest·catalog·Lyria pipeline 34개 | PASS | `tools/audio/test_audio_event_catalog.py`, `tools/audio/test_lyria_pipeline.py` |
| 2 | Godot 오디오 직접 계약: profile 43, music 77, routing 9, voice 55, footstep 31, bus 12 | PASS | `tools/tests/` 관련 장면 |
| 3 | Godot VFX catalog 직접 계약 59개 | PASS | `tools/tests/V122CombatVfxCatalogTest.tscn` |
| 4 | 전체 core verification Full 156개 | PASS, 156/156, 1153.01초 | `tmp/core_verification/latest.json` |
| 5 | Windows 1920×1080 후보 10초 부팅·로그 검색 | PASS, 오류 0건 | `tmp/v122_release_candidate/20260805_225608/windows/windows_boot_smoke_fixed.log` |
| 6 | Windows Vulkan 1280×720 혼잡 전투 600초 성능 | PASS, 평균 59.996 FPS, frame p95 19.51ms, 정적 메모리 +3.36MB | `tmp/v122_windows_owner_qa/retest2/sustained_windows_internal.json` |
| 7 | ZIP 엔트리 수·압축 내부 SHA-256과 원본 비교 | PASS, 2개/2개 일치 | `tmp/v122_release_candidate/20260805_225608/SHA256SUMS.txt` |
| 8 | `git diff --check` | PASS | 실행 로그 |
| 9 | 저장소 Google API 키 패턴 검색 | PASS, 0건 | 실행 로그 |
| 10 | 실제 Windows 물리 한국어 IME 조합·Backspace·Enter | OWNER PENDING | 사용자 실기 필요 |

### 검수 에이전트 반복 기록

- 별도 검수 에이전트는 요청되지 않아 실행하지 않았다.
- 전체 자동 검증은 사용자의 정식 후보 마무리 요청과 전체 승인에 따라 실행했다.
- 남은 P1/P2 지적: 자동 검증 범위 P1 0건 / P2 0건. 물리 한국어 IME 1건은 외부 실기 gate다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 이 핸드오프와 `CURRENT.md`뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: `SOL-V122-FINAL-RC-2026-08-05`
- Reviewed SHA: `N/A — uncommitted worktree based on efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- Review range: `N/A — uncommitted worktree`
- Remaining P1/P2: `0/0 in automated scope; owner physical Korean IME gate pending`
- Final review result: `WORKTREE_FULL_PASS — formal SHA PASS pending commit and SHA-bound recheck`

## 7. Windows 후보와 해시

- 후보 폴더: `tmp/v122_release_candidate/20260805_225608/`
- ZIP: `MawangCastle-v1.2.2-Windows.zip`, 311,459,234 bytes
- EXE: `windows/MawangCastle_v1.2.2.exe`, 96,523,776 bytes
- PCK: `windows/MawangCastle_v1.2.2.pck`, 281,956,104 bytes
- EXE SHA-256: `ba355653bcd0d5a43defd7e4cc3fdf837ecb61d96b4047b4162364e9582c9413`
- PCK SHA-256: `cabfdda2833ad0cf5e3b6e4170d7c43d20bc86a470e3697068c516137174289d`
- ZIP SHA-256: `cf0805270bf2011c900db2ed71b712597eeec580000263334a4210581a072379`
- Windows 메타데이터: File/Product version `1.2.2.0`, 제품명 `마왕님, 마왕성은 누가 지켜요?`
- 코드 서명: `NotSigned`. 내부 후보 실행에는 문제없지만 외부 배포 서명은 별도 인증서가 필요하다.

## 8. 미해결 항목과 위험

- 물리 한국어 IME: 실제 Windows 한/영 키로 조합 중 글자를 입력하고, 조합 중 Backspace와 Enter 제출을 확인해야 한다. 합성 입력 자동 테스트는 통과했다.
- Git 근거: 현재 전체 PASS는 미커밋 작업 트리 기준이다. 저장소 정책상 공식 PASS는 커밋 SHA에 묶어 다시 기록해야 한다.
- 공개 배포: 코드 서명, Git PR 병합, `v1.2.2` 태그, GitHub Release 업로드는 아직 하지 않았다.
- 작업 트리: 이전 세션부터 누적된 큰 변경 묶음이다. 현재 `git status`는 tracked 변경 57개, untracked 항목 396개이며 임의로 되돌리거나 분리하지 않았다.
- catalog의 구형 미연결 10개는 실제 런타임 경로가 아닌 감사용 잔존 항목이다. 전체 coverage 계약은 이 상태로 통과했다.

## 9. 다음 작업 순서

1. 사용자가 후보 EXE에서 새 게임의 성 이름 입력란을 열고 물리 한/영 키로 한글을 조합한다. 조합 중 Backspace, 다시 입력, Enter 확정까지 정상이어야 owner gate가 닫힌다.
2. 사용자가 커밋·푸시·PR·태그·Release 진행을 최종 승인한다.
3. 의도한 소스·데이터·자산·테스트·문서만 명시적으로 스테이징해 기능 SHA를 만든다. 그 SHA에서 Full 156개를 다시 실행하고, 이후에는 핸드오프 문서만 갱신한다.
4. 브랜치를 푸시하고 `release/v1.2.2`로 merge commit PR을 만든다. 필수 체크 통과 뒤 병합한다.
5. 병합 SHA에서 Windows 후보를 다시 내보내 부팅·해시를 확인하고 이동하지 않는 `v1.2.2` 태그와 GitHub Release 자산을 만든다.

## 10. 작업 트리 상태

- 브랜치: `codex/v122-ui-simplification`
- HEAD: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 원격 대비: ahead 2 / behind 0
- 미커밋 상태: tracked 변경 57개, untracked 항목 396개(이 문서 추가 전 집계)
- 의도하지 않은 기존 변경: 별도로 되돌리지 않음. 모든 누적 변경을 현재 후보 상태로 보존함.
- 스태시 또는 별도 작업공간: 없음
- 빌드 산출물: `tmp/v122_release_candidate/20260805_225608/`
- 전체 검증 보고서: `tmp/core_verification/latest.json`, `tmp/core_verification/latest.md`
- 원격 푸시: 안 함

## 11. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 전체 회귀 통과
- [x] 그래픽·오디오 생성 출처와 런타임 연결 기록 완료
- [x] Windows 후보 export·부팅·ZIP·SHA-256 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 물리 한국어 IME owner gate
- [ ] 검수 대상 최종 커밋 SHA와 SHA-bound PASS 기록
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시·PR 병합·`v1.2.2` 태그·Release
