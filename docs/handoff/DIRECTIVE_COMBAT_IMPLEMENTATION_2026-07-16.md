# 지시 전용 전투·3배속·UI·PC 한글 입력 구현 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-16
- 목표 버전: 제품 1.2 수정판(기술 SemVer `1.2.0`)
- 작업 브랜치: `codex/v12-directive-combat`
- 기준 브랜치 및 SHA: `origin/main` / `7131110245bc9ea45e4603fe32fdf38e5c2363d9`
- 마지막 기능·테스트 커밋 SHA: `e0da9591d0e317104f0d021509b6a9ba2b958e75`
- 자체 검수 여부: 사용자 요청에 따른 전체 회귀·실플레이·PC·Web 검수 PASS
- 관련 PR 또는 태그: [PR #35](https://github.com/bluehige/mawangseong-demo/pull/35) merge commit `93ba159694cf6010f4ec0f93331913c131f749ce`, 태그 생성 안 함

## 2. 이번 세션 목표

- 단일 유닛 직접 이동·공격·스킬 조작을 제거하고 전역·방 지시만으로 전투를 운영한다.
- 유닛 몸체 이동 충돌과 회피·우회를 제거하고 최대 x3 속도를 제공한다.
- DAY 1~3 초기 조작을 짧은 지시형 흐름으로 바꾼다.
- Windows PC 마왕 이름 입력이 IME 조합 중 끊기지 않도록 입력창 생명주기와 키 소유권을 수정한다.
- 확대 폰트로 깨진 핵심 HUD 배열을 PC·모바일 지정 해상도에서 정상화한다.
- DAY 1~3 튜토리얼은 x1로 진행하고, 완료 뒤 속도 기능을 사용할 수 있는 첫 일반 전투에서 x1~x3 기능을 한 번만 소개한다.
- 완료 조건: 관련 자동 테스트와 밸런스·UI 계약이 통과하고, 실기 확인이 필요한 항목을 분리해 기록한다.

## 3. 완료한 작업

### 전투 조작과 AI

- 직접 조작 상태·명령 지점·개별 이동·공격·지원 API, 우클릭·터치 명령, 숫자키 수동 스킬, 직접 조작/AI 복귀 HUD를 제거했다.
- 유닛 선택은 HP·역할·현재 지시·자동 스킬 상태를 보는 정보 전용 동작으로 유지했다.
- 전역 지시는 `사수`, `총공격`, `생존 우선`, 방 지시는 `집중 방어`, `함정 유도`, `후퇴 지점`으로 정리했다.
- 일반 몬스터 스킬에 지시별 우선순위, 사용 조건, 마나 보존선을 적용했다. 베베·코코·톡톡 등 별도 행동 처리도 자동 AI 경로를 유지했다.

### 충돌과 속도

- 유닛의 `CollisionShape2D`, 충돌 레이어·마스크, 유닛 회피·우회 계산을 제거했다. 공격·스킬 거리, 벽과 던전 경계 제한은 유지했다.
- PC와 모바일에 x1, x1.5, x2, x3, 일시정지를 제공하고 속도를 x3에서 상한 처리했다.
- 유닛 시뮬레이션, 공격·스킬 쿨다운, 투사체 이동, 타격 지연과 짧은 전투 연출 시간을 같은 전투 속도에 맞췄다.
- DAY 1~3 튜토리얼에서는 x1만 허용하고 x1.5~x3 버튼을 비활성화했다. 코드에서 직접 배속을 요청해도 x1을 유지한다.
- 튜토리얼 완료 뒤 처음 진입한 일반 전투는 일시정지한 채 `전투 속도 해금` 안내를 한 번 보여 준다. PC는 오른쪽 아래, 모바일은 아래 두 번째 줄의 속도 버튼 위치와 전투 판정·자동 스킬 동기화를 설명한다.
- 안내 확인 여부를 세이브에 저장한다. 기존 완료 저장은 누락 필드를 정상값으로 받아 다음 일반 전투에서 한 번 안내하고, 새 회차·디버그 건너뛰기에는 반복 노출하지 않는다.

### 이름 입력과 튜토리얼

- 이름 안내를 닫을 때 `LineEdit`를 다시 만들지 않고 기존 인스턴스를 유지한다.
- `LineEdit` 또는 `TextEdit`가 포커스를 가진 동안 전역 게임 단축키가 키 이벤트를 가로채지 않는다.
- IME 조합 중에는 길이를 자르지 않고 확정 시점에 12자 제한을 검사한다. 한글·숫자 혼합 이름의 저장·불러오기 회귀를 추가했다.
- DAY 1은 배치와 방어 지시, DAY 2는 가시 복도와 함정 유도, DAY 3은 후퇴 지점과 자동 화염구 관찰 중심으로 축소했다.
- 삭제된 구형 튜토리얼 단계를 가진 저장은 새 단계 목록에 맞춰 진행 인덱스를 보정한다.

### UI/UX

- 확대 글꼴을 유지하면서 자원 칩, DAY, 마왕성 체력, 시설 효과, 유닛 정보와 전투 하단 조작부의 경계를 재배치했다.
- PC는 6개 지시와 별도 속도 열, 모바일은 6개 지시와 5개 속도·일시정지 버튼의 두 행 구조로 단순화했다.
- 새 렌더 검수 도구가 최대 글꼴 배율에서 직접 조작·수동 스킬 부재, x3, 충돌 비활성화, 버튼 경계와 겹침을 확인한다.

### 밸런스

| 시나리오 | 결과 | x1 시뮬레이션 시간 | x3 체감 환산 | 몬스터 전투 불능 | 왕좌 HP |
|---|---|---:|---:|---:|---:|
| DAY1_AUTO | 승리 | 36.0초 | 약 12.0초 | 0 | 1500/1500 |
| DAY2_TRAP_DIRECTIVE | 승리 | 35.6초 | 약 11.9초 | 1 | 1500/1500 |
| DAY3_ASSISTED | 승리 | 68.7초 | 약 22.9초 | 1 | 1500/1500 |

공격력이나 체력을 추가로 일괄 상향하지 않았다. 충돌 제거와 x3만으로 빠른 체감 목표를 달성하고 세 대표 전투의 승패를 유지했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/units/Unit.gd`, `scripts/core/Constants.gd` | 직접 조작 상태·API와 이동 충돌·회피 제거, 속도 동기화 | 완료·검증 |
| `scripts/game/GameRoot.gd` | 직접 입력 제거, 이름 IME 포커스·확정 검증, 단순 튜토리얼 연결, 속도 잠금·1회 해금 안내 | 완료·검증 |
| `scripts/core/CampaignSaveStore.gd` | 속도 안내 확인 상태의 선택 필드 검증과 구형 저장 호환 | 완료·검증 |
| `scripts/game/CombatSceneController.gd` | 지시 기반 자동 스킬·특수 행동, x3 상한과 전투 시간축 동기화 | 완료·검증 |
| `scripts/ui/HUDController.gd` | PC·모바일 지시 전용 HUD, 튜토리얼 속도 잠금, x3, 확대 글꼴 배열 수정 | 완료·렌더 확인 |
| `data/onboarding_flow_dialogue_v0.4.json` | DAY 1~3 직접 조작 단계를 지시·관찰 흐름으로 교체 | 완료·검증 |
| `scripts/systems/tutorial/TutorialManager.gd`, `FirstPlayObservationSummary.gd` | 새 단계 검증·구형 저장 보정·관찰 문구 수정 | 완료·검증 |
| `tools/DirectiveCombatUIVisualCheck.gd`, `.tscn`, `.gd.uid` | 충돌·x3·지시 HUD·최대 폰트 렌더 계약 추가 | 신규·검증 |
| `tools/OnboardingFlowSmokeTest.gd`, `TutorialFlowSmokeTest.gd`, `MobileTouchUISmokeTest.gd` | 한글 저장, 단순 튜토리얼, 모바일 지시/x3 회귀 | 갱신·검증 |
| `tools/BalanceSimulation.gd`, `DayOneToThreePlaytestRecorder.gd` | 자동 스킬 호출과 새 초반 밸런스 범위 | 갱신·검증 |
| `tools/Update2ContractRosterSmokeTest.gd`, `tools/tests/BebePhase11Test.gd`, `ToktokPhase15Test.gd` | 수동 호출을 AI 호출로 전환하고 자동 예외 행동 검증 | 갱신·검증 |
| `tools/DemoSmokeTest.gd`, `ManualVerificationCapture.gd` | 제거된 직접 조작·충돌 계약과 캡처 절차 갱신 | 갱신·임포트 검증 |
| `docs/design/DIRECTIVE_COMBAT_INPUT_SIMPLIFICATION_PLAN_2026-07-16.md` | 페이즈별 구현 결과 기록 | 갱신 |
| `docs/handoff/CURRENT.md`, 본 문서 | 다음 세션 진입점과 구현 전달 | 갱신 |
| `docs/release/V1_2_RELEASE_NOTES_2026-07-16.md` | 제품 1.2 기능·수정·밸런스·버전 요약 | 신규 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 사용하지 않음
- 생성 모델: N/A
- 생성 원본 경로: N/A
- `SOURCE.md` 경로: N/A
- 런타임 최종 자산 경로: N/A
- 게임 연결 및 실제 렌더 확인 결과: 기존 자산만 사용, 신규 그래픽·오디오 없음

## 6. 테스트 및 검수

| 순서 | 검증 명령 또는 방법 | 결과 | 근거 |
|---:|---|---|---|
| 1 | `OnboardingFlowSmokeTest.tscn` | PASS | 같은 입력창 유지, 확정 한글 12자 검증, `검은성123` 저장 왕복, 튜토리얼 x1 잠금, 첫 일반 전투 안내·해금, 안내 상태 저장 및 구형 저장 호환 포함 |
| 2 | `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 단순 지시 흐름, 직접 공격 명령 부재, 자동 화염구, x3 잠금 포함 |
| 3 | `MobileTouchUISmokeTest.tscn -- --mobile-touch-ui` | PASS | 지시 전용 터치 HUD, 튜토리얼 x3 잠금, 완료 후 안내·x3 변경, 정보 전용 탭 포함 |
| 4 | `BalanceSimulation.tscn -- --assert-tutorial-balance` | PASS | DAY 1~3 승리·시간·생존 기준 통과 |
| 5 | `Update2ContractRosterSmokeTest.tscn` | PASS (68 assertions) | 계약 몬스터 5종 자동 스킬 |
| 6 | `BebePhase11Test.tscn` | PASS (31 assertions) | 베베 자동 구조·빗자루 행동, 수동 토글 부재 |
| 7 | `ToktokPhase15Test.tscn` | PASS (41 assertions) | 톡톡 자동 행동 |
| 8 | `DirectiveCombatUIVisualCheck.tscn` PC | PASS | 최대 글꼴, 1920×1080·1366×768·1280×720, 속도 해금 안내·6개 지시 무겹침·x3·무충돌 |
| 9 | 같은 렌더 검수 `-- --mobile-touch-ui` | PASS | 최대 글꼴, 세 해상도 속도 해금 안내·터치 버튼 경계·상단 HUD·시설 효과 확인 |
| 10 | Godot 4.5.2 전체 스크립트 임포트 | PASS | `--headless --editor --import --quit`, exit 0 |
| 11 | `git diff --check` | PASS | 공백 오류 없음, 줄바꿈 변환 경고만 존재 |
| 12 | Windows 1.2.0 내보내기·실행 | PASS | 타이틀 `버전 1.2`, 한글 이름 입력·Backspace·재입력·시작 전환 확인 |
| 13 | 로컬 PC Web 1.2.0 내보내기·브라우저 조작 | PASS | 1280×720 타이틀·빠른 시작·튜토리얼 대상·지시 메뉴, 경고·콘솔 오류 0건 |
| 14 | `TutorialFlowSmokeTest.tscn` seed 회귀 재검수 | PASS | 빠른 시작 전 양수 회차 seed 생성과 첫 자동 저장 경고 부재 확인 |
| 15 | `RunCoreVerification.ps1 -Mode Full` | PASS (89/89) | `tmp/core_verification/runs/20260716_164248`, 검수 SHA `e0da9591d0e317104f0d021509b6a9ba2b958e75` |

Godot 테스트 종료 시 출력되는 `ObjectDB instances leaked`와 `resources still in use` 경고는 기존 테스트 하네스의 종료 정리 경고이며 테스트 exit code는 0이다.

### 검수 정책 필드

- Review task ID: FULL_REVIEW_2026-07-16_DIRECTIVE_COMBAT
- Reviewed SHA: e0da9591d0e317104f0d021509b6a9ba2b958e75
- Review range: 7131110245bc9ea45e4603fe32fdf38e5c2363d9..e0da9591d0e317104f0d021509b6a9ba2b958e75
- Remaining P1/P2: 0
- Final review result: PASS

최종 검수 뒤에는 본 문서를 포함한 `docs/handoff/` 기록만 변경했다. 기능·데이터·자산 변경은 없다.

## 7. 미해결 항목과 위험

- Windows 네이티브 빌드에서 한글 문자열 입력·Backspace·재입력·확정 전환은 확인했다. 자동화 드라이버가 Windows 전용 `VK_HANGUL`을 지원하지 않아 물리 한/영 전환과 조합 중 상태 자체는 재현하지 못했다. 자동 테스트가 입력창 생명주기·키 소유권·확정 문자열·저장 왕복을 보완한다.
- PC Web은 실제 브라우저로 확인했다. 실제 Android/iOS는 실행하지 않았고 모바일 레이아웃은 Windows 네이티브 터치 프로필로 확인했다.
- 전체 회귀 1차 84/89의 5건을 수정하고 후보 SHA `6530e231e859f01d046d82158078a9571e42b9ac`에서 88/89를 확인했다. 남은 베베 테스트는 직전 왕좌 침입 적이 자동 구조보다 긴급 방어를 먼저 유발한 테스트 조건 문제였고, 조건 격리 뒤 최종 SHA에서 89/89를 통과했다.
- DAY 3의 x1 시뮬레이션은 68.7초지만 x3 체감은 약 22.9초다. 사용자 플레이에서 여전히 길다면 적 수·웨이브 간격을 별도 조정하고 공격력을 일괄 상향하지 않는다.

## 8. 다음 작업 순서

1. 후속 선택 사항으로 실제 한국어 물리 키보드와 Android/iOS 기기에서 입력·안전 영역을 확인한다.
2. 실제 사용자 관측에서 DAY 3가 여전히 길면 적 수와 웨이브 간격만 조정한다.

## 9. 작업 트리 상태

- 현재 브랜치: `codex/v12-directive-combat`, `origin/main` 추적
- 미커밋 파일: 사용자 소유 미추적 `.uid` 5개만 보존
- 보존한 사용자 미추적 파일:
  - `tools/tests/FinaleEveHardeningTest.gd.uid`
  - `tools/tests/Update3BaselineContractTest.gd.uid`
  - `tools/update3_baseline/Update3BaselineSpec.gd.uid`
  - `tools/update3_baseline/Update3BaselineSummary.gd.uid`
  - `tools/update3_baseline/Update3BaselineTrial.gd.uid`
- 별도 백업 stash: `stash@{0}` (`codex directive combat plan 2026-07-16`), 드롭하지 않음
- 원격 푸시 여부: `origin/codex/v12-directive-combat` 푸시, PR #35로 `main` 병합 완료
- 빌드/캡처 산출물: `builds/MawangCastle_v1.2.0/`, `tmp/` 아래 검수 산출물은 Git 제외, 커밋 대상 없음

## 10. 종료 체크리스트

- [x] 직접 조작·수동 스킬 제거와 정보 전용 선택 전환
- [x] 지시 기반 자동 스킬·특수 행동 이관
- [x] 이동 충돌·회피·우회 제거와 공격 판정 유지
- [x] PC·모바일 x3와 시간축 동기화
- [x] 튜토리얼 x1 잠금과 완료 후 첫 일반 전투의 1회 속도 해금 안내
- [x] 이름 입력 IME 생명주기·키 소유권·유니코드 저장 수정
- [x] 확대 글꼴 핵심 HUD 배열과 DAY 1~3 조작 단순화
- [x] 관련 자동 테스트·밸런스·지정 해상도 렌더 검수
- [x] 요청받은 전체 89종 후보 SHA 검수와 P1/P2 0건 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 사용자 기존 미추적 파일 보존
