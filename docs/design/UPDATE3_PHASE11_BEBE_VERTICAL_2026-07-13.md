# 3차 업데이트 Phase 11 완료 기록

- 완료일: 2026-07-13
- 범위: 유령 하녀 베베의 데이터, 스킬 3종, AI, 직접 조종, 유대·그래픽 placeholder, 저장

## 구현 결과

- `ghost_housemaid` / `CHR_BEBE` / `monster_bebe` 데이터와 기준 능력치를 등록했다.
- `spectral_transfer`는 HP 비율이 낮은 아군을 사거리 220 내에서 선택하고, 그래프 경로를 따라 최대 110px 안전 이동시키며 보호막 20을 부여한다.
- 안전 셀을 찾지 못하면 이동을 취소하고 보호막만 적용한다.
- 왕좌방이 공격받는 중이면 왕좌방 부상자를 우선한다.
- `haunted_broom_whirl`은 전방 85px 부채꼴에 `ATK×0.9+8` 피해를 주고, 일반 적을 최대 24px 밀치며 시전을 0.35초 중단한다. 보스는 피해만 받는다.
- `house_spirit`은 베베가 시설 내부·인접 방에 있을 때 시설 무력화 실제 시간을 12% 줄인다.
- 직접 조종 중에도 자동 구조를 켜거나 끈 수 있는 토글을 제공하고, 설정을 로스터에 저장한다.
- 기능용 전투 스프라이트와 `memory_bebe_01`은 placeholder로 명시했다.
- 기본 DPS를 임프보다 15% 이상 낮게 유지해 화력 조합의 대가를 보존했다.

## 검증

- `BebePhase11Test`: 33/33 PASS
- `Update3DataContractTest`: 17/17 PASS
- `SaveV4MigrationTest`: 42/42 PASS
- `RunCoreVerification.ps1 -Mode Quick`: 24/24 PASS

따라서 안전 셀·벽 통과 금지·경로 정지 0건·생존 시간 증가·화력 대가 조건을 모두 충족한다.
