# crumpled_map retry / 0103

Generation model: GPT internal image generation
Generated date: 2026-10-17
Target version: 1.3.0

Native image_gen only; transparent_background=true. Maximum4 calls reached.
Input roles: reference.png identity+real-map; approved_C_camera.png0098 C; approved_0101a_camera.png adopted frog/snail camera.
Calls1-2 use all three camera/identity images; call2 also rejected1 for identity only.
Call3 uses all three plus SW2 design. Call4 uses identity+0098 C+SW2+NE3.

## Attempt1

```text
Use case: stylized-concept. Create a production native-transparent sprite sheet for ONE cute parchment monster crumpled_map, in the painterly dimensional miniature style of the supplied refs.
INPUT 1 reference.png: identity on left (yellowed crumpled parchment, exactly three tiny rust-red THRONE doodles, dotted routes, curled corner arms) and real map buildings on right (camera only). INPUT 2 approved_C_camera.png: user-approved 0098 C elevated southwest miniature camera. INPUT 3 approved_0101a_camera.png: adopted frog and snail elevated-camera battle sprites. These are camera references only, do not add frog/snail or their props.
IMPORTANT NEW BODY CONSTRUCTION: A HALF-UNROLLED LIVING MAP RESTING ON THE FLOOR, WITH ONLY ITS FAR UPPER END BENT UP OBLIQUELY. Think of a small curled carpet/scroll lifting its head, not a standing flat sheet. The lower TWO THIRDS is a deep broad HORIZONTAL parchment map spread over the ground, receding diagonally UPPER RIGHT. Its MAP TOP SURFACE is the dominant visible shape: at least 60 percent of projected body area. The far end curls up into a small sloping head/neck, not a tall vertical panel. Two arms are the rolled paper corners on either side of that little raised end. Entire creature is low, squat, broad and deep, with tiny folded corner feet below the floor-level part. No wooden scroll rods, no book cover, no clothes.
SOUTHWEST GEOMETRY: In columns1-4, the front/lower edge of this broad horizontal scroll points DOWN-LEFT. The small raised face bends toward DOWN-LEFT, one side of head is visible, near ink eye larger, far eye narrower and partly around a fold. Face occupies a SMALL sloping southwest-facing panel; broad forehead, tiny chin, looking down at floor, never at viewer. Broad top map plane extends visibly behind the face toward UPPER RIGHT; three small throne doodles distributed across exposed parchment (one on raised upper fold, two on broad floor-level map), plus tiny trees/routes, no letters/numbers. Keep exactly three throne doodles wherever the visible front map side permits; back poses can occlude them naturally. Expressive ink eyebrows, eyes and mouth consistent with portrait.
CAMERA: orthographic 2:1 dimetric, 42 degrees above ground looking DOWN, same as both supplied approved camera references. Top >= front in EVERY pose, compressed height/foreshortening, little face low toward down-left, staggered depth contact, tiny horizontal soft 2:1 elliptical generated contact shadow. Broad map surface must look like a diamond/perspective trapezoid resting on the floor, NEVER a square rectangle facing viewer. Uphold this construction in walk/attack/skill/hurt.
OUTPUT EXACTLY 8 COLUMNS x 5 ROWS = 40 isolated full-body DISTINCT animation poses on a landscape transparent canvas, evenly spaced. Columns1-4 SW DOWN-LEFT front three-quarter. Columns5-8 NE UP-RIGHT genuine three-quarter BACK: physically rotate this half-unrolled body in space, show blank stained BACK of the raised head fold, face fully hidden including all hurt/recovery poses, broad horizontal map base extends in the opposite depth direction. No mirrored copy, no front face on rear.
For EACH 4-column half, same row order:
Row1: idle relaxed, idle breath, defeated flattened/slumped, defeated low rest.
Row2: four consecutive scooting/paper-foot steps; horizontal map base stays low.
Row3: paper-corner slap windup, short slap forward, contact, recover, toward facing direction; no detached effects.
Row4: inspect own routes, point the wrong way, open curled arms, settle; broad low map base retained.
Row5: hurt startle, recoil, compression, recover; NE face remains hidden.
Every pose has rolled-corner arms, amber/yellowed parchment creases and ink map identity. Same character scale all cells, generous at least 15 percent empty transparent padding around every sprite in its cell, contact centered near lower edge of cell. No sprite overlaps, no particles crossing cells, no labels/grid/panels/scene/floor/checkerboard or text. REAL NATIVE RGBA TRANSPARENCY; only the 40 sprites and tiny contact ellipses.
```

## Attempt2

```text
Use case: stylized-concept. Native transparent 4 columns x 5 rows sprite sheet, 20 full-body poses of crumpled_map, ALL SOUTHWEST. Match the painterly amber parchment monster identity in Image1, camera in approved0098 C Image2 and adopted frog/snail Image3. Image4 is REJECTED attempt1: retain its yellow paper, red throne doodles and rolled paper arms ONLY, correct its remaining frontal face and upright panel.
CRITICAL STRUCTURAL CORRECTION: 75 percent of this monster's paper body is LYING ALMOST HORIZONTAL ON THE FLOOR, a broad low deep diamond-shaped partly unrolled scroll. Only its far upper-right end rises in a LOW CURVED ARCH, like a rolled-up end of carpet bending forward. NOT a standing rectangle with a folded skirt. NO tall face panel. Total body is nearly TWICE as wide as tall, and extends visibly from down-left to upper-right in ground depth. View from ABOVE at 45 degrees as reference C. The visible HORIZONTAL MAP TOP must occupy at least TWO THIRDS of projected body; tiny raised head face at most ONE SIXTH. The raised paper arch has a broad visible TOP rolled fold; small ink face lies BELOW that top edge. Far paper end curves toward bottom left.
DIRECTION: SOUTHWEST is strongly DOWN AND LEFT at equal components; not straight down at camera. In EVERY pose the face looks past the LEFT edge of its floor-map body toward bottom-left. Profile compressed: near ink eye clearly visible on small southwest facing fold; far ink eye much smaller and partly occluded around its fold. Short mouth toward LEFT edge under eyes, small chin, broad visible forehead, no eye contact with viewer. You can see the RIGHT/back side of the raised folded head. Flat map body's long axis recedes UPPER RIGHT, staggered little folded corner feet. Camera is above the creature, not merely rotating a frontal portrait.
Keep yellowed crumpled parchment with ochre folds, dotted routes and tiny trees, EXACTLY THREE rust-red throne doodles on the original paper surface (one tiny on raised end, two on the broad horizontal floor map), curled paper corner arms with little folded fingers, tiny paper corner feet. No book, no rods, no added tools/costume. Same species as input1 but body architecture changed per above. No extra horns, hat, limbs or animal head.
4x5 EXACT GRID, even center spacing and consistent scale with WIDE at least 15 percent EMPTY TRANSPARENT margins on every cell. Paper arms, fingers, map corners, feet and tiny horizontal elliptical 2:1 contact shadow all inside their own cell.
Row1: relaxed idle, breathing idle, defeated folded/slumped, defeated low flat rest.
Row2: four consecutive scooting/paper-foot walk steps, broad map base stays low.
Row3: curled paper-arm slap windup, slap toward bottom-left, slap contact, recover. Clear pose changes confined to each cell.
Row4: look down at own routes, point the wrong way with rolled corner, raise BOTH rolled corner arms, settle.
Row5: hurt startle, recoil, crumple compression, recover, still facing SW.
All20 meet: broad dominant TOP >= front, strong bodily foreshortening, SMALL downward viewed face, generated horizontal contact ellipse, unmistakable SOUTHWEST three-quarter. No symmetrical front faces, no tall upright panel. Real NATIVE RGBA TRANSPARENT background; no floor/background/checkerboard/grid/labels/writing/numbers. Only20 separate sprites, no montage of references.
```

## Attempt3

```text
Use case: stylized-concept. Create a native transparent 4 columns x 5 rows sheet of EXACTLY20 full-body DISTINCT animation poses of crumpled_map, ALL facing NORTHEAST UP-RIGHT seen from genuine REAR three-quarter. This is the back view of Image4, NOT a mirrored image.
REFERENCE ROLES: Image1 is original parchment map identity and actual buildings camera; Image2 approved0098 C camera; Image3 adopted0101a frog/snail CAMERA only; Image4 accepted SOUTHWEST half-unrolled paper monster from attempt2, the exact BODY DESIGN, amber/yellowed palette and painted style to rotate into northeast. Use Image4 as strongest structural reference.
BODY: LOW living half-unrolled parchment scroll, nearly twice as wide as tall. Three quarters of the paper is a broad flat HORIZONTAL map floor-body, only the far end curls up into a small low curved head fold. Two curled paper corner arms and tiny folded paper corner feet. No wooden rods/book/extra tools/costume/animal body. Golden weathered parchment creases, dotted routes/tiny trees and three rust-red throne doodles on the FRONT map surface; naturally occlude doodles if head back covers them.
CRITICAL REAL ROTATION: Rotate the accepted SW model180 degrees IN GROUND SPACE until it faces UPPER RIGHT. The HEAD is now at the NE-facing raised end but the camera sees ONLY the outer BACK of that curved head fold. The little upright BACK-OF-HEAD fold is now on the LOWER LEFT / CAMERA-NEAR side of the broad flat map base. Flat floor-level parchment body projects/recedes toward UPPER RIGHT behind that near raised back fold. Rolled corner arms are seen from behind at the sides. Do NOT keep the SW geometry with head on upper-right and pretend it is rear by erasing eyes. The broad body/arms/feet/depth must rotate. Character looks AWAY FROM VIEWER toward UPPER RIGHT, absolutely NO eyes, eyebrows, mouth, facial marks, face or facial expression anywhere in any of the20 sprites. Back of folded head is plain stained paper, not a face-shaped mask. Upper-right is the direction of scooting/slapping/pointing.
CAMERA match C/approved frog/snail, orthographic2:1 dimetric45degrees DOWN from above, broad horizontal top >= raised back panel; strongly shortened height; big visible TOP of curved head fold and floor-map body. Tiny horizontal soft2:1 elliptical contact shadow under each sprite. Consistent character scale across all cells.
EXACT4columns5rows. Row1 idle relaxed, breathing idle, defeated slumped, defeated flat rest. Row2 four distinct scooting/paper-foot walk steps facing upper-right. Row3 rolled-corner arm slap windup, slap upper-right, contact, recover. Row4 inspect own markings (head stays away), point wrong way with curled arm, BOTH rolled arms spread, settle. Row5 back-view hurt startle, recoil, compressed crumble, recover. Every frame entirely rear-facing, even final hit/recover.
Wide gutters: each sprite and generated shadow completely in its own cell with >=15percent empty transparent padding on EVERY cell edge; no limbs/dust/trails cross neighbors. No detached effect or confetti. Real native transparent RGBA, no colored backdrop, no floor/scene/checkerboard/labels/grid/numbers/text, only20 separate rear-view full-body sprites. Keep low lying body construction and proper NE direction throughout.
```

## Attempt4

```text
Use case: stylized-concept. REPAIR FOUR animation poses only of crumpled_map, low HALF-UNROLLED FLOOR MAP body, native transparent RGBA, EXACTLY2 columns x2rows, four full-body isolated sprite poses. Painterly miniature battle art. Input1 approved original identity and real buildings camera. Input2 approved0098 C elevated camera. Input3 accepted SW floor-scroll sheet for EXACT identity/body/palette. Input4 accepted NE rear sheet for rear silhouette. Keep same yellowed amber parchment, weathered creases, dotted routes/trees, EXACTLYthree tiny rust-red throne doodles on FRONT map side where visible, two rolled paper-corner arms, tiny folded corner feet. No rods/book/tools/clothes/animals.
All4 camera42-45deg DOWN, orthographic2:1 dimetric, broad HORIZONTAL FLOOR MAP TOP dominates >=two-thirds area; tiny low curved raised head end, strongly foreshortened. No upright paper plate. Body nearly twice as wide as tall. Each pose tiny horizontal soft2:1 contact ellipse. Very WIDE transparent gutters: each sprite/effect/shadow fully inside CENTER60percent of own cell, minimum20percent empty transparent edges. NO detached particles/effects.
Read EXACT left-to-right then next row:
1 TOP LEFT: SW skill strongest, BOTH rolled paper corner arms spread/raised, BUT TINY FACE unmistakeably looks DOWN-LEFT, three-quarter not front. Floor-map long axis extends down-left from small raised head at upper-right; near ink eye larger, far eye tiny/partly around fold. Small mouth tilted down-left, tiny chin, broad top fold visible above face. Do not look at camera; do not enlarge face into flat upright panel. Three tiny throne doodles on map, two on the broad horizontal base.
2 TOP RIGHT: NE REAR skill inspect-own-markings pose, leaning slightly down, character still FACING UP-RIGHT. Camera sees ONLY plain stained BACK of small raised head, located at LOWER LEFT camera-near end, broad floor-map body extends/recedes toward UPPER RIGHT, arms seen from behind, no face/eyes/eyebrows/mouth. One rolled hand gestures toward UPPER RIGHT over map, keep NE geometry.
3 BOTTOM LEFT: NE REAR hurt startle, slightly lifted rolled arms close to body, raised BACK-OF-HEAD at LOWER LEFT, broad low floor-map body extends UPPER RIGHT. NO facial features, no turn toward camera, no floating marks.
4 BOTTOM RIGHT: NE REAR hurt recoil, body compressed/leaned away toward UPPER RIGHT, rolled arms tucked, raised plain back-of-head fold LOWER LEFT and broad low floor-map body UPPER RIGHT. Face COMPLETELY HIDDEN; no eyes/face-shaped marks. Do not swivel into southwest geometry.
This is NOT four repeated idle sprites: use the specified distinct actions while preserving the camera and true direction. Match the source design but correct the ambiguous facing of those four poses. Real native transparent background only; no floor/grid/panels/text/labels/numbers/checkerboard/reference montage. Exactly FOUR isolated sprites with small generated contact shadows.
```

## Selection

[
  {
    "attempt": 1,
    "status": "REJECTED",
    "selected_frames": 0,
    "T": false,
    "F": true,
    "H": false,
    "E": true,
    "S": false,
    "reason": "Half-unrolled lower base exists, but upright front/near-frontal face remains too dominant."
  },
  {
    "attempt": 2,
    "status": "PARTIAL_ADOPTED",
    "selected_frames": 19,
    "T": true,
    "F": true,
    "H": true,
    "E": true,
    "S": true,
    "excluded": "SW skill14 face too frontal; replaced by4."
  },
  {
    "attempt": 3,
    "status": "PARTIAL_ADOPTED",
    "selected_frames": 17,
    "T": true,
    "F": true,
    "H": "rear face hidden",
    "E": true,
    "S": "NE rear check",
    "excluded": "NE skill12/hurt0/hurt1 ambiguous direction; replaced by4."
  },
  {
    "attempt": 4,
    "status": "ADOPTED",
    "selected_frames": 4,
    "T": true,
    "F": true,
    "H": true,
    "E": true,
    "S": true,
    "reason": "SW skill14 and NE skill12/hurt0/hurt1 direction replacements."
  }
]
