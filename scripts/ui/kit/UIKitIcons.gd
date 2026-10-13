extends RefCounted
class_name UIKitIcons
## Replace only this mapping when the final asset set is approved.
const COMMON_ATLAS := "res://assets/ui/icons/v1213_common.png"
const COMMON_IDS := ["log", "settings", "menu", "auto", "skip", "close", "resume", "save", "load", "title", "quit", "reset"]
const PATHS := {
	"gold": "res://assets/sprites/ui/ui_icon_gold.png",
	"mana": "res://assets/sprites/ui/ui_icon_mana.png",
	"food": "res://assets/sprites/ui/ui_icon_food.png",
	"infamy": "res://assets/sprites/ui/ui_icon_infamy.png",
	"shield": "res://assets/sprites/ui/ui_icon_shield.png",
	"attack": "res://assets/sprites/ui/ui_icon_attack.png",
	"monster": "res://assets/sprites/portraits/uiux3d/pudding_base.png",
	"portrait": "res://assets/sprites/portraits/uiux3d/pudding_base.png",
	"build": "res://assets/ui/kit/icons/build.svg",
	"check": "res://assets/ui/kit/icons/check.svg",
	"chevron": "res://assets/ui/kit/icons/chevron.svg",
	"unchecked": "res://assets/ui/kit/icons/unchecked.svg",
	"slider_grip": "res://assets/ui/kit/icons/slider_grip.svg",
}
static var _cache: Dictionary = {}

static func get_icon(id: String) -> Texture2D:
	if _cache.has(id): return _cache[id]
	var texture: Texture2D
	if PATHS.has(id):
		texture = load(PATHS[id])
	elif id in COMMON_IDS:
		var sheet: Texture2D = load(COMMON_ATLAS)
		var index := COMMON_IDS.find(id)
		var cell := sheet.get_size() / Vector2(4, 3)
		var region := AtlasTexture.new()
		region.atlas = sheet
		region.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
		texture = region
	else:
		push_warning("UIKitIcons: unknown icon '%s'" % id)
		return null
	_cache[id] = texture
	return texture
