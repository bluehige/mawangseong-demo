# 3차 업데이트 Phase 9 완료 기록 — 합동기 L01

작성일: 2026-07-13

## 완료 범위

- L01 `link_spore_jelly_shelter`(포자 젤리 피난처) 데이터 등록
- 푸딩 + 모리 조합 및 프로필 해금 fixture
- 새 회차 합동기 편성 화면과 2개 장착 슬롯
- 같은 몬스터의 두 합동기 중복 장착 거부
- 출전하지 않은 멤버가 있을 때 경고만 표시하고 편성은 허용
- 전투 시작 시 활성/비활성 판정 및 비활성 링크 수 안내
- 링크별 0~100 게이지, 동일 사건 중복 방지, 행동 1회 최대 +10
- 푸딩 피해 흡수 20마다 +3
- 모리 실제 회복 15마다 +3
- 100 충전 후 J 키/버튼 수동 발동
- 자동 사용 토글 기본 OFF, 사용자가 켠 설정은 전투와 v4 저장에 유지
- 전투당 1회, 멤버 전투 불능 시 게이지 동결
- 반경 190 아군 보호막 40, 5초간 초당 회복 3, 상태 이상 1개 정화
- 첫 회복 틱은 회복 피로 무시, 이후 틱은 기존 피로 규칙 적용
- 푸딩과 모리 0.6초 행동 잠금, 공격 피해 없음
- 전투 결산에서 사용 횟수와 최초 사용 회차 기록
- v4 저장에 장착·게이지·자동 사용·사용 완료 상태 보존
- 최소 전투 HUD에서 이름·게이지·활성/비활성·준비·사용 완료 표시

## 주요 구현 파일

- `data/regular_version/update3/duo_links.json`
- `scripts/systems/duo_links/DuoLinkGaugePolicy.gd`
- `scripts/systems/duo_links/DuoLinkService.gd`
- `scenes/ui/screens/DuoLinkLoadoutScreen.gd`
- `scenes/ui/hud/DuoLinkCombatHUD.gd`
- `scripts/game/GameRoot.gd`
- `scripts/game/CombatSceneController.gd`
- `scripts/units/Unit.gd`
- `scripts/systems/save/SaveV3ToV4Migrator.gd`

## 검증 결과

- Phase 9 전용: 49/49 PASS
- Update3 데이터 계약: 17/17 PASS
- 저장 v4: 42/42 PASS
- Phase 8 심장 선택 회귀: 63/63 PASS
- Update2 계약 로스터 회귀: 68/68 PASS
- Update2 릴리스 계약: 387/387 PASS
- 빠른 핵심 검증 22개 중 최초 실행 21 PASS, 1 FAIL
  - 실패 원인: 기존 Phase 2 테스트가 `계약 → 교리`의 이전 화면 순서를 기대함
  - 테스트 계약을 `계약 → 합동기 편성 → 교리`로 갱신한 뒤 해당 테스트 71/71 PASS

## 다음 단계로 넘기지 않은 항목

- L02~L04 신규 몬스터 조합
- L05·L06 기존 종 조합
- 합동기 최종 VFX

위 항목은 계획 순서에 따라 Phase 10 이후에서 처리한다.
