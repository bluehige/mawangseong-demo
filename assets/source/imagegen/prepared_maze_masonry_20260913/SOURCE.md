# Prepared maze masonry and warm sconce

- Generation model: GPT internal image generation
- Generated date: 2026-09-13
- Target version: v1.2.6
- Source image path: assets/source/imagegen/prepared_maze_masonry_20260913/masonry_material_source.png
- Runtime image path: assets/dungeon_quarter/prepared_maze/masonry_material.png
- Source image path: assets/source/imagegen/prepared_maze_masonry_20260913/warm_sconce_source.png
- Runtime image path: assets/dungeon_quarter/prepared_maze/warm_sconce.png

## Scope and native output

Unreleased UI/UX work on the existing 1.2.6 baseline; no new product version or release.
Both images were generated with the built-in GPT image generation tool.
Masonry: native 1254×1254 RGB opaque material. Sconce: native 1536×1024 RGBA with actual transparency.
Source and runtime files are byte-identical. No local raster editing, cropping, alpha removal, resizing, or invented transparency was applied.
Godot generates mipmaps. The masonry material is mapped onto cached wall polygons; the sconce is scaled at runtime and positioned on a real closed rear wall.

The material covers straight walls, shared corners, caps, and high/low transitions from the same wall-edge height field. This is a renderer change, not a navigation or save-format change. The sconce is decorative; it does not add a gameplay effect or a light-range rule.

## Masonry prompt

Use case: stylized-concept. Asset type: seamless square masonry material texture for actual isometric game wall surfaces, NOT a scene, not a wall sprite or perspective illustration. Create one square, fully edge-to-edge, straight-on orthographic stone masonry texture: exactly FOUR broad horizontal courses of large rectangular hand-cut dark charcoal basalt blocks, staggered joints, subtle bevelled edges, shallow dark mortar grooves, restrained warm grey mineral variation and very sparse worn nicks. Clean readable stylized 3D game material, broad smooth surfaces, low visual noise, softly lit with no directional cast shadows, no baked perspective. Albedo-like diffuse surface intended to be mapped onto real game geometry. Seamless repeating edges horizontally and vertically, stone courses continue across opposite image edges. Fill the entire square canvas with the texture. No backdrop, no wall silhouette, no borders, no columns, no doors, no floor, no letters, no decorations, no plants, no checkers. Opaque material image is intentional. Medium charcoal values rather than near-black, so real geometry lighting can darken it. The blocks must read clearly at small game scale.

## Sconce prompt

Use case: stylized-concept. Asset type: one transparent game sprite for a roofless isometric demon castle dungeon. A single compact medieval iron wall sconce, with a short thick bracket and simple dark basalt mounting plate, holding a warm amber-orange flame. Strong readable stylized 3D forms, broad bevelled iron shapes with restrained antique brass rivets, softly rendered flame with pale gold center. Orthographic isometric 2:1 game camera looking downward, upper-left light, no perspective vanishing point. Entire object centered with generous empty transparent space around it. Native RGBA PNG with real alpha-zero transparent background, no painted background or checkerboard. No floor, no wall segment, no room, no extra torches, no text, no enclosing frame. Minimal fine detail because it will be shown about 45 pixels tall; silhouette and warm flame should remain very clear. Compact flame glow may be translucent near the flame, but the surrounding canvas must be fully transparent.
