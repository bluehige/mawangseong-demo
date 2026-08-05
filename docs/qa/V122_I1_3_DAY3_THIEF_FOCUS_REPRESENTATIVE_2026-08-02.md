# V1.2.2 I1-3 DAY 3 도둑·집중·혼잡 타격 대표 검수

- 검수일: 2026-08-02
- 대상 버전: 제품 `1.2.2`
- 브랜치: `codex/v122-ui-simplification`
- 기준 커밋: `efab13e7f9a2c1e2bd059eb8abf4cc409710380d`
- 범위: DAY 3, 고블린 도둑 사냥꾼 특성, 일반 탐험가와 도둑 동시 침입, 집중 명령, 실제 기본 공격
- 대표 해상도: `1280×720`
- 변경 원칙: 검수용 임시 캡처·문서만 추가. 런타임 코드·데이터·자산·빌드는 수정하지 않음

## 결과

상태는 `TARGETED_PASS_WITH_OWNER_PLAY_PENDING`이다.

- DAY 3 전투에 진입하고 고블린 `goblin_treasure_hunter` 특성을 적용했다.
- 일반 탐험가와 도둑을 동시에 배치한 뒤 집중 대상 선택 모드를 실제 runtime 경로로 열었다.
- 집중 대상은 도둑 instance로 기록되고, 전투 AI도 같은 도둑 instance를 반환했다.
- 더 가까운 탐험가가 있어도 기본 공격은 도둑에게만 적중했다. 이 재현에서 도둑 HP 변화는 `-21`, 탐험가 HP 변화는 `0`이었다.
- 대표 캡처 2장 모두 `1280×720`으로 생성했다.

캡처:

- [집중 대상 선택 상태](../../tmp/v122_release_polish/i1_3_day3_focus/i1_3_day3_focus_target_1280x720.png)
- [집중 공격 직후](../../tmp/v122_release_polish/i1_3_day3_focus/i1_3_day3_focus_hit_1280x720.png)

기계 결과: [`i1_3_inventory.json`](../../tmp/v122_release_polish/i1_3_day3_focus/i1_3_inventory.json)

## 회귀 범위

- `V122DefenderConnectorTest`는 집중 기본 공격·Quick Slash·사거리 밖 추격·가까운 일반 적의 추격 중단 금지를 포함해 PASS했다.
- `V122CommandButtonIntegrationTest`는 실제 버튼→전장 대상 선택→instance ID 보존→집중 기본 공격·스킬 피해 배율을 포함해 PASS했다.
- 이번 패킷에서 새 전투 규칙이나 특성을 수정하지 않았다.

## 판정 경계

자동·합성 대표 경로는 PASS지만, 사용자가 실제 DAY 3에서 일반 탐험가와 도둑을 동시에 두고 집중 명령을 눌러 느끼는 추격·공격·결산 문구는 아직 OWNER 플레이 확인이 필요하다.

Related tests: `I1Day3FocusRepresentative` 7 assertions PASS; `V122DefenderConnectorTest` PASS; `V122CommandButtonIntegrationTest` PASS.

UI check: DAY 3 전투의 집중 대상·공격 직후 화면을 실제 `1280×720`으로 2장 캡처했고, 둘 다 크기 PASS.

Unresolved issues: 실제 사용자 DAY 3 플레이·도둑 사냥꾼 체감·결산 확인 OWNER 대기. Q1-R 오디오 manifest·권리 gate와 I1-2 UI음 공백 유지.
