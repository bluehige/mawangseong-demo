extends RefCounted
## Alpha body HEIGHT, never a width-limited fit. At .75: 72 screen pixels.
const BODY_HEIGHT := 96.0
const LARGE_MULTIPLIER := 1.15
const BOSS_MULTIPLIER := 1.35
const BOSSES := ["official_hero_leon","selen_trainee_paladin","official_paladin_selen","guild_commissioner_roman"]
static var profiles: Dictionary = {}
static var alpha_bounds: Dictionary = {}

static func size_class(id: String) -> String:
	if id in BOSSES: return "boss"
	if profiles.is_empty(): profiles = JSON.parse_string(FileAccess.get_file_as_string("res://data/v122/combat_visual_profiles.json"))
	var profile: String = profiles.unit_overrides.get(id,{}).get("profile_id",profiles.default_profile_id)
	return str(profiles.profiles.get(profile,{}).get("size_class","normal"))

static func multiplier(id: String) -> float:
	match size_class(id):
		"boss": return BOSS_MULTIPLIER
		"large": return LARGE_MULTIPLIER
	return 1.0

static func visible_bounds(texture: Texture2D) -> Rect2:
	var key := texture.get_instance_id()
	if not alpha_bounds.has(key):
		alpha_bounds[key] = Rect2(texture.get_image().get_used_rect())
	return alpha_bounds[key]

static func body_scale(bounds: Rect2, id: String = "") -> float:
	return BODY_HEIGHT/maxf(1,bounds.size.y)*multiplier(id)

static func ui_scale(id: String) -> float:
	return BODY_HEIGHT/66.0*multiplier(id)

static func depth(point: Vector2) -> int:
	return clampi(roundi(point.y),1,3500)
