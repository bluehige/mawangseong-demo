# 1.3.0 출시 빌드 준비 — PARTIAL / BGM 완료 대기

## 1. 메타데이터

- 작성일: 2026-10-15
- WORKSTREAM_ID: V130-RELEASE-BUILD
- 목표 버전: 1.3.0 / Windows 파일·제품 버전 1.3.0.0
- 작업 브랜치: `codex/v130-map-overhaul`
- 시작 SHA: `8d4023e7aab0d72952be4ffcad996ee8d7fa70f6`
- 기준 참조: 캐시 origin/main 및 merge base `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`
- 마지막 구현·직접 검증 SHA: `ea44d080fd5775924289a28526f6a323c818eb71`
- 마지막 문서 커밋 SHA: `git log -1 --format=%H -- docs/handoff/V130_RELEASE_BUILD_2026-10-15.md`로 조회
- 원격 push·merge·태그·Release·Steam 업로드/Commit/default/공지 게시: 모두 0
- 권위 제한: 로컬 main 참조 없음. 원격 조회·fetch는 하지 않았다. 캐시 origin/main의 정책/CURRENT는 읽었으나 원격 최신 권위로 확정하지 않았다. 사용자 제공 최신 정책과 이번 명시 지시를 따른다.

## 2. 이번 세션 목표와 실제 상태

목표는 1.3.0 버전 적용·공식 Windows Steam export·최종 EXE의 3언어 스모크·Steam 웹 업로드용 7파일 ZIP이다. **이번 결과는 소스 버전/문구/계획 정리만 완료한 PARTIAL이며 출시 후보나 ZIP은 준비되지 않았다.**

시작 조건인 BGM 구현 커밋 `46f602a`와 지정 [BGM 인계](V130_BGM_2026-10-15.md)의 문서 커밋 `8d4023e`가 현재 브랜치 이력에 있다. 그러나 그 인계는 **실제 14곡, 마지막 엔딩 1곡 미생성, 관련 필수 검사 실패**를 명시한다. 실제 `assets/audio/bgm/v130/`도 WAV 14개이며 `final_ending_02_home_after_siege.wav`가 없다. 완료 커밋이 있다고 가정하지 않았다.

이 차이를 사용자에게 보고하고, 15곡 완료 커밋 대기 또는 14곡 출시·표기 변경 중 처리 방향을 비동기로 질문했다. 종료 시 답변 미수신. **응답을 승인으로 간주하지 않으며, 추가 음원 생성·기존 검사 기대값 완화·14곡을 15곡으로 표기하는 조치는 하지 않았다.**

| 요청 | 실제 결과 |
|---|---|
| A. 프로젝트·export·EXE 설정·게임 내 버전/공지·문서 1.3.0 | 소스 적용 완료. 실제 EXE·manifest는 export 미실행으로 없음 |
| 패치노트 3언어의 초안 문구 제거·720 안내 | 완료 |
| 패치노트 3언어의 새 BGM 15곡 항목 | 미적용. 실제 15곡 완료 또는 사용자 범위 변경이 선행해야 함 |
| 사용자 확정 4항목·1.5.0 DLC 백로그 | 완료 |
| B. 공식 Windows Steam export | NOT_RUN / BGM 완료 대기 |
| C. Steam-1.3.0-Ready, Content 7파일, ZIP, 업로드 안내·서버 대조 목록 | NOT_CREATED / 이번 세션에서 대상 폴더를 생성하지 않음 |
| D. 최종 EXE 타이틀→새 게임→DAY1·3언어 버전 확인 | NOT_RUN. 아래 소스 공지 화면 확인으로 대체 판정하지 않음 |

사용자가 지정한 1.2.12 폴더와 버전 범위 JSON·manifest·패치노트·인계를 읽기만 했다. 파일 수정 0. 기존 export preset은 **Windows Steam**, 공식 Godot은 **4.6.3.stable.official.7d41c59c4**다.

## 3. 완료한 작업

- `project.godot`, Windows Desktop/QA/Steam의 export 버전 정보·기본 출력명, 공지 UPDATE_ID와 README를 1.3.0으로 갱신했다. 저장 경로·Cloud·App5267750/Depot5267751은 변경하지 않았다.
- 게임 내 KO/EN/ZH 공지는 자유 배치·1층 부지 성장·장식의 비전투 역할·720 보유 조건·관전/UI·의회 방어/저장 이관으로 갱신했다. 영어 화면의 오른쪽 잘림을 실제 캡처에서 발견해 문장을 줄이고 재확인했다.
- DAY14 주 대사와 DAY14~15 관리 안내, 전투 시작 차단 안내에 금화 720·악명 720은 **보유 자격이며 차감하지 않음**을 명확히 했다. 일반 몬스터 승급의 별도 비용은 그대로다. 대사의 오해에 대한 해명과 “돈을 내는데 벽은 그대로” 문장도 세 언어에서 정리했다.
- 전투·성장·장식 수치 및 자원 판정 로직은 변경하지 않았다. JSON의 비문자열 구조/수치를 비교했고 GameRoot의 문자열 외 코드가 동일함을 검사했다. 번역 메시지 수와 스토리 cue ID도 보존했다.
- 밸런스 제안서 5절에 사용자 2026-10-15 09:33 KST 질문 1~4 권장안 채택을 기록했다. 보류 항목은 [1.5.0 DLC 백로그](../design/plans/V150_DLC_BACKLOG_2026-10-15.md)에 모으고 PRODUCT_VERSIONING·plans/README에서 연결했다.

## 4. 변경 파일

구현 커밋 24파일, 종료 문서 2파일이다. 전체 목록은 아래와 같다.

```text
README.md
project.godot
export_presets.cfg
scripts/ui/PlayerContinuityUI.gd
scripts/game/GameRoot.gd
data/campaign_days.json
data/story/v122_main/day_14.json
data/localization/ui_en.json
data/localization/ui_zh_cn.json
data/localization/story_en.json
data/localization/story_zh_cn.json
docs/PRODUCT_VERSIONING.md
docs/design/plans/README.md
docs/design/plans/V150_DLC_BACKLOG_2026-10-15.md
docs/design/v20_map_builder/V130_BALANCE_PROPOSAL.md
docs/release/PATCH_NOTES_1.3.0_KO.txt
docs/release/PATCH_NOTES_1.3.0_EN.txt
docs/release/PATCH_NOTES_1.3.0_ZH_CN.txt
tools/tests/DayOneFeedbackHotfixTest.gd
tools/tests/PlayerContinuityTest.gd
tools/tests/PlayerFeedbackHotfixTest.gd
tools/tests/V122ReleaseReadinessTest.gd
tools/tests/V130Council1FTest.gd
tools/tests/V130DecorationTest.gd
docs/handoff/V130_RELEASE_BUILD_2026-10-15.md
docs/handoff/CURRENT.md
```

기존 버전 테스트 갱신 사유: 사용자 승인된 제품 버전 변경에 맞춰 고정 기대값 `1.2.11`/`1.2.11.0`을 `1.3.0`/`1.3.0.0`으로 갱신했다. 동적 자기 비교·부분 버전·검사 삭제로 완화하지 않았다. 역사적 readiness 기준 `1.2.3`은 그대로다. PlayerContinuity의 기존 contains/정확 일치 조건도 유지한다. V130Decoration은 변경된 한국어 번역 키를 조회하도록 바꿨다. V130Council1F에는 실제 승격 후 gold/infamy가 각각 720인 검사를 추가했다.

## 5. 그래픽 및 오디오 자산

신규 이미지·오디오 생성/수정 0. BGM 원본·출처·manifest·playlists·카탈로그와 기대 개수는 이번 세션에서 바꾸지 않았다. 실제 14곡이라는 기존 결과와 누락으로 실패한 기존 검사 기록은 유효한 미해결 항목으로 유지한다. E18 새 그림은 DLC 백로그에만 기록했다.

## 6. 테스트 및 검수

| 실행 | 결과 | 근거 |
|---|---|---|
| `RunV130.ps1 -Scene V122ReleaseReadinessTest -OutputRoot tmp/v130_release` | PASS 85개, Godot 종료 0 | `tmp/v130_release/V122ReleaseReadinessTest-1920x1080/run.log` |
| `RunV130.ps1 -Scene V130Council1FTest -OutputRoot tmp/v130_release` | PASS 303개. 보유 조건과 자원 미차감 포함 | `tmp/v130_release/V130Council1FTest-1920x1080/run.log` |
| `RunV130.ps1 -Scene V1213StageTwoTest -OutputRoot tmp/v130_release` | PASS 1,126개 | `tmp/v130_release/V1213StageTwoTest-1920x1080/run.log` |
| `python -m unittest discover -s tools/ci -p test_validate_steam_release.py` | PASS 11개. 검증 도구의 테스트이며 최종 depot 검증이 아님 | 명령 출력 |
| 임시 소스 GUI 확인, KO/EN/ZH 각각 1920×1080 | PASS 25개. 정확한 v1.3.0·공지 9행 모두 표시·비차감 번역. 세 화면 직접 확인 | `tmp/v130_release/source-ui-results.json`, `source-notes-ko.png`, `source-notes-en.png`, `source-notes-zh_CN.png` |
| 버전·JSON·문자열 외 변경 비교 | PASS 8항목, JSON 6개 파싱 성공, 메시지 수 유지 | `tmp/v130_release/impact-check.json` |
| 명시 24파일 스테이징·`git diff --cached --check` | PASS, import/UID/빌드/캡처 포함 0 | 구현 커밋 |
| 공식 export·PE 버전·최종 EXE 스모크·ZIP/서버 대조 | NOT_RUN | BGM 처리 대기 |
| 전체 회귀·전체 플레이·별도 검수 에이전트 | NOT_REQUESTED / 미실행 | 이번 사용자 지정 표적 범위 |

모든 게임/검사 실행은 격리 APPDATA로 했다. 직접 검사 실행 전후 0·실행 중 최대 1 Godot, 최종 생존 0. 임시 GUI 도구의 첫 실행은 UTF-8 BOM 때문에 씬 파싱에 실패했고, 다음 실행에서는 Label의 target_id를 노드 이름으로 잘못 조회해 실패했다. 도구만 보정하고 기존 오류 로그를 보존했다. 타임아웃 종료 직후 프로세스 열거 경합은 소멸 대기로 보정했다. 제품 실행 오류로 오인하지 않는다. 화면 확인에서 발견한 실제 영어 잘림은 공지 문구를 축약해 수정하고 새 캡처에서 확인했다.

**범위 제한:** 위 PASS는 이번 버전/안내/계획 변경에 대한 표적 결과다. BGM 15곡 검사, 통합 출시 준비, 최종 EXE 또는 ZIP PASS가 아니다. 기존 BGM 인계의 U5F·오디오 매니페스트·pipeline·catalog 실패를 이번 검사로 덮어쓰지 않는다. 재실행하지 않은 PlayerContinuity/DayOneFeedback/PlayerFeedback 전체 시나리오도 통과했다고 기록하지 않는다.

### 정책 CI용 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ea44d080fd5775924289a28526f6a323c818eb71
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..ea44d080fd5775924289a28526f6a323c818eb71
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

Release build result: BLOCKED_BGM_INCOMPLETE / PARTIAL. 이 필드는 통합 출시 승인과 구분한다. 위 SHA 이후에는 docs/handoff만 수정한다.

## 7. 미해결 항목과 위험

- `v130_final_ending_02_home_after_siege` 미생성. 기존 인계의 API 입력 거절·재시도 한도 및 검사 실패가 남아 있다. 이번 사용자 요청은 추가 유료 생성 승인이 아니므로 호출 0.
- 요청한 BGM 15곡 패치노트 항목은 실제 완료 또는 사용자의 14곡 범위 변경 전까지 보류한다. 다른 변경 설명은 확정 내용을 반영했지만 현재 패치노트를 게시 가능한 최종본으로 판정하지 않는다.
- 출시 폴더·EXE·PCK·manifest·ZIP·업로드 안내·서버 대조 목록·최종 EXE 캡처가 없다. ZIP 경로/크기/SHA256은 모두 N/A이며 가짜 경로나 해시를 제시하지 않는다.
- 1.2.12 기준 폴더는 읽기만 했으며 수정하지 않았다. 자연 30일·Steam 설치·2PC Cloud·실기 터치는 미실행이다.

## 8. 다음 작업 순서

1. 헤드가 BGM 15곡 완료 커밋을 제공하거나 실제 14곡으로 출시 요구를 변경한다. 15곡 유지 시 누락곡 연결과 기존 실패 검사가 해결된 SHA를 먼저 확인한다. 완료 시 패치노트 KO/EN/ZH에 각각 다음 항목을 추가한다.
   - KO: `새 BGM 15곡을 추가했습니다(타이틀·관리·전투·결과·엔딩).`
   - EN: `Added 15 new BGM tracks for the title, management, combat, results and endings.`
   - ZH_CN: `新增15首背景音乐，涵盖标题、管理、战斗、结算与结局。`
2. 새 최종 소스를 영어 로컬 커밋으로 고정하고, 기존 혼합 변경을 보존한 채 공식 Godot 4.6.3의 `Windows Steam` preset으로 export한다. 매 실행 전후 0·최대 1을 기록한다. 기존 PrepareSteamBuild.ps1은 dirty worktree를 거절하므로 사용자 변경을 임의 스태시/정리하지 않는다. 직접 공식 export 및 기존 패키징 검증 경로를 사용한다.
3. `C:/Users/blueh/Documents/Codex/2026-10-13/task/Steam-1.3.0-Ready/Content`에 EXE/PCK/THIRD_PARTY_NOTICES.txt/licenses 3개/manifest 총 7파일만 넣는다. 태그는 만들지 않고 manifest에 `tag_state=not_created`를 기록한다.
4. 최종 EXE를 격리 APPDATA에서 3언어 1920×1080으로 실행해 버전 1.3.0, 타이틀→새 게임→DAY1 관리 진입을 확인한다. 이번 소스 화면을 재사용하지 않는다.
5. `MawangCastle-v1.3.0-SteamContent-<짧은SHA>.zip`을 EXE/PCK 최상위로 만들고 목록/CRC/바이트/해시·7파일·금지 파일 부재를 검사한다. ZIP·export 종료·예상 서버 대조 목록·3언어 캡처는 Evidence, 이벤트 패치노트 3개는 루트에 둔다. 인증정보·세이브·로그·VDF·스크립트는 ZIP 제외.
6. HTTP_UPLOAD_1.3.0_KO.md에 URL `https://partner.steamgames.com/apps/depotuploads/5267750`, Depot5267751/Standard, 실제 ZIP 전체 경로, Notes `v1.3.0 - <짧은SHA>`, Commit Branch None을 기입한다. 업로드/공개 변경은 이번 준비 범위 밖이다. 인계/CURRENT와 영어 로컬 문서 커밋으로 종료한다.

## 9. 작업 트리 상태

시작 시 기존 import 1,423개·미추적 UID 31개. 해당 변경을 보존했고 이번 커밋에 포함하지 않았다. 브랜치 전환·reset·stash·git add -A 0. 구현 24파일만 명시 스테이징해 영어 로컬 커밋 `ea44d08`을 만들었다. 종료 인계/CURRENT는 별도 영어 로컬 문서 커밋이다. push·merge·태그는 금지대로 수행하지 않는다.

검사 로그·임시 도구·캡처는 Git 제외 `tmp/v130_release/`에만 있다. 읽기 전용 보조 에이전트는 기존 최종 EXE 스모크 도구의 재사용 가능성만 조사했고 파일·프로세스·UI를 변경/실행하지 않았다. 검수 에이전트를 통한 전체 검수는 수행하지 않았다.

## 10. 종료 체크리스트

- [x] BGM 커밋/인계 존재와 실제 PARTIAL 상태 확인
- [x] 버전·세 언어 보유 자격 문구·확정 기록·DLC 백로그
- [x] 버전/의회/StageTwo 직접 검사 및 소스 공지 화면 확인
- [x] 기존 테스트의 고정 버전 기대값 갱신 사유 기록, 기대값 약화 없음
- [x] 기존 혼합 변경 보존·영어 로컬 커밋·CURRENT 갱신
- [ ] BGM 15곡 완료 및 요청 패치노트 항목
- [ ] 공식 export·출시 폴더·최종 EXE 스모크·7파일 ZIP·Evidence/업로드 안내
- [x] push·merge·태그·공개 배포 0 기록
