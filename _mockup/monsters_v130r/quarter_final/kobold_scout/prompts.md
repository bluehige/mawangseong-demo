# 0101c kobold_scout / 로로

Generation model: GPT internal image generation
Generated date: 2026-10-17
Target version: 1.3.0

0098 prompts.md 구조 재사용. 참조 역할·정확한 영문 호출문·시도별 판단을 보존한다.
입력: reference.png (외형: 기존 초상화/전투, 각도: 실제 지도 4조각 + 승인된 0098 후보 C 3종).
도구: image_gen; transparent_background=true; referenced_image_paths=[reference.png].
종별 최대4회 준수. 원본은 유지하고 후보의 그림을 코드로 수정하지 않는다.

| 시도 | T/F/H/E/S | 채택 | 판단 |
|---:|---|---|---|
| 1 | O/O/O/O/O | 아니오 | 각도 충족, 외형 미충족: 참조에 없는 망토 해골 무늬. |
| 2 | O/O/O/O/O | 아니오 | 각도 충족, 외형/포즈 미충족: 일부 북동 랜턴 중복·쓰러짐 자리 서 있음. |
| 3 | O/O/O/O/O | 아니오 | 각도·소품 충족, 원본 쓰러짐과 다음 행 이동의 사각 경계가 겹침. |
| 4 | O/O/O/O/O | 예 | 최종 채택. 각도5항목 충족; 기술 검증은 validation_0101c.json 참조. |

## Attempt 1

```text
Use case: stylized-concept. Production combat miniature animation sprite sheet, native transparent RGBA. Reference image supplied: LEFT portrait and old combat figure are IDENTITY ONLY; TOP RIGHT contains the three user-approved 0098 candidate C characters for CAMERA ANGLE ONLY; BOTTOM four real map pieces are CAMERA references. Do not copy frog/troll identity or old eye-level camera.
CRITICAL CAMERA, identical to 0098 C: orthographic 2:1 dimetric view looking DOWN 42 degrees above horizontal, strong crown/shoulder/back TOP surfaces AT LEAST as extensive as visible front. Foreshortened short torso/lower body, face small LOW on front, viewed from ABOVE, never looking up at viewer. Southwest front three-quarter: entire head/body turned 45 degrees toward screen LOWER LEFT, near eye larger, far eye compressed by half, nose points diagonally down-left, shoulders and feet stagger diagonally. Broad crown and upper back, tiny chin. Ground contact soft horizontal 2:1 elliptical shadow generated as part of figure. No long cast shadow.
LAYOUT: wide 3072x1920 transparent canvas, EXACTLY 8 columns x 5 rows, 40 distinct separate complete figures in equal cells. All sprites same camera and scale. Each sprite entirely contained with at least 12% empty transparent margins on all sides, all limbs and props included, no touching neighbors. Left FOUR columns SW front view; right FOUR columns NE up-right BACK view, clear back of head and body, face hidden except tiny possible far-side profile. Never front-facing NE sprites. Reference props remain in same anatomical hands; actually draw reverse views, never flip front sprites.
Each half: ROW1 idle relaxed; idle breathing; defeat kneel; defeat rest. ROW2 move step1,2,3,4. ROW3 attack windup,strike,contact,recover. ROW4 skill gather,prepare,release,settle. ROW5 hit startle,recoil,compress,recover. Exactly four poses per row per facing. Attack axes follow respective facing. Distinct consecutive animation, no duplicated poses. Contact at 50% cell x,85% cell y.
Style: preserve approved softly shaded detailed dimensional chibi game painting, readable crisp edges and original palette/accessories. Only figure and compact generated contact shadow. Genuine native alpha, no painted checkerboard, background, scenery, floor, tile, labels, letters, borders or detached VFX. Do not draw reference montage.
IDENTITY: Exactly Rolo: small olive-green reptilian kobold, narrow snout and amber eyes, tan/brown head crest/spines, large pointed ears, long green tail, green hood/scarf and brown leather scout clothing, belt/pouches and brown boots, original slender staff with glowing amber lantern at its top and original rolled equipment. Preserve portrait and old combat design, no bow or new weapon. Broad crest/crown and shoulders seen from above, lowered narrow snout toward SW, diagonal feet. Staff close to body, lantern never cropped.
Extra strict: the lantern and crest do not permit frontal posing. Face is a SIDE-dominant down-left reptilian muzzle with one compressed far eye. Broad crown, upper back and shoulder tops dominate.
```

Original: `C:\Users\blueh\.codex\generated_images\01a1456c-90b2-7e63-800b-8f5f1471372f\exec-b400d4f2-5993-4c7d-bafb-7613dadd3de0.png`
Saved: `_mockup/monsters_v130r/quarter_final/kobold_scout/attempt_1.png`
Native alpha extrema: [0, 255]

## Attempt 2

```text
Use case: stylized-concept. Production combat miniature animation sprite sheet, native transparent RGBA. Reference image supplied: LEFT portrait and old combat figure are IDENTITY ONLY; TOP RIGHT contains the three user-approved 0098 candidate C characters for CAMERA ANGLE ONLY; BOTTOM four real map pieces are CAMERA references. Do not copy frog/troll identity or old eye-level camera.
CRITICAL CAMERA, identical to 0098 C: orthographic 2:1 dimetric view looking DOWN 42 degrees above horizontal, strong crown/shoulder/back TOP surfaces AT LEAST as extensive as visible front. Foreshortened short torso/lower body, face small LOW on front, viewed from ABOVE, never looking up at viewer. Southwest front three-quarter: entire head/body turned 45 degrees toward screen LOWER LEFT, near eye larger, far eye compressed by half, nose points diagonally down-left, shoulders and feet stagger diagonally. Broad crown and upper back, tiny chin. Ground contact soft horizontal 2:1 elliptical shadow generated as part of figure. No long cast shadow.
LAYOUT: wide 3072x1920 transparent canvas, EXACTLY 8 columns x 5 rows, 40 distinct separate complete figures in equal cells. All sprites same camera and scale. Each sprite entirely contained with at least 12% empty transparent margins on all sides, all limbs and props included, no touching neighbors. Left FOUR columns SW front view; right FOUR columns NE up-right BACK view, clear back of head and body, face hidden except tiny possible far-side profile. Never front-facing NE sprites. Reference props remain in same anatomical hands; actually draw reverse views, never flip front sprites.
Each half: ROW1 idle relaxed; idle breathing; defeat kneel; defeat rest. ROW2 move step1,2,3,4. ROW3 attack windup,strike,contact,recover. ROW4 skill gather,prepare,release,settle. ROW5 hit startle,recoil,compress,recover. Exactly four poses per row per facing. Attack axes follow respective facing. Distinct consecutive animation, no duplicated poses. Contact at 50% cell x,85% cell y.
Style: preserve approved softly shaded detailed dimensional chibi game painting, readable crisp edges and original palette/accessories. Only figure and compact generated contact shadow. Genuine native alpha, no painted checkerboard, background, scenery, floor, tile, labels, letters, borders or detached VFX. Do not draw reference montage.
IDENTITY: Exactly Rolo: small olive-green reptilian kobold, narrow snout and amber eyes, tan/brown head crest/spines, large pointed ears, long green tail, green hood/scarf and brown leather scout clothing, belt/pouches and brown boots, original slender staff with glowing amber lantern at its top and original rolled equipment. Preserve portrait and old combat design, no bow or new weapon. Broad crest/crown and shoulders seen from above, lowered narrow snout toward SW, diagonal feet. Staff close to body, lantern never cropped.
RETRY 2 -- IDENTITY CORRECTION MANDATORY. Previous generation invented a skull symbol on the back cloak, REJECTED. The green scarf/cape is PLAIN olive green cloth with ordinary worn edge: ABSOLUTELY NO SKULL, NO BONES, NO CROSS, NO LOGO, NO EMBLEMS, NO DECORATIVE PATTERNS on the cape/back or anywhere. Preserve original existing roll and pouches, staff lantern and head crest. Strong down-left reptilian muzzle, near eye dominant and far eye tiny, broad TOP crest/crown and upper back exceed frontal face. Orthographic elevated 42 degrees matching approved C.
```

Original: `C:\Users\blueh\.codex\generated_images\01a1456c-90b2-7e63-800b-8f5f1471372f\exec-c24892d9-0969-4758-9e2b-a39a19c311ad.png`
Saved: `_mockup/monsters_v130r/quarter_final/kobold_scout/attempt_2.png`
Native alpha extrema: [0, 254]

## Attempt 3

```text
Use case: stylized-concept. Production combat miniature animation sprite sheet, native transparent RGBA. Reference image supplied: LEFT portrait and old combat figure are IDENTITY ONLY; TOP RIGHT contains the three user-approved 0098 candidate C characters for CAMERA ANGLE ONLY; BOTTOM four real map pieces are CAMERA references. Do not copy frog/troll identity or old eye-level camera.
CRITICAL CAMERA, identical to 0098 C: orthographic 2:1 dimetric view looking DOWN 42 degrees above horizontal, strong crown/shoulder/back TOP surfaces AT LEAST as extensive as visible front. Foreshortened short torso/lower body, face small LOW on front, viewed from ABOVE, never looking up at viewer. Southwest front three-quarter: entire head/body turned 45 degrees toward screen LOWER LEFT, near eye larger, far eye compressed by half, nose points diagonally down-left, shoulders and feet stagger diagonally. Broad crown and upper back, tiny chin. Ground contact soft horizontal 2:1 elliptical shadow generated as part of figure. No long cast shadow.
LAYOUT: wide 3072x1920 transparent canvas, EXACTLY 8 columns x 5 rows, 40 distinct separate complete figures in equal cells. All sprites same camera and scale. Each sprite entirely contained with at least 12% empty transparent margins on all sides, all limbs and props included, no touching neighbors. Left FOUR columns SW front view; right FOUR columns NE up-right BACK view, clear back of head and body, face hidden except tiny possible far-side profile. Never front-facing NE sprites. Reference props remain in same anatomical hands; actually draw reverse views, never flip front sprites.
Each half: ROW1 idle relaxed; idle breathing; defeat kneel; defeat rest. ROW2 move step1,2,3,4. ROW3 attack windup,strike,contact,recover. ROW4 skill gather,prepare,release,settle. ROW5 hit startle,recoil,compress,recover. Exactly four poses per row per facing. Attack axes follow respective facing. Distinct consecutive animation, no duplicated poses. Contact at 50% cell x,85% cell y.
Style: preserve approved softly shaded detailed dimensional chibi game painting, readable crisp edges and original palette/accessories. Only figure and compact generated contact shadow. Genuine native alpha, no painted checkerboard, background, scenery, floor, tile, labels, letters, borders or detached VFX. Do not draw reference montage.
IDENTITY: Exactly Rolo: small olive-green reptilian kobold, narrow snout and amber eyes, tan/brown head crest/spines, large pointed ears, long green tail, green hood/scarf and brown leather scout clothing, belt/pouches and brown boots, original slender staff with glowing amber lantern at its top and original rolled equipment. Preserve portrait and old combat design, no bow or new weapon. Broad crest/crown and shoulders seen from above, lowered narrow snout toward SW, diagonal feet. Staff close to body, lantern never cropped.
RETRY 3: SINGLE LANTERN STAFF ONLY IN EVERY SPRITE, including NE. No duplicate torch, lantern or staff behind head. The rolled item on back is a SMALL CLOSED CREAM SCROLL with NO flame, NOT a second lantern. PLAIN olive green cloak, no emblem/skull/logos. Copy original combat identity precisely. TWO IDLES in first two columns of EACH half, THIRD is clearly DEFEATED KNEELING WITH HEAD LOWERED, FOURTH is clearly DEFEATED LYING FLAT ON GROUND WITH HEAD LOWERED. Specifically overall row1 col7 = NE kneeling defeat, NOT standing. Row1 col8 = NE prone defeat. NE sprites face up-right with backs visible. Left-half muzzle strongly down-left profile under broad crown/crest, as approved C camera. Preserve ONLY ONE staff and ONE amber lantern in ALL 40 figures.
```

Original: `C:\Users\blueh\.codex\generated_images\01a1456c-90b2-7e63-800b-8f5f1471372f\exec-1eb558ad-dd36-4c6d-9e8d-7490eec44646.png`
Saved: `_mockup/monsters_v130r/quarter_final/kobold_scout/attempt_3.png`
Native alpha extrema: [0, 255]

## Attempt 4

```text
Use case: stylized-concept. Production combat miniature animation sprite sheet, native transparent RGBA. Reference image supplied: LEFT portrait and old combat figure are IDENTITY ONLY; TOP RIGHT contains the three user-approved 0098 candidate C characters for CAMERA ANGLE ONLY; BOTTOM four real map pieces are CAMERA references. Do not copy frog/troll identity or old eye-level camera.
CRITICAL CAMERA, identical to 0098 C: orthographic 2:1 dimetric view looking DOWN 42 degrees above horizontal, strong crown/shoulder/back TOP surfaces AT LEAST as extensive as visible front. Foreshortened short torso/lower body, face small LOW on front, viewed from ABOVE, never looking up at viewer. Southwest front three-quarter: entire head/body turned 45 degrees toward screen LOWER LEFT, near eye larger, far eye compressed by half, nose points diagonally down-left, shoulders and feet stagger diagonally. Broad crown and upper back, tiny chin. Ground contact soft horizontal 2:1 elliptical shadow generated as part of figure. No long cast shadow.
LAYOUT: wide 3072x1920 transparent canvas, EXACTLY 8 columns x 5 rows, 40 distinct separate complete figures in equal cells. All sprites same camera and scale. Each sprite entirely contained with at least 12% empty transparent margins on all sides, all limbs and props included, no touching neighbors. Left FOUR columns SW front view; right FOUR columns NE up-right BACK view, clear back of head and body, face hidden except tiny possible far-side profile. Never front-facing NE sprites. Reference props remain in same anatomical hands; actually draw reverse views, never flip front sprites.
Each half: ROW1 idle relaxed; idle breathing; defeat kneel; defeat rest. ROW2 move step1,2,3,4. ROW3 attack windup,strike,contact,recover. ROW4 skill gather,prepare,release,settle. ROW5 hit startle,recoil,compress,recover. Exactly four poses per row per facing. Attack axes follow respective facing. Distinct consecutive animation, no duplicated poses. Contact at 50% cell x,85% cell y.
Style: preserve approved softly shaded detailed dimensional chibi game painting, readable crisp edges and original palette/accessories. Only figure and compact generated contact shadow. Genuine native alpha, no painted checkerboard, background, scenery, floor, tile, labels, letters, borders or detached VFX. Do not draw reference montage.
IDENTITY: Exactly Rolo: small olive-green reptilian kobold, narrow snout and amber eyes, tan/brown head crest/spines, large pointed ears, long green tail, green hood/scarf and brown leather scout clothing, belt/pouches and brown boots, original slender staff with glowing amber lantern at its top and original rolled equipment. Preserve portrait and old combat design, no bow or new weapon. Broad crest/crown and shoulders seen from above, lowered narrow snout toward SW, diagonal feet. Staff close to body, lantern never cropped.
FINAL RETRY 4 -- WIDE GUTTERS are mandatory, previous sheet had prone pose touching next row. Make each character VERY SMALL inside its equal cell: at most 55% cell WIDTH and 55% cell HEIGHT including lantern/tail, and 45% empty padding. 8x5 regular grid, all 40 whole characters. AT LEAST 45 pixels clear transparent distance between bounding rectangles in every direction. No glow rays, particles, arcs or detached effects. Compact attack and skill poses, no long sideways staff swing. SINGLE staff with SINGLE amber lantern ONLY. Small closed rolled scroll on back, not a second torch. Plain green scarf/cape, NO skulls, symbols or logos. Exact existing reptile scout identity with brown crest, tail and pouches. Left half SW strongly down-left muzzle, broad head TOP, compressed far eye, 42 degree elevated C camera. Right half NE backs. In ROW1 of each half first two are IDLE, third DEFEATED KNEELING, fourth DEFEATED LYING FLAT, all four remain SMALL and separated by big gutters. No cropped lanterns or tails.
```

Original: `C:\Users\blueh\.codex\generated_images\01a1456c-90b2-7e63-800b-8f5f1471372f\exec-e90edef5-6e3e-499c-b9cc-9a455418334a.png`
Saved: `_mockup/monsters_v130r/quarter_final/kobold_scout/attempt_4.png`
Native alpha extrema: [0, 255]
