# 1.2.10 사용자 피드백 수정 빌드 — 2026-10-08

## 1. 메타데이터

- WORKSTREAM_ID: V1210_PLAYER_FEEDBACK_HOTFIX_20261008
- 작성일: 2026-10-08 KST
- 목표 버전: 1.2.10 유지 / Windows file·product 1.2.10.0 유지
- 작업 브랜치: codex/v1210-player-feedback
- 기준 브랜치 및 SHA: fetch로 확인한 origin/main@0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b
- 마지막 제품 커밋 SHA: feb230dda34b77b971081bf986a683bcb88c2d43; 이 SHA 이후에는 핸드오프만 추가한다.
- 원격 푸시 여부: 아니오. 기존 폴더·main·불변 v1.2.10 태그·Release 변경 없음.
- 작업공간: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\tmp\v1210_player_feedback
- 기존 루트는 codex/v125-release-candidate@e6ae83d의 역사적 작업선이다. fetch된 origin/main의 권위 CURRENT/AGENTS와 최신 1.2.10 핸드오프를 읽고 새 작업공간에서 시작했다.

## 2. 이번 세션 목표

사용자 요청: 캐릭터 일러스트 크기 편차를 줄여 주인공을 가장 크게 표시하고, 창모드 및 대화창 클릭으로 다음 대사 이동을 추가한 뒤 버전업 없이 Steam에 바로 업로드할 빌드를 준비한다.
완료 조건: 세 수정·직접 테스트·실제 Windows 대표 화면·Steam 6파일 ZIP 검증.
전체 회귀·전체 플레이·별도 검수 에이전트·Steam 업로드·default 적용·새 태그·GitHub Release는 요청 범위에 포함하지 않았다. 사용자는 직접 Steam에 올릴 예정이라고 말했다.

## 3. 완료한 작업

- 일러스트: uiux3d의 비어 있는 알파 여백을 런타임 AtlasTexture 표시 영역에서 제외한다. 주인공 1.0, 다른 캐릭터 0.8 배율과 공통 하단 기준선을 적용한다. 구 초상화도 주인공보다 작은 틀로 표시한다. 모든 등록 캐릭터·표정의 너비/높이 우선순위와 대표 화면을 확인했다.
- 창모드: 화면 설정에 Windowed/Fullscreen을 추가했다. 창모드에는 제목 표시줄·크기 조절·화면 내 중앙 배치가 있고 기본 크기는 1280×720이다. 적용 시 settings.cfg에 저장하고 취소/기본값/재시작 읽기에 포함한다. Alt+Enter는 대화 입력보다 먼저 처리하며 설정 화면에서는 저장하지 않는 미리보기로 작동한다. Web/mobile/headless에는 네이티브 모드 옵션을 노출하지 않는다.
- 대화: 도입 대화·메인 스토리·전투 오버레이에서 대화창 여백과 본문 클릭으로 기존 다음 버튼과 같은 함수를 호출한다. 왼쪽 누름 한 번에 한 줄만 이동하고 우클릭·휠·더블클릭의 두 번째 누름·Auto 버튼은 추가 이동을 유발하지 않는다. 마지막 전투 대화 뒤 전투가 재개된다.
- 한·영·간체 설정 4키씩 추가. 버전·스토리 내용·밸런스·캠페인 저장 schema·이미지 원본·오디오 변경 없음.
- 동일 버전 빌드 출처: PrepareSteamBuild.ps1의 -SameVersionHotfix와 검사기를 추가했다. manifest는 version=1.2.10, build_kind=same_version_hotfix, tag=null, 실제 새 source_commit을 기록한다. 불변 v1.2.10 태그의 원래 출시본으로 위장하지 않는다.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| scripts/core/UISettings.gd | 창모드 적용·저장·snapshot·복원 | 완료 |
| scripts/game/GameRoot.gd | 화면 옵션·Alt+Enter·초상화 크기·대화 클릭 | 완료 |
| scripts/story/StoryDialoguePresenter.gd | 일반/전투 스토리 클릭 연결 | 완료 |
| data/localization/v122_stage10_ui.json | 한·영·간체 화면 모드 문구 | 완료 |
| tools/tests/PlayerFeedbackHotfixTest.gd / .tscn | 포인터·네이티브 화면·모든 표정·UI 검증 | 완료 |
| tools/release/PrepareSteamBuild.ps1 / validate_steam_release.py | 동일 버전 빌드 manifest | 완료 |
| tools/ci/test_validate_steam_release.py | 새 커밋 빌드의 기존 태그 오인 방지 | 완료 |
| docs/handoff/CURRENT.md / V1210_PLAYER_FEEDBACK_HOTFIX_2026-10-08.md | 종료 기록 | 완료 |

## 5. 그래픽 및 오디오 자산

새 생성·이미지 픽셀 변경·외부 서비스 호출 없음. 원본 PNG와 출처 문서는 보존했다. 표시할 때의 영역·배율만 변경했다.
대표 1280×720: 주인공/바티/로로/곱/푸딩 비교, 일반 대화, 전투 대화, 한·영·간체 화면 설정. 캡처는 tmp/player_feedback/ 및 packaged/에만 둔다.

## 6. 테스트 및 검수

| 검증 | 결과 | 증거 |
|---|---|---|
| 최종 소스 GUI 직접 테스트 | PASS, 145 checks / 0 failures | tmp/player_feedback/targeted-gui-final.log |
| 최종 소스 headless 직접 테스트 | PASS, 136 checks / 0 failures | tmp/player_feedback/targeted-headless-final.log |
| V122StoryProductFlowTest | PASS, 33 assertions | tmp/player_feedback/V122StoryProductFlowTest.log |
| V122Stage10LocalizationTest | PASS, 45 assertions | tmp/player_feedback/V122Stage10LocalizationTest.log |
| V122TutorialGuidanceLevelTest | PASS | tmp/player_feedback/V122TutorialGuidanceLevelTest.log |
| Steam release validator 단위 테스트 | PASS, 11 tests | python -m unittest discover -s tools/ci -p test_validate_steam_release.py |
| 최종 Windows Steam export/패키지 검사 | PASS | tmp/player_feedback/steam-export-final.log |
| PCK 독립 검사 | PASS, 3385 entries; project.binary 1539 bytes; 금지 경로 0; 카탈로그 5종 소스 일치·CJK font·compiled scripts | tmp/player_feedback/pack-content-final.log |
| 최종 PCK 실제 GUI 실행 | PASS, 145 checks / 0 failures | tmp/player_feedback/packed-runtime.log; packaged/ 캡처 |
| 최종 출시 EXE 부팅 | --headless --quit-after 60, exit 0 | 실제 최종 EXE를 격리 APPDATA로 Start-Process 실행·종료 확인 |
| ZIP6파일 내용/무결성 | PASS | tmp/player_feedback/zip-verification.json |
| 전체 회귀·전체 플레이·별도 QA 에이전트 | NOT_REQUESTED | 실행하지 않음 |

읽기 전용 하위 에이전트는 최신 빌드 도구·Godot 실행파일·템플릿 위치 조사만 수행했다. 검수 에이전트로 기록하지 않는다.
첫 기본 환경 export는 exit0/패키지 표면 검사는 통과했으나 독립 PCK 검사에서 project.binary가 0bytes여서 폐기했다. 최종 export는 APPDATA/TEMP/TMP를 쓰기 가능한 프로젝트 내부 격리 폴더로 지정하고 공식 4.6.3 템플릿 두 파일을 복사해 해결했다. 편집기 설정의 safe-save 경고는 남았지만 최종 프로젝트 설정 바이트·실행·패키지 내용 검사로 런타임 산출물을 검증했다. 첫 sandbox EXE 외부 스크립트 캡처 시도는 로그/완료가 확인되지 않아 중단했다. 최종 EXE는 실제 headless 부팅만, 최종 PCK는 동일 4.6.3 콘솔 엔진의 --main-pack으로 실제 GUI 검증했다.
기존 StoryProductFlowTest 종료의 ObjectDB/resource 경고와 최종 PCK 합성 테스트에서 강제로 만든 캠페인 상태의 자동저장 요약 불일치 경고를 관찰했다. 이 합성 테스트는 캠페인 저장 검증 근거로 쓰지 않는다. SCRIPT/parse/resource-load 오류는 없다. 개인 캠페인/설정 파일은 수정하지 않았다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: feb230dda34b77b971081bf986a683bcb88c2d43
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..feb230dda34b77b971081bf986a683bcb88c2d43
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 산출물 및 미해결 항목

- 업로드 ZIP: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\builds\steam\windows\MawangCastle-v1.2.10-SteamContent-hotfix-20261008.zip
- ZIP bytes: 614425126
- ZIP SHA-256: be7f77a92095f8382334b1ae021287010c1c80696acff2b829a6464520fe0523
- 최종 6파일 폴더: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\builds\steam\windows\v1.2.10-hotfix-20261008-final
- manifest의 파일별 size/SHA256과 ZIP6엔트리의 size/SHA256/SHA1을 대조했다. 실행파일 file/product version은 1.2.10.0이다.
- Steam 서버 조회/업로드/default 적용·Steam 설치/2PC Cloud는 미실행. 로컬 release_config의 기존 외부 placeholder 15개를 실제 서버 승인 상태로 판단하지 않는다.
- 원어민/전체 DAY1–30/전체 회귀는 새로 수행하지 않았다. 요청 범위의 표적 검증은 완료했다.

## 8. 다음 작업 순서

1. 사용자가 위 최종 6파일 ZIP을 Steamworks에 업로드한다. 버전은 1.2.10이며 기존 태그/출시 파일을 대체하지 않는다.
2. 서버 Build/Manifest·파일을 대조한 뒤 사용자 배포 절차로 적용한다. 이번 세션은 서버 조치를 하지 않았다.
3. 소스 통합을 요청받으면 이 브랜치를 push하고 repository-policy 통과 후 main에 merge commit PR로 반영한다. 새 버전/태그는 발급하지 않는다.

## 9. 작업 트리 상태

- 제품 9파일만 명시적 스테이징해 커밋했다. 자동 .import 줄바꿈 상태와 테스트 .gd.uid는 이 세션의 새 작업공간 안에서만 정리한다.
- 원래 루트의 기존 .import 206개와 미추적 8항목은 보존했다. reset/stash/강제 push/기존 태그 이동 없음.
- 원격 push/PR/태그/Release/Steam upload 없음. 핸드오프만 문서 후속 커밋한다.
- 바이너리·ZIP·캡처·프로필은 ignored builds/ 및 tmp/에만 저장하며 소스 커밋에서 제외한다.

## 10. 종료 체크리스트

- [x] 세 요구사항 구현·버전 유지
- [x] 관련 자동 테스트·필요한 실제 대표 화면
- [x] 최종 PCK GUI 및 EXE 부팅
- [x] 최종 6파일 ZIP 무결성 검사
- [x] 검증 대상 제품 SHA·build provenance 기록
- [x] CURRENT와 세션 핸드오프 갱신
- [x] 의도한 제품 파일만 커밋
- [x] 원격·Steam 미실행 상태 기록

## 11. 사용자 승인 후 Steam 후속 상태

- 사용자는 열어둔 Chrome Steamworks에서 빌드를 업데이트하고 직접 해야 할 단계가 있으면 보고하라고 지시했다. 이번 수정 ZIP 업로드와 공개 기본 빌드 교체는 승인됐다.
- 실제 서버 조회: App5267750 Released, 현재 default Build25780940, Depot5267751 Manifest1499837472719962438. 기존 공개 빌드는1.2.10이며 버전 유지한다. 이 값은 위 역사 기록의 미조회 상태를 대체한다.
- Web Uploads의 올바른 Depot5267751/Standard 화면에서 최종 ZIP614425126bytes의 공식 filechooser 선택을 시도했다. 호출 후 DOM에서 input.files=[]를 확인해 Upload를 누르지 않았다.
- 공식 Chrome 업로드 문제 해결 문서가 요구한 ChatGPT 확장 `Allow access to file URLs` 또는 사용자 직접 파일 선택 대기다. 권한 확대를 자동으로 수행하지 않았다. 로그인·Steam Guard 장애는 나오지 않았다.
- 현재 업로드 페이지는 handoff로 보존했다. 확인 화면: tmp/player_feedback/steam-upload-awaiting-file.jpg (ignored).
- 신규 업로드/Build 생성/default 변경/서버 파일 대조는 아직 미실행. 선택 후 승인된 upload→6파일 크기/SHA1 대조→default 적용→Build/Manifest 전후 보고를 계속한다. 현 default25780940/Manifest1499837472719962438는 롤백 기준이다.
- 소스/바이너리/제품 SHA는 변경하지 않았다. 이번 후속은 docs/handoff 문서만 갱신하며 원격 push는 하지 않는다.

## 12. 업로드 완료·공개 적용 모바일 승인 대기

- 사용자 직접 파일 선택/업로드 후 Web Uploads에 Building depot done Manifest2614967785369199063이 표시됐다. 브라우저 입력의 files 배열은 이미 비어 있었으므로 서버 파일로 실제 선택본을 판단했다.
- Commit uploaded depots as build를 branch None으로 처리해 Build25803750 등록 성공을 확인했다. 설명은1.2.10 동일버전 수정과 제품 SHA feb230dda34b77b971081bf986a683bcb88c2d43이다.
- Manifest2614967785369199063의 서버 파일6개(689MB)의 크기/SHA1이 최종 ZIP의 각 파일과 전부 일치했다. DOM 행을 ignored tmp/player_feedback/steam-server-manifest-2614967785369199063.json에 저장하고 PowerShell로6/6 대조 PASS했다. 따라서 사용자가 선택한 ZIP은 이번 수정본이 맞다.
- Build Change Preview: default25780940/Manifest1499837472719962438 →25803750/2614967785369199063, 다운로드4.1MB. 승인 범위에서 Set Build Live Now와 JavaScript 확인창을 처리했다.
- 이어 나온 Confirm setting this build live 화면은 휴대폰 Steam Mobile authenticator 메뉴의 Confirmations 승인을 요구한다. 사용자에게 빌드25803750 요청의 직접 승인을 요청했고 대기 탭을 handoff로 보존했다. 공개 default의 최종 변경은 아직 확인하지 않았다.
- 증거: tmp/player_feedback/steam-manifest-verified.jpg 및 steam-mobile-confirmation-required.jpg (ignored). 로그인/OTP/비밀번호를 조회하지 않았다. 새 업로드 반복 불필요.
- 다음은 사용자 모바일 승인 후 Builds의 default25803750/Manifest2614967785369199063 및 Set live 이력을 확인하고 완료를 기록하는 것이다. 이전 빌드25780940은 롤백 기준으로 보존한다.
- 소스·버전·바이너리 변경 없음. docs/handoff 후속만 커밋하며 원격 push 없음. Steam 클라이언트 실설치·전체 회귀는 새로 실행하지 않았다.
- 사용자 채팅 응답은 "승인"이었다. 실제 서버 default가 여전히25780940임을 새로고침으로 확인했고 적용 단계 재진입 후에도 변화가 없어, 채팅 진행 승인인지 휴대폰 Confirmations 실제 완료인지 구분을 요청했다. 추가 업로드나 인증 우회는 하지 않는다. 사용자 완료 답변만으로 실제 공개 적용을 완료로 기록하지 않는다.
