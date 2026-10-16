extends RefCounted
## Alpha body HEIGHT, never a width-limited fit. At .75: 72 screen pixels.
const BODY_HEIGHT := 96.0
const LARGE_MULTIPLIER := 1.15
const BOSS_MULTIPLIER := 1.35
const BOSSES := ["official_hero_leon","selen_trainee_paladin","official_paladin_selen","guild_commissioner_roman"]
static var profiles: Dictionary = {}
static var alpha_bounds: Dictionary = {}
static var alpha_outlines: Dictionary = {}
static var alpha_pixels: Dictionary = {}

static func pixels(texture: Texture2D) -> Dictionary:
	var key := texture.get_instance_id()
	if not alpha_pixels.has(key):
		var image := texture.get_image(); image.convert(Image.FORMAT_RGBA8)
		alpha_pixels[key] = {"data":image.get_data(),"width":image.get_width(),"height":image.get_height()}
	return alpha_pixels[key]

static func size_class(id: String) -> String:
	if id in ["bridge_troll","hollow_armor","stone_sentinel","armored_beetle"]: return "large"
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
		# AtlasTexture.get_image() omits the transparent frame margin, while
		# AnimatedSprite2D renders it. Restore those original frame coordinates.
		if texture is AtlasTexture: alpha_bounds[key].position += texture.margin.position
	return alpha_bounds[key]

static func body_scale(bounds: Rect2, id: String = "") -> float:
	return BODY_HEIGHT/maxf(1,bounds.size.y)*multiplier(id)

static func visible_outline(texture: Texture2D) -> PackedVector2Array:
	var key := texture.get_instance_id()
	if not alpha_outlines.has(key):
		var image := pixels(texture)
		var data: PackedByteArray = image.data
		var width: int = image.width; var height: int = image.height
		var points := PackedVector2Array()
		var margin: Vector2 = texture.margin.position if texture is AtlasTexture else Vector2.ZERO
		# Exact alpha>0 support, including isolated/one-pixel tips that polygon
		# contour simplification can remove. Cache once per animation frame.
		for x in range(width):
			var top := 0; var bottom := height-1
			while top<height and data[(top*width+x)*4+3]==0: top += 1
			if top==height: continue
			while bottom>top and data[(bottom*width+x)*4+3]==0: bottom -= 1
			bottom += 1
			for point in [Vector2(x,top),Vector2(x+1,top),Vector2(x,bottom),Vector2(x+1,bottom)]: points.append(point+margin)
		alpha_outlines[key] = Geometry2D.convex_hull(points)
	return alpha_outlines[key]

static func ui_scale(id: String) -> float:
	return BODY_HEIGHT/66.0*multiplier(id)

static func depth(point: Vector2) -> int:
	return clampi(roundi(point.y),1,3500)
