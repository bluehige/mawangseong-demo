# v1.2.2 Stage 01 성 배경·공간 연결 시각 계약

## 1. 상태

- 작성일: 2026-07-29
- 대상 단계: 순차 시각 개편 4단계
- 대상 화면: 관리·배치·전투의 Stage 01 성 지도
- 현재 상태: `OWNER_SCOPE_APPROVAL_PENDING`
- 구현 전제: 사용자 승인 전에는 런타임 그래픽 자산과 렌더러를 변경하지 않는다.
- 제외: 모바일 웹, 밸런스, AI, spawn, 시설·몬스터 효과, 저장 의미, 방 위치, 이동 판정

## 2. 시각 논지·콘텐츠 계획·상호작용 논지

### 시각 논지

> 거칠게 확장 중인 하나의 동굴 성이 방과 복도 전체에 이어지고, 황금 표시가 없어도 바닥·문턱·그림자만으로 이동 가능한 길이 읽힌다.

### 콘텐츠 계획

1. 성 전체 실루엣과 실제 주 경로
2. 입구·병영·회복실·보물실·건설 슬롯·왕좌의 같은 크기 비교
3. 방 5×5와 복도 2셀의 정확한 접합
4. 선택·전투 표시를 제거해도 이해되는 기본 공간

### 상호작용 논지

- hover나 선택 전에도 문턱과 바닥 흐름으로 진입 방향을 읽는다.
- 선택 시에는 기존 공통 상태 테두리만 더하고 배경 그래픽 자체를 황금색으로 바꾸지 않는다.
- 전투 중 캐릭터가 복도를 이동하면 접지 그림자와 바닥 투영이 같은 높이로 보인다.

## 3. 현재 런타임의 실제 기준

### 활성 렌더 경로

- `GameRoot.use_quarter_module_map` 기본값은 `true`다.
- 실제 지도는 `QuarterDungeonRenderer`가 그린다.
- 과거 `gpt2_dungeon_connected_map.png`는 로드되지만 quarter module map이 활성화된 현재 기본 흐름에서는 사용되지 않는다.
- `assets/sprites/dungeon_quarter/modules/*_visual.png`도 현재 Stage 01 전체 지도의 주 렌더 기준이 아니다.

### 공간 데이터

| 항목 | 현재 계약 |
|---|---|
| 마스터 그리드 | 28×26 |
| 방 크기 | 5×5 셀 |
| 복도 폭 | 2셀 |
| Stage 01 방 | 입구, 병영, 회복실, 보물실, 건설 슬롯, 왕좌 |
| 복도 모듈 | `corridor_gap_network_01` |
| 복도 floor 셀 | 88 |
| 복도 walk 셀 | 88 |
| 함정 셀 | 4 |
| 연결 bridge | 14개, 7개 2셀 접합군 |

`ModuleGraph`가 같은 blueprint에서 floor, walkable, socket, object block을 만들고 `DungeonWalkMap`이 그 셀을 이동 판정에 사용한다. 별도의 자유형 물리 collider가 주 경로를 소유하는 구조가 아니다.

### 현재 합성 순서

1. 암석 void
2. floor tile
3. 방 footprint
4. 복도 path tint
5. wall·socket
6. connection bridge·문턱
7. Stage별 방 랜드마크
8. 캐릭터·전투 표시

구조 연결은 이미 존재한다. 현재 문제는 4~7번의 재질·명암·픽셀 밀도가 달라 접합부가 길이 아니라 UI 표시처럼 읽히는 데 있다.

## 4. 현재 Stage 01 자산 판정

| 역할 | 런타임 자산 | 판정 | 이유 |
|---|---|---|---|
| 입구 | `assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png` | 유지 | 회화형 석재·목재·황동 밀도가 기준 역할을 수행 |
| 병영 | `assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png` | 유지 | 입구와 광원·재질 계열이 가까움 |
| 회복실 | `assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png` | 유지 | 청록 포인트가 역할을 분리하면서 배경 암부를 유지 |
| 보물실 | `assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png` | 유지 | 재질 밀도와 투영이 다른 방과 호환 |
| 건설 슬롯 | `assets/props/stage_01/prop_foundation_marks_stage01_NE_back.png` | 유지 | 빈 공간 역할과 확장 가능성을 전달 |
| 왕좌 | `assets/props/stage_01/prop_throne_stage01_SW_back.png` | 교체 | 다른 다섯 자산보다 픽셀 밀도·선 굵기·단차 표현이 달라 화풍 이탈 |

교체하지 않는 다섯 자산도 최종 렌더에서 바닥 접합과 폐색 그림자가 맞는지 확인한다. 현재 판정은 자산 자체를 새로 생성하지 않는다는 뜻이며 배치·scale·modulate 보정까지 금지한다는 뜻은 아니다.

## 5. 핵심 문제

### P1. 복도가 공간보다 황금 안내선처럼 보임

- `QuarterDungeonRenderer._draw_corridor_path_layer`가 갈색·황금 계열을 사용한다.
- `_draw_connection_bridge`와 `_draw_path_mouth`가 밝은 황금 선을 반복한다.
- 결과적으로 실제 석재 길보다 UI 경로 표시가 먼저 읽힌다.

수정 규칙:

- 일반 복도는 저채도 보라 회색·철색 석재로 낮춘다.
- 밝은 황금은 현재 선택 후보나 주 행동에만 사용한다.
- 2셀 접합은 선이 아니라 같은 높이의 문턱·파손석·폐색 그림자로 연결한다.

### P2. 방과 복도의 높이·명암이 끊김

- 방은 full-grid 랜드마크 이미지가 바닥과 벽까지 포함한다.
- 복도는 타일·절차형 벽·bridge를 별도로 합성한다.
- 문턱에서 재질 주파수, 그림자 방향, 벽 높이가 한 번에 바뀐다.

수정 규칙:

- N/E/S/W 2셀 문턱 transition 4종을 exact socket 위치에 맞춘다.
- 방과 복도 바닥의 가장 밝은 면과 폐색 그림자 방향을 동일하게 고정한다.
- 방 가장자리와 복도 가장자리의 돌 크기 범위를 맞춘다.

### P3. 왕좌가 가장 큰 화풍 이탈점

- 픽셀아트 계열 왕좌가 회화형 입구·시설 사이에 놓인다.
- 최종 목표 방이 가장 먼저 별도 게임 자산처럼 보인다.

수정 규칙:

- SW 방향과 남쪽 2셀 입구는 유지한다.
- 5×5 room footprint와 alpha 여백을 유지한다.
- 입구 자산과 같은 회화형 디테일 밀도, 좌상단 온광, 보라 반사광으로 다시 제작한다.
- 금·수정 장식을 줄이고 돌·목재·뼈·찢어진 천을 중심으로 Stage 01의 미완성 성격을 유지한다.

## 6. 제작안 비교

### Option A — 셀 정합형 부분 교체

`추천`

- 왕좌 1종 재제작
- N/E/S/W 2셀 문턱 transition 4종
- 직선·코너·교차 복도 표면 정리
- 방·복도 공통 폐색 그림자
- 암벽·보라 안개 불규칙 가장자리 마스크
- 현행 room 위치와 walkable 셀 유지

장점:

- 보이는 길과 이동 판정이 같은 데이터에서 유지된다.
- 방 교체·Stage 확장·전투 좌표가 깨질 가능성이 낮다.
- 문제가 있는 자산만 교체해 화풍 기준을 빠르게 고정할 수 있다.

위험:

- renderer와 새 tile의 경계 조정이 필요하다.
- 문턱 4종을 실제 2셀 socket에 정확히 맞춰야 한다.

### Option B — 전체 연결형 배경 한 장 재제작

`비추천`

- Stage 01 전체 지도를 하나의 그림으로 다시 제작한다.

장점:

- 한 장 안에서는 광원과 분위기를 통일하기 쉽다.

위험:

- 방 교체, 확장 Stage, 지도 변화와 불일치한다.
- 이미지 속 길과 `DungeonWalkMap` 셀이 어긋날 수 있다.
- 기능을 유지하려면 상태별 전체 배경을 계속 추가해야 한다.

## 7. Option A 승인 시 제작·연결 순서

1. 왕좌와 문턱 4종의 exact 투영 guide를 기존 셀에서 추출한다.
2. GPT 내부 이미지 생성으로 왕좌와 transition 원본을 만든다.
3. `assets/source/imagegen/v122_stage01_spatial/`에 원본·프롬프트·출처를 기록한다.
4. alpha·scale·socket 정합 후 런타임 자산을 `assets/`에 둔다.
5. `asset_manifest.json`과 `QuarterDungeonRenderer`의 역할 기반 lookup만 변경한다.
6. 1920 표준과 1280 compact 관리 화면에서 방 중심 좌표가 이동하지 않았는지 확인한다.
7. 같은 build에서 이동 경로와 보이는 바닥의 일치를 관련 테스트로 확인한다.

## 8. 불변 조건

- `data/dungeon_quarter/starting_layout.json`의 방 위치와 연결을 변경하지 않는다.
- `data/dungeon_quarter/room_blueprints.json`의 floor/walk/socket을 변경하지 않는다.
- `ModuleGraph`, `DungeonWalkMap`, AI, 순찰, 전투 수치와 저장 의미를 변경하지 않는다.
- Stage 02~04 자산을 이번 단계에 섞지 않는다.
- 모바일 웹 레이아웃을 만들지 않는다.
- 사용자 승인 전 신규 그래픽을 생성하거나 런타임에 연결하지 않는다.

## 9. 승인 질문

`Option A — 셀 정합형 부분 교체`를 4단계의 제작 범위로 확정할 것인가?

승인되면 위 순서대로 왕좌와 4방향 문턱 guide부터 제작한다.
