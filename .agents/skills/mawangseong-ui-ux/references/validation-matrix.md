# 마왕성 UI·UX 검증 매트릭스

## 기본 원칙

- 변경 범위와 직접 관련된 테스트만 실행한다.
- 전체 회귀·전체 플레이·별도 검수 에이전트는 현재 사용자 요청 또는 최신 출시 게이트가 요구할 때만 실행한다.
- UI 후보의 source SHA가 바뀌면 해당 캡처·상호작용·승인 증거를 갱신한다.

## 자동 검사 E0

대상에 따라 다음을 선택한다.

- `V20InformationArchitectureTest`
- `V20PlacementUxTest`
- `V20TacticalCommandsTest`
- `V20ResultScreenTest`
- `V20OnboardingRetrySaveTest`
- `V20FinalUIFlowSmokeTest`

검사 항목 예시:

- 주 행동 수와 신호 연결
- 필수 정보 존재와 실제 데이터 연결
- 핵심 rect 화면 내부·비겹침
- 금지 패널 부재
- drag/drop·Undo·invalid 상태 불변
- 명령 대상·성공·실패 상태
- 결과 행동과 retry 경로

## 실제 렌더 E2

PC 기본 매트릭스:

- 1280×720
- 1366×768
- 1920×1080

상태 캡처:

- 타이틀: 저장 없음 / 유효 저장
- 침입 브리핑
- 배치: 초기 / drag / valid / invalid / 적용 / 시작 차단
- 전투: 기본 / telegraph / 명령 선택 / 성공 / 실패
- 결과: 승리 / 패배 / 상세 접힘·펼침

확인:

- 글자 잘림과 대비
- 지도·전장 가림
- 시선 우선순위
- 작은 버튼·카드·슬롯
- 상태 간 시각 차이
- 디버그 표시가 제품 위계를 침범하는지

## 상호작용 E3

동일 build에서 다음을 수행한다.

1. 새 테스트 시작 또는 이어하기
2. 침입 목표 확인
3. 시설 설치
4. 몬스터 배치·이동
5. invalid drop
6. Undo
7. 방어 시작과 countdown 취소·재시작
8. 전투 위협 확인
9. 명령 선택·대상 지정·취소·사용
10. 승패 결과
11. 패배 배치 수정 또는 동일 배치 재도전

기록:

- 도달 불가능한 컨트롤
- 오입력·취소 횟수
- 차단 이유와 실패 피드백
- 실제 data/state 변화
- 콘솔 오류·경고

## 사용자 검증 E4

최신 handoff의 고정 source/build와 질문을 사용한다. 최소 관찰 항목:

- 설명 없이 첫 행동을 찾는가
- 시설과 몬스터의 배치 위치를 이해하는가
- 중요한 정보가 작거나 가려졌다고 느끼는가
- 전투 중 적 행동과 명령 대상을 이해하는가
- 패배 원인과 다음 수정 행동을 말할 수 있는가
- 의미를 알 수 없는 버튼이 남았는가
- 정식판 기준 UI로 승인하는가

E4 이전에는 `사용자 승인 PENDING`이다.

## 판정 템플릿

```text
Structural: PASS / REVISE / FAIL
Evidence: E0 / E1 / E2 / E3 / E4
Owner acceptance: PENDING / ACCEPTED / REJECTED
Source SHA:
Build hash:
Supported viewports tested:
Supported inputs tested:
Hygiene blockers:
Unknowns:
```
