# 간체 최종 후보·영문 동적 잔여 수정 — 2026-10-07

## 1. 메타데이터

- WORKSTREAM_ID: ZH_CN_RELEASE_FINAL_20261007
- 작성일: 2026-10-07 UTC.
- 목표 버전: 승인 1.2.9 기반 간체 Steam 업데이트 후보. 새 SemVer 미확정이며 project/export의 1.2.9를 임의 변경하지 않았다.
- 작업 브랜치: codex/v129-build-approval-status (기존 브랜치; ahead 1).
- 기준 및 마지막 커밋 SHA: b06be967aa763199ac631729eb65cacbe9489c26; main/origin/main의 로컬 참조도 동일. 새 fetch 없음; 원격 최신성은 당일 부모 감사 근거에 의존한다.
- 불변 공개 기준: v1.2.9 / 4076e099202f440c85a30699268d1c887c26c903; Steam Build25450324 / Manifest1103993226303809008은 이전 서버 감사 확인값이며 이번 현재 서버 조회값이 아니다.
- 후보: UNCOMMITTED_WORKING_COPY, 제품·검수·자산 48파일 지문 cea7cebda2491e6a5b908b6f9c84f1fdedcb5a759972d680cd3ccb7cb9bb9ef9. Git관리영역 쓰기 제한으로 새 커밋/브랜치/태그 없음. docs/handoff 문서는 별도이며 지문에 포함하지 않는다.
- 원격 푸시·PR·Release·Steam 업로드·default 변경: 수행하지 않음. 최신 부모 지시는 Steam 업데이트를 승인했으며, 적용 전에 정확한 파일과 상태를 전달하는 것이 이번 위임 경계다.

## 2. 이번 세션 목표

사용자의 “미해결항목도 수정하고 최종맞다 싶으면 빌드해서 스팀에 업데이트” 지시를 따른다. 확인된 영문 동적 한국어 잔여를 최소 수정하고 한/영/간체 UI·정상 저장·실제 EXE를 확인한 후보를 만든다. parent가 로그인된 Steamworks에서 현재 대상/승인/날짜를 읽은 뒤 업데이트를 계속하도록 정확한 패키지·미실행 범위를 전달한다. Release App/가격/할인/광고/계약/키/권한/새 설치는 범위 밖이다. 전체 회귀·새 전체30일·독립 검수 에이전트 요청은 없음.

## 3. 완료한 작업

- 구현: 전술 배치요약·시설효과·침입자목록·지시 피드백의 기존 간체 전용 번역 연결을 모든 비한국어에 적용했다. BASELINE-EN-01 전술 한국어 잔여 및 같은 계열 시설/보물/복도 동적 문자열을 표적 보완했다.
- 데이터: ui_en의 기존 5344문장 중 1개의 “and %d others”를 “and %d more”로 고쳐 1명과 복수명이 모두 자연스럽게 표시된다. supplemental 9개에 복도4·시설/보물5를 추가했다. 형식 토큰 순서·수치·이름·ID는 보존했다. 기존 간체 실번역과 용어집 유지.
- 로컬 Steam 제품 메타데이터: schinese interface/subtitles=true, full_audio=false 추가. 서버 상점 설정을 게시한 것은 아니다. 기존 review gates를 거짓 true로 바꾸지 않았다.
- 밸런스/스토리/저장 스키마: 변경 없음. 한국어 출력은 기존 fixture 40요약+25시설과 일치한다.
- 실제 EXE: 승인본과 동일한 MawangCastle.exe를 최종 PCK와 실행해 한/영/간체 1080p 타이틀→정상 DAY17 Continue→전술을 직접 검사했다. 출시 EXE의 --main-pack/script 경로 override는 사용하지 않았다.
- 저장: 원본 정상 체크포인트를 격리 AppData에 복사해 승인1.2.9와 최종3언어로 동일 Continue를 했다. v1~v5 전체 정상 재저장 payload 15쌍은 saved_at_text/saved_at_unix 2개를 제외하면 승인본과 deep equal이다. 로더가 원본의 일시 필드를 정규화하는 기존 동작을 동일하게 재현하며, 원본 파일 바이트 동일 주장과 구분한다. 개인 AppData/save 접근 없음.

## 4. 변경 파일

이 세션에서 이전 자연플레이 수정후보 대비 변경한 제품/검수 경로는 아래 6개다. 전체 간체 작업 누적48파일은 source-manifest.json이 분모다.

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| scripts/ui/DefensePreparationSummary.gd | 동적 인원 문구를 영어에도 연결 | 완료 |
| scripts/ui/FacilityEffectText.gd | 시설효과·적용범위 영어 연결 | 완료 |
| scripts/game/GameRoot.gd | 영어 침입자·지시 피드백 연결 | 완료 |
| data/localization/ui_en.json | 9보조문장 + 인원 문법1건 | 완료 |
| steam/release_config.json | 로컬 schinese 지원 메타데이터 | 완료; 서버 미게시 |
| tools/tests/ChineseNaturalPresentationTest.gd | 한영중 동적문구396검사 | PASS |

종료 문서: 이 핸드오프와 CURRENT.md. tmp/zh_cn_release_final_20261007의 로그·도구·캡처·ZIP은 ignored local artifacts이며 소스 커밋 대상이 아니다.

## 5. 그래픽 및 오디오 자산

신규 생성/다운로드/폰트 설치/라이선스 수락/오디오 변경 없음. 기존 GPT 내부 생성 원본·SOURCE.md와 간체 제목 谁来守护魔王城？, 상점/라이브러리7PNG 및 promo1PNG를 보존하고 실제 픽셀을 읽었다. 짧은 홍보문구 小小伙伴，一座值得守护的城堡。도 오탈자·읽힘·잘림을 직접 점검했다. 원어민 취향/전문 상점 교정이나 Steam의 실제 업로드 승인을 받았다고 주장하지 않는다. 간체 상점 설명은 작성·의미 점검됐으나 서버 image-group의 간체 변형 등록 여부는 현재 조회하지 못했다.

기존 OFL NotoSansCJKkr-Regular.otf의 GSUB hani ZHS/KOR/JAN/ZHT/ZHH 언어 지원을 확인했다. 공식 Godot TextServer에서 1800종 한자를 zh_CN/zh-Hans/ko로 shaping: 미지원0, zh_CN 대 ko glyph 차이766, zh_CN 대 zh-Hans 차이0. 자동 locale의 SC shaping 경로를 확인했으며 파일명의 KR만으로 SC 미지원이라 단정하지 않는다. 1794종 런타임 glyph 검사와 1800종 원문 키까지 포함한 probe는 다른 분모다. 원어민 자형/미학 판단은 미실행이다.

## 6. 테스트 및 검수

근거 루트: tmp/zh_cn_release_final_20261007/.

| 순서 | 검사 | 결과 | 근거 |
|---:|---|---|---|
| 1 | ChineseNaturalPresentationTest | PASS396 | 동명.log |
| 2 | ChineseLocalizationTest | PASS1843 /1794glyph | 동명.log |
| 3 | EnglishTranslation / UIEnglishFormatted / StoryEnglishRuntime / V122Stage10 | PASS16 /967·0issues /26 /45 | 각각.log |
| 4 | Node 간체/UI영문/영문스토리 카탈로그 | PASS5344UI·142설정·1741대사·216제목; 토큰 순서보존 | CatalogTest.log 3종 |
| 5 | 최종 PCK export·카탈로그/font 포함·금지 경로 | PASS3389엔트리 /금지0 | windows_export.log, pack_verification.json |
| 6 | 이전후보 대 최종PCK, 한1080·영/중720/1080 5화면씩 | 상태25쌍·UI1240항목·의도한영문변경10·예상외0, 정확해상도50PNG | runtime-verification.json, live_run/captures |
| 7 | 닫기·지도확대·숨김/복원 | 전5조건 PASS; 닫기 zoom불변/정상zoom변화 | cases/*new_r3.json |
| 8 | 정상 최종PCK DAY17 방어 승리→기존 자동저장 Continue→DAY18 준비 | PASS; 게임 상태 setter/강제승리/날짜변경 없음 | cases/zh_battle_720_new_final.json, zh_normal_advance_1080_new.json |
| 9 | 정상 구DAY30엔딩 저장→후일담관리/전술/시설→E02재진입→재시작 | PASS12의미필드 /DAY30·왕좌2500 | cases/zh_ending*.json |
| 10 | 실제 출시 EXE 한/영/중 1080p title/normalContinue/tactics | exit0·최종9PNG 직접읽음 | native-verification.json, native_movie_* |
| 11 | 승인 EXE/PCK 같은 정상Continue 대 최종3언어 전체save | 15payload쌍 deep equal(시간2필드제외) | native-verification.json |
| 12 | 승인6·초기7·동결8·기존ZIP9·544캡처·구저장·태그/HEAD 보존 | PASS | preservation.json |
| 13 | 전체회귀 / 최종PCK 전체30일 / 별도 검수 에이전트 | NOT_REQUESTED / NOT_RUN / NOT_REQUESTED | 범위외 |

과거 구PCK 정상30/30일·29/29승리 기록은 ZH_CN_FULL_PLAY_2026-10-07.md에 보존한다. 그 완주를 이번 PCK 전체완주로 계산하지 않는다. 실제 EXE 검사는 Continue/전술까지이며 전투/엔딩은 동일최종PCK+공식엔진·정상UI 입력으로 검증했다. MovieWriter가 dummy audio로 실행됐으므로 청취 검사도 아니다. 초기 GDI black/foreground 실패와 EXE override 거부는 제외했다. 영문 번역으로 line_count가 3→2처럼 달라지는 것은 정상이며 rect/controls 불변·모든 줄 표시를 검사했다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKING_COPY (cea7cebda2491e6a5b908b6f9c84f1fdedcb5a759972d680cd3ccb7cb9bb9ef9; Git SHA 아님)
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..UNCOMMITTED_WORKING_COPY; 실제 commit 부재로 정책 CI용40자SHA 범위는 미발급
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS
- 알려진 네 간체 P2와 동적영문 잔여는 표적 수정/재검사했다. 제품 전체 P1/P2 0건 보증은 아니다. 이 지문 이후 제품/데이터/자산 변경 없음; 종료문서와 ignored evidence만 추가.

## 7. 미해결 항목과 위험

- 원어민 전체7288중복제외문장·상점/홍보·자형 취향 검수 미실행. SC shaping/대표 픽셀은 확인됐으나 원어민 승인과 구분한다.
- 새 전체30일·전분기/23엔딩/NG+·오디오청취·Steam클라이언트 실제설치·2PC Cloud·성능하한 미실행. 이번 표적 변경이 수치/규칙/저장 포맷을 바꾸지는 않는다.
- root certificate / ObjectDB·resource-at-exit 경고는 승인1.2.9와 최종3언어에서 동일하게 재현되는 기존 경고다. 종료코드0이나 stderr0이라 주장하지 않는다.
- Steam 현재 default/manifest/approval/release날짜·미게시 앱설정 조회: 이 환경에 승인된 브라우저/Steam 연결 도구가 없어 미실행. 부모의 로그인된 브라우저에서 읽어야 한다. 새 자격증명/권한/결제/키/설치 없음.
- 새 SemVer·실제 Git commit/tag가 없다. 후보 manifest는 tag/source_commit=null로 기록한다. 기존 immutable-tag/fullSHA 필수 release validator는 이 미커밋 후보에 적합하지 않으며 통과했다고 주장하지 않는다. 기존 태그를 재지정하면 안 된다.

## 8. 다음 작업 순서

1. 부모가 steam-upload-manifest.json과 DELIVERY.md의 exact package/PCK/source48 지문을 확인한다. 이번 Steam 업데이트는 사용자 승인 범위이며 다시 미세승인을 요청할 필요가 없다.
2. 로그인된 Steamworks에서 App5267750·Depot5267751·Windows exe·현재 default Build/Manifest·상점/게임 Approved for release·2026-10-08 출시 readiness 및 기존 launchconfig 미게시변경을 읽고 기록한다. 과거25450324/1103993226303809008을 현재 조회값으로 대체하지 않는다.
3. 안전한 Gitwriter가 필요하면 사용자 확정 새SemVer와 실제SHA를 먼저 정리하고 재export가 필요할 경우 변경된최종PCK를 다시 표적검사한다. 기존 v1.2.9/approved 바이너리/rollback은 보존한다. 또는 동일 미커밋 후보임을 정확히 기록한 승인된 배포 절차로 진행하되 태그형 provenance를 위조하지 않는다.
4. 부모가 전달된 Steam용6파일 ZIP을 해당 Depot에 업로드하고 실제 새 BuildID/Manifest/파일 SHA1을 기록한다. 실제 파일을 확인한 뒤 사용자 승인된 업데이트로 default 적용하고 readiness와 실제설치를 확인한다. 이 단계는 아직 수행되지 않았다.
5. schinese 상점지원 Interface/Subtitles·localized assets/copy 게시 범위는 부모가 사용자 지시와 서버 상태를 대조한다. Release App은 내일 확정시각 절차이며 이번 빌드업데이트만으로 누르지 않는다. 가격/Cloud기능/할인/권한은 임의 변경하지 않는다.

## 9. 작업 트리 상태

기존 혼합 작업트리와 전 간체 작업은 보존했다. tracked19파일+기존 간체 신규경로가 미커밋이며 이번6제품경로는 그 누적작업에 포함된다. 이 핸드오프/CURRENT 추가만 별도 종료변경이다. git add/reset/commit/push/branch-switch 없음. import시 .tscn/.tres newline-only194파일은 정확한 이전바이트로 복원했고 기존 source48해시 일치. 승인6/과거후보7·8·7/ZIP2·4·3/캡처544/원본save6은 보존해시 PASS. 모든 새 빌드·캡처·profile은 위 tmp root 아래이며 개인 저장 접근 없음.

## 10. 종료 체크리스트

- [x] 알려진 문제 수정·표적 테스트·UI/실제 EXE·저장 대조 완료
- [x] 실제 source48 지문·최종 PCK·미커밋/미실행 범위 기록
- [x] 기존 승인본·태그·후보·저장·캡처 보존 확인
- [x] CURRENT.md 갱신·부모 전달자료 준비
- [ ] 원어민 전체교정 / 새 전체회귀·전체30일 (미실행)
- [ ] Git commit·새SemVer/tag (미발급)
- [ ] 현재 Steam 상태 read→업로드→default 적용 (부모 후속)
