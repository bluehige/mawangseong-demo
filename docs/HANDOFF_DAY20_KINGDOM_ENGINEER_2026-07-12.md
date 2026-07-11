# DAY 20 왕국 공병 완료 핸드오프

작성일: 2026-07-12

## 완료 상태

DAY 20 `왕국 공병의 첫 시험`을 실제 플레이 가능한 상태로 완료했다. 신규 적 `왕국 공병`은 가장 가까운 작동 중 병영·감시초소·회복 둥지를 목표로 이동하고, 도착하면 해당 시설의 전투 효과를 10초 동안 실제로 멈춘다.

## 구현한 핵심 동작

- 공병은 일반 왕좌 목표와 분리된 `facility` 역할을 사용한다.
- 작동 중인 세 시설 가운데 가장 가까운 경로를 선택한다.
- 이미 무력화된 시설은 새 목표에서 제외한다.
- 도달하면 시설 효과를 10초간 중단하고 이후 왕좌로 진격한다.
- 맵에는 주황색 `공병 목표`, 무력화 뒤에는 빨간색 남은 시간이 표시된다.
- 시설 효과 패널도 무력화 상태와 남은 시간을 실시간으로 표시한다.
- 공병의 머리 위 위협 문구는 `시설 교란`이다.
- 결산에는 `시설 도달/등장`, `무력화 횟수`, `지켜낸 시설`을 표시한다.

## 신규 그래픽

공병 원본은 사용자가 지정한 대로 내장 이미지 생성기로 제작했다.

- 생성 원본: `assets/source/imagegen/engineer/CHR_ENGINEER_design_imagegen.png`
- 공격 포즈 원본: `assets/source/imagegen/engineer/CHR_ENGINEER_attack_pose_imagegen.png`
- 시설 교란 포즈 원본: `assets/source/imagegen/engineer/CHR_ENGINEER_skill_pose_imagegen.png`
- 생성 기록과 최종 프롬프트: `assets/source/imagegen/engineer/SOURCE.md`
- 런타임 스프라이트: `assets/sprites/enemies/enemy_engineer_*.png`
- 파생 도구: `tools/prepare_engineer_enemy_assets.py`
- 구성: idle 2장, move 4장, attack 4장, skill 4장, down 2장

첫 검수에서는 공격·교란 프레임이 기본 자세의 변형만으로 보여 동작 구분이 부족했다. 내장 이미지 생성기로 내려치기 공격 포즈와 장치 설치 포즈를 추가 생성한 뒤 런타임 프레임에 교체했다. 각 생성 원본에는 자르기, 크기 조정, 기울이기, 위치 이동만 적용했다. 16장 모두 RGBA 192x192이며 모서리가 투명한 것을 확인했다.

## DAY 20 구성

- 탐험가 2명: 0초부터
- 왕국 공병 1명: 15초
- 왕국 방패병 1명: 25초
- 왕국 공병 1명: 36초
- 왕국 조사관 1명: 48초
- 총 6명

## 검수 결과

- `DemoSmokeTest`: PASS. DAY 1~20 전체 흐름과 공병 목표·무력화·복구·결산 포함.
- `DAY20_ENGINEER_GOBLIN`: 74.4초 승리, 왕좌 1500/1500, 몬스터 전투 불능 0명.
- `DAY20_ENGINEER_SLIME`: 65.6초 승리, 왕좌 1500/1500, 몬스터 전투 불능 0명.
- 핵심 통합 검증 Full: PASS 10/10, 614.3초.
- 1920x1080 실제 렌더링 검수: 관리 예고, 공병 목표, 시설 무력화, 결산 모두 겹침·잘림 없음.

확인한 DAY 20 캡처는 `tmp/ui_regression_review`의 다음 네 파일이다.

- `05n_day20_management_engineer.png`
- `05o_day20_engineer_target.png`
- `05p_day20_facility_disabled.png`
- `05q_day20_engineer_result.png`

## 다음 작업

다음 실제 콘텐츠는 DAY 21이다. DAY 20의 공병 구성을 그대로 반복하기보다 공병 실패에 대한 왕국 측 반응을 짧게 이어 받고, 다른 전투 판단을 요구하는 리듬으로 전환한다. 두 번째 승급은 DAY 23까지 잠그고 Stage 02 외형 전환도 승인된 실제 자산이 준비될 때까지 보류한다.
