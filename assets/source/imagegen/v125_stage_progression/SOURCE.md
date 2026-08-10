# v1.2.5 마왕성 단계별 공간 그래픽 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-08-10
- Target version: v1.2.5
- Source image path: assets/source/imagegen/v125_stage_progression/backgrounds/stage02_castle_selected.png
- Source image path: assets/source/imagegen/v125_stage_progression/backgrounds/stage03_keep_selected.png
- Source image path: assets/source/imagegen/v125_stage_progression/backgrounds/stage04_citadel_selected.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage02_castle_raw_chroma.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage02_castle_selected_alpha.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage03_keep_raw_chroma.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage03_keep_selected_alpha.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage04_citadel_raw_chroma.png
- Source image path: assets/source/imagegen/v125_stage_progression/corridor_surfaces/stage04_citadel_selected_alpha.png
- Runtime image path: assets/backgrounds/v125/bg_stage02_castle.png
- Runtime image path: assets/backgrounds/v125/bg_stage03_keep.png
- Runtime image path: assets/backgrounds/v125/bg_stage04_citadel.png
- Runtime image path: assets/tiles/stage_02/spatial/corridor_surface_stage02_2cell.png
- Runtime image path: assets/tiles/stage_02/spatial/corridor_surface_stage02_cell_00.png
- Runtime image path: assets/tiles/stage_02/spatial/corridor_surface_stage02_cell_01.png
- Runtime image path: assets/tiles/stage_02/spatial/corridor_surface_stage02_cell_10.png
- Runtime image path: assets/tiles/stage_02/spatial/corridor_surface_stage02_cell_11.png
- Runtime image path: assets/tiles/stage_02/spatial_road_autotile_v1/corridor_road_autotile_stage02_atlas.png
- Runtime image path: assets/tiles/stage_03/spatial/corridor_surface_stage03_2cell.png
- Runtime image path: assets/tiles/stage_03/spatial/corridor_surface_stage03_cell_00.png
- Runtime image path: assets/tiles/stage_03/spatial/corridor_surface_stage03_cell_01.png
- Runtime image path: assets/tiles/stage_03/spatial/corridor_surface_stage03_cell_10.png
- Runtime image path: assets/tiles/stage_03/spatial/corridor_surface_stage03_cell_11.png
- Runtime image path: assets/tiles/stage_03/spatial_road_autotile_v1/corridor_road_autotile_stage03_atlas.png
- Runtime image path: assets/tiles/stage_04/spatial/corridor_surface_stage04_2cell.png
- Runtime image path: assets/tiles/stage_04/spatial/corridor_surface_stage04_cell_00.png
- Runtime image path: assets/tiles/stage_04/spatial/corridor_surface_stage04_cell_01.png
- Runtime image path: assets/tiles/stage_04/spatial/corridor_surface_stage04_cell_10.png
- Runtime image path: assets/tiles/stage_04/spatial/corridor_surface_stage04_cell_11.png
- Runtime image path: assets/tiles/stage_04/spatial_road_autotile_v1/corridor_road_autotile_stage04_atlas.png

## 목적과 판정

기존 런타임은 Stage 02~04가 Stage 01의 동굴 배경·회색 벽·바닥을 그대로 공유하고, Stage 02는 데이터상 `production_fallback_v3` 상태였다. 이번 묶음은 시설 수만 늘어나는 방식에서 벗어나 다음 성장 단계를 공간 자체에서 읽히게 한다.

- Stage 02: 자연 동굴 안에 처음 축조한 저채도 현무암 성곽과 정돈된 통로
- Stage 03: 공성전에 대비한 중량감 있는 요새, 철제 보강과 낮은 보라 수호석
- Stage 04: 흑요석·암철·절제된 고금 장식으로 완성된 최종 성채
- 공통 계약: 맵과 유닛이 올라가는 중앙은 비워 두고 배경은 외곽에만 집중한다. 통로는 정확한 2:1 등각 투영, 단일 높이, 무방향 반복 표면을 유지한다.

## 생성 방법

Codex 내장 이미지 생성의 `precise-object-edit` 흐름을 사용했다. 배경은 기존 `assets/backgrounds/v2/bg_cave_f_3x3_01.png`를 카메라·중앙 여백 기준으로 고정했고, 통로는 기존 Stage 01 초록 배경 원본을 투영·캔버스 등록 기준으로 고정했다. Stage 03은 승인된 Stage 02 결과, Stage 04는 승인된 Stage 03 결과를 추가 기준으로 사용해 성장 연속성을 유지했다.

통로 초록 배경은 imagegen skill의 `remove_chroma_key.py`를 다음 공통 옵션으로 제거했다.

```text
--auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
```

`tools/prepare_v125_stage_progression_assets.py`가 선택 alpha의 가시 영역을 정확한 `256×128` 2셀 다이아몬드에 맞추고, `128×64` parity 셀 4종과 N/E/S/W 16-mask `2048×256` atlas를 결정적으로 생성한다. 배경은 `1536×1024` RGB PNG로 최적화한다.

## 최종 프롬프트 요약

### Stage 02 배경

기존 3:2 등각 배경의 중앙 60%와 어두운 값 체계를 보존하고, 외곽 자연 암반을 초창기 지하 마왕성의 낮은 현무암 기단·철제 보강·짙은 버건디 깃발·소형 화로로 교체한다. 보라색과 금색은 제한하고 중앙에는 시설·문·격자·캐릭터를 추가하지 않는다.

### Stage 03 배경

Stage 02의 구도를 보존하면서 외곽을 층진 현무암 성벽·철제 버팀대·작은 방어탑·낮은 보라 수호석을 갖춘 공성 요새로 강화한다. 밝기가 아니라 구조와 중량감으로 성장시키며 중앙은 계속 비워 둔다.

### Stage 04 배경

Stage 03의 방어 논리를 유지한 채 흑요석·암철·얇은 고금 테두리·낮은 보라 마력 통로·깊은 균열의 미세한 용암 반사로 최종 성채를 만든다. 네온·넓은 금판·중앙 초점·과도한 안개는 금지한다.

### Stage 02 통로

기존 초록 배경 2:1 다이아몬드의 형상과 위치를 완전히 보존하고, 거친 동굴 석판을 더 정돈된 현무암 블록·작은 철제 고정구·매우 얇은 버건디 줄눈으로 교체한다. 모든 요소는 평평하고 반복 가능해야 한다.

### Stage 03 통로

Stage 02 표면을 더 차갑고 무거운 현무암, 일부 매입형 암철 보강띠, 충격 마모, 극소수의 낮은 보라 수호점으로 강화한다. 보강재는 모두 바닥과 같은 높이이며 중앙 문양과 발광은 금지한다.

### Stage 04 통로

Stage 03 보강 논리를 유지하면서 조밀한 흑요석·암철 조립, 얇은 고금 매입점, 거의 꺼진 보라 마력선을 더한다. 시설보다 어둡고 조용해야 하며 모든 장식은 완전 매입형이다.

## 런타임 연결

`data/dungeon_quarter/asset_manifest.json`의 Stage 02~04 프로필이 각각 전용 배경과 전용 통로 atlas를 선택한다. 같은 프로필의 `floor_modulate`, `wall_modulate`, `object_modulate`는 기존 회색 구조벽과 고채도 후반 시설 사이의 명암·색온도 차이를 완화한다. 외곽 9-slice는 기존 검증된 암벽 실루엣을 재사용하되 단계별 feather 색만 달리해 검은 직사각형 끝을 없앤다.
