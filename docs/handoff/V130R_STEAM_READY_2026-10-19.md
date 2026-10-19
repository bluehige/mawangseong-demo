# V130R Steam 1.3.0 출시 패키지 준비 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-19 KST / 목표 버전: 1.3.0 (PE 1.3.0.0)
- 작업 브랜치: `codex/v130r-defense-layout`
- 시작 기준 SHA: `73227dcb69d1bec62becc07368d6472a9d9e6cd2` (0123 교정 이후 HEAD)
- 구현·표적 검증 커밋: `6ea21a7ad3d0e596e588574999e119031f53d697`
- 마지막 코드 커밋 SHA: 위 구현 커밋. 이후 `docs/handoff/` 문서만 로컬 커밋한다. 문서 커밋을 포함한 최종 패키지40자리 SHA는 출력 폴더 `Content/steam-build-manifest.json` 및 `Scripts/package_identity.json`에 기록한다.
- 원격 푸시/태그/PR/main 변경: 없음. 로컬 main 부재, 캐시 origin/main=`0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 원격 조회/fetch 없이 최신성 미확정. 캐시 origin/main 정책·CURRENT와 브랜치 최신 CURRENT를 읽고 최신 사용자 범위를 우선했다.
- 사용 스킬: `mawangseong-steam-release`(준비·선례만), `computer-use`(실제 EXE), `karpathy-guidelines`(변경 최소화). 독립 에이전트는 공식 자료 읽기 전용 조사만 수행했으며 전체 검수 에이전트가 아니다.

## 2. 이번 세션 목표

집에서 업적 등록·게시와 업로드 버튼 실행만으로 진행할 수 있는 로컬 준비물 완성. Steam 로그인·SteamCMD 실행·업로드·Steamworks 계정 화면 편집·게시·default 변경은 **전부 실행 금지/미실행**. 비밀번호·토큰·로그인 캐시를 읽거나 패키지에 복사하지 않았다. 실제 업적 등록/해제·서버 파일·BuildID는 사용자 후속이다.

출력: `C:/Users/blueh/Desktop/진행중인프로젝트/Steam-1.3.0-Ready/`.

## 3. 완료한 작업

- `Windows Steam` 공식 release export. Steam 기능 포함, QA autoload/`MAWANG_DISABLE_STEAM` 차단 없음. EXE/PCK와 공식 GodotSteam4.23.1/Steamworks1.65의 release DLL·steam_api64.dll 포함. steam_appid.txt 제외.
- 업적 CSV4개의 기존 `importer="keep"` 확인. export 플러그인에서도 업적 폴더 비JSON 파일과 `_mockup/`, `builds/`를 제외했다. 런타임 카탈로그·규칙 JSON은 유지. PCK4,990항목에 업적 CSV/translation·QA·원본·steam_appid 없음.
- Content10파일(실행4, 고지1, 라이선스4, manifest1). GodotSteam MIT·Steamworks 고지와 공식 Godot4.6.3 `COPYRIGHT.txt`, 기존 폰트 라이선스 포함. manifest는 버전·전체 SHA·모든 배포 파일의 크기/SHA256/SHA1·공식 DLL 해시를 담는다.
- `VerifyContent.py`: 파일 목록/크기/해시, 소스 버전, 필수DLL·라이선스, 실제 PE 파일·제품 버전 확인.
- `Upload_1.3.0.cmd` → 검증 → 중복 확인 안내/UPLOAD → 저장 로그인 한 번. 인증 실패가 명확하고 빌드 시작 증거가 없을 때만 사용자가 CONSOLE을 선택하여 공식 콘솔에서 직접 로그인·run_app_build 한다. 콘솔 입출력/비밀번호/Guard를 캡처하지 않는다. 성공 BuildID만 최소 결과에 기록한다. 불확실한 전송/timeout은 재시도하지 않는다. SetLive는 빈 값이다. 실제 호출은 수행하지 않았다.
- Content 전체와 엔트리별 해시가 같은 HTTP ZIP 및 `HTTP_UPLOAD_1.3.0_KO.md`, Builds 링크, 패치노트 KO/EN/ZH_CN. ZIP 최상위는 EXE/PCK/DLL이며 Content 접두 폴더 없음. 최종 ZIP 이름·해시는 `Evidence/package-checks.json` 참조.
- 업적100개·스탯20종·숨김8개·추가세트7개 정합성 대조. `_ACHIEVED.png`100개(모두256×256)와 아이콘 ZIP, 공식 속성 설명 순서의 스탯 입력표, 3언어 세트 이름표. 실제 Stats UI 필드 배치는 미접속으로 확인 필요라고 표시.
- `Make_Achievement_CSV.cmd`: 실제 세트ID7개만 입력하면 기존 `prepare_steam_import.py`로 정의100행·업적 현지화200행·세트 현지화7행의 CSV3개를 생성한다. ID누락/중복/양의정수가 아님/REPLACE_WITH 잔존은 실패. 실제 서버 ID 존재 확인은 하지 않는다. 시험용 ID 결과는 임시 폴더에서만 만들고 폐기했으며 최종 Generated 폴더에 넣지 않았다.
- `START_HERE_KO.md`: 업적 등록·게시30~60분 → 업로드5~30분 → 원할 때 default·공지5~15분. 업적 게시를 default 전에 완료하도록 명시했다.
- 스토리·밸런스·게임 저장 형식/사용자 세이브 변경 없음. 새 그래픽/음원 생성 없음; 기존 승인 아이콘 원본/출처 유지.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| `addons/steam_release_export_filter/steam_release_export_filter.gd` | 행정CSV/불필요 자료 제외 | 완료 |
| `legal/THIRD_PARTY_NOTICES.txt` | GodotSteam·SDK 고지 | 완료 |
| `tools/achievements/prepare_steam_import.py` | ID 검증·현지화CSV2종 추가 | 완료 |
| `tools/release/steam_ready/` 12파일 | 검증·조립·사용자 실행 도구/안내/패치노트/표적검사 | 완료 |
| `docs/handoff/V130R_STEAM_READY_2026-10-19.md`, `CURRENT.md` | 인계·진입점 | 완료 |

## 5. 그래픽 및 오디오 자산

기존 `assets/achievements/v130/icons/`100개를 그대로 복사했다. 새 생성·후처리·원본 변경 없음. 256×256 PNG서명·API 파일명 전수 확인. 화면은 Content EXE를 Computer Use로 실제 실행하여 확인했다.

## 6. 테스트 및 검수

| 명령/방법 | 결과 | 외부 출력 폴더 Evidence 근거 |
|---|---|---|
| `python tools/release/steam_ready/check_preparation.py` | PASS; 100/20 API,100아이콘,7세트,CSV 정상/오류 입력, SteamCMD mock 경로 | `preparation-checks.log` |
| 격리 소스 `--headless --editor --import` → `--export-release "Windows Steam"` | exit0, stderr0; 공식 Godot4.6.3 | `import.log`, `export.log`, `*.err.log` |
| `VerifyContent.py` / PCK 인덱스 / ZIP 전엔트리 대조 | PASS; PE1.3.0.0, 공식DLL 해시, 불필요CSV/translation 없음 | `package-checks.json`, `pck-paths.json`, `expected-server-files.json` |
| 별도 임시 Content에서 버전/추가파일/누락DLL/같은크기 변조/PE버전 오류 | 모두 거부 PASS | `content-negative-checks.json` |
| 전달될 Achievements 폴더 사본에서 ID7개 입력 스크립트 | CSV3종 생성 PASS; 가짜ID 결과 미전달 | 위 검사JSON |
| Content 실제 EXE, Steam 미실행·차단변수UNSET, 격리 APPDATA | 타이틀→새 게임/이름선택→DAY1 지도→격리 저장/타이틀→종료0. stderr0. DLL2개 로드 확인 | `computer-use-checks.json`, `preliminary-execution.json`, `01-title.png`, `02-new-game.png`, `03-day1.png` |
| 기존 혼합 변경 보존 | 추적 import1,307개 바이트 일치 | `baseline-tracked-changes.json`, 최종보존JSON |
| 전체 회귀/전체 플레이/별도 전체 검수 에이전트 | NOT_REQUESTED / 미실행 | 사용자 범위 |
| Steam 로그인/업로드/서버검증/default/공지/실계정 업적 해제 | NOT_RUN | `upload-result.txt` 초기 상태 |

문서 커밋 뒤 최종 HEAD로 다시 export하고 패키지를 조립한다. 이미 확인한 EXE/PCK/DLL/고지·라이선스9파일과 최종 파일의 해시 비교, 최종 manifest SHA·ZIP 검증은 `Evidence/final-head-checks.json`에 남긴다. 같으면 위 실제 조작 근거가 최종 Content에도 적용된다. 변경된 게임 파일이 있으면 실제 조작을 재확인한다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 6ea21a7ad3d0e596e588574999e119031f53d697
- Review range: 73227dcb69d1bec62becc07368d6472a9d9e6cd2..6ea21a7ad3d0e596e588574999e119031f53d697
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

실제 세트ID7개/Steamworks 설정·게시/클라이언트 해제/서버BuildID·manifest/default·공지 모두 사용자 작업이다. G01 실제 출시 세이브 출처, G02 실서버 업적 게이트와 기존 비차단 밸런스 권장은 앞선0121c 인계에서 유지하며 이번 패키지 검증으로 대체하지 않는다. 전체 회귀·전체 플레이는 요청받지 않아 수행하지 않았다.

공식 업적 문서에서 새 편집기의 `Manage Achievements`, `Bulk Import/Export`, CSV3종, API명 `_ACHIEVED`, `Automatically generate unachieved icons`, `Save imported data`를 확인했다. 로그인한 UI의 스탯 필드 배치·세트 생성 버튼·최종 게시 버튼은 확인 필요로 표시했다. HTTP Standard는1.2.12 실제 성공 선례를 따르며 공식 부분갱신 문서의 Merge With Baseline과 구분한다.

공식 근거(2026-10-19):

- https://partner.steamgames.com/doc/features/achievements/ach_guide?l=english
- https://partner.steamgames.com/doc/features/achievements?l=english
- https://partner.steamgames.com/doc/sdk/uploading
- https://partner.steamgames.com/doc/sdk/updating/partial_depot
- https://raw.githubusercontent.com/godotengine/godot/4.6.3-stable/COPYRIGHT.txt

## 8. 다음 작업 순서

1. 집에서 `Achievements/STEAMWORKS_ACHIEVEMENTS_KO.md`대로 등록·게시. 생성될 CSV3종과 서버20stats/100업적을 확인한다.
2. 동일 Desc 빌드가 없을 때 `Upload_1.3.0.cmd`를 실행. 실패 시 HTTP 대안. 새BuildID를 확인하고 Content 서버 파일 목록과 대조한다. 중복 업로드 금지.
3. 원할 때만 default 지정과3언어 공지. 이 세션은 어떠한 공개 조치도 수행하거나 승인하지 않는다.

**사용자 확인 대기.**

## 9. 작업 트리 상태

기존 tracked import1,307개와 다수 미추적 `_mockup/`·`.uid`·이전 작업물을 보존했다. git add에 해당 경로를 넣지 않았다. 빌드 입력은 커밋 archive를 `tmp/steam_ready_v130/source`로 추출한 사본이며 기존 혼합 변경을 포함하지 않는다. 최종 문서 외 신규 소스 수정은 로컬 영어 커밋에 모두 포함했다. 산출물·로그·캡처는 Desktop 준비 폴더와 기존 정책상 제외되는 tmp에만 있으며 소스 커밋에 넣지 않았다.

## 10. 종료 체크리스트

- 구현/요구사항 대조, 표적검사·Windows Steam export·실제 EXE 확인 완료.
- 코드 커밋 뒤 docs/handoff만 변경. CURRENT 갱신. 로컬 영어 커밋만.
- Steam 로그인/업로드/편집/게시/default0, 사용자 세이브 접근·수정0, push/fetch/태그/main0.
- Godot/게임 동시 최대1개, 실제 EXE 정상 종료 뒤0개. 최종 HEAD 패키지 검증 상세는 외부 Evidence에 남긴다.
