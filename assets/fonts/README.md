# Font Assets

Runtime font roles are centralized in `scripts/ui/UIFont.gd`.

## Current Roles

- `body`: `NEXON_Maplestory_Light.otf`
  - General UI labels and normal dialogue text.
- `dialogue`: `NEXON_Maplestory_Light.otf`
  - Dialogue body copy; use top alignment and up to four visible lines in dialogue boxes.
- `emphasis`: `NEXON_Maplestory_Bold.otf`
  - Speaker names, headings, and highlighted labels.
- `button`: `NEXON_Maplestory_Bold.otf`
  - Button text and primary commands.
- `fallback`: `NotoSansCJKkr-Regular.otf`
  - Keep this for broad CJK fallback coverage if a replacement font misses glyphs.

## Source

`NEXON_Maplestory_Light.otf` and `NEXON_Maplestory_Bold.otf` were copied from `참고자료/font/NEXON_Maplestory.zip`.

The commercial-use and redistribution notice is preserved in
`NEXON_Maplestory_LICENSE.txt`. Keep that notice with every distributed build
that embeds these fonts. The Steam build preparation script copies it into the
build's `licenses/` directory automatically.

If the project font changes later, update `scripts/ui/UIFont.gd` first, then re-run the onboarding portrait capture to check line wrapping.
