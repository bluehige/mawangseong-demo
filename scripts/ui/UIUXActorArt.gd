extends RefCounted
static var catalog: Dictionary = {}
static func entry(path: String) -> Dictionary:
	if catalog.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/uiux_actor_art.json"))
		if parsed is Dictionary: catalog = parsed
	for value in catalog.values():
		if str(value.get("path","")) == path: return value
	return {}
static func frame(sheet: Texture2D, index: int) -> AtlasTexture:
	var info := entry(sheet.resource_path)
	var result := AtlasTexture.new()
	result.atlas = sheet
	result.filter_clip = true
	if not info.is_empty():
		var r: Array = info.regions[index]
		var m: Array = info.margins[index]
		result.region = Rect2(r[0],r[1],r[2],r[3])
		result.margin = Rect2(m[0],m[1],m[2],m[3])
		var b: Array = info.visible_bounds[index]
		result.set_meta("uiux_visible_bounds",Rect2(b[0],b[1],b[2],b[3]))
	else:
		var cell_size := sheet.get_size()/4.0
		result.region = Rect2(Vector2(index%4,index/4)*cell_size,cell_size)
	return result

static var preview_bounds: Dictionary = {}
static func visible_bounds(texture: Texture2D) -> Rect2:
	if texture.has_meta("uiux_visible_bounds"):
		return texture.get_meta("uiux_visible_bounds")
	if texture is AtlasTexture:
		return Rect2(texture.margin.position, texture.region.size)
	var key := texture.get_instance_id()
	if not preview_bounds.has(key):
		var im := texture.get_image()
		preview_bounds[key] = Rect2(im.get_used_rect()) if im != null else Rect2(Vector2.ZERO,texture.get_size())
	return preview_bounds[key]

static func preview_rect(texture: Texture2D, foot: Vector2, body_height: float) -> Rect2:
	var bounds := visible_bounds(texture)
	var factor := body_height / maxf(bounds.size.y,1.0)
	return Rect2(foot-Vector2(bounds.get_center().x,bounds.end.y)*factor,texture.get_size()*factor)
