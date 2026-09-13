# UIUX V2 수호핵 방향별 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-12
- Target version: v1.2.6

위 고정 필드는 작업 기준 제품이며, 새 출시 버전을 확정하는 필드가 아니다. UIUX V2 작업의 새 제품 버전은 미확정이다.

## 생성 및 연결

사용자 지시에 따라 현재 내장 생성 도구로 네이티브 투명 PNG를 생성했다. 도구 입력에는 실제 제공된 prompt와 referenced_image_paths만 사용했으며, 존재하지 않는 background 파라미터를 전달했다고 주장하지 않는다. RGB 체크무늬 후보는 탈락시켰다. 선택본은 RGBA와 바깥 알파 0을 직접 검사했다. 로컬 배경 제거·색상 키·반전·회전·크롭·재샘플링은 하지 않았다. 생성 원본과 런타임 파일은 바이트가 같은 PNG다. 런타임에서는 기존 바닥 기준 배치와 캐시를 사용한다.

기존 NW 방향은 stage_03/04의 승인된 저장소 자산을 그대로 사용한다. 새 방향은 기존 투명 원본을 참고한 GPT 그림이며, 3D 모델의 기계적 회전 추출물은 아니다. 방향별 문·불기둥·수정 위치를 시각 확인하고 카드·고스트·설치 동일성은 실제 게임 테스트로 확인한다.

## stage03_NE

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage03_NE.png
- Runtime image path: assets/props/uiux/ward_core_stage03_NE.png
- Generation output: exec-e5996f81-0a05-4e59-a7a2-19aa067a13ab.png
- Reference: assets/props/stage_03/prop_ward_core_stage03_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Rotate this isometric dungeon room architecture exactly one quarter-turn clockwise about the vertical axis while keeping the camera fixed. The small raised crystal currently at the TOP corner must move to the RIGHT corner; the cluster of three gold spires currently at the BOTTOM corner must move to the LEFT corner. The two rear low walls now form the RIGHT-facing V (upper-right and lower-right edges), not the top-facing V. Re-render the stone and metal objects from this new view; all vertical spires remain vertical. Keep the same stage-3 central purple ward crystal, floor grid, gold fittings, room scale, clean outlined game art. Center the complete room with wide transparent margins. Make the background transparent using native transparent PNG output.

## stage03_SE

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage03_SE.png
- Runtime image path: assets/props/uiux/ward_core_stage03_SE.png
- Generation output: exec-600aea7f-b602-4b4f-b379-6376ac7424dc.png
- Reference: assets/props/stage_03/prop_ward_core_stage03_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Rotate the same room architecture by 180 degrees around the vertical axis, keeping the isometric camera fixed. The small raised corner crystal originally at the TOP must be at the BOTTOM/front corner. The triple gold spires originally at the BOTTOM must be at the TOP/rear corner. Keep the paired gold spires on left/right corners. Re-render the architectural surfaces from this new direction, not by flipping pixels. Keep the original clean outlined painted game art, dark stone, gold fittings, purple energy and original isometric projection and ground contact. All vertical pillars remain upright. Entire 5x5 diamond room centered with wide margins, no cropping, no text, no labels. Make the background transparent using native transparent PNG output. Preserve a real alpha channel around the room.
Native alpha edit: Make the background transparent using native transparent image output. Preserve the dungeon room completely unchanged. Return a transparent PNG with an alpha channel, not a picture of a checkerboard.

## stage03_SW

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage03_SW.png
- Runtime image path: assets/props/uiux/ward_core_stage03_SW.png
- Generation output: exec-c6c37a17-8155-4a7c-99c2-13ac0fd9cf42.png
- Reference: assets/props/stage_03/prop_ward_core_stage03_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Rotate the same room architecture by 90 degrees counterclockwise around the vertical axis, keeping the isometric camera fixed. The small raised corner crystal originally at the TOP must be at the LEFT corner. The triple gold spires originally at the BOTTOM must be at the RIGHT corner. The paired gold spires must now be at the TOP and BOTTOM corners. Re-render the architectural surfaces from this new direction, not by flipping pixels. Keep the original clean outlined painted game art, dark stone, gold fittings, purple energy and original isometric projection and ground contact. All vertical pillars remain upright. Entire 5x5 diamond room centered with wide margins, no cropping, no text, no labels. Make the background transparent using native transparent PNG output. Preserve a real alpha channel around the room.

## stage04_NE

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage04_NE.png
- Runtime image path: assets/props/uiux/ward_core_stage04_NE.png
- Generation output: exec-17fab4d2-4340-4363-8bdd-5e6d46ff42b6.png
- Reference: assets/props/stage_04/prop_ward_core_stage04_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Create a transparent PNG game asset. Recreate the supplied purple crystal ward room as viewed after a quarter turn clockwise around its vertical axis: the single arched door is visible on the LEFT-facing curve of the central circular platform, and the far-corner flame tower shifts to the RIGHT diamond corner. Same stage 4 room identity, stone diamond floor, runic gold ring, crystal pillars and 2:1 isometric projection. Draw exactly one door. Transparent background with an alpha channel. Do not draw a background pattern. The output itself must support transparency.
Correction: Remove the small gold framed purple doorway at the FRONT CENTER of the circular platform, at about x755 y650. Replace it entirely with uninterrupted dark stone masonry. Keep the large arched purple door on the LEFT side unchanged. Preserve everything else and the transparent background. Output native transparent PNG with an alpha channel.

## stage04_SE

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage04_SE.png
- Runtime image path: assets/props/uiux/ward_core_stage04_SE.png
- Generation output: exec-82205c1c-e710-4f33-b844-a6fe3e178afc.png
- Reference: assets/props/stage_04/prop_ward_core_stage04_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Create the rear view of this exact game building, rotated 180 degrees around its vertical axis at the same isometric camera angle. The purple doorway is on the far side, completely hidden behind the round stone base. All visible sides of the circular platform are continuous stone masonry, no door. The lone flame tower on the far TOP diamond corner moves to the near BOTTOM corner; the near crystal cluster moves to the far TOP corner. Keep the same giant purple crystal, circular gold rune ring, stone diamond platform and materials. Transparent PNG with native alpha transparency. Background is transparent, not a drawn checkerboard.

## stage04_SW

- Source image path: assets/source/imagegen/uiux_ward_core_directions_20260912/stage04_SW.png
- Runtime image path: assets/props/uiux/ward_core_stage04_SW.png
- Generation output: exec-616e5c76-d4c9-4253-9ed5-dcf2edde345b.png
- Reference: assets/props/stage_04/prop_ward_core_stage04_NW_back.png (및 같은 생성 흐름의 중간 후보)

### 실제 프롬프트

Edit this transparent game asset to show its opposite side. Move the single purple arched doorway from the LEFT curve of the central circular base to its RIGHT curve. Where the left doorway was, draw continuous dark stone masonry. Keep the front center as continuous masonry. Move the lone high flame pillar at the upper right to upper left. Keep the purple central crystal, gold rune ring, and room style. Preserve native transparency: output an RGBA PNG with transparent background, no checkerboard.
