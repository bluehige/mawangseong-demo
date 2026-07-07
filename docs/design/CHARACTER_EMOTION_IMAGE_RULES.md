# Character Emotion Image Rules

This is the required rule file for character and monster portrait generation.
Read it before generating, editing, or wiring dialogue portraits.

## Source Of Truth

- Character classification and current portrait metadata: `data/characters.json`
- Runtime access point: `DataRegistry.character(character_id)`
- Current UI consumer: `scripts/game/GameRoot.gd`
- Current base portrait folder: `assets/sprites/portraits/onboarding/`

Do not add new hard-coded portrait paths to `GameRoot.gd`.

## Character Classes

Use these categories consistently:

- `player_avatar`: the player-facing demon lord identity.
- `castle_staff`: named non-combat castle operators such as advisors and treasury staff.
- `monster_unit`: allied deployable monsters that also speak in dialogue.
- `human_intruder`: regular human-side enemies or visitors.
- `boss_rival`: major recurring enemy or boss characters.

Every speaking `CHR_*` id must have:

- `display_name`
- `category`
- `species_group`
- `faction`
- `combat_side`
- `role_tags`
- `portrait.base`
- `portrait.accent`
- `portrait.observed_emotions`
- `generation_profile.identity_anchor`

## Emotion Variant Policy

Every speaking character needs one base portrait first.

Emotion-specific portraits are generated only for emotions listed in `portrait.variant_priority`.
Other observed emotions fall back to the base portrait or to an alias in `portrait.emotion_aliases`.

Use this priority order when the character list grows:

1. Core repeated speakers: `CHR_DARKLORD_PLAYER`, `CHR_BATI`, `CHR_HERO_LEON`.
2. Result and system commentary speakers: `CHR_GOLDIN`.
3. Playable monster units: `CHR_PUDDING`, `CHR_GOB`, `CHR_PYNN`.
4. Day-specific human intruders: `CHR_EXPLORER_MILO`, `CHR_THIEF_NIA`.

Do not create a one-off emotion image for a line that appears once unless it is a boss entrance, loss, win, or major story beat.

## Naming

Existing base portraits keep their current filenames.

Future emotion variants must use:

```text
assets/sprites/portraits/<scope>/<character_id>_portrait_<emotion>.png
```

Examples:

```text
assets/sprites/portraits/onboarding/CHR_BATI_portrait_stern.png
assets/sprites/portraits/onboarding/CHR_HERO_LEON_portrait_flustered.png
```

After importing the image in Godot, update:

```json
"variants": {
  "stern": "res://assets/sprites/portraits/onboarding/CHR_BATI_portrait_stern.png"
}
```

## Generation Prompt Contract

Use Codex built-in `image_gen` for normal portrait generation.

Base prompt shape:

```text
Use case: stylized-concept
Asset type: 512x512 game dialogue portrait
Primary request: <character identity> with <target emotion>
Subject: <generation_profile.identity_anchor from data/characters.json>
Style/medium: dark fantasy comedy, polished painterly 2D game dialogue portrait
Composition/framing: bust portrait, three-quarter view, centered, readable silhouette, generous padding
Lighting/mood: dramatic dungeon rim light, expressive face, clear eyes
Color palette: <generation_profile.palette_notes>
Constraints: preserve the character's base identity, costume, proportions, and palette; no labels; no text; no watermark
Avoid: <generation_profile.avoid>
```

For emotion variants, use the current base portrait as the identity reference when possible.
The edit/generation instruction must preserve identity and change only expression, head tilt, hand/shoulder acting if needed, and mood.

## Transparency

Do not require true transparent output for dialogue portraits unless the UI needs it.
The current dialogue frame supports square portrait images with their own painted backdrop.

If a transparent cutout is explicitly needed, use the imagegen skill's built-in-first chroma-key workflow and validate alpha locally before wiring it into the project.

## Acceptance Checklist

Before reporting portrait work complete:

1. `data/characters.json` has the character id and emotion entry.
2. The PNG exists under `assets/sprites/portraits/<scope>/`.
3. The `.png.import` sidecar exists after Godot import.
4. `tools/CharacterDataSmokeTest.tscn` passes.
5. `tools/OnboardingFlowSmokeTest.tscn` passes if onboarding dialogue uses it.
6. A dialogue screenshot is captured and inspected if UI layout or visual assets changed.
