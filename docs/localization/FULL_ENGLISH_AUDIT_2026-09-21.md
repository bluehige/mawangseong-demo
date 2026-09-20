# 전체 영어화 검증 기록 — 2026-09-21

작업흐름: `CONTENT_ENGLISH_FULL_DAY01_30`. 공개 v1.2.7 이후 영어화 작업이며 새 제품 버전·출시 태그를 만들지 않았다. 구현 브랜치 `codex/content-english`, 기준 `df9b4f886806c960e15431a5e2a15ffe7373c0ee`.

## 범위와 구현

- DAY 1–30 원문 대사 **1,741개**, 모든 승패·선택 분기를 포함한 장면 제목 **216개**를 ID 기준으로 연결했다. 원본 `data/story/v122_main/day_*.json`은 변경하지 않았다.
- 스크립트·씬·JSON에서 수집한 원문 **5,334개**를 모두 덮는 UI 카탈로그 **5,344개**를 구성했다. 이 수치는 개발용 진단 문자열도 포함하며, 화면 수를 뜻하지 않는다.
- Godot Translation 리소스가 표시 단계에서 원문 및 치환된 문구를 번역한다. 게임 규칙·ID·원문 모델·세이브 스키마는 바꾸지 않았다. 기본 이름은 저장할 때 원문을 유지하며, 사용자 지정 이름은 대화에 그대로 표시한다.
- 직접 그리는 전투·맵 글자와 글꼴 크기 계산도 영어 표시를 사용한다. 영문이 길어지는 진화·원정·선택 카드, 심장·전선 제목, 의회 지역 카드 및 DAY 안내 배치를 조정했다. 지역 카드는 영어에서 스크롤로 전체 내용을 확인한다.
- 이름·시설·기술·지역·마지막 선언의 용어를 대조해 통일했다. 전투 로그, 대화 기록, 기록 하위 탭, 상층·전초기지·의회 UI를 포함한다.

## 실행한 직접 검증

Godot 4.6.3, OpenGL 호환 렌더러, 격리한 APPDATA를 사용했다. 종료 코드 0과 로그를 확인했다.

| 검사 | 결과 |
|---|---|
| StoryEnglishCatalogTest.cjs | PASS — 원문 ID·누락·중복·치환문자·장면·화자, 1,741개 |
| UIEnglishCatalogTest.cjs | PASS — 원문 5,334개 전체 포함, 원문 키 중복·한글 잔존·치환문자·깨진 문자 검사 |
| UIEnglishFormattedTest | PASS — 실제 값으로 치환한 형식 958개, 누락 0 |
| EnglishTranslationTest | PASS — 16개 사례: 중첩·수치·기록·선택 문구·한국어 복귀 |
| StoryEnglishRuntimeTest | PASS — 26개: 대사·피드·기록·진행 보존·기본 저장 이름·사용자 이름 |
| V122Stage10LocalizationTest | PASS — 42개, 이름 입력·설정·튜토리얼 영어/한국어 전환 |
| V122StoryRuntimeIntegrationTest | PASS — 58개, 기존 스토리 연결 |
| FullEnglishRuntimeTest 대사 | PASS — 216개 장면의 모든 1,741개 대사를 실제 대화창에 표시, 넘침 0 |
| FullEnglishRuntimeTest 화면 | PASS — 73개 화면/상태, 최종 720p·1080p 각 표시 문자열 3,739개, 누락·잘림 0 |
| Windows Desktop PCK 내보내기 | PASS — 최종 소스에서 내보내기 성공 |
| 독립 PCK 로딩 검사 | PASS — 대사 1,741·제목 216·UI 5,344 항목 존재, 네이티브 번역 동작 |

화면 검사는 모든 DAY의 관리 화면, 전투 준비·실제 전투·승패, 동료 성장·원정·기억·엔딩, 전선·심장·합동기, 지역 상·하단, 기록의 모든 하위 탭, 상층, 전초기지 전투·승패, 설정을 포함한다. 자동 검사 외에 캡처를 직접 확인해 제목/설명 간 겹침을 수정했다.

이 검증은 **영문 콘텐츠와 표시 검수**다. DAY 1부터 30까지의 모든 선택 조합을 정상 플레이로 완주한 밸런스 검수나 저장소 전체 회귀 검수는 실행하지 않았다.

로그·캡처: `tmp/full_english_validation/`, `tmp/full_english_validation_1080/`.
최종 화면 보고서: 각 폴더의 `runtime_report_views.json`. 전체 대사 표시 기록: `tmp/full_english_validation/runtime_report.json`.
배포 포함 검사: `export_pack.log`, `pack_smoke.log`.

## 이미지 글자 조사와 산출물

- 기존 기록 `docs/handoff/V127_ENGLISH_PROMO_RATING_2026-09-14.md` 및 `V127_STEAM_SUBMISSION_2026-09-14.md`에서 영문 홍보 그림 제작·업로드 완료를 확인했다. `marketing/steam/promo/promo_english.png`는 그대로 사용한다.
- `assets/ui` PNG **90개**를 접촉시트로 직접 확인했다. 패널·아이콘·배경·삽화에서 읽을 수 있는 한국어 텍스트는 발견하지 않았다. 게임 제목은 이미지가 아닌 Label이다.
- 그 밖의 런타임 이미지 **1,211개 경로**와 코드 참조를 조사했다. 글자 가능성이 있는 설명서·점검표·장부 초상화, 심장 소품, 연결 맵 후보 5장을 추가로 직접 확인했고 읽을 수 있는 언어 글자는 없었다. 1,211장의 모든 픽셀을 전수 육안 검사했다는 의미는 아니다.
- 한국어 Steam 로고를 GPT 내부 이미지 생성 도구로 영문 수정했다. 정확한 제목은 **Who Guards the Demon Castle?**. 원본·프롬프트·후처리는 `assets/source/imagegen/steam_english_title_v127/SOURCE.md`에 보존했다.
- 기존 코드 기반 캡슐 레이아웃으로 영어 로고 및 캡슐 **6종**을 `marketing/steam/english/`에 만들었다. 한국어 자산은 보존했다. 영문 글자와 로고 투명도·각 규격을 확인했다.
- 구 한국어 스크린샷 6장은 2026-07-15 v0.5 촬영본이었다. 영어 ZIP에는 최신 게임의 실제 **1920×1080 캡처 6장**을 넣는다. 현재 기능인 심장 선택을 다섯 번째 이미지로 쓰며 구버전 직접 조종 화면은 재사용하지 않는다. 촬영본은 AI 그림으로 고치지 않았고, 소스 브랜치의 생성 그림으로 등록하지 않는다.

## 명시적 예외와 배포 경계

- `data/dungeon_quarter/wall_asset_catalog.json`의 `quarantined_legacy_groups/*/reason` 4개는 기존부터 깨진 개발용 격리 사유다. 게임에 표시되지 않으므로 카탈로그 검사에서 제외하고 원문을 변경하지 않았다.
- 언어 선택 항목의 `한국어`와 사용자가 직접 입력한 한국어 이름은 의도적으로 유지한다.
- 원본 오디오·그래픽·밸런스 변경, main 병합·새 태그·Release·Steam 빌드 업로드 및 영어 지원 체크 변경은 하지 않았다.
- Steam 심사 수정은 이전 세션에서 완료했다. 이 작업의 완료가 스토어 심사 승인이나 영어 지원 빌드의 공개를 뜻하지 않는다.

## 재검증·전달

`tools/BuildStoryEnglishPackage.cjs`는 커밋된 구현에서 바이너리 이미지를 포함하는 Git 패치, 원문 JSON, 1,741개 대사 HTML 대조표, UI 대조 JSON, 원문 목록, 영어 Steam 자산 및 SHA256 목록을 만든다.
ZIP 압축 해제 후 두 Node 검사기·파일 해시·기준 커밋에 대한 패치 적용 검사를 별도로 실행한다. 실제 ZIP 경로·크기·해시는 최종 세션 핸드오프에 기록한다.
