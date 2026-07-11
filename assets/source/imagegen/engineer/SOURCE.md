# Kingdom Engineer Imagegen Source

Date: 2026-07-12

Generated with the built-in `image_gen` tool and converted from a flat chroma-key background to transparent RGBA with the installed imagegen helper.

Workspace source:

- `assets/source/imagegen/engineer/CHR_ENGINEER_design_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_attack_pose_imagegen.png`
- `assets/source/imagegen/engineer/CHR_ENGINEER_skill_pose_imagegen.png`

Original generated image path:

- `C:\Users\blueh\.codex\generated_images\019f5307-3216-7452-8a75-3ff8456540ce\exec-6b005456-b315-4ca3-b060-356014a4b3e3.png`

Runtime combat sprites:

- `assets/sprites/enemies/enemy_engineer_*.png`
- Derived only by crop, scale, rotation, and offset from the imagegen source with `tools/prepare_engineer_enemy_assets.py`.

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
