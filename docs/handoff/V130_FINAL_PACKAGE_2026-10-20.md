# Steam 1.3.0 최종 패키지 — 사용자 확인 대기

## 1. 메타데이터

- 작성일: 2026-10-20 KST / WORKSTREAM_ID: V130-FINAL-PACKAGE-20261020.
- 목표 버전: 1.3.0 / PE 파일·제품 버전: 1.3.0.0.
- 작업 브랜치: `codex/v130-final`; 작업트리: `C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-v130-final`.
- 빌드 기준·Reviewed SHA: `e70e04c24b61b65b493b48baa1285556170dc47f` (`codex/v131-patch`, 0130~0134 포함).
- 마지막 문서 커밋 SHA: `git log -1 -- docs/handoff/V130_FINAL_PACKAGE_2026-10-20.md`; 실제 SHA는 외부 `Evidence/final-head-checks.json`의 documentation_head에도 기록한다. 빌드 입력 SHA와 문서 커밋을 구분한다.
- 로컬 main 부재, origin/main 캐시 `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; 원격 최신성 미확정. 사용자 지정 e70e04c2를 우선했고 원격 조회·fetch·push·PR·태그·main 변경0.

## 2. 이번 세션 목표

사용자 결정(10/20 08:54) **“0134까지가 1.3.0 완성”**에 따라 e70e04c2의 최종 로컬 Steam 준비 패키지를 만든다. 0135 밸런스는 중단 상태로 보존하며 이번 빌드에 포함하지 않는다. Steam 로그인·SteamCMD 실행·업로드·Steamworks 편집·default·공지는 모두 NOT_RUN이다.

전용 새 브랜치·worktree를 e70e04c2에서 만들고 처음과 export 직전 `HEAD=e70e04c2 / git status clean`을 확인했다. `.godot` 캐시는 새 import했다. Godot GUI 실행 파일을 직접 호출하여 동시 최대1개, 최종0개를 지켰다.

## 3. 완료한 작업

- `Windows Steam` release export 성공. 제품 코드·스토리·데이터·밸런스·저장 형식 추가 변경0. 0135 미커밋 변경 배제.
- Desktop Ready의 Content10파일·manifest·VerifyContent·새 SHA ZIP·Scripts identity/VDF Desc·HTTP 안내·3언어 패치노트·Evidence 갱신. 기존 ZIP/Evidence는 `_old/before-final-e70e04c2-20261020/` 보존.
- 기존 패치노트 내용을 유지하고 깨진 과거 핫픽스 문구를 복구했다. 전투 팝업, 패널/툴팁 크기, 상단 탭 확대, 튜토리얼 버튼 강조, 투명 초상26종+니아, 대화 넘김 지연 감소, 숨은 전투 UI 갱신 중지를 3언어로 정리했다.
- 업적122파일·START_HERE 바이트 보존, 업적100/스탯20/아이콘100/추가세트7 게임 API 대조 재실행. START_HERE의 참조 파일·업적 우선 게시·SetLive 빈 값 확인.
- 실제 Content EXE의 정상 새 게임→DAY1 승리→DAY2 팝업→특화1/1→DAY2 전투 시작·대화 넘김→전체화면→저장→종료0 확인. 니아 사각 배경 없음 직접 확인.
- DAY1 교전 캡처는 기존 QA 체크포인트 `130401_1.json`을 새 테스트 프로필에 실제 저장 API로 왕복해 보완했다(37검사). 캡처 사본만 `legacy_cutover_day=2`로 반복 DAY1 대화를 생략했고 몬스터/웨이브/능력치 변경0. 최종 프레임은 DAY1·웨이브3/3·남은 적2·10.5초를 OCR로 확인했다. 직접 이미지 열람15장 제한 때문에 그 최종 프레임을 추가 직접 열람하지 않았다.

## 4. 변경 파일

| 경로 | 내용 |
|---|---|
| `docs/handoff/V130_FINAL_PACKAGE_2026-10-20.md` | 이 인계 |
| `docs/handoff/CURRENT.md` | 최종 패키지 진입점 |
| 외부 `Steam-1.3.0-Ready/Content/`, `Scripts/package_identity.json`, `Scripts/app_build_5267750.vdf` | e70e04c2 패키지/Desc |
| 외부 `MawangCastle-v1.3.0-SteamContent-e70e04c24b61.zip` | Content 최상위10파일 ZIP |
| 외부 `PATCH_NOTES_{KO,EN,ZH_CN}.txt`, `HTTP_UPLOAD_1.3.0_KO.md`, `Evidence/` | 최종 안내·검증·6장 증거 |

소스 커밋에는 인계 문서2개만 넣는다. 빌드/캡처/도구 임시 사본은 커밋하지 않는다.

## 5. 그래픽 및 오디오 자산

신규 생성·후처리·런타임 자산 변경0. e70e04c2의 GPT 네이티브 투명 초상과 기존 NEXON MapleStory·음원을 그대로 사용한다. 데이터 참조 PNG/AtlasTexture154경로 사각 배경0, 레이아웃360검사 통과. 0132 출처는 기존 SOURCE.md와 V131_PORTRAIT_ALPHA 인계를 유지한다.

## 6. 테스트 및 검수

| 검사 | 결과 |
|---|---|
| 새 import / Windows Steam export | exit0 / exit0·오류0. export의 빠진 UID 캐시 재생성 경고121개 별도 기록 |
| VerifyContent / PE / 공식 DLL / PCK / ZIP | Content10파일·PE1.3.0.0·해시와 ZIP 전체 엔트리 일치, PCK5060항목·행정CSV/QA/원본 제외 |
| 준비 도구·업적 자료 | API100/스탯20/아이콘100/세트7, 정상/오류 CSV와 mock 업로더 PASS(실제 Steam 실행0) |
| 24종 실제 디스크 저장 왕복 / QA 구v1~v6 | 1912 / 42검사 PASS |
| B01 unit / replay | 172 / 48검사 PASS |
| 0130 전투 버튼 / 0131 UI / 튜토리얼 흐름 | 84 / 1917 / 87검사 PASS |
| 0132 초상 / 0133 대화 재사용 | 360 / 237검사 PASS |
| 명령 | 236검사 PASS |
| 0121b 넘침 / 대화 입력 | 336076배치·116832검사·228조합·넘침0 / 41검사 PASS |
| 0134 숨은 UI | QA 사본10검사 PASS: 숨은 갱신0·동일 전투 복귀·비시각 알림·DAY29 무전투 유지 |
| 실제 Content EXE / 보완 재현 EXE | 모두 정상 종료0·런타임 오류0. 주 실행의 기존 guardian 아이콘 경고1 유지 |
| 캡처/직접 이미지 | 증거PNG6장, 직접15장·모두960px 이하 사본. 추가 프레임은 OCR만 사용 |
| 전체 회귀·전체 수동 캠페인·별도 전체 검수 | NOT_REQUESTED / 미실행 |

근거: 외부 `Evidence/regression-summary.json`, 개별 로그/JSON, `computer-use-checks.json`, `package-checks.json`, `final-head-checks.json`. 초상 첫 시도는 감사 JSON 준비 누락으로 실패했다. 해당 fixture를 생성한 뒤360검사를 재실행해 통과했고 제품 변경0이다. 최초 교전 캡처는 승리 대화로 넘어가 미채택했으며 최종 02 PNG로 대체했다.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: e70e04c24b61b65b493b48baa1285556170dc47f
- Review range: e70e04c24b61b65b493b48baa1285556170dc47f..e70e04c24b61b65b493b48baa1285556170dc47f
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

이번 판정은 사용자 지정 SHA의 로컬 패키지와 요청된 표적 검사·EXE 경로에 한정한다. 기존 G01 실제 출시 저장 출처·G02 실서버 업적 게이트, 과거 난도/배치 비교·진단 전환 충돌·ObjectDB 기록을 새로 해결한 것으로 주장하지 않는다. 사용자 결정에 따라0135 밸런스는 중단하며 자동 재개하지 않는다.

Computer Use의 물리 키 매핑은 새 게임 외 복사본에서 다를 수 있어 마우스 넘김을 사용했다. 주 실행에서 Alt+Enter는 전환 근거를 얻지 못했고, 설정→전체화면→적용 경로로1920×1080과 저장 완료를 확인했다. 일반 키보드 결함 해결을 주장하지 않는다. 두PC Cloud·Steam 실설치·실서버 업적/BuildID·manifest/default는 미검증/NOT_RUN.

## 8. 다음 작업 순서

**사용자 확인 대기.** 준비 폴더와6장 증거를 검토한다. Steam 로그인·업적 게시·업로드·공개 적용은 이번 실행 범위 밖이며 자동 진행하지 않는다.

## 9. 작업 트리 상태와 0135 보존

`mawangseong-v131-patch`는 HEAD `e70e04c24b61b65b493b48baa1285556170dc47f`와 아래13개 미커밋 파일을 상태·SHA256 대조로 그대로 보존했다. stash/reset/체크아웃 전환/파일 수정0.

```text
 M data/v122/dual_front_day01_05_waves.json
 M data/waves.json
 M scripts/combat/WaveManager.gd
 M scripts/game/ApprovedBattleController.gd
 M tools/run_v130r_b04.py
 M tools/run_v130r_engage.py
 M tools/tests/V130RB04Campaign.gd
 M tools/tests/V130RB04FastController.gd
 M tools/tests/V130REngagementSample.gd
 M tools/tests/V130REngagementTest.gd
 M tools/tests/v130r_b04_report.py
 M tools/tests/v130r_b04_report_test.py
?? tools/run_v131_balance.py
```

새 worktree는 import/export가 만든 메타데이터만 복원하여 문서 작성 직전 clean을 재확인했다. 마지막 커밋 뒤에는 새 worktree clean이며 제품 파일은 e70e04c2와 동일하다. 원래 action worktree의 기존 변경도 건드리지 않았다. 사용자 저장 원본 접근·수정0; 기존 QA 복사본과 이번 새 테스트 프로필만 사용했다.

## 10. 종료 체크리스트

- [x] e70e04c2 전용 clean 빌드 /0135 제외 /버전1.3.0 유지.
- [x] 관련 표적 검사·실제 Content EXE·6장 증거·격리 저장·정상 종료.
- [x] 업적122파일·START_HERE·중단0135 변경 보존.
- [x] 인계/CURRENT 갱신·영어 로컬 문서 커밋만.
- [x] Steam 로그인·업로드·Steamworks·push·태그·main0, Godot/게임 종료0.

ZIP: `MawangCastle-v1.3.0-SteamContent-e70e04c24b61.zip` (847,104,986 bytes), SHA256 `11c535133bded48bbf6786f20cd84c9250963365e42f4a124e2969697c3b68f4`.

사용자 확인 대기.
