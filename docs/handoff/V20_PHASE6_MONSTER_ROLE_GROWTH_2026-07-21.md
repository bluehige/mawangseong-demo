# 제품 2.0 Phase 6 몬스터 역할 성장 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-21
- 목표 버전: 제품 2.0 / 기술 SemVer 2.0.0
- 작업 브랜치: `codex/v20-p06-monster-roles`
- 기준 브랜치 및 SHA: `origin/release/v2.0` / `8799c7a7d1bdd5febb9a5c4b7866523722d806ac`
- 마지막 제품 커밋 SHA: `ccfa61bf9a34dfab709ce8bcce9679196ff1ee99`
- 원격 푸시 여부: 푸시 완료
- 관련 PR 또는 태그: PR #50

## 2. 이번 세션 목표

- 요청 사항: 기존 슬라임·고블린·임프의 두 특화를 경로·시설·전투 행동에 연결한다.
- 완료 조건: 각 두 빌드가 이동, 표적, 시설 synergy와 결산 지표를 다르게 생성한다.
- 범위에서 제외한 사항: 신규 특화 선택지, 특화 획득 시점 변경, 전술 명령 자원·cooldown, encounter와 최종 밸런스.

## 3. 완료한 작업

- 구현: specialization의 v2 역할 계약을 해석해 표적·이동 anchor·weighted route·시설 synergy·명령 affinity를 만드는 deterministic 서비스를 추가했다.
- 전투 AI: v2 활성 경로에서 역할 서비스의 표적과 이동을 소비하고 역할 결정·시설 synergy 지표를 누적하도록 연결했다. v1.2 비활성 경로는 기존 AI를 유지한다.
- 스토리 및 데이터: 기존 성문 파수/구조 점액, 도둑 사냥꾼/마무리 칼날, 장거리/함정 화염술 여섯 항목에만 v2 역할 계약을 추가했다.
- 밸런스: 기존 stat multiplier와 skill upgrade는 바꾸지 않았다. Phase 7 명령 multiplier 소비를 위한 affinity만 선언했다.
- UI/UX: 변경 없음.
- 저장 및 호환성: 기존 specialization ID와 저장 필드는 불변이다. 새 계약은 누락돼도 기존 AI가 작동하는 추가 필드다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `data/specializations.json` | 기존 여섯 특화에 v2 이동·표적·시설·명령·지표 계약 추가 | 완료 |
| `scripts/v20/monsters/V20MonsterRoleService.gd` | 역할 계획·weighted route·synergy·결산 서비스 | 완료 |
| `scripts/game/CombatSceneController.gd` | v2 활성 전투 AI 역할 어댑터 | 완료 |
| `tools/tests/V20MonsterRoleGrowthTest.*` | 세 몬스터의 두 빌드 차이 검증 | 완료 |
| `tools/tests/core_verification_suite.json` | 관련 검증 scene 등록 | 완료 |

## 5. 그래픽 및 오디오 자산

- GPT 내부 이미지 생성 사용 여부: 아니오
- 생성 모델: 해당 없음
- 생성 원본 경로: 해당 없음
- `SOURCE.md` 경로: 해당 없음
- 런타임 최종 자산 경로: 변경 없음
- 프롬프트/후처리/크롭/알파 처리 요약: 해당 없음
- 게임 연결 및 실제 렌더 확인 결과: UI 변경이 없어 별도 캡처를 만들지 않았다.

## 6. 테스트 및 검수

| 순서 | 검수 명령 또는 방법 | 결과 | 근거 경로 |
|---:|---|---|---|
| 1 | `V20MonsterRoleGrowthTest.tscn` | PASS, 39 assertions | 역할 계약·이동·표적·경로·시설·집중 명령·결산 |
| 2 | `BalanceSimulation.tscn -- --assert-specialization-choices` | PASS | 기존 특화 선택 회귀 |
| 3 | `V20FacilityReworkTest.tscn` | PASS, 27 assertions | Phase 5 시설 회귀 |
| 4 | `DemoSmokeTest.tscn` | PASS | CombatSceneController parse·기존 부팅 회귀 |
| 5 | JSON/suite parse, Godot editor import, `git diff --check` | PASS | 변경 파일 |
| 6 | 전체 회귀·전체 플레이·검수 에이전트 | NOT_REQUESTED | 별도 요청 없음 |

### 검수 에이전트 반복 기록

| 회차 | 검수 작업 ID | 검수 범위 (`base..head`) | 대상 최종 SHA | 주요 지적 | 수정 내용 | 근거 경로 | 재검수 결과 |
|---:|---|---|---|---|---|---|---|
| 1 | NOT_REQUESTED | N/A | `ccfa61bf9a34dfab709ce8bcce9679196ff1ee99` | 별도 검수 에이전트 요청 없음 | 해당 없음 | 해당 없음 | N/A |

- 남은 P1/P2 지적: N/A
- 실행하지 못한 필수 검수와 이유: 없음.
- PASS 이후 기능·데이터·자산 변경 여부: 없음. 이후 변경은 `docs/handoff/` 문서뿐이다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: ccfa61bf9a34dfab709ce8bcce9679196ff1ee99
- Review range: 8799c7a7d1bdd5febb9a5c4b7866523722d806ac..ccfa61bf9a34dfab709ce8bcce9679196ff1ee99
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 버그 또는 회귀 위험: v2 활성 진입과 전투 session 상태는 Phase 10에서 연결되므로 현재 공개 v1.2 흐름에서는 역할 어댑터가 비활성이다.
- 밸런스 관찰 항목: 명령 affinity는 Phase 7에서 명령력·cooldown과 함께 검증해야 한다.
- 임시 구현 또는 대체 자산: 없음.
- 외부 환경/도구 제약: 자동 역할 차이는 사람의 재미·가독성 판정이 아니다.

## 8. 다음 작업 순서

1. Phase 7에서 집결·집중·시설 발동·비상 후퇴 명령과 명령력 자원을 선언한다.
2. 전투 HUD action을 명령 서비스에 연결하고 spam 방지·대상·지속시간을 검증한다.
3. 명령 사용/미사용이 같은 패턴의 결과 지표를 다르게 만드는 관련 검사를 통과한다.

## 9. 작업 트리 상태

- `git status --short --branch` 결과: 제품 변경은 커밋·푸시했고 사용자 소유 미추적 UID 5개만 보존한다.
- 미커밋 파일: 사용자 소유 미추적 UID 5개.
- 의도하지 않은 기존 변경: Phase 0부터 보존 중인 UID 5개.
- 스태시 또는 별도 작업공간: 없음.
- 빌드/캡처 산출물 위치: 없음.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 전체 회귀·검수 에이전트 미요청 기록
- [x] 검수 대상 최종 SHA 기록
- [x] 신규 자산 없음 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [x] 의도한 파일만 커밋
- [x] 원격 푸시 및 PR 상태 기록
