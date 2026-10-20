# 1.3.0 BGM 완료·Windows 출시 후보 빌드 — TARGETED_PASS

## 1. 메타데이터

- 작성일: 2026-10-15
- WORKSTREAM_ID: V130-BGM-FINAL-RELEASE-BUILD
- 목표 버전: 1.3.0 / Windows 파일·제품 버전 1.3.0.0
- 작업 브랜치: codex/v130-map-overhaul
- 시작 SHA: f4f4367a805cd33345b698198b785c28954450da
- 기준 참조·merge base: origin/main 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b
- 마지막 제품 커밋·빌드 SHA: 74f175365d77dbb67619099a160ee1821147946b
- 마지막 문서 커밋: `git log -1 --format=%H -- docs/handoff/V130_RELEASE_BUILD_2026-10-15.md`로 조회
- 원격 push·merge·태그·Release·Steam 업로드/Commit/default/공지 게시: 모두0
- 권위 제한: 로컬 main 부재. git show main의 두 문서 조회는 실패했고 origin/main 정책·CURRENT를 읽었다. 읽기 전용 ls-remote의 main과 origin/main이 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b로 일치한다. 로컬 main 권위를 임의로 만들지 않았고 사용자 제공 최신 정책과 지정 브랜치를 따랐다.

## 2. 목표 및 완료 조건

누락곡을 평화로운 프롬프트로 **추가1회만** 생성하고, 성공 시 신규15곡의 기존 직접 검사 PASS와 0054의 출시 폴더·공식 export·최종 EXE 스모크까지 완료한다. 실제1회 성공하여 14곡 대체 구성/DLC 보류 분기는 사용하지 않았다. 공개 배포·원격 Git 변경·이미지 생성은 범위 밖이다.

## 3. 완료한 작업

- 누락곡을 `귀환의 난롯가` / `Hearth of Return` / `归来的炉火`로 변경. 내부 ID `v130_final_ending_02_home_after_siege` 유지.
- 기존72BPM/D major/어쿠스틱 기타·cor anglais(잉글리시 호른)·따뜻한 실내악 스트링·하프/132초/2초 루프 조건 유지. 전체 입력을 평화로운 귀가·난롯가 문구로 직접 구성해 기본 프롬프트의 전투·방어 표현도 제외했다. 원작 모방 금지·보컬 없음 유지.
- SDK attempts=0 유지. 이번 성공1회, 누적17요청(성공15/기존HTTP400거절2), 수동재시도 누적2, SDK자동재시도0. 거절 원인이 전쟁 어휘라는 가설은 미확인이다.
- render→품질 자동 점검→promote(confirm=True/force=False)→출처·runtime active131·카탈로그131/이벤트123·실제연결121·장면당5곡 연결. 검사 기대값·테스트 코드 변경0, 구v05/v122 manifest 무변경.
- 패치노트 KO/EN/ZH_CN에 실제 신규 BGM15곡 항목 추가. 기존1.3.0 버전·720 보유 안내는 보존.
- 정책 지적 공백만 수정: V20_MAP_BUILDER_PLAN 28·45행 줄끝 공백2건, concept/SOURCE 마지막 빈줄1건. 이 두 문서의 내용 변경0.
- 게임 로직·수치·스토리·저장 스키마·그래픽 변경0. 기존 버전 관련 표적 검사는 직전 ea44d08 인계의 이력이며 이번에 재실행했다고 주장하지 않는다.

## 4. 변경 파일

제품 커밋17파일(새 WAV·새 오디오 import·곡별 원본/출처/JSON5경로 포함):

- `assets/audio/bgm/v130/final_ending_02_home_after_siege.wav`
- `assets/audio/bgm/v130/final_ending_02_home_after_siege.wav.import`
- `assets/source/audio/lyria/v1.3.0/v130_final_ending_02_home_after_siege/SOURCE.md`
- `assets/source/audio/lyria/v1.3.0/v130_final_ending_02_home_after_siege/generation.json`
- `assets/source/audio/lyria/v1.3.0/v130_final_ending_02_home_after_siege/source.mp3`
- `assets/source/audio/v130_bgm/SOURCE.md`
- `assets/source/audio/v130_bgm/request_ledger.json`
- `data/audio/audio_event_catalog.json`
- `data/audio/music_playlists.json`
- `docs/design/audio/V130_BGM_CONCEPTS.md`
- `docs/design/v20_map_builder/V20_MAP_BUILDER_PLAN_2026-10-14.md`
- `docs/design/v20_map_builder/concept/SOURCE.md`
- `docs/release/PATCH_NOTES_1.3.0_EN.txt`
- `docs/release/PATCH_NOTES_1.3.0_KO.txt`
- `docs/release/PATCH_NOTES_1.3.0_ZH_CN.txt`
- `tools/audio/lyria_v130_manifest.json`
- `tools/audio/lyria_v130_runtime_manifest.json`

종료 문서: 이 파일, V130_BGM_2026-10-15.md, CURRENT.md. 빌드·캡처·임시 도구는 소스 Git에 포함하지 않는다.

## 5. 오디오·빌드 산출물

- 모델: lyria-3-pro-preview / Gemini Interactions / store=false. 이미지 생성0.
- 원본·정확한 요청·출처: assets/source/audio/lyria/v1.3.0/v130_final_ending_02_home_after_siege/ 아래 source.mp3, generation.json, SOURCE.md.
- 원본 무변경. 런타임 PCM16/44100Hz/stereo, 2초 중첩 후 상수 이득. 신규곡130초/-16.536241LUFS/sample peak -4.957117dBFS/추정 true peak -4.948082dBTP/연속무음0초/루프 경계 PASS.
- **사용자 청취 전**. 자동 측정은 보컬·음악적 자연스러움의 직접 청취를 대신하지 않는다. 이번 요청의 자동 점검 후 채택 지시로 승격.
- 추정비용: 15×USD0.08=USD1.20, 이번 추가 성공분USD0.08. [공식 가격](https://ai.google.dev/gemini-api/docs/pricing), [실패 과금 FAQ](https://ai.google.dev/gemini-api/docs/billing) 2026-10-15 재확인. HTTP400 실패 비용 제외는 FAQ의 토큰 문구를 적용한 추정, 실제 청구 미조회.
- 공식 엔진4.6.3.stable.official.7d41c59c4, Windows Steam preset. 사용자 기존 dirty import/UID를 보존하기 위해 PrepareSteamBuild의 clean gate를 변경하지 않고 직접 공식 export와 기존 depot validator 사용.
- 출시 루트: `C:\Users\blueh\Documents\Codex\2026-10-13\task\Steam-1.3.0-Ready`
- Content7파일: MawangCastle.exe, MawangCastle.pck, THIRD_PARTY_NOTICES.txt, licenses/Godot-COPYRIGHT.txt, licenses/NEXON_Maplestory_LICENSE.txt, licenses/NotoSansCJK_LICENSE.txt, steam-build-manifest.json.
- manifest: source_commit=74f175365d77dbb67619099a160ee1821147946b, tag=v1.3.0, tag_state=not_created, build_kind=release_candidate. 태그 생성 사실을 주장하지 않는다.
- ZIP: `C:\Users\blueh\Documents\Codex\2026-10-13\task\Steam-1.3.0-Ready\MawangCastle-v1.3.0-SteamContent-74f1753.zip`
- 크기: 689415304bytes; SHA256: `50284b446f56c63807a658293c9a5f8f6ae3b580622b0c85b3af0e91462a413b`
- 루트 패치노트3개·HTTP_UPLOAD_1.3.0_KO.md·Evidence 생성. 안내에는 App5267750/Depot5267751/Standard/Notes `v1.3.0 - 74f1753`/Commit Branch None을 기록.
- Content는7파일만, ZIP EXE/PCK 최상위. Evidence·키·세이브·로그·VDF·스크립트는 ZIP 제외. 로그는 Evidence의 검사 증거에만 있고 게임 저장·인증정보는 포함하지 않는다.

## 6. 테스트 및 검수

| 검사 | 최종 결과 | 증거 |
|---|---|---|
| 누락곡 render·bgm_quality | 7/7 PASS | 곡별 generation.json, Evidence/bgm-completion.json |
| 전체 WAV manifest validate | 131 active, planned0, coverage PASS | 명령 출력 |
| V1213U5FTest | 5572 checks PASS | Evidence/u5f.log |
| V122A0AudioManifestContractTest | 15 checks PASS; 구 manifest SHA 보존 | Evidence/manifest.log |
| test_lyria_pipeline.py | 29/29 PASS; SDK retries0 회귀 포함 | Evidence/pipeline-tests.log |
| test_audio_event_catalog.py | 13/13 PASS | Evidence/catalog-tests.log |
| test_v130_bgm_launcher.py | 5/5 PASS | Evidence/launcher-tests.log |
| 공식 Windows Steam export | exit0, errors0 | Evidence/v130-export-exit.json |
| PE 파일·제품 버전 | 1.3.0.0 / 1.3.0.0 | PowerShell VersionInfo |
| 최종 EXE 실제 입력 | KO 타이틀→새 게임→이름→도입→DAY01 관리·저장 후 정상 exit0 | Evidence/final-exe-smoke.json, day1-management-ui.png |
| 최종 EXE 3언어 화면 | KO/EN/ZH_CN 각1920×1080/v1.3.0 직접 확인, exit0/errors0 | Evidence/final-screen-results.json, *-1.3.0.png |
| PCK | 3705엔트리, 금지 리소스0, 신규15곡·누락곡 sample 있음 | Evidence/pck-audit.json |
| depot validator | build errors0; SETUP_PASS, 과거 외부 게이트 pending15개 별도 | Evidence/depot-validation.log |
| ZIP | 7파일·CRC·원본바이트·전체 SHA256 PASS | Evidence/v130-http-zip-verification.json |
| 서버 대조 목록 | 7파일 경로·크기·SHA1/SHA256 준비, 서버 확인 NOT_RUN | Evidence/v130-http-expected-server-files.json |
| 1.2.12 폴더 보존 | 기존 사전 기준 35파일 해시 전부 일치 | Evidence/v1212-preservation.json |
| 키·스테이징·형식 | key pattern hits0, unrelated import/UID 포함0, diff --cached --check PASS | Evidence/source-checks.json |
| repository-policy | PASS: 892 final files / 166 commits, 검사 HEAD4484f72·제품74f1753 | Evidence/repository-policy.log |
| 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED / 이번 실행0 | 사용자 표적 범위 |

초기 카탈로그 검사의 순서 실패1건은 신규 자산을 manifest 순서로 옮겨 해결했고 기대값 변경0. 첫 export 두 번은 격리 프로필 템플릿 부재/복사 대상 프로필 불일치로 실패했다. 설치된 공식4.6.3 release template를 실제 export 프로필에 복사한 뒤 최종 export 성공, 제품 설정 변경0. 초기 외부 --script 방식은 출시 EXE에서 검사 실행을 확인할 수 없어 제한시간 종료했고 PASS로 세지 않았다. 이후 외부 드라이버 없이 실제 UI 입력과 정상 종료로 대체했다. ZIP 첫 검증의 Windows 경로 대소문자 정렬 차이는 비교 목록을 정렬해 수정했으며 실제 ZIP·내용을 다시 만들지 않았다. 모든 실패 로그는 tmp/v130_release에 보존.

실행은 Godot 또는 최종 EXE를 한 번에1개만, 매 실행 전후0을 확인했다. 최종0. GUI의 virtual keyboard unsupported 경고1종은 기록하되 script/resource ERROR0과 구분했다. 3언어 캡처는 최종 EXE --write-movie 첫 타이틀 프레임, 각 격리 프로필에서 순차 실행했다.

### 정책 CI용 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 74f175365d77dbb67619099a160ee1821147946b
- Review range: 0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b..74f175365d77dbb67619099a160ee1821147946b
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 제한

요청한 BGM·출시 후보 준비에 남은 필수 실패0. 전체 회귀·자연30일·Steam 실설치·2PC Cloud·실기 터치·보컬 직접 청취는 이번 미실행이며 전체출시 PASS로 확대하지 않는다. 기존 depot validator의 외부 설정/과거 게이트 pending15개는 새 Windows export/ZIP 실패가 아니고, 외부 상태를 이번에 확인하거나 변경하지 않았다.

## 8. 다음 작업

헤드가 위 제품SHA·Evidence·ZIP을 인수한다. 업로드/Commit/default/공지 게시 및 push·merge·태그는 이번 지시로 금지·미실행. 실제 공개 조치는 새 명시 지시가 있어야 한다. 추가 BGM API 호출은 필요하지 않다.

## 9. 작업 트리 상태

제품17파일을 영어 로컬 커밋74f1753으로 고정. 이후 docs/handoff만 수정한다. 기존 .import1423개·무관 미추적.uid31개 보존·커밋 제외. 사전1454파일 바이트 전부 일치. Godot이 새로 생성한 미추적UID44개도 커밋 제외하여 최종 미추적UID는75개다. 브랜치 전환/reset/stash/git add -A/강제push0. 이번 새 오디오 .import1개만 포함했다. tmp/v130_release, tmp/v130_bgm, tmp/lyria_audio_v130와 외부 Ready 폴더는 소스 Git 제외.

## 10. 종료 체크리스트

- [x] 누락1곡 승인된 추가1회 성공·원본/출처/요청·비용 기록
- [x] 신규15곡 관련 지정 검사 전부 PASS·기대값 변경0
- [x] 실제15곡 패치노트3언어·문서공백3건만 정리
- [x] 공식 export·최종EXE 실제DAY1·3언어 버전 캡처
- [x] Content7파일·ZIP·Evidence·업로드 안내·1.2.12 보존
- [x] 새 검증SHA·제한·CURRENT 기록, 로컬 영어 커밋만
