# 1.2.10 첫날 피드백 수정 및 Steam 업데이트 — 2026-10-09

## 1. 메타데이터

- WORKSTREAM_ID: V1210_DAY1_FEEDBACK_HOTFIX_20261009
- 작성일: 2026-10-09 KST
- 목표 버전: 1.2.10 유지; Windows FileVersion/ProductVersion 1.2.10.0 유지
- 작업 브랜치: codex/v1210-day1-feedback
- 기준 브랜치 및 SHA: fetch한 origin/main@0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b
- 직접 시작점: 앞선 Steam 수정본과 핸드오프가 있는 codex/v1210-player-feedback@8dc52c967ba8c6fe828ea7b68ffcd019e7751c06
- 마지막 제품 커밋 SHA: 515ed745d4ce731f7bafb31ee1f9381470794d72
- 원격 푸시 여부: 미실행. main 병합·태그 재지정·새 Release 없음.
- 작업공간: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\tmp\v1210_player_feedback
- 기존 루트 codex/v125-release-candidate의 사용자 변경은 보존했다. 로컬 main은 과거 b06be967이며 원격 main과 다름을 사용자에게 알렸다. main의 AGENTS/CURRENT와 실제 원격·앞선 배포 핸드오프를 확인했다.

## 2. 이번 세션 목표

사용자가 첨부한 첫날 피드백의 이름 다양성, 설명 가독성, 자원 숫자 공백, 지도 태그/체력바 겹침, DAY 2 필수 성장 안내, 전투 속도 고정을 수정한다. 기존 창모드 정상 동작과 앞선 일러스트/대화 클릭 수정을 유지한다.

사용자는 수정·빌드·Steam 업로드·공개 업데이트를 명시적으로 승인했고 재승인은 불필요하다고 말했다. 완료 조건은 직접 검증·최종 Windows/PCK/ZIP 검증·Steam 서버 파일 대조·default 변경 확인이다. 전체 회귀·전체 캠페인·main 통합·새 버전은 요청받지 않았다. 후속으로 사용자가 출시 이후 핫픽스 공지의 적절한 Steam 노출 위치 조사와 실제 공개 게시까지 요청했다.

## 3. 완료한 작업

- 무작위 이름: 한국어·영어·간체 각 5개에서 40개로 확장했다. 등록 제한 12자 이내이며 바로 직전 이름은 다음 무작위 선택에서 제외한다.
- 설명: HUD 버튼의 설명을 560px 폭으로 줄바꿈하고 읽기 쉬운 글꼴·크기를 적용했다. TooltipPanel에 불투명 배경·테두리·여백을 제공한다. 줄바꿈한 높이를 팝업 배치 전에 계산해 창 아래쪽 잘림을 방지했다.
- 자원 표시: 금화/마력/식량/악명 제목과 숫자를 한 줄로 표시하고 높이를 확보했다. 공통 라벨 맞춤은 세 언어 모두 실제 표시 줄 수도 검사해 1px 반올림으로 숫자가 사라지는 경우를 방지한다. 전투 아군 HP도 동일 조건에서 공백이었던 화면이 정상 표시되는 것을 확인했다.
- 지도 태그: 시설/지침/이름 배경을 불투명한 StyleBoxFlat으로 그린다. 전투 지도 태그와 유닛 상태 태그는 주변 실제 체력바 사각형을 피해 배치한다. 체력바를 태그의 기존 위치로 실제 이동시킨 검증을 포함했다.
- DAY 2~3 안내: 특화가 필수인 상태의 기본 행동을 활성화된 ‘몬스터 성장 · 필수 선택’ 버튼으로 바꾸고 성장 화면으로 직접 연결했다. 성장 화면에 필수 안내를 제공하고 특화 선택을 훈련보다 먼저 배치한다. 선택 후 기존 방어 조건이 해제되는 것을 확인했다.
- 속도: 화면 설정의 ‘전투 속도 고정’에서 ‘매 전투 1배’/‘마지막 선택 속도 유지’를 선택한다. 유지 옵션은 1/1.5/2/3배의 마지막 선택을 settings.cfg에 저장하며 다음 전투·재시작·설정 취소/기본값 처리에 포함한다. 튜토리얼은 1배를 유지하고 저장한 속도를 지우지 않는다.
- 코드 외 스토리·밸런스·저장 게임 구조·그래픽 원본 변경 없음. 신규 설정 키는 누락 시 기존 동작(false/1배)으로 읽는다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| scripts/core/UISettings.gd | 속도 옵션·선택 저장 및 복원 | 완료 |
| scripts/game/CombatSceneController.gd | 전투 시작 속도 및 선택 저장 | 완료 |
| scripts/game/GameRoot.gd | 이름 후보·설정 UI·필수 안내·지도 장애물 | 완료 |
| scripts/ui/HUDController.gd | 자원 표시·라벨 맞춤·툴팁 테마 | 완료 |
| scripts/ui/ReadableTooltipButton.gd 및 .uid | 설명 줄바꿈과 팝업 높이 | 완료 |
| scripts/ui/ManagementWorkspaceUI.gd | 필수 성장 직접 연결 | 완료 |
| scripts/ui/MonsterWorkspaceUI.gd | 성장 안내 및 특화 우선 배치 | 완료 |
| scripts/ui/UIUXTheme.gd | 지도 태그 배경 | 완료 |
| scripts/units/Unit.gd | 실제 체력바 좌표·상태 태그 회피 | 완료 |
| data/localization/v122_stage10_ui.json | 한·영·간체 이름과 설정/안내 문구 | 완료 |
| tools/tests/DayOneFeedbackHotfixTest.gd/.uid/.tscn | 관련 저장·실제 클릭·렌더 검증 | 완료 |
| tools/tests/PlayerFeedbackHotfixTest.gd.uid | 이전 테스트의 재생성 UID 기록 | 완료 |
| docs/handoff/CURRENT.md 및 이 문서 | 종료 및 배포·공지 상태 | 완료 |

## 5. 그래픽 및 오디오 자산

새 이미지 생성·음원 생성·픽셀 수정 없음. UI 배경과 배치 코드만 변경했다. 한·영·간체 자원, 설정, 성장, 실제 호버 설명, 겹친 체력바 회피를 1280×720에서 확인했다. 캡처는 ignored tmp/day1_feedback 및 packaged 하위에 보관한다.

## 6. 테스트 및 검수

| 검수 | 결과 | 근거 |
|---|---|---|
| 수정 직접 headless 테스트 | PASS, 309 checks | tmp/day1_feedback/headless.log |
| 최종 수정 GUI 직접 테스트 | PASS, 323 checks / 0 failures | tmp/day1_feedback/gui.log 및 PNG |
| V122ManagementInteractionTest | PASS, 22 assertions | 동명 로그 |
| V122CombatUISimplificationTest | PASS, 93 assertions | 동명 로그 |
| V122Stage10LocalizationTest | PASS, 45 assertions | 동명 로그 |
| ChineseLocalizationTest | PASS, 1855 checks / 1806 glyphs | 동명 로그 |
| 이전 PlayerFeedbackHotfixTest | PASS, 136 checks | 동명 로그 |
| 최종 Steam Windows export/manifest validator | PASS | tmp/day1_feedback/steam-export.log |
| 최종 PCK 독립 검사 | PASS, 3387 entries, project.binary 1539 bytes, 금지 경로 0, 카탈로그 5종 소스 일치·글꼴·컴파일 스크립트 | tmp/day1_feedback/pack-audit.json |
| 실제 최종 PCK GUI | PASS, 323 checks / 0 failures | tmp/day1_feedback/packed-runtime.log 및 packaged PNG |
| 최종 EXE 부팅 | exit 0, --headless --quit-after 60 | tmp/day1_feedback/exe-boot.log |
| ZIP 6파일 크기·SHA256 대조 | PASS | tmp/day1_feedback/zip-verification.json |
| Steam 새 Manifest 6파일 크기·SHA1 대조 | PASS, 6/6 | tmp/day1_feedback/steam-server-verification.json 및 steam-server-manifest.json |
| 전체 회귀·전체 캠페인·별도 검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

읽기 전용 Ampere는 HUD 자원 표시 원인 후보와 관련 테스트를 조사했다. 구현·별도 전체 QA·브라우저 변경은 맡기지 않았다. 원인이 확정되지 않은 데이터 소실을 주장하지 않는다. 소스/배포본 화면에서 숫자 공백과 설명 창 아래 잘림을 확인한 뒤 표시 코드를 보완했다.

기존 ManagementInteractionTest의 종료 ObjectDB/resource 경고가 있다. 합성 상태를 강제로 만든 PCK 검사에서 캠페인 저장 요약 불일치 경고가 발생했다. 이는 실제 저장 검증 근거로 쓰지 않으며 개인 저장을 건드리지 않았다. 실행 파일 단독 부팅에는 스크립트/로드 오류가 없다. 초기 ChineseLocalizationTest는 요구하는 격리 폴더 이름이 아니어서 저장 전 차단됐고, 지정한 격리 경로로 실행한 최종 결과는 PASS다. 두 초기 직접 테스트의 테스트 코드 타입/상수 오류는 수정했으며 최종 로그에는 없다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 515ed745d4ce731f7bafb31ee1f9381470794d72
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..515ed745d4ce731f7bafb31ee1f9381470794d72
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

검수 SHA 이후에는 docs/handoff 문서만 수정한다. 정책 validator의 오래된 최초 출시 setup 항목 15개는 별도 PENDING으로 표시되며 이번 이미 출시된 앱의 수정 산출물 검사 결과와 구분한다.

## 7. 산출물 및 외부 상태

- 업로드 ZIP: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\builds\steam\windows\MawangCastle-v1.2.10-SteamContent-hotfix-20261009.zip
- ZIP bytes: 615477902
- ZIP SHA256: 4803a0573355457e763c53bc5c8b62b15b7eaa40749dd6a96939bd19f568f551
- Windows 산출물: builds/steam/windows/v1.2.10-hotfix-20261009-final
- manifest: version=1.2.10, build_kind=same_version_hotfix, tag=null, source_commit=515ed745d4ce731f7bafb31ee1f9381470794d72
- Steam App5267750, Depot5267751; 시작 시 default25803750/Manifest2614967785369199063를 확인했다. 이 빌드는 롤백 기준으로 보존한다.
- 현재 Steam 상태: **Build25808943 / Manifest7359545829337152740 등록 완료, 서버6파일 크기·SHA1 일치 PASS.** 최종 canonical Builds의 공개 default는 **25808943**이며 Set live Build25808943 for branch public 이력(서버8Oct9:42am)을 확인했다. 변경 미리보기는25803750→25808943, 업데이트 다운로드3.5MB다.
- Chrome 자동 파일 선택은 페이지에서 실제 선택되지 않아 사용자에게 파일 선택 조작만 요청했다. 사용자가 선택한 파일명을 화면으로 확인한 뒤 Upload를 실행했다. 배포 재승인은 요청하지 않았다.
- 공개 적용의 Chrome JS 확인창은 대상 Build25808943/default를 표시했다. 자동 accept 및 정확한 OK 클릭은 No dialog is showing으로 끝났고 default는 변경되지 않았다. Enter 재입력은 자동 승인 검토가 중복 위험으로 거절했다. 이후 읽기 전용으로 확인창의 대상을 확인하고 OK를 시도했으나 같은 도구 오류였다. 사용자가 현재 미리보기의 Set Build Live Now→OK를 직접 처리하도록 요청했다. 이는 배포 재승인 요청이 아니다. 휴대폰 인증 안내가 실제로 뜨면 Steam 확인에서 처리한다. 사용자 답변 뒤 canonical Builds의 default를 확인한다. 캡처 steam-live-button-needed.jpg, 유지 탭874258631.
- 사용자가 ‘버튼과 확인창 처리 완료’, ‘내가했다’라고 답했다. Builds?submittedbuild=25808943로 이동한 화면을 확인했다. canonical Builds를 새로 열고 35초 뒤 다시 읽었을 때 default25803750이어서 당시에는 반영 확인을 계속했다. 이후 공개 default25808943과 Set live 이력이 표시되어 적용 완료를 확인했다. 사용자에게 동일 웹 조작이나 배포 재승인을 다시 요구하지 않았다. 증거: tmp/day1_feedback/steam-default-live.jpg. 추가 휴대폰 작업은 요청하지 않았다.

## 8. 고객 공지 및 다음 작업

- 실제 출시일은 Steam 공식 상점 및 Steamworks의 Released/Release Date에서 **2026-10-08**로 확인했다. 9월30일 승인 기록과 구분하며 출시 전 수정과 간체 지원을 출시 후 추가로 표현하지 않는다.
- 읽기 전용 Ampere가 10/08 제품feb230dd와 10/09 제품515ed745의 핸드오프/배포 상태를 대조했다. 공지에는 출시 이후 두 핫픽스의 고객 관련 변경 9개만 포함했다. 밸런스 변경·전체 검수 완료·향후 일정·저장 완전 호환 주장은 없다.
- Steam 공식 Events/Small Update 문서에서 고객이 업데이트 후 확인할 경로를 조사했다. **소규모 업데이트 및 패치 노트** 유형을 선택하고 공개 **Build25808943**에 연결했다. 이 연결로 다운로드 화면 PATCH NOTES 경로를 제공한다. 라이브러리 게임 상세 페이지 노출은 켜기이며 게임 뉴스·커뮤니티·팔로워 활동 피드에도 공개된다. 대규모 이벤트용 집중 조명과 라이브러리 홈 What's New는 사용하지 않았다. 상점에는 최신 패치 노트 링크 형태로 제공되며 일반 공지 카드 노출과 구분한다.
- 공식 근거: https://partner.steamgames.com/doc/marketing/event_tools/type_patchnotes 및 https://partner.steamgames.com/doc/marketing/event_tools . Steam 라이브러리 노출은 검토로 1시간 이상 지연될 수 있다. 현재 고객용 공지 직접 페이지 공개와 본문을 확인했으며 모든 고객의 라이브러리에서 이미 보였다고 주장하지 않는다.
- 공개 공지: **1.2.10 출시 후 핫픽스 — 버그 수정 및 편의성 개선**
- URL: https://store.steampowered.com/news/app/5267750/view/678511862081390358
- Event ID: 678511862081390358
- 공개 게시 일시: **2026-10-09 01:53 KST** (Steam 표시)
- 언어: 한국어·영어·중국어 간체. 제목·요약·본문을 각 언어로 저장하고 번역 본문을 직접 대조했다. 한국어 미리보기의 제목·목록·문단 서식과 공개 고객 페이지 본문을 확인했다.
- 별도 공지 이미지 없이 기존 게임 캡슐을 사용했다. 이미지 없음 경고는 필수 실패가 아니며 사용자 승인 범위의 게시를 계속했다. 게시 조작 직후 DOM 분리 응답이 있었지만 재게시하지 않고 상태를 읽어 **상태: 공개**와 라이브 보기 URL을 확인했다.
- 증거: tmp/day1_feedback/steam-announcement-public-status.jpg, steam-announcement-live.jpg, steam-announcement-content.json. 고객용 공지 탭을 deliverable로 보존했다.
- 다음 필수 작업 없음. Steam 클라이언트 실설치·전체 회귀는 이번에 수행하지 않았다. main 통합/원격 push/새 태그는 별도 요청 범위다.

## 9. 작업 트리 상태

제품 커밋 후 codex/v1210-day1-feedback의 작업 트리는 clean이었다. 현재 종료 문서 두 파일만 추가/수정한다. 기존 루트 사용자 변경은 보존했다. 빌드·로그·캡처·ZIP은 ignored 경로에만 있으며 소스 커밋에 포함하지 않는다.

## 10. 종료 체크리스트

- [x] 요청과 구현 대조 및 관련 테스트 통과
- [x] 최종 소스·배포본 실제 화면 확인
- [x] 최종 SHA·검수 범위·그래픽 변경 여부 기록
- [x] 전체 회귀/별도 QA 요청 여부 정확히 구분
- [x] 의도한 제품 파일만 커밋
- [x] Steam 서버 파일 대조 및 default 적용 완료
- [x] 출시 후 두 핫픽스 고객 공지 3언어 공개 게시·새 빌드 연결
- [x] CURRENT 최종 갱신 및 종료 문서 커밋 (이 문서를 포함하는 docs 전용 종료 커밋)
- [x] 원격 push·PR·태그 미실행 상태 기록
