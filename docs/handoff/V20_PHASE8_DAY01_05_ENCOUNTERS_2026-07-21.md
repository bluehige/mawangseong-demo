# 제품 2.0 Phase 8 DAY 1~5 encounter 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p08-day01-05-encounters`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `54d16f40d1e0644061eee3bce6515772a003ccbc`
- 마지막 제품 커밋 SHA: `163ba4e14de3f9520fbdacf69298932f6d0513f1`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #52

## 2. 이번 세션 목표

- 요청 사항: DAY 1~5를 서로 다른 목표·경로·특수 패턴·대응 선택이 있는 첫 버티컬 슬라이스로 재구축한다.
- 완료 조건: 매일 목표와 예상 경로를 사전 표시하고, 각 phase에 두 개 이상의 대응이 있으며, DAY 2~5는 DAY 1 고정 전략만으로 통과할 수 없다.
- 범위에서 제외한 사항: 난이도·경제 프로필, v2 저장·재시도·온보딩, 실제 사람 판매성 검증.

## 3. 완료한 작업

- 구현: DAY 1 정면 탐험가, DAY 2 왕좌·보물 분리, DAY 3 공병 시설 무력화, DAY 4 방패병 보호 후열, DAY 5 영웅 돌파 후 반대 경로 증원을 deterministic schedule로 선언했다.
- 경로·전투 연결: Phase 4 weighted path로 각 spawn의 목표·경로를 결정하고 기존 `WaveManager` 입력으로 변환한다. v2 gate가 켜진 DAY 1~5에서만 적용한다.
- 대응·결산: phase별 response tag, 실패 지표, 결과 지표, outcome signature를 기록하고 전술 명령의 response tag를 현재 예고 phase에 연결했다.
- UI/UX: 전투 HUD에 다음 특수 패턴, 시작까지 남은 시간, 권장 대응을 한국어로 표시한다.
- 저장 및 호환성: encounter state는 전투 session 상태이며 저장하지 않는다. 공개 v1.2 wave catalog와 방어 modifier 경로는 v2 gate가 꺼진 상태에서 불변이다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/encounters.json` | DAY 1~5 목표·preview·phase·spawn·대응·실패/결산 계약 | 완료 |
| `scripts/v20/encounters/V20EncounterService.gd` | schedule·telegraph·response·결과·WaveManager adapter | 완료 |
| `scripts/core/DataRegistry.gd` | v2 encounter catalog 별도 로드 | 완료 |
| `scripts/game/CombatSceneController.gd` | v2 encounter 진행·spawn 경로·명령 대응·공병/영웅 연결 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | encounter HUD 상태 갱신 | 완료 |
| `tools/tests/V20DayOneToFiveEncountersTest.*` | 5일 계약·경로·대응·실패·렌더 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 v2 runtime HUD와 폰트·색만 사용했다.
- 게임 연결 및 실제 렌더 확인 결과: `user://v20_phase8_day5_encounter_1280x720.png`에서 DAY 5 패턴명, 6.0초 예고, 권장 대응, 명령력과 네 명령이 겹침 없이 읽힘을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20DayOneToFiveEncountersTest.tscn` headless | PASS, 69 assertions | catalog·schedule·route·telegraph·response·failure·adapter |
| 2 | 동일 test OpenGL `--capture-v20-encounter` | PASS, 70 assertions | 1280×720 실제 렌더 |
| 3 | `V20FacilityReworkTest.tscn` | PASS, 27 assertions | 공병 무력화·경로·시설 회귀 |
| 4 | `V20TacticalCommandsTest.tscn` | PASS, 26 assertions | 명령 response 연결 회귀 |
| 5 | `V20StrategicRoutingTest.tscn` | PASS, 14 assertions | weighted route 회귀 |
| 6 | `DemoSmokeTest.tscn` | PASS | 기존 부팅·CombatScene parse 회귀 |
| 7 | JSON/suite parse와 `git diff --check` | PASS | 변경 파일 |
| 8 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `163ba4e14de3f9520fbdacf69298932f6d0513f1` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 163ba4e14de3f9520fbdacf69298932f6d0513f1
- Review range: 54d16f40d1e0644061eee3bce6515772a003ccbc..163ba4e14de3f9520fbdacf69298932f6d0513f1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: 실제 v2 진입·저장이 Phase 10 전까지 비활성이라 통합 전투의 장시간 흐름은 아직 외부 사용자가 접근하지 않는다.
- 밸런스 관찰 항목: spawn 수·간격·HP 상한은 Phase 9의 예산·동시 목표·예고 시간 프로필에서 조정한다.
- 임시 구현 또는 대체 자산: 신규 그래픽 없음. encounter는 기존 적 catalog와 v2 HUD를 재사용한다.
- 외부 환경/도구 제약: 자동 전략 검사는 사람의 이해도·재미·구매 의향을 대신하지 않는다.

## 8. 다음 작업 순서

1. Phase 9에서 HP 배율 중심이 아닌 건설 예산·동시 목표·예고 시간·명령 자원 난이도 프로필을 선언한다.
2. 프로필을 encounter schedule과 전술 명령 초기 상태에 연결한다.
3. 난이도가 선택 압박을 높이되 전투 시간/HP만 일률 증가시키지 않는 계약 검사를 추가한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase8_day5_encounter_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·1280×720 렌더 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
