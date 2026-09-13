# Prepared maze dark brown packed earth

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6
- Source image path: assets/source/imagegen/prepared_maze_soil_20260913/packed_earth_source.png
- Runtime image path: assets/dungeon_quarter/prepared_maze/packed_earth.png

## Native output and integration

Unreleased UI/UX work on the 1.2.6 baseline; no new version or release.
Built-in GPT image generation, one material. Native output: 1254×1254 RGB, 2,573,418 bytes. The requested 1024 square was returned at 1254 square; its native size is preserved.
SHA256 (source and runtime): ddfc3518ff391e4d5e55e52c072c38b6b0708d7a37b3780f0be182b34970ef4b.
Original tool output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-3cc6aed9-b340-474f-ad68-c278402ba61a.png.

Source and runtime are byte-identical. No local raster editing, recoloring, cropping, alpha processing or downscaling. Opaque material output is intentional. Godot generates mipmaps and maps one full texture over four by four world floor cells. Continuous world-aligned texture coordinates replace the stone-tile layer and the old room/corridor grid overlays for the prepared maze. Existing facility plinth sprites, thresholds, black masonry, actors, movement and save data are preserved. Cards and ghosts share the same facility renderer as the installed building.

## Final generation prompt

Use case: stylized-concept. Asset type: seamless square diffuse material texture for the walkable ground of a roofless isometric demon-castle game, NOT a screenshot or a perspective floor tile. Create one fully edge-to-edge square 1024x1024 opaque texture of dark rich brown compacted earth, natural packed soil. Dominant deep umber and dark chocolate brown, with restrained lighter earthy brown broad worn patches and soft shallow depressions. Dense smooth packed soil, a few very small embedded pebbles, subtle organic unevenness; broad readable hand-painted stylized 3D game texture, low visual noise, crisp yet soft material detail. Dark brown but enough readable midtones to contrast with near-black stone walls. Flat top-down orthographic material, even diffuse illumination, seamless tiling on all four edges. No paving stones, no masonry blocks, no stone slab grid, no bricks, no regular tiles, no large cracks, no grass, no roots, no objects, no footprint pattern, no baked directional shadows, no borders, no vignette, no background, no text, no checkerboard. Entire image is the soil surface. Opaque output is intentional.
