# v1.2.2 C1 접촉 피드백 동기화 결과

작성일: 2026-08-02
대상 버전: 제품 `1.2.2`
범위: 일반 공격, 투사체, 돌진, 광역 피해의 접촉 사건

## 결론

`PASS` — 피해가 적용되는 접촉 사건에서 피격 동작, 피해 숫자, 타격음, VFX를 같은 런타임 사건으로 발생시키도록 통합했다. 공격 시작 시 미리 재생되던 일반 베기음·임프 화염구 충돌음을 제거하고, 실제 일반 접촉·투사체 도착·돌진 충돌·광역 피해 시점으로 옮겼다.

## 구현

- `CombatSceneController._show_combat_hit_feedback`를 접촉 사건의 단일 입구로 확장했다.
- 사건 기록에 접촉 종류, 대상 HP, simulation 시간·프레임, 다섯 피드백 채널을 남긴다.
- 동일 토큰의 중복 콜백은 무시해 투사체·광역 틱의 중복 피드백을 막는다.
- 일반 공격과 근접 스킬은 접촉 시 `slash`, 투사체·돌진·광역은 접촉 시 `impact`를 만든다.
- 투사체는 도착 콜백이 접촉 VFX를 만들며, 공통 투사체 표시 함수는 선택적으로 도착 VFX를 생략한다.
- 산성 장판 틱, 가시 복도 함정, 베베 빗자루, 돌콩 파동, 달빛 표식, 달향 추적, 등껍질 돌진도 같은 입구를 사용한다.
- 기존 `AudioDirector` 경로를 유지해 직접 `AudioStreamPlayer`를 만들지 않는다.

## 검증

실행:

- `godot --headless --path . --scene res://tools/tests/ContactFeedbackSyncTest.tscn --quit-after 1800`
- `python -m json.tool tools/tests/core_verification_suite.json`
- `godot --headless --path . --scene res://tools/tests/V122ContentCompatibilityTest.tscn --quit-after 1800`
- `godot --headless --path . --scene res://tools/tests/CombatAudioDirectorRoutingTest.tscn --quit-after 1800`

결과:

- `ContactFeedbackSyncTest`: 23/23 assertions PASS
- 일반·투사체·돌진·광역 접촉 종류별 단일 사건 PASS
- x1·x2·x3 고정 피해량 및 simulation 프레임 동일성 PASS
- 다섯 채널 순서 `damage → hit_reaction → damage_number → audio → vfx` PASS
- V122 suite coverage 85/85, 500 assertions PASS
- 기존 전투·HUD AudioDirector 라우팅 9/9 PASS

## 제한 및 다음 단계

- Godot 종료 시 기존 테스트와 동일한 ObjectDB/resource leak 경고가 남지만 프로세스 종료 코드는 0이다.
- 실제 Windows 1280×720 3프레임 캡처와 x1·x2·x3 장시간 플레이는 I1/최종 OWNER 검수에서 확인한다.
- 다음 계획 패킷은 V5 VFX catalog·런타임 연결이다.
