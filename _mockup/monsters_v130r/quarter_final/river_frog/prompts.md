# river_frog / 0101a

- image_gen; transparent_background=true
- Image1: reference.png (identity + real map assets)
- Image2: approved_C_camera.png (approved0098 C camera)

## Attempt1

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species river_frog. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the teal green plump river frog, droopy amber eyes, pale cream muzzle/belly, broad green leaf hat with water droplet, brown crossbody pouch with round bottle and folded leaf sprig, both hands holding ragged off-white blank paper. Hat TOP elliptical leaf plane dominant, broad back/shoulders behind hat, short belly. No added weapons.
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: short frog waddle; keep paper, pouch and hat; attack leans/hops down-left holding paper, skill gentle attached water glint.
Same character scale all40 cells. Contact at50% cell x /85% cell y. All body/limbs/props/effects/shadow fully within each cell with wide empty transparent gutters, no overlap. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.
```

## Attempt2 / targeted frame repair
- Image3: generated_attempt_1.png

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species river_frog. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the teal green plump river frog, droopy amber eyes, pale cream muzzle/belly, broad green leaf hat with water droplet, brown crossbody pouch with round bottle and folded leaf sprig, both hands holding ragged off-white blank paper. Hat TOP elliptical leaf plane dominant, broad back/shoulders behind hat, short belly. No added weapons.
OUTPUT TARGETED REPAIR ONLY: exactly 2 columns x 1 rows of full-body isolated animation sprites, 2 total. ALL sprites same body size and exact C camera elevation. Output NATIVE TRANSPARENT RGBA, no backdrop. VERY WIDE genuinely transparent gutters: each character occupies only CENTER60% of cell width and CENTER65% of cell height. At least15% EMPTY transparent padding on EVERY edge of EACH cell. Keep limbs/props/shadow/TINY attached effects entirely inside central60% width/65% height. No floating or detached particles, no long trailing effects, no inter-cell contact. Tiny horizontal elliptical contact shadows only. No grid, panels, text, labels, numbers. Input3 is previous generated sheet: identity/palette/props and same C camera only; DO NOT copy its tight spacing. Render ONLY this species.
Exact reading order, left to right then next row:
1. SW attack contact: short low frog paper shove toward DOWN LEFT, keep paper/hat/pouch; mouth low, no looking up.
2. SW skill strongest: small water glint ATTACHED close to hands, NO floating bubbles, face low on southwest side.
Do not change which way a pose faces. SW=front three-quarter DOWN LEFT, NE=back three-quarter UPPER RIGHT with face HIDDEN. All poses look downward; never raise chin to camera. No scenery, checkerboard or background color. Native transparency is mandatory.
```

## Selection and rejected-frame table

| Attempt | Status | Reason |
|---|---|---|
| 1 | PARTIAL | T/F/H/E/S pass; SW attack10 and skill14 overlap source row boundary; those2 frames rejected |
| 2 | ADOPTED | Two SW replacement poses; attached effects, native alpha, all criteria pass |
