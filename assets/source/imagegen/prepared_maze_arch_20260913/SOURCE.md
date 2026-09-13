# Fixed maze open arch atlas

Generation model: GPT internal image generation
Generated date: 2026-09-13
Target version: 1.2.6-based UIUX worktree; unreleased
Source image path: assets/source/imagegen/prepared_maze_arch_20260913/open_arch_atlas_source.png
Runtime image path: assets/dungeon_quarter/prepared_maze/open_arch_atlas.png

Native RGBA 1774x887, alpha 0..255, preserved byte-for-byte. No background removal, resizing, recoloring or pixel edits. Godot uses two 887x887 AtlasTexture regions and runtime uniform scaling. Transparent empty pixels also exist inside each passage. Linear mipmaps at runtime.

## Generator prompt

Use case: stylized-concept. Asset type: game-ready transparent sprite atlas for a Korean fantasy demon-castle isometric dungeon game. Create ONE cohesive two-direction atlas of the SAME open stone doorway arch. Wide canvas split into two equal square cells, one arch centered in each half with generous fully transparent margins and no overlap. Left cell: orthographic isometric 2:1 view, doorway threshold baseline rising from lower-left to upper-right. Right cell: its mirrored orientation, baseline falling from upper-left to lower-right. Both are solid dimensional stone arches, two short thick carved basalt piers supporting a rounded pointed vault, restrained antique brass trim and a single small purple jewel above the opening. Clean stylized 3D game render, broad readable stone shapes, soft upper-left lighting, not noisy pixel art, no excessive spikes. Open passage interior must be completely transparent: no door slab, no dark painted interior, no floor or platform or backdrop. Wall thickness visible but modest. Low wide arch proportions, opening wide enough for two game characters. Actual native RGBA PNG transparency is REQUIRED around and INSIDE both arches, alpha zero through the opening. Do not paint a checkerboard or solid color to represent transparency. No shadows extending across empty background, no text, no captions, no dividing lines, no frame.