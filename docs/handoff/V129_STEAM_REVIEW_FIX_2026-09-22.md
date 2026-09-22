# 1.2.9 Steam 심사 반려 입력 수정

## 1. 메타데이터
- 작성일: 2026-09-22
- 목표 버전: 1.2.9
- 작업 브랜치: codex/v128-steam-review-fix
- 기준 브랜치 및 SHA: origin/main / 1be65978fd7b0489647415ce9784e35e58a380f6
- 마지막 구현 커밋 SHA: be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- 원격 푸시 여부: 수정 및 검증 기록 push 완료 / PR #104 MERGED
- 배포 제품 SHA / 태그: 4076e099202f440c85a30699268d1c887c26c903 / v1.2.9
- 배포 기록 브랜치: codex/v129-steam-review-publish (기준 origin/main 4076e099202f440c85a30699268d1c887c26c903)
- 관련 PR: https://github.com/bluehige/mawangseong-demo/pull/104
- WORKSTREAM_ID: STEAM_REVIEW_FIRST_PLAY_INPUT_20260922

## 2. 목표와 원인
사용자 제공 반려 원문 및 Steamworks에서 App5267750 / Build25423797의 시설 드래그·몬스터 배치 불가, Defense 비활성, 회색 UI 차단을 확인했다. `_management_ui_at`이 `MOUSE_FILTER_IGNORE`인 전체 화면 TutorialOverlay까지 Panel이라는 이유로 입력 차단 영역으로 판정했다. 실제 GUI 드래그/배치는 실패하고 필수 고블린 배치 튜토리얼을 끝낼 수 없었다. 기존 관리 화면 검사는 튜토리얼을 건너뛰거나 내부 배치 함수를 호출하여 이 결함을 놓쳤다.

## 3. 완료한 구현
- Control의 실제 mouse_filter와 화면 좌표를 따르도록 수정. 안내 전용 패널은 통과시키며 자식 버튼·팝업은 계속 입력을 차단한다. 숨김·클리핑된 자식은 차단하지 않는다.
- 새 게임/필수 튜토리얼 상태에서 시설 드래그, 확정 비용1회, 고블린 클릭 및 드래그, 안내막 종료, Defense 활성화, 전투 적/수비대 생성을 실제 viewport 입력으로 검사했다. 인트로 대사 진행만 내부 함수를 사용한다.
- 기본 Quick/Full 검사 목록에 영어 새 게임 입력 회귀를 등록했다.
- 기존1.2.8을 보존하고 프로젝트/Windows 제품 버전을1.2.9로 구분했다.
- 스토리·밸런스·저장 형식·그래픽/오디오 자산 변경 없음. 신규 이미지 생성 없음.

## 4. 변경 파일
- scripts/game/GameRoot.gd: 수동 UI 영역 판정 수정
- tools/SteamFirstPlayInputTest.gd/.gd.uid/.tscn: 실제 입력 회귀
- tools/tests/core_verification_suite.json: 기본 검사 등록
- project.godot, export_presets.cfg, docs/PRODUCT_VERSIONING.md: 패치 버전
- docs/handoff/CURRENT.md 및 본 문서: 근거/후속 단계

## 5. 검증
Godot4.6.3.stable.official.7d41c59c4, 독립된 APPDATA 사용. 근거 루트 `tmp/steam_review_fix/`.

| 검사 | 결과 | 근거 |
|---|---|---|
| 수정 전 같은 새 게임 입력 | FAIL: 시설 드롭/고블린 배치/Defense 진행 차단 재현 | before_en.log |
| 영문1280×720 실제 그래픽/클릭 | PASS31 | en_click.log, en_click/*.png |
| 한국어1920×1080 실제 그래픽/몬스터 드래그 | PASS28 | ko_drag.log, ko_drag/*.png |
| 기본 headless 입력 회귀 | PASS26, exit0 | final_headless.log |
| 기존 건설·Undo·UI·4성 단계 회귀 | PASS344 | build_placement.log |
| 튜토리얼 흐름 | PASS177 | TutorialFlowSmokeTest.log |
| UI 입력 계층 | PASS35 | UIInputLayerSmokeTest.log |
| 초기 진행 DAY5/저장 호환 | PASS57 | OnboardingFlowSmokeTest.log |
| git diff --check | PASS | 로컬 실행 |

실제 캡처에서 안내막 제거·활성 Defense·전투 적/수비대를 확인했다. 숨긴 Windows 테스트 창에서는 OS 포인터가 프레임 간 버튼 hover를 바꾸므로 클릭 press/release를 같은 프레임에 주입한다. 시설/몬스터 드래그는 여러 프레임으로 검사한다. headless 종료 일부에서 ObjectDB/resource 정리 경고가 남으며 assertion 실패나 SCRIPT ERROR는 없다. 그래픽 첫 플레이 로그에는 해당 종료 경고가 없다. Steam 클라이언트 설치 테스트나 사람이 조작한 검수로 표현하지 않는다. 전체 캠페인/전체 회귀/별도 검수 에이전트는 NOT_REQUESTED.

### 정책 CI용 최종 승인 필드
- Review task ID: NOT_REQUESTED
- Reviewed SHA: be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- Review range: 1be65978fd7b0489647415ce9784e35e58a380f6..be8176ca39a2f3ebf85740ae7c5ab82cc5a729b0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 6. 남은 작업
1. Valve 수정 빌드/상점 심사 결과 확인. 수정·태그·기본 빌드 교체·재심사 접수는10절대로 완료했다.
2. Coming Soon 첫 공개 이후 최소2주 요건을 고려해 실제 출시일을 확정한다.
3. Steam 클라이언트 실설치·삭제 및 두PC Cloud 실동기화는 미수행이다. 한국등급 등록·Cloud 설정·가격·출시일은 변경하지 않았다.

## 7. 작업 트리
기존 루트의 혼합 작업 트리는 보존했다. 최신 main 기반 tmp/uiux_v2 작업트리에서 수행했다. 에디터가 갱신한194개 import 파일은 HEAD와 줄바꿈 외 내용이 동일함을 검사하고 원복했다. 빌드/캡처는 무시 경로에만 둔다.

## 8. 이전 로컬 후보 단계 기록 — 아래 승인 대기는10절에서 해결됨
이 절은 사용자 승인 전의 이력이다. 현재 상태는10절을 따른다.
- PR104 필수 repository-policy PASS(54초), 로컬 정책 검사 PASS. main 병합·원격 태그 생성은 실행되지 않았다.
- 자동 승인 검토가 `gh pr merge104 --merge` 및 v1.2.9 생성·push를 포함한 명령 전체를 거절했다. 사유: 사용자가 이전에1.2.8을 명시했고1.2.9 병합/태그를 별도 승인하지 않았음. 1.2.9 병합·태그·Steam 반영 또는1.2.8 유지 선택 질문을 보냈으며 당시에는 답변이 없었다. 다른 도구나 명령 분할로 우회하지 않는다.
- 승인과 무관한 로컬 후보 생성·검증은 완료했다. 후보 소스SHA `03cc09d7bf208b36b463152e0f3328f9cecde7ce`(구현 이후 핸드오프만 추가).
- 후보 폴더 `builds/steam/windows/v1.2.9-candidate/`, Windows 제품/파일 버전1.2.9.0. manifest의tag필드는 빌드 도구가 만든 예정값이며 실제 태그 생성의 증거가 아니다.
- `PrepareSteamBuild.ps1 -Version1.2.9 -OutputRoot builds/steam/windows/v1.2.9-candidate` 성공. validate_steam_release SETUP_PASS; 외부 미완료/이전 설정 placeholder15항목은 판매 READY를 의미하지 않는다.
- 동일4.6.3 엔진이 후보PCK를 `--main-pack`으로 읽고 제품 코드를 덮어쓰지 않는 검사 전용PCK(테스트2파일)로 첫 플레이26개 검사를 통과했다. `packed_probe.log`.
- 최종 release EXE는 `--script`를 제공하지 않는다(`exe_help.txt`). 초기 하네스 시도는 실제 검사를 실행하지 않아 제한시간 뒤 해당 프로세스만 종료했다. 이를 EXE 게임플레이 검증 통과로 계산하지 않는다.
- 실제 후보EXE를 한/영 별도APPDATA에서 각각 실행, MovieWriter로 타이틀1920×1080 캡처 확인. 두 실행 exit0·stderr오류 없음. `exe_boot_ko/`, `exe_boot_en/`.
- ZIP `builds/steam/MawangCastle-v1.2.9-Windows-Steam-candidate.zip`: 614,172,411bytes, SHA256 `7b1d8d590d829cfc50e0a71d2b55311a8b261e3533f14e157881c11a77c31a50`. 압축CRC 및 manifest5파일 SHA256 대조 PASS. 검사용PCK는 이ZIP에 들어가지 않는다.
- 후보 검증 보고서 `tmp/steam_review_fix/candidate_verification.json`.
- **당시 Steam default는 기존25423797. 새 패키지 업로드·default교체·재심사 제출은 하지 않았다.** Steamworks Web Uploads 화면을 확인했으며 승인 뒤 태그 소스로 최종 export/업로드해야 한다.
- 사용자 응답이1.2.8 유지면 임의로1.2.9를 배포하지 않는다. 지시된 버전으로 수정본을 구분하는 절차를 정하고 재검증/기록한다.

## 9. 재심사용 영어 설명 — 사용자 승인 후 제출 완료
2026-09-22 채팅 승인을 근거로 Steamworks 재심사 Notes에 아래 내용을 제출했다.

The input issue reported for Build25423797 has been corrected in replacement Build25450324 (v1.2.9), now on the default branch.

A passive tutorial overlay incorrectly blocked map input. Facility card dragging and Gob placement now work with the first-play tutorial enabled; completing Gob placement dismisses the overlay and enables Start Defense. Normal UI controls continue to receive input.

To verify from a fresh save:
1. Choose New Game, enter a name, and continue the opening dialogue to Invasion Intel. Choose Begin Deployment.
2. Open Build. Drag an unlocked, affordable facility card onto an empty building slot and confirm the installation. Resources are charged only when confirmed.
3. Open Garrison. Select Gob and click the rear formation/Recovery Nest, or drag Gob there. Pudding and Pynn have intentionally fixed positions during the DAY1 introduction.
4. The tutorial shading clears. Click Start Defense, continue the pre-battle dialogue, and allow the three-second countdown to finish. Defenders and enemies enter combat.
5. Settings offers Korean and English. The flow was checked in both languages.

Validation: Korean 1920x1080 monster drag, English 1280x720 click placement, facility drag and combat entry with the tutorial enabled; exported PCK first-play regression passed. All six Steam depot files match the final local package by size and SHA1. No third-party login or online server is required.

## 10. 사용자 승인 후 실제 배포·재심사 완료 (2026-09-22 KST)
- 사용자가 원격 채팅 승인 요청에 **승인**이라고 답했다. 범위는 PR104 main 병합, v1.2.9 태그, Steam default 교체 및 수정/조작 안내를 포함한 Valve 재심사 제출이다. 8절의 자동 승인 거절 사유는 이 명시적 응답으로 해결됐다.
- PR104를 merge commit으로 병합했다. 제품 SHA4076e099202f440c85a30699268d1c887c26c903에 불변v1.2.9 태그를 생성·push했다. 이전 태그는 이동하지 않았다.
- [태그 Windows CI](https://github.com/bluehige/mawangseong-demo/actions/runs/35676690799) SUCCESS. 최종 태그 소스로 PrepareSteamBuild.ps1 -Version1.2.9 성공.
- 최종 ZIP: builds/steam/MawangCastle-v1.2.9-Windows-Steam.zip, 614,172,557bytes. SHA256: 64df71332273f30027d324a9400734c636de3c770e05078bf9b01ba2321f1627.
- 후보와 최종 EXE는 동일 바이트이며 한/영1080p 실제 EXE 부팅 확인이 적용된다. 최종 PCK는 내보내기 캐시 등의 차이로 후보와 달라 동일4.6.3 엔진/컴파일PCK의 새 게임 입력26개 검사를 재실행해 통과했다. final_packed.log, final_verification.json. 일부 headless 종료 자원 정리 경고는5절 제한과 같다.
- Steam App5267750 / Depot5267751 / **최종 default Build25450324 / Manifest1103993226303809008**. 서버6파일 크기와 SHA1이 최종 로컬과 일치한다(steam_server_verification.json). 검사용PCK는 배포ZIP에 포함되지 않았다.
- 최초 업로드 Build25450138의 Preview Change 확인창에서 도구 연결이 멈췄다. 새 Chrome 탭에서 동일 검증 ZIP을 업로드하고 Set build live for branch=default로 Commit해 해결했다. 같은 Manifest를 쓰는 최종25450324가 만들어졌고 default 및 Set live history를 확인했다. 25450138은 중간 등록으로 보존한다. 사용자 PC 조작이나 추가 승인은 요구하지 않았다.
- 9절 Notes를 넣어 Mark as ready for review → Update 제출. [Steamworks 랜딩](https://partner.steamgames.com/apps/landing/5267750)의 **Game Build: Your app build is in the review queue / Submitted for review on 21 Sep**를 확인했다. 화면의21Sep는 표시값 그대로 기록했으며 실제 작업일은 한국9월22일이다. 상점은20Sep 접수 대기 그대로다. 제출 완료와 Valve 심사 통과는 구분한다.
- 가격, 한국 KGRB12 등록, 별도 지원 문의, Cloud 및 출시일 변경 없음. GitHub 별도 공개 Release나 Web 재배포도 하지 않았다.
- 배포 후 수정은 docs/handoff/CURRENT.md와 본 문서뿐이다. 제품 코드/데이터/스토리/밸런스/그래픽/음원 추가 변경 없음. 전체 캠페인·별도 검수 에이전트는 NOT_REQUESTED.
- 최종 export가 만든194개 import 변경은 HEAD와 줄바꿈 외 내용이 동일한지 비교 후 정리했다. 기존 루트 혼합 작업은 보존했다. ZIP/로그/캡처는 무시 경로에만 있으며 소스 커밋에 포함하지 않는다.
