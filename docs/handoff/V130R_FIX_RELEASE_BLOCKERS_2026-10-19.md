# V130R 출시 차단·권장 항목 수정 — 2026-10-19

## 1. 메타데이터

- 목표 버전: 1.3.0, 0120b 출시 재점검 후속
- 작업 브랜치: `codex/v130r-defense-layout`
- 기준 SHA: `a5ab80ec1b746f37fc6a44ab242cfbeb3c9a61d5` (감사 제품 기준 `e40eb91c4902e72237783508105004be7e4d989e` 이후 HEAD)
- 제품 수정 커밋: `2595c854f831e1bf63a96520515f189ad0b227a1`
- 최종 구현·검수 대상 SHA: `58cab224928f3ffb57c4973d95bdcd34b51582b1`
- 마지막 커밋 SHA: 최종 문서 커밋은 세션 최종 응답 및 Git 로그 참조. 검수 대상 이후 제품 변경 없음.
- 원격 푸시/PR/태그: 없음. 영어 로컬 커밋만 수행. push/fetch/Git 원격 조회/Steam/main 조작 없음.
- 권위 한계: 로컬 `main` 없음. 캐시 `origin/main=0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`의 최신성 미확인. 캐시 AGENTS/CURRENT를 읽었으며 최신 제품 권위를 확정하지 않음. 사용자 지시와 지정 브랜치를 작업 기준으로 삼음.

## 2. 이번 세션 목표

[0120b 재점검](../../_mockup/release_audit_v130b/RELEASE_AUDIT.md)의 N01/N02/N03/V01/V02 및 waves 보호 해시를 수정하고 요청된 표적 검증을 완료한다. 사용자 세이브 원본, DAY29 무전투, waves·스탯·밸런스 수치, 신규 그림 생성, 공개 배포는 변경 범위에서 제외했다.

**결과: TARGETED_PASS (이번 수정·표적 검증 범위). 사용자 확인 대기.** 전체 출시 승인으로 대체하지 않는다.

## 3. 완료한 작업

- **N01**: v1 종→개체 변환표에 신규 10종 `river_frog`, `glue_snail`, `bridge_troll`, `under_bed_shadow`, `crumpled_map`, `hollow_armor`, `candle_wisp`, `mole_digger`, `rat_union`, `curse_doll`의 기존 카탈로그 ID를 추가했다. 기존 14종을 포함한 24종 전체를 전수 확인했다.
- N01에 가려졌던 추가 차단도 수정했다. 자유 배치의 실제 출전 인원이 구형 Stage 한도를 넘으면 v3 변환 검사가 실패했다. `_campaign_save_payload()`에서 자유 배치일 때만 저장용 한도를 `max(구형 한도, 실제 출전 인원)`으로 기록한다. 실전 출전/식량/슬롯/밸런스 규칙과 구형 로드 검사는 변경하지 않았다. 저장용 출전 목록 24종도 왕복 확인했다.
- 보조 스냅샷 실패의 기존 묶음 복구와 짧은 화면 안내는 유지하고, 게임 로그 누락·잘못된 v5 경고 이름·복구 자체 실패 문구를 보완했다.
- **N02**: `_mockup/.gdignore`로 감사 CSV의 번역 테이블 자동 수입을 차단했다. 게임의 JSON 번역 자료는 그대로 사용한다. EXE 초상화는 `FileAccess.file_exists()`가 포장된 PNG를 찾지 못해 신규 종이 없는 구형 fallback 사전과 빈 리소스 경로에 진입했다. `ApprovedMonsterPlacementUI.portrait()`를 `ResourceLoader.exists()`로 수정했다. 관련 없는 임시 QuarterDungeonRenderer 방어 코드는 최종 변경에서 제거했다.
- **N03**: Approved 전투 시작 때 꺼 둔 GameRoot 입력이 승리 정산 후 복구되지 않았다. `ApprovedBattleController.settle_result()`에서 입력을 복구한다. 기존 대사 키 설정은 유지했다. 실제 EXE 승리 대사에서 Space 다음 줄과 Escape 게임 메뉴를 확인했다.
- **V01**: 번역 후 커진 Label 높이를 포함해 설정 카드 여백·후속 행·스크롤 높이를 계산한다. 지연 계산으로 실제 글 배치 후 높이도 반영한다. en/zh_CN의 5개 설정 분류를 검사했다.
- **V02**: 클릭을 통과시키는 업적 알림을 y22에서 y176으로 내려 우상단 메뉴/뒤로 영역을 확보했다. 그림은 생성하지 않았다.
- **데이터 무결성**: `data/waves.json`은 수정하지 않았다. 현재 CRLF SHA256 `2d5b3519c6bf6a630a099844d07a2db92a5646fe5425db7d3ff392168205b539`가 0119c 최종 `0dec2aacda020cd0c76a3c5358a3ecb760ed5294` Git blob과 줄바꿈 정규화 후 동일하다. LF blob SHA256은 `b102662f864b5a5c53f880e2cef66854e15d8a56687e7c49a9e4d42564f8f384`. manifest 보호값만 갱신하고 이전 값·의도 커밋·CRLF 규약·근거를 기록했다.

## 4. 변경 파일

| 경로 | 목적 | 상태 |
|---|---|---|
| `_mockup/.gdignore` | 출시 차단·권장 항목 수정 | 완료 |
| `data/v130r/story/manifest.json` | 보호 기준 갱신 | 완료 |
| `scripts/achievements/AchievementToast.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `scripts/core/CampaignSaveMigratorV1ToV2.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `scripts/game/ApprovedBattleController.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `scripts/game/GameRoot.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `scripts/map_builder/ApprovedMonsterPlacementUI.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `scripts/ui/SettingsWorkspaceUI.gd` | 출시 차단·권장 항목 수정 | 완료 |
| `tools/run_v130r_release_blockers.py` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseBlockersTest.gd` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseBlockersTest.tscn` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseLayoutTest.gd` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseLayoutTest.tscn` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseLegacyTest.gd` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseLegacyTest.tscn` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseCampaign.gd` | 표적 검증 도구 | 완료 |
| `tools/tests/V130RReleaseCampaign.tscn` | 표적 검증 도구 | 완료 |
| `docs/handoff/V130R_FIX_RELEASE_BLOCKERS_2026-10-19.md` | 수정·검증·제한 인계 | 완료 |
| `docs/handoff/CURRENT.md` | 지정 브랜치 진입점 갱신 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규/수정 그림·오디오 없음. GPT 이미지 생성 사용하지 않음. 기존 초상화의 export 로드 판정만 변경.
- en/zh_CN 설정 960×540 사본 2장을 직접 확인했다.
- 실제 EXE 지정 캡처 3장: [타이틀](../../tmp/v130r_release_blockers/captures/01_title.png), [DAY1](../../tmp/v130r_release_blockers/captures/02_day1.png), [재시작 후 이어하기](../../tmp/v130r_release_blockers/captures/03_continue.png). 모두 960px 이하 사본.
- **이미지 제한 이탈 1건**: 첫 Computer Use 자동 스크린샷을 1282×752 원본으로 전달했다. 이후 원본 이미지 전달을 차단하고 960px 이하 사본만 직접 열람했다. 총 직접 열람 12장(설정2+EXE10), 추가 EXE 화면은 축소 사본의 OCR 텍스트만 확인했다. 이미지 크기 제한 완전 준수로 기록하지 않는다.

## 6. 테스트 및 검수

재현: `python -X utf8 tools/run_v130r_release_blockers.py <mode>`. 설치된 godot.cmd에서 실제 EXE를 찾고, Godot 1개씩만 실행한다. APPDATA/LOCALAPPDATA는 `tmp/v130r_release_blockers/profiles/`로 격리하고 `MAWANG_DISABLE_STEAM=1`을 사용한다. 전체 로그는 tmp에만 보존하고 대화에는 요약만 보고했다.

| 명령/방법 | 결과 | 근거 (`tmp/v130r_release_blockers/`) |
|---|---|---|
| `unit`: 24종 실제 디스크 v1~v6 왕복 | PASS **1,912검사**, 오류/경고0 | `unit_checks.json`, `runs/unit.json` |
| `legacy`: 기존 v1~v6 사본 | PASS **42검사**, 오류/경고0 | `legacy_checks.json`, `runs/legacy.json` |
| `layout`: en/zh_CN × 설정5분류 + toast | PASS **108검사**, 오류/경고0 | `layout_checks.json`, `settings_en.png`, `settings_zh_CN.png` |
| `export`: Windows Desktop release | PASS, 오류/경고0 | `runs/export.json`, `export/MawangCastle.exe` |
| `exe`: 실제 새 게임→DAY1 저장→정상 종료 | PASS, 종료0·오류/경고0 | `runs/exe.json`, 캡처1/2 |
| `exe_resume`: 실제 재시작→Continue→DAY1, 전투 승리 대사 Space/Escape | PASS, 종료0·오류/경고0 | `runs/exe_resume.json`, `native_checks.json`, 캡처3, `victory_*_ocr.json` |
| `campaign`: seed130401 새 게임→DAY30 엔딩→후기 저장 | PASS **819검사**, 29승·DAY29 무전투·재시도0·오류/경고0 | `campaign_130401_checks.json`, `campaign_130401_days.json` |
| `resume`: 별도 프로세스 후기 복원 | PASS **14검사**, 11개 상태 영역 동일·오류/경고0 | `campaign_130401_resume_checks.json` |
| 스토리 보호 검증기 | PASS **73,027검사**, 오류0 | `_mockup/story_v130r/validation_report.json` |
| `python -X utf8 -m unittest discover -s tools/content -p test_validate_v130r_story.py` | PASS **13테스트** | 대화 명령 결과 |
| 대상 `git diff --check`, Python 문법, waves/스탯 불변 비교 | PASS | `source_integrity.json` |
| 전체 회귀·별도 검수 에이전트 | NOT_REQUESTED, 미실행 | 요청된 표적 캠페인만 실행 |

- 24종 테스트는 기억 목록, 유대/등급, 전문화, 전직, 레벨/경험치, 배치 참조, 부상 HP/최대HP/전투결과, 식량/허기를 비교한다. 구형 한도를 넘는 저장용 출전 목록도 보존한다. JSON 숫자의 정수/실수 표현만 정규화한다.
- 기존 v1~v5는 `tmp/v130_m6/original_copies/`, v6는 이전 감사의 격리 EXE `tmp/release_audit_v130b/export_computer_use/appdata/` 사본을 다시 격리 복사했다. 입력 사본 SHA256 불변을 검사하고 `legacy_checks.json`에 기록했다. v6의 본래 DAY2 dialogue 체크포인트도 보존했다. 실제 Steam 출시 세이브의 출처 증거를 대신하지 않는다.
- 실제 EXE는 정상 Main 진입과 Computer Use 클릭/키를 사용했다. 제품 세이브를 고쳐서 통과시키지 않았다. 승리 대사 `Victory…` → Space → `Strictly speaking…` → Escape → `Game menu/Resume/Save/Quit`를 OCR로 기록했다.
- **진단 이력**: 구형 Stage 한도 실패를 발견한 첫 캠페인은 383.06초에 중단했다(오류0/중복 경고932). PASS가 아니며 `diagnostic_campaign.*`에 분리했다. 이후 tools/tests 하네스의 저장 쓰기가 기본 비활성화된 사실을 중간 디스크 검사에서 발견해 해당 실행도 중단했다(`diagnostic_save_disabled_campaign.*`). 자동 저장 성공 증거로 채택하지 않는다. `58cab224`에서 6개 격리 저장 경로를 켜고, 실제 v6 파일 존재와 DAY30 완료/후기 플래그의 디스크 읽기 검사를 필수화했다. 최종 실행은 새 `campaign_verified` 프로필이다.
- Windows debug export는 로컬 debug 템플릿 부재로 실패해 사용하지 않았다. 원인 파악용 editor+PCK 프로브의 확장 DLL/구형 초상화 오류는 최종 release EXE 로그와 구분했다.
- 최종 연속 실행 **1,411.34초**, 별도 재시작 **11.23초**. 엔딩 `monster_family_castle`, 최종 HP **845/2500**. 실제 v6 파일의 DAY30 완료/후기 플래그를 확인했고 별도 프로세스의 날짜·자원·식량/허기·동료·배치·엔딩 등 11개 영역이 동일했다. 종합: `verification_summary.json`.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 58cab224928f3ffb57c4973d95bdcd34b51582b1
- Review range: a5ab80ec1b746f37fc6a44ab242cfbeb3c9a61d5..58cab224928f3ffb57c4973d95bdcd34b51582b1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 이번 요청의 수정·표적 검증에 남은 차단 없음. 전체 회귀·모든 난도·Steam 온라인 검증은 이번 PASS 범위가 아니다.
- 감사의 G02 Steam 서버/정의 등록, 실제 출시 세이브 출처, 기존 난도/배치/명령 손해 수용 여부는 이번 수정으로 해제하지 않는다.
- 로컬 main 부재/원격 최신성 미확인, 첫 이미지 크기 제한 이탈을 유지한다.

## 8. 다음 작업 순서

1. **사용자 확인 대기**: 이 인계, 요청된 수정, 대표 캡처 3장을 검토한다.
2. 기존 난도·출시 출처·Steam 서버 증빙은 별도 범위로 결정한다.
3. 공개 배포·태그·Steam·main 작업은 실행하지 않는다.

## 9. 작업 트리 상태

- 기존 import 수정 **1,307개**, 미추적 STEP10C/감사 산출물과 `.uid`를 보존했다. 사용자 변경을 되돌리거나 `git add -A`하지 않았다.
- 위 17개 구현/테스트 경로만 명시적으로 스테이징해 `2595c854`, `58cab224`에 커밋했다. 이후 인계/CURRENT 문서만 변경한다.
- 사용자 세이브 원본 접근/수정 없음. 기존 사본만 격리 복사했다. EXE 언어 설정은 격리 테스트 프로필의 settings.cfg만 변경했다.
- 산출물: `tmp/v130r_release_blockers/`. EXE/PCK/DLL/캡처/로그는 소스 커밋에 넣지 않았다.
- Godot 동시 실행 1개 이하, 최종 **0개**. 검수 대상 소스 해시 drift0. push/태그/Steam/main 조작0.

## 10. 종료 체크리스트

- [x] N01/N02/N03/V01/V02/해시 요구사항 구현
- [x] 24종 왕복·구버전 사본·설정·export·실제 EXE 검증
- [x] DAY30 후기 저장·프로세스 재시작 복원
- [x] 요청 없는 전체 회귀·별도 에이전트 미실행
- [x] 밸런스·DAY29 정책·사용자 세이브 보존
- [x] CURRENT 갱신·명시적 문서 스테이징·Godot0
- [x] 로컬 영어 커밋만, 사용자 확인 대기
