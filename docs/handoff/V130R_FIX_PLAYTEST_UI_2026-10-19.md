# V130R 사용자 실플레이 UI·이미지·전체화면 수정

**최신 결과: [9절 Computer Use 재확인](#9-computer-use-재확인-2026-10-19) 참조.** 사용자가 Computer Use를 다시 허용하여 요청한 네 항목을 실제 EXE에서 확인했고, 초상 크기·툴팁 여백을 추가 수정했다. 이번 재확인 범위는 TARGETED_PASS · 사용자 확인 대기다. 아래 1~8절은 0125 중단 당시 기록이며, 다른 불투명 초상 전체 교체가 완료됐다는 뜻은 아니다.

## 1. 메타데이터

- 작성일: 2026-10-19 KST
- 목표 버전: 1.3.0
- 작업 브랜치: `codex/v130r-defense-layout`
- 기준 SHA: `39f1da3130080f2ae40e2fa132c645f6bd203d86`
- 구현·표적 검증 SHA: `195d12e4d417d2f7fcdafdd6a71041f9e9312038`
- 마지막 제품 커밋: `195d12e4` — `Fix dialogue portrait sizing, toolbar states, and Goldin alpha`
- 원격 푸시/PR/태그/main/Steam 작업: 전부 없음. 로컬 영어 커밋만.
- 로컬 main 참조 부재. origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 정책·CURRENT와 브랜치 CURRENT를 읽었으나 원격 최신성은 미확정. fetch/원격 조회 없이 사용자 지정 브랜치에서 작업했다.

**결과: PARTIAL · 사용자 확인 대기.** 사용자 Escape로 Computer Use가 중단되어 더 이상 화면 입력을 하지 않았다. 전체화면 수정·실제 EXE 왕복 검증, 나머지 배경 이미지 교체는 끝내지 못했다. 아래 표적 검사의 통과를 요청 전체 완료나 출시 PASS로 해석하지 않는다.

## 2. 목표와 현재 결과

| 요청 | 수행 내용 | 남은 필수 확인 |
|---|---|---|
| 몬스터 대화 초상 통일 | 24종+골딘 25명에 바티의 실제 알파 높이·하단 기준선 적용. 720p/1080p 기하 검사·전후 렌더 | 실제 EXE에서 사용자 체감 확인; 감정/승급별 별도 육안 전수는 미실행 |
| 자동·툴팁 | 기존 GPT 체크 아이콘 재사용, 자동 켜짐/꺼짐 문구·툴팁 상태 표시. 잠긴 넘기기 설명 유지. 대화 버튼 공통 툴팁 글꼴·GPT 프레임 | 실제 EXE 마우스 오버 위치·로그/메뉴 조작 확인 미완료 |
| 골딘·배경 이미지 | 골딘 RGB 초상 2종을 각각 네이티브 투명 재생성·연결. 타 자산 알파 조사·후보 목록 저장 | 불투명 개별 초상 21개와 합본 5개 미교체. 추가 생성 후보 6개 미채택 |
| 전체화면·가독성 | 기준 EXE export·Vulkan 부팅, 기존 충돌 기록과 설정 경로 조사 | 원인 확정/제품 수정 없음. 설정 토글·Alt+Enter·최대화 실제 재현, 3해상도·5왕복 전부 미완료 |

## 3. 완료한 구현

- `StoryDialoguePresenter._standing` 공통 경로에서 현재 DataRegistry의 몬스터 분류/인스턴스를 판별한다. 골딘은 배치 유닛이 아닌 해골 직원이므로 별도 포함했다. 마왕·바티·인간 NPC의 기존 배치는 유지한다.
- 몬스터 텍스처의 실제 사용 영역을 AtlasTexture로 선택하고 바티 dry 초상의 보이는 높이와 하단 위치로 맞춘다. 원본 픽셀·알파·그림을 편집하지 않는 배치 조립이다. 창 크기가 바뀌면 다시 계산하며 컷신/본편/전투 대화가 같은 함수를 쓴다.
- 자동 버튼은 원래 아이콘 위에 기존 GPT `icon_check`를 변형 없이 표시한다. 캡션/툴팁에 현재 켜짐·꺼짐, 비활성 시 사용 불가 이유를 표시한다. 잠긴 넘기기의 툴팁을 지우던 처리를 제거했다. 로그/메뉴는 일시 동작 버튼이며 기존 자동 재생 일시정지 설명을 유지했다.
- `DialogueToolbarButton`은 기존 UIStandard의 NEXON Maplestory 글꼴과 `obsidian_panel.png`를 사용한다. 새 코드 그림·색 제거·엣지 필터를 만들지 않았다. 툴팁 수동 렌더는 두 해상도에서 폭480·높이260 이내였지만 네이티브 팝업 위치의 실제 마우스 확인은 미완료다.
- 골딘 기본형(해골/단안경/깃펜/주판), accounting형(뿔 달린 청년 악마/안경/장부)의 기존 서로 다른 디자인을 각각 유지했다. 원래 두 파일은 바꾸지 않고 `_alpha_v130r.png` 새 경로로 연결했다. panic/relieved 대체 경로도 기본형을 사용한다. 전용 전투 몸체·별도 도감·전용 아이콘 연결은 없었다.
- 스토리 문구·밸런스·DAY29 무전투·웨이브·저장 형식·프로젝트 stretch/렌더러/기본 창 크기는 변경하지 않았다.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/story/StoryDialoguePresenter.gd` | 몬스터 배치·자동 체크·상태 설명 |
| `scripts/story/DialogueToolbarButton.gd`, `.uid` | 대화 툴바 공통 읽기 쉬운 툴팁 |
| `data/characters.json` | 골딘 두 초상 경로만 변경 |
| `assets/sprites/portraits/onboarding/*goldin*alpha_v130r.png`, 대응 `.import` | 네이티브 투명 런타임 2종(대소문자 구분 파일명은 커밋 목록 참조) |
| `assets/source/imagegen/v130r_playtest_transparency_20261019/` | 생성 원본2·수정 전 원본2·SOURCE.md/실제 프롬프트 |
| `tools/tests/PlaytestUIFixTest.gd`, `.uid`, `.tscn` | 25명·두 해상도·툴팁/상태·사람 제외 검사 |
| `tools/tests/PlaytestExeProbe.gd`, `.uid` | 임시 export 프로젝트용 화면/프로필 관측 보조 |
| `tools/run_playtest_ui.py` | 단일 엔진·프로필 격리·기존 import 보존·짧은 로그 실행기 |
| `docs/handoff/V130R_PLAYTEST_ALPHA_2026-10-19.csv` | 배경 후보29개와 두 골딘 교체 상태 |
| 이 문서, `CURRENT.md` | 부분 완료·재개 순서 |

## 5. 이미지 출처·알파 조사

- Generation model: GPT internal image generation
- Generated date: 2026-10-19
- Target version: 1.3.0
- [정확한 원본·런타임 경로와 실제 프롬프트](../../assets/source/imagegen/v130r_playtest_transparency_20261019/SOURCE.md).
- 두 호출 모두 `transparent_background=true`. 두 출력은 1254×1254 RGBA, 알파0..255. 완전 투명 픽셀 기본형630,190개 / accounting형557,757개. 생성 PNG를 그대로 복사했고 리샘플링·필터·색 빼기·로컬 배경 제거는 하지 않았다.
- 과거 골딘 기본형 출처는 `docs/WORK_LOG_2026-07-07_ONBOARDING_PORTRAITS.md` 및 onboarding 합본, accounting형은 `docs/HANDOFF_DAY05_07_CAMPAIGN_AND_ASSETS_2026-07-09.md`. 과거 개별 SOURCE.md·완전 실행 프롬프트는 찾지 못했음을 새 출처 문서에 명시했다.
- 독립 읽기 전용 조사 `01a15384-9c19-7302-95b8-3e556e541ca4`: 캐릭터45·몬스터24·적33의 조건부 런타임 참조 및 `.tres` 원본을 반영한 고유 PNG251장. 수정 전 알파 없음27 / 완전 불투명28 / 모서리 α255 후보29. 전투 시트88장의 4×4 셀 모서리 불투명 후보0. 이 전체251장 원시 JSON/재현 스크립트는 저장되지 않았으며, 아래 후보29개에 대해서는 본 세션이 다시 PNG를 읽어 CSV를 저장했다.
- [후보29개 CSV](V130R_PLAYTEST_ALPHA_2026-10-19.csv): 골딘2개 교체, 개별 불투명 초상21개 미교체, 의도적 배경의 진화/왕관 합본5개 미교체, Evelyn 모서리 접촉1개는 실제 배경 결함 미확정이다. 장면 배경 그림은 투명 캐릭터 검사에서 제외했다.
- 합본5개는 1536×1024, 3열×2행/셀512×512이며 당시 의도적 배경 근거는 `assets/source/imagegen/uiux_evolution_portraits_20260913/SOURCE.md`, `uiux_evolution_emotions_20260913/SOURCE.md`, `uiux_crown_emotions_20260913/SOURCE.md`. 지금 사용자 요구에 맞춘 투명 교체는 아직 하지 않았다.
- update3_atlas의 불투명6개는 실제 전투 시트가 아니라 초상 `.tres`의 원본이다. 현재 region은 `Rect2(0,0,313.5,313.5)`이므로 새 개별 초상으로 바꿀 때 영역도 맞춰야 한다.
- 추가 NPC 6종의 네이티브 투명 후보는 생성했으나 Computer Use 중단 뒤 채택하지 않았다. [프롬프트·생성 경로·알파 결과](../../tmp/playtest_ui_20261019/other_candidate_jobs.json), [로컬 후보 폴더](../../tmp/playtest_ui_20261019/unadopted_candidates/). 이 후보들은 제품에 연결하거나 소스 커밋하지 않았다.

## 6. 실행한 검사와 캡처

| 검사 | 결과 |
|---|---|
| `python -X utf8 tools/run_playtest_ui.py before` | GUI 기준 렌더, 25명·두 해상도, exit0·진단0 |
| `python -X utf8 tools/run_playtest_ui.py after` | GUI 123검사·실패0. 골딘 연결 후 재실행도 통과 |
| `python -X utf8 tools/run_playtest_ui.py headless` | 최종 123검사·실패0, 진단0 |
| `python -X utf8 tools/run_playtest_ui.py import` | 신규 PNG/스크립트 import exit0·진단0 |
| `python -X utf8 tools/run_dialogue_overflow.py after` | 0121b 기존 검사 228조합/335,416배치, 넘침0·실패0, 원문 보존116,568검사 |
| `python -X utf8 tools/run_dialogue_overflow.py behavior` | 페이지/입력/자동 41검사·실패0 |
| `python -X utf8 tools/run_v130r_release_blockers.py layout` | 기존 설정/알림 108검사·실패0·오류/경고0 |
| `python -m py_compile tools/run_playtest_ui.py`, `git diff --check` | 통과 |
| 기준 Windows export | exit0·진단0. Vulkan/Forward+ 실제 EXE 부팅 로그 확인 |
| 실제 EXE Computer Use | **미완료**. 첫 캡처가 다른 앱을 보여 무효 처리. 재활성화 시 사용자가 Escape로 중단하여 이후 호출0 |
| 수정 후 EXE export/전체화면·최대화/해상도·5왕복 | **미실행** |
| 전체 회귀·전체 플레이·전체 검수 에이전트 | NOT_REQUESTED / 미실행 |

캡처·로그·프로필은 [로컬 증거 폴더](../../tmp/playtest_ui_20261019/)에 있다. 캡처는 소스 커밋하지 않았다.

- [몬스터3종+골딘, 바티 비교 전후 요약](../../tmp/playtest_ui_20261019/before_after_comparison_960.png).
- [720p 전](../../tmp/playtest_ui_20261019/before_1280_comparison.png) / [후](../../tmp/playtest_ui_20261019/after_1280_comparison.png), [1080p 전](../../tmp/playtest_ui_20261019/before_1920_comparison.png) / [후](../../tmp/playtest_ui_20261019/after_1920_comparison.png). 후 캡처는 두 번째 GUI 실행의 골딘 교체 후 개별 PNG도 보존되어 있다. 비교 합본 일부는 첫 GUI 실행 시점이므로 골딘 원본 배경 확인에는 개별 최종 PNG를 사용한다.
- [자동 꺼짐/켜짐·툴팁 수동 배치 전후](../../tmp/playtest_ui_20261019/toolbar_before_after_960.png): 실제 마우스 오버 캡처가 아닌 GUI 검사 장면이다.
- [골딘 생성 결과 검토 사본](../../tmp/playtest_ui_20261019/goldin_after_review_960.png).
- 직접 이미지 열람9장, 모두 긴 변960px 이하 사본/합본. 원본 캡처와 생성 이미지를 그대로 직접 열지 않았다. 무효 CU 캡처도960px 사본으로만 봤다.
- `APPDATA`/`LOCALAPPDATA`를 tmp에 격리, `MAWANG_DISABLE_STEAM=1`. 개인 세이브를 수정하지 않았으며 테스트에서 저장 쓰기를 비활성화했다. 프로세스는 직렬1개, 최종0개.

### 전체화면 조사 근거와 미확정 원인

읽기 전용 조사 `01a15384-9e74-7cd3-aec5-ab2d041146e3`가 Windows Application 접근 위반2건(`c0000005`, 2026-10-19 18:24:56·18:29:10 KST)을 확인했다. EXE 내부 오프셋은 `0x2d985a7`, `0x2ddee99`. 기존 `C:/Users/blueh/AppData/Local/CrashDumps/MawangCastle.exe.35900.dmp` 존재, 덤프 스택 분석은 미실행이다. 확인 범위에서 cdb/WinDbg/dumpchk 및 일치하는 공식 Godot 심볼을 찾지 못했다.

소스 GUI 검사기는 Compatibility를 강제하지만 실제 EXE는 Vulkan1.4.341/Forward+/RTX3060Ti였다. project.godot에는 모바일 Compatibility 설정만 있다. 렌더러 전환 경로, 설정 PopupMenu 선택 신호 안에서 네이티브 모드 변경 후 즉시 UI 재구성하는 경로, 최대화 복원 상태가 원인 후보이며 어느 것도 확정하지 않았다. 제품 렌더러/전체화면 코드를 추측으로 바꾸지 않았다. 기준 EXE 실행은 중단된 세션에서 비정상 종료코드4294967295로 끝났으며 이를 정상 종료나 전체화면 재현 성공으로 세지 않는다.

### 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 195d12e4d417d2f7fcdafdd6a71041f9e9312038
- Review range: 39f1da3130080f2ae40e2fa132c645f6bd203d86..195d12e4d417d2f7fcdafdd6a71041f9e9312038
- Remaining P1/P2: N/A
- Final review result: PARTIAL

미완료 필수 항목이 있어 전체 TARGETED_PASS로 기록하지 않는다. 제품 커밋 뒤에는 docs/handoff 문서만 갱신한다.

## 7. 다음 작업

1. **사용자 확인 대기.** Computer Use 재개 허용 뒤 격리 EXE를 실제로 활성화하고 설정 토글·Alt+Enter·최대화를 재현한다. 기존 사용자 게임이 실행 중이면 세이브 보존과 동시1개 제한을 먼저 해결한다.
2. 충돌 원인을 로그/덤프와 실제 재현으로 좁힌 뒤 `UISettings.gd`/`GameRoot.gd`/필요한 렌더러 설정만 수정한다. 1280×720·1920×1080·2560×1440 및 전체화면↔창모드5회, 크래시0 확인. 현재 stretch는 canvas_items/keep/1920×1080이며 기본1280×720 창의 실제 가독성은 아직 검증하지 않았다.
3. 후보6개를 먼저 검토·채택하고 나머지 불투명 초상21개/합본5개를 사용자 지시대로 GPT 네이티브 투명 출력으로 처리한다. Evelyn은 먼저 실제 배경인지 확인한다. 직접 열람 한도와 이미지 출처·알파 검사를 유지한다.
4. 수정 후 EXE를 새로 export하여 초상/자동 상태/네이티브 툴팁 실제 조작 확인. 남은 변경에 맞춰 0121b/레이아웃 검사를 다시 실행한 뒤 새 로컬 영어 커밋·인계를 남긴다. push/태그/main/Steam/개인 저장 변경 금지 유지.

## 8. 작업 트리·종료

- 작업 시작 시 기존 추적 변경은 .import 1,307개였고 코드/데이터 추적 변경은 없었다. 종료 대조에서도 기존 1,307개 상태 항목을 모두 보존했고 예상 밖 추적 변경은0개였다. 기존 미추적 자료를 보존했으며 `tmp/playtest_ui_20261019/initial_status.txt`에 시작 목록이 있다.
- 이번 19개 제품/도구/출처 파일만 명시 스테이징하여 로컬 커밋했다. 기존 import 내용은 실행기에서 매번 사본을 보존·복구했고 기존 혼합 변경은 스테이징하지 않았다.
- 테스트 EXE/PCK/캡처/후보/로그는 tmp에만 남겼다. 최종 Godot/검증 게임 프로세스0.
- 전체화면·추가 이미지·실제 EXE 확인이 남아 요청 전체 완료는 아니다. **사용자 확인 대기.**

## 9. Computer Use 재확인 (2026-10-19)

### 범위·기준

- 사용자 재지시: 10/19 18:48 Computer Use 중단으로 확인하지 못한 실제 EXE 조작 재수행. 초상 크기, 자동 버튼/툴팁, 골딘 투명 배경, 화면 모드/창 크기 확인의 네 항목이 이번 완료 범위다.
- 목표 버전/브랜치: `1.3.0` / `codex/v130r-defense-layout`.
- 세션 시작 SHA: `d70e8a14575cd42ca3aafe5f303f21912917a4ea`.
- 제품 구현·30전환 실제 조작 SHA: `28894c28d4846c14d97ec53ab7bdc72c6d496e68`. 최종 검증/HEAD export SHA: `f5644419983b237805539f0acbb77cd5650779b5`. 마지막 커밋은 수정 전 비교 검사 호환성만 보존하며 게임 코드/내보낸 자원은 변경하지 않는다. 이후에는 인계 문서만 정리했다.
- 로컬 영어 커밋: `c6401867` 검사용 EXE 비교/관측 보강, `f81169af` 보이는 초상 높이 수정, `28894c28` 툴팁 장식 여백 수정, `f5644419` 구버전 비교 검사 호환 보존. 제품 프로젝트에 검사용 autoload를 추가하지 않았다. export용 tmp 프로젝트에만 보조 도구를 연결했다.
- 로컬 `main` 참조 부재. `origin/main` 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 정책/CURRENT를 읽었으며 원격 최신성은 미확정이다. fetch·원격 조회·push·PR·태그·main·Steam 조작 없음.

### 중단 항목의 실제 조작 결과

| 항목 | 최종 EXE에서 한 조작·결과 | 증거 |
|---|---|---|
| 몬스터 3종+바티 | Computer Use F7로 실제 Main의 대화 화면을 열고 푸딩·곱·핀 각각 바티와 같은 화면 비교. 세 종 모두 보이는 높이/하단 기준선 일치. 골딘도 같은 방식으로 확인 | [비교 캡처 960px](../../tmp/playtest_ui_20261019/cu_verified_portraits_960.png), [실제 표시 인물/좌표](../../tmp/playtest_ui_20261019/cu_verified_portraits.json) |
| 자동 툴팁·토글 | 마우스를 버튼 위로 이동(가운데 버튼은 자동 상태를 바꾸지 않음)하여 네이티브 툴팁 표시. 좌측 아래로 펼쳐져 창 안에 들어오며 문구가 금색 프레임 안에 배치됨. 왼쪽 클릭으로 꺼짐→켜짐→꺼짐, 체크 표시와 pressed/visible 상태도 함께 확인 | [오버·켜짐·꺼짐 캡처](../../tmp/playtest_ui_20261019/cu_verified_auto_960.png), [상태 관측](../../tmp/playtest_ui_20261019/cu_verified_auto.json) |
| 골딘 투명 이미지 | 골딘 등장 대화에서 해골·의상 바깥으로 왕좌 배경이 이어지고 직사각형 불투명 배경 없음 | 비교 캡처 우하단 골딘. 기존 네이티브 투명 PNG를 그대로 사용 |
| 설정 전환 | 실제 설정의 창 모드 목록을 마우스로 선택하여 창모드↔전체화면 **5왕복**, 10전환. 네이티브 mode 0↔3 및 설정값 일치 | [전환 30건 원시 기록](../../tmp/playtest_ui_20261019/cu_verified_actions.json) |
| Alt+Enter | 실제 키 입력으로 **5왕복**, 10전환. mode 0↔3 일치 | 같은 전환 기록, `cu_verified_alt_*` 원본 캡처 |
| 창 최대화 | 제목 표시줄 더블 클릭으로 Windows 최대화↔복원 **5왕복**, 10전환. mode 0↔2, 1280×720↔1920×1009. Windows 최대화와 전체화면 mode 3은 구분하여 확인 | 같은 전환 기록, `cu_verified_maximize_*` / `cu_verified_restore_*` 원본 캡처 |
| 창모드 가독성 | 실제 EXE를 1280×720·1920×1080·2560×1440으로 변경하고 1280으로 복귀. 같은 UI/문구가 창 크기에 따라 약 0.667→1→1.333배로 확대됨. 설정 필드/하단 버튼 배치 유지 | [모드·창 크기·실제 픽셀 글자 비교](../../tmp/playtest_ui_20261019/cu_verified_display_960.png), [창 크기 관측](../../tmp/playtest_ui_20261019/cu_verified_snapshots.json) |

최종 EXE에서 **15왕복/30전환, 기대 모드 불일치0, 크래시0**. 기존 18:24/18:29 접근 위반은 이번 재확인에서 재현되지 않았다. 전체화면 제품 코드·렌더러는 수정하지 않았으며 원인이 해결됐다고 단정하지 않는다.

현재 데스크톱은 1920×1080이므로 큰 창 일부는 모니터 밖으로 나간다. 1920/2560 창의 전체 UI는 Computer Use F8 입력으로 실제 실행 중 EXE의 전체 viewport(그리기 영역)를 PNG로 캡처하여 확인했다. 해당 크기의 별도 물리 모니터 검수로 해석하지 않는다. 세 PNG의 실제 크기는 각각 1280×720·1920×1080·2560×1440이다.

### 재확인 중 발견·수정

1. **푸딩의 몸체가 바티보다 작게 보임:** 원본 알파1~8의 거의 투명한 픽셀이 넓게 흩어져 기존 `get_used_rect()`가 빈 여백까지 크기로 계산했다. 기존 기하 검사가 통과해도 실제 화면에서는 차이가 남았다. `StoryDialoguePresenter.standing_visible_bounds()`가 보이는 경계를 측정·캐시하고 그 영역을 AtlasTexture로 선택하도록 수정했다. 크기 계산에서만 알파8 이하를 제외하며 원본 픽셀·알파·파일은 수정하지 않았다. 바티의 같은 기준을 적용한다. 기존 초상 로더가 반환하는 푸딩 텍스처의 독립 측정값 `Rect2i(50,240,1163,783)` 회귀 검사를 추가했다.
2. **실제 툴팁 문구가 장식에 너무 붙음:** `DialogueToolbarButton.gd`의 안쪽 여백24→40, 문구 폭420→392. 기존 GPT 프레임/폰트를 그대로 쓰고 총 폭480·높이260 이내를 유지했다. 실제 마우스 오버에서 프레임 안쪽 배치를 재확인했다.
3. **EXE 검사용 보조 도구:** F7은 바티+대상 한 명씩 네 쌍을 순환한다. 원래 다섯 인물 묶음은 후속 몬스터가 바티를 화면에서 교체하므로 비교에 부적합했다. 표시 인물, 버튼 상태, 창 크기·모드·격리 user 경로를 기록한다. F6/F8/F10도 export용 임시 프로젝트에서만 작동한다.

스토리 원문·밸런스·DAY29 무전투·저장 형식·기존 이미지 파일·전체화면 설정 코드는 변경하지 않았다. 다른 불투명 초상21개/합본5개 및 기존 미채택 후보는 이번 네 항목 재확인 범위 밖이며 그대로 남아 있다.

### 빌드·검증·제한

| 명령/확인 | 결과 |
|---|---|
| `python -X utf8 tools/run_playtest_ui.py headless` | 초상 보정 후 25명·두 해상도 **124검사 실패0**, exit0·진단0 |
| `python -X utf8 tools/run_playtest_ui.py after` | 최종 초상/툴팁 **128검사 실패0**, GUI Compatibility, exit0·진단0 |
| `python -X utf8 tools/run_playtest_ui.py before` | 구버전 비교 호환 보존 후 기준25명·두 해상도 렌더 완료, exit0·진단0. 수정 전 단계는 동일 크기 단언을 하지 않음 |
| `python -X utf8 tools/run_playtest_ui.py export-after` | 최종 HEAD `f5644419` Windows release export 성공, exit0·진단0 |
| `python -X utf8 tools/run_playtest_ui.py launch-after` + Computer Use | Vulkan1.4.341 / Forward+ / RTX3060Ti, 최종 698초 실행, 정상 종료 **exit0**, 진단0·종료 후 프로세스0 |
| 최종 HEAD 재export 바이너리 대조 | 실제 30전환을 조작한 EXE/PCK와 **SHA256 모두 동일**, 따라서 새 게임 코드/빌드 변경에 대한 검수 재사용이 아님. [동일성 증거](../../tmp/playtest_ui_20261019/cu_binary_identity.json) |
| `python -X utf8 tmp/playtest_ui_20261019/summarize_recheck.py` | 30전환 기대 모드, 5왕복×3경로, 자동 false/true/false·체크 표시, 표시 인물, 창 크기3종, 열람15장/최대960px, 기존 import 상태 보존 대조 통과 |
| 변경 경로 한정 `git diff --check` | 통과 |
| Windows Application 1000/1002 | 재확인 시작 이후 해당 Godot/검증 EXE의 새 충돌/정지 이벤트0 |
| 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED / 미실행 |

- [최종 요약 JSON](../../tmp/playtest_ui_20261019/cu_recheck_summary.json), [직접 열람15장 목록·크기](../../tmp/playtest_ui_20261019/cu_viewed_images.json). 원본 CU 캡처는 도구 결과에서 직접 표시하지 않고 저장했으며, 직접 열람은 960px 이하 사본/합본 **15장**이다. 추가 열람 없음.
- Computer Use의 `unknown screenshotId screenshot-0` 1회는 창 재선택·새 캡처로 복구했다. 목록 렌더 전 캡처1회는 갱신 후 다시 위치를 찾았다. 접근성 최대화 입력의 무반응1회는 성공 횟수에서 제외하고 제목 표시줄 직접 조작으로 5왕복을 채웠다. 게임 크래시나 성공한 조작으로 계산하지 않았다.
- 최종 EXE SHA256: `b69539e846fdac8b167c852b578a49d9a11d0ba18663a1a7f66a35de5ae72046`; PCK SHA256: `f64e161f5be880102a89a932169253ba325e69ecb428eb93cfab6fa0fbfd3a8d`. 기준 렌더가 실행 중일 때 export 실행기 단일 엔진 보호가 요청1회를 거부했으며, 종료 후 다시 실행해 성공했다. 동시 엔진 수를 늘리지 않았다.
- `APPDATA`·`LOCALAPPDATA`는 `tmp/playtest_ui_20261019/profiles/launch-after/` 아래로 격리했고 `MAWANG_DISABLE_STEAM=1`이다. 보조 도구에서 캠페인 저장 쓰기도 껐다. 사용자 세이브 접근·수정0. Godot/게임 동시1개 이하, 최종0개.
- 시작 시 기존 추적 `.import` 변경 **1,307개**와 미추적 `.import` **64개**의 상태를 모두 보존했다. 실행기는 import 내용을 매번 사본 보존·복구했다. 기존 미추적 자료도 보존했다. 이번 제품/도구4경로와 인계2경로만 명시 스테이징했다. EXE/PCK/캡처/프로필/tmp는 커밋하지 않았다.

### 이번 재확인의 정책 필드·다음 작업

- Review task ID: NOT_REQUESTED
- Reviewed SHA: f5644419983b237805539f0acbb77cd5650779b5
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..f5644419983b237805539f0acbb77cd5650779b5
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

범위는 이번 네 항목이며 출시 전체 PASS가 아니다. 위 Review range는 로컬 캐시 기준 merge base를 위한 정책 필드이고, 이번 세션 변경/검수 범위는 `d70e8a14..f5644419`이다. 이후에는 `docs/handoff/`만 변경한다. 로컬 영어 커밋만 남겼으며 원격·공개 배포 작업은 없다. **다음: 사용자 확인 대기.**
