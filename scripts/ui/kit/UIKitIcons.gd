extends RefCounted
class_name UIKitIcons
## Native-alpha GPT artwork, optimized to 64/128. Legacy atlas is isolated for U5.
const COMMON_ATLAS := "res://assets/ui/icons/v1213_common.png"
const COMMON_IDS := ["log", "settings", "menu", "auto", "skip", "close", "resume", "save", "load", "title", "quit", "reset"]
const IDS := ["settings", "log", "save", "load", "encyclopedia", "speed", "pause", "play", "skip", "auto_play", "build", "garrison", "tactics", "monster", "battle_start", "undo", "close", "info", "warning", "lock", "check", "gold", "mana", "food", "infamy", "throne", "treasury", "explorer_enemy", "watch_post_range", "experience", "hp", "language"]
const ALIASES := {"shield":"garrison", "attack":"tactics", "auto":"auto_play", "resume":"play", "menu":"settings", "title":"encyclopedia", "quit":"close", "reset":"undo", "chevron":"undo", "unchecked":"lock", "slider_grip":"mana"}
const PATHS := {"portrait":"res://assets/sprites/portraits/uiux3d/pudding_base.png"}
static var _cache: Dictionary = {}

static func get_icon(id: String, pixels: int = 48) -> Texture2D:
	var canonical: String = ALIASES.get(id, id)
	var resolution := 64 if pixels <= 48 else 128
	var key := "%s/%d" % [canonical, resolution]
	if _cache.has(key): return _cache[key]
	var texture: Texture2D
	if PATHS.has(canonical):
		texture = load(PATHS[canonical])
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
