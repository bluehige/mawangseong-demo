# 1.2.10 간체 Steam 업데이트 — 2026-10-07

## 1. 메타데이터

- 작성일: 2026-10-07 KST
- 목표 버전: 사용자 확정 1.2.10 (이번 채팅 응답)
- 작업 브랜치: codex/v1210-zh-cn-release (기존 작업트리 브랜치 이름만 변경; 파일 전환 없음)
- 기준 브랜치 및 SHA: main/origin/main b06be967aa763199ac631729eb65cacbe9489c26; git fetch origin main 성공, 동일 확인
- 마지막 제품 커밋 SHA: e24a651b2c9a12f760760b5461b08503e1ecacaa
- 원격 푸시 여부: 이 기록 작성 시 아직 미실행; 후속 게시 기록에 실제 결과 추가
- 관련 태그: v1.2.10 발급 예정. 기존 v1.2.9@4076e099202f440c85a30699268d1c887c26c903 불변

## 2. 이번 세션 목표

사용자가 승인한 간체 최종 후보를 정식 소스·SemVer·새 불변 태그로 처리한 뒤 App5267750 / Depot5267751 업데이트와 서버 6파일 대조 후 default 적용한다. Release App·가격·할인·계약·권한 변경은 제외한다. 실제 원본 tmp/uiux_v2만 사용한다.

## 3. 완료한 작업

- 실제 Chrome Steamworks 인증 세션 재사용. Sign in 선택 후 기존 로그인 복구; 비밀번호/SteamGuard/인증 파일 접근 없음.
- 현재 default Build25450324 / Manifest1103993226303809008을 직접 읽었다. 역사적 승인 기준도 25450324 / 1103993226303809008이며 둘을 별도 롤백 항목으로 기록했다.
- 상점·게임 모두 APPROVED FOR RELEASE, Store Visible, Prerelease, Earliest possible release 8 Oct. 기존 내부 Sep28,2026 11:00 PM GMT+9 및 공개 Coming Soon 유지. 정확한 한국 판매 개시 시각은 미확정; 아직 Release App 실행 안 함.
- Available worldwide. Launch executable MawangCastle.exe / Windows / 64-bit only. Depot는 All Languages / All OSes / All Architectures, 3 packages 참조. 미게시 앱 설정 목록 0건.
- 원본 ZIP 615467464 bytes / b96f82e9b6c0f61e00b9cf498de14b11df43f2317217828d2d1b8325f7eb4374 및 모든 6파일 size/SHA256/SHA1 재검사 PASS. source48 원본 각 파일 size/SHA256 일치. 원본 후보·기존 승인 1.2.9 바이너리 보존.
- 누적 간체 UI5344·설정142·대사1741·장면216, 관련 영문 동적 문구 수정 반영. 밸런스·저장 형식 변경 없음.
- project 1.2.10 / Windows file·product 1.2.10.0 / export 경로·설명 정합성. EXE/PCK 새 export. Godot 4.6.3.stable.official.7d41c59c4.
- 새 PCK 584255000 bytes / 55fd2a8a630e4a0f8df136cce5d1b9bc869e165b29837a32369c5a4ed88d694e. 후보 PCK 3389엔트리와 비교해 project.binary만 변경, 나머지3388 size/MD5 모두 동일. 카탈로그5종 소스 byte 일치·CJK font·compiled scripts·개발/개인자료 제외검사 PASS.

## 4. 변경 파일

- source-manifest.json의 지정 누적48경로 + project.godot/export_presets.cfg/README.md/docs/PRODUCT_VERSIONING.md =52경로만 제품 커밋.
- 두 그래픽 SOURCE.md의 Target version과 미확정 설명만 1.2.10 확정으로 갱신. 이미지 픽셀 변경 없음.
- 기존7개 ZH_CN 핸드오프와 CURRENT 변경 보존; 이번 세션 핸드오프·CURRENT 요약 추가.
- 산출물은 ignored tmp/steam_v1.2.10_20261007 및 builds/steam/windows/v1.2.10 아래. 바이너리/ZIP/캡처는 Git 소스 커밋 제외.

## 5. 그래픽 및 오디오 자산

기존 GPT 내부 생성 간체 홍보7종과 promo1종 및 원본/SOURCE.md를 source48에 포함한다. 이번 세션 새 생성·오디오 변경 없음. 픽셀/규격/알파 검사 PASS; 상점 간체 게시와 원어민 검토는 별도 미완료이며 서버에 새 이미지 업로드하지 않았다.

## 6. 테스트 및 검수

- 새 제품 커밋 e24a651b2c9a12f760760b5461b08503e1ecacaa: ChineseNaturalPresentation396, ChineseLocalization1843/1794glyph, EnglishTranslation16, UIEnglishFormatted967, StoryEnglishRuntime26, V122Stage10Localization45 모두 exit0.
- ChineseCatalogTest source/ID/placeholder/누락·중복·치환문자 검사 PASS; ChineseGraphicsTest9이미지 규격/알파 PASS.
- 공식 Windows export exit0, PE file/product1.2.10.0, ChinesePackTest3389엔트리/금지자료0 PASS. 버전 변경 전후 PCK 대조로 project.binary 이외3388 파일 불변 확인.
- 새 출시 EXE headless ko/en/zh_CN 부팅 exit0. 화면 없는 로컬 실행 검사이며 Steam 설치 또는 실제 새 UI 시각 검수로 주장하지 않는다. 기존 인증서 읽기 경고가 계속 있으나 script/parse/resource 오류는 없음.
- 이전 최종 후보의 실제 EXE Continue/전술·3언어 UI·저장15쌍·정상 DAY17→18·엔딩 복귀 근거는 ZH_CN_RELEASE_FINAL_2026-10-07.md에 보존한다. 이번 버전 PCK는 프로젝트 버전 설정 외 내용이 동일하며 새 전체30일 완료로 확대하지 않는다.
- 근거: tmp/steam_v1.2.10_20261007/pre-update-audit.json, *Test.log, formal-export.log, formal-pack-verification.json, pck-version-comparison.json, exe-boot-*.stdout/stderr.log.
- 테스트 첫 실행 2회는 테스트별 격리 경로 허용 문자열이 달라 실패했다. 제품 수정 없이 새 프로필 경로에 두 허용 문자열을 모두 넣은 후 6종 최종 PASS.
- Review task ID: NOT_REQUESTED
- Reviewed SHA: e24a651b2c9a12f760760b5461b08503e1ecacaa
- Review range: b06be967aa763199ac631729eb65cacbe9489c26..e24a651b2c9a12f760760b5461b08503e1ecacaa
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

정식 main PR/새 불변 태그/manifest·최종 ZIP/Steam 업로드·서버 해시·default 적용은 이 기록 작성 시 진행 전이다. 새 전체30일·원어민 전체교정·Steam 클라이언트 설치·2PC Cloud·새 UI 시각 검수 미실행. 기존 release_config 외부 gate의 로컬 placeholder를 실제 서버 승인과 혼동하지 않는다. 출시 일정은 변경하지 않는다.

## 8. 다음 작업 순서

1. 위 고정 제품 SHA 검증 기록과 기존 핸드오프를 커밋, repository-policy 통과 후 main PR merge commit.
2. 병합된 main의 새 불변 v1.2.10 태그. 제품 트리 동일성 검증 후 원본 작업트리에서 정식 tag/fullSHA manifest·별도6파일ZIP·해시 검사.
3. 공식 Steamworks Web Upload Standard로 Depot5267751에6파일만 업로드. 새 BuildID/Manifest와 서버 size/SHA1 전수 대조.
4. 검증된 빌드만 이미 승인된 업데이트로 default 적용 후 승인/readiness/rollback/해시/미완료를 기록. Release App 클릭 금지.

## 9. 작업 트리 상태

기존 혼합 작업트리에서 지정 소스만 커밋했다. 기존7개 세션 핸드오프·CURRENT는 문서 커밋으로 보존할 예정이며 handoff.txt는 원문 그대로 남긴다. 새 stash/reset/다른 작업트리 없음. import1615개 snapshot·194개 newline만 원상복구, 현재 제품 변경0.

## 10. 종료 체크리스트

- [x] 서버 실제 상태/롤백 기록 및 사용자 버전 확정
- [x] 원본 후보/과거 태그·바이너리/개인 저장 보존
- [x] 관련 소스 commit·6종 검사·새 Windows export/PCK 표적 검사
- [x] CURRENT 갱신·실행/미실행 구분
- [ ] main PR·새 태그·정식 manifest·최종 ZIP
- [ ] Steam 업로드·서버 대조·default·사후 readiness
