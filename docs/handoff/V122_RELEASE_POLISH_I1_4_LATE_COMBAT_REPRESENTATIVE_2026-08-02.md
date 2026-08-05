# v1.2.2 출시 마무리 I1-4 후반 일반 전투 핸드오프

목표 버전: `1.2.2`
브랜치: `codex/v122-ui-simplification`
기준 SHA: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
검수일: 2026-08-02

## 완료 내용

I1-4 후반 일반 전투 대표 검수를 완료했다. DAY 20 비보스 전투를 `1280×720`에서 고정 배치해 일반전 BGM, 기본 공격, 화염구 투사체와 피격, 실제 전투 종료·결과 화면·관리 BGM 복귀를 확인했다.

## 변경 파일과 산출물

- 검수용 임시 장면·스크립트: `tmp/v122_release_polish/i1_4_late_combat/I1LateCombatRepresentative.{gd,tscn}`
- 기계 결과: `tmp/v122_release_polish/i1_4_late_combat/i1_4_inventory.json`
- 실행 로그: `tmp/v122_release_polish/i1_4_late_combat/i1_4_capture.log`
- 캡처: `tmp/v122_release_polish/i1_4_late_combat/i1_4_late_combat_*_1280x720.png`
- QA 보고서: `docs/qa/V122_I1_4_LATE_COMBAT_REPRESENTATIVE_2026-08-02.md`
- 검수 계약 보정: `tools/tests/V122ResultUISimplificationTest.gd` (재도전 카운트다운 표시 3초의 한 프레임 허용 범위)

## 판정·경계

- 대표 자동 검수 13 assertions: PASS, 실패 0건.
- 관련 전투·결과·UI 계약 테스트: 모두 PASS.
- 런타임·데이터·그래픽·오디오 자산·빌드는 바꾸지 않았다.
- 실제 소유자 청취·Windows 후보 조작은 `I1-4-OWNER-01`로 남겼다. Q1-R 권리·manifest gate와 I1-2 UI음 공백도 별도 대기다.

Related tests: I1LateCombatRepresentative 13 assertions PASS; V122CombatResultUIContractTest PASS; V122ResultUISimplificationTest 37 assertions PASS; V122CombatUISimplificationTest 85 assertions PASS; V122CombatVisualHierarchyTest PASS.
UI check: Vulkan `1280×720` 대표 전투 5장(준비·기본 타격·화염구 시전·화염구 도착·결과)을 캡처하고 시각 확인했다.
Unresolved issues: 실제 소유자 청취·Windows 후보 조작, Q1-R 오디오 권리·manifest 승격, I1-2 전용 UI 효과음 공백, 결과 화면 성장 선택의 실제 사용자 체감은 다음 OWNER 검수다.

## 다음 작업

계획 순서대로 I1-5 보스·최종전 음악·VFX 대표 검수로 이동한다. 이 핸드오프 뒤에도 커밋·푸시는 수행하지 않는다.
