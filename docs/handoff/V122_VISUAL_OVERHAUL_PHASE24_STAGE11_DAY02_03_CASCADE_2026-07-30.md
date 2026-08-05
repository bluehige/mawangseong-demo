# v1.2.2 시각 개편 24단계 Stage 11 DAY 2~3 파급 수정 핸드오프

## 1. 메타데이터

- 작성일: 2026-07-30
- 목표 버전: 제품 1.2.2
- 작업 브랜치: `codex/v122-ui-simplification`
- 기준 SHA: `49388876d50009ed87655fffb2bf6974098b2f6c`
- 원격 푸시 여부: 아니요
- 작업 단위: 시각 개편 11단계 1차

## 2. 조사 범위와 시각 기준

- 성 지도와 전장은 계속 주 작업면으로 남기고 DAY 전용 안내는 보조 레이어에서만 작동하게 했다.
- 관리 화면은 지도 클릭과 우측 컨텍스트 드로어가 한 번에 하나의 다음 행동만 말하는지 확인했다.
- 전투 화면은 왕좌·위협 상단 rail, 지침·명령·속도 하단 rail, 관찰 안내가 서로 겹치지 않는지 확인했다.
- 결산은 승패·핵심 원인·세 지표·내 선택의 결과·성장·다음 행동 순서와 클릭 영역을 확인했다.
- 확인 해상도는 `1920×1080 Standard`, `1366×768 Compact`, `1280×720 Compact`다.

최종 캡처는 해상도마다 다음 9개 상태, 총 27장이다.

1. DAY 2 `TUT_110_TRAP_CORRIDOR` 관리
2. DAY 2 `TUT_120_TRAP_LURE` 관리
3. DAY 2 `TUT_130_GOBLIN_CONTROL` 전투
4. DAY 2 승리 결산
5. DAY 3 `TUT_210_RECOVERY_NEST` 관리
6. DAY 3 `TUT_220_RETREAT_LINE` 관리
7. DAY 3 `TUT_230_IMP_FIREBALL` 전투
8. DAY 3 `TUT_240_BOSS_HP` 전투
9. DAY 3 패배 결산

## 3. 공통 UI 파급과 DAY 전용 분류

| 분류 | 재현 상태 | 원인 | 처리 |
|---|---|---|---|
| 공통 관리 안내 배치 | DAY 2 함정 유도, DAY 3 후퇴선 유지, 세 해상도 | 클릭 대상이 드로어 안에 있을 때 일반 후보가 모두 탈락하고 드로어 내부 fallback을 사용 | 드로어 왼쪽·안내 카드 위/아래의 안전 후보를 먼저 평가해 배지를 드로어 밖에 배치 |
| 공통 관리 우선순위 | DAY 2 가시 복도, DAY 3 회복 둥지, 세 해상도 | 지도 클릭 안내와 다음 전투의 전술 특화 `필수 준비` 드로어가 동시에 자동 노출 | 두 지도 클릭 단계에서는 자동 드로어를 닫고, 후속 방 지침 단계에서는 다시 열도록 분리 |
| 공통 전투 target 연결 | DAY 3 보스 HP 50% 관찰, 세 해상도 | 전투 HUD가 `BossHpBar`를 `CombatThroneStatus`로 개편했지만 legacy 튜토리얼 target alias를 등록하지 않음 | 새 왕좌 상태 rail을 `BossHpBar` target에도 등록해 실제 전투 관찰 카드를 복구 |
| DAY 2 전용 | 관리·고블린/도둑 전투·승리 결산 | 추가로 재현되는 깨진 배치·상태 언어·클릭 대상 없음 | DAY 2 규칙·밸런스·단계 ID 유지 |
| DAY 3 전용 | 관리·임프 자동 기술·보스 HP·패배 결산 | 추가로 재현되는 깨진 배치·상태 언어·클릭 대상 없음 | DAY 3 규칙·밸런스·단계 ID 유지 |

## 4. 구현 내용

### 관리 지도 클릭 단계

- `ROOM_SPIKE_CORRIDOR`, `ROOM_RECOVERY_NEST`가 현재 튜토리얼 focus이면 generic pending reason보다 지도를 우선한다.
- 지도 클릭 뒤 `ROOM_DIRECTIVE_TRAP_LURE`, `ROOM_DIRECTIVE_RETREAT_LINE`으로 넘어가면 기존 우측 드로어가 다시 열리고 실컨트롤을 강조한다.
- 전술 특화 요구 자체와 전투 시작 게이트는 제거하거나 늦추지 않았다.

### 드로어 대상 클릭 배지

- 드로어 왼쪽 여백에 배지를 놓되 현재 안내 카드 위쪽 후보를 우선한다.
- 후보는 기존과 동일하게 안내 카드, 실클릭 target, 드로어와 겹치지 않을 때만 채택한다.
- 일반 지도·결산·DAY 1 클릭 배지의 기존 후보 순서는 유지했다.

### 보스 HP 관찰 target

- `CombatThroneStatus` rail은 새 이름과 `CombatThroneStatus` 등록을 유지한다.
- 저장 호환 튜토리얼 focus인 `BossHpBar`를 같은 실컨트롤의 alias로 추가 등록했다.
- `TUT_240_BOSS_HP`의 ID·순서·완료 조건 `boss_hp_50`은 변경하지 않았다.

## 5. 변경 파일

| 파일 | 역할 |
|---|---|
| `scripts/game/ManagementSceneController.gd` | 지도 클릭 단계의 단일 행동 우선순위 |
| `scripts/game/GameRoot.gd` | 드로어 밖 클릭 배지 안전 후보 |
| `scripts/ui/HUDController.gd` | 전투 왕좌 rail의 `BossHpBar` target alias |
| `tools/V122Stage11CascadeAudit.gd` | DAY 2~3 실제 관리·전투·결산 3해상도 감사 |
| `tools/V122Stage11CascadeAudit.tscn` | 전용 감사 실행 scene |
| `docs/plans/V122_VISUAL_OVERHAUL_SEQUENTIAL_PLAN_2026-07-29.md` | 11단계 1차 완료·2차 진입 기록 |
| `docs/handoff/CURRENT.md` | 현재 상태와 다음 작업 진입점 |

## 6. 테스트 및 검수

| 검수 | 결과 | 범위 |
|---|---|---|
| Godot editor 로드·스크립트 파싱 | PASS | 최종 변경 뒤 exit code 0 |
| `V122Stage11CascadeAudit.tscn` | PASS, 405 assertions / 27 PNG | DAY 2~3 관리·전투·결산, 1920/1366/1280 |
| 대표 1920/1280 캡처 육안 확인 | PASS | 지도 우선, 배지·드로어 분리, 전투 rail, 관찰 카드, 승리·패배 결산 |
| `V122TutorialGuidanceLevelTest.tscn` | PASS, 20 assertions | Full/Core/Off 안내 수준 |
| `V122Stage10LocalizationTest.tscn` | PASS, 42 assertions | 한국어/영어 DAY 1~3 안내 |
| `V122ManagementInteractionTest.tscn` | PASS | 관리 드로어·배치·시설 상호작용 |
| `V122CombatUISimplificationTest.tscn` | PASS, 85 assertions | 3해상도 전투 HUD·명령 rail |
| `V122ResultUISimplificationTest.tscn` | PASS, 37 assertions | 승패 결산·인과·행동 |
| `TutorialFlowSmokeTest.tscn` | PASS | DAY 1~3 실제 진행·패배 재전투·기존 단계 ID |
| `git diff --check` | PASS | 기존 줄바꿈 경고 외 공백 오류 없음 |

- 최종 PNG는 `tmp/v122_stage11_cascade_audit/`에 있으며 커밋 대상이 아니다.
- Godot 종료 시 기존 ObjectDB/resource 잔류 메시지와 editor scan thread 경고가 일부 남지만 대상 테스트 exit code는 모두 0이다.
- 전체 회귀·전체 플레이·Windows/Web 빌드는 수행하지 않았다.

### 정책 CI용 최종 승인 필드

- Review task ID: NOT_REQUESTED
- Reviewed SHA: UNCOMMITTED_WORKTREE
- Review range: N/A
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. 미해결 항목과 위험

- 이번 1차는 DAY 2~3 대표 상태만 다뤘다. DAY 4 이후 raid preview, 새 해금, 일반 캠페인 안내의 파급은 아직 조사하지 않았다.
- Stage 10 카탈로그 밖의 일반 캠페인 전체 영어화는 여전히 범위 밖이다.
- 기존 저장 ID, 전투 밸런스, 성장 규칙, 전술 특화 요구는 변경하지 않았다.
- Phase 3~24 누적 미커밋 변경과 대량 `.import` 변경을 그대로 보존했다.

## 8. 다음 작업 순서

1. 시각 개편 11단계 2차로 DAY 4~5의 침입 정보/원정 미리보기·관리·전투·결산을 실제 진행 순서대로 조사한다.
2. 같은 1920/1366/1280 기준으로 공통 UI 파급과 DAY 전용 문제를 먼저 분류한다.
3. 재현되는 문제만 공통 원인부터 최소 수정하고 콘텐츠 규칙·밸런스·저장 호환은 유지한다.
4. 전체 QA·전체 플레이·빌드·커밋·푸시는 사용자가 별도로 요청하기 전까지 수행하지 않는다.

## 9. 작업 트리 상태

- `codex/v122-ui-simplification`의 Phase 3~24 누적 미커밋 변경을 보존했다.
- 기존 사용자 변경과 대량 `.import` 갱신을 되돌리거나 분리하지 않았다.
- 빌드·커밋·푸시는 진행하지 않았다.

## 10. 종료 체크리스트

- [x] DAY 2~3 관리·전투·결산 실제 화면 목록화
- [x] 1920 Standard·1366/1280 Compact 27장 캡처
- [x] 공통 UI 파급과 DAY 전용 문제 분리
- [x] 지도 클릭 단계의 경쟁 드로어 제거
- [x] 지침 클릭 배지와 드로어 비겹침
- [x] DAY 3 보스 HP 관찰 카드 복구
- [x] 기존 튜토리얼 ID·규칙·밸런스·저장 호환 유지
- [x] 직접 관련 테스트 통과
- [x] 요청받지 않은 전체 회귀·전체 플레이·빌드 미실행 기록
- [x] `docs/handoff/CURRENT.md` 갱신
- [ ] 의도한 파일만 커밋
- [ ] 원격 푸시 및 PR/태그 상태 기록
