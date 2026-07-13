"""Prepare runtime PNGs from built-in GPT ImageGen source sheets.

This tool does not draw artwork.  It only crops GPT-generated source sheets,
removes the chroma background, resizes frames, and writes the existing runtime
filenames expected by Godot.
"""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "concepts" / "gpt_runtime_replacement_2026-07-12"
MAGENTA = (255, 0, 255)


def grid_cell(image: Image.Image, column: int, row: int, columns: int, rows: int) -> Image.Image:
    left = round(column * image.width / columns)
    right = round((column + 1) * image.width / columns)
    top = round(row * image.height / rows)
    bottom = round((row + 1) * image.height / rows)
    return image.crop((left, top, right, bottom))


def remove_magenta(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = []
    for red, green, blue, alpha in image.get_flattened_data():
        distance = ((red - MAGENTA[0]) ** 2 + green**2 + (blue - MAGENTA[2]) ** 2) ** 0.5
        if distance <= 48:
            alpha = 0
        elif distance < 78:
            alpha = round(alpha * (distance - 48) / 30)
        pixels.append((red, green, blue, alpha))
    image.putdata(pixels)
    return image


def prepared_cell(image: Image.Image, column: int, row: int, columns: int, rows: int, size: int) -> Image.Image:
    cell = grid_cell(image, column, row, columns, rows)
    cell = cell.resize((size, size), Image.Resampling.LANCZOS)
    return remove_magenta(cell)


def save(image: Image.Image, relative_path: str) -> None:
    path = ROOT / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)


def prepare_character_sheet(source_name: str, prefix: str) -> None:
    image = Image.open(SOURCE / source_name)
    for column in range(2):
        save(prepared_cell(image, column, 0, 4, 4, 192), f"{prefix}_idle_down_{column:02d}.png")
    for animation, row in (("move", 1), ("attack", 2), ("skill", 3)):
        for column in range(4):
            save(prepared_cell(image, column, row, 4, 4, 192), f"{prefix}_{animation}_down_{column:02d}.png")
    for column in range(2):
        down = prepared_cell(image, column + 2, 0, 4, 4, 192).rotate(90, resample=Image.Resampling.BICUBIC)
        save(down, f"{prefix}_down_{column:02d}.png")


def prepare_badges() -> None:
    names = [
        "badge_slime_gate_bulwark.png",
        "badge_slime_rescue_alchemy_gel.png",
        "badge_goblin_ambush_captain.png",
        "badge_goblin_vault_keeper.png",
        "badge_imp_flame_adept.png",
        "badge_imp_ember_shaman.png",
    ]
    image = Image.open(SOURCE / "evolution_badges_3x2.png")
    for index, name in enumerate(names):
        save(prepared_cell(image, index % 3, index // 3, 3, 2, 128), f"assets/sprites/ui/evolution/{name}")


def prepare_icons() -> None:
    names = [
        "ui_icon_gold.png", "ui_icon_mana.png", "ui_icon_food.png",
        "ui_icon_infamy.png", "ui_icon_shield.png", "ui_icon_attack.png",
        "ui_icon_survival.png", "ui_icon_trap.png", "ui_icon_direct_control.png",
    ]
    image = Image.open(SOURCE / "base_ui_icons_3x3.png")
    for index, name in enumerate(names):
        save(prepared_cell(image, index % 3, index // 3, 3, 3, 128), f"assets/sprites/ui/{name}")


def prepare_props() -> None:
    names = [
        "prop_gate_01.png", "prop_spike_floor_01.png", "prop_brazier_01.png",
        "prop_barracks_01.png", "prop_throne_01.png", "prop_treasure_pile_01.png",
        "prop_recovery_nest_01.png", "prop_build_slot_01.png", "prop_watch_post_01.png",
    ]
    image = Image.open(SOURCE / "legacy_room_props_3x3.png")
    for index, name in enumerate(names):
        save(prepared_cell(image, index % 3, index // 3, 3, 3, 128), f"assets/sprites/rooms/{name}")


def prepare_tiles() -> None:
    image = Image.open(SOURCE / "legacy_tiles_3x1.png").convert("RGB")
    bounds = ((0, 702), (746, 1426), (1470, image.width))
    names = ("tile_cave_floor_01.png", "tile_cave_wall_top_01.png", "tile_spike_floor_01.png")
    for (left, right), name in zip(bounds, names):
        width = right - left
        top = max(0, (image.height - width) // 2)
        bottom = min(image.height, top + width)
        tile = image.crop((left, top, right, bottom)).resize((64, 64), Image.Resampling.LANCZOS)
        save(tile, f"assets/sprites/tiles/{name}")


def prepare_vfx() -> None:
    image = Image.open(SOURCE / "base_vfx_4x6.png")
    names = ("fireball", "hit_slash", "fire_impact", "shield_pulse", "guard_pulse", "loot_spark")
    for row, name in enumerate(names):
        for column in range(4):
            save(prepared_cell(image, column, row, 4, 6, 128), f"assets/sprites/effects/fx_{name}_{column:02d}.png")
    ring = Image.open(SOURCE / "selection_ring_4x1.png")
    save(prepared_cell(ring, 2, 0, 4, 1, 128), "assets/sprites/effects/fx_selection_ring_00.png")


def prepare_portrait() -> None:
    portrait = Image.open(SOURCE / "shieldbearer_portrait.png").convert("RGB")
    portrait = portrait.resize((768, 768), Image.Resampling.LANCZOS)
    save(portrait, "assets/sprites/portraits/enemies/CHR_SHIELDBEARER_portrait.png")


def main() -> None:
    character_sheets = (
        ("slime_combat_4x4.png", "assets/sprites/monsters/monster_slime"),
        ("goblin_combat_4x4.png", "assets/sprites/monsters/monster_goblin"),
        ("imp_combat_4x4.png", "assets/sprites/monsters/monster_imp"),
        ("explorer_combat_4x4.png", "assets/sprites/enemies/enemy_explorer"),
        ("thief_combat_4x4.png", "assets/sprites/enemies/enemy_thief"),
        ("trainee_hero_combat_4x4.png", "assets/sprites/enemies/enemy_trainee_hero"),
        ("shieldbearer_combat_4x4.png", "assets/sprites/enemies/enemy_shieldbearer"),
        ("selen_paladin_combat_4x4.png", "assets/sprites/enemies/enemy_selen_paladin"),
    )
    for source_name, prefix in character_sheets:
        prepare_character_sheet(source_name, prefix)
    prepare_badges()
    prepare_icons()
    prepare_props()
    prepare_tiles()
    prepare_vfx()
    prepare_portrait()
    print("Prepared GPT ImageGen runtime art: 128 animation frames, 6 badges, 9 icons, 9 props, 3 tiles, 25 VFX, 1 portrait.")


if __name__ == "__main__":
    main()
