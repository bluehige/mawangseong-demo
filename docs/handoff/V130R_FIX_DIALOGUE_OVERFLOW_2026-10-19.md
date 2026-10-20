# V130R 대사 UI 넘침 전수 확인·수정 — 2026-10-19

## 1. 메타데이터

- 목표 버전: 1.3.0, 0121 위 사용자 보고 수정
- WORKSTREAM_ID: V130R_DIALOGUE_OVERFLOW_2026-10-19
- 작업 브랜치: `codex/v130r-defense-layout`
- 기준 브랜치 및 SHA: 사용자 지정 브랜치 / `0141647b11e02f892364c9da0ec93d62b3f2e62d`
- 구현·검증 대상 SHA: `733ca7f402833c0e35dc1d1871e3e1c85e8f6073`
- 마지막 커밋 SHA: 위 구현 커밋 이후 이 문서와 CURRENT만 갱신. 문서 커밋 SHA는 Git 로그·최종 응답 참조.
- 원격 푸시 여부: 없음. push/fetch/PR/태그/Release/Steam/main 변경 없음.
- 권위 한계: 로컬 `main`이 없어 `main:AGENTS.md`·`main:CURRENT.md` 조회 불가. 캐시 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 원격 최신성도 확정하지 않았다. 사용자가 제공한 정책과 지정 브랜치를 기준으로 진행했다.

**결과: TARGETED_PASS. 사용자 확인 대기.** 대사 표시 범위의 결과이며 전체 출시 검수는 아니다.

## 2. 목표·완료 조건·측정 정의

- 본편·컷신·전투·barks·유대/기억/합동기/합류·정산·튜토리얼·도입·업적·로그의 전체 대사 소스를 실제 게임 글꼴로 측정한다.
- ko/en/zh_CN × 1280×720/1920×1080 × 기본1.0/최대1.15. 최대 사용자 이름은 기존 검증 규칙의 12자이며 W·한글·중국어 12자도 검사했다.
- 131개 JSON/스크립트 소스의 14,370개 텍스트 필드를 수집했다. 본편 30일 1,741개 대사, 0111 930개 대사 및 두 언어의 documents 묶음, 별도 합류·기억 quote·관계 대사·이벤트 선택지·원문 UIUX 오버레이·코드 내 3언어 문구를 포함한다. 번역 묶음 안의 원래 문서명을 JSON pointer로 보존하여 barks/유대 등을 올바른 표시 유형에 배정한다.
- 보수적인 표시 후보를 관련 공통 UI 프로필에도 넣어 **335,236건 / 228개 조합**을 검사했다. 숫자는 소스 필드×표시 위치×설정의 건수이며 고유 대사 수나 고유 결함 수가 아니다. 의미 없는 메타데이터까지 포함될 수 있는 넓은 후보 집합이다.
- 실제 생성기의 컨트롤 크기·글꼴을 사용한다. Label은 실제 line height/visible line count, RichTextLabel은 content height, 줄 분할은 TextParagraph로 검사한다. 기존 스크롤이 있는 가변 행은 스크롤을 통한 원문 접근을 허용한다. 고정 영역의 말줄임·숨김·줄 수 부족은 실패다.
- GPT 프레임의 반투명/경사 테두리를 텍스트 영역으로 보지 않는다. 공통 대화 프레임의 안전 영역은 좌우32·상하24px이며, 수정본 실제 여백은 좌우48·상하28px다. canvas_items의 1920×1080 논리 좌표를 물리 해상도 두 가지에서 각각 측정했다.
- 머리 위 대사 말풍선/꼬리 구현은 현재 scripts/scenes에 없다. 기존 barks는 좌측 고정 패널이므로 해당 패널을 측정·수정했다. 새 말풍선이나 그림을 만들지 않았다.

소스·전수 위반 목록: [sources.json](../../tmp/dialogue_overflow/sources.json), [corpus.json](../../tmp/dialogue_overflow/corpus.json), [수정 전 전체 목록](../../tmp/dialogue_overflow/before.json), [수정 후 전체 결과](../../tmp/dialogue_overflow/after.json), [UI 프로필](../../tmp/dialogue_overflow/after_profiles.json). 이 산출물은 로컬 tmp에만 보관한다.

## 3. 완료한 수정·전후 결과

- 대화창: 기존 GPT 그림을 9분할로 표시하고 프레임 내부 여백을 확보했다. 하단 패널 높이를 확보하고 긴 본문은 원문 순서대로 페이지를 나눈다. 클릭·Space/Enter·다음 버튼·자동 재생이 한 대사의 마지막 페이지를 읽은 뒤 다음 대사로 간다. 페이지 중간에는 읽음/완료 처리를 하지 않는다.
- 이름: 긴 이름이 컨테이너 폭을 강제로 늘리지 않도록 줄바꿈과 최소 행 높이를 지정했다. 이름 입력 제한 자체는 바꾸지 않았다.
- 전투 대사·barks·승리: 최대 폭1080, 높이520 이내에서 실제 라벨 줄 높이로 확장하고 화면 내부로 제한한다. 기본 맞춤 하한18px, 도입·알림20px. 지연 HUD 축소와 전용 맞춤이 충돌하지 않는다.
- 첫날/도입: 글자 배율을 적용하고 실제 줄 높이에 따라 고정 슬롯 안으로 맞춘다.
- 업적 알림: 말줄임 대신 두 줄 원문 영역을 확보하고 기존 프레임을 9분할로 늘렸다.
- 로그: 가로 스크롤을 막고 가변 폭·높이의 행과 글자 배율을 사용한다. 식량 결산은 줄바꿈·스크롤·배율을 명시했다.
- **대사 문구 변경 목록: 없음.** JSON·번역·밸런스·DAY29 데이터·폰트·그림 원본 변경 없음. 페이지 경계의 공백만 화면에서 생략하며 페이지를 다시 연결하면 원문과 정확히 일치한다(전수 116,496검사, 실패0).

수정 전 **154,728건 → 수정 후 0건**. 프레임 안전 여백 위반이 각 후보 대사/이름에 반복 집계된 수치다. 아래 각 셀은 **기본/최대 배율의 수정 전 → 수정 후**다. 720p=1280×720, 1080p=1920×1080.

| UI | ko 720p | ko 1080p | en 720p | en 1080p | zh_CN 720p | zh_CN 1080p |
|---|---:|---:|---:|---:|---:|---:|
| 본편·컷신 본문 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 |
| 전투 컷신 본문 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 | 4290/4290 → 0/0 |
| 화자 이름 | 3184/3184 → 0/0 | 3184/3184 → 0/0 | 3184/3184 → 0/0 | 3184/3184 → 0/0 | 3184/3184 → 0/0 | 3184/3184 → 0/0 |
| 전투 고정 대사·barks | 1/1 → 0/0 | 1/1 → 0/0 | 2/2 → 0/0 | 2/2 → 0/0 | 1/1 → 0/0 | 1/1 → 0/0 |
| 승리 bark | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 유대·기억·합동기·합류 | 1128/1128 → 0/0 | 1128/1128 → 0/0 | 1128/1128 → 0/0 | 1128/1128 → 0/0 | 1128/1128 → 0/0 | 1128/1128 → 0/0 |
| 사건 대사 본문 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 선택지 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 이름 짓기 도입 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 이름 입력 코멘트 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 프롤로그 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 첫날 안내 | 0/0 → 0/0 | 0/0 → 0/0 | 1/1 → 0/0 | 1/1 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 튜토리얼 안내 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 튜토리얼 관찰 안내 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 정산·결산 흐름 본문 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 24종 하루 식량 결산 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 업적 알림 이름 | 0/0 → 0/0 | 0/0 → 0/0 | 1/1 → 0/0 | 1/1 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 업적 목록 설명 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |
| 대사 기록 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 | 0/0 → 0/0 |

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `scripts/achievements/AchievementToast.gd` | 두 줄 전체 이름·9분할·배율·창 가장자리 |
| `scripts/game/GameRoot.gd` | 클릭·키·자동 재생에서 페이지를 먼저 진행 |
| `scripts/story/CombatStoryFeed.gd` | 실제 줄 높이에 맞춘 고정 패널 확장 |
| `scripts/story/StoryDialoguePresenter.gd` | 안쪽 여백·9분할·원문 보존 페이지·이름 |
| `scripts/story/V130RStoryRuntime.gd` | barks·승리 패널 확장·화면 클램프 |
| `scripts/ui/ApprovedBattleUI.gd` | 식량 결산의 줄바꿈·스크롤·배율 명시 |
| `scripts/ui/DialogueLayout.gd` | 실제 줄 높이·하한 있는 축소·원문 보존 분할 |
| `scripts/ui/DialogueLayout.gd.uid` | 공통 배치 스크립트 UID |
| `scripts/ui/HUDController.gd` | 대사 전용 맞춤과 지연 축소의 충돌 방지 |
| `scripts/ui/PlayerContinuityUI.gd` | 로그 행의 가변 폭·확대 글꼴·가로 스크롤 방지 |
| `scripts/ui/StartFlow.gd` | 도입·첫날 안내 배율과 실제 줄 높이 맞춤 |
| `tools/run_dialogue_overflow.py` | 전체 소스 수집·기준판 복사·격리·직렬 실행·EXE |
| `tools/tests/DialogueOverflowTest.gd` | 전체 언어 측정·렌더·입력·테스트 세이브 |
| `tools/tests/DialogueOverflowTest.gd.uid` | 테스트 스크립트 UID |
| `tools/tests/DialogueOverflowTest.tscn` | 측정 진입 씬 |
| `docs/handoff/V130R_FIX_DIALOGUE_OVERFLOW_2026-10-19.md` | 수정·전후 표·증거·한계 |
| `docs/handoff/CURRENT.md` | 다음 세션 진입 링크와 사용자 확인 대기 |

## 5. 그래픽·캡처·EXE

- 신규 그림/이미지 생성/외부 자산/글꼴 교체: 없음. 기존 GPT 상자 크기·여백·9분할만 조정했다. NEXON Maplestory와 기존 중국어 fallback을 유지했다.
- 수정 전/후 각각6장, 모두960×540 사본. 같은 최대 배율1.15로 캡처했다. 전체 화면 원본을 직접 열지 않았다.

| 대상 | 전 | 후 |
|---|---|---|
| 긴 한국어 | [수정 전](../../tmp/dialogue_overflow/before_long_ko.png) | [수정 후](../../tmp/dialogue_overflow/after_long_ko.png) |
| 긴 영어 본편 | [수정 전](../../tmp/dialogue_overflow/before_long_en_main.png) | [수정 후](../../tmp/dialogue_overflow/after_long_en_main.png) |
| 긴 영어 0111 | [수정 전](../../tmp/dialogue_overflow/before_long_en_extra.png) | [수정 후](../../tmp/dialogue_overflow/after_long_en_extra.png) |
| 긴 중국어 | [수정 전](../../tmp/dialogue_overflow/before_long_zh.png) | [수정 후](../../tmp/dialogue_overflow/after_long_zh.png) |
| 기존 고정 bark 패널 | [수정 전](../../tmp/dialogue_overflow/before_bark.png) | [수정 후](../../tmp/dialogue_overflow/after_bark.png) |
| 대사 로그 | [수정 전](../../tmp/dialogue_overflow/before_log.png) | [수정 후](../../tmp/dialogue_overflow/after_log.png) |

- EXE: [MawangDialogue.exe](../../tmp/dialogue_overflow/exe/MawangDialogue.exe), Windows release 템플릿의 로컬 검증 빌드(출시·게시 아님). 설치된 공식4.6.3 release 템플릿을 격리 경로에 복사해 사용했다.
- EXE의 제품 스크립트와 실제 Main 진입은 그대로다. 이미지 열람960px 제한을 위해 **임시 export 프로젝트에 창 크기920×518만 설정하는 autoload 한 개**를 추가했다. 이 보조 코드는 소스 프로젝트/런타임 커밋에 넣지 않았다. 자세한 실제 확인: [computer_use.json](../../tmp/dialogue_overflow/computer_use.json).
- Computer Use: Computer Use? Start?Continue? ???? DAY1? ?? STORY_D01_RESULT_WIN_008 ?? ??(2?)? ????. ?? ?? ? ?? v6 ??? checkpoint/screen=management, story cue ??? ????.
- EXE 제품 코드 일치: [export_source_identity.json](../../tmp/dialogue_overflow/export_source_identity.json), scripts/scenes270개 일치·차이0. [긴 대사 실제 화면](../../tmp/dialogue_overflow/exe_long_dialogue.png).
- `APPDATA`/`LOCALAPPDATA`는 tmp 아래 격리했다. 원본 사용자 세이브를 읽거나 수정하지 않았고 새 DAY1 테스트 v6 세이브만 생성했다. `MAWANG_DISABLE_STEAM=1`로 외부 Steam 초기화/전송을 차단했다.
- 직접 이미지 열람: 15장, 모두 최대960px 이하. 최종 작업 Godot/EXE 프로세스0.

## 6. 검증

| 순서 | 명령·방법 | 결과 |
|---:|---|---|
| 1 | `python tools/run_dialogue_overflow.py before` | 기준판 `0141647b`의 별도 tmp 복사, 335,236건, 위반154,728; 실행 오류/경고0 |
| 2 | `python tools/run_dialogue_overflow.py after` | 같은 소스·조합·건수, 위반0, 검사116,496, 실패0, 실행 오류/경고0 |
| 3 | `python tools/run_dialogue_overflow.py behavior` | 41검사 PASS. legacy/director 양쪽의 페이지·자동 재생·클릭·키·로그 차단·최대 이름·DAY29 |
| 4 | `render-before`, `render` | GPU 실제 렌더, 전후12장960×540, 실행 오류/경고0. bark의 실제 표시 줄 수 확인 |
| 5 | `fixture`, `export`, `launch` + Computer Use | 테스트 v6 생성3검사 PASS, Windows export 성공, 실제 긴 대사·입력 확인 |
| 6 | `python -m py_compile tools/run_dialogue_overflow.py`, `git diff --check` | PASS |
| 7 | 전체 회귀/전체 플레이/별도 검수 에이전트 | NOT_REQUESTED / 미실행. 읽기 전용 소스 조사1명은 구현 위치·누락 소스 파악만 수행 |

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 733ca7f402833c0e35dc1d1871e3e1c85e8f6073
- Review range: 0141647b11e02f892364c9da0ec93d62b3f2e62d..733ca7f402833c0e35dc1d1871e3e1c85e8f6073
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

정책 검사도 PASS: `tools/ci/ValidateRepositoryPolicy.ps1 -BaseRef 0141647b11e02f892364c9da0ec93d62b3f2e62d -HeadRef codex/v130r-defense-layout`, 문서 커밋 `8d3060ae`에서 17파일·2커밋 확인. [최종 정책 로그](../../tmp/dialogue_overflow/policy.log). 이후에는 이 증거 문구만 추가했다. 검증 SHA 이후 제품/테스트 코드 변경 없음.

## 7. 제한·시행착오

- 최종 판정은 위 표적 범위에 한정한다. 조건별 캠페인 전체 플레이와 출시 검수는 실행하지 않았다.
- 초기 콘솔 래퍼가 래퍼1+엔진1 프로세스를 만들었다. 해당 실행을 모두 종료하고 이후에는 공식 엔진 exe를 직접 호출하고 기존 프로세스가 있으면 시작을 거부하도록 바꿨다. 이후 동시 엔진1, 최종0.
- 중간 측정기의 글자 모양 높이만 사용하는 방법은 전체 font line height를 반영하지 못했다. 실제 라벨 높이·숨은 줄 검사를 추가했고 최종 전/후 결과는 같은 보강된 방법으로 다시 생성했다. 중간 수치는 최종 판정에 사용하지 않는다.
- 초기 later-DAY 테스트 세이브는 정상 유효성 검사에서 거부되었다. 실제 DAY1 대사로 새 테스트 세이브를 만들어 해결했다. 사용자 세이브 관련 변경은 없다.
- 격리 환경에 debug export 템플릿이 없어 설치된 release 템플릿을 사용했다. release EXE의 외부 `--script` 방식은 적용되지 않아 종료하고, 위의 임시 창 크기 autoload 방식으로 대체했다. 원본 프로젝트 설정은 변경하지 않았다.
- EXE Space 1? ??/??? ??? ?? ?????. EXE Space ?? ??? ???? ???. ? ??? ?? ??? ??41??? ????.
- Alt+F4 ? ?? ?? EXE PID3676? ??? ???? ??. ?? Godot/EXE0. 관리 화면 복귀는 추가 이미지 열람 없이 테스트 저장 내용으로만 확인했으며 실제 관리 화면 렌더 확인으로 대체해 기록하지 않는다.

## 8. 다음 작업·작업 트리·종료

1. **사용자 확인 대기**: 전후 캡처와 필요시 로컬 EXE의 상자 크기·여백·페이지 진행을 확인한다.
2. 승인 없는 push/태그/Steam/main/출시 작업은 진행하지 않는다.

- 기존 혼합 작업: 추적 중 import 변경1,307개 및 기존 미추적 파일 보존. 최종 보호 검사에서 기존 비대상 파일 변경 0개. [보호 결과](../../tmp/dialogue_overflow/preservation.json).
- 빌드/캡처/원시 로그/전수 JSON/임시 프로젝트는 `tmp/dialogue_overflow/`에만 보관하며 커밋하지 않는다. source 브랜치에 EXE/PCK/PNG를 추가하지 않았다.
- 의도한 파일만 명시적으로 스테이징하고 영어 로컬 커밋만 생성한다. 최종 상태/커밋은 최종 응답과 Git 로그에 기록한다.
