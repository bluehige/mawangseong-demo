# Steam store asset workspace

Only final Steam upload assets belong here. Generated source artwork belongs in
`assets/source/imagegen/steam_store_keyart/` with its `SOURCE.md` provenance
record. Do not place screenshots, generated originals, or build captures in
`tmp/`, `output/`, or the repository root for release.

Required current upload names and dimensions used by the validator:

| Path | Dimensions | Notes |
|---|---:|---|
| `store/header_capsule.png` | 920×430 | Logo + artwork only |
| `store/small_capsule.png` | 462×174 | Logo must remain readable |
| `store/main_capsule.png` | 1232×706 | Logo + artwork only |
| `store/vertical_capsule.png` | 748×896 | Logo + artwork only |
| `library/capsule.png` | 600×900 | Logo + artwork only |
| `library/hero.png` | 3840×1240 | Artwork only, no words |
| `library/logo.png` | 1280 px wide or 720 px tall | Transparent PNG, logo only |
| `library/header.png` | 920×430 | Logo + artwork only |
| `icons/shortcut.png` | 256×256 | PNG or ICO |
| `icons/app_icon.jpg` | 184×184 | JPEG |
| `screenshots/*.png` | at least 1920×1080 | At least five real gameplay shots |

Base capsules must not contain review scores, awards, discount text, update
copy, or unrelated product promotion. Screenshots must be actual gameplay, not
concept art or marketing composites. At least four suitable screenshots should
be marked as suitable for all ages in Steamworks when their content qualifies.

The strict release validator fails until these files exist and match the
required dimensions.

Regenerate the current approved set with:

```powershell
python tools/release/generate_steam_graphics.py
```

See `ARTWORK_PROVENANCE.md` for the source illustration and license trail.
