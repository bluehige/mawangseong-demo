# v1.2.2 I1-5 보스·최종전 음악·VFX 대표 검수

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

I1 통합 대표 검수의 다섯 번째 패킷으로, DAY 30 최종전에서 정식 셀렌 보스의 BGM 전환과 실제 보스 상태 연출을 확인했다. 전체 DAY 1~30 플레이, Full 회귀, 다중 해상도 검수는 실행하지 않았다.

## 실행 방법

- 임시 검수 장면: `tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn`
- 명령: `godot --path . --scene res://tmp/v122_release_polish/i1_5_boss_final/I1BossFinalRepresentative.tscn --quit-after 600`
- 실제 Godot Vulkan 렌더링, `1280×720`, DAY 30, 정식 셀렌·탐험가·슬라임 배치
- 기계 결과: `tmp/v122_release_polish/i1_5_boss_final/i1_5_inventory.json`
- 실행 로그: `tmp/v122_release_polish/i1_5_boss_final/i1_5_capture.log`

## 대표 결과

- 11 assertions PASS, 실패 0건이다.
- 살아 있는 보스 감지 후 `combat_boss_council.wav`로 보스 BGM이 선택됐다.
- 정식 셀렌의 검수 예고가 시작되고 0.8초 이상 경고 시간이 유지됐다.
- HP 65% 이하에서 축성 바닥이 1개 생성되고 화면 효과가 보였다.
- HP 35% 이하 마지막 단계에서 자비의 방벽을 활성화하고 보스 주변 방벽 고리가 보였다.
- 캡처 4장: 준비, 검수 예고, 축성 바닥, 자비의 방벽.

## 관련 자동 테스트

- `OfficialSelenPhase20Test.tscn`: PASS, 26 assertions
- `EndingPhase28Test.tscn`: PASS, 45 assertions

두 테스트 모두 기존 보스 데이터·단계 전환·최종 엔딩 조건을 확인하는 범위로 실행했다. headless 종료 시 Godot harness의 RID/ObjectDB leak 경고가 출력됐지만 종료 코드는 0이며 검수 실패로 분류하지 않았다.

## 변경 범위와 판정

- 런타임 코드, 전투 데이터, 그래픽·오디오 자산, 프로젝트 설정, 빌드는 수정하지 않았다.
- 검수용 임시 스크립트·장면·캡처·JSON·로그만 `tmp/v122_release_polish/i1_5_boss_final/`에 만들었다.
- 실제 소유자 청취와 Windows 후보 조작은 별도 확인이 필요하다.

Related tests: I1BossFinalRepresentative 11 assertions PASS; OfficialSelenPhase20Test 26 assertions PASS; EndingPhase28Test 45 assertions PASS.
UI check: 실제 Vulkan `1280×720`에서 보스 정보 패널, 보스 BGM 전환 상태, 검수 예고, 축성 바닥, 자비의 방벽 고리와 전투 명령 UI를 캡처 4장으로 확인했다.
Unresolved issues: 실제 소유자 헤드폰·스피커 청취와 Windows 후보 조작(`I1-5-OWNER-01`), Q1-R 오디오 출처·manifest gate, I1-2 UI음 공백은 남아 있다.
