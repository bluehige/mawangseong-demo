# ghost_housemaid / 0101d

## Attempt 2 / targeted repair

- Image3: attempt_1.png. Replace SW skill gather and NE hurt recover only.

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species ghost_housemaid.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the cute lavender translucent ghost housemaid, bobbed lavender hair with wispy curls and tapered floating ghost tail, TWO small silver rectangular hair clips on front fringe, white ruffled maid headband with large black side BOW and small GOLD center stud, dark violet dress and white bib/apron, dark bow necktie with gold stud, little purple eyes and lavender cheeks, small gold key ring at waist. Hold existing brown-handled straw broom; no new weapons. Broad crown and maid cap TOP; face small low down-left, short dress/tail body.
OUTPUT TARGETED REPAIR ONLY: exactly TWO columns by ONE row, 2 isolated whole-body poses. Input Image3 is previous generated sheet, preserve its correct elevated camera and identity but fix spacing and facing.
LEFT pose = SOUTHWEST skill gather, looking DOWN LEFT three-quarter FRONT: broom held close across apron, small lavender glint ATTACHED to broom-hand. NO spiral ring, NO outer aura, NO streaks, NO particles. Keep headband, TWO fringe clips, black side bow/gold stud, apron, waist keys and ghost tail.
RIGHT pose = NORTHEAST hit recovery, looking UP RIGHT three-quarter BACK: show back of head and maid cap, back of dress and trailing tail, broom mostly seen from behind, NO visible frontal eyes/nose/mouth. Same camera looking DOWN42deg. Never front facing for NE.
Extremely wide native transparent gutters, each character fits CENTRAL55% of cell width and CENTRAL65% height, 20% blank padding. Tiny generated horizontal elliptical contact shadow. Both sprites same body size, no scene/panels/grid/text/painted checkerboard/background. No extra poses. Native TRANSPARENT RGBA. Only these2 poses.
```

- GPT internal image_gen; transparent_background=true.
- Image1: reference.png (approved identity + real map pieces).
- Image2: ../moon_tracker/approved_C_camera_uniform.png (approved0098 C).

## Attempt 1

```text
Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species ghost_housemaid.
Input Image1: approved character portrait and three old poses on LEFT are IDENTITY and paint style only; actual game bed, chest, watchtower and bridge at BOTTOM are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
Identity: Exactly the cute lavender translucent ghost housemaid, bobbed lavender hair with wispy curls and tapered floating ghost tail, TWO small silver rectangular hair clips on front fringe, white ruffled maid headband with large black side BOW and small GOLD center stud, dark violet dress and white bib/apron, dark bow necktie with gold stud, little purple eyes and lavender cheeks, small gold key ring at waist. Hold existing brown-handled straw broom; no new weapons. Broad crown and maid cap TOP; face small low down-left, short dress/tail body.
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: ghost glide close to floor; broom sweep down-left SW / up-right NE; compact lavender attached ghost shimmer for skill. Keep broom inside cell, no long trails.
Same character scale all40 cells. Contact at50% cell x /85% cell y. Each sprite occupies ONLY CENTRAL60% of its cell width and CENTRAL65% height. At least15% EMPTY transparent padding on every edge of EACH cell, ALL body/limbs/props/effects/shadow fully within each cell. No inter-cell contact, no detached particles, all effects tightly attached to hands/weapon. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.
```

## Final selection and rejection table

| Attempt | Status | Adopted poses | Reason |
|---:|---|---:|---|
| 1 | PARTIAL | 38 | NE hurt-recover returned to front; SW skill-gather effect spacing risk. Those two frames rejected. |
| 2 | ADOPTED | 2 | SW compact gather and genuine NE rear hurt-recover replacement. Native alpha and T/F/H/E/S pass. |
