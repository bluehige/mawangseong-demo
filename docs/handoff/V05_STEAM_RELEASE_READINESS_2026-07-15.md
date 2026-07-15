# v0.5 Steam 판매 출시 준비 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-15
- 목표 버전: v0.5 Steam 판매 출시 준비 기반
- 작업 브랜치: `codex/v05-steam-release-readiness`
- 기준 브랜치 및 SHA: 최신 `main` / `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 마지막 Steam 구현 커밋 SHA: `856440c525fec8d82ce5a10d7dc25e3e160cb31c`
- 통합 검증 SHA: `63d1242624d3d0fff27b53c84fe286de4f372156`(진행 중 별도 세션이 추가한 오디오 도구 커밋 포함)
- 원격 푸시 여부: 미실행
- 관련 PR 또는 태그: 없음

## 2. 이번 세션 목표

- 요청 사항: 게임을 Steam에 올려 실제로 판매할 수 있도록 사용자가 해야 하는 일과 저장소에서 자동화할 일을 모두 정리하고 기반을 구현한다.
- 완료 조건: Steamworks 가입부터 출시까지의 책임 분담과 일정이 문서화되고, 스토어 초안·필수 그래픽·Windows depot 빌드·SteamPipe 업로드·Steam Cloud 설정·출시 차단 검증을 재현할 수 있다.
- 범위에서 제외한 사항: 사용자의 계약 서명, 본인·세금·은행 검증, 앱 등록비 결제, 한국 법적 의무에 대한 확정 자문, 실제 App/Depot ID 발급, Steamworks 포털 입력·업로드, Valve 심사, 출시 버튼 실행, 전체 회귀·전체 플레이·별도 검수 에이전트.

## 3. 완료한 작업

- 출시 운영: Windows 64-bit 유료 정식판, Coming Soon 뒤 Demo, Steam Auto-Cloud를 사용하는 최소 출시 구조를 고정했다.
- 책임 분담: 사용자가 직접 처리할 Steamworks 계약·신원·세금·은행·앱 등록비·한국 사업/등급 확인과, 이후 저장소에 전달할 공개 메타데이터를 분리했다.
- 스토어: 한국어 상점 설명, Steamworks 포털 입력값, 콘텐츠·폭력·공포·사전 생성형 AI 설문 초안을 작성했다.
- 그래픽: 현재 게임의 GPT 내부 생성 엔딩 자산을 기반으로 Steam 상점·라이브러리·아이콘 규격 자산을 만들고, 1920×1080 실제 플레이 스크린샷 6장을 연결했다.
- 빌드: Godot 4.5.2 `Windows Steam` export preset, 초기 임포트, 별도 EXE/PCK, 라이선스 포함, SHA-256 매니페스트 생성을 자동화했다.
- 배포: 전용 빌드 계정과 공식 Steamworks SDK를 사용하는 SteamPipe VDF 생성·업로드 스크립트를 추가했다. 비밀번호와 Steam Guard 코드를 인자·VDF·Git에 남기지 않으며 기본 브랜치를 자동 공개하지 않는다.
- 출시 차단: App/Depot ID, 연락처, 개인정보 처리방침, 권리, 콘텐츠 설문, 그래픽, 사양, Cloud, 설치, Valve 승인, Coming Soon 기간을 엄격 모드에서 차단한다.
- 패키지 안전: Steam export plugin이 소스, 도구, 문서, 마케팅 원본, 임시 산출물을 PCK에서 제외하며 검증기가 금지 경로를 실제 PCK 디렉터리에서 검사한다.
- 저장 호환성: 공개 게임명은 `마왕님, 마왕성은 누가 지켜요?`로 정리하되 기존 사용자의 저장 경로는 유지했다.
- CI: 관련 Python 테스트와 저장소 정책 검사를 추가하고, `v*` 태그에서 Windows Steam artifact를 생성하는 GitHub Actions를 추가했다.
- 법적 고지: Godot, Noto Sans CJK, NEXON MapleStory 폰트 고지를 depot에 포함한다. 문서는 법률·세무 자문이 아니며 한국 의무는 관할 기관 또는 전문가 확인 대상으로 남겼다.
- 스토리·밸런스·게임 데이터: 변경 없음.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `docs/release/STEAM_RELEASE_MASTER_PLAN.md` | 판매 가능 조건, 운영 구조, 역산 일정, 공식 기준 | 완료 |
| `docs/release/OWNER_ACTIONS.md` | 사용자 직접 작업, 한국 별도 확인, 안전한 전달값 | 완료 |
| `steam/release_config.json` | App/Depot/Cloud/출시 게이트 단일 설정 | 외부 값 17개 대기 |
| `steam/store/` | 상점 문구, 포털 입력값, 콘텐츠·AI 설문 초안 | 사용자 승인 필요 |
| `marketing/steam/` | 필수 Steam 그래픽, 실제 플레이 스크린샷, 출처 문서 | 규격 검사 완료, 사용자 승인 필요 |
| `tools/release/PrepareSteamBuild.ps1` | 깨끗한 SHA 기반 Godot Windows depot 빌드 | PASS |
| `tools/release/UploadSteamBuild.ps1` | SteamPipe VDF 생성과 보안형 업로드 | 포털 ID·SDK 대기 |
| `tools/release/validate_steam_release.py` | 설정·그래픽·빌드·PCK·출시 게이트 검증 | PASS |
| `tools/release/generate_steam_graphics.py` | 승인된 기존 자산에서 Steam 그래픽 재생성 | PASS |
| `addons/steam_release_export_filter/` | 개발·문서·원본 자산의 PCK 제외 | 실제 export 확인 |
| `export_presets.cfg` | `Windows Steam` 별도 PCK export preset | 실제 export 확인 |
| `.github/workflows/build-windows-steam.yml` | 태그 기반 Windows artifact 생성 | 로컬 구문·정책 확인, 원격 미실행 |
| `.github/workflows/repository-policy.yml` | Steam 준비 검증을 기존 정책 CI에 연결 | 로컬 테스트 PASS, 원격 미실행 |
| `tools/ci/test_validate_steam_release.py` | Steam validator 회귀 테스트 | 6/6 PASS |
| `legal/` 및 폰트 라이선스 파일 | 개인정보 처리방침 초안과 제3자 고지 | 공개 정보 확정 필요 |
| `project.godot` | 공개 게임명과 기존 저장 경로 고정 | PASS |
| `tools/ManualVerificationCapture.gd` | Steam용 실제 플레이 캡처 안정화 | PASS |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번 세션에서 신규 생성은 하지 않음. 기존 GPT 내부 생성 게임 자산을 Steam 마케팅 그래픽의 입력으로 재사용.
- 생성 모델: `GPT internal image generation`(기존 원본의 기록값)
- 생성 원본 경로: `assets/source/imagegen/update4_endings_phase32/ending_e19_minion_crown_source_2026-07-14.png`
- `SOURCE.md` 경로: `assets/source/imagegen/update4_endings_phase32/SOURCE.md`
- 기존 런타임 입력 자산: `assets/ui/endings/update4/ending_minion_wears_the_crown.png`
- Steam 최종 자산 경로: `marketing/steam/store/`, `marketing/steam/library/`, `marketing/steam/icons/`, `marketing/steam/screenshots/`
- 후처리 요약: 외부 이미지나 출처 불명 자산을 사용하지 않고, 저장소의 결정론적 스크립트로 크롭·리사이즈·타이포그래피·아이콘 변환을 수행했다. 상세 연결은 `marketing/steam/ARTWORK_PROVENANCE.md`에 기록했다.
- 게임 연결 및 실제 렌더 확인: 캡처 도구로 실제 게임 화면 6장을 1920×1080으로 생성하고 직접 확인했다. 상점·라이브러리·아이콘은 Steam 필수 치수 검사를 통과했다.
- 오디오: 이번 Steam 작업에서 변경하지 않았다. 작업 도중 별도 세션이 오디오 도구를 `63d1242624d3d0fff27b53c84fe286de4f372156`으로 커밋했다. 해당 커밋을 보존하고 Steam 패키지 영향만 재검증했으며 오디오 파이프라인 자체는 이번 검수 범위가 아니다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `python tools/release/validate_steam_release.py` | SETUP_PASS, 외부 항목 17개 PENDING | `steam/release_config.json` |
| 2 | `python -m py_compile tools/release/validate_steam_release.py tools/release/generate_steam_graphics.py` | PASS | Python 구문 검사 |
| 3 | `python tools/ci/test_validate_steam_release.py` | PASS, 6/6 | validator 단위 테스트 |
| 4 | `python tools/ci/test_validate_build_manifest.py` | PASS, 13/13 | 기존 빌드 매니페스트 회귀 포함 |
| 5 | PowerShell parser로 `PrepareSteamBuild.ps1`, `UploadSteamBuild.ps1` 파싱 | PASS | 구문 오류 0 |
| 6 | `./tools/ci/TestRepositoryPolicy.ps1` | PASS, 9 scenarios | 저장소 정책 회귀 |
| 7 | 깨끗한 detached worktree에서 `PrepareSteamBuild.ps1 -Version 0.3.0` | PASS | Godot 4.5.2 전체 임포트·Windows export·depot validator |
| 8 | 생성 매니페스트 확인 | PASS | source SHA `63d1242624d3d0fff27b53c84fe286de4f372156`, artifact 5개 |
| 9 | 패키지 `MawangCastle.exe --headless --quit-after 60` | PASS | exit 0, stdout/stderr ERROR 0 |
| 10 | Steam validator의 실제 PCK 금지 경로 검사 | PASS | 소스·도구·문서·마케팅 원본 포함 없음 |
| 11 | Steam 그래픽 치수 검사와 6장 실제 플레이 캡처 확인 | PASS | `marketing/steam/` |
| 12 | `git diff --check` | PASS | 공백 오류 0 |
| 13 | 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED | 저장소 정책에 따라 미실행 |

### 검수 에이전트 반복 기록

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음. 전체 회귀·전체 플레이·별도 검수 에이전트는 요청되지 않았다.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. Reviewed SHA 이후에는 이 핸드오프와 `CURRENT.md`만 변경한다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 63d1242624d3d0fff27b53c84fe286de4f372156
- Review range: d5a2d24457edcb919ae3ae4fe1d642552097f9c8..63d1242624d3d0fff27b53c84fe286de4f372156
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 판매 가능 상태는 아직 아니다. validator가 보여 주는 17개 항목은 Steamworks 계정·공개 정보·사용자 승인·Valve 심사·실기기 검수를 기다리는 의도적 출시 차단이다.
- `app_id`, `windows_depot_id`, 선택적 `demo_app_id`는 아직 0이다. 공개 지원 이메일과 개인정보 처리방침에도 placeholder가 남아 있다.
- 한국의 사업자등록, 세무, 게임 등급/관련 사업자 신고, 통신판매업 의무는 계약 주체와 Valve의 판매 구조를 제시하여 관할 기관 또는 전문가에게 확인해야 한다.
- Steam Cloud와 설치·실행·업데이트·삭제는 App/Depot 생성 뒤 Steam 클라이언트와 서로 다른 PC 2대에서 확인해야 한다.
- 시스템 요구사항은 대표 저사양·권장 사양에서 측정하기 전까지 임의로 확정하지 않는다.
- 현 빌드 재현은 프로젝트에 기록된 `0.3.0`으로 확인했다. 실제 판매 버전과 태그는 v0.4 마감 및 다음 출시 범위 확정 뒤 일치시켜야 한다.
- 원격 CI, SteamPipe 업로드, Valve 리뷰는 아직 실행하지 않았다.

## 8. 다음 작업 순서

1. 사용자: `docs/release/OWNER_ACTIONS.md` 순서대로 계약 주체를 정하고 Steamworks NDA/SDA, 앱 등록비, 신원·세금·은행 검증을 완료한다. 완료 조건은 App Credit 활성화와 Partner 홈의 검증 완료다.
2. 사용자 → 저장소 작업: 공개 App/Depot ID, 개발자·퍼블리셔명, 지원 이메일/사이트, 최종 게임명, 가격 방향, 목표 출시일만 전달한다. 완료 조건은 `steam/release_config.json`, 개인정보 처리방침, 스토어 초안의 placeholder 0개다.
3. 공동 승인: 권리·한국 의무·콘텐츠 및 사전 생성형 AI 설문·스토어 문구·그래픽·가격을 승인하고 Coming Soon 페이지를 제출한다. 완료 조건은 Valve 스토어 승인과 Coming Soon 공개일 기록이다.
4. 저장소/Steamworks: 정식 SemVer 태그에서 빌드하고 SteamPipe로 비공개 branch에 업로드하여 설치·실행·업데이트·삭제와 Auto-Cloud를 PC 2대에서 확인한다. 완료 조건은 관련 게이트가 모두 `true`다.
5. 출시: Valve 빌드 승인, Coming Soon 최소 14일, 고객지원 준비와 `--strict` PASS를 확인한 뒤 사용자가 Steamworks에서 직접 Release App을 실행한다.

## 9. 작업 트리 상태

- 브랜치: `codex/v05-steam-release-readiness`
- 기준 SHA: `d5a2d24457edcb919ae3ae4fe1d642552097f9c8`
- 마지막 Steam 구현 SHA: `856440c525fec8d82ce5a10d7dc25e3e160cb31c`
- 통합 검증 SHA: `63d1242624d3d0fff27b53c84fe286de4f372156`
- 미커밋 파일: 최종 문서 커밋 뒤 없음.
- 의도하지 않은 기존 변경: 작업 시작 시에는 깨끗했으며 진행 중 별도 오디오 작업이 같은 브랜치의 `63d1242`로 커밋됐다. 재작성하지 않고 보존했으며 Steam export 영향만 검증했다.
- 스태시 또는 별도 작업공간: 빌드 검증용 detached worktree만 사용했고 검증 후 제거한다. 스태시는 사용하지 않았다.
- 빌드/캡처 산출물: 검증용 Windows 빌드는 임시 worktree의 ignored `builds/`에서 생성했으며 저장소에 커밋하지 않는다. Steam 마케팅용 최종 스크린샷만 `marketing/steam/screenshots/`에 추적했다.
- 원격 푸시·PR·태그: 미실행.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 관련 테스트 통과
- [x] 전체 회귀·검수 에이전트가 요청되지 않았음을 기록
- [x] 검수 대상 최종 SHA와 정책 필드 기록
- [x] 그래픽 출처와 Steam 최종 자산 연결 기록 완료
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 구현 커밋
- [x] 외부 17개 게이트를 미완료로 정확히 기록
- [x] 원격 푸시·PR·태그 미실행 상태 기록
