# V131 dialogue portraits: native transparency

- Generation model: GPT internal image generation
- Generated date: 2026-10-20
- Target version: v1.3.1

Workstream: v1.3.1-2 / 0132. All 26 calls used `transparent_background=true`. Runtime PNG files are byte-identical copies of generated originals. No local masking, chroma key, alpha filtering, recoloring, scaling, or background removal was applied. The only assembly changes are data paths and AtlasTexture source/region paths. The six update3 dialogue portraits use the original sheet first-frame identities; combat sprite sheets remain unchanged. Legacy originals were copied for provenance. Existing Goldin native-alpha references were reused in the speaker registry.

The five contact sheets were made only for bounded inspection and generator references (maximum 960px); compositing them does not modify the runtime assets. Old prompts for the legacy images were not reconstructed. Exact prompts used in this session follow.

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/reference_0.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/reference_1.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/reference_2.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/reference_3.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/reference_4.png

## 00: portrait_explorer_milo.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_00.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_00.png
- Runtime image path: assets/sprites/portraits/onboarding/portrait_explorer_milo_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/portrait_explorer_milo.png`. Generated size: 1323?1189. Runtime SHA256: `bb82da848c38ff33d364f76d8e6ca95c9a8f679777c0782d751f6a788a333600`.

Prompt: `prompt_00.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 0 top left: portrait_explorer_milo, frightened brown-haired boy explorer, brown miner helmet with headlamp, green scarf, brown leather coat and gloves, backpack, map, nervous mouth and sweat. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 01: portrait_hero_leon.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_01.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_01.png
- Runtime image path: assets/sprites/portraits/onboarding/portrait_hero_leon_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/portrait_hero_leon.png`. Generated size: 1320?1192. Runtime SHA256: `70f9f86a5ed2fe51e13621807bc85a5180a27f4a16c2a6853de8ec4734e8a941`.

Prompt: `prompt_01.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 1 top second: portrait_hero_leon, tousled blond young male hero, blue eyes, determined tense expression and sweat, blue hooded cloak with gold trim and gold star brooch over dark armor, fist held to chest. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 02: portrait_thief_nia.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_02.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_02.png
- Runtime image path: assets/sprites/portraits/onboarding/portrait_thief_nia_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/portrait_thief_nia.png`. Generated size: 1269?1240. Runtime SHA256: `2e283253c6652bf0375bd94992d0d7c92be4b27079c6db7a0f186d17395c5ffb`.

Prompt: `prompt_02.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 2 top third: portrait_thief_nia, adult pale woman thief with black hair partly across face, dark purple hood with gold vine embroidery, purple gem drop earrings, knowing sly smile, finger to lips, brown-black leather armor and gold chains. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 03: CHR_EXPLORER_MILO_portrait_panic.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_03.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_03.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_EXPLORER_MILO_portrait_panic_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_EXPLORER_MILO_portrait_panic.png`. Generated size: 1389?1132. Runtime SHA256: `0815e80134cfcc959ba22c89896ba46471d3ce426b30d6d451107ab940bfd17f`.

Prompt: `prompt_03.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 3 top right: CHR_EXPLORER_MILO_portrait_panic, frightened young explorer with brown hair and brown brimmed hat, teal scarf and weathered brown coat, backpack, lantern raised with left hand, map in right hand, scared open mouth. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 04: CHR_INVESTIGATOR_IRIS_portrait_inquisitive.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_04.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_04.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_INVESTIGATOR_IRIS_portrait_inquisitive_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_INVESTIGATOR_IRIS_portrait_inquisitive.png`. Generated size: 1278?1230. Runtime SHA256: `324e0559fd0e6bc339730af6a7692b81139152921b5a72a112d415b98cde86ae`.

Prompt: `prompt_04.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 4 bottom left: CHR_INVESTIGATOR_IRIS_portrait_inquisitive, young woman investigator, brown curled bob and brown military cap with shield badge, narrowed inquisitive eyes, brown leather coat, map and magnifying glass. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 05: CHR_SELEN_portrait_checklist.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_05.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_05.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_SELEN_portrait_checklist.png`. Generated size: 1150?1367. Runtime SHA256: `42ce567ce1ed70d37c680dd75afc81ae27935919967a8ecc1bcf3ae545cd001a`.

Prompt: `prompt_05.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Edit target is ONLY character 5 bottom middle: CHR_SELEN_portrait_checklist, stylized cartoon male knight bust, blue blindfold-like visor, gold crown helmet red gem, gold white silver blue armor, neutral mouth and exact angular bust silhouette. Reference is the numbered contact sheet. Recreate that ONE portrait faithfully, keeping original identity, clothing, facial expression, pose, props, colors and painterly style. Native transparent RGBA background, alpha=0 around silhouette and all four corners. Remove the entire original backdrop, stone walls, dark vignette, colored panel, white background. Do not include other reference characters, sheet labels, frame, text or checkerboard. Full visible head and original bust composition, a small transparent margin around the silhouette. Only background removal changes requested.
```

## 06: CHR_THIEF_NIA_portrait_teasing.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_06.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_06.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_THIEF_NIA_portrait_teasing_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_THIEF_NIA_portrait_teasing.png`. Generated size: 1254?1254. Runtime SHA256: `c25c890d7627c4f0bcb9f4f8c3462a13ccaf6fef5872c63ab414ac62c566b102`.

Prompt: `prompt_06.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Produce ONE transparent RGBA game dialogue portrait of ONLY the woman labeled 6 (bottom row, right): CHR_THIEF_NIA_portrait_teasing. Keep her exact black ponytail with purple ribbon, face, sly smirk, purple scarf, brown-black leather outfit, clipboard and raised lockpick, original pose and painterly style. Reconstruct the portrait faithfully at 1024 square resolution. Remove ALL the stone wall and surrounding rectangular background; genuine native transparent background with alpha=0, including empty corners and space around her hair/body. Do not include other characters from the reference contact sheet, labels, backdrop, frames, shadow panels, white or checkerboard pixels. Keep original bust composition and full visible head and shoulders.
```

## 07: CHR_HERO_LEON_portrait_defeated.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_07.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_07.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_defeated_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_defeated.png`. Generated size: 1254?1254. Runtime SHA256: `0077db13b352af47ae98e1ff004726603c9b9e250fa42d3134708c74db1652f4`.

Prompt: `prompt_07.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 7 in reference sheet reference_1. Character is the same young male hero Leon. defeated: lowered head, sad dejected blue eyes and frown; blue hooded cape, dark armor and gold star brooch. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 08: CHR_HERO_LEON_portrait_determined.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_08.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_08.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_determined_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_determined.png`. Generated size: 1254?1254. Runtime SHA256: `329e665bf26835a61f1809e38ff898f93f2d2b03ef4d337c0f8bce0f26186a68`.

Prompt: `prompt_08.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 8 in reference sheet reference_1. Character is the same young male hero Leon. determined: tense serious direct blue eyes and firm mouth, blond hair, blue cape and dark armor with gold star clasp, right fist at chest. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 09: CHR_HERO_LEON_portrait_flustered.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_09.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_09.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_flustered_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_flustered.png`. Generated size: 1254?1254. Runtime SHA256: `53b84c9644d2b2fd42f531c19eb8503a1171fa3aef88891a373817086d8e53e2`.

Prompt: `prompt_09.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 9 in reference sheet reference_1. Character is the same young male hero Leon. flustered: startled worried open mouth, wide blue eyes, blushing cheeks, fist raised at chest, blue hooded cape and gold star brooch. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 10: CHR_HERO_LEON_portrait_heroic.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_10.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_10.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_heroic_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_heroic.png`. Generated size: 1254?1254. Runtime SHA256: `efeaa51a034008a05fd4d49861666d472cfe5e3c0c06c1c207bffd1f23f1b66c`.

Prompt: `prompt_10.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 10 in reference sheet reference_1. Character is the same young male hero Leon. heroic: confident smile, blue eyes, tousled blond hair, black steel knight armor with gold trim, blue cape and clenched armored fist. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 11: CHR_HERO_LEON_portrait_manual.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_11.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_11.png
- Runtime image path: assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_manual_alpha_v131.png

Original: `assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_manual.png`. Generated size: 1254?1254. Runtime SHA256: `ef3f906b61218ad9779b7625d486d1473aebaed494b461c4cdb3651a55d7476a`.

Prompt: `prompt_11.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 11 in reference sheet reference_1. Character is the same young male hero Leon. manual: thoughtful expression, right hand touching chin, open brown book in left hand, blond hair blue eyes, blue cape dark gold-trimmed armor. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 12: CHR_HERO_LEON_OFFICIAL_portrait_final.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_12.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_12.png
- Runtime image path: assets/sprites/portraits/campaign/CHR_HERO_LEON_OFFICIAL_portrait_final_alpha_v131.png

Original: `assets/sprites/portraits/campaign/CHR_HERO_LEON_OFFICIAL_portrait_final.png`. Generated size: 1254?1254. Runtime SHA256: `f38ea670214211a8e3c358650bc26b492b7befbfdb568e11dd91b896c658b6f2`.

Prompt: `prompt_12.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 12 in reference sheet reference_1. Character is the same young male hero Leon. official final: confident slight smile, tousled blond hair, blue eyes, blue cape, black gold-trimmed plate armor, silver gauntlet clenched across chest. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 13: CHR_ROMAN_portrait_command.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_13.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_13.png
- Runtime image path: assets/sprites/portraits/campaign/CHR_ROMAN_portrait_command_alpha_v131.png

Original: `assets/sprites/portraits/campaign/CHR_ROMAN_portrait_command.png`. Generated size: 1254?1254. Runtime SHA256: `8bcaf78ee58ef04e203d1aa13f8729534e1e187168336d93cb4ac37a06fbb86b`.

Prompt: `prompt_13.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate only numbered portrait 13 in reference sheet reference_1. Roman command: serious weathered adult male officer with dark brown hair and short beard, navy peaked cap gold emblem, navy coat with ornate gold edges and lapels, white shirt red tie, brown gloves holding brown clipboard. Keep original character identity, expression, clothes, pose, props, colors and detailed painterly game style. Make one square bust portrait, native transparent RGBA, alpha=0 in empty corners and all space around silhouette, small transparent margin at head and sides. Remove ALL dark scenery, stone background, vignette and rectangular panels. No other sheet characters, labels, text, shadows on panels, checkerboard or colored background. Preserve original composition; only remove background.
```

## 14: CHR_SHIELDBEARER_portrait.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_14.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_14.png
- Runtime image path: assets/sprites/portraits/enemies/CHR_SHIELDBEARER_portrait_alpha_v131.png

Original: `assets/sprites/portraits/enemies/CHR_SHIELDBEARER_portrait.png`. Generated size: 1275?1234. Runtime SHA256: `f2004ac7dedce5009b5a6cfde6e229b4cabceee4860dc9b1bb4cda9a68d58f10`.

Prompt: `prompt_14.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from the shieldbearer in the top-left image labeled 14: young male knight with brown hair and confident eyes, navy hood, silver and gold helmet, blue gold-trimmed cape, dark plate armor, large black-gold shield with crown emblem in right side, short sword in left hand. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 15: enemy_bounty_tracker_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_15.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_15.png
- Runtime image path: assets/sprites/portraits/update3/enemy_bounty_tracker_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_bounty_tracker_sheet.png`. Generated size: 1185?1327. Runtime SHA256: `6a49114f1df5b1b15025a5f8ab379618402212a5ccc4d5b75c6b3da93ba3b8de`.

Prompt: `prompt_15.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from bounty tracker in image 15: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Dark brown-green hooded ranger with leather armor, brown cloak, crossbow/ranged hunting gear. Retain its original isometric game sprite design, pose and green/brown palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 16: enemy_choir_exorcist_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_16.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_16.png
- Runtime image path: assets/sprites/portraits/update3/enemy_choir_exorcist_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_choir_exorcist_sheet.png`. Generated size: 1169?1345. Runtime SHA256: `43bfab4c90761cc6ef2cb4155ecd563ca4cec43905af741adb84b67d4e3d1ac4`.

Prompt: `prompt_16.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from choir exorcist in image 16: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Pale blonde long-haired priestess in white and gold religious robes holding golden staff. Retain its original isometric game sprite design, pose and white/gold palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 17: enemy_combat_alchemist_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_17.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_17.png
- Runtime image path: assets/sprites/portraits/update3/enemy_combat_alchemist_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_combat_alchemist_sheet.png`. Generated size: 1159?1357. Runtime SHA256: `1f9192a60b66aed56b936e0206ecdd9f98c72b994cfd63a220d498f84425a96c`.

Prompt: `prompt_17.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from combat alchemist in image 17: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Green coat brown leather belt and dark hood, green potion equipment, gloved hands, mysterious face. Retain its original isometric game sprite design, pose and green/brown palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 18: enemy_ledger_binder_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_18.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_18.png
- Runtime image path: assets/sprites/portraits/update3/enemy_ledger_binder_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_ledger_binder_sheet.png`. Generated size: 1219?1290. Runtime SHA256: `671b0d4fe7f9b58852295ba5135145d9e1ad5c0557d77504c6f62b7eda78ebf8`.

Prompt: `prompt_18.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from ledger binder in image 18: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Gold pointed hood, brown-purple ornate long coat, pale face, large gilded ledger book held in front and chain ornament. Retain original isometric game sprite design, pose and gold/brown/purple palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 19: enemy_reliquary_guard_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_19.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_19.png
- Runtime image path: assets/sprites/portraits/update3/enemy_reliquary_guard_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_reliquary_guard_sheet.png`. Generated size: 1193?1319. Runtime SHA256: `9a9e2f0dfb5f606d0e3e261df9d2625829d3a1809ac236bd5b3285141d715f3a`.

Prompt: `prompt_19.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from reliquary guard in image 19: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Heavy gold full plate armor and helmet, massive gold shield, glowing cyan blue face visor and blue tabard. Retain original isometric game sprite design, pose and gold/cyan palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 20: enemy_seal_chainbearer_sheet.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_20.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_20.png
- Runtime image path: assets/sprites/portraits/update3/enemy_seal_chainbearer_alpha_v131.png

Original: `assets/sprites/enemies/update3_atlas/enemy_seal_chainbearer_sheet.png`. Generated size: 1191?1320. Runtime SHA256: `6746b03c49dbe82d4d25dc4f254940bccb5de5b9fa3eccf32670d99cfc169aa5`.

Prompt: `prompt_20.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Make ONE native transparent RGBA game portrait from seal chainbearer in image 20: only the standing humanoid FIRST top-left frame of its 4x4 spritesheet. Long pale blond-haired robed figure in white and grey layered robes, gold belts and chains, staff/chain magical implement. Retain original isometric game sprite design, pose and white/gold palette. Reference is numbered contact sheet reference_2. Preserve the original character identity, outfit, expression, pose and art style. For 14 preserve bust composition; for 15-20 produce an enlarged faithful version of ONLY THE FIRST STANDING FRAME, full original body, not an invented bust, no other animation frames. Alpha=0 completely outside character, four empty transparent corners and small transparent margin. Remove magenta, stone walls and all scenery completely. No checkerboard, flat color panel, frame, label, text or other characters. This is a replacement dialogue portrait only, no animation sheet.
```

## 21: portraits.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_21.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_21.png
- Runtime image path: assets/sprites/portraits/uiux_evolution/portraits_alpha_v131.png

Original: `assets/sprites/portraits/uiux_evolution/portraits.png`. Generated size: 1536?1024. Runtime SHA256: `247ee170e1a3d5fe708eed8eef6a4d4012a4b3b603bfdc0a1281bf14bf742fec`.

Prompt: `prompt_21.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate ONLY the left sheet labeled 21 portraits: neutral/ready expressions. Six cells: top row blue gelatin slime knight with strawberry and whipped cream top, teal shield and golden star crest; green hooded goblin with leather armor and spear; pink-haired imp mage with small dark horns and pink fire. Bottom row white/lavender crowned slime alchemist with strawberry whipped cream and teal potion bottle; green goblin vault guard in ornate dark-gold plate and lock emblem shield; pale pink/white-haired imp shaman with large black horns and black-purple feathered robe, purple staff. Reference is a contact sheet containing several sheets: output ONLY the six characters belonging to the indicated numbered sheet, not the neighboring sheets. Output ONE LANDSCAPE 3:2 RGBA atlas, 1536x1024, EXACTLY 3 equal columns and 2 equal rows (each cell512 square). Maintain each character identity, costume, pose, expression, style and original cell order. Each character is individually isolated on genuine native transparency, alpha=0 throughout all six cell backgrounds. Keep a generous transparent gutter on ALL FOUR edges of EVERY cell; heads, bodies, weapons, flames and wings must remain inside their own cell. Preserve original colored character lighting and design. Remove ALL dark rectangular cell background panels, gradient/vignette, shadow backdrops, labels, frames and checkerboard. No text, no extra characters. Distinct six portraits, consistent original 3x2 grid; background removal only.
```

## 22: victory.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_22.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_22.png
- Runtime image path: assets/sprites/portraits/uiux_evolution/victory_alpha_v131.png

Original: `assets/sprites/portraits/uiux_evolution/victory.png`. Generated size: 1536?1024. Runtime SHA256: `d746927a85a8ab3756bf8b263edb448fc728a243698c120cf4035f4c3078b3fb`.

Prompt: `prompt_22.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate ONLY the middle sheet labeled 22 victory: happy/victorious expressions as shown. Six cells in same original order: blue gelatin slime knight strawberry whipped cream top teal shield and gold star crest; green hooded goblin leather armor spear; pink-haired horned imp mage pink flames; white/lavender slime alchemist strawberry top teal potion; green goblin vault keeper dark-gold plate and lock emblem shield; pale pink/white-haired imp shaman black horns purple feathered robes and staff. Reference is a contact sheet containing several sheets: output ONLY the six characters belonging to the indicated numbered sheet, not the neighboring sheets. Output ONE LANDSCAPE 3:2 RGBA atlas, 1536x1024, EXACTLY 3 equal columns and 2 equal rows (each cell512 square). Maintain each character identity, costume, pose, expression, style and original cell order. Each character is individually isolated on genuine native transparency, alpha=0 throughout all six cell backgrounds. Keep a generous transparent gutter on ALL FOUR edges of EVERY cell; heads, bodies, weapons, flames and wings must remain inside their own cell. Preserve original colored character lighting and design. Remove ALL dark rectangular cell background panels, gradient/vignette, shadow backdrops, labels, frames and checkerboard. No text, no extra characters. Distinct six portraits, consistent original 3x2 grid; background removal only.
```

## 23: wounded.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_23.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_23.png
- Runtime image path: assets/sprites/portraits/uiux_evolution/wounded_alpha_v131.png

Original: `assets/sprites/portraits/uiux_evolution/wounded.png`. Generated size: 1536?1024. Runtime SHA256: `252331834932d10c386356c35cfd01713253a34fef2f9ae4ca14e53cb57dfca9`.

Prompt: `prompt_23.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate ONLY the right sheet labeled 23 wounded: tired/hurt/sad expressions as shown. Six cells in same original order: blue gelatin slime knight strawberry whipped cream top teal shield and gold star crest; green hooded goblin leather armor spear; pink-haired horned imp mage pink flames; white/lavender slime alchemist strawberry top teal potion; green goblin vault keeper dark-gold plate and lock emblem shield; pale pink/white-haired imp shaman black horns purple feathered robes and staff. Reference is a contact sheet containing several sheets: output ONLY the six characters belonging to the indicated numbered sheet, not the neighboring sheets. Output ONE LANDSCAPE 3:2 RGBA atlas, 1536x1024, EXACTLY 3 equal columns and 2 equal rows (each cell512 square). Maintain each character identity, costume, pose, expression, style and original cell order. Each character is individually isolated on genuine native transparency, alpha=0 throughout all six cell backgrounds. Keep a generous transparent gutter on ALL FOUR edges of EVERY cell; heads, bodies, weapons, flames and wings must remain inside their own cell. Preserve original colored character lighting and design. Remove ALL dark rectangular cell background panels, gradient/vignette, shadow backdrops, labels, frames and checkerboard. No text, no extra characters. Distinct six portraits, consistent original 3x2 grid; background removal only.
```

## 24: core.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_24.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_24.png
- Runtime image path: assets/sprites/portraits/uiux_crowns/core_alpha_v131.png

Original: `assets/sprites/portraits/uiux_crowns/core.png`. Generated size: 1536?1024. Runtime SHA256: `deed88cc1cd9ba573fd9a3664cebebf1cf7e84921e090647e5eae2860d2896b4`.

Prompt: `prompt_24.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate ONLY the left sheet labeled 24 core. Top row victorious, bottom row wounded. Columns: blue slime royal bastion with strawberry cake top, golden crown and teal crystal shield, purple gel body; green hooded goblin midnight marshal with elaborate black/gold armor, gold crown and spear; magenta-haired horned imp queen with black/gold/purple robes, gold crown and purple fire orb. Reference is a contact sheet containing several sheets: output ONLY the six characters belonging to the indicated numbered sheet, not the neighboring sheets. Output ONE LANDSCAPE 3:2 RGBA atlas, 1536x1024, EXACTLY 3 equal columns and 2 equal rows (each cell512 square). Maintain each character identity, costume, pose, expression, style and original cell order. Each character is individually isolated on genuine native transparency, alpha=0 throughout all six cell backgrounds. Keep a generous transparent gutter on ALL FOUR edges of EVERY cell; heads, bodies, weapons, flames and wings must remain inside their own cell. Preserve original colored character lighting and design. Remove ALL dark rectangular cell background panels, gradient/vignette, shadow backdrops, labels, frames and checkerboard. No text, no extra characters. Distinct six portraits, consistent original 3x2 grid; background removal only.
```

## 25: support.png

- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/generated_25.png
- Source image path: assets/source/imagegen/v131_portrait_alpha_20261020/original_25.png
- Runtime image path: assets/sprites/portraits/uiux_crowns/support_alpha_v131.png

Original: `assets/sprites/portraits/uiux_crowns/support.png`. Generated size: 1536?1024. Runtime SHA256: `4144a125fd2a222a2f5371cee64a0687d36cf6521677c9e099fdd13c6cf10f16`.

Prompt: `prompt_25.txt` (exact, also reproduced below).

```text
Use case: background-extraction. Recreate ONLY the right sheet labeled 25 support. Top row victorious, bottom row wounded. Columns: elder mushroom priest with beige drooping moustache/beard, red-spotted cap and gold jeweled crown, green cloak and glowing staff; heavily armored horned beetle with royal gold crown, black/gold segmented armor and purple gem face; blue bat courier with gold crown, purple ears/wing membranes, brown satchel, parcel and mail paper. Reference is a contact sheet containing several sheets: output ONLY the six characters belonging to the indicated numbered sheet, not the neighboring sheets. Output ONE LANDSCAPE 3:2 RGBA atlas, 1536x1024, EXACTLY 3 equal columns and 2 equal rows (each cell512 square). Maintain each character identity, costume, pose, expression, style and original cell order. Each character is individually isolated on genuine native transparency, alpha=0 throughout all six cell backgrounds. Keep a generous transparent gutter on ALL FOUR edges of EVERY cell; heads, bodies, weapons, flames and wings must remain inside their own cell. Preserve original colored character lighting and design. Remove ALL dark rectangular cell background panels, gradient/vignette, shadow backdrops, labels, frames and checkerboard. No text, no extra characters. Distinct six portraits, consistent original 3x2 grid; background removal only.
```
