# UIUX 진화체 초상화

Generation model: GPT internal image generation
Generated date: 2026-09-13
Target version: 1.2.6 UIUX worktree (unreleased)
Source image path: assets/source/imagegen/uiux_evolution_portraits_20260913/portraits.png
Runtime image path: assets/sprites/portraits/uiux_evolution/portraits.png

내부 생성 도구 원본을 그대로 복사. 래스터 축소·배경 제거·후처리 없음. Godot AtlasTexture에서 512×512 영역 6개를 참조한다. 기본/승리/부상 초상은 동일한 중립 그림을 재사용하며 별도 감정 그림을 생성했다고 표시하지 않는다. 기존 전장 3D 시트 5개를 참조했고 보물고 수호자는 장비·색상을 텍스트로 지정했다(도구 참조 상한 5개).

## Prompt

Create one production portrait atlas for an existing fantasy defense game. Use the FIVE referenced sprite sheets ONLY as character identity references, The vault guard has no reference sheet: green goblin in dark metal helmet carrying a lock shield and gold keys. Output a landscape 3 columns by 2 rows atlas, exactly six equal square portrait cells, no gutters, no borders, no writing, no labels. Top row left to right: reference 1 purple pudding slime in turquoise fortress armor with cream/cherry hat; reference 2 green goblin ambush captain in black leather hood and burgundy scarf with spear; reference 3 pink-haired red-skinned horned flame mage with black/gold armor and magenta flame staff, little dark familiar. Bottom row left to right: reference 4 purple pudding rescue healer with white cloak, green medical medallion, blue potions, cream/cherry hat; green goblin vault guard in dark metal helmet with lock shield and golden keys; reference 5 pale pink-haired horned ember shaman in raven feather cloak, green lantern staff and purple wisp. Each cell must depict ONLY that one SAME character, head and upper body, three-quarter view looking toward viewer, full horns/hat/ears within its own cell, important equipment partly visible. Preserve their exact identity and equipment, do not redesign them into ordinary base monsters. Clean polished stylized 3D collectible character rendering, smooth modeled forms, broad legible highlights, sharp eyes and silhouettes, high quality hand-painted materials, no pixel art, no coarse noise or excessive surface texture. Each cell has the SAME very dark charcoal violet subtle studio gradient background, no scenery or ground. Soft cool rim lighting, flattering key light, strong figure/background separation. Neutral confident lively expressions, detailed at 512px per cell. Fill each equal square evenly with face large enough to read at a small UI portrait size. This atlas is used as six cropped in-engine square portraits so nothing may cross cell boundaries. Background is intentionally opaque for these framed portraits.

Godot import: mipmaps/generate=true. 원본 크기는 유지하고 GPU 축소 표시용 밉맵만 생성한다.
