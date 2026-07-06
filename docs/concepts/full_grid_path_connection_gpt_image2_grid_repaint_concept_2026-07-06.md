# Full-Grid Path Connection GPT Image 2 Grid-Repaint Concept - 2026-07-06

Image:

- `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`

Status:

- GPT Image 2 / built-in `image_gen` concept art.
- Generated as a repaint pass using the grid-accurate clean reference as the structural guide.
- This supersedes the earlier GPT Image 2 radial/symmetric concept at `docs/concepts/full_grid_path_connection_gpt_image2_concept_2026-07-06.png`.
- Not a runtime atlas.
- Not production-approved until the user accepts it.

## Why This Exists

The previous GPT Image 2 concept drifted into a prettier symmetric six-room composition and did not match the actual grid layout.

This pass explicitly asked GPT Image 2 to:

- preserve the clean grid-accurate reference geometry,
- avoid redesigning the macro layout,
- avoid a radial/symmetric six-room layout,
- repaint the existing positions and path skeleton only.

## Source Of Truth

Placement source:

- `docs/concepts/full_grid_path_connection_grid_accurate_concept_2026-07-06.png`
- `docs/concepts/full_grid_path_connection_grid_accurate_concept_overlay_2026-07-06.png`
- generator: `tools/generate_grid_accurate_path_concept.py`

Art-direction target:

- `docs/concepts/full_grid_path_connection_gpt_image2_grid_repaint_concept_2026-07-06.png`

## Important Limitation

This is still GPT Image 2 generated art. It is more layout-faithful than the previous radial concept, but pixel-perfect grid truth remains the grid-accurate generated reference and the JSON data.

If the user accepts this visual direction, production should use:

- grid-accurate reference for placement,
- this repaint concept for mood/material/readability,
- runtime JSON for final path and doorway positions.

## Prompt Used

```text
Image-to-image repaint task. Use the provided clean grid-accurate reference image as the exact composition. Preserve its geometry exactly.

Hard constraints:
- Keep the exact same canvas crop and camera angle as the reference.
- Keep every room footprint in the exact same position and size as the reference.
- Keep every corridor/path tile in the exact same position and shape as the reference.
- Keep the central spike trap in the exact same position as the reference.
- Keep the same asymmetric layout. Do not make a prettier radial layout. Do not center the throne. Do not move entrance, barracks, recovery, treasure, build slot, or throne.
- Do not add new rooms. Do not remove rooms. Do not add extra corridors. Do not fill empty cave void with floor.
- This is a repaint/texture pass only, not a redesign.

Allowed changes:
- Replace simple placeholder room icons with polished pixel-adjacent room art, while staying inside the existing room footprints.
- Add rough hand-stacked cave stone texture to existing room boundaries.
- Add worn dark stone texture to the existing corridor tiles only.
- Add cave rock, rubble, muted violet shadows, and warm torch accents around existing forms.
- Make the entrance gate, barracks, throne, recovery nest, treasure vault, and build-slot foundation more readable without moving them.

Style: polished painterly pixel-adjacent 2D isometric dungeon concept art, small Demon King cave castle, rough basalt stone, dark cave void, readable game-map silhouettes.

Output rules: no labels, no UI, no text, no watermark, no characters. Preserve the exact reference layout above all other goals.
```
