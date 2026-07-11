# Kingdom Engineer Imagegen Source

Date: 2026-07-12

Generated with the built-in `image_gen` tool and converted from a flat chroma-key background to transparent RGBA with the installed imagegen helper.

Workspace source:

- `assets/source/imagegen/engineer/CHR_ENGINEER_design_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_attack_pose_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_skill_pose_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_idle_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_move_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_attack_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_skill_sheet_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_down_sheet_imagegen.png`

Original generated image path:

- `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-6b005456-b315-4ca3-b060-356014a4b3e3.png`
- idle sheet: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-85433f3a-ea13-4035-9a05-5e0a303e0e31.png`
- move sheet: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-58993aa2-01b8-4959-a24f-e8a79dbc2535.png`
- attack sheet: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-c601a346-962e-4f2c-9585-5aa15c2aa337.png`
- skill sheet: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-717ecc59-200d-4d74-b07b-8a07ad7d298e.png`
- down sheet: `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-25ed7c40-34d1-4bc3-a1c5-b1f555aa881b.png`

Runtime combat sprites:

- `assets/sprites/enemies/enemy_engineer_*.png`
- The five sequential imagegen sheets are split in reading order and resized as complete cells with `tools/prepare_engineer_enemy_assets.py`.
- No runtime animation frame is made by rotating, translating, scaling, mirroring, or warping another frame.
- Required sequence: idle 2, move 4, attack 4, skill 4, down 2.

The attack and facility-disruption skill poses were added after visual review found that transform-only frames did not communicate the actions clearly enough.

Prompt:

```text
Use case: stylized-concept
Asset type: transparent game character sprite for a Korean fantasy dungeon-defense game
Primary request: create one full-body royal kingdom combat engineer enemy, a clever young adult fantasy sapper carrying a compact wooden-and-brass tool satchel, short iron pry bar, folded measuring tool, and a small mechanical disruption device; readable silhouette that clearly differs from a thief, investigator, shield bearer, and knight
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal
Subject: single character only, neutral ready stance, facing mostly toward the viewer and slightly downward as a top-down quarter-view game sprite, entire body visible
Style/medium: polished hand-painted 2D chibi fantasy game sprite, compact proportions, dark brown leather work coat, muted steel helmet with a small gold kingdom badge, brass hardware, burgundy cloth accents, crisp dark outline, detailed but readable at about 160 pixels tall
Composition/framing: centered, generous even padding, no cropping
Lighting/mood: restrained neutral game lighting on the character only
Constraints: background must be one perfectly uniform #00ff00 color with no shadows, gradients, texture, reflections, floor plane, or lighting variation; do not use #00ff00 anywhere in the character; crisp isolated silhouette; no cast shadow; no contact shadow; no extra characters; no text; no logo; no watermark
Avoid: realistic human proportions, oversized weapon, modern explosives, firearms, green clothing, background scenery, glow, smoke, particles
```

Attack pose prompt:

```text
Use case: identity-preserve
Asset type: source pose for a 2D game character attack animation
Input images: Image 1 is the exact royal kingdom engineer character anchor and must define identity, outfit, proportions, equipment, colors, and painted style
Primary request: create the same engineer in one clearly different full-body melee attack key pose, lunging forward and swinging the short iron pry-bar hammer downward with force; the wooden tool case follows the motion; the brass disruption device remains secured in the other hand; readable action silhouette at small sprite size
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal
Subject: exactly one character, full body, same face, helmet badge, dark brown leather coat, burgundy cloth, brass tools, boots, chibi proportions, top-down quarter-view facing mostly toward viewer and slightly downward
Style/medium: preserve the exact polished hand-painted 2D chibi fantasy game style of Image 1
Composition/framing: centered with generous even padding, feet and tool fully visible, no cropping
Lighting/mood: preserve neutral game lighting
Constraints: change only the pose and limb/tool positions; preserve character identity and costume details; background must be one perfectly uniform #00ff00 with no shadow, gradient, texture, floor, reflection, or lighting variation; do not use #00ff00 on the character; no cast shadow; no contact shadow; no motion effects; no extra character; no text; no logo; no watermark
Avoid: redesign, different age, different face, oversized weapon, modern explosives, firearms, scenery, smoke, particles, glow
```

Facility-disruption skill pose prompt:

```text
Use case: identity-preserve
Asset type: source pose for a 2D game character facility-disruption skill animation
Input images: Image 1 is the exact royal kingdom engineer character anchor and must define identity, outfit, proportions, equipment, colors, and painted style
Primary request: create the same engineer in one clearly different full-body skill key pose, crouched low while planting the small wooden-and-brass disruption device onto the ground directly in front of him, one gloved hand pressing the device's top control and the short iron pry-bar held back in the other hand; focused technical action, readable silhouette at small sprite size
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for local background removal
Subject: exactly one character and exactly one attached disruption device, full body, same face, steel helmet and gold badge, dark brown leather coat, burgundy cloth, brass tools, boots, chibi proportions, top-down quarter-view facing mostly toward viewer and slightly downward
Style/medium: preserve the exact polished hand-painted 2D chibi fantasy game style of Image 1
Composition/framing: centered with generous even padding, feet, hand, device and pry-bar fully visible, no cropping
Lighting/mood: preserve neutral game lighting
Constraints: change only the pose and limb/tool positions; preserve character identity and costume details; device remains the same compact brass-and-dark-steel cylinder from Image 1; background must be one perfectly uniform #00ff00 with no shadow, gradient, texture, floor, reflection, or lighting variation; do not use #00ff00 on the character; no cast shadow; no contact shadow; no glow; no motion effects; no extra character; no extra device; no text; no logo; no watermark
Avoid: redesign, different age, different face, standing idle pose, oversized device, modern explosives, firearms, scenery, smoke, sparks, particles
```

## 2026-07-12 Production Sequential Animation Prompt Set

All five sheets used the built-in image generator in identity-preserve mode. The common identity and rendering constraints were:

```text
Preserve the exact same young chibi male face, steel helmet with centered gold kingdom badge and brass ear fittings, black hair, dark brown leather work coat, burgundy scarf/tabard, wooden tool case, short iron pry bar, compact brass-and-dark-steel disruption device, boots, proportions, colors, outline and painted rendering from the character reference. Use a top-down quarter-view facing mostly toward the viewer and slightly downward, with a consistent camera, character scale and ground baseline. This must be true hand-drawn sequential animation art: redraw the body, face, limbs, clothing folds and equipment for every frame; do not duplicate, translate, scale, rotate, mirror, squash or merely warp one pose. Use a perfectly uniform pure #00ff00 chroma-key backdrop with no shadow, gradient, floor, glow, particles, scenery, dividers, labels, logo or watermark. Never use #00ff00 on the character. Keep generous padding and crop nothing.
```

Idle sheet, two equal horizontal cells:

```text
Frame 1: neutral alert stance at the top of a breath, shoulders slightly raised, pry bar ready, device at his side. Frame 2: the bottom of the breath, shoulders and torso settled lower, coat hem and scarf relaxed, hands and tools shifted naturally by breathing.
```

Move sheet, 2x2 reading order:

```text
Frame 1 left-foot contact with torso counter-rotation and equipment lag; frame 2 passing/up with rear foot lifting and arms crossing center; frame 3 right-foot contact/down with the opposite arm swing and reversed coat tails; frame 4 opposite passing/up returning naturally toward frame 1. Redraw legs, feet, hips, torso, shoulders, arms, hands, pry bar, device, tool case, scarf and coat folds in each frame.
```

Attack sheet, 2x2 reading order:

```text
Frame 1 anticipation/wind-up with bent knees, rearward weight and pry bar high; frame 2 acceleration with a forward step and unwinding hips/shoulders; frame 3 deepest impact/follow-through lunge with the pry-bar head at the ground-target area; frame 4 low rebound and recovery toward ready. No slash arc, debris, sparks, impact flash, smoke, glow or particles.
```

Facility-disruption skill sheet, 2x2 reading order:

```text
Frame 1 lowers the device while checking placement; frame 2 deep crouch as device feet touch down and one hand steadies it; frame 3 lowest focused pose pressing the brass top control; frame 4 withdraws the hand and starts rising while the activated device remains on the ground in front. No glow, electricity, sparks, particles, smoke, runes, floor circle or flash.
```

Down sheet, two equal horizontal cells:

```text
Frame 1 stagger/fall with buckling knees, pitching torso, reaching hand, slipping pry bar and swinging tool case; frame 2 fully collapsed on his side with naturally bent legs and loose equipment beside him. Draw a clean non-graphic fantasy defeat with no blood, wounds, gore or broken limbs; do not make it by rotating the standing pose.
```
