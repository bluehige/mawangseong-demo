# B04 변경 값

몬스터 종족·레벨 성장·건물 기본 수치와 웨이브 HP/ATK 계수 변경 없음. 웨이브의 수량·등장 간격·경유·목표 우선만 조정한다. 탐색 중 DAY30 ATK -20% 후보는 지도 강화 상태가 누락된 비교에 근거한 것으로 확인해 원복하고 채택하지 않았다.

`data/waves.json` — 이번 B04 (0118 커밋 대비)

| DAY | 행(1부터) | 필드 | 이전 | 이후 |
|---|---:|---|---|---|
| day_10 | 2 | objective_priority | 1 | 0.25 |
| day_10 | 2 | spawn_interval | 3.28 | 4.592 |
| day_10 | 3 | objective_priority | 1 | 0.25 |
| day_10 | 3 | spawn_interval | 0.8 | 1.12 |
| day_10 | 4 | objective_priority | 1 | 0.25 |
| day_10 | 4 | spawn_interval | 0.8 | 1.12 |
| day_10 | 5 | objective_priority | 1 | 0.25 |
| day_10 | 5 | spawn_interval | 0.8 | 1.12 |
| day_11 | 2 | objective_priority | 1 | 0.25 |
| day_11 | 2 | spawn_interval | 3.36 | 4.704 |
| day_11 | 3 | objective_priority | 1 | 0.25 |
| day_11 | 3 | spawn_interval | 0.8 | 1.12 |
| day_11 | 4 | objective_priority | 1 | 0.25 |
| day_11 | 4 | spawn_interval | 5.6 | 7.84 |
| day_12 | 2 | objective_priority | 1 | 0.25 |
| day_12 | 2 | spawn_interval | 3.28 | 4.592 |
| day_12 | 3 | objective_priority | 1 | 0.25 |
| day_12 | 3 | spawn_interval | 0.8 | 1.12 |
| day_12 | 4 | objective_priority | 1 | 0.25 |
| day_12 | 4 | spawn_interval | 6.8 | 9.52 |
| day_12 | 5 | objective_priority | 1 | 0.25 |
| day_12 | 5 | spawn_interval | 0.8 | 1.12 |
| day_13 | 2 | objective_priority | 1 | 0.25 |
| day_13 | 2 | spawn_interval | 3.44 | 4.816 |
| day_13 | 3 | objective_priority | 1 | 0.25 |
| day_13 | 3 | spawn_interval | 0.8 | 1.12 |
| day_13 | 4 | objective_priority | 1 | 0.25 |
| day_13 | 4 | spawn_interval | 0.8 | 1.12 |
| day_13 | 5 | objective_priority | 1 | 0.25 |
| day_13 | 5 | spawn_interval | 6.4 | 8.96 |
| day_14 | 2 | objective_priority | 1 | 0.25 |
| day_14 | 2 | spawn_interval | 3.28 | 4.592 |
| day_14 | 3 | objective_priority | 1 | 0.25 |
| day_14 | 3 | spawn_interval | 0.8 | 1.12 |
| day_14 | 4 | objective_priority | 1 | 0.25 |
| day_14 | 4 | spawn_interval | 0.8 | 1.12 |
| day_14 | 5 | objective_priority | 1 | 0.25 |
| day_14 | 5 | spawn_interval | 8.0 | 11.2 |
| day_15 | 2 | count | 3 | 2 |
| day_15 | 2 | objective_priority | 1 | 0.2 |
| day_15 | 2 | spawn_interval | 3.36 | 5.04 |
| day_15 | 3 | objective_priority | 1 | 0.2 |
| day_15 | 3 | spawn_interval | 0.8 | 1.2 |
| day_15 | 4 | objective_priority | 1 | 0.2 |
| day_15 | 4 | spawn_interval | 0.8 | 1.2 |
| day_15 | 5 | objective_priority | 1 | 0.2 |
| day_15 | 5 | spawn_interval | 0.8 | 1.2 |
| day_15 | 6 | objective_priority | 0.9 | 0.1 |
| day_15 | 6 | spawn_delay | 48.0 | 78.0 |
| day_15 | 6 | spawn_interval | 0.8 | 1.2 |
| day_15 | 6 | waypoint_room_id | null | "ward_core" |
| day_16 | 1 | spawn_interval | 1.4 | 1.68 |
| day_16 | 2 | objective_priority | 1 | 0.25 |
| day_16 | 2 | spawn_interval | 3.36 | 4.032 |
| day_16 | 3 | objective_priority | 1 | 0.25 |
| day_16 | 3 | spawn_interval | 0.8 | 0.96 |
| day_16 | 4 | objective_priority | 1 | 0.25 |
| day_16 | 4 | spawn_interval | 0.8 | 0.96 |
| day_16 | 5 | objective_priority | 1 | 0.25 |
| day_16 | 5 | spawn_interval | 0.8 | 0.96 |
| day_17 | 1 | spawn_interval | 1.4 | 1.68 |
| day_17 | 2 | objective_priority | 1 | 0.25 |
| day_17 | 2 | spawn_interval | 4.0 | 4.8 |
| day_17 | 3 | objective_priority | 1 | 0.25 |
| day_17 | 3 | spawn_interval | 0.8 | 0.96 |
| day_17 | 4 | objective_priority | 1 | 0.25 |
| day_17 | 4 | spawn_interval | 0.8 | 0.96 |
| day_17 | 5 | objective_priority | 1 | 0.25 |
| day_17 | 5 | spawn_interval | 0.8 | 0.96 |
| day_18 | 1 | spawn_interval | 1.4 | 1.68 |
| day_18 | 2 | objective_priority | 1 | 0.25 |
| day_18 | 2 | spawn_interval | 4.0 | 4.8 |
| day_18 | 3 | objective_priority | 1 | 0.25 |
| day_18 | 3 | spawn_interval | 20.8 | 24.96 |
| day_18 | 4 | objective_priority | 1 | 0.25 |
| day_18 | 4 | spawn_interval | 0.8 | 0.96 |
| day_18 | 5 | objective_priority | 1 | 0.25 |
| day_18 | 5 | spawn_interval | 0.8 | 0.96 |
| day_19 | 1 | spawn_interval | 1.4 | 1.68 |
| day_19 | 2 | objective_priority | 1 | 0.25 |
| day_19 | 2 | spawn_interval | 4.0 | 4.8 |
| day_19 | 3 | objective_priority | 1 | 0.25 |
| day_19 | 3 | spawn_interval | 3.2 | 3.84 |
| day_19 | 4 | objective_priority | 1 | 0.25 |
| day_19 | 4 | spawn_interval | 3.2 | 3.84 |
| day_19 | 5 | objective_priority | 1 | 0.25 |
| day_19 | 5 | spawn_interval | 0.8 | 0.96 |
| day_19 | 6 | objective_priority | 1 | 0.25 |
| day_19 | 6 | spawn_interval | 0.8 | 0.96 |
| day_20 | 2 | objective_priority | 1 | 0.4 |
| day_20 | 3 | objective_priority | 1 | 0.4 |
| day_20 | 4 | objective_priority | 1 | 0.4 |
| day_20 | 5 | objective_priority | 1 | 0.4 |
| day_20 | 6 | objective_priority | 1 | 0.4 |
| day_20 | 7 | objective_priority | 0.6 | 0.2 |
| day_21 | 2 | objective_priority | 1 | 0.4 |
| day_21 | 3 | objective_priority | 0.6 | 0.2 |
| day_21 | 4 | objective_priority | 1 | 0.4 |
| day_21 | 5 | objective_priority | 1 | 0.4 |
| day_21 | 6 | objective_priority | 1 | 0.4 |
| day_22 | 2 | objective_priority | 1 | 0.2 |
| day_22 | 3 | objective_priority | 1 | 0.3 |
| day_22 | 4 | objective_priority | 1 | 0.3 |
| day_22 | 5 | objective_priority | 1 | 0.3 |
| day_22 | 6 | objective_priority | 1 | 0.3 |
| day_23 | 2 | objective_priority | 1 | 0.2 |
| day_23 | 3 | objective_priority | 1 | 0.3 |
| day_23 | 4 | objective_priority | 1 | 0.3 |
| day_23 | 5 | objective_priority | 1 | 0.3 |
| day_23 | 6 | objective_priority | 1 | 0.3 |
| day_23 | 7 | objective_priority | 1 | 0.3 |
| day_24 | 2 | objective_priority | 1 | 0.2 |
| day_24 | 3 | objective_priority | 1 | 0.3 |
| day_24 | 4 | objective_priority | 1 | 0.3 |
| day_24 | 5 | objective_priority | 1 | 0.3 |
| day_24 | 6 | objective_priority | 1 | 0.3 |
| day_24 | 7 | objective_priority | 1 | 0.3 |
| day_25 | 2 | objective_priority | 1 | 0.4 |
| day_25 | 3 | objective_priority | 1 | 0.4 |
| day_25 | 4 | objective_priority | 1 | 0.4 |
| day_25 | 5 | objective_priority | 1 | 0.4 |
| day_25 | 6 | objective_priority | 1 | 0.4 |
| day_26 | 2 | objective_priority | 1 | 0.4 |
| day_26 | 3 | grade_routes.D.objective_priority | 1.0 | 0.2 |
| day_26 | 3 | objective_priority | 0.6 | 0.2 |
| day_26 | 4 | objective_priority | 1 | 0.4 |
| day_26 | 5 | objective_priority | 1 | 0.4 |
| day_26 | 6 | objective_priority | 1 | 0.4 |
| day_26 | 7 | objective_priority | 1 | 0.4 |
| day_27 | 2 | objective_priority | 1 | 0.5 |
| day_27 | 3 | objective_priority | 1 | 0.5 |
| day_27 | 4 | objective_priority | 1 | 0.5 |
| day_27 | 5 | objective_priority | 1 | 0.5 |
| day_27 | 6 | objective_priority | 1 | 0.5 |
| day_27 | 7 | objective_priority | 1 | 0.5 |
| day_28 | 2 | objective_priority | 1 | 0.5 |
| day_28 | 3 | objective_priority | 1 | 0.5 |
| day_28 | 4 | objective_priority | 1 | 0.5 |
| day_28 | 5 | objective_priority | 1 | 0.5 |
| day_28 | 6 | objective_priority | 1 | 0.5 |
| day_28 | 7 | objective_priority | 1 | 0.5 |
| day_28 | 8 | objective_priority | 1 | 0.5 |
| day_30 | 2 | objective_priority | 1 | 0.5 |
| day_30 | 3 | objective_priority | 1 | 0.5 |
| day_30 | 4 | objective_priority | 1 | 0.5 |
| day_30 | 5 | objective_priority | 1 | 0.5 |
| day_30 | 6 | objective_priority | 0.6 | 0.5 |
| day_30 | 7 | objective_priority | 1 | 0.5 |
| day_30 | 8 | grade_routes.C.objective_priority | 0.3 | 0.1 |
| day_30 | 8 | grade_routes.C.waypoint_room_id | null | "ward_core" |
| day_30 | 8 | objective_priority | 0.6 | 0.1 |
| day_6 | 2 | objective_priority | 1 | 0.25 |
| day_6 | 2 | spawn_interval | 3.84 | 5.376 |
| day_6 | 3 | objective_priority | 1 | 0.25 |
| day_6 | 3 | spawn_interval | 5.6 | 7.84 |
| day_7 | 2 | objective_priority | 1 | 0.25 |
| day_7 | 2 | spawn_interval | 3.36 | 4.704 |
| day_7 | 3 | objective_priority | 1 | 0.25 |
| day_7 | 3 | spawn_interval | 5.2 | 7.28 |
| day_8 | 2 | objective_priority | 1 | 0.25 |
| day_8 | 2 | spawn_interval | 3.36 | 4.704 |
| day_8 | 3 | objective_priority | 1 | 0.25 |
| day_8 | 3 | spawn_interval | 5.6 | 7.84 |
| day_9 | 2 | objective_priority | 1 | 0.25 |
| day_9 | 2 | spawn_interval | 3.52 | 4.928 |
| day_9 | 3 | objective_priority | 1 | 0.25 |
| day_9 | 3 | spawn_interval | 0.8 | 1.12 |
| day_9 | 4 | objective_priority | 1 | 0.25 |
| day_9 | 4 | spawn_interval | 5.6 | 7.84 |

`data/v122/dual_front_day01_05_waves.json` — 실제 DAY1~5 선택 파일

| DAY | 행(1부터) | 필드 | 이전 | 이후 |
|---|---:|---|---|---|
| day_1 | 1 | attack_throne | null | true |
| day_1 | 1 | objective_priority | null | 1 |
| day_5 | 1 | attack_throne | null | true |
| day_5 | 1 | attack_throne_lane | null | 0 |
| day_5 | 1 | objective_priority | null | 1 |

중지된 0115 미커밋 보정→0118 복원 (원문: superseded_0115_waves.json)

| DAY | 행(1부터) | 필드 | 이전 | 이후 |
|---|---:|---|---|---|
| day_20 | 2 | grade_routes.D.waypoint_room_ids | ["recovery_nest", ""] | null |
| day_20 | 5 | grade_routes | {"D": {"target_room_id": "recovery_nest"}} | null |
| day_21 | 2 | grade_routes.D.waypoint_room_ids.0 | "recovery_nest" | "watchtower_2" |
| day_22 | 1 | grade_routes | {"D": {"atk_scale": 1.6464}} | null |
| day_22 | 2 | grade_routes.D.atk_scale | 1.679328 | null |
| day_22 | 3 | grade_routes | {"D": {"atk_scale": 1.644244}} | null |
| day_22 | 4 | grade_routes | {"D": {"atk_scale": 1.609356}} | null |
| day_22 | 5 | grade_routes | {"D": {"atk_scale": 1.679328}} | null |
| day_22 | 6 | grade_routes | {"D": {"atk_scale": 1.609356}} | null |
| day_23 | 2 | grade_routes.D.atk_scale | 1.7 | 1.4 |
| day_23 | 2 | grade_routes.D.hp_scale | 12.536048 | 17.90864 |
| day_30 | 1 | grade_routes | {"C": {"atk_scale": 1.893375}} | null |
| day_30 | 2 | grade_routes.C.atk_scale | 1.415271 | 1.71548 |
| day_30 | 3 | grade_routes | {"C": {"atk_scale": 2.134687}} | null |
| day_30 | 4 | grade_routes | {"C": {"atk_scale": 2.134687}} | null |
| day_30 | 5 | grade_routes | {"C": {"atk_scale": 2.134687}} | null |
| day_30 | 6 | grade_routes | {"C": {"atk_scale": 2.262728}} | null |
| day_30 | 7 | grade_routes | {"C": {"atk_scale": 2.134687}} | null |
| day_30 | 8 | grade_routes.C.atk_scale | 4.269375 | null |

코드 변경:

- `GameRoot._open_intrusion_brief`: 진행 중인 본편/합류 대사를 예약된 관리 복귀가 덮어쓰지 않도록 보호.
- `ApprovedBattleController.spawn_enemy`: 명시적 옥좌 우선 공격·경유를 F/E에서도 지정 웨이브에 적용. 공병·도둑의 최종 목표 정책은 유지.
- `ApprovedMonsterPlacement.auto_place`: D는 실제 가용 탱커 2명을 옥좌 호위로 우선 배치. C는 입구 슬라임을 유지하고 가용 다리 트롤·접착 달팽이 등을 양쪽 옥좌 입구에 분산.

웨이브 SHA-256: `d113b2c419b53db16f1e5bea2bf930bbd94e48c5d241dbc9976a1e1e5eebf3f4`.
