# 첫 정상 승리 v5 저장 P1 — 의회 자료의 레거시 회차 삽입 수정

## 메타데이터와 승인

2026-10-13 UTC. Who Guards the Demon Castle / bluehige/mawangseong-demo / Steam5267750. 버전1.2.11, Godot4.6.3 유지. Branch `codex/fresh-v5-result-save-fix`, base `519464518e3c7856f6a69e783362d22d6b72c218`, Product/Reviewed SHA **b1a9e502cafc8a18d6161c4757fec9bdc1ebf96f**. 이후 변경은 핸드오프/CURRENT 문서만. 로컬main 부재·origin/main0ac9fdc7의 원격 최신성 미검증 유지; 원격 push/merge 없음.

사용자 승인 ‘그래 버전문제면 수정해야지 진행하고 보고해’에 따라 새 격리 게임의 첫 승리 저장 실패를 최소 수정했다. 레거시 보호를 끄거나 기존 진행을 신규 모드로 강제 변환하지 않는다. 새 게임 첫 정상 승리→저장→별도 실행 로드 및 영향을 받는 레거시 경계만 수행하며 전체 스킬 검사는 반복하지 않는다. 부모 Cloud/Linux 실플레이의 후속 검증용 최소 패키지를 전달한다.

## 원인과 실제 호출 순서 — Cloud 통신 실패 아님

부모가 확인한 base80335024/PCK BDAAF764...의 정상 새 게임 첫 승리에서 `진행 중 v4 레거시 회차에는 Update 4 상태를 삽입할 수 없습니다`가 표시됐다. 원인 호출 순서는 다음과 같다.

1. `CombatSceneController.finish_combat`가 모든 모드에서 `native_objectives.before_result()`를 호출한다.
2. 이전 `NativeObjectiveRuntime.before_result`는 활동이 없어도 `run_metrics_update4.native_1f_objectives={adapter:actual_1F,metrics:{},losses:[]}`를 무조건 삽입했다. 외부 dict가 비어 있지 않게 된다.
3. 첫 스토리 캠페인은 기존 LEGACY 호환 모드를 사용한다. `_flush_campaign_autosave`의 v1 쓰기→`_write_campaign_v2_snapshot`의 v2/v3/v4→v5 쓰기에서 `CampaignSaveV5Store.write`가 먼저 `SaveV4ToV5Migrator.validate_v5`를 호출한다.
4. 그 validator의 LEGACY_MODE/nonempty run_metrics_update4 거부 조건은 올바른 기존 세이브 보호다. v5의 FileAccess 쓰기 전에 거부되고, 바깥 `CampaignSaveBundleGuard.restore`가 이전 다섯 체크포인트 파일을 되돌린 뒤 저장실패 안내를 표시한다. 화면의 승리 진행이 새 디스크 체크포인트에 반영되지 않는 P1이다.

이 경로에는 Steam/SteamAPI/Steamworks/RemoteStorage/GodotSteam 호출이 없다(실제 scripts 검색0, packed native extension0). FileAccess와 DirAccess로 로컬 파일을 기록한다. Auto-Cloud는 이 게임의 스키마 검증기 호출이 아니며, 부모가 확인한 Steam 문서의 실행/종료 로컬파일 동기화와 별개다. Cloud 미접속이나 Linux 격리환경만의 무시 가능한 통신 오류로 해석할 수 없다. Steam 로그인/설정 변경은 진단에 필요하지 않아 하지 않았다.

## 최소 변경과 기존 호환성

| 생산 파일 | diff |
|---|---|
| scripts/combat/NativeObjectiveRuntime.gd | before_result의 bag 정리는 유지하고, 의회 모드가 아니면 의회 전용 metric 직렬화 전에 return. 3줄 추가 |
| scripts/game/GameRoot.gd | 새 게임에서 Update4 profile/run 및 cached v5 envelope 정리. 기존 preserve_story_read_state=true 다음 회차 경로는 earned Update4 profile을 유지. 4줄 추가 |
| tools/tests/FirstVictorySaveBoundaryTest.gd | 기존 PCK+실제 최종 compiled patch에서 정상 입력/실제 전투/디스크 저장/새 프로세스 로드 및 관련 보호 경계만 검증하는 standalone harness |

**생산7줄 삽입, validator/migrator/기존 회차 분류/저장 경로/슬롯/Cloud 등록 변경0.** 실제 v4 진행을 새 회차로 바꾸지 않는다. 능력치/해금일/적수/보상/스킬/그림 변경0.

## 검증과 실패 기록 구분

| 검사 | 결과와 한계 |
|---|---|
| 정상 New Game→이름→도입 대화→고블린 배치→첫 방어 승리→RESULT v5 디스크 확인 | **PASS15/0**. 실제26초 전투·정상 3명/실제 적, forced finish·기존 저장 없음. 대화는 기계 입력으로 넘겼으므로 사람13분 플레이/재미 증명 아님 |
| 완전히 별도 엔진 프로세스 시작→Continue→첫 RESULT 복원 | **PASS7/0**. DAY/resources/roster EXP·bond/result/mode/Update4 metric을 빠짐없이 같은 JSON 표현으로 비교, 보상 재지급 없음 |
| 실제 fresh writer의 v4를 v5로 migrate / 기존 LEGACY mode 유지 / council metric 삽입 거부 / 거부 뒤 기존 합성 v5 bytes 보존 / council metric 기록 유지 / New Game 이전 Council context 제거 / 다음 회차 earned profile 유지 | **PASS12/0**, 합성 격리 프로필만 사용 |
| 최종 exported compiled4resource patch 생성 / 최종 Bootstrap 실제 Main | 성공 / **90frames exit0·ERROR/SCRIPT ERROR0** |
| 정상 승리·재시작 2PNG | 실제 엔진 화면 직접 확인. 방어 성공·성장 확인 화면과 동일 복원, 저장 실패 toast 없음 |
| 개인698개+기존 백업 | **mismatch0** |
| 다른 전체 스킬/전체 회귀/자연 전체해금/사람 재미·밸런스/두PCCloud | **NOT_RUN**, 반복하지 않음 |
| Linux 실제 새 게임 첫 승리·저장·로드 | DK 로컬은 NOT_RUN. **부모 Cloud native CUA 표적 PASS** 후속 보고 확인; 아래 기록 참조 |

중간 source-remap overlay는 의존 script resolution으로 boot 실패해 전달본에서 제외했다. 최종은 full export에서 변경된 .gdc/.remap만 추출한4resource patch다. 최초 restart 비교 **FAIL6/1**은 JSON 숫자 Variant 형식 차이였으며, Python 구조 대조에서 실제 저장 필드 값 차이0이었다. 어떤 자원·보상·상태 필드도 생략하지 않고 양쪽 JSON 표현을 통일해 **그 실패 restart 사례만** 재실행했다. 첫 승리15·레거시12 PASS를 반복하지 않았다. 중간 로그/결과를 삭제하거나 전체PASS로 승격하지 않는다. 가상 키보드 미지원 WARNING은 디스플레이의 알림이며 Script/ERROR는 없다.

Review task ID NOT_REQUESTED, Remaining P1/P2 N/A(전체제품), Final review result TARGETED_PASS(이 저장 P1/인계 범위). 자연 플레이/출시 전체PASS 주장은 하지 않는다.

## 진단 ZIP 수신 제한

부모 Library `libfile_3046854c12d48191b4888a7c670e7034` / Mawang-8033502-FirstVictory-SaveFailure.zip을 정확한 ID로 resolve했다. 공식 current materialization helper는 Windows Python `os.setxattr` 미지원으로 최종 ZIP 설치에 실패했다. 최종 파일 존재/가독성은 확인하지 못했고 원본 ZIP을 읽었다고 주장하지 않는다. 사용자 지시에 따라 우회/재시도/원본 변경0. supplied stack·toast와 matching source call order로 진단·수정을 계속했다. 실패 로그는 `evidence/fresh-save-p1/library-helper/materialize-error.txt`에 보존했으며 transfer의 서명 URL은 인계/패키지에 넣지 않았다.

## 부모 후속 검증용 최소 패키지 — 개인 Library 성공

- 파일 `Mawang-FirstVictory-SaveFix-b1a9e50.zip`, **2137973 bytes**, SHA256 **BBE490A657BD9C98237D9D51B197C8A16854E6BFB472FC32F407EFA6B981346C**.
- Library **libfile_76ff7a9ba2d88191a1bd63db120e2e89**, File Service **file_000000004dac820997990bcf62bc70f8**, version0, create status succeeded. Share/public access 호출0. Windows xattr의 이미 확인된 실패를 재시도하지 않고 exact ID/version/xattrs를 delivery JSON에 보존했다.
- 포함: **FreshVictorySavePatch.pck 524284 bytes**, source.diff, manifest, Bootstrap, Linux 격리 launcher, README, 관련 로그/합성 결과/2PNG/보존 숫자. 기존 base PCK/개인 세이브/진행파일/계정/SDK/비밀은 포함하지 않는다.
- Patch SHA256 **F79D8C3237B57FF213388E818CB18F6D9CDD3CAE179FB2E939C5D2899381D912**. 원래 base803 PCK SHA256 **BDAAF764C8F413275B7BB5577A3A09BDCC42D7C98BAC22ACC753AB716E8E8B00**가 반드시 필요하다.

같은 Godot4.6.3에서 `BASE_PCK=/absolute/path/to/MawangCastle.pck GODOT_BIN=/absolute/path/to/godot bash ./launch-linux.sh`. 이 launcher는 해시를 확인하고 별도 XDG data/config/cache를 잡은 뒤 Bootstrap이 실제 Main 생성 전에 변경4리소스를 mount한다. patch 자체를 --main-pack으로 실행하거나 다른 base 버전에 적용하지 않는다. 기존 base 파일은 변경하지 않는다.

다음: 아래 부모의 Linux 실제 CUA 표적 PASS에 따라 중단했던 의미있는 선택/결과 가독성/재도전 이유 검토로 복귀한다. 부모 worker의 남은 약7분 DAY2/성장 표시 검토는 진행 중이며 결과 대기다. 공개Steam/개발자전용 해제/원격push·merge/SDK계약·보안변경0. source b1a9e50와 작업루트 `evidence/fresh-save-p1`이 복구 지점이다.

## 부모 Cloud native CUA 후속 표적 PASS — 새 검사 재실행 없음

부모 thread `01a118bb-f1ec-7077-b2ce-7197fcdef0cc`의 직접 실행 결과 보고를 기록한다. DK에서 재실행하거나 새 assertion 수로 합산하지 않았다. 제품 b1a9e50·patch 해시 확인 후 새 격리 프로필 ‘천둥남작’, 동일 곱 전열로 정상 DAY1 승리했다. 오류 toast 없이 result 체크포인트가 자동 저장됐다.

마지막 자동 저장을 사용하는 정상 Quit 후 **별도 엔진 프로세스**를 시작하고 Continue로 동일 결과를 복원했다. 종료 전 수동 저장 우회는 사용하지 않았으며 복원 후 메뉴 Save도 성공했다. 전후 parsed current-state의 **monsters/game_state/result/checkpoint/screen 모두 동일**했고 gold1443·mana300·EXP22/20/19·bond6/5/3을 유지해 보상 중복이 없었다. 기존 실패 프로필은 보존했다.

판정은 **이 로컬 저장 P1의 실제 Linux/Cloud native CUA 경로 PASS**다. Steam Cloud 동기화 또는 두 PC 검증 PASS가 아니며, 실제 Steam Cloud2PC·공개 배포는 별도 NOT_RUN이다. DAY2/성장 표시·선택의 재미/다음 방어 재도전 이유는 부모가 계속 검토 중이라 완료로 주장하지 않는다. 이 기록 추가에 제품 코드·패치·기존 Library 산출물 변경0, 새 검사0.
