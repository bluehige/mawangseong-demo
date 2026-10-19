# V130R DAY 2 전투 버튼 긴급 수정 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-20 KST / 목표 버전: 1.3.0, PE 1.3.0.0.
- WORKSTREAM_ID: V130R-HOTFIX-BATTLE-BUTTON-20261020.
- 브랜치: `codex/v130r-defense-layout`.
- 시작 SHA: `abea779292b0967d1702a780c89a5381ad94369e`.
- 제품·표적 검증 SHA: `6d3f0a133209b8111a687266f3a7b567e64824cf`.
- 마지막 제품 커밋: `Fix blocked battle navigation with explicit preparation prompts`. 이후에는 이 인계와 CURRENT만 변경한다. 최종 문서 커밋은 `git log -1 -- docs/handoff/V130R_HOTFIX_BATTLE_BUTTON_2026-10-20.md`, 패키지 전체 HEAD는 외부 `Evidence/final-head-checks.json`에서 확인한다.
- 로컬 main 부재. origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 정책·CURRENT를 읽었으나 원격 조회/fetch 없이 최신성 미확정. 사용자의 지정 브랜치·SHA·긴급 범위를 적용했다.
- 영어 로컬 커밋만. push·fetch·PR·태그·main·Steam 로그인/업로드/Steamworks 조작 없음.

## 2. 목표와 원인

DAY 2 배치 후 전투 버튼이 다른 화면으로 조용히 이동하는 문제를 실제 EXE에서 재현하고, 차단 규칙을 유지하며 명시적 안내·선택으로 바꾼다. 요청된 직접 회귀와 로컬 Ready 패키지 재생성만 수행한다. 공개 출시·전체 회귀·전체 플레이·별도 전체 검수는 범위 밖이다.

수정 전 Content EXE에서 **새 게임→DAY 1 실제 전투 승리→성장 선택/확인→DAY 2 관리→3명 배치→전투**를 Computer Use로 조작했다. 특화가 0명이어서 `_management_start_state(true)`가 `reason_code=specialization`, `required_action_id=specialization`을 반환하는 경로다. `ApprovedPlacementView.start_battle()`는 상태 문자열만 변경하고 즉시 몬스터 화면을 열었다. 기본 탭이 훈련이어서 사용자에게는 전투 버튼이 몬스터 배치 버튼처럼 보였다.

사용자가 본 `Lv.1→1`, `27/50`은 **특화 툴팁이 아니라 훈련 미리보기**와 일치한다. 실제 EXE에서도 같은 화면을 재현했다. 특화 1명을 선택한 뒤 관리로 돌아와 전투를 누르면 전투 직전 대사를 거쳐 DAY 2 실제 전투가 시작됐다. 지속 차단 루프는 재현되지 않았다. 클릭 영역 겹침·툴팁·튜토리얼 오버레이가 원인이라는 증거도 없었다.

## 3. 구현

- 준비 조건으로 차단되면 지도 중앙에 이유와 `특화 선택하러 가기` / `닫기`를 표시한다. 클릭만으로 다른 화면을 열지 않는다. 반복 클릭은 팝업을 중복 생성하지 않는다.
- 첫 승급·원정·의회 요구도 같은 명시적 결정 방식으로 처리한다. 닫기/ESC는 배치를 유지하며, 화면 이동은 해당 버튼을 눌렀을 때만 한다.
- 특화 이동은 몬스터의 **스킬·특화 탭**을 연다. DAY 2~3에는 `몬스터 1명 특화를 고르면 전투 가능` 안내를 화면 상단에 표시한다.
- 전투 버튼 툴팁과 상태에 차단 이유를 표시하고, 특화 선택/관리 복귀 후 갱신한다. 한국어·영어·간체 중국어를 포함한다.
- DAY 2~3 특화 1명 필수와 DAY 29 빈 웨이브/준비일을 유지했다. 몬스터 능력치·웨이브·스토리 원문·저장 형식 변경 없음.
- 패치노트 KO/EN/ZH_CN에 핫픽스 한 줄씩 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 |
|---|---|
| `scripts/map_builder/ApprovedPlacementView.gd` | 명시적 차단 팝업, 툴팁/상태, 확인 후 화면 이동 |
| `scripts/map_builder/ApprovedMonsterPlacementUI.gd` | 배치·특화 변경 후 준비 이유 갱신 |
| `scripts/ui/MonsterWorkspaceUI.gd` | DAY 2~3 특화 요구 안내 |
| `tools/tests/V130RBattleButtonHotfixTest.gd` | 실제 DAY 1~3·3언어 팝업·특화·저장 회귀 |
| `tools/tests/V130RBattleButtonHotfixTest.tscn` | 검사 진입점 |
| `tools/release/steam_ready/PATCH_NOTES_KO.txt` | 한국어 핫픽스 안내 |
| `tools/release/steam_ready/PATCH_NOTES_EN.txt` | 영어 핫픽스 안내 |
| `tools/release/steam_ready/PATCH_NOTES_ZH_CN.txt` | 중국어 핫픽스 안내 |
| `docs/handoff/V130R_HOTFIX_BATTLE_BUTTON_2026-10-20.md` | 이 인계 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입점 |

## 5. 그래픽·오디오

새 그림 생성·코드 그리기·이미지 필터 처리 없음. 기존 승인된 GPT 생성 `assets/ui/uiux/obsidian_panel.png`, `obsidian_button.png`를 조립하고 NEXON MapleStory Bold/Light를 사용한다. 자산 원본·폰트·오디오 변경 없음. 새 자산이 없으므로 새 SOURCE.md도 만들지 않았다.

## 6. 표적 검증

| 검사 | 결과 | 근거 |
|---|---|---|
| 새 `V130RBattleButtonHotfixTest`, 시드13011 | 84검사 PASS; 3언어 팝업·Close·Go·첫 승급 무음 이동 방지·실제 특화 버튼·차단 해제·DAY 1~3 전투·DAY 2 저장 재시작 | `tmp/hotfix_battle/checks/v130r_b01_V130RBattleButtonHotfixTest_replay_13011/checks.json` |
| B01 unit / 시드13012 replay | 172 / 48검사 PASS | 같은 checks 폴더 |
| 24종 실제 디스크 저장 왕복 / 구v1~v6 사본 | 1,912 / 42검사 PASS | `tmp/hotfix_battle/checks/saves/` |
| 명령 단위 검사 | 236검사 PASS | `tmp/v130r_commands/v130r_commands_hotfix_unit/checks.json` |
| 0121b, 새 팝업 문구 33언어 항목 포함 | 335,896배치·116,760검사, 넘침0·실패0; 3언어×1280/1920×1.0/1.15 | `tmp/hotfix_battle/overflow/after.json` |
| Windows Steam 리소스 import / export | 각각 exit0·stderr0 | Ready `Evidence/import*`, `export*` |
| 실제 수정 전/후 배포 EXE Computer Use | 양쪽 새 게임→DAY 1 승리→DAY 2 실제 전투 시작, exit0; 수정판 팝업·선택·전투 캡처3장 | Ready `Evidence/computer-use-checks.json` |

신규 검사 첫 시도의 자료형 추론 오류를 수정한 뒤 재실행했다. 실행 중인 Godot를 감지한 검사 실행기는 중복 실행을 차단했고, 앞 검사의 종료 뒤에 다시 실행했다. 실제 Godot/게임 동시 실행은 최대1개다. 새 검사에서 특화 선택 후 발생한 `UIKitIcons: unknown icon ...guardian.png` 경고1건은 수정 전 EXE에서도 재현된 기존 항목이다. 이를 신규 오류0/경고0으로 합치지 않는다. 나머지 최종 표적 실행은 오류/경고0이다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6d3f0a133209b8111a687266f3a7b567e64824cf
- Review range: abea779292b0967d1702a780c89a5381ad94369e..6d3f0a133209b8111a687266f3a7b567e64824cf
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 실제 EXE·패키지

수정판도 별도 새 테스트 프로필에서 **새 게임→DAY 1 전투 승리→집중 성장/성장 확인→DAY 2 배치→전투 팝업→명시적 Go→스킬·특화 화면→푸딩 성문 파수 선택(1/1)→관리 복귀→DAY 2 실제 전투 시작**을 Computer Use로 확인했다. 팝업 뒤에는 사용자가 Go를 누르기 전까지 배치 화면을 유지했다. 선택 후 차단 상태는 없어졌으며 반복 차단은 없었다. 실제 Vulkan/Forward+ 배포 EXE는 정상 종료0, 오류0·기존 아이콘 경고1이다.

최종 대표 캡처는 `01-day2-blocked-popup-960.png`, `02-day2-specialization-selected-960.png`, `03-day2-battle-started-960.png`다. DAY 2 웨이브1/6과 실제 아군/적·전투 명령 바를 확인했다. 직접 이미지 열람 총13장 중 최초1장만1282px였고 나머지12장은960px 이하 사본이다. 이후 캡처 원본은 도구 출력에서 억제했다.

최종 조작·캡처와 패키지의 전체 HEAD/ZIP 해시는 Ready `Evidence/computer-use-checks.json`, `final-head-checks.json`, `package-checks.json`에 기록한다. 문서 커밋을 포함해 재export한 뒤 실제 조작한 런타임 파일9개와 바이트 일치를 확인한다. 다른 파일이 생기면 실제 조작 증거를 그대로 적용하지 않는다.

출력은 `C:/Users/blueh/Desktop/진행중인프로젝트/Steam-1.3.0-Ready/`. 이전 ZIP/Evidence는 `_old/`로 이동해 보존한다. Content·manifest·전체 HEAD를 담은 새 SHA ZIP·app_build Desc·3언어 패치노트·Evidence를 갱신하고 SetLive는 빈 값으로 유지한다. Achievements122파일과 START_HERE 원본은 바이트 그대로 보존한다. SteamCMD 실행·인증·업로드·서버·default·공지는 전부 NOT_RUN이다.

직접 이미지 열람은13/15장이다. 첫 Computer Use 타이틀 캡처1장이 도구에서1282px 원본으로 자동 전달되어 크기 제한 이탈1회가 있었다. 이를 숨기지 않으며 이후 원본 도구 출력은 차단하고960px 이하 사본만 열람했다. 캡처/OCR 전처리는 검증 사본에만 적용했고 게임 이미지에 적용하지 않았다.

## 8. 남은 제한·다음 작업

**사용자 확인 대기.** 이번 결과는 긴급 버튼 수정과 로컬 준비 패키지의 표적 판정이다. 기존 난도 곡선·DAY30 배치 비교, 범위 밖 불투명 초상, 과거 진단 사본 전환 충돌, G01/G02 출시 게이트를 해결하거나 수용한 것으로 확대하지 않는다. 기존 아이콘 경고도 별도 항목으로 유지한다. 전체 회귀·전체 수동 캠페인·별도 전체 검수는 NOT_REQUESTED/미실행이다.

## 9. 작업 트리·보존

시작 시 추적 import1,307개와 다수 미추적 기존 자료가 있었다. 원본 바이트·미추적 경로 존재를 확인해 보존하고 이번10파일만 명시적으로 스테이징한다. 스태시·reset·브랜치 전환·main 수정 없음. 빌드는 커밋 archive를 `tmp/hotfix_battle/package_work/source`에 추출한 사본을 사용한다. 자동 검사/EXE 모두 새 APPDATA/LOCALAPPDATA 테스트 프로필만 사용하며 사용자 세이브 원본 접근/수정0이다.

## 10. 종료 기준

관련 검사, 최종 배포 EXE 조작, 캡처3장, SHA ZIP·Desc·manifest·보존 검증, CURRENT 갱신, 영어 로컬 커밋까지 수행하고 종료 시 Godot/게임0개를 확인한다. 공개·원격·Steam 조작은 하지 않는다. 정확한 최종 실행 결과는 외부 Evidence를 함께 인계한다.
