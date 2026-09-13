# 진화체 승리·부상 초상

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6
- Build context: UIUX worktree (unreleased); product version unchanged.
- Source image path: assets/source/imagegen/uiux_evolution_emotions_20260913/victory.png
- Runtime image path: assets/sprites/portraits/uiux_evolution/victory.png
- Source image path: assets/source/imagegen/uiux_evolution_emotions_20260913/wounded.png
- Runtime image path: assets/sprites/portraits/uiux_evolution/wounded.png

기존 중립 초상 atlas를 참조한 GPT 내부 이미지 편집. 각 1536×1024 RGB 원본을 동일 복사했고 래스터 후처리는 없다. 프레임형 초상이라 배경은 의도적으로 불투명하다. Godot AtlasTexture에서 512×512 영역을 참조하고 밉맵으로 축소한다.

## victory prompt

Use case: identity-preserve. Edit the referenced 1536x1024 portrait atlas for this existing game. Keep the EXACT same 3-column by 2-row grid, six square 512x512 cells, no gutters or borders, identical six characters in identical positions, same costumes, equipment, species, palettes, head size and dark charcoal-violet opaque studio backgrounds. Top row: armored purple pudding with cream/cherry hat and turquoise fortress shields; green goblin ambush captain with leather hood and burgundy scarf/spear; pink-haired red-skinned horned flame mage with magenta staff/familiar. Bottom: purple pudding healer with white medical cloak/blue potions; helmeted green vault goblin with lock shield/keys; pink-haired horned raven-cloaked shaman with green lantern. Change ONLY expressions and small upper-body poses to a distinct VICTORY mood: pudding delighted confident cheerful eyes, goblins satisfied celebratory grin, flame mage triumphant proud warm smile, healer relieved joyous smile, shaman subtle satisfied knowing smile. Preserve recognizable identities and all attire, avoid confetti, trophies, extra characters, text or marks. Polished clean stylized 3D collectible render matching reference. Portrait framing, no full body expansion, nothing crosses cells. This is an opaque UI portrait atlas, not a transparent sprite.

## wounded prompt

Use case: identity-preserve. Edit the referenced existing game portrait atlas. Preserve exact 1536x1024 landscape composition: 3 columns x 2 rows, six equal square 512x512 cells, NO gutters/borders/text, the SAME characters and equipment at the same size in the SAME order with same opaque charcoal-violet studio backgrounds. Top row: purple pudding fortress defender with turquoise shield armor and cream/cherry; hooded green goblin ambush captain with red scarf/spear; pink-haired red-skinned horned flame mage with black/gold armor, staff and familiar. Bottom row: purple pudding medic with cream/cherry hat and white medical cloak/blue potions; helmeted green goblin with lock shield and gold keys; pink-haired horned feather-cloaked shaman with green lantern. Change ONLY expressions and subtle poses to WOUNDED AFTER A HARD FIGHT, still alive and recovering: visibly tired drooping eyes, slight grimace, lowered brows, lowered shoulders, pudding slumped slightly but still recognizable, healer concerned and tired, goblins weary determined, mages fatigued. Gentle scuffs on armor permissible, absolutely no blood, gore, torn bodies, huge bruises, new bandages or changed outfit. Clear emotional difference from neutral and victory without melodramatic despair. Match polished clean stylized 3D collectible rendering, soft cool rim lights, strong readable silhouettes. Head and upper-body portrait crop unchanged, no imagery crosses cell edges. Intentionally opaque portraits.
