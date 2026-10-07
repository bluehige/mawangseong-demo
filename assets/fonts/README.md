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

## Simplified Chinese local candidate

`zh_CN` uses the already bundled `NotoSansCJKkr-Regular.otf` explicitly for all
roles, default fallback and tooltip text. The Korean/English NEXON roles retain
their original font and gain the bundled CJK fallback for the Chinese selector.
No new font was downloaded or installed and the existing OFL notice remains.
The Chinese locale is used for shaping. This is the existing KR-family font,
not a separately acquired SC-family font. The local engine check covers all
1,793 CJK/punctuation codepoints used in the candidate catalogs; final regional
typography and native-speaker aesthetic acceptance are not implied by coverage.
