# DAY 1–30 전체 영어화 및 이미지 글자 정리

## 1. 메타데이터

- 작성일: 2026-09-21
- 목표 버전: 공개 v1.2.7 이후 영어화 작업분. 새 버전·태그·출시 없음.
- 작업 브랜치: `codex/content-english`
- 기준 브랜치 및 SHA: `main` / `df9b4f886806c960e15431a5e2a15ffe7373c0ee`
- 마지막 구현 커밋 SHA: `5386ade59c2f5b8ff51126aeb42e0a060c05725c`
- 원격 푸시: 이 핸드오프 커밋과 함께 `origin/codex/content-english`에 반영하는 단계. 최종 도구 결과로 확인.
- 관련 PR: [#100](https://github.com/bluehige/mawangseong-demo/pull/100)
- 작업 디렉터리: `C:/Users/blueh/Desktop/진행중인프로젝트/codex/마왕성/tmp/uiux_v2`
- WORKSTREAM_ID: `CONTENT_ENGLISH_FULL_DAY01_30`

## 2. 목표와 완료 조건

사용자가 요청한 DAY 30까지 전체 콘텐츠와 이미지 글자를 확인하고, 부분 번역 패키지를 전체 영어화 패키지로 확장한다. 원문·ID·치환값 보존, 실제 영어 화면, 전체 대사 표시, 영문 스토어 자산, 검증 가능한 ZIP을 완료 기준으로 삼았다.

Steam 심사 수정은 이전 세션에서 끝났다. 이 세션에서는 상점·언어 지원 체크·출시 빌드·태그를 변경하지 않았다.

## 3. 완료한 작업

- 스토리: DAY 1–30 **1,741개 대사 / 216개 장면 제목**, 승패·선택 분기 포함.
- UI: 스크립트·씬·데이터 원문 **5,334개** 전체를 포함하는 영어 항목 **5,344개**. 개발 진단 문구도 포함한 수치다.
- 표시 계층: 네이티브 Translation 리소스, 치환된 문자열·문단·동적 조합, 직접 그리는 글자와 영문 폭 계산.
- 배치: 진화·원정·선택 카드, 전선·심장 제목, 영어 의회 지역 카드의 스크롤 배치, 긴 DAY 제목과 안내.
- 저장: 한국어 원본·ID·세이브 형식 유지. 기본 이름은 원문으로 저장하고 사용자 이름은 그대로 표시. NPC와 같은 이름을 쓰더라도 NPC 번역을 막지 않는다.
- 용어: 동료·시설·적·기술·지역·최종 선언 대조 및 통일.
- 밸런스·오디오: 변경 없음.

## 4. 변경 파일

| 경로 | 목적 |
|---|---|
| `data/localization/story_en.json`, `ui_en.json` | 전체 영어 번역 |
| `scripts/core/EnglishTranslation.gd`, `LanguageSettings.gd` | 표시 번역·언어 전환 |
| `scripts/game`, `scripts/story`, `scripts/ui`, `scripts/map`, `scripts/units`의 해당 변경 파일 | 이름 보존·대화·직접 그리는 글자·영문 배치 |
| `scenes/ui/screens/{Front,Heart,Region}SelectionScreen.gd` | 영문 카드 가독성 |
| `tools/localization/`, `tools/tests/*English*`, `tools/BuildStoryEnglishPackage.cjs` | 수집·검사·전달 도구 |
| `tools/release/generate_steam_graphics.py` | 승인된 영문 로고를 기존 캡슐 레이아웃에 출력 |
| `docs/localization/FULL_ENGLISH_AUDIT_2026-09-21.md` | 구체적 검증 범위·근거·예외 |

## 5. 그래픽 및 이미지 글자

- GPT 내부 이미지 생성으로 영문 로고 수정. 모델: GPT internal image generation.
- 원본·프롬프트·후처리: `assets/source/imagegen/steam_english_title_v127/SOURCE.md`.
- 결과: `marketing/steam/english/` — 투명 로고와 영문 캡슐 6종. 기존 한국어 자산 보존.
- 로고 알파·글자·규격 확인. 기존 코드 기반 출력 시 미세한 투명 픽셀 때문에 글자가 작아지는 문제를 가시 알파 경계로 보정했다.
- `assets/ui` 90개 직접 확인, 추가 글자 후보 이미지 5개 직접 확인. 기타 런타임 1,211개 경로/참조 조사. 모든 1,211장을 픽셀 단위 전수 확인했다고 주장하지 않는다.
- 기존 영문 홍보 이미지 제작·업로드 기록 확인. 현재 `promo_english.png` 재사용.
- ZIP에 실제 1080p 영어 게임 캡처 6장 포함. 생성 그림이 아닌 촬영 산출물로 소스 브랜치 밖에 보관한다.

## 6. 검증

| 검사 | 결과 |
|---|---|
| 대사 카탈로그 | PASS: 1,741개 / 216장면 |
| UI 카탈로그 | PASS: 원문 5,334개, 영문 5,344항목 |
| UI 치환 형식 | PASS: 958개, 누락 0 |
| 번역 동작 | PASS: 16개 |
| 스토리 표시·이름·진행 보존 | PASS: 26개 |
| 기존 설정·이름·튜토리얼 | PASS: 42개 |
| 기존 스토리 연결 | PASS: 58개 |
| 모든 분기 대사 실제 표시 | PASS: 1,741개, 넘침 0 |
| 실제 화면 73개 | PASS: 720p·1080p, 각 3,739개 표시 문자열, 누락·잘림 0 |
| PCK 내보내기와 독립 로딩 | PASS: 전체 번역 포함 및 네이티브 번역 동작 |
| 영문 이미지 | PASS: 7개 규격·알파·육안 확인 |
| ZIP 재압축 해제 | PASS: manifest 97개 파일의 길이·SHA256 일치 |
| 압축 해제본 검사기 | PASS: 스토리/UI 양쪽 |
| 기준 커밋 패치 | PASS: 임시 index에 기준 SHA를 읽고 `git apply --cached --check` |
| 전체 회귀·모든 캠페인 경로 완주·독립 전체 코드 검수 | NOT_REQUESTED |

로그는 `tmp/full_english_validation/`, `tmp/full_english_validation_1080/`에 있다. 보조 에이전트는 읽기 전용 번역 제안·용어·이미지 자료 조사만 수행했고 구현 writer는 한 명이었다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 5386ade59c2f5b8ff51126aeb42e0a060c05725c
- Review range: df9b4f886806c960e15431a5e2a15ffe7373c0ee..5386ade59c2f5b8ff51126aeb42e0a060c05725c
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 전달 파일

- ZIP: `tmp/MawangCastle-English-DAY01-30-20260921.zip`
- 크기: **25,236,693 bytes** (약 24.1 MiB)
- SHA256: `217baa854ac6ca5efe50325fd8d821a3d977793a47a50ccea4b42063d55297ba`
- 대사 HTML: `tmp/english_full_delivery_20260921/dialogue-bilingual.html` — 1,741개 원문·영문·ID 검색.
- UI 대조: `tmp/english_full_delivery_20260921/ui-bilingual.json`.
- 98개 파일, 원본 JSON·바이너리 이미지 포함 Git 패치·영문 자산·검사기·manifest 포함.
- 실행 파일·엔진·오디오·개인 저장 파일 제외. 검사용 PCK는 배포물로 공개하지 않았다.
- 이전 DAY 1–10 ZIP과 358개 대조표도 보존했다. 현재 전체 패키지가 최신이다.

## 8. 제한·다음 단계

- 기존부터 깨진 격리 자산 사유 4개는 게임에 표시되지 않는 개발 메모로, 원문 보존 후 번역 검사에서 제외했다.
- 영어 선택 UI의 `한국어` 표기 및 사용자 입력 이름은 의도적으로 남긴다.
- 새 PR 커밋의 repository-policy를 확인하고, 사용자가 릴리스/Steam 영어 빌드 공개를 요청하면 해당 출시 절차로 이어간다.
- main 병합·Steam 영어 지원 체크·새 빌드 업로드는 이 작업에서 실행하지 않았다.
- 구현 커밋 뒤 변경은 핸드오프 문서뿐이다. 루트의 다른 작업트리는 수정하지 않았다.
