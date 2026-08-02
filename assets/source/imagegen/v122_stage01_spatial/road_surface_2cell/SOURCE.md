# Stage 01 2셀 도로 표면 시안 생성 기록

## 정책 고정 필드

- Generation model: GPT internal image generation
- Generated date: 2026-08-01
- Target version: 1.2.2
- Source image path: assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_generated_raw_black.png
- Source image path: assets/source/imagegen/v122_stage01_spatial/road_surface_2cell/road_surface_2cell_alpha_preview.png
- Runtime image path: 미연결 — 사용자 시각 승인 및 exact slicing 후 결정

## 상태

- 자산 역할: Stage 01 도로 표면 2셀 proof candidate
- 방향: 긴 축을 따라 읽히는 비방향성 도로 재질
- 합성 역할: 방과 방 사이의 물리적 보행 도로 표면
- 생성 canvas: 1254×1254
- 상태: `SOURCE_CANDIDATE_PENDING_APPROVAL`
- 기존 비교 자산: `assets/source/imagegen/v122_stage01_spatial/corridor_surface_2cell/corridor_surface_2cell_selected_alpha_preview.png`

## 생성 입력과 변환

- 입력 reference: 기존 2셀 복도 표면 alpha 후보를 편집 대상으로 사용했다.
- 변경 의도: 규칙적인 작은 사각 타일 반복을 제거하고, 큰 불규칙 석판이 길의 진행 방향을 은근히 보여 주도록 수정했다.
- 배경: 생성 결과가 검정 단색으로 반환되어 `remove_chroma_key.py --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill`로 알파 후보를 만들었다.
- 최종 원본은 아직 256×128 exact runtime patch로 자르지 않았다.

## 생성 프롬프트 요약

```text
Replace the overly regular square paving grid with a believable worn fortress road. Keep the same full 2-by-2 isometric diamond footprint and flat walkable height. Use large irregular dark stone slabs with subtle longitudinal direction, restrained wear, and no gold route line. Match the painterly dark-fantasy Stage 01 room assets. Avoid checkerboard repetition, high-frequency micro-cobbles, room-floor appearance, walls, props, UI, text, and watermark.
```

## 검수 메모

- 시각 판정: 기존 후보의 작은 규칙 격자보다 도로 방향과 큰 석판이 잘 읽힌다.
- 남은 판정: 실제 256×128 축소에서 석판 경계가 지나치게 촘촘해지지 않는지 확인해야 한다.
- 남은 판정: 직선·코너·교차 파생을 만들었을 때 반복 패턴이 눈에 띄지 않는지 확인해야 한다.
- 런타임 연결: 하지 않음.
