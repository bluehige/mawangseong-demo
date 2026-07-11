# DAY 19 완료 및 다음 세션 최종 인계

## 가장 먼저 읽을 문서

다음 세션은 수정 전에 아래 순서로 상태를 확인한다.

1. `docs/GAMEPLAY_CORE_AUDIT_2026-07-10.md`
2. 이 문서 `docs/HANDOFF_DAY19_FINAL_NEXT_SESSION_2026-07-12.md`
3. `docs/HANDOFF_DAY18_BLOCKADE_RESPONSE_2026-07-12.md`
4. `git status`, `git diff --check`, 실제 DAY 19 데이터와 코드

작업 트리에는 여러 세션의 누적 미커밋 변경이 있다. 관계없는 변경을 되돌리거나 덮어쓰지 않는다. 커밋과 푸시는 사용자가 명시적으로 요청할 때만 한다.

## 현재 게임 진행 상태

- DAY 1~3 첫 플레이 흐름과 실제 게임 기능 검수 회차는 종료됐다.
- DAY 4~15 캠페인, 첫 승급, Stage 02 심사 흐름이 구현돼 있다.
- DAY 16 보급로 선택, DAY 17 니아 보안 평가, DAY 18 봉쇄 대응 선택이 구현돼 있다.
- DAY 19 봉쇄 명령서 회수대까지 실제 콘텐츠와 검수가 완료됐다.
- 두 번째 승급은 DAY 23까지 잠겨 있다.
- Stage 02 방·경로 외형 전환은 승인된 실제 게임 자산이 없어 보류 상태다.

## DAY 19 플레이 구조

DAY 19에는 새 필수 원정 선택이 없다. DAY 18 선택이 자동으로 선발대를 바꾼다.

### 가짜 보급 장부 후속전

- 탐험가 2명: 0초, 5초
- 조사관 2명: 14초, 18초
- 회수 도둑 1명: 36초
- 수련생 회수대장 1명: 48초
- 총 6명

### 밀수 갱도 봉쇄 후속전

- 탐험가 2명: 0초, 5초
- 방패병 2명: 20초, 24초
- 회수 도둑 1명: 36초
- 수련생 회수대장 1명: 48초
- 총 6명

30초에는 회수 도둑, 42초에는 회수대장 도착 경고가 한 번씩 표시된다. 회수 도둑은 기존 도둑 AI와 공통 보안 평가 S/A/C/D를 사용한다.

## 이번에 추가한 공통 데이터 연결

`data/campaign_days.json`에서 다음 키를 사용할 수 있다.

- `completed_raid_enemy_notice_lines`: 이전 작전별 관리 화면 출현 예고
- `completed_raid_combat_start_lines`: 이전 작전별 전투 시작 대사
- `completed_raid_result_lines`: 이전 작전별 결산 문구
- `completed_raid_defense_modifiers`: 이전 작전을 실제 웨이브 변화로 자동 적용
- `combat_timed_lines`: 지정한 전투 시간에 한 번만 표시하는 경고

캠페인 자동 웨이브 변화는 `GameRoot._active_defense_modifiers()`에서 기존 원정 수정값과 합쳐진다. `next_defense_modifiers`에 저장된 일회성 원정 효과는 전투 뒤 소모되지만, 현재 날짜 데이터에서 읽은 이전 작전 후속 효과는 완료 작전 기록을 기준으로 다시 계산된다.

전투 효과 로그의 `source_label`을 지정하면 기본 `원정 효과 적용` 대신 `전날 선택 반영`처럼 출처를 표시할 수 있다.

## 실제 검수 결과

- Godot 프로젝트 가져오기 및 스크립트 등록: PASS
- JSON 파싱: PASS
- `DemoSmokeTest`: PASS, DAY 1~19 포함
- `DAY19_MANIFEST_GOBLIN`: 63.9초 승리, 왕좌 피해 0, 도난 없음, 전투 불능 1명
- `DAY19_TUNNEL_SLIME`: 79.3초 승리, 왕좌 피해 0, 도난 없음, 전원 생존
- `UIRegressionVisualReview`: PASS
- `git diff --check`: 공백 오류 없음, 기존 줄바꿈 변환 경고만 있음

자동 전투는 실제 사람 플레이 표본이 아니다. 다만 두 분기 모두 시간 초과, 왕좌 피해, 도난 없이 끝났고 역할 차이가 유지되는지 확인하는 용도로 사용했다.

Godot 종료 시 기존 `ObjectDB instances leaked` 또는 `resources still in use` 경고가 드물게 출력될 수 있다. 현재 검사는 종료 코드 0이고 기능 실패는 없었지만, 장기적으로 테스트 씬 정리 시 확인할 잔여 위험이다.

## 시각 자료

- `tmp/ui_regression_review/05k_day19_management_tunnel.png`
- `tmp/ui_regression_review/05l_day19_recovery_combat.png`
- `tmp/ui_regression_review/05m_day19_recovery_result.png`

확인한 내용:

- DAY 18 선택 결과가 DAY 19 요약과 출현 예고에 표시됨
- DAY 19 하단에는 평범한 `전투 시작`이 있어 선택 반복이 없음
- 회수 도둑 경고와 실제 위협 표시가 전투 로그·맵에서 읽힘
- 보안 평가, 선택 후속 결과, DAY 19 공통 결과가 결산에 모두 표시됨
- 1920x1080에서 관리·전투·결산 글자 겹침과 잘림 없음

## 핵심 수정 파일

- `data/campaign_days.json`: DAY 19 스토리, 분기, 시간 경고
- `data/waves.json`: DAY 19 기본 6명 웨이브
- `scripts/game/GameRoot.gd`: 이전 작전별 공지·대사·결산·웨이브 계승, 시간 경고
- `scripts/game/CombatSceneController.gd`: 시간 경고 갱신과 효과 출처 로그
- `tools/DemoSmokeTest.gd`: DAY 19 전체 흐름 검사
- `tools/BalanceSimulation.gd`: DAY 19 두 분기 실제 자동 전투
- `tools/UIRegressionVisualReview.gd`: DAY 19 관리·전투·결산 캡처
- `docs/GAMEPLAY_CORE_AUDIT_2026-07-10.md`: 27차 개발 기록

## 다음 세션의 첫 작업

DAY 20 실제 콘텐츠를 개발한다. DAY 16~19에서 보급로 선택, 도둑 추격, 방패병·조사관 분기를 충분히 사용했으므로 같은 구성을 다시 반복하지 않는다.

권장 방향은 **왕국 공병의 첫 등장**이다.

- 공병은 왕좌나 보물 대신 가장 가까운 작동 중 시설을 목표로 한다.
- 시설에 도착하면 감시초소·병영·회복 둥지 효과를 짧은 시간 무력화한다.
- 무력화 중인 시설은 맵과 시설 효과 패널에서 즉시 알아볼 수 있어야 한다.
- 플레이어는 고블린 추격, 슬라임 길막기, 임프 집중 공격 중 누구를 공병 대응에 돌릴지 판단한다.
- 결산에는 공병 도달 수, 무력화 횟수, 막아 낸 시설 수를 짧게 표시한다.
- 단순 체력·공격력 상승으로 위협을 만들지 않는다.

이 방향은 아직 구현되지 않은 권장안이다. 다음 세션은 먼저 현재 적 목표 선택과 시설 효과 적용 구조를 확인하고, 기능을 실제로 완성할 수 있는 범위로 DAY 20을 설계한다.

## 하지 말아야 할 일

- DAY 1~3 전체 검수 회차 재개
- DAY 18~19 수치만 반복 조정
- DAY 23 전 두 번째 승급 해금
- 승인 자산 없는 Stage 02 외형 임시 전환
- DAY 20 전에 DAY 16 이후 스토리를 다시 대량 수정
- 누적 미커밋 변경 되돌리기

이번 세션은 커밋하거나 푸시하지 않았다.
