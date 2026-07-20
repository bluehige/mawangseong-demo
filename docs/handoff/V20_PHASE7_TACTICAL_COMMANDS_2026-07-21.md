# 제품 2.0 Phase 7 전술 명령 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p07-tactical-commands`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `73fe32b296c869e36dad97a764c70ccccd631ae2`
- 마지막 제품 커밋 SHA: `362bf248ca03a55bed1bee900e5b745297eda7a0`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #51

## 2. 이번 세션 목표

- 요청 사항: 자동 전투를 관찰만 하지 않도록 집결·집중·시설 발동·비상 명령과 명령력 자원을 연결한다.
- 완료 조건: 명령 spam이 불가능하고, 사용/미사용이 같은 패턴의 결과를 바꾸며, 전투 HUD에 네 명령 상태가 보인다.
- 범위에서 제외한 사항: DAY 1~5 encounter 본문, 난이도별 명령력 수치, 최종 결과 UI, 모바일 UI.

## 3. 완료한 작업

- 구현: 명령력 3점, 12초 회복, 비용·cooldown·지속시간·대상 검증·활성 효과·결산 지표를 관리하는 deterministic 서비스를 추가했다.
- 전투 연결: 집중 표적/피해, 집결·비상 후퇴의 강제 이동/이동 속도/피해 감소, 시설 charge 발동을 v2 활성 전투 경로에 연결했다.
- 패턴 대응: 명령별 response tag를 선언하고 동일 패턴에서 사용/미사용 결과 signature와 남은 압력이 달라지는 평가를 추가했다.
- UI/UX: 전투 하단 네 버튼에 현재 명령력, 각 비용 또는 cooldown, 비활성 상태와 설명을 직접 표시한다.
- 저장 및 호환성: 전투 중 command state는 아직 session 상태이며 저장하지 않는다. 공개 v1.2 HUD와 전투 경로는 v2 gate가 꺼져 있어 불변이다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/v20/commands.json` | 네 명령의 대상·비용·cooldown·효과·response·metric 계약 | 완료 |
| `scripts/v20/commands/V20CommandService.gd` | 명령력·발동·회복·효과·pattern 평가 | 완료 |
| `scripts/core/DataRegistry.gd` | v2 명령 catalog 별도 로드 | 완료 |
| `scripts/game/CombatSceneController.gd` | v2 전투 HUD·AI·피해·시설 발동 연결 | 완료 |
| `scripts/units/Unit.gd` | v2 명령 이동 multiplier 소비 | 완료 |
| `scripts/v20/ui/V20InformationHUD.gd` | 명령력·비용·cooldown·disabled 표시 | 완료 |
| `tools/tests/V20TacticalCommandsTest.*` | 서비스·패턴 차이·HUD·렌더 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 기존 폰트·색과 runtime UI만 사용했다.
- 게임 연결 및 실제 렌더 확인 결과: `user://v20_phase7_commands_1280x720.png`에서 네 명령, 명령력 2/3, 집중 8.0초 disabled, 속도 버튼이 겹치지 않고 읽힘을 확인했다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20TacticalCommandsTest.tscn` headless | PASS, 26 assertions | catalog·자원·대상·cooldown·facility·pattern·HUD |
| 2 | 동일 test OpenGL `--capture-v20-commands` | PASS, 27 assertions | 1280×720 실제 렌더 |
| 3 | `V20MonsterRoleGrowthTest.tscn` | PASS, 39 assertions | Phase 6 역할 회귀 |
| 4 | `V20InformationArchitectureTest.tscn` | PASS, 33 assertions | 1280/1366/1920 HUD 배치 회귀 |
| 5 | `DemoSmokeTest.tscn` | PASS | 기존 부팅·CombatScene parse 회귀 |
| 6 | JSON/suite parse, Godot editor import, `git diff --check` | PASS | 변경 파일 |
| 7 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `362bf248ca03a55bed1bee900e5b745297eda7a0` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 362bf248ca03a55bed1bee900e5b745297eda7a0
- Review range: 73fe32b296c869e36dad97a764c70ccccd631ae2..362bf248ca03a55bed1bee900e5b745297eda7a0
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: Phase 8 encounter가 pattern response tag와 실제 spawn/telegraph를 연결해야 한다.
- 밸런스 관찰 항목: 초기 3점, 12초 회복, 비상 후퇴 2점은 Phase 9에서 난이도·패턴 밀도와 함께 조정한다.
- 임시 구현 또는 대체 자산: 신규 그래픽 없음. 명령은 Phase 2 runtime UI를 재사용한다.
- 외부 환경/도구 제약: 자동 pattern 결과 차이는 사람의 이해도·재미 판정이 아니다.

## 8. 다음 작업 순서

1. Phase 8에서 DAY 1~5 encounter preview·phase·spawn·response·failure metric을 선언한다.
2. 실제 enemy ID와 weighted route, facility/command response를 scheduler에 연결한다.
3. 각 패턴 대응 두 개 이상과 DAY 5 고정 배치 실패를 관련 검사로 고정한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: `user://v20_phase7_commands_1280x720.png` (커밋 안 함).

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트·1280×720 렌더 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
