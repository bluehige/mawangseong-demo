extends RefCounted
class_name UIKitIcons
## Native-alpha GPT artwork, optimized to 64/128. Legacy atlas is isolated for U5.
const COMMON_ATLAS := "res://assets/ui/icons/v1213_common.png"
const COMMON_IDS := ["log", "settings", "menu", "auto", "skip", "close", "resume", "save", "load", "title", "quit", "reset"]
const IDS := ["settings", "log", "save", "load", "encyclopedia", "speed", "pause", "play", "skip", "auto_play", "build", "garrison", "tactics", "monster", "battle_start", "undo", "close", "info", "warning", "lock", "check", "gold", "mana", "food", "infamy", "throne", "treasury", "explorer_enemy", "watch_post_range", "experience", "hp", "language"]
const ALIASES := {"shield":"garrison", "attack":"tactics", "auto":"auto_play", "resume":"play", "menu":"settings", "title":"encyclopedia", "quit":"close", "reset":"undo", "chevron":"undo", "unchecked":"lock", "slider_grip":"mana"}
const PATHS := {"portrait":"res://assets/sprites/portraits/uiux3d/pudding_base.png", "focus":"res://assets/sprites/ui/ui_icon_direct_control.png", "spikes":"res://assets/sprites/ui/ui_icon_trap.png"}
const ACTION_IDS := {"rally":"watch_post_range", "focus":"focus", "emergency_fallback":"speed", "slime_shield":"garrison", "hold_corridor":"spikes", "rooted_guard":"garrison", "patch_plates":"garrison", "fireball":"mana", "flame_zone":"infamy", "tricolor_demonfire":"mana", "spore_mend":"hp", "cleansing_bloom":"hp", "scent_lock":"focus", "moon_mark":"focus", "vault_swap":"treasury", "false_treasure":"treasury", "royal_jelly_bastion":"garrison", "royal_shared_umbrella":"hp", "royal_emergency_plating":"garrison", "royal_urgent_courier":"speed", "night_relay":"speed", "emergency_thread_pull":"hp", "war_rhythm":"tactics", "steady_beat":"hp", "echo_alarm":"warning", "stitch_stairway":"garrison", "false_footprints":"speed", "stone_pulse":"throne", "haunted_broom_whirl":"attack", "royal_no_second_cut":"battle_start", "quick_slash":"tactics", "scent_pursuit":"focus", "loot_instinct":"gold", "rumor_boost":"log", "spectral_transfer":"speed", "home_guard_bark":"garrison", "carapace_ram":"battle_start"}
const COMBAT_REGIONS := {"settings":Rect2(18,18,94,94), "save":Rect2(17,26,85,83), "log":Rect2(24,15,91,98), "garrison":Rect2(33,19,75,92), "watch_post_range":Rect2(20,18,92,87), "speed":Rect2(25,29,88,76), "throne":Rect2(10,9,98,109), "monster":Rect2(12,20,102,98), "mana":Rect2(46,11,65,107), "tactics":Rect2(11,13,106,102)}
static var _cache: Dictionary = {}

static func get_icon(id: String, pixels: int = 48) -> Texture2D:
	var canonical: String = ALIASES.get(id, id)
	var resolution := 64 if pixels <= 48 else 128
	var key := "%s/%d" % [canonical, resolution]
	if _cache.has(key): return _cache[key]
	var texture: Texture2D
	if PATHS.has(canonical):
		texture = load(PATHS[canonical])
		if canonical in ["focus", "spikes"]:
			# Existing circular artwork: use its central detail, excluding magenta corners.
			var detail := AtlasTexture.new()
			detail.atlas = texture
			detail.region = Rect2(26,26,76,76)
			texture = detail
		if canonical == "portrait":
			var trimmed := AtlasTexture.new()
			trimmed.atlas = texture
			# Measured visible silhouette. Alpha=1 fringe spans most of the square;
			# an atlas rectangle preserves the pixels without editing/removing alpha.
			trimmed.region = Rect2(48,276,1168,789)
			texture = trimmed
	elif canonical in IDS:
		texture = load("res://assets/ui/kit/icons/icon_%s_%d.png" % [canonical, resolution])
	else:
		push_warning("UIKitIcons: unknown icon '%s'" % id)
		return null
	_cache[key] = texture
	return texture

static func action_icon(id: String) -> String:
	return str(ACTION_IDS.get(id, "tactics"))

static func get_legacy_icon(id: String) -> Texture2D:
	if not id in COMMON_IDS: return null
	var key := "legacy/" + id
	if _cache.has(key): return _cache[key]
	var sheet: Texture2D = load(COMMON_ATLAS)
	var index := COMMON_IDS.find(id)
	var cell := sheet.get_size() / Vector2(4, 3)
	var region := AtlasTexture.new()
	region.atlas = sheet
	region.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	_cache[key] = region
	return region

static func combat_icon(id: String) -> Texture2D:
	var key := "combat/"+id
	if _cache.has(key): return _cache[key]
	var texture := get_icon(id,64)
	if COMBAT_REGIONS.has(id):
		var detail := AtlasTexture.new()
		detail.atlas=texture; detail.region=COMBAT_REGIONS[id]
		texture=detail
	_cache[key]=texture
	return texture
