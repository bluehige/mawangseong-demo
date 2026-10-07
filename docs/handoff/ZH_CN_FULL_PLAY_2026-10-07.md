# 간체 후보 DAY1–30 정상 플레이 핸드오프 — 2026-10-07

## 1. 메타데이터

- 작성일: 2026-10-07 UTC
- WORKSTREAM_ID: ZH_CN_NATURAL_FULL_PLAY_20261007
- 목표 버전: 승인1.2.9 기반 미게시 간체 후보, 새 SemVer NOT_ASSIGNED
- 작업 브랜치: codex/v129-build-approval-status (기존 ahead1 유지)
- 기준 브랜치 및 SHA: main / b06be967aa763199ac631729eb65cacbe9489c26
- 마지막 커밋 SHA: b06be967aa763199ac631729eb65cacbe9489c26 (이번 새 커밋 없음)
- 후보 식별: source40 SHA256 3fb94fed82dbf4dfd95f0651f03aca95f930e7379728e8eafbc16059b3d2fd8c / PCK SHA256 4cbd9ea1538b3e17a250c27fd66521a70a5919db6f23c0bda2dcc51686e2dc6c
- 원격 푸시 여부: 없음. local main/origin/main 동일. 이번 새 원격 조회 없이 당일 감사의 remote main 일치 증거 사용
- 관련 PR 또는 태그: 기존 v1.2.9@4076e099202f440c85a30699268d1c887c26c903 보존; 새 PR/태그 없음

## 2. 이번 세션 목표

- 요청 사항: 동결 간체 후보를 실제 정상 새 게임 DAY1–30 전체 플레이한 뒤 보고. 상태/보상/승리 강제 변경 없이 한 경로를 끝까지 진행
- 완료 조건: 30/30일 도달, DAY29 정상 준비, DAY30 실제 승리/엔딩과 일별·저장/복원·선택·성장·자원·픽셀 증거
- 범위에서 제외한 사항: 제품/밸런스/번역 수정, 모든 분기/23엔딩, 패배/재도전 경로, 후일담/NG+, 청취, 전체 한영 캠페인 회귀, 별도 검수 에이전트, Steam/공개 Git 조작

## 3. 완료한 작업

- 구현: 제품 수정0. ignored tmp의 수동 관측/일반 입력 도구와 증거 보고서만 작성
- 스토리 및 데이터: 정상 이름 阿斯特 새 게임, 튜토리얼/전날10대사/선언 castle_oath, 30일 경로 완료. DAY4 표지판·DAY16 정찰·DAY18 장부위조·DAY28 최종 정찰을 UI로 선택
- 밸런스:29회 방어 승리/0패배/0재도전, 모든 결과 왕좌 피해0/3명 생존. DAY15/20/27 정상 확장. 이 유리한 한 경로는 난이도 전체 평가가 아님
- UI/UX: DAY1–30 도달·결과와 실제1280×720 PNG544장 기록. 대표18장 연결. P2 한글 잔재3유형+닫기/확대 겹침1유형 OPEN; 수정하지 않음
- 저장 및 호환성: DAY2 두 번/DAY6/DAY12/DAY25 두 번 정상 Continue6회에서 날짜·이름·자원·튜토리얼·왕좌 복원 대조 PASS. 최종 정상save에 campaign completed/final preparation/victory/ending E02 저장 확인. 개인 save 읽기/쓰기0
- 완료 엔딩: 铁壁魔王要塞, ID impregnable_demon_citadel, E02, 표시1/23. 최종 왕좌2500/2500, 마물3/3, 금화13543/마력2024/식량155/악명2891

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| docs/handoff/ZH_CN_FULL_PLAY_2026-10-07.md | 정상 완주·미해결 지적·한계 인계 | 완료 |
| docs/handoff/CURRENT.md | 새 완주 진입점/다음 결정 | 완료 |
| tmp/zh_cn_full_play_20261007/ | observer/일반 UI 입력, 실제544 PNG, events/observations, 정상save, 일별표, 보고/보존 확인 | ignored 로컬 증거 |
| 제품 기존40파일 | 이전 후보 작업의 미커밋 변경을 동결; 이번 쓰기0/해시 대조 | 보존 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 이번0회
- 생성 모델/원본/SOURCE.md/런타임 자산: 이번 신규 자산 없음; 이전 간체 graphics와SOURCE 문서40파일 지문에 포함해 보존
- 후처리/크롭/알파: 없음
- 게임 연결 및 실제 렌더: 정상 게임의 대표 화면/최종 결과/엔딩1280×720 픽셀 확인. 전체544장 사람 전수 검수는 아님
- 오디오: Dummy driver, 청취 검수 없음

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | 공식 Godot4.6.3 + 동일최종PCK, 정상 Main/UI InputEvent 새 게임→DAY30 | PLAYTHROUGH_COMPLETE:30/30일·29승·0패·E02 | tmp/zh_cn_full_play_20261007/REPORT.md, day-ledger.json/.csv, events.jsonl |
| 2 | 정상 Continue6회, 이전 STOP와 복원 자원/날짜/이름/단계/왕좌 대조 | PASS | reload-verification.json |
| 3 | 실제 화면 및 동적 텍스트/닫기 재현 | FAIL_OPEN_P2:4유형 | issues.json, EVIDENCE_INDEX.md, captures/ |
| 4 | Node BuildEvidence.cjs |30개 결과/544개PNG규격·해시/결과/최종save 대조 완료 | PLAY_REPORT.json, capture-manifest.json |
| 5 | Node VerifyPreservation.cjs | PASS:40소스/후보8/승인6/이전후보7/기존ZIP4 | preservation.json |
| 6 | 전체 자동 회귀·별도 검수 에이전트 | NOT_REQUESTED/미실행 | 이번 요청은 전체 실제플레이만 |

### 검수 에이전트 반복 기록

별도 검수 에이전트는 요청되지 않아0명이다. 본 단일 writer가 제품 동결 상태에서 요청된 실제 플레이만 수행했다.

- 남은 P1/P2 지적: P1 0 / P2 4유형 OPEN. 개별 문자열 수의 분모는 아님
- 실행 제약: 출시 EXE는 observer --script를 지원하지 않아 부팅만 하고 안전 종료. 동일PCK를 공식 동일버전 Godot에서 플레이. 출시 EXE 직접30일 자동화 결과와 구분
- editor feature의 FirstPlayObservationRecorder는 ignored tmp 관측만 추가; game.rules 변경 없음. qa actions/state injection 사용0
- source/product/script/data/balance/save 직접 편집0. 검수 후 변경은 docs/handoff 및 ignored 증거뿐

### 정책 CI용 최종 승인 필드

- Review task ID: ZH_CN_NATURAL_FULL_PLAY_20261007 (단일 writer 실제 플레이; separate review agent NOT_REQUESTED)
- Reviewed SHA: b06be967aa763199ac631729eb65cacbe9489c26
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..b06be967aa763199ac631729eb65cacbe9489c26
- Remaining P1/P2: 0 / 4
- Final review result: FAIL (PLAYTHROUGH_COMPLETE, OPEN_P2; 출시 승인 PASS 아님)

이 Git SHA만으로 미커밋 후보를 특정할 수 없으므로 위 소스40 지문/PCK SHA256/manifest가 필수다. P2가 남아 있어0/PASS로 기록하지 않았다. 이전 QA의 TARGETED_PASS는 그 이전 표적 범위 기록으로 보존하며 이번 자연 경로 품질을 대신하지 않는다.

## 7. 미해결 항목과 위험

- NATURAL-ZH-01/P2: 배치/경로 동적 summary에 핀 Lv.1 외1명·탐험가·수련생 용사 잔재
- NATURAL-ZH-02/P2: 시설 연결 효과/보물방 경고 한글 잔재
- NATURAL-ZH-03/P2: 방drawer Close 중앙이 ZoomIn과 겹침. DAY25 올바른 motion/wheel 입력으로 재현. 정상Escape 우회 가능
- NATURAL-ZH-04/P2:2단계 측문 복도 이름이 전투지도/결과에서 한글
- 보장하지 않은 범위: 원어민 교열·SC 지역자형·홍보승인·모든분기/엔딩·다른 원정/선언·패배/재도전·후일담/NG+·전체 한영회귀·청취·모든해상도
- 환경 로그: root-certificate-store 오류 반복, virtual-keyboard unsupported 경고, DAY6 종료 ObjectDB/1resource 잔존 경고. 플레이중 product script/parse/invalid-call 오류·크래시0. 모든stderr0이라는 주장은 하지 않음
- 입력 도구 보정: 숨은 OS포인터/roster 클릭, wheel release/mask 문제를 ignored helper에서만 수정. 초기 실패 승급시도 PNG는 완료 증거 아님. 실제 승급 D25-flame-adept-success.png와 자원 차감으로 재확인
- DAY5 helper 일시 겹침은 일반 입력만 포함했고 중복날짜 진행 없음; 이후 입력 writer 하나로 진행

## 8. 다음 작업 순서

1. 네 P2 문제의 수정 범위/후보 채택 결정. 예상 대상 scripts/game/GameRoot.gd·ManagementSceneController.gd·scripts/ui/HUDController.gd·ManagementWorkspaceUI.gd 및 data/localization/ui_zh_cn.json. 실제 원인 조사 뒤 필요한 경로만 변경하며 ko/en behavior 보존
2. 수정 후보의 동적 실제 노출·닫기 입력·관련 localized tests/ko-en 비교/export를 다시 확인하고 새 source/PCK 지문 기록. 이번 동결 후보/ZIP은 덮어쓰지 않음
3. 원어민/SC지역자형/홍보 검토·새SemVer·허용된 writer commit과 공개 배포는 사용자 결정 후 별도 처리. 승인1.2.9·내일 출시 확정과 간체 후보 채택을 구분

## 9. 작업 트리 상태

- 실제 작업트리: C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성\tmp\uiux_v2
- 기존 branch/HEAD/main/origin/main/v1.2.9 보존; branch 전환/stash/reset/commit/push 없음
- 제품40 미커밋은 기존 간체 후보의 의도된 변경. source-manifest40과 byte/SHA256 동일
- 이번 추적 변경: docs/handoff/CURRENT.md. 새 추적대상 문서: docs/handoff/ZH_CN_FULL_PLAY_2026-10-07.md
- 기존 변경: 간체 소스40 및 이전 핸드오프2개 보존. 다른 세션 변경을 되돌리지 않음
- Git관리영역 read-only: 커밋/새branch 시도나 escalation 없이 로컬 결과로 전달
- 빌드/캡처 산출물: tmp/zh_cn_full_play_20261007/ (ignored), 실제동결후보 tmp/zh_cn_fix_20261007/windows_candidate_fixed/ 및 기존ZIP 보존
- 테스트 엔진 정상 observer quit 완료; 다른 게임 프로세스 untouched

검증 직전의 git status (이 새 문서 작성 전; 종료 상태는 preservation.json에 갱신):

```text
## codex/v129-build-approval-status...origin/codex/v129-build-approval-status [ahead 1]
 M assets/fonts/README.md
 M data/localization/v122_stage10_ui.json
 M docs/handoff/CURRENT.md
 M scenes/ui/screens/RegionSelectionScreen.gd
 M scripts/core/EnglishTranslation.gd
 M scripts/core/LanguageSettings.gd
 M scripts/game/CombatSceneController.gd
 M scripts/game/GameRoot.gd
 M scripts/game/ManagementSceneController.gd
 M scripts/ui/HUDController.gd
 M scripts/ui/ManagementWorkspaceUI.gd
 M scripts/ui/UIFont.gd
 M scripts/ui/UIUXTheme.gd
 M tools/tests/FullEnglishRuntimeTest.gd
 M tools/tests/V122Stage10LocalizationTest.gd
?? assets/source/imagegen/steam_chinese_promo_local_candidate/
?? assets/source/imagegen/steam_chinese_title_local_candidate/
?? data/localization/story_zh_cn.json
?? data/localization/ui_zh_cn.json
?? docs/handoff/ZH_CN_LOCAL_CANDIDATE_2026-10-07.md
?? docs/handoff/ZH_CN_QA_FIX_2026-10-07.md
?? docs/localization/ZH_CN_GLOSSARY_2026-10-07.md
?? docs/localization/ZH_CN_LOCAL_CANDIDATE_2026-10-07.md
?? marketing/steam/promo/promo_schinese.png
?? marketing/steam/schinese/
?? steam/store/PROMOTION_COPY_ZH_CN_CANDIDATE.md
?? steam/store/store_copy_schinese_candidate.json
?? tools/localization/BuildChineseReviewPackage.cjs
?? tools/release/GenerateSteamChineseGraphics.ps1
?? tools/tests/ChineseCatalogTest.cjs
?? tools/tests/ChineseGraphicsTest.cjs
?? tools/tests/ChineseLocalizationTest.gd
?? tools/tests/ChineseLocalizationTest.gd.uid
?? tools/tests/ChineseLocalizationTest.tscn
?? tools/tests/ChinesePackTest.cjs
```

## 10. 종료 체크리스트

- [x] 요청30일 정상 완주/최종전/엔딩 근거 완료
- [x] 일별 결과·선택·성장·자원·저장/복원·실제캡처 기록
- [x] 미해결P2 발견/재현과 한계 기록, 제품수정0
- [x] 관련 보존/증거 검증 완료
- [x] 요청된 전체 실제플레이 수행; 전체 자동회귀/별도검수에이전트 미요청 기록
- [x] 최종 기준 SHA 및 소스/PCK 지문 기록
- [x] 새 자산 생성 없음/기존출처 보존
- [x] CURRENT 갱신
- [ ] 의도한 파일 커밋: 미실행, Git관리영역 read-only
- [x] 원격push/PR/태그/Steam 공개조작 없음 기록
- [ ] 품질PASS: P2 4유형 OPEN으로 미충족
