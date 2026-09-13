# UIUX V2 입체 캐릭터 1차 원본

- Generation model: GPT internal image generation
- Generated date: 2026-09-12
- Target version: v1.2.6

제품 기준선이며 새 출시 버전은 미확정이다. 3D처럼 보이는 사전 렌더 스프라이트다. 실제 3D 모델/스켈레톤을 추가한 것은 아니다. 기존 종족·의상·색·장비와 idle 2/down 2/move 4/attack 4/skill 4의 16프레임 계약을 유지했다. 기존 능력·AI·프레임 속도는 변경하지 않았다. 이번 8종 외 진화·왕관·후반 캐릭터는 기존 그림을 유지하며 전면 미술 완료라고 판정하지 않는다.

## 생성·알파·런타임 처리

내장 imagegen의 실제 prompt/referenced_image_paths를 사용했다. 별도 background 파라미터가 제공되지 않아 인수로 전달했다고 주장하지 않는다. 불투명 RGB 체크무늬 후보는 탈락시켰으며 최종 파일의 RGBA와 바깥 alpha 0을 검사했다. 네이티브 투명화도 동일 GPT 내부 도구로 처리했다. 로컬 배경 제거·색상 키·PNG 크롭·리사이즈·회전·반전은 하지 않았다. 아래 원본/런타임 PNG의 SHA-256은 같다.

Godot는 원본을 축소 저장하지 않고 mipmap과 AtlasTexture UV로 표시한다. tools/measure_uiux_actor_art.py는 PNG를 읽어 연결된 불투명 몸체 경계를 측정하고 JSON 좌표만 쓴다. data/uiux_actor_art.json의 384×384 논리 프레임과 margin이 동작 크기/발 위치를 맞춘다. 미세한 분리 입자와 이웃 프레임 조각은 런타임 UV 범위 밖에 놓이며 PNG를 수정하지 않는다. 공격·마법의 과도한 경계 입자/프레임별 체형 일관성은 네이티브 동작 캡처로 별도 확인한다. 핀은 프레임 간 여백을 넓히는 GPT 재편집을 추가했다.

## slime

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/slime_sheet.png
- Runtime image path: assets/sprites/uiux3d/slime_sheet.png
- Generation output: exec-fb31e162-752e-4365-9ca3-c814002376cf.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/slime_combat_4x4.png

## goblin

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/goblin_sheet.png
- Runtime image path: assets/sprites/uiux3d/goblin_sheet.png
- Generation output: exec-ce2bcf30-6ed6-4c70-ba7a-1dc92cf111a9.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/goblin_combat_4x4.png

## imp

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/imp_sheet.png
- Runtime image path: assets/sprites/uiux3d/imp_sheet.png
- Generation output: exec-11654dd5-5775-4ab3-a426-29e14f5ec0bb.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/imp_combat_4x4.png

## explorer

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/explorer_sheet.png
- Runtime image path: assets/sprites/uiux3d/explorer_sheet.png
- Generation output: exec-10f2d451-499d-4ada-bf41-348470b19e40.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/explorer_combat_4x4.png

## thief

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/thief_sheet.png
- Runtime image path: assets/sprites/uiux3d/thief_sheet.png
- Generation output: exec-a72b5a8a-4b56-473b-89f8-071a2a0bea35.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/thief_combat_4x4.png

## trainee_hero

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/trainee_hero_sheet.png
- Runtime image path: assets/sprites/uiux3d/trainee_hero_sheet.png
- Generation output: exec-eda5d80e-dd28-447a-8439-3ac0e68dd6d5.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/trainee_hero_combat_4x4.png

## shieldbearer

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/shieldbearer_sheet.png
- Runtime image path: assets/sprites/uiux3d/shieldbearer_sheet.png
- Generation output: exec-9341009c-fcd1-492d-bd57-2854b58bca24.png
- Reference: docs/concepts/gpt_runtime_replacement_2026-07-12/shieldbearer_combat_4x4.png

## spore_healer

- Source image path: assets/source/imagegen/uiux_actors3d_20260912/spore_healer_sheet.png
- Runtime image path: assets/sprites/uiux3d/spore_healer_sheet.png
- Generation output: exec-89ce0caa-3820-413d-8463-c1548cd84d1c.png
- Reference: assets/source/imagegen/update4_contract_monsters/mori/mori_combat_sheet_chroma_2026-08-02.png

## 실제 공통 프롬프트

Edit the reference game character sprite sheet into a stylized 3D-rendered game character look: sculpted rounded volume, soft physically grounded light from upper left, subtle ambient occlusion, broad readable material highlights, clean silhouette. Keep the exact same recognizable character, face, species, costume colors, weapon and equipment. No upgrades, no crown, no new accessories. Remove the flat black comic outlines and tiny noisy texture. This must be a usable 4 by 4 animation atlas of exactly 16 separated whole-body poses in a perfectly regular square grid, not a character lineup or concept sheet. Each cell's character is centered horizontally, feet stay at 88 percent of its cell height, with safe transparent gutters and consistent body scale. First row: two subtle idle poses then two incapacitated non-graphic down poses. Row 2: four steps in a movement cycle. Row 3: four frames of the existing attack, windup to impact to recovery. Row 4: four frames of the existing special skill shown in the reference. Faces generally toward camera/right as in the reference. Render at square 1024 by 1024 if possible, no labels or visible grid. IMPORTANT use native transparent-background PNG output, actual alpha channel behind and between every character. No magenta chroma backdrop, no painted checkerboard, no flat background. Keep each entire figure and any skill effect inside its own cell. This is the actual runtime asset, not a screenshot.

## 실제 네이티브 투명화 프롬프트

Make the background transparent using native transparent image output. Preserve all sixteen character sprites completely unchanged in their exact positions. Return a transparent PNG with an alpha channel, not a picture of a checkerboard.

도둑·수습 용사 두 번째 투명화: Output this sprite atlas with a truly transparent background. Use the image generator's native transparent-background output mode. Preserve all 16 sprites and poses unchanged. Replace the gray checker pattern with transparency in the PNG alpha channel. No checker pattern, no backdrop.

## 핀 간격 보완 프롬프트

Edit this exact Imp 4 by 4 sprite atlas to add generous spacing for a game animation. Keep the character design, color, 3D shaded material, all sixteen poses and row ordering identical. Each complete pose including its fire must fit inside the central 70 percent of its cell; provide at least 45 empty pixels on every side in each 314x314 cell. Reduce the character AND all its effects together within each cell. No pose or fire may touch or overlap another cell. It is essential that the idle poses remain the same size as attack and spell bodies. Produce a native transparent PNG with actual zero alpha outside the sprites, with no grid or checker picture.

## 푸딩·탐험가·수습 용사·모리의 효과 여백 보완 프롬프트

Edit this exact 4 by 4 sprite atlas to add generous spacing for game animation. Keep the character identity, costume, rounded 3D shaded materials, all sixteen poses and row ordering identical. Each complete pose INCLUDING the entire glow and effect must fit inside the central 68 percent of its cell. Provide at least 45 empty pixels on every side within each 314x314 cell. Reduce the body and its equipment together equally in EVERY cell; compress any oversized glow to fit without changing the body size. No body, glow, sparkle or effect may touch or overlap another cell. Keep the idle body the same size as attack and spell bodies. No cropping at cell edges. Native transparent PNG output with actual zero alpha outside the sprites, no checkerboard picture and no backdrop.

이후 위 네이티브 투명화 프롬프트를 적용하고 실제 RGBA를 검사했다. 수습 용사는 두 번째 투명화 문구로 다시 생성해 채택했다. 앞서 올린 RGB 체크무늬 후보는 사용하지 않았다.

최종 런타임 표시 영역은 측정 몸체 경계와 분리했다. 몸체 경계 바깥으로 원본 기준 10px의 반투명 빛 여유를 두되 인접 셀을 넘지 않게 제한한다. visible_bounds는 몸체 크기만 보존하므로 효과 여백을 늘려도 캐릭터가 작아지지 않는다. 이는 JSON UV/margin 처리이며 원본이나 런타임 PNG 픽셀을 바꾸지 않는다.
