# 간체 추가 로컬 후보 핸드오프

WORKSTREAM_ID: ZH_CN_LOCAL_CANDIDATE_20261007

후속 상태: 추가 화면·이미지 검수에서6종을 확인한 뒤 사용자 승인으로 [간체 검수 지적 수정](ZH_CN_QA_FIX_2026-10-07.md)을 완료했다. 최신 후보는 `tmp/zh_cn_fix_20261007/`, 대조7497슬롯/글리프1794종이다. 아래의 최초 후보40소스 지문·PCK·7493슬롯·검수는 당시 기록이며 이전 후보와 함께 보존한다.

## 1. 메타데이터

- 작성일: 2026-10-07.
- 목표 버전: 승인1.2.9 기반 미게시 간체 추가 후보. 새 SemVer: NOT_ASSIGNED. v1.2.9 태그·배포 바이너리 보존.
- 사용자 지정 실제 최신 원본: `tmp/uiux_v2`. 루트의 과거1.2.5 작업트리를 수정하지 않았다.
- 작업 브랜치: `codex/v129-build-approval-status` 그대로. 시작 때 선택 작업트리는 깨끗했고 이 세션이 유일한 제품 writer다.
- 기준 main / origin/main / HEAD / 마지막 커밋: `b06be967aa763199ac631729eb65cacbe9489c26`.
- 승인 제품: `v1.2.9` / `4076e099202f440c85a30699268d1c887c26c903`.
- 원격 최신성은 같은 날 부모의 읽기 감사 `tmp/zh_cn_audit_20261007/REPORT.md`에서 실제 GitHub main과 main/origin/main 일치 확인 근거를 사용했다. 이 writer가 새 fetch나 Steam 조회를 한 결과가 아니다. 권위 정책·CURRENT는 시작 때 `git show main:AGENTS.md`, `git show main:docs/handoff/CURRENT.md`로 읽었다.
- Steam 기준: App5267750 / Depot5267751 / Build25450324 / Manifest1103993226303809008. 사용자확정2026-10-08 출시와 이 후보 채택을 구분한다.
- 이번 커밋·브랜치·PR·태그·원격 push: 없음. Git 관리 영역 읽기 전용으로 브랜치 생성/index.lock 쓰기가 Permission denied로 실패했다. 권한 변경이나 이력 수정 없이 미커밋 전달한다.
- 검증 소스 지문(SHA256): `c9b2981c9dcb6e4423fa65e269710be1cdc8fad0eb32bd1ba7c5e5c6041f3ad5`. `tmp/zh_cn_work_20261007/source-manifest.json`의40파일과 개별 해시 기준, `docs/handoff/` 제외. Git SHA가 아니다.

## 2. 이번 세션 목표

승인 영문 UI·설정·DAY1–30 대사·제목·홍보 그림을 대조해 원문 의미·말투·기술명·placeholder를 유지한 간체를 실제 작성·연결하고 로컬 Windows 후보를 만든다. 기존 ko/en·저장·태그·배포를 보존한다. 외부 번역 서비스/키·폰트 설치/다운로드·결제/계정 권한 변경, Steam업로드/default/지원언어 공개/출시 클릭, Git공개push는 범위 밖이다. 전체 회귀·전체 플레이·검수 에이전트는 NOT_REQUESTED다.

## 3. 완료한 작업

- 구현: `zh_CN`, zh-CN/zh-SG/zh-Hans 정규화, zh-TW/zh-Hant 비지원 분리, 세 언어 선택/미리보기/취소/저장, 창 제목·스토리/화자/기록/툴팁 연결. 영어 Translation을 locale별로 일반화하고 다른 locale에 영어 fallback이 새지 않게 했다.
- 실제 작성: UI5344/5344, 영어 장식 제목2/2, 설정·이름·튜토리얼142/142, cues1741/1741, scene_titles216/216, speaker_labels39/39, story UI9/9. 감사 중복제외 주요 원문7288/7288과 전체 슬롯7493은 다른 분모다.
- UI4배치×1336, DAY1–15(618cues/92titles), DAY16–30(1123/124)를 독립 에이전트6명에게 scratch 번역만 맡겼다. 한국어 원문·영어·위치를 읽고 실제 문장을 작성했다. 제품 통합·엔진은 이 writer만 했다. 검수 에이전트로 계산하지 않는다. 깨진 진단은 읽을 수 있는 승인 영어와 위치를, title 없는 원문은 승인 영어 제목과 DAY를 의미 근거로 삼았다.
- 용어집·인명을 통일하고 瞭望哨/城堡之心/债务标记/挑战印章/约定再战/提议休战/撤退线 등의 배치 차이를 교정했다. 이미 작성한 문장의 명칭 통일이며 문자 치환으로 전체 번역을 생성한 것이 아니다.
- 기존 OFL Noto를 role 폰트와 직접 그리는 HUD/전투 글자에 연결했다. 영어 전용 확장 레이아웃을 비한국어에 적용했다. 빈 카드 툴팁 glyph89건과 중국어 visible-line rounding의 이름3개/시설제목1개 잘림을 수정했다.
- 밸런스·게임 규칙·원문·ID·수치·save schema·사용자 이름 변경 없음. ui_en/story_en byte동일, stage10 ko/en 객체 동일, font3개와 project 버전/기존 한영 상점 본문 보존.
- 별도 상점 후보: 제목·짧은 설명92자·본문·그림 대체 텍스트3개·홍보 글 작성. 기존 BBCode와 그림 그룹3개 참조 보존. 서버 저장/게시0건.
- Windows: Godot4.6.3 Windows Steam preset의 새 PCK + 승인 EXE 그대로 복사. `RunIsolated.ps1`은 독립 테스트 프로필을 사용한다. clean/tag release helper를 통과한 새 정식 출시 빌드로 표시하지 않는다.

## 4. 변경 파일

정확한40파일과 해시는 `source-manifest.json` / `source_overlay/`에 있다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/core/{LanguageSettings,EnglishTranslation}.gd` | 언어·카탈로그·fallback·스토리·제목 | 관련 검사 통과 |
| `scripts/ui/{UIFont,HUDController,UIUXTheme,ManagementWorkspaceUI}.gd` | CJK·툴팁·줄바꿈·레이아웃 | 관련 검사 통과 |
| `scripts/game/{GameRoot,CombatSceneController,ManagementSceneController}.gd`, `scenes/ui/screens/RegionSelectionScreen.gd` | 선택기·기록·그리는 글자·지역 화면 | 관련 검사 통과 |
| `data/localization/{ui_zh_cn,story_zh_cn,v122_stage10_ui}.json` | 실제 간체 연결 | 구조/표시 통과, 원어민 미승인 |
| `assets/fonts/README.md`, `docs/localization/ZH_CN_*2026-10-07.md` | 라이선스·용어·미완 교정 구분 | 완료 |
| `assets/source/imagegen/steam_chinese_*_local_candidate/` | 원본2개·출처 문서2개 | 보존 |
| `marketing/steam/schinese/`, `promo/promo_schinese.png` | 로고·캡슐7종·별도 promo | 규격/알파 통과, 취향 미승인 |
| `steam/store/*ZH_CN_CANDIDATE*`, `store_copy_schinese_candidate.json` | 미게시 문구 | 구조 통과, 원어민 미승인 |
| `tools/localization/BuildChineseReviewPackage.cjs`, `tools/release/GenerateSteamChineseGraphics.ps1` | 오프라인 대조·홍보 재현 | 완료 |
| `tools/tests/Chinese*`, `FullEnglishRuntimeTest.gd`, `V122Stage10LocalizationTest.gd` | 토큰·glyph·전환/저장·화면·PCK | 통과 |
| `docs/handoff/CURRENT.md`, 이 문서 | 후보 진입점 | 갱신 |

## 5. 그래픽 및 오디오 자산

- Generation model: GPT internal image generation. 영문 logo/capsule/promo를 실제 픽셀 확인하고 공개 홍보 참조/목적을 부모에게 보고한 뒤 wordmark와 promo를 생성했다. 내부 Windows 절대경로 형식 거절은 dispatch 전이었으며 이미 본 대화 이미지로 성공2건. 외부 서비스·키·배경 제거 없음.
- 원본·SOURCE.md: `assets/source/imagegen/steam_chinese_title_local_candidate/`, `steam_chinese_promo_local_candidate/`. 고정 모델/날짜/버전/원본/최종 경로, 프롬프트와 후처리를 기록했다.
- 최종: `marketing/steam/schinese/{store,library}/` 7PNG 및 `marketing/steam/promo/promo_schinese.png`. 게임 texture 교체가 아닌 홍보 sibling이다. 기존 한영 그림 보존. 최종 promo와 생성 원본은 byte 동일.
- 네이티브 Windows/.NET으로 visible-alpha bounds·비율·크롭·음영·로고 배치를 재현했다. 기존 승인 일러스트를 사용했다. 생성 wordmark915414픽셀/최종logo549240픽셀이 alpha0, 규격7종과 별도1672×941promo 통과.
- 눈으로 확인: 실제 제목·설정·몬스터·전투·지역·DAY30대화, 로고·작은/세로캡슐·promo. Runtime PNG1301개 전체를 이번에 픽셀 재감사했다고 주장하지 않는다.
- 오디오 변경/생성 없음. 표시 테스트는 Dummy audio.

## 6. 테스트 및 검수

엔진마다 APPDATA/LOCALAPPDATA를 작업 독립 프로필로 지정하고 한 번에 한 엔진만 실행했다. Godot4.6.3, GUI는 OpenGL3.3/NVIDIA RTX3060Ti다. 아래는 현지화 관련 표시 검증이며 전투 전체 플레이가 아니다.

| 순서 | 검사 | 결과 | 근거 (`tmp/zh_cn_work_20261007/`) |
|---:|---|---|---|
| 1 | ChineseCatalogTest | PASS: UI5344+보조2/설정142/대사1741/제목216/화자39/UI9. 키·ordered printf/%%/named tokens·빈값·잔존한글·raw중복 | `catalog_final.json` |
| 2 | EnglishTranslation / UIEnglishFormatted / StoryEnglishRuntime / V122Stage10Localization | PASS16 / 958 / 26 / 45 | 각 `*_final.log` |
| 3 | ChineseLocalizationTest | PASS1830검사/1793glyph. 별칭·사용자/기본이름·Native Translation·팝업 폰트·선택/취소/저장·role·binding·세 언어 cursor/read-state 보존 | `ChineseLocalizationTest_final.log` |
| 4 | 실제1280×720, 상태73 | PASS3740문자열/0문제 | `actual_720_final/runtime_report_views.json` |
| 5 | GUI1080p요청 창, 상태73+장면216/대사1741 | PASS5046문자열/1741cues/0문제 | `actual_1080_final/runtime_report.json` |
| 6 | 마지막 동길이16UI 기술명 교정 후 GUI재검사 | PASS73상태/3740문자열/0문제. story JSON 해시 동일 | `ui_1080_final/runtime_report_views.json` |
| 7 | ChineseGraphicsTest | PASS규격·실제alpha·promo원본 | `graphics_verification.json` |
| 8 | Export + ChinesePackTest | PASS3389엔트리/project.binary1539bytes/카탈로그5개 소스byte동일/묶음font·compiled script/금지경로0 | `windows_export_final.log`, `pack_verification.json` |
| 9 | 최종 별도 EXE+PCK 제목 부팅 | exit0, 정확1920×1080 간체 | `candidate_boot/final_pack_boot.log`, `final_title00000015.png` |
| 10 | 원본6파일·font·ko/en 보존, diff--check, HTML/launcher구문 | PASS | `approved_release_preservation.json`, `source-manifest.json` |
| 11 | 전체 회귀/전체 캠페인/검수 에이전트 | NOT_REQUESTED, 미실행 | 이 기록 |

해상도 정정: GUI의1920×1080 요청은 Windows 창 영역으로 실제1886×1061 캡처가 됐다.5~6번 PASS는 그 실제 크기에 적용한다.720p는 정확1280×720,9번 MovieMaker는 정확1920×1080이다.

관련 실패는 수정·재검증했다: 초기 const font 대입 parse오류를 alias로 수정, 첫720검사93문제(4잘림/89glyph) 수정→0건. 첫 export는 exit0이면서 공용TEMP project.binary 저장 오류를 남겨 작업 전용TEMP/TMP로 다시 만들고 내부 설정까지 확인했다. 첫 MovieMaker 상대출력 저장실패는 절대 작업경로로 고쳐 최종16PNG를 얻었다. promo 재인코딩은 원본그대로복사로 수정→보존검사PASS. 로그의 root-certificate-store 읽기 경고는 환경제약으로 남았으며 localization script오류/네트워크작업으로 해석하지 않는다.

### 검수 에이전트 및 정책 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKING_COPY (위 source SHA256 지문으로 콘텐츠 식별)
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..UNCOMMITTED_WORKING_COPY
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

이 결과는 정확한 지문의 로컬 관련 검사다. 새 Git SHA의 PR/출시 승인이 아니다. 허용된 writer의 실제 커밋 뒤40자리 Reviewed SHA/range와 필요한 검사를 기록해야 정책CI 완료 상태가 된다. 소스 지문 고정 후에는 handoff/CURRENT와 ignored 전달 산출물만 작성했다.

## 7. 미해결 항목과 위험

- 원어민 공식 승인0건. 전체7493슬롯과 상점/홍보, 인명·기술명·명령/수치`集中`/설명`集火`·농담·말투·후반 감정·분기 의미·제목 교정 미완이다.
- 기존 NotoSansCJKkr OFL glyph1793종과 표시 PASS. SC 전용패밀리 취득·지역 자형 전체 승인은 미완. 骨/令/直/门/关/这/述, 작은 UI 가독성을 중국어 독자가 확인해야 한다. 새 폰트 다운로드/라이선스 수락 없음.
- 로고·캡슐·promo 취향 승인 미완. 서버 설명 그룹3개의 간체 그림/대체텍스트와 공개 지원언어/본문 반영0건. 승인1.2.9에는 간체가 없다.
- Git `.git/worktrees/uiux_v2/index.lock` 쓰기 권한 장애로 미커밋. 자동 승인 리뷰 거절 사례가 아니다. 새 보안권한 없이 overlay/patch/해시로 전달한다.
- Library 현재 skill/prepared 공식도우미3개를 새 scoped폴더에 준비해 대표5이미지의 단일 요청을 실행하려 했으나 `python3: The term 'python3' is not recognized...`로 도우미 시작 전 실패. 부모 추가지시로 python/python3/py PATH, HKCU/HKLM등록·일반설치경로를 읽기 확인했으나 지원되는 기존 실행기를 찾지 못했다. 설치·직접전송·다른앱우회·재시도 없음. 확인된 Library ID0개.
- Steam계정·재심사·지원조건을 새로 조작/확정하지 않았다. 실제 Steam설치/Cloud2PC·전체플레이·성능/최저사양·Vulkan검사도 미실행이다.

## 8. 다음 작업 순서

1. `review_package/index.html`, 대표5PNG·용어집에서 원어민/SC자형/제목/홍보를 묶어 검토한다. 수정은 실제 대조ID·희망표현으로 전달한다.
2. 새 SemVer와 채택/공개 범위를 사용자 확정한다. 기존 승인1.2.9 출시와 간체후보 채택을 구분한다.
3. 허용된 Git writer에서 소스40파일+handoff2파일만 명시적 적용/커밋, 실제SHA의 필요한 관련 검사와 정책 필드를 기록한다. ignored 빌드/캡처/profile을 source에 포함하지 않는다.
4. 별도 명시적 승인 뒤에만 Steam지원언어/문구/그림/빌드/default/출시를 처리한다. 이 세션은 로컬에서 종료한다.

## 9. 작업 트리와 전달 파일

- 기존 승인-status브랜치[ahead1]은 시작 상태이며 이번 커밋이 아니다. source40+handoff/CURRENT2파일 미커밋.
- 정확 파일·해시 `source-manifest.json`, 기존 추적파일 patch `tracked-source.patch`, 완전한 변경파일 복사본 `source_overlay/`.
- 엔진의194개 추적.import는 baseline과 의미동일을 확인해 원래CRLF로 복원했다. 최종 source diff에서 제외. 부모 루트의 혼합변경/개인save 보존, stash/새worktree 없음.
- 후보 폴더 `tmp/zh_cn_work_20261007/windows_candidate/`, 소스 지문 포함 `candidate-manifest.json`, 독립 launcher `RunIsolated.ps1`.
- PCK584250248bytes, SHA256 `c0cc41c0e262fef3e292b85e5971dc7f7bc968b4f6e1665a33ff265e040b56b6`.
- 승인 EXE 재사용 SHA256 `da91956741a557d45fa748ed68bbb865fdf8d8dc2b144d952c0538e0f37e9cde`.
- 대표실제경로 `tmp/zh_cn_work_20261007/review_images/MawangCastle-zhCN-{title,settings,dialogue-DAY30,logo,small-capsule}.png`. `REVIEW_IMAGES.json`에 픽셀/해시/Library실패. 제목은 최종EXE1920×1080, 설정·대화1886×1061, logo1280×720 RGBA, 작은capsule462×174.
- 전체 대조 HTML/JSON·이미지5개 `tmp/zh_cn_work_20261007/review_package/`.
- ZIP `tmp/zh_cn_work_20261007/MawangCastle-zhCN-local-Windows-20261007.zip`, `MawangCastle-zhCN-review-and-source-20261007.zip`. 크기·해시는 ignored `delivery-manifest.json`에 기록하며 공개 push대상이 아니다.

## 10. 종료 체크리스트

- [x] 로컬 구현·실제 번역·font·카탈로그 연결 완료
- [x] 관련 검사·실제 화면·별도 후보 부팅·원본 보존 PASS
- [x] 미요청 전체회귀/플레이/검수 에이전트 미실행 명시
- [x] 원어민/SC자형/시각/공개 미완과 서로 다른 분모 구분
- [x] 생성 원본/SOURCE.md/최종 경로 기록
- [x] CURRENT후보 링크·다음 작업 갱신
- [ ] 원어민/SC/홍보 승인
- [ ] 새SemVer/실제최종GitSHA/PR정책검사 확정
- [ ] 의도한 파일만 커밋 (읽기전용으로 미실행)
- [x] push/Steam공개/tag/출시 미실행 기록
