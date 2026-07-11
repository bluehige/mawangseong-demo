# DAY 17 니아의 두 번째 침투 인계

## 완료 범위

- DAY 4~16 공통 시스템 전이 대표 검수
- 전 날짜 공통 도둑 침투·약탈·탈출 기록
- 결산 보안 평가 S/A/C/D
- DAY 17 관리 대사, 5명 방어 웨이브, 니아 결과 반응
- DAY 16 정찰·급습 선택별 DAY 17 니아 관리 대사
- 관리 화면 하단 목표 가독성 개선
- 실제 화면에서 내부 결과 꼬리표 숨김
- DAY 17 관리·전투·결산 화면 캡처

## DAY 17 플레이

적은 탐험가 2명, 조사관 1명, 도둑 2명이다. 도둑은 10초와 34초에 따로 들어오며 새 적 종류나 단순 체력 상승은 없다. 슬라임이 입구 전열을 붙잡고 고블린이 두 침투를 추격하는 역할 분담을 노린다.

보안 평가는 다음처럼 실제 전투 기록으로 결정된다.

| 등급 | 조건 |
|---|---|
| S | 도둑이 보물 방에 들어오기 전에 모두 격퇴 |
| A | 보물 방에는 들어왔지만 약탈 전에 격퇴 |
| C | 약탈은 끝냈지만 탈출 전에 격퇴 |
| D | 약탈한 도둑이 입구로 탈출 |

## 확인 결과

- `DemoSmokeTest`: PASS. DAY 1~17 흐름, DAY 6 C 등급, DAY 17 S 등급 포함.
- `DAY10_CHAPTER_CLOSE`: 52.5초 승리.
- `DAY13_SHIELDBEARER_GOBLIN`: 66.4초 승리.
- `DAY15_SELEN_BOSS_GOBLIN`: 67.1초 승리.
- `DAY17_NIA_SECURITY_GOBLIN`: 60.2초 승리, 왕좌 피해 0, 전원 생존, 도난 없음.
- `UIRegressionVisualReview`: PASS.
- `git diff --check`: 공백 오류 없음. 기존 줄바꿈 변환 경고만 있음.

시각 자료는 다음 파일이다.

- `tmp/ui_regression_review/05d_day17_management.png`
- `tmp/ui_regression_review/05e_day17_combat.png`
- `tmp/ui_regression_review/05f_day17_security_result.png`

## 다음 작업

DAY 18 실제 콘텐츠를 개발한다. DAY 16 원정 선택 또는 DAY 17 보안 등급을 짧게 이어 받아 3장 보급로 사건을 전진시키되, 새 검증 도구나 전체 밸런스 반복을 우선하지 않는다. 두 번째 승급은 DAY 23까지 잠그고 Stage 02 외형 전환은 승인 자산 전까지 보류한다.
