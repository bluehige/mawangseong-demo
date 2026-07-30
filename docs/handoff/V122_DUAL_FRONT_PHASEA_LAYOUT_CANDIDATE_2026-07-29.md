# v1.2.2 이중 전선 Phase A 레이아웃 후보 핸드오프

## 결과

Stage 01 이중 전선 구조의 첫 구현 단계를 완료했다. 기존 제품 기본 레이아웃은 아직 교체하지 않았고, 실제 `ModuleGraph`로 검증할 수 있는 별도 후보 레이아웃을 추가했다.

이 단계에서 고정한 내용은 다음과 같다.

- 정문 A와 서비스 침입 균열 B는 서로 다른 외부 진입점과 통로를 사용한다.
- A와 B는 왕좌 직전 5×5 전실 전에는 만나지 않는다.
- A는 3셀 폭의 짧은 회랑이며 기존과 같은 실제 가시 칸 6개를 가진다.
- B는 5셀 폭의 더 긴 회랑이다.
- 병영·회복실·빈 건설 슬롯·금고는 주 통로가 아닌 5×5 측면 시설 패드에 있다.
- 네 시설은 기존 instance ID를 유지하고 교체 가능 상태로 남는다.
- 몬스터용 방어구역 5개와 시설 슬롯 4개의 topology metadata를 시설 room과 분리해 선언했다.
- 후방 전선 연결로는 건설 위치와 비용만 기록했고 공용 `ModuleGraph` edge에는 넣지 않았다.

## 파일

- 구조 계약: `docs/design/v122/V122_STAGE01_DUAL_FRONT_COMBAT_STRUCTURE_CONTRACT_2026-07-29.md`
- 신규 블루프린트 묶음: `data/dungeon_quarter/dual_front_blueprints.json`
- 후보에서 제품 기본값으로 승격된 레이아웃: `data/dungeon_quarter/layouts/stage01_dual_front_01.json`
- 블루프린트 등록: `scripts/core/DataRegistry.gd`
- 전용 계약 테스트: `tools/tests/V122DualFrontLayoutContractTest.gd`
- 전용 테스트 scene: `tools/tests/V122DualFrontLayoutContractTest.tscn`

## 활성화 보류 이유

현재 전투 런타임은 모든 적을 `entrance`에서 생성하고 하나의 `active_route`만 사용한다. 후보 레이아웃을 지금 제품 기본값으로 교체하면 다음 문제가 생긴다.

- B 전선 도둑·공병이 A 정문에서 생성되어 B 전선을 역주행한다.
- 목표 시설을 다른 슬롯으로 옮겨도 specialist의 진입 전선이 시설 위치를 따라가지 않는다.
- 방어자 전용 연결로를 일반 graph edge로 열면 적도 최단경로로 사용한다.
- 기존 room 기반 몬스터 배치와 시설 배치가 다시 결합될 수 있다.

따라서 제품 활성화는 복수 진입 경로, 시설 위치 기반 specialist spawn, 방어자 전용 traversal, 저장 마이그레이션이 함께 준비된 뒤 수행한다. 이 안전장치는 임시 UI 플래그가 아니라 데이터의 `activation_state: candidate_not_product_default`로 명시했다.

## 전용 검증

실행:

```powershell
& 'C:\Users\LDK-6248\.local\godot45\Godot_v4.5.2-stable_win64.exe' --headless --path . --log-file .godot\v122_dual_front_contract.log --run res://tools/tests/V122DualFrontLayoutContractTest.tscn
```

결과:

- `V122_DUAL_FRONT_LAYOUT_CONTRACT_TEST: PASS`
- Godot의 Windows root certificate store 읽기 경고가 있었으나 테스트 결과와 무관하다.
- 전체 QA, 플레이 검수, 빌드, 커밋, 배포는 수행하지 않았다.

전용 테스트가 확인하는 항목:

- 실제 `ModuleGraph` validation
- 두 외부 진입점에서 왕좌까지의 exact route
- 전실 이전 공통 노드 0개
- 전실 이후 단일 공통 경로
- B 경로 길이 비율 1.15~1.35
- A/B 실제 walk-cell 폭 차이
- 실제 가시 칸 6개
- 5×5 전실과 전실 내 시설·함정 부재
- 고정 방어구역 5개와 교체식 시설 슬롯 4개
- 시설이 주 적 경로에 포함되지 않음
- 연결로가 초기 공용 graph에 존재하지 않음
- 기존 핵심 instance ID 보존

## 다음 단계

Phase B는 다음을 한 묶음으로 처리해야 한다.

1. `V122BattlePlanAdapter`를 단일 `active_route`에서 A/B route 집합으로 확장한다.
2. 몬스터 배치를 facility room이 아니라 고정 defense zone 기준으로 저장·복원한다.
3. 네 시설 슬롯의 내용과 몬스터 정원을 분리한다.
4. 시설 효과를 `local/adjacent/lane/global` 구역 판정으로 계산한다.
5. 같은 효과 계열은 최강 하나, 다른 계열은 조합하는 규칙을 실제 전투에 연결한다.
6. 집결·후퇴는 방어구역, 집중은 적, 시설 발동은 시설 instance를 직접 대상으로 삼는다.

Phase C에서는 그 위에 진입 전선별 spawn·telegraph, 도둑/공병의 시설 위치 추적, DAY 1~5 웨이브, 금화 1000·마나 100 연결로 건설과 저장 마이그레이션을 연결한다. 연결로는 방어자 전용 traversal이 준비되기 전까지 공용 graph에 추가하면 안 된다.
