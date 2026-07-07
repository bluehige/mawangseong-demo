# Portrait Sprites

Portrait metadata is declared in `data/characters.json`.

Current onboarding base portraits live in `assets/sprites/portraits/onboarding/` and keep their existing filenames:

- `portrait_darklord_player.png`
- `portrait_bati.png`
- `portrait_goldin.png`
- `portrait_pudding.png`
- `portrait_gob.png`
- `portrait_pynn.png`
- `portrait_explorer_milo.png`
- `portrait_thief_nia.png`
- `portrait_hero_leon.png`

Future emotion variants should use:

```text
assets/sprites/portraits/<scope>/<character_id>_portrait_<emotion>.png
```

Example:

```text
assets/sprites/portraits/onboarding/CHR_BATI_portrait_stern.png
```

After adding a variant, update the character's `portrait.variants` entry in `data/characters.json`.

Do not generate a new emotion variant without checking `docs/design/CHARACTER_EMOTION_IMAGE_RULES.md` first.
