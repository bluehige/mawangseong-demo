# v1.2.6 사용자 피드백 AI·관리 UX 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-08-20
- 목표 버전: `1.2.6`
- 작업 브랜치: `codex/v126-user-feedback-ai-ux`
- 기준 SHA: `e8aca24c435fc64d3ec6a6079623185ed0232010`
- 제품 수정 SHA: `608a3da47dcfdb0e1bb259a96130e214d9c55e4a`
- 원격 푸시 여부: 아니오
- 관련 피드백: `FDB-20260820-001`~`FDB-20260820-004`

## 2. 이번 세션 목표

- 몬스터 AI의 방 지침 범위·우선순위를 예측 가능하게 만든다.
- 방 지침의 수락·적용 대상·현재 행동을 화면에서 확인 가능하게 만든다.
- DAY 2 보물 보관실 전선의 건설 슬롯 발견과 확정 흐름을 단순화한다.
- 방 이름표가 전면 소품·벽에 가려지는 문제를 수정한다.
- 스토리·오디오·전체 캠페인 재검수·원격 배포는 범위에서 제외한다.

## 3. 완료한 작업

- 세 방 지침을 명시적 명령·왕좌 긴급 대응 뒤, 자율 역할 AI보다 먼저 하나의 resolver에서 평가하도록 정렬했다.
- 입구·함정 지침이 반대 전선 몬스터에게 전역 적용되지 않도록 선택 방·인접 배치 범위로 제한했다.
- `사수`가 연결로 존재만으로 반대 전선을 추격하던 분기를 제거하고, 후퇴선은 현재 방을 지키는 경계로 바꿨다.
- 방 지침 수락 토스트, 맵 지속 배지, 선택 몬스터의 적용 지침·현재 행동 표시를 추가했다.
- 빈 슬롯에 `+ 건설 가능` 배지를 표시하고, 보물실 같은 전선 추천·시설 효과 tooltip을 연결했다.
- 모든 지도 건설 클릭을 `미리보기 → 명시적 확정 → 1회 비용 차감`으로 통일했다.
- 선택 방 이름표를 z=0 정적 맵에서 z=60 월드 오버레이로 이동했다.
- DAY 2 안내 대사에 건설 가능 슬롯을 추가했다.

## 4. 변경 파일

| 경로 | 변경 목적 | 상태 |
|---|---|---|
| `scripts/game/CombatSceneController.gd` | AI·방 지침 범위, 우선순위, 피드백 | 완료 |
| `scripts/game/GameRoot.gd` | 방·지침·건설 배지, 미리보기 입력 | 완료 |
| `scripts/game/ManagementSceneController.gd` | 건설 슬롯 제목·보물 전선 추천 | 완료 |
| `scripts/ui/HUDController.gd` | 몬스터 적용 지침·현재 행동 동적 표시 | 완료 |
| `scripts/dungeon_quarter/QuarterDungeonRenderer.gd` | 가려지는 z=0 이름표 제거 | 완료 |
| `data/onboarding_flow_dialogue_v0.4.json` | DAY 2 건설 슬롯 안내 | 완료 |
| `tools/**`, `tools/tests/**` | AI·건설·토스트·시각 회귀 | 완료 |

## 5. 그래픽 및 오디오 자산

- 신규 그래픽·오디오 생성: 없음
- 기존 전면 보물실 자산은 유지하고 이름표 렌더 계층만 수정했다.

## 6. 테스트 및 검수

| 검수 | 결과 | 근거 |
|---|---|---|
| `V122Day02FeedbackTest` | PASS | `tmp/postcommit_V122Day02FeedbackTest.log` |
| `V122DefenderConnectorTest` | PASS | `tmp/postcommit_V122DefenderConnectorTest.log` |
| `V122CommandButtonIntegrationTest` | PASS | `tmp/postcommit_V122CommandButtonIntegrationTest.log` |
| `V122ManagementInteractionTest` | PASS | `tmp/postcommit_V122ManagementInteractionTest.log` |
| `DayOneToThreePlaytestRecorder` | PASS | `tmp/postcommit_DayOneToThreePlaytestRecorder.log` |
| `DemoSmokeTest` | PASS | `tmp/postcommit_DemoSmokeTest.log` |
| Windows 1920×1080·1280×720 DAY 2 캡처 | PASS | `tmp/v122_day02_feedback_visual/` |
| Windows QA export·타이틀 부팅 | PASS | `builds/qa/MawangCastle_v1.2.6_QA_608a3da*` |
| 전체 회귀·DAY 1~30 완주 | NOT_REQUESTED | 이번 피드백 영향 범위만 검증 |

### 검수 에이전트 반복 기록

| 회차 | 범위 | 주요 지적 | 재검수 |
|---:|---|---|---|
| 1 | AI·방 지침 | 지침 일부가 역할 AI 뒤, 토스트 HUD 재구성으로 삭제 | 수정 후 PASS |
| 2 | 건설 UX | 슬롯 발견·추천·확정 흐름 불명확 | 수정 후 PASS |
| 3 | 방 이름표 | 전면 소품 z=30·벽 z=50이 z=0 이름표를 가림 | z=60 이동 후 PASS |

- Review task ID: `FDB-20260820-001-004-TARGETED-RETEST`
- Reviewed SHA: `608a3da47dcfdb0e1bb259a96130e214d9c55e4a`
- Review range: `e8aca24c435fc64d3ec6a6079623185ed0232010..608a3da47dcfdb0e1bb259a96130e214d9c55e4a`
- Remaining P1/P2: `N/A`
- Final review result: `TARGETED_PASS`

## 7. 미해결 항목과 위험

- 사용자·지인 수용 상태는 아직 `USER_ACCEPTED`가 아니다.
- Godot Windows root certificate store 경고는 반복됐지만 모든 대상 테스트와 부팅은 통과했다.
- 전체 DAY 1~30 회귀는 이번 수정 요청에서 실행하지 않았다.

## 8. 다음 작업 순서

1. 새 QA ZIP으로 동일 사용자 장면을 재확인한다.
2. 새 피드백이 있으면 기존 완료 판정을 소급 변경하지 않고 다음 피드백 주기로 접수한다.
3. 원격 병합·출시는 별도 승인 후 진행한다.

## 9. 작업 트리 상태

- 제품 수정은 `608a3da47dcfdb0e1bb259a96130e214d9c55e4a`에 커밋했다.
- 빌드·캡처는 gitignored `builds/`, `tmp/`에만 있다.
- `main` worktree의 기존 미커밋 CURRENT 재정리는 건드리지 않았다.

## 10. 종료 체크리스트

- [x] 구현과 요구사항 대조 완료
- [x] 관련 테스트 통과
- [x] 검수 대상 제품 SHA 기록
- [x] 의도한 제품 파일만 커밋
- [ ] `docs/handoff/CURRENT.md` 갱신 — 별도 `main` worktree의 기존 사용자 재정리와 충돌 방지를 위해 보류
- [ ] 원격 푸시·PR·태그 — 미수행

## 11. 정식 후보 후속 교정

- 정식 승격 독립 감사에서 `입구 봉쇄`가 HUD에는 모든 로컬 수비대에 적용된 것처럼 보이지만 실제 AI는 슬라임만 수행하는 P2를 추가 발견했다.
- `75a4115b8337569a83db5544076f9c2ca9d55941`에서 행동과 HUD가 같은 applicability 판정을 사용하도록 교정하고 슬라임·곱·임프·후반 동료와 원격 전선 제외를 재검증했다.
- `2c2d46ca339cb9d298d0ab3051b22fa649c41c73`에서 후기 수비대가 같은 목적점에 포개지지 않도록 고유 lane·rank 포메이션과 최소 48px 간격 단언을 추가했다.
- 모바일 회귀의 오래된 명령 4개 기대값을 사용자 확정 핵심 명령 3개 정책에 맞췄다.
- Stage 03 `slot_02`와 Stage 04 `slot_03`의 미리보기·무비용·취소 흐름을 정식 카탈로그에 추가했다.
- 이 문서의 기존 `608a3da` TARGETED_PASS는 당시 범위 기록으로 보존하며, 정식 후보 판정은 [V126_RELEASE_CANDIDATE_2026-08-20.md](V126_RELEASE_CANDIDATE_2026-08-20.md)를 따른다.
