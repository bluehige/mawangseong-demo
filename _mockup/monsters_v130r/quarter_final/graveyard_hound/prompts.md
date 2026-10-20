# graveyard_hound / 0101d

## Attempt 3 / rear collar correction

- Attempt2 rejected: frontal bone pendant incorrectly moved onto back.
- Same Image1/Image2/Image3 as attempt2.

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species graveyard_hound.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small charcoal/black fluffy graveyard puppy with pointed purple-inner ears, bright round icy blue eyes, dark muzzle, white fang tips, cream bone-bead collar with LARGE central bone pendant. Thin upward curled dark tail holds a small BLACK metal lantern with cyan glass light; tiny cyan ghost flame on top of lantern. Lantern MUST remain attached to curled tail, not a replacement tail flame, not a staff. Big head TOP and broad back dominate, muzzle low down-left, body and legs short. Preserve collar, lantern and tail in every appropriate pose; no clothing.
OUTPUT TARGETED REPAIR ONLY: ONE single whole-body sprite, NORTHEAST HIT-REACTION RECOVERY. The puppy faces UP RIGHT showing back of skull/ears, back/haunches and rear paws. NO visible frontal face, eyes, nose or mouth. Do NOT look back at viewer. Input3 old sheet is identity/scale/camera reference, but its bottom-right frontal puppy is WRONG: replace it with genuine rear view. Previous repair also put the large front pendant on the BACK incorrectly. Correct this, do not move frontal chest accessories to rear. Tail curls upward supporting black metal blue glass lantern, cyan flame on lantern. Cream bone-BEAD collar wraps around back of neck. IMPORTANT large central bone PENDANT belongs on FRONT chest and is HIDDEN from rear. Show ONLY small bead backs at rear neck, NO large bone pendant on back. Four paws rest low on floor in recovering crouch, not a flying leap. Same DOWN42degree camera as C, broad visible head/back TOP, short legs. Tiny horizontal elliptical contact shadow. Sprite occupies CENTRAL55% of square canvas with generous empty transparent padding, all lantern/flame/feet within bounds. Native transparent RGBA; no particles/aura/glow rings/scenery/text/grid. Only ONE sprite.
```

## Attempt 2 / NE hurt recovery repair

- Image3: attempt_1.png.

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species graveyard_hound.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small charcoal/black fluffy graveyard puppy with pointed purple-inner ears, bright round icy blue eyes, dark muzzle, white fang tips, cream bone-bead collar with LARGE central bone pendant. Thin upward curled dark tail holds a small BLACK metal lantern with cyan glass light; tiny cyan ghost flame on top of lantern. Lantern MUST remain attached to curled tail, not a replacement tail flame, not a staff. Big head TOP and broad back dominate, muzzle low down-left, body and legs short. Preserve collar, lantern and tail in every appropriate pose; no clothing.
OUTPUT TARGETED REPAIR ONLY: ONE single whole-body sprite, NORTHEAST HIT-REACTION RECOVERY. The puppy faces UP RIGHT showing back of skull/ears, back/haunches and rear paws. NO visible frontal face, eyes, nose or mouth. Do NOT look back at viewer. Input3 old sheet is identity/scale/camera reference, but its bottom-right frontal puppy is WRONG: replace it with genuine rear view. Tail curls upward supporting black metal blue glass lantern, cyan flame on lantern. Cream bone collar wraps around back of neck. Same DOWN42degree camera as C, broad visible head/back TOP, short legs. Tiny horizontal elliptical contact shadow. Sprite occupies CENTRAL55% of square canvas with generous empty transparent padding, all lantern/flame/feet within bounds. Native transparent RGBA; no particles/aura/glow rings/scenery/text/grid. Only ONE sprite.
```

- GPT internal image_gen; transparent_background=true.
- Image1: reference.png (approved identity + real map pieces).
- Image2: ../moon_tracker/approved_C_camera_uniform.png (approved 0098 C, uniform scaling).

## Attempt 1

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species graveyard_hound.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small charcoal/black fluffy graveyard puppy with pointed purple-inner ears, bright round icy blue eyes, dark muzzle, white fang tips, cream bone-bead collar with LARGE central bone pendant. Thin upward curled dark tail holds a small BLACK metal lantern with cyan glass light; tiny cyan ghost flame on top of lantern. Lantern MUST remain attached to curled tail, not a replacement tail flame, not a staff. Big head TOP and broad back dominate, muzzle low down-left, body and legs short. Preserve collar, lantern and tail in every appropriate pose; no clothing.
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: four short puppy gait phases; lunge/bark/bite down-left SW / up-right NE; compact cyan scent/ghost glint attached to muzzle/tail, no floating detached wisps.
Same character scale all40 cells. Contact at50% cell x /85% cell y. Each sprite occupies ONLY CENTRAL60% of its cell width and CENTRAL65% height. At least15% EMPTY transparent padding on every edge of EACH cell, ALL body/limbs/props/effects/shadow fully within each cell. No inter-cell contact, no detached particles, all effects tightly attached to hands/weapon. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.
```

## Final selection and rejection table

| Attempt | Status | Adopted poses | Reason |
|---:|---|---:|---|
| 1 | PARTIAL | 39 | NE hurt-recover returned to front; that one frame rejected. |
| 2 | REJECTED | 0 | Rear camera correct but large front bone pendant wrongly put on back. |
| 3 | ADOPTED | 1 | Genuine NE rear crouch; only small bone beads on rear neck, front pendant hidden; tail lantern kept. |
