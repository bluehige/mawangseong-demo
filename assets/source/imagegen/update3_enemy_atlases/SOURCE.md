# Update 3 enemy atlas source record

- Created: 2026-07-13
- Generator: OpenAI image generation tool available in Codex
- Runtime folder: `res://assets/sprites/enemies/update3_atlas/`
- Layout: strict 4 × 4 sheet, 16 complete poses per enemy
- Frame map: idle 2, down 2, move 4, attack 4, skill 4
- Enemies: seal chainbearer, reliquary guard, choir exorcist, bounty tracker, combat alchemist, ledger binder
- Art direction: painterly dark-fantasy tactical RPG sprite, three-quarter view, safe padding in every frame
- Background workflow: generated source sheets were retained here; chroma-key copies use uniform RGB 255,0,255. Runtime `Unit.gd` removes only the chroma background with a shader, preserving source pixels and transparent-looking edges in game.
- Crop policy: every figure, weapon, effect, and down pose must stay inside its 4 × 4 cell. The runtime uses equal atlas regions and never expands beyond a cell.

The original generation prompts asked for one named enemy, consistent armor and silhouette across all 16 cells, explicit row-by-row actions, no text, no dividers, generous padding, and a uniform removable background. Chroma conversions retained the character design while replacing the background with pure hot magenta.
