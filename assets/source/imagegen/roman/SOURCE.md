# CHR_ROMAN Imagegen Source

Date: 2026-07-12

Roman is an original campaign boss character generated only with Codex's built-in
`image_gen` tool. Transparent sources were generated on a flat green chroma-key
field and converted to RGBA with the installed imagegen skill helper.

## Character direction

- Role: official adventurer-guild survey captain, supply commander, and weary middle manager
- Read: exhausted by upper-management paperwork, but still competent and authoritative in battle
- Silhouette: peaked compass-crest cap, long split-tail command coat, report ledger,
  short command baton, field-supply satchel, and two rolled route maps
- Palette: slate navy, charcoal, worn brown leather, parchment cream, antique brass,
  and muted wine red
- Combat language: baton melee attack; ledger verification and directional baton signal
  for the resupply command skill

## Workspace assets

Imagegen sources:

- `assets/source/imagegen/roman/CHR_ROMAN_design_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_portrait_command_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_idle_sheet_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_move_sheet_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_attack_sheet_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_skill_sheet_imagegen.png`
- `assets/source/imagegen/roman/CHR_ROMAN_down_sheet_imagegen.png`

Runtime assets:

- `assets/sprites/portraits/campaign/CHR_ROMAN_portrait_command.png`
- `assets/sprites/enemies/enemy_roman_idle_down_00.png` through `_01.png`
- `assets/sprites/enemies/enemy_roman_move_down_00.png` through `_03.png`
- `assets/sprites/enemies/enemy_roman_attack_down_00.png` through `_03.png`
- `assets/sprites/enemies/enemy_roman_skill_down_00.png` through `_03.png`
- `assets/sprites/enemies/enemy_roman_down_00.png` through `_01.png`

Dedicated deterministic processor and validator:

- `tools/prepare_roman_enemy_assets.py`

## Original built-in image generation outputs

- Design anchor: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-8abf7766-5fd5-4999-ae83-d1944ed73178.png`
- Command portrait: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-2239bf43-4f72-41a4-ae60-3b0e25ba47c6.png`
- Idle sheet: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-c7f9a606-2f83-46f0-a8e7-fb1802e69067.png`
- Move sheet: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-3d4f847e-0f07-4d88-86c9-f3449556b301.png`
- Attack sheet: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-26df1ae6-ac31-4ae6-ba3a-04c628fcbacd.png`
- Skill sheet: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-475206e2-179f-477b-b554-f62c5eee331a.png`
- Down sheet: `C:\Users\blueh\.codex\generated_images\019f5453-f9e8-72d3-bd75-7aa6a676ac75\exec-926ea91b-35a2-40a1-a828-5daffc6ac31b.png`

## Chroma-key and runtime processing

The six transparent source images were processed with:

```powershell
python C:\Users\blueh\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py `
  --input <generated-chroma.png> `
  --out <source-rgba.png> `
  --auto-key border `
  --soft-matte `
  --transparent-threshold 12 `
  --opaque-threshold 220 `
  --despill
```

`tools/prepare_roman_enemy_assets.py` then splits complete generated cells in reading
order, adds a small transparent safety margin, resizes each complete cell to
`192x192` RGBA, and registers every independently drawn pose to the common combat
origin (`x=96`) and floor line (`y=180`). This final canvas registration prevents
layout jitter; it is not used to manufacture one animation pose from another.

The processor validates:

- exactly 16 runtime frames at `192x192` RGBA
- transparent corners and an alpha range containing both 0 and 255
- no opaque chroma-green pixels in Roman's approved non-green palette
- unique SHA-256 pixel content across every runtime frame
- pairwise normalized RGBA and alpha-silhouette differences within every animation
- translation/scale-normalized comparisons plus mirror and 90-degree rotation variants
  as transform-only rejection checks
- a square high-resolution campaign portrait

## Design prompt

```text
Use case: stylized-concept
Asset type: design anchor for a transparent 2D game boss character in a Korean fantasy dungeon-defense game
Primary request: create Roman, a completely original full-body fantasy adventurer-guild survey captain and supply commander, a weary late-thirties male middle manager who looks exhausted by official paperwork but remains competent and authoritative in combat
Scene/backdrop: perfectly flat solid pure #00ff00 chroma-key background for local background removal
Subject: exactly one character, neutral command-ready stance, facing mostly toward the viewer and slightly downward in a top-down quarter-view game-sprite camera; full body visible. Roman has a mature angular face, visible tired under-eye lines, short tousled ash-brown hair with a subtle gray forelock, and a stern resigned expression. He wears a distinctive slate-navy peaked guild officer cap with a small original brass compass-and-scroll crest, a long structured slate-navy survey-command coat with ochre-gold piping and split tails, parchment-cream high collar, muted wine-red necktie, dark trousers, worn brown knee boots, fingerless gloves, and a broad cross-body supply harness. He carries a large leather report ledger/clipboard with loose parchment tabs and one red wax seal in his left hand, a short steel-and-brass command baton that also reads as a practical melee weapon in his right hand, a boxy field-supply satchel at one hip, and two rolled route maps on his back. No shield, no helmet, no hammer, no firearm.
Style/medium: polished hand-painted 2D chibi fantasy game character art matching a premium tactical RPG sprite; compact adult proportions around 3.5 heads tall, crisp dark outline, detailed painterly surfaces but a bold readable silhouette at about 160 pixels tall
Composition/framing: single centered character, generous even padding, feet, cap, coat tails, baton, ledger, satchel and map rolls fully visible, no cropping
Lighting/mood: restrained neutral game lighting on the character only; tired bureaucratic comedy balanced with credible boss authority
Color palette: slate navy, charcoal, worn brown leather, parchment cream, antique brass, muted wine red; never use bright green or #00ff00 on Roman
Materials/textures: worn wool officer coat, scuffed leather, scratched brass, dog-eared parchment, dull steel
Constraints: one character only; original design; the background must be one perfectly uniform pure #00ff00 color with no shadows, gradients, texture, reflections, floor plane, lighting variation, halo, scenery or dividers; crisp isolated silhouette; no cast shadow; no contact shadow; no particles; no text; no letters or numbers on papers; no logo; no watermark
Avoid: youthful hero face, glamorous noble, smiling pose, engineer helmet, investigator cap shape, oversized weapon, sword, gun, modern office supplies, green clothing, background scene, glow, smoke, extra limbs, cropped equipment
```

## Portrait prompt

```text
Use case: identity-preserve
Input images: Image 1 is Roman's exact generated design anchor.
Asset type: square campaign dialogue portrait
Primary request: paint the same Roman chest-up, holding the report ledger against his
chest with the command baton across the lower foreground; weary narrowed eyes, furrowed
brow, stern resigned middle-manager expression, and tired but disciplined posture.
Scene/backdrop: simple dark desaturated blue-gray painterly vignette with subtle dungeon haze.
Style/medium: polished hand-painted 2D fantasy tactical-RPG dialogue portrait.
Composition/framing: square, cap fully visible, crop around mid-torso.
Constraints: preserve exact identity, apparent age, stubble, gray forelock, cap, crest,
coat, tie, harness, palette, ledger, and baton; one character; no readable writing, logo,
watermark, frame, extra object, bright green, or redesign.
```

## Sequential animation prompt set

All five sheets used the design anchor as an identity reference. The common production
constraints were:

```text
Preserve Roman's exact mature tired face, gray forelock, stubble, peaked guild cap with
brass compass-scroll crest, slate-navy long coat, cream collar, wine tie, harness,
report ledger, command baton, supply satchel, two map rolls, palette, compact proportions,
outline, and painterly rendering from Image 1. Use a consistent top-down quarter-view
facing mostly toward the viewer and slightly downward, with a stable camera, scale, and
ground baseline. This must be true hand-drawn sequential animation art: independently
redraw the body, face, limbs, hands, feet, clothing folds, and equipment for every frame;
never duplicate, translate, scale, rotate, mirror, squash, stretch, or merely warp one
pose. Use one perfectly uniform pure #00ff00 chroma-key field with no shadow, gradient,
floor, glow, particles, scenery, dividers, labels, text, logo, or watermark. Never use
#00ff00 on Roman. Keep all figures fully inside equal square cells with generous padding.
```

Idle, two horizontal cells:

```text
Frame 1: top of the breath, shoulders and chest raised, balanced command-ready weight,
ledger firm at the chest, baton angled down, coat tails and map rolls lightly lifted.
Frame 2: bottom of the breath, shoulders and torso settle into a tired slouch, chin and
eyelids dip, hips shift to the other support leg, ledger and baton lower, coat and satchel settle.
```

Move, 2x2 reading order:

```text
Frame 1: left-foot contact/down with counter-rotated torso and trailing equipment.
Frame 2: passing/up over the left foot, right knee forward, arms and props crossing center.
Frame 3: right-foot contact/down with opposite torso rotation and reversed equipment lag.
Frame 4: opposite passing/up over the right foot, returning naturally toward frame 1.
```

Attack, 2x2 reading order:

```text
Frame 1: wide bent-knee anticipation, weight rearward, baton high, ledger raised as guard.
Frame 2: hard forward step and diagonal baton acceleration with coat and satchel trailing.
Frame 3: deepest low forward impact lunge, baton extended to the ground-target area.
Frame 4: low recovery guard, baton sweeping across the waist and ledger returning to chest.
No slash arc, impact flash, debris, sparks, smoke, glow, or particles.
```

Supply-command skill, 2x2 reading order:

```text
Frame 1: braced ledger check, book opened wide, baton low, focused administrative fatigue.
Frame 2: authorization, open ledger forward and baton tip tapping an abstract route diagram.
Frame 3: command peak, baton raised vertically overhead, mouth delivering the order.
Frame 4: directional deployment step, baton thrust outward and ledger braced across chest.
Pages contain only abstract non-language shapes. No generic magic, aura, particles, crates,
summoned objects, floating papers, or extra characters.
```

Down, two horizontal cells:

```text
Frame 1: asymmetric knee buckle and forward-sideways fall, ledger and baton slipping loose,
cap tilting, satchel and coat tails swinging with the lost balance.
Frame 2: fully collapsed on his side with bent legs, eyes closed, cap askew, ledger and
baton immediately beside his hands, attached satchel and map rolls still present.
Clean non-graphic fantasy defeat: no blood, wound, gore, broken limb, dust, or impact effect.
```
