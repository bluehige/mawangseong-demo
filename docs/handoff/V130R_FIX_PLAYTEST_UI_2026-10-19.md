# V130R 사용자 실플레이 UI·이미지·전체화면 수정

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
