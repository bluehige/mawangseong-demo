# mimic_porter / 0101d

- GPT internal image_gen; transparent_background=true.
- Image1: reference.png (approved identity + real map pieces).
- Image2: ../moon_tracker/approved_C_camera_uniform.png (approved 0098 C, uniform scaling).

## Attempt 1

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species mimic_porter.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the squat dark wooden treasure chest mimic with thick antique gold/brass bands, round rivets, curved hinged lid, triangular ivory teeth, red tongue INSIDE mouth, front lock plate/keyhole and ragged red hanging BANNER with the approved gold upward-arrow rune, two brown short jointed wooden arms and tiny brown feet. NO added eyes; the mouth itself is the face, as in the approved reference. Preserve front red banner and gold rune on every visible front pose, not a replacement tongue. Same chest and golden corner details. Lid TOP wood area dominant; foreshortened short box walls. No backpack, coins or hats added.
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: short waddling steps; lid bite attack and short arm shove, skill protective bracing/tiny attached gold glint, no detached treasure.
Same character scale all40 cells. Contact at50% cell x /85% cell y. Each sprite occupies ONLY CENTRAL60% of its cell width and CENTRAL65% height. At least15% EMPTY transparent padding on every edge of EACH cell, ALL body/limbs/props/effects/shadow fully within each cell. No inter-cell contact, no detached particles, all effects tightly attached to hands/weapon. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.
```

## Final selection and rejection table

| Attempt | Status | Adopted poses | Reason |
|---:|---|---:|---|
| 1 | ADOPTED | 40 | T/F/H/E/S pass; lid top, red banner, lock, teeth, wooden limbs retained. |
