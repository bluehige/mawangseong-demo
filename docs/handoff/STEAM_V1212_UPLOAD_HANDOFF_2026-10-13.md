# Steam1.2.12 최종 파일·업로드 인증 실패·DK 재개 인계

## 1. 메타데이터

- 작성일: 2026-10-13 UTC
- 목표 버전: 1.2.12 유지보수 패치 / App5267750 / Depot5267751
- 작업 브랜치: codex/fresh-v5-result-save-fix
- 시작 문서 체크포인트: e50945b886b1c1ab295db2bd686dd2392b1f0d47
- 기존 검증 제품 SHA: 2dfbaeea2e28b4d8d04631689eee24c9ef7b0800
- 마지막 제품·최종 빌드 소스 SHA: 9f0be3be3642eaa18a45bfca2679e187e2077d7a
- 기준: origin/main0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b(현재 HEAD와 merge-base 동일). main 로컬 ref 부재/원격 fetch 미수행으로 최신 main 권위는 확정하지 않는다. 과거 tuple/정책 확인은 이전 인계를 재사용한다.
- 변경 전 작업 트리 clean. 최종 소스 이후 변경은 docs/handoff 문서뿐이다. 종료 문서 커밋 SHA는 외부 final-checkpoint.json 및 대화 결과에 기록한다.
- 원격 push/merge, GitHub Release, 불변 태그 생성: 미수행. Manifest tag=v1.2.12는 출시 라벨이며 tag_state=not_created/build_kind=release_candidate로 실제 상태를 명시한다.

## 2. 이번 작업 목표·승인

사용자는 02:17UTC Steam 업데이트/default공개/패치노트 게시를 승인했고, 이후 기존 SteamCMD를 먼저 찾아 업로드를 시도하고 실패하면 Google 원격 데스크톱으로 직접 이어갈 한 폴더를 준비하라고 지시했다. 이전 공개금지 지시는 이 최신 승인으로 대체됐다. 동일 승인 재질문0. 이번 업로드는 기존 공식 계정 로그인 경로로 한 번만 실행하며 새 비밀번호·OTP를 자동 공급하지 않는다.

최신 추가 지시: 현재 턴은 완료하고 다음 작업부터 gpt-6.1-sol / high / 일반속도(service_tier default). 현재 턴 설정이 바뀌었다고 주장하지 않았으며 추가 ultra/Fast 작업을 새로 만들지 않았다.

## 3. 완료한 작업

- 기존 설치 SteamCMD를 발견했다. SDK형 루트 C:/Users/blueh/Documents/Codex/2026-10-11/task-2/runtime/SteamPipe, 실행파일 tools/ContentBuilder/builder/steamcmd.exe. Valve Corp. Authenticode Valid, SHA25688f791368cdb3a8c82b84d3ea53f25c18c33b425a0560d5a3f851bd709b35580. 새 설치0.
- 2026-10-11 명시 프로젝트 evidence/STEAMCMD_DK_SETUP_RESULT.md와 STEAMCMD_HUMAN_LOGIN_PENDING.md, script-path-connection 기록으로 이전 설치/로그인 실행경로를 확인했다. 사용자22:49 login bluehige1→quit 완료 지시를 인수했다. 당시 공개1.2.11은 부모 WebUpload이며 로컬CLI 업로드 기록과 혼동하지 않았다.
- 현재 브라우저 도구는 IAB/Chrome/MCPApps backend가 설정됐지만 선택 전 MXC 실행 커널이 HRESULT0x80070003으로 종료됐다. 이를 계정 로그아웃/클라우드 부모 브라우저 불능으로 해석하지 않았다. 쿠키·인증캐시·비공식디버그접속 사용0.
- 정상 SteamCMD 캐시 로그인 조회1회는 Cached credentials not found/password prompt. 새 자격증명을 공급하지 않았으며 원인(만료/저장 여부)은 단정하지 않았다. 이 조회를 다시 실행하지 않았다.
- 별도 공식 실행파일·DLL 복사에 anonymous 로그인으로 현재 공개 app-info를 직접 읽었다. 인증설정/캐시는 복사하지 않았다. Public Build25870353 / Depot5267751 Manifest5824439082666467035가 불변 공개1.2.11 배포 기록과 정확히 일치한다. News1.2.10 기사만으로 공개버전을 판단했던 이전 상태를 대체한다.
- 이에 승인된 높은 유지보수 버전1.2.12로 project/export/공지ID/KOENZH노트만 갱신했다. 전투·스킬·성장·저장 로직 및 Cloud 경로 변경0.
- 공식 Godot4.6.3 Windows Steam export exit0, PE FileVersion/ProductVersion1.2.12.0. 이전 검토fullPCK3421자원과 비교해 project.binary와 PlayerContinuityUI.gdc만 차이; 그 외 자원 동일.
- 최종 EXE+PCK의 KO/EN/ZH 공지를 1920×1080 한 해상도에서 확인했다. 세 언어 모두 제목1.2.12/본문/확인 버튼이 읽히고 잘림 없음; 각각 exit0/script-resource ERROR0.
- 기존 UploadSteamBuild.ps1로 최종 depot validator를 실행하고 실제 +login bluehige1 +run_app_build +quit를 한 번 시도했다. SetLive를 지정하지 않았다.
- DK 사용자 재개 폴더를 만들었다: C:\Users\blueh\Documents\Codex\2026-10-13\task\Steam-1.2.12-Ready. Content7파일(6실제산출물+manifest), 기존공식SteamCMD용 Upload.cmd, 업로드VDF, 무결성확인, 세언어패치노트, 짧은안내, 안전메타데이터와 공지PNG. Evidence/개인userdata/실행스크립트는 Content밖이며 업로드대상이 아니다.

## 4. 변경 파일

| 파일 | 변경 |
|---|---|
| project.godot | config/version1.2.12 |
| export_presets.cfg | Windows metadata/기본출력명1.2.12 |
| scripts/ui/PlayerContinuityUI.gd | UPDATE_ID1.2.12, 실제완료내용의KOENZH공지5항목 |
| README.md | 후보1.2.12와 직접확인한현재공개1.2.11 |
| docs/PRODUCT_VERSIONING.md | 높은patch근거/태그상태/영향범위 |
| docs/handoff/STEAM_V1212_UPLOAD_HANDOFF_2026-10-13.md | 본통합인계 |
| docs/handoff/FINAL_PATCH_REQUIREMENT_MATRIX_2026-10-13.md | 기존판정의원본은보존하고현재상태링크추가 |
| docs/handoff/CURRENT.md | 최신후보/인증실패/재개경로 |

코드/데이터/스토리/밸런스: 이번단계는공지및버전메타데이터뿐이다. 기존8스킬/성장/첫승리저장/전열후열/시설결산/DAY30매핑/실패Quit 구현은2df불변검토범위를 그대로 계승한다.

## 5. 그래픽·음원·대용량 산출물

신규 그래픽·음원 생성 및 기존자산변경0. 기존런타임과THIRD_PARTY_NOTICES/font라이선스/공식GodotCOPYRIGHT를 패키징했다. 개인세이브/Play.cmd 격리런처/소스/원본/QA스크립트는 depot에 넣지 않았다. 빌드/캡처/로그는 workspace에만 두며 소스Git에 커밋하지 않는다. Library 호출·첨부0, Google 원격 데스크톱 설치·설정변경0.

최종 EXE: 104699392B / SHA2569635b610bcdec45777201b71353717aca796cff97b910261376f5e0281bd077e.
최종 PCK: 584536312B / SHA256a424ede0168c38d11158b102b4510c292efa52f2f820a91c2671f5d309e0613b.
Content manifest는 각depot파일을 정확히한번기록한다. 인증정보·토큰·패스워드·개인세이브·캐시를 폴더로 복사하지 않았다.

## 6. 최종 검증·증거 재사용

최종 제품9f에 대해 새로운메타데이터/공지/패키징 영향만 한 최종판정 묶음으로 확인했다. 불변2df 스킬/성장/저장PASS를 무조건 재실행하지 않았고 반복횟수0. 기존 실패 및 보정 경계는 요구사항 matrix에 보존되어 있다. 처음 manifest작성 보조스크립트의파일명/표준모듈/self목록 오류는 validator 전에 수정했으며 제품코드변경 없이 최종manifest를 검증했다.

| 범위 | 결과·근거 |
|---|---|
| 공식Steam export/PE metadata | PASS; release-readiness/v1212-export-exit.json, final-gate.json |
| 검증된fullPCK와자원대조 | PASS; v1212-runtime-impact.json, 차이2/뜻밖변경0 |
| 실제최종EXE KOENZH공지 | PASS; v1212-final-screen/final-screen-results.json와3PNG, 시각확인 |
| 기존depotvalidator | STEAM_RELEASE: SETUP_PASS; UploadSteamBuild.ps1 실제업로드전1회. 기존외부gate/strict전체QA를완료로승격하지않음 |
| 기존8스킬/성장/저장/Continue/실패Quit | 기존제품SHA별PASS·영향범위재사용; FINAL_PATCH_REQUIREMENT_MATRIX_2026-10-13.md |
| SteamCMD업로드 | AUTH_BLOCKED; v1212-upload-attempt.json |
| 자연전체캠페인·재미/실제Steam설치·2PCCloud·특정사용자DAY30·downgrade | NOT_RUN |

새공지 boot는 gameplay검수나사용자 실제저장복구 검증으로 표시하지 않는다. 개인698파일의 마지막 hash보존결과는 기존2df 인계를 재사용하며, 이번게임부팅은각언어별격리APPDATA를 사용했다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 9f0be3be3642eaa18a45bfca2679e187e2077d7a
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..9f0be3be3642eaa18a45bfca2679e187e2077d7a
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

위필드는제품/공지/패키징표적범위이며전체플레이QA나Steam공개완료를의미하지않는다.

## 7. 업로드 실패·환경 차단

실제업로드attempt_count1, PowerShell uploader exit1, SteamCMD exit5. 현재공식클라이언트가 Cached credentials not found와password prompt를 반환했다. stdin은EOF였고password/token/OTP 입력0. 따라서ERROR Invalid Password는사용자가비밀번호를잘못입력했다는증거가아니다.

content_build_start_observed=false, process_still_running=false, 강제종료0, 새BuildID 없음. 업로드성공/default변경/패치노트게시를주장하지않는다. 캐시확인외 실제업로드는딱1회이며재시도0. SteamCMD불확실종료나부분업로드여부를숨기지않고단계별기록했다.

자동승인검토는 .codex memories sqlite의 전체 raw_memory/rollout_summary 읽기를 자격증명노출위험으로 거부했다. 해당읽기는실행되지않았고우회하지않았다. 대신명시프로젝트설치·로그인인계와서명실행파일/정상클라이언트응답으로경로와상태를확인했다. 이차단은현재SteamCMD발견/패키지준비를막지않으므로추가권한요청이필요하지않았다.

## 8. 다음 작업 순서·안전한 재개

1. 사용자가기존Google원격데스크톱으로DK접속후폴더Upload.cmd실행. 필요시직접SteamCMD콘솔에password/Guard입력. 정상실행은Contenthash확인→기존SteamCMD→실제업로드, default자동변경없음.
2. 앱builds화면에서Desc v1.2.12 9f0be3be3642/actualBuildID를확인한뒤default적용. 부모클라우드기존브라우저와중복공개를하지않는다. 불확실응답은동일Desc완료빌드먼저조회하고무조건재업로드하지않는다.
3. default확인뒤SmallUpdate/PatchNotes하나를세언어txt로게시. BuildID/default·depotmanifest·공지URL을기록한다.
4. 이후작업은부모가gpt-6.1-sol/high/service_tier default로명시하여재개한다. 제품9f의검증된게임테스트를다시무조건돌리지않는다.

짧은실행안내: C:\Users\blueh\Documents\Codex\2026-10-13\task\Steam-1.2.12-Ready/START_HERE_KO.md.
공식SteamPipe지침: https://partner.steamgames.com/doc/sdk/uploading (default는AppAdmin에서설정).

## 9. 작업 트리 상태

소스freeze9f당시clean, 해당export만생성한 .import와추적되지않은testUID만자기생성근거로정리했고원래변경0. 현재종료문서만explicitstage/commit한다. 승인된원격Steam공개는인증단계차단으로변경0, Git원격push/merge0/태그0/Cloud설정0. 바이너리·PNG·실행로그는소스Git에없다.

## 10. 종료 체크리스트

- [x] 기존SteamCMD찾기와최신공개Build/manifest직접확인
- [x] 올바른높은patch1.2.12/최종소스SHAfreeze
- [x] 최종export·metadata/공지/패키징판정, 기존PASS반복0
- [x] 실제SteamCMD업로드1회및인증실패정확히기록
- [x] 한DK폴더로최종게임/스크립트/KOENZH공지/짧은안내준비
- [x] 자격증명파일없음/개인세이브보존/원격설정변경없음
- [x] CURRENT최신진입점갱신
- [ ] 사용자직접인증뒤업로드성공과새BuildID확인
- [ ] default공개와patchnotesURL확인
