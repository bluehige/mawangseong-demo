# 제품 1.2.1 공개 출시 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-20
- 목표 버전: 제품 표시 1.2 / 기술 SemVer 1.2.1
- 최종 기록 브랜치: `codex/v121-release-record-final`
- 기록 기준 브랜치 및 SHA: `origin/main` / `bc7ca8e2b0763814b69beaf0db3ee29bc3cf8d56`
- 출시 런타임·태그 SHA: `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- 출시 workflow 강화 merge SHA: `bc7ca8e2b0763814b69beaf0db3ee29bc3cf8d56`
- 원격 푸시 여부: 최종 기록 docs-only PR 전
- 관련 이슈·PR: [이슈 #39](https://github.com/bluehige/mawangseong-demo/issues/39), 소스 PR [#40](https://github.com/bluehige/mawangseong-demo/pull/40)·[#41](https://github.com/bluehige/mawangseong-demo/pull/41)·[#42](https://github.com/bluehige/mawangseong-demo/pull/42), PC Web PR [#6](https://github.com/bluehige/mawangseong-web-playtest/pull/6), 모바일 Web PR [#7](https://github.com/bluehige/mawangseong-mobile-playtest/pull/7)·[#8](https://github.com/bluehige/mawangseong-mobile-playtest/pull/8)

## 2. 이번 세션 목표

- PR #40의 플레이 검수 수정분을 `main`에 merge commit으로 통합한다.
- 기존 불변 태그 `v1.2.0`을 유지하고 기술 수정판 `v1.2.1`을 별도 PR·태그·GitHub Release로 출시한다.
- 정확한 출시 태그에서 Windows 패키지, PC Web, 모바일 Web을 생성한다.
- Windows는 GitHub Release 자산으로 제공하고 PC·모바일 Web은 각각 공개 Pages 링크에서 바로 체험할 수 있게 한다.
- 사용자가 요청한 전체 검수와 실제 플레이 검수 결과를 합쳐 출시 차단 P1/P2가 없는지 확인한다.

## 3. 완료한 작업

- PR #40을 ready 상태로 전환하고 필수 `repository-policy` 통과 뒤 merge commit `25a41a4f08925e35592aca890e0c56a75c5203f9`로 `main`에 병합했다.
- `hotfix/v1.2.1`을 새 `main`에서 분기했다.
- `project.godot` 기술 버전을 `1.2.1`로 올렸고 화면 표시와 기존 사용자 저장 경로는 1.2로 유지했다.
- Windows 및 Steam export의 파일·제품 버전을 `1.2.1.0`으로 맞추고 Windows 출력 경로를 1.2.1 패키지명으로 변경했다.
- 버전 정책, README, Steam 예시와 `docs/release/V1_2_1_RELEASE_NOTES_2026-07-20.md`를 갱신했다.
- 기능·버전 SHA `07586e51a7c66d6290602629a54b4cb6ce6b6d40`의 깨끗한 분리 작업공간에서 전체 코어 검증 89/89를 통과했다.
- GitHub PR #41에서 발견된 Steam validator 테스트의 1.2.0 하드코딩을 제거하고 `project.godot` 기술 버전을 읽도록 수정했다. 제품 validator 로직과 런타임은 변경하지 않았다.
- 최종 검증 SHA `8b2f1e4f626501b555efb03802b6d07df02c9226`에서 Steam validator 단위 테스트 6/6, manifest validator 13/13, 저장소 정책 테스트 9/9와 전체 코어 검증 89/89를 통과했다.
- 이전 수정 Windows 빌드에서 이름 `마왕성` 입력, 대화 표시, 저장 JSON 반영, 종료·재실행, 이어하기 복원을 확인했다.
- PR #41을 merge commit `c483d135b13cf9771ee43b045ba2c3dde51573ee`로 `main`에 병합하고, 그 정확한 merge SHA에서 전체 코어 검증 89/89와 `source_tree_clean=true`를 다시 확인했다.
- 주석 태그 `v1.2.1`을 만들고 태그 객체 `eca4d82d6d5820f807eb98ac33c3959220d8f603`이 출시 SHA `c483d135...`를 가리키는 상태로 푸시했다. 기존 `v1.2.0`과 `v1.2.1` 태그는 이동하지 않았다.
- [GitHub Release `마왕성 v1.2.1`](https://github.com/bluehige/mawangseong-demo/releases/tag/v1.2.1)을 공개했다. Windows 자산은 `MawangCastle-v1.2.1-Windows.zip`, 263,306,748바이트, SHA-256 `63118100a3b304a1c10c904a6e6b5da2a368ee0d5721dcd9037b982f80f3cb3e`다.
- 정확한 태그 SHA의 clean LFS 작업공간에서 Windows EXE·PCK를 만들었다. EXE/PCK SHA-256은 각각 `46a9a1968e4cf0a2002f8e6e8d6d8525191ec634fbfca890b4466d8308f0a81d`, `6807712e5e88af5de59199d34e7d73007dcbbf5a6ea80c7fd66407cb0b8a04ac`이며 파일·제품 버전은 1.2.1.0이다.
- Windows 출시본을 실제 실행해 타이틀의 제품 표시 `버전 1.2`와 새 게임의 `F급 신입 마왕 등록` 화면까지 확인하고 정상 종료했다.
- PC Web을 PR #6, merge `1d02f2912be8ce5bbc115e2d4980398c6ea73d41`, Pages run [29732695420](https://github.com/bluehige/mawangseong-web-playtest/actions/runs/29732695420)로 배포했다. 모바일 Web은 PR #7, merge `8d84ca2106c4dd560f89b3af1f60d4fa4f36e844`, run [29732695904](https://github.com/bluehige/mawangseong-mobile-playtest/actions/runs/29732695904)로 배포했다.
- Playwright 공개 검수에서 PC 1920×1080과 모바일 844×390 모두 타이틀에서 새 게임 등록 화면까지 진입했고, 모바일 390×844에서는 가로 회전 안내가 표시됐다. 두 사이트 모두 콘솔 오류·경고 0건, HTML·JS·WASM·PCK 요청 전부 HTTP 200이었다.
- 독립 감사에서 모바일 브라우저 탭 제목만 `v1.2`로 남은 P3 표기 불일치를 발견해 PR #8, merge `5a0461f4a896a3c1d6829f6d0410b531a0614b35`, Pages run [29733411515](https://github.com/bluehige/mawangseong-mobile-playtest/actions/runs/29733411515)로 `v1.2.1`에 맞췄다. 공개 제목과 콘솔 오류 0건을 재확인했다.
- 최초 태그 Actions run 29729582970은 LFS WAV pointer를 실파일로 오인해 성공 표시됐으므로 해당 artifact ID 8455749963을 사용하지 않았다. PR #42에서 LFS 실파일·필수 BGM sample·Windows headless 부팅 검사를 추가했고 merge `bc7ca8e2...`의 repository-policy run [29732718325](https://github.com/bluehige/mawangseong-demo/actions/runs/29732718325)이 통과했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `AGENTS.md` | 현재 수정판 기술 SemVer와 불변 태그 정책에 1.2.1 반영 | 완료 |
| `project.godot` | 프로젝트 기술 버전 1.2.1 | 완료 |
| `export_presets.cfg` | Windows 출력명 및 파일·제품 버전 1.2.1.0 | 완료 |
| `README.md` | 최신 기술 SemVer 안내 | 완료 |
| `docs/PRODUCT_VERSIONING.md` | 1.2.1 안정화 수정판 계보 | 완료 |
| `steam/README.md` | 1.2.1 패키지 예시 | 완료 |
| `docs/release/V1_2_1_RELEASE_NOTES_2026-07-20.md` | 공개 변경점·링크·제한 | 완료 |
| `tools/ci/test_validate_steam_release.py` | 정상 manifest 픽스처가 프로젝트 기술 버전을 따르도록 수정 | 완료 |
| `docs/handoff/V12_1_PUBLIC_RELEASE_2026-07-20.md` | 검수·출시 핸드오프 | 완료 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 갱신 | 완료 |

기능 수정 파일은 PR #40과 `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md`에 기록돼 있으며 이번 버전 브랜치에서는 다시 수정하지 않았다.

최종 출시 기록 PR은 이 문서와 `docs/handoff/CURRENT.md`만 변경한다. Windows ZIP, PCK, WASM, 실행 파일과 Playwright 캡처는 소스 브랜치에 커밋하지 않는다.

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델·원본·`SOURCE.md`: 해당 없음
- 런타임 자산 변경: 없음
- 게임 연결 및 실제 렌더 확인: PR #40 검수에서 튜토리얼 표식·대화 UI·전투 화면을 확인했고 이번 버전 커밋은 자산을 바꾸지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `python tools/release/validate_steam_release.py` | `SETUP_PASS`; 외부 Steam 소유자 작업 17건은 예상대로 미완료 | 콘솔 기록 |
| 2 | `tools/tests/RunCoreVerification.ps1 -Mode Full` 1차 | 기능 88개 PASS, 최초 프로젝트 임포트만 Godot 접근 위반으로 FAIL | `tmp/core_verification/runs/20260720_163039/` |
| 3 | 동일 SHA 프로젝트 임포트 재시도 | PASS, 1,248단계 완료 | `tmp/v121_project_import_retry.log` |
| 4 | 깨끗한 작업 트리에서 `tools/tests/RunCoreVerification.ps1 -Mode Full` 재실행 | PASS, 89/89, `source_tree_clean=true` | `tmp/core_verification/latest.md`, `tmp/core_verification/latest.json` |
| 5 | 이전 수정 Windows export Computer Use | PASS: `마왕성` 입력·대화·저장·재실행·이어하기 | 격리 프로필 `tmp/ime_appdata_20260720_001/` |
| 6 | `python tools/ci/test_validate_steam_release.py` | PASS, 6/6 | 콘솔 기록 |
| 7 | `python tools/ci/test_validate_build_manifest.py` | PASS, 13/13 | 콘솔 기록 |
| 8 | `tools/ci/TestRepositoryPolicy.ps1` | PASS, 9/9 | 콘솔 기록 |
| 9 | 최종 SHA에서 `tools/tests/RunCoreVerification.ps1 -Mode Full` | PASS, 89/89, `source_tree_clean=true` | `tmp/core_verification/latest.md`, `tmp/core_verification/latest.json` |
| 10 | PR #41 merge SHA `c483d135...`에서 `RunCoreVerification.ps1 -Mode Full` | PASS, 89/89, `source_tree_clean=true` | merge SHA 콘솔·보고서 기록 |
| 11 | `v1.2.1` annotated tag 원격·로컬 peel 검증 | PASS, 태그 객체 `eca4d82d...` → `c483d135...` | `git ls-remote --tags`, `git rev-parse v1.2.1^{}` |
| 12 | GitHub Release·로컬 ZIP 자산 대조 | PASS, 263,306,748바이트와 SHA-256 `63118100...` 일치 | GitHub Release API, `Get-FileHash` |
| 13 | 태그 SHA clean Windows 패키지 구조·버전·실행 | PASS, EXE 1.2.1.0, PCK 오디오 포함, 타이틀→새 게임 진입 | `tmp/v121_public_windows_clean/`, Computer Use |
| 14 | PC Web PR #6 / Pages run 29732695420 | PASS, PCK 231,380,996바이트, 공개 배포 성공 | PC Pages 저장소·Actions |
| 15 | 모바일 Web PR #7 / Pages run 29732695904 | PASS, PCK 146,798,916바이트, 공개 배포 성공 | 모바일 Pages 저장소·Actions |
| 16 | Playwright PC 1920×1080 공개 URL | PASS, 타이틀→새 게임 등록, 콘솔 오류·경고 0, 요청 실패 0 | `output/playwright/v121-public-20260720/pc-new-game.png` |
| 17 | Playwright 모바일 844×390 / 390×844 공개 URL | PASS, 새 게임 등록과 세로 회전 안내, 콘솔 오류·경고 0, 요청 실패 0 | `output/playwright/v121-public-20260720/mobile-landscape-new-game.png`, `mobile-portrait-390x844.png` |
| 18 | 모바일 제목 PR #8 / Pages run 29733411515 | PASS, 공개 `<title>` `마왕성 v1.2.1 · 모바일 Web`, 콘솔 오류 0 | 모바일 Pages 저장소·Playwright |
| 19 | 출시 workflow PR #42 / main run 29732718325 | PASS, repository-policy와 validator 테스트 전부 성공 | 소스 저장소·Actions |

후보 SHA의 최종 전체 검증은 2026-07-20 17:25:08~17:38:35 KST에 실행됐고 807.27초가 걸렸다. 보고서의 커밋 SHA는 `8b2f1e4f626501b555efb03802b6d07df02c9226`, 전체 89개 중 PASS 89개·FAIL 0개다. 직전 전체 런에서 성 Stage 4 캡처가 240초 그래픽 프로세스 타임아웃으로 1회 실패했으나 동일 장면 단독 실행은 5.9초 PASS했고, 최종 전체 런에서도 Stage 1~4가 5.7초에 PASS했다. 이후 정확한 PR #41 merge·태그 SHA `c483d135...`에서도 89/89를 다시 통과해 출시본과 검수 SHA를 일치시켰다.

### 검수 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 | 대상 | 주요 지적 | 수정·대응 | 근거 | 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | `FULL_USER_PLAYTEST_2026-07-20_V12` | 이슈 #39 및 사용자 추가 지적 | `6a2dd1747c7a07a10c0a4bf37b4cd59911c69f54` | DAY 3 진행 불가, 튜토리얼·대화 UI, 자동전투 정체 | PR #40에서 수정 | `docs/handoff/V12_USER_PLAYTEST_QA_2026-07-20.md` | PASS |
| 2 | `FULL_RELEASE_VERIFICATION_2026-07-20_V121` | `25a41a4f08925e35592aca890e0c56a75c5203f9..07586e51a7c66d6290602629a54b4cb6ce6b6d40` | `07586e51a7c66d6290602629a54b4cb6ce6b6d40` | 최초 OTF 임포트 시 Godot 4.5.2 접근 위반 | 동일 blob 캐시 완성 뒤 깨끗한 작업 트리에서 전체 재실행 | `tmp/core_verification/latest.md` | 89/89 PASS |
| 3 | `FULL_RELEASE_VERIFICATION_2026-07-20_V121` | `25a41a4f08925e35592aca890e0c56a75c5203f9..8b2f1e4f626501b555efb03802b6d07df02c9226` | `8b2f1e4f626501b555efb03802b6d07df02c9226` | Steam 테스트 픽스처 구버전 하드코딩, 성 Stage 4 캡처 일회성 타임아웃 | 프로젝트 버전 동적 참조, 단독 재현 후 전체 재실행 | `tmp/core_verification/latest.md` | 89/89 PASS |
| 4 | `FULL_RELEASE_VERIFICATION_2026-07-20_V121` | `25a41a4f08925e35592aca890e0c56a75c5203f9..c483d135b13cf9771ee43b045ba2c3dde51573ee` | `c483d135b13cf9771ee43b045ba2c3dde51573ee` | PR #41 merge 결과가 후보와 동일한지 확인 필요 | 정확한 merge SHA의 clean worktree에서 전체 재실행 | merge SHA 전체 검증 기록 | 89/89 PASS |

- 남은 P1/P2 지적: 0건
- 실행하지 못한 필수 검수와 이유: Computer Use 드라이버가 물리 한/영 키 코드를 제공하지 않아 Microsoft 한국어 IME의 실제 한/영 전환 동작은 수동 실기 확인이 필요하다.
- PASS 이후 기능·데이터·자산 변경 여부: 출시 태그 `c483d135...`에는 없음. 이후 `main`의 PR #42는 다음 태그용 release validator·workflow만 강화했고 별도 targeted 검증을 통과했다.

### 정책 CI용 최종 승인 필드

- Review task ID: FULL_RELEASE_VERIFICATION_2026-07-20_V121
- Reviewed SHA: c483d135b13cf9771ee43b045ba2c3dde51573ee
- Review range: 25a41a4f08925e35592aca890e0c56a75c5203f9..c483d135b13cf9771ee43b045ba2c3dde51573ee
- Remaining P1/P2: 0
- Final review result: PASS

## 7. 미해결 항목과 위험

- Windows 코드 서명 인증서가 없어 공개 패키지는 서명되지 않는다. 릴리스 노트에 이를 명시한다.
- 물리 Microsoft 한국어 IME 한/영 키 전환은 수동 실기 확인 항목이다. 확정 한글 `마왕성`의 게임 입력·저장·재실행 복원은 확인했다.
- Godot 4.5.2가 최초 대량 임포트에서 `NEXON_Maplestory_Bold.otf` 처리 중 `c0000005`로 비결정적으로 종료됐다. 자산이나 출시 게임 충돌은 아니며 캐시를 완성한 뒤 동일 SHA의 프로젝트 임포트와 전체 89개 검증이 통과했다.
- 장시간 전체 검증에서 성 Stage 4 시각 캡처가 한 번 240초 타임아웃됐지만, 장면 단독 실행과 다음 전체 실행은 각각 5.9초·5.7초에 통과했다. 재현되는 제품 결함이 아니라 검수 그래픽 프로세스의 일회성 지연으로 기록한다.
- 모바일 버전은 APK/AAB가 아니라 모바일 브라우저용 Web 빌드다.
- GitHub Release API의 플랫폼 `immutable` 기능은 활성화돼 있지 않다. 저장소 정책상 `v1.2.1` 태그를 이동·삭제·재지정하지 않고 현재 tag object와 peeled SHA를 감사 기준으로 유지한다.
- 태그 직후 Actions run 29729582970의 artifact는 LFS 오디오 누락으로 사용 금지다. 공개 Release의 ZIP은 정확한 태그 SHA clean LFS 빌드이며 GitHub digest와 로컬 해시가 일치한다.

## 8. 다음 작업 순서

1. 필수 출시 작업은 완료됐다. `v1.2.1` 태그와 Release 자산은 이동·교체하지 않는다.
2. 이슈 #39는 물리 Microsoft 한국어 IME 한/영 조합 중 상태를 사람이 실기 확인한 뒤 닫는다.
3. 선택 후속으로 실제 Android/iOS 안전 영역과 저사양 PC·모바일 10분 발열·메모리를 확인한다.
4. 다음 불변 태그에서는 강화된 Windows workflow가 LFS WAV, PCK 필수 BGM sample, headless 부팅을 모두 통과하는지 확인한다.

## 9. 작업 트리 상태

- 최종 기록 브랜치: `codex/v121-release-record-final`
- 기준 `origin/main`: `bc7ca8e2b0763814b69beaf0db3ee29bc3cf8d56`
- 출시 런타임·태그·Reviewed SHA: `c483d135b13cf9771ee43b045ba2c3dde51573ee`
- PC Pages main: `1d02f2912be8ce5bbc115e2d4980398c6ea73d41`
- 모바일 Pages main: `5a0461f4a896a3c1d6829f6d0410b531a0614b35`
- 이 문서 작성 전 상태: clean worktree, 이후 이 문서와 `CURRENT.md`만 수정
- 빌드·검수 산출물: `tmp/` 아래에만 존재하며 커밋하지 않는다.
- 주 작업공간의 사용자 소유 미추적 UID 5개는 수정·스테이징하지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 사용자 요청 범위의 전체 자동 회귀·검수 통과
- [x] 검수 대상 불변 기능 SHA 기록
- [x] 그래픽·오디오 자산 변경 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] `hotfix/v1.2.1` 원격 푸시와 PR #41 merge commit 병합
- [x] `v1.2.1` 태그와 Windows GitHub Release
- [x] PC·모바일 Web Pages 배포와 공개 URL 검증
- [x] 잘못된 태그 Actions artifact 사용 금지 및 workflow 방어 PR #42 병합
- [x] 최종 출시 링크·해시·배포 SHA 기록
