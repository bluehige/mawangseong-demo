# glue_snail / 0101a

- image_gen; transparent_background=true
- Image1: reference.png (identity + real map assets)
- Image2: approved_C_camera.png (approved0098 C camera)

## Attempt1

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species glue_snail. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small round lilac snail with droopy patient face, TWO long stalk eyes AND little facial eyes. Cozy rounded spiral HOUSE shell, warm window, little copper-roof chimney, moss and small flowers. Preserve all shell details and flowers; show broad TOP of shell and roof receding upper-right, compressed face low on southwest side. Not a plain spiral shell.
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: four slow crawl stretch/contractions; attack short attached sticky slime spit; skill attached glossy trail close to base; house travels with body.
Same character scale all40 cells. Contact at50% cell x /85% cell y. All body/limbs/props/effects/shadow fully within each cell with wide empty transparent gutters, no overlap. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.
```

## Attempt2 / ne

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species glue_snail. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small round lilac snail with droopy patient face, TWO long stalk eyes AND little facial eyes. Cozy rounded spiral HOUSE shell, warm window, little copper-roof chimney, moss and small flowers. Preserve all shell details and flowers; show broad TOP of shell and roof receding upper-right, compressed face low on southwest side. Not a plain spiral shell.
OUTPUT REPAIR: ONLY NORTHEAST direction. Portrait canvas exactly FOUR columns by FIVE rows =20 different complete sprites. ALL20 poses face SCREEN UPPER RIGHT in genuine three-quarter REAR view. Camera stays42degrees DOWN, see broad back/crown/shell/hood/paper fold tops. FACE IS HIDDEN IN EVERY CELL INCLUDING LAST COLUMN. Never reset to front for recover, defeated or movement. No frontal eyes/face visible except tiny far-side profile at most. Do not copy a FRONT sprite into final column! No horizontal mirroring. Keep same identity and physical accessory side. Leftmost column and rightmost column BOTH northeast rear. Row1 rear idle, rear breath, rear defeated slump, rear defeated rest. Row2 four consecutive rear moving poses. Row3 rear windup, rear strike aimed upper-right, rear contact, rear recover. Row4 rear skill gather, prepare, strongest, settle. Row5 rear hit startle, recoil, compress, recover. Keep same compact scale and elevation all20. Entire sprites contained in cells with WIDE transparent gutters; no touching neighbours. Generated small horizontal elliptical contact shadows. Native transparent RGBA only. No text/grid/scenery/checkerboard. If a shell creature: the eye stalks emerge on FAR UPPER-RIGHT SIDE of the shell and point AWAY; no face on screen lower-left. If troll, show mossy back in every cell; no frontal face in final hit recover. Image1 is identity+real map angles, Image2 is approvedC CAMERA reference. Do not render other species.
```

## Attempt3 / targeted frame repair
- Image3: generated_attempt_1.png

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species glue_snail. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the small round lilac snail with droopy patient face, TWO long stalk eyes AND little facial eyes. Cozy rounded spiral HOUSE shell, warm window, little copper-roof chimney, moss and small flowers. Preserve all shell details and flowers; show broad TOP of shell and roof receding upper-right, compressed face low on southwest side. Not a plain spiral shell.
OUTPUT TARGETED REPAIR ONLY: exactly 3 columns x 2 rows of full-body isolated animation sprites, 6 total. ALL sprites same body size and exact C camera elevation. Output NATIVE TRANSPARENT RGBA, no backdrop. VERY WIDE genuinely transparent gutters: each character occupies only CENTER60% of cell width and CENTER65% of cell height. At least15% EMPTY transparent padding on EVERY edge of EACH cell. Keep limbs/props/shadow/TINY attached effects entirely inside central60% width/65% height. No floating or detached particles, no long trailing effects, no inter-cell contact. Tiny horizontal elliptical contact shadows only. No grid, panels, text, labels, numbers. Input3 is previous generated sheet: identity/palette/props and same C camera only; DO NOT copy its tight spacing. Render ONLY this species.
Exact reading order, left to right then next row:
1. SW attack windup.
2. SW attack strike short sticky spit ATTACHED close to mouth DOWN LEFT.
3. SW attack contact short sticky spit ATTACHED within silhouette near DOWN LEFT base.
4. SW skill gather tiny glossy slime at base.
5. SW skill prepare tiny glossy slime at base.
6. SW skill strongest glossy slime hugging base; no distant particles.
Do not change which way a pose faces. SW=front three-quarter DOWN LEFT, NE=back three-quarter UPPER RIGHT with face HIDDEN. All poses look downward; never raise chin to camera. No scenery, checkerboard or background color. Native transparency is mandatory.
```

## Selection and rejected-frame table

| Attempt | Status | Reason |
|---|---|---|
| 1 | PARTIAL | SW camera criteria pass; some NE frames turn frontal; six SW frames overlap adjacent body/effects |
| 2 | ADOPTED_NE | 20 genuine NE rear poses; native alpha; selected all NE |
| 3 | ADOPTED_SW_PATCH | Six SW attack/skill poses with ample margins; all criteria pass |
