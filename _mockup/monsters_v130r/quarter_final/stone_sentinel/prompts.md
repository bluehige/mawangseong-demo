# 0101c stone_sentinel / 돌콩

Generation model: GPT internal image generation
Generated date: 2026-10-17
Target version: 1.3.0

0098 prompts.md 구조 재사용. 참조 역할·정확한 영문 호출문·시도별 판단을 보존한다.
입력: reference.png (외형: 기존 초상화/전투, 각도: 실제 지도 4조각 + 승인된 0098 후보 C 3종).
도구: image_gen; transparent_background=true; referenced_image_paths=[reference.png].
종별 최대4회 준수. 원본은 유지하고 후보의 그림을 코드로 수정하지 않는다.

| 시도 | T/F/H/E/S | 채택 | 판단 |
|---:|---|---|---|
| 1 | O/O/O/O/O | 예 | 최종 채택. 각도5항목 충족; 기술 검증은 validation_0101c.json 참조. |

## Attempt 1

```text
Use case: stylized-concept. Production combat miniature animation sprite sheet, native transparent RGBA. Reference image supplied: LEFT portrait and old combat figure are IDENTITY ONLY; TOP RIGHT contains the three user-approved 0098 candidate C characters for CAMERA ANGLE ONLY; BOTTOM four real map pieces are CAMERA references. Do not copy frog/troll identity or old eye-level camera.
CRITICAL CAMERA, identical to 0098 C: orthographic 2:1 dimetric view looking DOWN 42 degrees above horizontal, strong crown/shoulder/back TOP surfaces AT LEAST as extensive as visible front. Foreshortened short torso/lower body, face small LOW on front, viewed from ABOVE, never looking up at viewer. Southwest front three-quarter: entire head/body turned 45 degrees toward screen LOWER LEFT, near eye larger, far eye compressed by half, nose points diagonally down-left, shoulders and feet stagger diagonally. Broad crown and upper back, tiny chin. Ground contact soft horizontal 2:1 elliptical shadow generated as part of figure. No long cast shadow.
LAYOUT: wide 3072x1920 transparent canvas, EXACTLY 8 columns x 5 rows, 40 distinct separate complete figures in equal cells. All sprites same camera and scale. Each sprite entirely contained with at least 12% empty transparent margins on all sides, all limbs and props included, no touching neighbors. Left FOUR columns SW front view; right FOUR columns NE up-right BACK view, clear back of head and body, face hidden except tiny possible far-side profile. Never front-facing NE sprites. Reference props remain in same anatomical hands; actually draw reverse views, never flip front sprites.
Each half: ROW1 idle relaxed; idle breathing; defeat kneel; defeat rest. ROW2 move step1,2,3,4. ROW3 attack windup,strike,contact,recover. ROW4 skill gather,prepare,release,settle. ROW5 hit startle,recoil,compress,recover. Exactly four poses per row per facing. Attack axes follow respective facing. Distinct consecutive animation, no duplicated poses. Contact at 50% cell x,85% cell y.
Style: preserve approved softly shaded detailed dimensional chibi game painting, readable crisp edges and original palette/accessories. Only figure and compact generated contact shadow. Genuine native alpha, no painted checkerboard, background, scenery, floor, tile, labels, letters, borders or detached VFX. Do not draw reference montage.
IDENTITY: Exactly Dolkong: stocky dark GREY stone gargoyle sentinel, rocky pointed ear/horns, glowing small amber eyes, carved angular stone muzzle, huge stone hands and short chunky feet, folded dark stone BAT WINGS, stone belt/skirt plates. No moss, green vines, wood sign, scarf, weapon or extra equipment. Broad head crown and shoulder tops/back visible from above, small lowered muzzle, compressed torso, staggered feet. Attack stone punch; skill defensive braced stone stance; NE clearly shows folded wings and rear head.
Extra strict: asymmetrical SW profile, muzzle points strongly down-LEFT, far eye half the near eye, one rocky shoulder behind the other. Do NOT show two equally sized frontal eyes. Crown/upper back TOP area greater than muzzle/chest front. NO added emblems.
```

Original: `C:\Users\blueh\.codex\generated_images\01a1456c-90b2-7e63-800b-8f5f1471372f\exec-35c8e2c5-78dd-4c39-b93b-f7fbe9f9bd2c.png`
Saved: `_mockup/monsters_v130r/quarter_final/stone_sentinel/attempt_1.png`
Native alpha extrema: [0, 255]
