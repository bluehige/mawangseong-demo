# Steam 심사 수정 및 DAY 1–10 영어 대사 연결

## 1. 메타데이터

- 작성일: 2026-09-20
- 목표 버전: 공개 v1.2.7 이후 영어화 작업분. 새 제품 버전·태그·출시는 지정하지 않았다.
- 작업 브랜치: `codex/content-english`
- 기준 브랜치 및 SHA: `main` / `df9b4f886806c960e15431a5e2a15ffe7373c0ee`
- 마지막 구현 커밋 SHA: `ad96c196de16e84617db1166c95e23c03d33647b`
- 원격 푸시 여부: 구현·핸드오프 커밋 후 원격 작업 브랜치로 푸시 예정. main 병합·출시는 별도다.
- 작업 디렉터리: `C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2`

## 2. 이번 세션 목표

- 사용자 지시 순서대로 Steam 심사 반려 사유를 먼저 수정·게시하고 게임 영어 번역을 이어갔다.
- 이전에 안내됐던 191KB ZIP과 358개 대조표의 실제 파일은 확인되지 않았다. 저장된 DAY 1–5 번역 183개에서 시작해 DAY 1–10 358개와 실제 전달 파일을 만들었다.
- 이번 영어 작업분의 완료 조건은 원문·ID·치환문자 보존, 영어 선택 시 실제 대사 연결, 직접 검사, ZIP 재압축 해제 검증이다. 게임 전체 영어화 완료를 뜻하지 않는다.
- 이미지 생성·수정, 음원, 밸런스, 전체 캠페인 검수, 출시 빌드·태그·판매 시작은 제외했다.

## 3. 완료한 작업

### Steam 반려 사유 수정

- App ID: **5267750**.
- 기존 Content Survey `811321`의 한국어 AI 설명은 저장돼 있었지만 English Generative AI 설명은 비어 있었다. 기존 한국어 원문은 다음과 같다.

> 우리게임은 저의 아이디어에서 시작하여
> 개발, 기획, 사운드, 그래픽 전부 AI로 제작하였습니다.

- 영어 설명에 아래 내용을 입력·저장했다. 기존 AI 사용 여부·실시간 생성 없음·외부 AI 연결 없음 체크값은 보존했다.

> This game started with my own ideas. Its development, design, sound, and graphics were all created using AI. AI-generated content was created during development. The game does not generate AI content during gameplay or connect to external AI services.

- 새 [Content Survey 815414](https://partner.steamgames.com/contentdescriptors/editsurvey/5267750/815414)를 저장하고 **Publish Generated Ratings**를 실행했다. Steam 게시 성공 안내를 확인했다. 기존 등급과 다른 설문 응답은 바꾸지 않았다.
- [앱 게시 화면](https://partner.steamgames.com/apps/publishing/5267750)의 View Diffs에서 Valve가 추가한 `name_localized.koreana = 마왕님, 마왕성은 누가 지켜요?` 한 항목만 있는 것을 확인했다. Prepare Publishing → Publish to Steam → STEAMWORKS 입력 → Really Publish 후 **Publishing successful / Publish to steam OK**를 확인했다.
- [앱 대시보드](https://partner.steamgames.com/apps/landing/5267750)에서 반려 사유 해결 내용을 첨부해 상점 재심사를 제출했다. UI 상태 **Your app is in the review queue / Submitted for review on 20 Sep**를 확인했다.
- 빌드 심사는 기존 **Submitted for review on 14 Sep** 상태다. 이번 작업은 승인 완료가 아니라 재심사 제출 완료다.
- 영어 게임 지원 체크는 켜지 않았다. 한국어 인터페이스·자막 지원 표시를 유지했다. 공개 Coming Soon 전환·판매 시작은 실행하지 않았다.

### 영어화 구현

- DAY 1–10의 모든 원문 대사 **358개**, 장면 제목 **61개**, 화자 표기 **14개**, 대화 조작 문구 **9개**를 별도 JSON에 저장했다.
- LanguageSettings에서 cue ID·scene ID로 영어를 조회한다. 미번역 ID는 한국어 원문으로 돌아가며 사용자 이름과 `{{player_name}}` 치환을 보존한다.
- 전체 화면 대화·전투 중 대사·전투 일시정지 대화·대화 기록에 적용했다. 자동 진행 시간 계산은 실제 표시 문장 길이를 사용한다.
- 언어를 바꿔도 대사 위치·읽음 상태를 진행시키지 않으며 전투 로그를 중복 추가하지 않는다.
- 한국어 스토리 JSON·조건·보상·캐릭터 이미지·저장 구조는 바꾸지 않았다.
- 기존 언어 검사에서 UIUX V2에 없는 `NAME REGISTRATION` 안내 제목을 찾던 항목을 실제 안내 본문과 입력 비차단 상태 검사로 고쳤다. 검사 종료 시 게임 노드가 제거된 뒤 언어 설정을 복원해 종료 시 잔존 리소스 경고도 해소했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/localization/story_en.json` | DAY 1–10 번역·제목·화자·조작 문구 | 완료 |
| `scripts/core/LanguageSettings.gd` | 번역 조회·한국어 대체 표시 | 완료 |
| `scripts/story/StoryDialoguePresenter.gd` | 전체 화면·전투 대화 연결 | 완료 |
| `scripts/story/CombatStoryFeed.gd` | 전투 중 대사·언어 전환 | 완료 |
| `scripts/game/GameRoot.gd` | 읽기 시간·언어 전환·대화 기록 | 완료 |
| `tools/tests/StoryEnglishCatalogTest.cjs` | 원문 대응 정적 검사 | PASS |
| `tools/tests/StoryEnglishRuntimeTest.gd`, `.tscn` | 실제 게임 연결 검사·화면 캡처 | PASS |
| `tools/tests/V122Stage10LocalizationTest.gd` | 현행 이름 입력 안내 검증·종료 정리 | PASS |
| `tools/BuildStoryEnglishPackage.cjs` | 텍스트 전용 전달 패키지 생성 | PASS |
| `docs/handoff/CURRENT.md`, 이 문서 | Steam 최신 상태·후속 번역 진입점 | 갱신 |

## 5. 그래픽 및 오디오 자산

- 이미지 생성·편집 및 오디오 변경: 없음. 기존 자산을 그대로 사용했다.
- Godot import로 내용이 같지만 변경 표시된 `.import` 194개는 Git 내용 비교 후 원상 복구했다. 이미지 변경은 커밋하지 않았다.
- 실제 렌더: Godot 4.6.3, Compatibility, 1280×720에서 대화·전투 중 대사·전투 대화·기록 화면을 직접 확인했다.

## 6. 테스트 및 검수

| 검사 | 결과 | 근거 |
|---|---|---|
| `node tools/tests/StoryEnglishCatalogTest.cjs` | PASS: 358개·61장면, ID·중복·누락·치환문자·U+FFFD·화자 | 검사기 및 전달 폴더 `validation.json` |
| Godot 4.6.3 import | PASS | `tmp/story_english_validation/import.log` |
| `StoryEnglishRuntimeTest.tscn` headless | PASS: 23개 | `tmp/story_english_validation/runtime.log` |
| 같은 테스트 실제 화면 1280×720 | PASS: 27개, 캡처 4개 직접 확인 | `tmp/story_english_validation/gui.log`, `fullscreen_en.png`, `overlay_en.png`, `feed_en.png`, `archive_en.png` |
| `V122Stage10LocalizationTest.tscn` | PASS: 42개, 최종 종료 로그 오류 없음 | `tmp/story_english_validation/localization.log` |
| `V122StoryRuntimeIntegrationTest.tscn` | PASS: 58개 | `tmp/story_english_validation/story_integration.log` |
| `git diff --exit-code HEAD -- data/story` | PASS: 한국어 원문 변경 없음 | 구현 커밋 전 실행 |
| 패치 `git apply --check --cached`, `--check --reverse` | PASS: 기준 index 및 현재 작업 트리에 대응 | 구현 커밋 전 실행 |
| `node --check` 생성기, `git diff --check` | PASS | 구현 커밋 전 실행 |
| ZIP 압축 해제·파일 해시·검사기 재실행 | PASS: manifest 대상 25개·358개 검사 | `tmp/story_english_zip_verified_20260920/` |
| 전체 회귀·전체 캠페인·별도 검수 에이전트 | NOT_REQUESTED | 실행하지 않음 |

- 런타임 검사는 프로젝트 tmp 아래의 별도 APPDATA를 사용했다. 개인 저장 파일과 언어 설정은 건드리지 않았다.
- 최초 실패는 검사 코드의 HUD label 조회 방식과 현행 UI에 없는 안내 제목 기대값이었다. 수정 후 관련 검사를 재실행했다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: ad96c196de16e84617db1166c95e23c03d33647b
- Review range: df9b4f886806c960e15431a5e2a15ffe7373c0ee..ad96c196de16e84617db1166c95e23c03d33647b
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- DAY 11–30의 **1,383개 대사**와 나머지 게임 화면은 아직 영어화되지 않았다. 전체 스토리는 1,741개다.
- 영어를 선택해도 미번역 부분은 한국어로 나온다. 현재 Steam 영어 지원 표시를 확대하면 안 된다.
- Valve 상점 재심사와 기존 빌드 심사 결과는 대기 중이다. 심사 통과를 주장하지 않는다.
- 전체 회귀·정식 영어 빌드·Steam 영어 플레이 확인은 이번 검증 범위가 아니다.
- root의 `codex/v125-release-candidate` 작업 트리는 별도이며 기존 변경을 그대로 보존했다.

## 8. 다음 작업 순서

1. `data/story/v122_main/day_11.json`부터 남은 1,383개를 같은 ID로 `data/localization/story_en.json`에 추가한다. 검사기 범위와 패키지 제목도 실제 완료 범위에 맞춰 확장한다.
2. 메뉴·관리·전투·결과·캐릭터/시설·튜토리얼의 미번역 문구를 번역 카탈로그에 연결하고 해당 화면을 직접 검사한다. 이름 입력 UI의 새 장식 문구도 아직 한국어다.
3. 영어 지원 표시와 출시 빌드는 실제 전체 영어 플레이 확인 후 별도 반영한다. Steam 심사 결과가 오면 해당 지적부터 처리한다.
4. 이미지 작업은 사용자가 뒤로 미뤘으므로 현재 번역 흐름에 섞지 않는다.

## 9. 작업 트리와 전달 파일

- 구현 커밋 후 실질 변경은 핸드오프 문서뿐이다. 검사에서 생긴 import 메타데이터 표시는 정리했다.
- 실제 ZIP: `tmp/MawangCastle-English-DAY01-10-20260920.zip` — **313,647 bytes (약 306 KiB)**.
- ZIP SHA256: `46125c9f8e2dcfdd9d3074fede7a4fb13eb1925e21c8d9bc0f4cce09031222df`.
- 한영 대조표: `tmp/story_english_delivery_20260920/dialogue-bilingual.html` — 검색 가능한 358개 대사.
- JSON 대조표·원문 검증용 JSON·영어 카탈로그·수정 파일·patch·검사기·생성기·README·SHA256 manifest를 포함한다. ZIP·캡처는 소스 커밋에서 제외했다.
- 패키지는 구현 커밋 직전에 생성했다. `validation.json`의 생성 시 HEAD는 기준 SHA이며 정확한 전달 바이트는 `SHA256SUMS.json`으로 확인한다.

## 10. 종료 체크리스트

- [x] Steam 반려 사유 수정·게시·재심사 제출 확인
- [x] 이번 358개 번역 작업분·게임 연결·직접 검사 완료
- [x] 원문 보존·ZIP 압축 해제·파일 무결성 검증
- [x] 전체 영어화와 현재 부분 완료를 구분
- [x] 검수 대상 구현 SHA 기록
- [x] 의도한 소스·도구·검사 파일만 커밋
- [x] CURRENT의 현재 상태·다음 작업 갱신
- [ ] 원격 푸시 및 PR 상태 확정
