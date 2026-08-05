# v1.2.2 I1-4 후반 일반 전투 대표 검수

검수일: 2026-08-02
대상 브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`

## 범위

I1 통합 대표 검수의 4번 패킷만 확인했다. DAY 20을 후반 일반 전투 대표로 삼아 보스가 없는 일반 전투의 기본 공격, 원거리 스킬 투사체, 피격 피드백, 전투 결과 화면과 BGM 전환을 확인했다. 전체 DAY 1~30 플레이와 Full 검증은 수행하지 않았다.

## 자동·실기 검수 결과

- `I1LateCombatRepresentative`를 실제 Godot Vulkan 렌더링 환경에서 실행했다.
- `1280×720`에서 DAY 20 전투에 슬라임·고블린·임프와 탐험가·조사관·공병을 배치했다. 보스 유닛은 없었다.
- 일반전 BGM `combat_dungeon_pressure.wav`가 유지되는지 확인했다.
- 고블린 기본 공격은 탐험가에게 즉시 `90` 피해를 적용했고, 임프 화염구는 투사체 도착 뒤 탐험가에게 `73` 피해를 적용했다.
- 전투 종료를 실제 `finish_combat(true, ...)` 경로로 처리해 결과 화면과 승리 상태를 확인했고, 결과 화면에서 관리 BGM `management_castle_bustle.wav`로 전환됐다.
- 대표 캡처 5장은 `tmp/v122_release_polish/i1_4_late_combat/`에 보관했다. 기계 결과는 `i1_4_inventory.json`, 실행 로그는 `i1_4_capture.log`다.

## 관련 계약 테스트

- `V122CombatResultUIContractTest`: PASS
- `V122ResultUISimplificationTest`: PASS, 37 assertions
- `V122CombatUISimplificationTest`: PASS, 85 assertions
- `V122CombatVisualHierarchyTest`: PASS

재도전 결과 화면 테스트는 버튼 입력 직후 한 물리 프레임이 먼저 진행되는 환경에서 내부 카운트다운이 `3.0` 대신 `2.95`가 될 수 있어, 화면에 `3초`로 보이는 범위(`2.9~3.0`, `ceil=3`)를 계약으로 명확히 했다. 제품 런타임은 수정하지 않고 `tools/tests/V122ResultUISimplificationTest.gd`의 검수 조건만 보정했다.

## 판정

기계 대표 검수는 PASS다. 이번 패킷은 기본 공격·스킬 투사체·피격 피드백·결과 화면 구조만 판정했으며 실제 소유자의 헤드폰·일반 스피커 청취와 실제 Windows 후보 조작은 별도 대기 항목이다.

Related tests: I1LateCombatRepresentative 13 assertions PASS; V122CombatResultUIContractTest PASS; V122ResultUISimplificationTest 37 assertions PASS; V122CombatUISimplificationTest 85 assertions PASS; V122CombatVisualHierarchyTest PASS.
UI check: 실제 Vulkan 창 `1280×720`에서 전투 준비·기본 타격·화염구 시전·화염구 도착·결과 화면 5장을 확인했으며 UI가 화면 밖으로 잘리거나 빈 화면인 캡처는 없었다.
Unresolved issues: 실제 소유자 청취·Windows 후보 조작, Q1-R 오디오 권리·manifest gate, I1-2 전용 UI 효과음 공백은 남아 있다.

## 변경 범위

- 런타임·데이터·그래픽·오디오 자산·빌드는 수정하지 않았다.
- 검수 테스트의 프레임 경계 계약만 보정했다.
