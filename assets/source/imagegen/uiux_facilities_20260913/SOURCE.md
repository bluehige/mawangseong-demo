# UIUX V2 보물고·회복 둥지·감시초소 원본 재제작

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6

공개 제품 기준선이며 새 버전·출시를 확정하지 않는다. 기존 v3의 각 방향을 편집 대상으로, 앞서 완성한 병영 NE를 재질·조명의 참고로 사용했다. 보물고·감시초소 SW 최종 후보는 기존 v3 투명 원본 하나로 다시 생성했다. 3D처럼 보이는 2D 스프라이트이며 기계적인 3D 회전 추출물은 아니다. 방향별 소품의 세부 묘사 차이는 남는다.

12장 모두 내부 도구의 실제 RGBA 출력이다. 불투명 RGB 체크무늬 후보는 채택하지 않았다. 도구는 prompt와 referenced_image_paths만 노출하므로 네이티브 투명 요구를 실제 prompt에 전달했다. 노출되지 않은 background 인자를 전달했다고 주장하지 않는다. 로컬 배경 제거·축소 저장·크롭·반전·회전·재인코딩 없이 원본을 동일 바이트로 복사했다. Godot 가져오기의 밉맵과 기존 알파 테두리 보정만 사용한다.

첫 묶음 중 이미지 읽기 helper_unknown_error가 발생하여 중단된 후보는 같은 내부 도구로 순차 재요청했다. 반복 투명 출력 실패는 해당 결과의 실패이며 모델의 투명 출력 불가능 판정이 아니다.

기본 facing_sprites 12경로와 성 2단계 NW 보물고/회복 둥지 별도 선택 2경로를 연결한다. 성 1·3·4 NW 전용 원본과 병영·수호핵은 보존한다. 카드·고스트·설치에는 같은 manifest 선택과 기존 렌더 구성을 사용한다. SW는 현재 기본 지도에 변경 가능한 슬롯이 없어 리소스 계약 검사로 구분한다.

## recovery_NE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/recovery_NE.png
- Runtime image path: assets/props/uiux/recovery_NE.png
- Reference: assets/props/v3/prop_recovery_nest_v3_NE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-1be6a3e6-08c0-4131-809d-c03d1c9c6949.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 44f18f8c0590f6713a9a99496d5355b54a6f7aaddcb6dbea2fa26177c43b6cc9

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Preserve the precise arrangement and camera view in image 1 for the existing recovery building. This is a separate facing, so do not mirror or rotate the style image. Make the output background transparent.

### 채택까지의 투명 출력 요청

최초 리마스터 출력에서 실제 RGBA를 확인하여 추가 편집 없이 채택.

## recovery_NW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/recovery_NW.png
- Runtime image path: assets/props/uiux/recovery_NW.png
- Reference: assets/props/v3/prop_recovery_nest_v3_NW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-e2e7790e-deb7-40b6-a2a5-8460d361e857.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 87a1788a71d3a73f3365490e70df1188a78d57481b2aa36fa0a82acb063ecea6

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Facility identity: the turquoise healing pool and existing jagged crystal sanctuary with its small torches. Preserve the exact pool shape, crystal positions and overall heights.

### 채택까지의 투명 출력 요청

이 이미지의 배경을 제거해 줘. 배경이 없는 투명 PNG 이미지로 만들어 줘.

## recovery_SE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/recovery_SE.png
- Runtime image path: assets/props/uiux/recovery_SE.png
- Reference: assets/props/v3/prop_recovery_nest_v3_SE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-b6796638-c43b-4792-8789-778678ac25fb.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 3f2c274eb0ecad24d314ac3b3497ce801b5dc0c70adfaf42620733af92c4a8f3

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Preserve the precise arrangement and camera view in image 1 for the existing recovery building. This is a separate facing, so do not mirror or rotate the style image. Make the output background transparent.

### 채택까지의 투명 출력 요청

건물과 바닥의 모습은 그대로 유지하고, 배경만 제거해서 투명 배경 PNG로 만들어 줘. 실제 알파 채널이 있는 이미지로 출력해 줘.

## recovery_SW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/recovery_SW.png
- Runtime image path: assets/props/uiux/recovery_SW.png
- Reference: assets/props/v3/prop_recovery_nest_v3_SW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-f07c45fe-1433-4c23-b5a3-ec11e5da12bc.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 5b02d45e3fe562be242b7aca58684c7378c6b50efaa17d4532c8f9a2cec49fd4

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
This is the exact recovery_SW reference view. Keep the original arrangement on each visible side. Whole object, actual transparent PNG, no backdrop.

### 채택까지의 투명 출력 요청

건물과 바닥의 모습은 그대로 유지하고, 배경만 제거해서 투명 배경 PNG로 만들어 줘. 실제 알파 채널이 있는 이미지로 출력해 줘.

## treasure_NE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/treasure_NE.png
- Runtime image path: assets/props/uiux/treasure_NE.png
- Reference: assets/props/v3/prop_treasure_pile_v3_NE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-416be2c8-5c1f-4ec9-8c79-863b92312f12.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 705c058e0f0a37eda0e7425349c052d59eb523621887643d6918fad9eae66081

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Preserve the precise arrangement and camera view in image 1 for the existing treasure building. This is a separate facing, so do not mirror or rotate the style image. Make the output background transparent.

### 채택까지의 투명 출력 요청

최초 리마스터 출력에서 실제 RGBA를 확인하여 추가 편집 없이 채택.

## treasure_NW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/treasure_NW.png
- Runtime image path: assets/props/uiux/treasure_NW.png
- Reference: assets/props/v3/prop_treasure_pile_v3_NW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-429ce588-a297-4559-8991-043a33854ad9.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): b873e8ca399186f770e698de2486e2a6309fafb0863073b0be3edad671401d17

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Facility identity: the piled treasure storage with its existing chests, coin barrels, gold and purple cloth. Preserve the exact chest and barrel count and orientation.

### 채택까지의 투명 출력 요청

건물과 바닥의 모습은 그대로 유지하고, 배경만 제거해서 투명 배경 PNG로 만들어 줘. 실제 알파 채널이 있는 이미지로 출력해 줘.

## treasure_SE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/treasure_SE.png
- Runtime image path: assets/props/uiux/treasure_SE.png
- Reference: assets/props/v3/prop_treasure_pile_v3_SE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-e26c6cac-d8ab-4508-b6d4-60ed1e2a28ea.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 70941de3c01de59242c58f7997e02d869619ade46cb29bfa222c9b4df8272323

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Preserve the precise arrangement and camera view in image 1 for the existing treasure building. This is a separate facing, so do not mirror or rotate the style image. Make the output background transparent.

### 채택까지의 투명 출력 요청

최초 리마스터 출력에서 실제 RGBA를 확인하여 추가 편집 없이 채택.

## treasure_SW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/treasure_SW.png
- Runtime image path: assets/props/uiux/treasure_SW.png
- Reference: assets/props/v3/prop_treasure_pile_v3_SW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-a3951735-43fa-4e78-a198-e362a4d80bdd.png
- Dimensions: 1448 × 1086
- SHA-256 (source = runtime): 294d709a9bf2b27d1d89ef482c08cf3ea8b2bac3eb3d160ce361c4a94c7e40e0

### 실제 생성 프롬프트

Edit this transparent game sprite into a softly lit stylized 3D render. Keep exactly its isometric camera, treasure chests, barrels, gold piles, purple cloth and diamond stone base. Simplify noisy tiny details into clean sculpted shapes and smooth material shading. Output a PNG with a transparent background. Keep the original transparency, no background at all. Keep the same 4:3 canvas aspect ratio and narrow transparent margin.

### 채택까지의 투명 출력 요청

Native transparency requested directly in remaster prompt; no separate processing.

## watch_post_NE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/watch_post_NE.png
- Runtime image path: assets/props/uiux/watch_post_NE.png
- Reference: assets/props/v3/prop_watch_post_v3_NE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-4b202387-125c-41f6-8ef1-166e68565427.png
- Dimensions: 1145 × 1374
- SHA-256 (source = runtime): 1a6eb7c9c642279264afa79f06894f1d447bd0243ed7efd99b924dd6b6a32125

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Facility identity: the existing compact stone-and-wood watch tower, purple canopy and hanging banner, leaning ladder and small torch. Preserve this exact side of the ladder and banner.

### 채택까지의 투명 출력 요청

이 이미지의 배경을 제거해 줘. 배경이 없는 투명 PNG 이미지로 만들어 줘.

## watch_post_NW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/watch_post_NW.png
- Runtime image path: assets/props/uiux/watch_post_NW.png
- Reference: assets/props/v3/prop_watch_post_v3_NW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-c8213d89-8abb-4341-af10-859688f5d7d4.png
- Dimensions: 1145 × 1374
- SHA-256 (source = runtime): cce6cce04273e1b45e7f5a96665c1eb22f0b94865b8f2b56ae5f9f6995995788

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
Preserve the exact ladder on the right and banner on the left, torch on the left and rocks on the right. Keep the entire outer stone platform visible. Native transparent background PNG.

### 채택까지의 투명 출력 요청

건물과 바닥의 모습은 그대로 유지하고, 배경만 제거해서 투명 배경 PNG로 만들어 줘. 실제 알파 채널이 있는 이미지로 출력해 줘.

## watch_post_SE

- Source image path: assets/source/imagegen/uiux_facilities_20260913/watch_post_SE.png
- Runtime image path: assets/props/uiux/watch_post_SE.png
- Reference: assets/props/v3/prop_watch_post_v3_SE_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-84425ce4-5b3e-4916-a998-f12387dec127.png
- Dimensions: 1145 × 1374
- SHA-256 (source = runtime): 9e50c06d5cf657d1dc4a24a277aa673d3dc6017050959bc1bfbf2162d1ea8cf0

### 실제 생성 프롬프트

Use case: style-transfer. Asset type: actual transparent isometric dungeon facility for the game Mawangseong. Image 1 is the exact building to remaster. Image 2 is ONLY the approved material/lighting style, never transfer its objects. Remaster image 1 in the clean sculpted stylized 3D game render of image 2. Preserve image 1's exact isometric camera angle, facing, footprint, silhouette, object count, arrangement, purple/bronze/dark-stone color identities. No upgrade, new objects, floor expansion, new walls or roof. Replace tiny noisy scratches, dot-like edges and muddy shading with broad clean material planes, soft upper-left lighting, rounded highlights and restrained ambient occlusion. Keep the same clearly recognizable facility at its actual 200px screen size. Single whole building centered on its existing diamond stone footprint, use the canvas efficiently with narrow transparent safety margin. Native transparent PNG output with actual alpha outside the object, including between thin parts. No checkerboard picture, solid backdrop, text, labels or layout panels. Keep all existing torches/effects small and within the object silhouette. Do not enlarge or alter the stone footprint relative to the objects.
This is the exact watch_post_SE reference view. Keep the original arrangement on each visible side. Whole object, actual transparent PNG, no backdrop.

### 채택까지의 투명 출력 요청

건물과 바닥의 모습은 그대로 유지하고, 배경만 제거해서 투명 배경 PNG로 만들어 줘. 실제 알파 채널이 있는 이미지로 출력해 줘.

## watch_post_SW

- Source image path: assets/source/imagegen/uiux_facilities_20260913/watch_post_SW.png
- Runtime image path: assets/props/uiux/watch_post_SW.png
- Reference: assets/props/v3/prop_watch_post_v3_SW_front.png
- Generated output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-9c0e8cfd-c76d-48ba-8897-8210036e92b0.png
- Dimensions: 1145 × 1374
- SHA-256 (source = runtime): fc2343eef945c68795124fbcd0b29fa3851e6ee748e5009cc59c2775841b55fc

### 실제 생성 프롬프트

Edit this transparent game sprite into a softly lit stylized 3D render. Keep exactly its camera, building, structure, purple roof, banners and stone base. Simplify noisy details into clear sculpted shapes and smooth material shading. Output a PNG with a transparent background. Keep the original transparency, no background at all. Keep the same 5:6 canvas aspect ratio and narrow transparent margin.

### 채택까지의 투명 출력 요청

Native transparency requested directly in remaster prompt; no separate processing.
