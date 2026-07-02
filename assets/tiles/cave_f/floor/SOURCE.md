이 파일이 왜 필요한지: `cave_f` 쿼터뷰 던전 바닥 타일 PNG의 생성 출처와 후처리 규칙을 남겨, 이후 렌더러 연결이나 재생성 시 같은 기준을 유지하게 한다.

# Cave F Floor Tile Source

작성일: 2026-07-02

## 생성 방식

- 사용자 지시에 따라 GPT 이미지 생성 경로를 사용했다.
- 원본은 4x4 쿼터뷰 동굴 석재 바닥 타일 시트로 생성했다.
- 원본 프롬프트 핵심:
  - 4 columns x 4 rows atlas
  - reusable quarter-view/isometric cave stone floor tile art
  - dark fantasy cave fortress stone floor
  - pure `#00ff00` chroma-key background
  - no text, labels, UI, props, characters, or full map

## 원본 파일

생성 원본 보관 위치:

```text
C:\Users\blueh\.codex\generated_images\019f1d97-678f-73e1-9106-3e8b68f3c791\ig_000244b01eca693f016a464a3a0c988191ad0e787937d8924b.png
```

프로젝트 내 복사본:

```text
assets/tiles/cave_f/floor/gpt2_floor_cave_f_source_atlas.png
```

## 최종 파일

최종 출력은 `data/dungeon_quarter/tile_variant_manifest.json`의 `floor_mask` 항목에 맞춘다.

```text
assets/tiles/cave_f/floor/floor_cave_f_mask_00.png
assets/tiles/cave_f/floor/floor_cave_f_mask_01.png
assets/tiles/cave_f/floor/floor_cave_f_mask_02.png
assets/tiles/cave_f/floor/floor_cave_f_mask_03.png
assets/tiles/cave_f/floor/floor_cave_f_mask_04.png
assets/tiles/cave_f/floor/floor_cave_f_mask_05.png
assets/tiles/cave_f/floor/floor_cave_f_mask_06.png
assets/tiles/cave_f/floor/floor_cave_f_mask_07.png
assets/tiles/cave_f/floor/floor_cave_f_mask_08.png
assets/tiles/cave_f/floor/floor_cave_f_mask_09.png
assets/tiles/cave_f/floor/floor_cave_f_mask_10.png
assets/tiles/cave_f/floor/floor_cave_f_mask_11.png
assets/tiles/cave_f/floor/floor_cave_f_mask_12.png
assets/tiles/cave_f/floor/floor_cave_f_mask_13.png
assets/tiles/cave_f/floor/floor_cave_f_mask_14.png
assets/tiles/cave_f/floor/floor_cave_f_mask_15.png
```

## 후처리 규칙

- 초록 배경을 투명 알파로 제거했다.
- 각 셀을 `128x64` 쿼터뷰 바닥 타일 크기에 맞췄다.
- 최종 타일은 다이아몬드 형태의 알파 마스크를 사용한다.
- 4방향 연결 마스크는 `AutoTileMask.gd` 기준을 따른다.
  - `NW = 1`
  - `NE = 2`
  - `SE = 4`
  - `SW = 8`
- 연결되지 않은 방향은 더 어두운 테두리와 낮은 립을 넣어, 통로 끝이나 방 외곽처럼 읽히게 했다.

## 주의

현재 `QuarterDungeonRenderer.gd`는 아직 이 PNG를 실제 화면에 그리지 않는다. 이번 작업은 실제 타일 리소스를 먼저 준비한 것이며, 다음 단계에서 `tile_variant_manifest.json`과 렌더러를 연결해야 한다.
