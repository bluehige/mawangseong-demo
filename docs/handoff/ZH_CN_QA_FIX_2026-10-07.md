# 간체 로컬 후보 — 검수 지적 수정

WORKSTREAM_ID: ZH_CN_QA_FIX_20261007

## 1. 메타데이터

- 작성일: 2026-10-07.
- 목표 버전: 승인 1.2.9 기반 미게시 간체 후보. 새 SemVer: NOT_ASSIGNED.
- 작업트리: 사용자 지정 실제 원본 `tmp/uiux_v2`. 이 세션만 제품 writer이며 검수 에이전트를 새로 실행하지 않았다.
- 브랜치: `codex/v129-build-approval-status`; 기준 main/origin/main/HEAD 및 마지막 커밋: `b06be967aa763199ac631729eb65cacbe9489c26`. 기존 ahead 1은 이번 커밋이 아니다.
- 승인 제품: `v1.2.9` / `4076e099202f440c85a30699268d1c887c26c903`; Build25450324 / Manifest1103993226303809008.
- 권위 정책·CURRENT는 `git show main:...`로 다시 읽었다. 로컬 main/origin/main은 일치한다. 원격 최신성은 같은 날 부모 감사 근거를 이어받았으며 이 세션의 fetch/원격 재조회는 없다.
- 원격 push/PR/태그/Steam 변경: 없음. Git 관리 영역은 이전 세션에서 읽기 전용이 확인됐으며 새 권한 변경이나 재시도 없이 미커밋 전달한다.
- 최종 소스 지문 SHA256: `3fb94fed82dbf4dfd95f0651f03aca95f930e7379728e8eafbc16059b3d2fd8c`. `tmp/zh_cn_fix_20261007/source-manifest.json`의 40개 파일, handoff 문서 제외. Git SHA가 아니다.
- 이전 후보 소스 지문 `c9b2981c9dcb6e4423fa65e269710be1cdc8fad0eb32bd1ba7c5e5c6041f3ad5`와 이전 후보 폴더/ZIP 2개는 그대로 보존했다.

## 2. 이번 세션 목표

사용자의 “검수결과들 토대로 수정진행해” 승인에 따라 추가 화면 검수 보고서의 6종을 간체에서 고치고 DAY/Stage/Lv도 자연스러운 간체 표시로 통일한다. 동일한 노출 조건을 정확 720p·1080p에서 재검수하고 한영 회귀와 실제 후보 EXE 부팅을 확인한다. 전체30일 자연 플레이, 새 버전 결정, 공개 push, Steam 업로드/default/지원 언어 공표/출시는 범위 밖이다.

## 3. 완료한 작업

| 지적 | 수정 | 동일 조건 재검수 |
|---|---|---|
| ZH-QA-01: 발견 엔딩 상태의 한글 발견 | 간체 보조 카탈로그에 已发现 연결; 원문·E00–E22 코드·발견 기록 보존 | 발견 상태23개, 목록6스크롤 위치·E00 상세, 두 해상도 PASS |
| ZH-QA-02: LIVING CASTLE / HEART COVENANT | 活体城堡 / 城心契约 | 심장 선택 상단, 두 해상도 PASS |
| ZH-QA-03: hunger | 饥饿值; 패시브·충전원·관련 설명의 표시 문구만 교정 | 吞噬之心의 두 설명 줄 실픽셀 PASS. 충전원 문구는 카탈로그/placeholder 검사; 별도 충전원 HUD 노출은 미실행 |
| ZH-QA-04: Compact/Standard | 紧凑布局 / 标准布局; 설정 placeholder에 번역된 표시 이름 전달 | 두 레이아웃 각각, 두 해상도 PASS |
| ZH-QA-05: TUT_* 표시 | 기존 단계 ID에 대응하는 간체 tutorial.heading 문구를 표시 | 12단계 이름/본문, 실제 Next·Return 핸들러 PASS; 실제 ID와 연습 저장 불변 |
| ZH-QA-06: 전투 보조 줄 높이6 | 간체 동적 status의 예약 영역414×50 유지, 문구 변경 때 폰트 맞춤 재실행 | 실제 전투를 정지한 目标 · 尖刺走廊 및 자연 전투 중 目标 · 探险者, 두 해상도 PASS |
| DAY/Stage/Lv | 第n天 / 第n阶段 / n级; 숫자 전용 HUD도 간체에서만 처리 | 관리 DAY1/30·성 단계·몬스터 레벨·DAY30 대사 제목·튜토리얼. 코드 ID/사용자 이름 보호 검사 PASS |

기존 실제 번역 문장의 용어·숫자 표시 566곳을 교정했다. 전체 문장을 문자 치환으로 새로 번역한 것이 아니다. 원문 키·순서 있는 printf·named placeholder는 그대로이며 주요 UI5344, 설정142, 대사1741, 제목216, 화자39, story UI9의 분모가 유지된다. 보조 항목은2→6으로 늘어 대조 슬롯은7493→7497이다. 감사 중복제외 주요 원문7288과 대조 슬롯은 별개다.

잘림 원인: status가 초기에는 비어 있어 수직 정렬 함수가 영역을6으로 축소했고, 대상 문구가 나중에 갱신돼도 원래50 영역으로 돌아오지 않았다. 간체 전투 정보창에만 예약 영역과 동적 재맞춤을 적용했다. 두 문구의 실제 내용 높이27/영역50, 표시 픽셀을 확인했다. 한영의 기존 문구·배치는 이전 후보와 동일하게 보존했다.

스토리 규칙·캐릭터 말투·밸런스 수치·저장 schema·개인 이름·단축키·실제 데이터 ID는 변경하지 않았다. ko/en 카탈로그는 byte 동일, 설정 ko/en 객체·폰트·project 설정도 보존했다.

## 4. 변경 파일

최초 후보 대비 이번 수정은 다음12경로다. 전체 누적 후보 소스는40파일이며 정확한 해시는 source-manifest.json에 있다.

| 경로 | 목적 | 상태 |
|---|---|---|
| `scripts/core/EnglishTranslation.gd` | 간체 숫자 전용 날짜/단계/레벨 표시, 코드·사용자 이름 보호 | 검사 통과 |
| `scripts/core/LanguageSettings.gd` | 간체 이름+레벨 조합 | 검사 통과 |
| `scripts/game/GameRoot.gd` | 설정 레이아웃 표시, 튜토리얼 의미 문구 | 실제 화면 통과 |
| `scripts/ui/HUDController.gd` | 간체 전투 동적 보조 문구 영역/맞춤 | 실제 화면 통과 |
| `data/localization/ui_zh_cn.json`, `story_zh_cn.json`, `v122_stage10_ui.json` | 잔재와 표시 용어 교정 | 키·토큰·glyph 통과 |
| `tools/tests/ChineseCatalogTest.cjs`, `ChineseLocalizationTest.gd` | 보조 카탈로그·표기·이름·숫자 조합 회귀 | 통과 |
| `tools/localization/BuildChineseReviewPackage.cjs` | 새 출력 경로·7497슬롯·대표 이미지·최신 검수 범위 | 구문/생성 통과 |
| `docs/localization/ZH_CN_GLOSSARY_2026-10-07.md`, `ZH_CN_LOCAL_CANDIDATE_2026-10-07.md` | 표기 규칙·최신 후보 진입점 | 갱신 |
| `docs/handoff/CURRENT.md`, 이 문서, 최초 후보 handoff 주석 | 종료 기록 | 갱신 |

## 5. 그래픽 및 오디오 자산

- 이번 수정의 이미지 생성/편집/교체·오디오 변경: 없음.
- 이전 후보 PCK와 새 PCK의 assets·imported resource·게임 데이터·영문 카탈로그3002개 엔트리의 크기/MD5가 동일하다. 이전 실제 픽셀 검수1301개 PCK 이미지 및 중국어 마케팅8파일의 보존 근거이며, 이번에1301개를 다시 픽셀 전수검수했다고 주장하지 않는다.
- 이번 수정 화면58개는 실제 픽셀로 확인했다. 추가 실제 EXE 타이틀과 DAY30 대사도 정확1920×1080으로 확인했다. 캡처/연락판은 ignored tmp에만 있다.
- 최초 이미지 원본/SOURCE.md/최종 마케팅 파일은 그대로 보존했다. 새 다운로드·폰트 설치·라이선스 수락·외부 API·결제·Library 전송 없음.

## 6. 테스트 및 검수

근거는 `tmp/zh_cn_fix_20261007/`에 있다. Godot4.6.3, GPU호환 모드,100%글자 크기, 격리 APPDATA/LOCALAPPDATA/TEMP를 사용했다. 이 세션의 엔진은 한 번에 하나만 실행했고 다른 게임 프로세스는 조작하지 않았다.

| 검사 | 결과 | 근거 |
|---|---|---|
| ChineseCatalogTest | PASS: UI5344·설정142·cues1741·titles216·speaker39·UI9, 빈값/한글/키/ID/토큰·표기 검사 | `catalog_test.json` |
| EnglishTranslationTest / UIEnglishFormattedTest / StoryEnglishRuntimeTest / V122Stage10LocalizationTest | PASS16 / 958 / 26 / 45 | 각 테스트 log |
| ChineseLocalizationTest | PASS1843검사·1794glyph; 언어 전환/저장/취소·커서/read-state·사용자 이름·코드/숫자 표시 | `ChineseLocalizationTest.log` |
| 새 후보 PCK, 정확1280×720 | PASS29표적 화면·965텍스트 기록·0문제 | `packed_zh_CN_720/report.json`, PNG |
| 새 후보 PCK, 정확1920×1080 | PASS29표적 화면·965텍스트 기록·0문제 | `packed_zh_CN_1080/report.json`, PNG |
| 한영 이전 후보/새 후보 실행 비교,720p | 각29조건 실행; 시간 변화 전투 화면1개를 제외한28고정 화면/935기록의 텍스트·좌표·크기 차이0 | `ko_en_runtime_comparison.json` |
| export·ChinesePackTest | PASS3389엔트리·카탈로그5개 소스byte 동일·금지 경로0 | `windows_export.log`, `pack_verification.json` |
| 실제 새 후보 EXE 기본 타이틀 부팅 | exit0·정확1920×1080 간체·20프레임 | `exe_boot/title00000019.png`, stdout/stderr log |
| DAY30 대표 대사 제목/본문 | PASS·정확1920×1080·카탈로그 바인딩/본문 영역 확인 | `preview/preview.json`, PNG |
| 한영 원본·승인6·이전후보7·이전ZIP2 보존 | SHA256/크기 일치. pack자산/게임 데이터3002엔트리 동일 | `preservation.json`, `pack_resource_preservation.json` |
| 번역 대조 문서·diff--check | PASS7497슬롯/5대표이미지·Node구문·공백 검사 | `review_package/`, 기록 |
| 전체 회귀/30일 실제 완주/검수 에이전트 | NOT_REQUESTED, 미실행 | 이 기록 |

보고서의 화면은 엔딩 발견23개·DAY/성 단계·튜토리얼 초기 상태를 주입한 표시 검증이다. 전투의 대상 변경은 실제 시뮬레이션을 짧게 진행한 후 정지했으며 결과/승리를 주입하지 않았다. 해금·엔딩 달성·30일 자연 플레이와 동일하지 않다. 한영 비교에서 제외한 실시간 전투 화면은 HP/상태의 시간차가 있어서 임의 동등 판정을 하지 않았다.

검수 도구의 초기 실패는 수정해 재실행했다: 기존 테스트의 격리 경로 guard가 새 fix 경로를 거부한 것은 개인 save 접근 이전에 종료됐고 허용된 독립 경로를 추가했다. 추가 이름 fixture의 잘못된 고브를 실제 원문 곱으로 고쳤다. standalone check-only의 autoload 없는 환경·QA 타입 추론 문제는 실제 후보 wrapper 실행으로 해소했다. 환경의 root-certificate-store 경고는 남았으며 네트워크/제품 현지화 실패로 해석하지 않는다.

### 정책 CI용 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKING_COPY (위40파일 SHA256 지문)
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..UNCOMMITTED_WORKING_COPY
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

최종 지문 이후 제품·카탈로그·도구·localization 문서는 수정하지 않았다. handoff 문서와 ignored 전달 자료만 종료 기록으로 추가한다. 실제 Git SHA의 PR/정식 출시 승인으로 표시하지 않는다.

문장 안의 사용자 이름이 `DAY 30`인 경우에도 이름은 보존하고 다른 날짜만 변환하도록 보호 경계 검사2개를 추가했다. 이 최종 수정 뒤 관련 자동 검사, export/PCK 검사, 정확720p·1080p 화면, 한영 전후 비교와 실제 EXE 부팅을 다시 실행해 통과했다.

## 7. 미해결 항목과 위험

- 이번6지적과 표기 수정의 표적 재검수는 통과했다. 전 제품의 P1/P2 전수0건을 주장하지 않는다.
- 원어민 교열/말투/상점/홍보 승인0건, NotoSansCJK KR의 SC지역 자형 승인, 홍보 취향 승인과 새SemVer는 여전히 미완이다.
- 전체30일 자연 플레이·전 분기/엔딩 조건·전체회귀·Steam 실설치/Cloud2PC·성능/최저사양은 이번에 검사하지 않았다.
- 한영은 이번 수정 전/후 일치를 검증했다. 한영 원본의 모든 기존 잔재까지 고쳤다는 뜻이 아니다.
- Git 관리 영역 권한은 변경하지 않았다. 미커밋 소스 overlay와 patch로 전달하며 공개 Steam에는 반영되지 않았다.

## 8. 다음 작업 순서

1. 최신 `review_package/index.html`의7497슬롯과 대표5이미지로 원어민/지역 자형/홍보를 검토한다. 이전7493슬롯 패키지는 최초 후보 기록이다.
2. 새SemVer와 후보 채택/공개 범위를 확정한 뒤 허용된 Git writer가40소스+handoff 문서만 명시적 적용·커밋하고 실제SHA의 필요한 관련 검사를 기록한다.
3. Steam 업로드/default/지원 언어/출시 및 공개 push는 별도 명시적 승인 후 수행한다. 사용자 확정10월8일 출시와 후보 채택을 구분한다.

## 9. 작업 트리 상태 및 전달

- 기존 혼합 변경을 보존했다. 최초 후보 대비12경로의 관련 수정, 누적40소스+handoff3문서가 미커밋이다. stash/새worktree/commit/push 없음.
- 새 후보: `tmp/zh_cn_fix_20261007/windows_candidate_fixed/`.
- PCK584252616bytes; SHA256 `4cbd9ea1538b3e17a250c27fd66521a70a5919db6f23c0bda2dcc51686e2dc6c`.
- EXE104699392bytes; SHA256 `da91956741a557d45fa748ed68bbb865fdf8d8dc2b144d952c0538e0f37e9cde` (승인 EXE 그대로).
- `source-manifest.json`, `source_overlay/`, `tracked-source.patch`, 후보 `candidate-manifest.json`에 콘텐츠와 해시를 기록했다.
- 최신 대조 문서 `review_package/`; 상세 수정/캡처 `REPORT.md`, `index.html`. 최종 전달 ZIP은 `MawangCastle-zhCN-QA-final-Windows-20261007.zip` 및 `MawangCastle-zhCN-QA-final-review-source-20261007.zip`이며 크기·해시는 `delivery-manifest.json`에 기록한다. 중간 `QA-fixed` ZIP은 최종 전달물이 아니다.
- 개인 저장 경로는 읽거나 쓰지 않았다. 직접 EXE를 실행하면 개인 프로필이 쓰이므로 수동 검토는 후보의 `RunIsolated.ps1`을 사용한다.

## 10. 종료 체크리스트

- [x] 확인된6지적·DAY/Stage/Lv 수정 완료
- [x] 관련 자동 검사·정확720p/1080p·실제 EXE·한영 전후 일치 확인
- [x] 승인 출시·이전 후보/ZIP·개인 save 보존
- [x] 실행/미실행 범위·원어민/지역 자형 미완 기록
- [x] CURRENT 최신 후보 링크 갱신
- [ ] 원어민/SC/홍보/새SemVer 승인
- [ ] 실제 최종 Git SHA 커밋·정책 검사
- [x] 공개 push·Steam·태그·출시 미실행
