# Prepared maze torch-lit flagstone

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6
- Source image path: assets/source/imagegen/prepared_maze_flagstone_20260913/flagstone_source.png
- Runtime image path: assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png

## Native output and use

Unreleased UI/UX work on the current 1.2.6 baseline. Built-in GPT image generation, one opaque material.
Native output is 1254×1254 RGB, 2,483,938 bytes (requested 1024 square; native size preserved).
SHA256 of both source and runtime: 8f50dfb9f466bd0aeb054e249efbde915b28da966f350f99069b9302eb847d7c.
Tool output: C:/Users/blueh/.codex/generated_images/01a0945d-ec57-7dc1-9fa6-7b8ea8c19ca3/exec-ab5df811-5e6e-4092-a30a-6d83805d7a1b.png.

The source and runtime files are byte-identical. No local raster editing, crop, recoloring, alpha processing, or resizing. Godot generates mipmaps and maps the texture across three by three floor cells in world coordinates. Material joints are part of the generated image; cell geometry meets edge-to-edge. Existing facility bases and thresholds stay in place.
Runtime floor vertex colors provide cool ambient stone and warm falloff near existing wall sconces, restricted to the sconce's room. Colors are cached with map geometry; they add no gameplay illumination/stealth/range mechanic. No dynamic shadow system is introduced. The previously generated soil asset is retained as an unused prior alternative; the prepared maze now loads this stone texture.

## Final generation prompt

Use case: stylized-concept. Asset type: seamless square stone floor material for an isometric dark-fantasy dungeon game. One opaque edge-to-edge 1024x1024 TOP-DOWN orthographic flat texture, not a room, screenshot or isometric diamond. Medieval dungeon paving of broad worn rectangular and nearly square stone slabs, about eight slabs across and eight courses down, varied lengths with staggered joints. Smooth matte medium warm-grey stone faces, subtle taupe mineral variation, distinct narrow dark charcoal recessed joints, softly bevelled edges with readable pale grey highlights on upper-left edges and shallow shadows along lower-right edges. Stylized polished 3D game material with strong readable form, similar to attractive torch-lit stone platforms. Neutral grey base material suitable for warm torchlight applied in the game. Restrained broad stone shapes, shallow chips at a few corners, minimal grain, no noisy speckles. Seamless repeat on all four edges with consistent value across the canvas, even overall lighting, no central spotlight, no vignette. No dirt floor, no bricks, no cobblestone pebbles, no wall elevations, no objects, no torches, no plants, no gold ornaments, no border, no text, no checkerboard, no transparency. Fill the entire square with paving surface.
