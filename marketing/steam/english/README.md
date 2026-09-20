# English Steam assets

The seven PNG files in this directory are English siblings of the Korean Steam logo and capsules.

| File | Pixels |
|---|---|
| library/logo.png | 1280 × 720, transparent |
| library/capsule.png | 600 × 900 |
| library/header.png | 920 × 430 |
| store/header_capsule.png | 920 × 430 |
| store/small_capsule.png | 462 × 174 |
| store/main_capsule.png | 1232 × 706 |
| store/vertical_capsule.png | 748 × 896 |

Source and exact prompt: `assets/source/imagegen/steam_english_title_v127/SOURCE.md`.
The existing text-free hero/icons can be shared between languages. The previously approved `marketing/steam/promo/promo_english.png` remains valid.

Six current English gameplay captures are delivered in the full English ZIP under `marketing/steam/english/screenshots/`. They are unedited engine captures, not AI-generated artwork, and remain outside the source branch. Reproduce them with `FullEnglishRuntimeTest.tscn` in English at 1920 × 1080 (isolated APPDATA); see the localization audit for details.

Steam deployment update (2026-09-21): all seven English assets and their Korean counterparts are now saved in Steamworks. The English interface/subtitle flags and the Korean/English language selection notice are saved. The default game build is v1.2.8 (Build 25423797).

Fresh v1.2.8 gameplay captures live in `tmp/steam_store_v128/`. The store gallery uses six distinct scenes (three English and three Korean captures), led by combat; it is a shared bilingual gallery. The description uses three image groups (`v128_defense`, `v128_build`, `v128_companions`) that automatically select the matching English/Korean image and accessibility text. Existing artwork provenance is unchanged; no new AI artwork was generated for this store polish.

The store page is still awaiting Valve's first review and public Coming Soon publication. Saving assets and verifying BETA previews does not mean the store is publicly released. See `docs/handoff/V128_STEAM_STORE_POLISH_2026-09-21.md` for the final evidence and remaining release requirements.
