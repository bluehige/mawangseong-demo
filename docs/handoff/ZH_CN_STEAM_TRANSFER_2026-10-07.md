# 간체 Steam 실행 명령문 전달 — 2026-10-07

## 1. 메타데이터

- WORKSTREAM_ID: ZH_CN_RELEASE_FINAL_20261007_TRANSFER
- 목표 버전: 미커밋1.2.9기반 간체후보, 새SemVer 미확정.
- 작업 브랜치: codex/v129-build-approval-status.
- 기준/마지막커밋: b06be967aa763199ac631729eb65cacbe9489c26; 로컬main/originmain동일. 새fetch없음.
- 원격push/PR/태그/Steamwrite 없음. 승인v1.2.9@4076e099202f440c85a30699268d1c887c26c903 보존.

## 2. 이번 세션 목표

사용자최신지시: Steam실행은기존가능한세션에시키며본세션은완결된명령문을준비/동일handoff.txt저장하고나머지정리후보고한다. 직접Steam접근추가시도를중단했다.

## 3. 완료한 작업

최종SteamZIP존재/크기/SHA256 및6엔트리bytes/SHA256/SHA1을읽기재검증하고PASS했다. root handoff.txt에실제원본/ZIP/DELIVERY/UploadSteamBuild절대경로,6파일SHA1/PCK SHA256,serverread→정식provenance→공식upload→검증→default→서버결과보고순서와보존/인증제약을작성했다. 제품48파일unchanged 검증. 제품/스토리/밸런스/저장/자산 변경없음.

## 4. 변경 파일

- handoff.txt: 다른세션에복사할동일실행명령문;사용자명시요청경로.
- docs/handoff/ZH_CN_STEAM_TRANSFER_2026-10-07.md 및 CURRENT.md: 종료기록/최신진입점.
- ignored tmp/zh_cn_release_final_20261007/handoff-verification.json, command-handoff-manifest.json: 재검증/명령문해시증거. 기존ZIP들은재작성하지않았다.

## 5. 그래픽 및 오디오 자산

변경/생성/설치/다운로드0. 기존원본/라이선스/후보/승인본보존.

## 6. 테스트 및 검수

- 최종SteamZIP615467464bytes, SHA256 b96f82e9b6c0f61e00b9cf498de14b11df43f2317217828d2d1b8325f7eb4374: PASS.
- ZIP6엔트리모두size/SHA256/SHA1기대값일치,추가/누락/중복0: PASS.
- source48각파일hash최종manifest와일치: PASS.
- handoff.txt 5327bytes /SHA256 e44cb8a2498cc15ee8f5be95f901f99e1e33bc05164fcaa4abae471aba52e8db. 최종응답과동일본문을전달한다.
- 근거: tmp/zh_cn_release_final_20261007/handoff-verification.json, command-handoff-manifest.json.
- 제품변경없으므로Godot재실행/회귀미실행. 기존제품검수결과는ZH_CN_RELEASE_FINAL_2026-10-07.md에기록된동일PCK에유효하다.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKING_COPY (cea7cebda2491e6a5b908b6f9c84f1fdedcb5a759972d680cd3ccb7cb9bb9ef9; Git SHA아님)
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..UNCOMMITTED_WORKING_COPY
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

본세션의Steam업데이트는미실행이며사용자가기존세션으로담당을이관한다. 실제serverdefault/manifest/readiness미조회,새SemVer/실제commit/tag미발급. 기존후보를승인v1.2.9라고위조하지말고정식처리에따라파일이바뀌면별도ZIP/표적검증/새해시로진행해야한다. 원어민/새전체30일/Steam설치/2PCCloud미실행은명령문에명시했다.

## 8. 다음 작업 순서

1. 사용자가handoff.txt본문을실행가능한기존세션에전달.
2. 그세션이실제App5267750/Depot5267751/default/approval/readiness·rollback부터읽고보고.
3. 정식provenance필요요건을처리한6종SteamContent만공식upload하고서버목록/hash검증후승인된default적용·실제전후Build/Manifest보고.
4. ReleaseApp/가격/계약/새권한은별도범위이며본명령에는포함하지않음. 접근불가시실제최소사용자단계만보고.

## 9. 작업 트리 상태

기존혼합변경/승인본/ZIP/개인save보존. root handoff.txt는명시요청된추가파일이며제품지문48분모에는포함하지않는다. 이번기타tracked수정은docs/handoff만. gitstage/commit/push/브랜치전환없음. 검수이후root문서는사용자최신명시경로요청에따라작성했다.

## 10. 종료 체크리스트

- [x] Steam직접추가시도중단·복사용완결명령문저장
- [x] ZIPexists/size/digest·6엔트리전체hash·source48보존검증
- [x] 최신핸드오프/CURRENT·미완료/별도출시범위기록
- [ ] 실제Steam업데이트 (사용자지정기존세션후속)
