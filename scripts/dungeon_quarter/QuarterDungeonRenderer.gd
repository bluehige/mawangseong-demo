extends RefCounted
class_name QuarterDungeonRenderer

const Constants = preload("res://scripts/core/Constants.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")
const AutoTileMaskScript = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const CorridorTopologyBuilderScript = preload("res://scripts/dungeon_quarter/CorridorTopologyBuilder.gd")
const QuarterDungeonWallCanvasScript = preload("res://scripts/dungeon_quarter/QuarterDungeonWallCanvas.gd")

const REQUIRED_LAYER_NAMES = [
	"BackgroundVoidLayer",
	"FloorLayer",
	"EdgeSkirtLayer",
	"BackWallLayer",
	"ObjectBackLayer",
	"UnitYSortLayer",
	"ObjectFrontLayer",
	"FrontWallLayer",
	"FxLayer",
	"UiDebugLayer"
]

const TRAP_TRIGGER_FRAME_MSEC = 110
const RENDER_PROFILE_FULL := "full"
const RENDER_PROFILE_WEB := "web"
const RENDER_PROFILE_MOBILE := "mobile"
const CORRIDOR_AUTOTILE_CELL_SIZE := Vector2(128.0, 64.0)
const CORRIDOR_AUTOTILE_MASK_COUNT := 16
const CORRIDOR_AUTOTILE_VARIANTS := ["00", "10", "01", "11"]

# 유닛과 VFX는 실제 월드 Y를 그대로 z_index로 쓰지 않는다. 월드 좌표는
# 맵의 투영 크기에 따라 달라질 수 있으므로 유한한 슬롯으로 정규화한다.
# N/W 후면 벽은 정적 맵에, E/S 전면 벽은 반투명 FrontWallLayer에 분리한다.
# 정적 바닥은 z=0이므로 모든 유닛 슬롯은 반드시 0보다 커야 한다.
const UNIT_DEPTH_MIN := 1
const UNIT_DEPTH_MAX := 44
const FRONT_WALL_DEPTH := 50

var root: Node
var floor_tile_textures: Dictionary = {}
var edge_tile_textures: Dictionary = {}
var corner_overlay_textures: Dictionary = {}
var structural_wall_textures: Dictionary = {}
var structural_wall_front_occluder_textures: Dictionary = {}
var structural_wall_asset_entries: Dictionary = {}
var background_plate_textures: Dictionary = {}
var socket_cap_textures: Dictionary = {}
var stage_spatial_textures: Dictionary = {}
var object_sprite_textures: Dictionary = {}
var trap_animation_frame_counts: Dictionary = {}
var active_trap_animations: Dictionary = {}
var trap_animation_sprites: Dictionary = {}
var missing_floor_tile_masks: Array = []
var missing_addon_tiles: Array = []
var missing_structural_wall_asset_ids: Array = []
var missing_background_plates: Array = []
var missing_socket_caps: Array = []
var missing_object_sprites: Array = []
var last_floor_masks: Dictionary = {}
var last_open_edge_set: Dictionary = {}
var last_visual_open_edge_set: Dictionary = {}
var last_visual_floor_set: Dictionary = {}
var last_wall_edge_records: Array = []
var last_wall_vertex_records: Array = []
var last_wall_chain_records: Array = []
var last_topology_errors: Array = []
var last_connection_bridge_records: Array = []
var last_room_wall_records: Array = []
var last_socket_marker_draw_targets: Dictionary = {}
var last_floor_count := 0
var cached_tile_grid: Dictionary = {}
var tile_grid_cache_valid := false
var heart_core_sprite: Sprite2D = null
var heart_chroma_shader: Shader = null
var stage01_edge_layer: CanvasLayer = null
var stage01_edge_feather: ColorRect = null
var stage01_edge_mask: NinePatchRect = null
var stage01_edge_shader: Shader = null
var stage01_world_layers_visible := true
var back_wall_canvas: Node2D = null
var object_front_canvas: Node2D = null
var front_wall_canvas: Node2D = null
var render_profile := RENDER_PROFILE_FULL
var debug_draw_invocation_count := 0
var unit_depth_world_y_range := Vector2.ZERO
var unit_depth_world_y_range_valid := false

func setup(game_root: Node) -> void:
	root = game_root
	_configure_stage01_world_texture_filter()
	render_profile = _platform_render_profile()
	_load_floor_tile_textures()
	_load_addon_tile_textures()
	_load_structural_wall_textures()
	_load_background_plate_textures()
	_load_socket_cap_textures()
	_load_stage_spatial_textures()
	_load_object_sprite_textures()
	_ensure_scene_layers()
	_ensure_stage01_edge_overlay()


## 맵은 고해상도 소품과 128px 타일을 한 화면에서 축소 합성한다.
## UI의 선명한 픽셀 가장자리는 보존하고, GameRoot 아래의 월드만 선형 밉맵 필터를 쓴다.
func _configure_stage01_world_texture_filter() -> void:
	var canvas_root := root as CanvasItem
	if canvas_root != null:
		canvas_root.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func refresh_layout() -> void:
	invalidate_layout_cache()
	_ensure_scene_layers()
	if root != null:
		root.queue_redraw()

func invalidate_layout_cache() -> void:
	cached_tile_grid.clear()
	tile_grid_cache_valid = false
	last_visual_floor_set.clear()
	last_visual_open_edge_set.clear()
	last_wall_edge_records.clear()
	last_wall_vertex_records.clear()
	last_wall_chain_records.clear()
	last_topology_errors.clear()
	last_connection_bridge_records.clear()
	last_room_wall_records.clear()
	last_socket_marker_draw_targets.clear()
	unit_depth_world_y_range = Vector2.ZERO
	unit_depth_world_y_range_valid = false
	_queue_back_wall_canvas_redraw()
	_queue_object_front_canvas_redraw()
	_queue_front_wall_canvas_redraw()

func draw() -> void:
	if root == null or root.graph == null or not root.use_quarter_module_map:
		return
	debug_draw_invocation_count += 1
	_ensure_scene_layers()
	_sync_stage01_edge_overlay()
	var tile_grid = _tile_grid_for_draw()
	if render_profile != RENDER_PROFILE_MOBILE:
		_draw_active_rock_layer(tile_grid)
	_draw_floor_layer(tile_grid)
	_draw_room_footprint_layer(tile_grid)
	_draw_corridor_path_layer(tile_grid)
	_draw_stage01_threshold_layer(tile_grid, "back")
	if root.map_editor_active:
		_draw_map_editor_planning_grid(tile_grid)
	# N/W 후면 구조벽은 바닥 위 정적 맵에 그린다. 별도 BackWallLayer(-70)에
	# 두면 GameRoot 바닥 뒤에 묻히므로, E/S 전면 벽만 별도 반투명 canvas를 쓴다.
	if render_profile != RENDER_PROFILE_MOBILE:
		_draw_edge_skirt_layer(tile_grid)
		_draw_back_wall_layer(tile_grid)
		_draw_room_wall_layer(tile_grid, "wall_back")
	_draw_socket_cap_layer(tile_grid, "back")
	_draw_connection_bridge_layer(tile_grid)
	_draw_v122_defender_connector()
	_draw_outside_approach_layer(tile_grid)
	_draw_socket_layer(tile_grid)
	_draw_object_layer(tile_grid, "back")
	_draw_room_wall_layer(tile_grid, "wall_front")
	_draw_stage01_threshold_layer(tile_grid, "front")
	_draw_connected_path_mouth_layer(tile_grid)
	_draw_outside_mouth_overlay_layer(tile_grid)
	if root.current_screen == Constants.SCREEN_MANAGEMENT:
		_draw_main_route_overlay()
		_draw_selected_module_highlight(tile_grid)
	if root.map_editor_active:
		_draw_map_editor_overlay()
	if root.debug_show_active_overlay:
		_draw_active_overlay(tile_grid)
	if root.debug_show_walkable_overlay:
		_draw_walkable_overlay(tile_grid)
	if root.debug_show_floor_mask_overlay:
		_draw_floor_mask_overlay(tile_grid)
	if root.debug_show_socket_overlay:
		_draw_socket_overlay(tile_grid)
	if root.debug_show_room_id_overlay:
		_draw_room_id_overlay(tile_grid)
	if root.debug_show_cursor_cell:
		_draw_unit_or_cursor_cell(tile_grid)
	if root.debug_show_path_overlay:
		_draw_path_overlay()

func _platform_render_profile() -> String:
	if OS.has_feature("mobile_web") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return RENDER_PROFILE_MOBILE
	if OS.has_feature("web"):
		return RENDER_PROFILE_WEB
	return RENDER_PROFILE_FULL

func debug_render_profile() -> String:
	return render_profile

func debug_set_render_profile(profile: String) -> void:
	if profile in [RENDER_PROFILE_FULL, RENDER_PROFILE_WEB, RENDER_PROFILE_MOBILE]:
		render_profile = profile

func debug_reset_draw_invocation_count() -> void:
	debug_draw_invocation_count = 0

func debug_draw_invocations() -> int:
	return debug_draw_invocation_count

func set_world_layers_visible(is_visible: bool) -> void:
	stage01_world_layers_visible = is_visible
	for layer_name in REQUIRED_LAYER_NAMES:
		var layer = root.get_node_or_null(layer_name) if root != null else null
		if layer is CanvasItem:
			layer.visible = is_visible
	if heart_core_sprite != null and not is_visible:
		heart_core_sprite.visible = false
	_sync_stage01_edge_overlay()
	if is_visible:
		_queue_back_wall_canvas_redraw()
		_queue_object_front_canvas_redraw()
		_queue_front_wall_canvas_redraw()

func _tile_grid_for_draw() -> Dictionary:
	if tile_grid_cache_valid:
		return cached_tile_grid
	cached_tile_grid = _build_tile_grid()
	tile_grid_cache_valid = true
	return cached_tile_grid

func has_module_visuals() -> bool:
	return false

func uses_tile_grid_renderer() -> bool:
	return true

func uses_tile_map_layers() -> bool:
	return false

func debug_loaded_visual_count() -> int:
	return 0

func has_floor_tile_textures() -> bool:
	return floor_tile_textures.size() >= 16

func debug_loaded_floor_tile_count() -> int:
	return floor_tile_textures.size()

func debug_missing_floor_tile_masks() -> Array:
	return missing_floor_tile_masks.duplicate()

func has_addon_tile_textures() -> bool:
	return edge_tile_textures.size() >= 4 and corner_overlay_textures.size() >= 8

func debug_loaded_addon_tile_count() -> int:
	return edge_tile_textures.size() + corner_overlay_textures.size()

func debug_missing_addon_tiles() -> Array:
	return missing_addon_tiles.duplicate()

func has_stage01_spatial_textures() -> bool:
	return (
		_has_stage01_corridor_visual()
		and stage_spatial_textures.has("stage_01_cave:threshold:N")
		and stage_spatial_textures.has("stage_01_cave:threshold:E")
		and stage_spatial_textures.has("stage_01_cave:threshold:S")
		and stage_spatial_textures.has("stage_01_cave:threshold:W")
		and stage_spatial_textures.has("stage_01_cave:occlusion")
		and stage_spatial_textures.has("stage_01_cave:edge_mask")
	)

func has_stage01_corridor_autotile_texture() -> bool:
	return stage_spatial_textures.has("stage_01_cave:corridor_autotile_atlas")

func _has_stage01_corridor_visual() -> bool:
	return (
		has_stage01_corridor_autotile_texture()
		or (
			stage_spatial_textures.has("stage_01_cave:corridor:00")
			and stage_spatial_textures.has("stage_01_cave:corridor:10")
			and stage_spatial_textures.has("stage_01_cave:corridor:01")
			and stage_spatial_textures.has("stage_01_cave:corridor:11")
		)
	)

func debug_stage01_spatial_texture_count() -> int:
	var count := 0
	for key in stage_spatial_textures.keys():
		if str(key).begins_with("stage_01_cave:"):
			count += 1
	return count

func has_corner_overlay_textures() -> bool:
	return corner_overlay_textures.size() >= 8

func debug_loaded_corner_overlay_count() -> int:
	return corner_overlay_textures.size()

func has_structural_wall_kit() -> bool:
	if not missing_structural_wall_asset_ids.is_empty() or _active_structural_wall_set().is_empty():
		return false
	for side in ["N", "E", "S", "W"]:
		if _structural_edge_slot(side).is_empty():
			return false
	var required_vertex_orientations := {
		"corner": ["NE", "ES", "SW", "WN"],
		"cap": ["N", "E", "S", "W"],
		"junction": ["NEW", "NES", "ESW", "NSW"]
	}
	for kind in required_vertex_orientations.keys():
		for orientation in required_vertex_orientations[kind]:
			if _structural_vertex_asset_id(str(kind), str(orientation)) == "":
				return false
	return true

func debug_missing_structural_wall_asset_ids() -> Array:
	return missing_structural_wall_asset_ids.duplicate()

func debug_active_wall_kit_id() -> String:
	return str(_active_spatial_profile().get("wall_kit_id", ""))

func debug_active_boundary_marker_set_id() -> String:
	return str(_active_structural_wall_set().get("marker_set", ""))

func has_background_plate_textures() -> bool:
	return not background_plate_textures.is_empty()

func debug_missing_background_plates() -> Array:
	return missing_background_plates.duplicate()

func has_socket_cap_textures() -> bool:
	# 닫힌 socket은 구조 벽 자체가 막는다. 별도 장식 cap은 로드하지 않는다.
	return not socket_cap_textures.is_empty()

func debug_loaded_socket_cap_count() -> int:
	return socket_cap_textures.size()

func debug_missing_socket_caps() -> Array:
	return missing_socket_caps.duplicate()

func debug_socket_marker_draw_target(state: String, side: String) -> String:
	return str(last_socket_marker_draw_targets.get(_socket_cap_key(state, side), ""))

func debug_socket_cap_key(instance_id: String, socket_id: String) -> String:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			var state = str(socket.get("state", "closed"))
			var side = str(socket.get("side", ""))
			var key = _socket_cap_key(state, side)
			return key if socket_cap_textures.has(key) else ""
	return ""

func debug_socket_state(instance_id: String, socket_id: String) -> String:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return str(socket.get("state", ""))
	return ""

func has_object_sprite_textures() -> bool:
	return object_sprite_textures.size() > 0

func debug_loaded_object_sprite_count() -> int:
	return object_sprite_textures.size()

func debug_missing_object_sprites() -> Array:
	return missing_object_sprites.duplicate()

func debug_object_texture_key(instance_id: String, layer_name: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) != instance_id:
			continue
		var slot_id = str(slot.get("id", ""))
		var key = _object_texture_key_for_layer(slot, slot_id, layer_name)
		if key != "":
			return key
	return ""

func debug_object_facing(instance_id: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) == instance_id:
			return str(slot.get("facing", ""))
	return ""

func debug_object_connection_variant(instance_id: String) -> String:
	if root == null or root.graph == null:
		return ""
	var tile_grid = _build_tile_grid()
	for slot in tile_grid.get("objects", []):
		if str(slot.get("instance_id", "")) == instance_id:
			return str(slot.get("connection_variant", ""))
	return ""

func debug_active_castle_art_stage() -> String:
	return _active_castle_art_stage()

func trigger_trap_animation(instance_id: String, trap_id: String) -> void:
	if _trap_animation_frame_count(trap_id, "trigger") <= 0:
		return
	var animation_key := _trap_animation_key(instance_id, trap_id)
	active_trap_animations[animation_key] = Time.get_ticks_msec()
	_spawn_trap_animation_sprite(instance_id, trap_id, animation_key)

func clear_trap_animations() -> void:
	active_trap_animations.clear()
	for sprite_value in trap_animation_sprites.values():
		var sprite := sprite_value as AnimatedSprite2D
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()
	trap_animation_sprites.clear()

func debug_active_trap_animation_count() -> int:
	_prune_finished_trap_animations()
	return active_trap_animations.size()

func debug_active_trap_sprite_count() -> int:
	var count := 0
	for sprite_value in trap_animation_sprites.values():
		if sprite_value is AnimatedSprite2D and is_instance_valid(sprite_value):
			count += 1
	return count

func debug_current_trap_texture_key(instance_id: String, trap_id: String) -> String:
	return _active_trap_texture_key(instance_id, trap_id)

func debug_visual_variant_key(instance_id: String) -> String:
	var sides: Array = []
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("state", "")) == "connected":
			sides.append(str(socket.get("side", "")).to_lower())
	sides.sort()
	return "closed" if sides.is_empty() else "_".join(sides)

func debug_floor_cell_count() -> int:
	if last_floor_count == 0:
		_build_tile_grid()
	return last_floor_count

func debug_connection_bridge_count() -> int:
	_build_tile_grid()
	return last_connection_bridge_records.size()

func debug_connection_bridge_group_count() -> int:
	_build_tile_grid()
	var groups: Dictionary = {}
	for record in last_connection_bridge_records:
		groups[str(record.get("group_key", ""))] = true
	return groups.size()

func debug_outside_approach_cell_count() -> int:
	if root == null or root.graph == null:
		return 0
	var tile_grid = _build_tile_grid()
	var count := 0
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) == "outside_approach":
			count += 1
	return count

func debug_full_grid_room_projection_count() -> int:
	if root == null or root.graph == null:
		return 0
	var tile_grid = _build_tile_grid()
	var count := 0
	for slot in tile_grid.get("objects", []):
		if _is_full_grid_room_slot(slot):
			count += 1
	return count

func debug_room_wall_segment_count(state_filter: String = "") -> int:
	_build_tile_grid()
	var count := 0
	for record in last_room_wall_records:
		if state_filter == "" or str(record.get("state", "")) == state_filter:
			count += 1
	return count

func debug_object_uses_projection_safe_connection_sprite(instance_id: String, layer_name: String) -> bool:
	if root == null or root.graph == null:
		return false
	var texture_key = debug_object_texture_key(instance_id, layer_name)
	return _object_texture_uses_projection_safe_room_sprite(texture_key)

func debug_floor_mask_values() -> Array:
	if last_floor_masks.is_empty():
		_build_tile_grid()
	var values: Array = []
	for mask in last_floor_masks.values():
		if not values.has(mask):
			values.append(mask)
	values.sort()
	return values

func debug_wall_mask_values() -> Array:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	var values: Array = []
	for record in last_wall_edge_records:
		var key = str(record.get("texture_key", ""))
		if key != "" and not values.has(key):
			values.append(key)
	values.sort()
	return values

func debug_wall_cell_count() -> int:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	return last_wall_edge_records.size()

func debug_wall_edge_records() -> Array:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	return last_wall_edge_records.duplicate(true)


func debug_structural_wall_draw_rect(record: Dictionary) -> Rect2:
	var asset_id := str(record.get("structural_asset_id", ""))
	var texture := structural_wall_textures.get(asset_id, null) as Texture2D
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	if texture == null or str(entry.get("piece_kind", "")) != "edge_segment":
		return Rect2()
	return _structural_edge_draw_rect(texture, entry, record)


func debug_structural_wall_overlap_sample(record: Dictionary) -> Dictionary:
	var asset_id := str(record.get("structural_asset_id", ""))
	var texture := structural_wall_textures.get(asset_id, null) as Texture2D
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	if texture == null or str(entry.get("piece_kind", "")) != "edge_segment":
		return {}
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return {}
	var draw_rect := _structural_edge_draw_rect(texture, entry, record)
	if draw_rect.size.x <= 0.0 or draw_rect.size.y <= 0.0:
		return {}
	var image_size := Vector2(image.get_width(), image.get_height())
	var target := image_size * Vector2(0.5, 0.58)
	var step := maxi(1, int(minf(image_size.x, image_size.y) / 64.0))
	var best_pixel := Vector2i(-1, -1)
	var best_alpha := 0.0
	var best_distance := INF
	var min_x := clampi(int(image_size.x * 0.16), 0, image.get_width() - 1)
	var max_x := clampi(int(image_size.x * 0.84), min_x + 1, image.get_width())
	var min_y := clampi(int(image_size.y * 0.18), 0, image.get_height() - 1)
	var max_y := clampi(int(image_size.y * 0.88), min_y + 1, image.get_height())
	for y in range(min_y, max_y, step):
		for x in range(min_x, max_x, step):
			var alpha: float = image.get_pixel(x, y).a
			if alpha < 0.75:
				continue
			var distance := Vector2(x + 0.5, y + 0.5).distance_squared_to(target)
			if distance < best_distance:
				best_pixel = Vector2i(x, y)
				best_alpha = alpha
				best_distance = distance
	if best_pixel.x < 0:
		return {}
	var source_point := Vector2(best_pixel) + Vector2(0.5, 0.5)
	var world_point := draw_rect.position + source_point / image_size * draw_rect.size
	return {
		"draw_rect": draw_rect,
		"world_point": world_point,
		"source_pixel": best_pixel,
		"source_alpha": best_alpha
	}


func debug_structural_wall_source_alpha_at(record: Dictionary, world_position: Vector2) -> float:
	var asset_id := str(record.get("structural_asset_id", ""))
	var texture := structural_wall_textures.get(asset_id, null) as Texture2D
	if texture == null:
		return 0.0
	var draw_rect := debug_structural_wall_draw_rect(record)
	if draw_rect.size.x <= 0.0 or draw_rect.size.y <= 0.0 or not draw_rect.has_point(world_position):
		return 0.0
	var image: Image = texture.get_image()
	if image == null or image.is_empty():
		return 0.0
	var uv := (world_position - draw_rect.position) / draw_rect.size
	var pixel := Vector2i(
		clampi(floori(uv.x * image.get_width()), 0, image.get_width() - 1),
		clampi(floori(uv.y * image.get_height()), 0, image.get_height() - 1)
	)
	return image.get_pixelv(pixel).a

func debug_wall_edge_key_for_cell(cell: Vector2i, side: String) -> String:
	if last_wall_edge_records.is_empty():
		_build_tile_grid()
	for record in last_wall_edge_records:
		if record.get("cell", Vector2i.ZERO) == cell and str(record.get("side", "")) == side:
			return str(record.get("texture_key", ""))
	return ""

func debug_visual_mask_for_socket(instance_id: String, socket_id: String) -> int:
	for socket in root.graph.debug_socket_cells():
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return root.graph.debug_floor_mask(socket.get("cell", Vector2i.ZERO))
	return -1

func debug_visual_mask_for_global_cell(cell: Vector2i) -> int:
	return root.graph.debug_floor_mask(cell)

func debug_render_mask_for_global_cell(cell: Vector2i) -> int:
	_tile_grid_for_draw()
	return int(last_floor_masks.get(cell, -1))

func debug_visual_floor_cells() -> Dictionary:
	_tile_grid_for_draw()
	return last_visual_floor_set.duplicate(true)

func debug_visual_edge_open(cell: Vector2i, side: String) -> bool:
	_tile_grid_for_draw()
	return last_visual_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

func debug_wall_vertex_records() -> Array:
	_tile_grid_for_draw()
	return last_wall_vertex_records.duplicate(true)

func debug_wall_chain_records() -> Array:
	_tile_grid_for_draw()
	return last_wall_chain_records.duplicate(true)

func debug_corridor_topology_errors() -> Array:
	_tile_grid_for_draw()
	return last_topology_errors.duplicate(true)

func debug_active_spatial_profile() -> Dictionary:
	return _active_spatial_profile().duplicate(true)

func debug_edge_open(cell: Vector2i, side: String) -> bool:
	if last_open_edge_set.is_empty():
		_build_tile_grid()
	return last_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

func debug_layer_names() -> Array:
	return REQUIRED_LAYER_NAMES.duplicate()

func debug_tilemap_layer_names() -> Array:
	var names: Array = []
	for layer_name in REQUIRED_LAYER_NAMES:
		if root.get_node_or_null(layer_name) != null:
			names.append(layer_name)
	return names

func unit_depth_slot_bounds() -> Vector2i:
	return Vector2i(UNIT_DEPTH_MIN, UNIT_DEPTH_MAX)

func front_wall_depth() -> int:
	return FRONT_WALL_DEPTH

func debug_depth_world_y_range() -> Vector2:
	return _unit_depth_world_y_range()

func unit_depth_slot_for_position(world_position: Vector2) -> int:
	var y_range := _unit_depth_world_y_range()
	var normalized := 0.0
	if y_range.y > y_range.x:
		normalized = clampf(inverse_lerp(y_range.x, y_range.y, world_position.y), 0.0, 1.0)
	return clampi(
		roundi(lerpf(float(UNIT_DEPTH_MIN), float(UNIT_DEPTH_MAX), normalized)),
		UNIT_DEPTH_MIN,
		UNIT_DEPTH_MAX
	)

func debug_depth_contract() -> Dictionary:
	return {
		"unit_depth_min": UNIT_DEPTH_MIN,
		"unit_depth_max": UNIT_DEPTH_MAX,
		"static_floor_depth": 0,
		"front_wall_depth": FRONT_WALL_DEPTH,
		"back_wall_sides": ["N", "W"],
		"front_wall_sides": ["E", "S"],
		"front_wall_occluder": "translucent_full_body",
		"front_wall_alpha": _front_wall_alpha(),
		"structural_wall_actor_policy": "rear_opaque_front_translucent",
		"unit_depth_policy": "above_static_floor_below_front_wall",
		"vfx_connection_state": "LIVE_DEPTH_CONNECTED"
	}

func _unit_depth_world_y_range() -> Vector2:
	if unit_depth_world_y_range_valid:
		return unit_depth_world_y_range
	var minimum := INF
	var maximum := -INF
	var graph = root.get("graph") if root != null else null
	if graph != null and graph.has_method("debug_walkable_rects"):
		for rect_value in graph.debug_walkable_rects():
			if not rect_value is Rect2:
				continue
			var rect: Rect2 = rect_value
			minimum = minf(minimum, rect.position.y)
			maximum = maxf(maximum, rect.end.y)
	if minimum == INF or maximum <= minimum:
		var viewport_rect: Rect2 = root.get_viewport_rect() if root != null else Rect2(0, 0, 1920, 1080)
		minimum = viewport_rect.position.y
		maximum = viewport_rect.end.y
	if maximum <= minimum:
		maximum = minimum + 1.0
	unit_depth_world_y_range = Vector2(minimum, maximum)
	unit_depth_world_y_range_valid = true
	return unit_depth_world_y_range

func _ensure_scene_layers() -> void:
	_ensure_background_layer()
	for layer_name in REQUIRED_LAYER_NAMES:
		if layer_name == "BackgroundVoidLayer":
			continue
		if layer_name == "UnitYSortLayer" and root.unit_root != null:
			root.unit_root.name = "UnitYSortLayer"
			root.unit_root.y_sort_enabled = true
			continue
		if layer_name == "FxLayer" and root.effect_root != null:
			root.effect_root.name = "FxLayer"
			continue
		if root.get_node_or_null(layer_name) == null:
			var node := Node2D.new()
			node.name = layer_name
			node.z_index = _layer_z(layer_name)
			if layer_name == "UnitYSortLayer":
				node.y_sort_enabled = true
			root.add_child(node)
	_ensure_back_wall_canvas()
	_ensure_object_front_canvas()
	_ensure_front_wall_canvas()


func _ensure_back_wall_canvas() -> void:
	var layer := root.get_node_or_null("BackWallLayer") as Node2D
	if layer == null:
		return
	back_wall_canvas = layer.get_node_or_null("CorridorBackWallCanvas") as Node2D
	if back_wall_canvas == null:
		back_wall_canvas = QuarterDungeonWallCanvasScript.new()
		back_wall_canvas.name = "CorridorBackWallCanvas"
		layer.add_child(back_wall_canvas)
	back_wall_canvas.setup(self, "wall_back")


func _ensure_front_wall_canvas() -> void:
	var layer := root.get_node_or_null("FrontWallLayer") as Node2D
	if layer == null:
		return
	front_wall_canvas = layer.get_node_or_null("CorridorFrontWallCanvas") as Node2D
	if front_wall_canvas == null:
		front_wall_canvas = QuarterDungeonWallCanvasScript.new()
		front_wall_canvas.name = "CorridorFrontWallCanvas"
		layer.add_child(front_wall_canvas)
	front_wall_canvas.setup(self, "wall_front")


func _ensure_object_front_canvas() -> void:
	var layer := root.get_node_or_null("ObjectFrontLayer") as Node2D
	if layer == null:
		return
	object_front_canvas = layer.get_node_or_null("DungeonObjectFrontCanvas") as Node2D
	if object_front_canvas == null:
		object_front_canvas = QuarterDungeonWallCanvasScript.new()
		object_front_canvas.name = "DungeonObjectFrontCanvas"
		layer.add_child(object_front_canvas)
	object_front_canvas.setup(self, "object_front")


func _queue_front_wall_canvas_redraw() -> void:
	if front_wall_canvas != null and is_instance_valid(front_wall_canvas):
		front_wall_canvas.queue_redraw()


func _queue_object_front_canvas_redraw() -> void:
	if object_front_canvas != null and is_instance_valid(object_front_canvas):
		object_front_canvas.queue_redraw()


func _queue_back_wall_canvas_redraw() -> void:
	if back_wall_canvas != null and is_instance_valid(back_wall_canvas):
		back_wall_canvas.queue_redraw()


func draw_wall_canvas_layer(draw_target: CanvasItem, wall_layer_name: String) -> void:
	if (
		root == null
		or root.graph == null
		or not root.use_quarter_module_map
		or not stage01_world_layers_visible
	):
		return
	# 후면 본체는 GameRoot 정적 draw에서 바닥 위에 그린다. 전면 본체만
	# FrontWallLayer에 반투명으로 그려 캐릭터를 가리면서도 식별 가능하게 한다.
	if wall_layer_name == "wall_front":
		_draw_front_wall_layer(_tile_grid_for_draw(), draw_target)
	elif wall_layer_name == "object_front":
		if heart_core_sprite != null:
			heart_core_sprite.visible = false
		_draw_object_layer(_tile_grid_for_draw(), "front", draw_target)
	elif wall_layer_name == "wall_back":
		return


func debug_wall_canvas_contract() -> Dictionary:
	var back_layer := root.get_node_or_null("BackWallLayer") as Node2D if root != null else null
	var object_front_layer := root.get_node_or_null("ObjectFrontLayer") as Node2D if root != null else null
	var front_layer := root.get_node_or_null("FrontWallLayer") as Node2D if root != null else null
	return {
		"back_canvas_name": str(back_wall_canvas.name) if back_wall_canvas != null else "",
		"object_front_canvas_name": str(object_front_canvas.name) if object_front_canvas != null else "",
		"front_canvas_name": str(front_wall_canvas.name) if front_wall_canvas != null else "",
		"back_parent_z": int(back_layer.z_index) if back_layer != null else 999,
		"object_front_parent_z": int(object_front_layer.z_index) if object_front_layer != null else -999,
		"front_parent_z": int(front_layer.z_index) if front_layer != null else -999,
		"static_draw_scope": "rear_structural_wall_body_before_objects",
		"object_front_draw_scope": "front_props_at_depth_30",
		"front_draw_scope": "translucent_full_body_above_actors"
	}

func _ensure_background_layer() -> void:
	var layer = root.get_node_or_null("BackgroundVoidLayer")
	if layer == null:
		layer = Control.new()
		layer.name = "BackgroundVoidLayer"
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.z_index = -300
		root.add_child(layer)

	var full = layer.get_node_or_null("FullBackdrop") as ColorRect
	if full == null:
		full = ColorRect.new()
		full.name = "FullBackdrop"
		full.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(full)
	full.position = Vector2.ZERO
	full.size = Vector2(1920, 1080)
	full.color = Color("#050507")

	var panel = layer.get_node_or_null("DungeonBackdrop") as ColorRect
	if panel == null:
		panel = ColorRect.new()
		panel.name = "DungeonBackdrop"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(panel)
	panel.position = Vector2(330, 78)
	panel.size = Vector2(1198, 804)
	panel.color = Color("#08070c")

	var plate = layer.get_node_or_null("DungeonBackgroundPlate") as TextureRect
	if plate == null:
		plate = TextureRect.new()
		plate.name = "DungeonBackgroundPlate"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		layer.add_child(plate)
	plate.position = Vector2(330, 78)
	plate.size = Vector2(1198, 804)
	var background_id := str(_active_spatial_profile().get("background_id", "bg_cave_f_3x3_01"))
	plate.texture = background_plate_textures.get(background_id, background_plate_textures.get("bg_cave_f_3x3_01", null))
	plate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	plate.modulate = _active_profile_color("background_modulate", Color(1, 1, 1, 0.82))

func _ensure_stage01_edge_overlay() -> void:
	if root == null:
		return
	if stage01_edge_layer == null or not is_instance_valid(stage01_edge_layer):
		stage01_edge_layer = CanvasLayer.new()
		stage01_edge_layer.name = "CastleStageEdgeLayer"
		stage01_edge_layer.layer = 0
		root.add_child(stage01_edge_layer)
	if stage01_edge_feather == null or not is_instance_valid(stage01_edge_feather):
		stage01_edge_feather = ColorRect.new()
		stage01_edge_feather.name = "CavernEdgeFeather"
		stage01_edge_feather.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage01_edge_feather.color = Color.WHITE
		stage01_edge_feather.z_index = -1
		stage01_edge_layer.add_child(stage01_edge_feather)
		var material := ShaderMaterial.new()
		if stage01_edge_shader == null:
			stage01_edge_shader = Shader.new()
			stage01_edge_shader.code = (
				"shader_type canvas_item;\n"
				+ "uniform vec4 feather_color : source_color = vec4(0.16, 0.10, 0.23, 0.18);\n"
				+ "uniform float feather_width = 0.105;\n"
				+ "void fragment(){\n"
				+ "  float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));\n"
				+ "  float alpha = (1.0 - smoothstep(0.0, feather_width, edge_distance)) * feather_color.a;\n"
				+ "  COLOR = vec4(feather_color.rgb, alpha);\n"
				+ "}\n"
			)
		material.shader = stage01_edge_shader
		stage01_edge_feather.material = material
	if stage01_edge_mask == null or not is_instance_valid(stage01_edge_mask):
		stage01_edge_mask = NinePatchRect.new()
		stage01_edge_mask.name = "CavernEdgeMask"
		stage01_edge_mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage01_edge_layer.add_child(stage01_edge_mask)
	stage01_edge_mask.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _sync_stage01_edge_overlay() -> void:
	_ensure_stage01_edge_overlay()
	if stage01_edge_layer == null:
		return
	var visual_id := _active_stage_visual_id()
	var stage_visuals := _stage_spatial_visuals(visual_id)
	var edge_config: Dictionary = stage_visuals.get("cavern_edge_mask", {})
	var edge_texture = stage_spatial_textures.get("%s:edge_mask" % visual_id, null)
	var active: bool = (
		stage01_world_layers_visible
		and visual_id != ""
		and edge_texture is Texture2D
		and root != null
		and root.use_quarter_module_map
		and [Constants.SCREEN_MANAGEMENT, Constants.SCREEN_COMBAT].has(root.current_screen)
	)
	stage01_edge_layer.visible = active
	if not active:
		return
	var viewport_size: Vector2 = root.get_viewport_rect().size
	stage01_edge_feather.position = Vector2.ZERO
	stage01_edge_feather.size = viewport_size
	stage01_edge_mask.position = Vector2.ZERO
	stage01_edge_mask.size = viewport_size
	stage01_edge_mask.texture = edge_texture
	var margin := int(edge_config.get("patch_margin", 256))
	stage01_edge_mask.patch_margin_left = margin
	stage01_edge_mask.patch_margin_top = margin
	stage01_edge_mask.patch_margin_right = margin
	stage01_edge_mask.patch_margin_bottom = margin
	stage01_edge_mask.draw_center = bool(edge_config.get("draw_center", false))
	var material := stage01_edge_feather.material as ShaderMaterial
	if material != null:
		material.set_shader_parameter("feather_color", Color(str(edge_config.get("feather_color", "#291b3b38"))))
		material.set_shader_parameter("feather_width", float(edge_config.get("feather_width", 0.105)))

func _layer_z(layer_name: String) -> int:
	match layer_name:
		"FloorLayer":
			return -100
		"EdgeSkirtLayer":
			return -90
		"BackWallLayer":
			return -70
		"ObjectBackLayer":
			return -40
		"UnitYSortLayer":
			return 0
		"ObjectFrontLayer":
			return 30
		"FrontWallLayer":
			return 50
		"FxLayer":
			return 70
		"UiDebugLayer":
			return 200
	return 0

func _build_tile_grid() -> Dictionary:
	var cells: Array = []
	var active_cells: Dictionary = root.graph.debug_active_cells()
	var cell_data: Dictionary = root.graph.debug_cell_data()
	var floor_set: Dictionary = root.graph.debug_floor_cells()
	var walk_set: Dictionary = root.graph.debug_walk_cells()
	var blocked_set: Dictionary = root.graph.debug_tile_blocked_cells()
	var sockets = root.graph.debug_socket_cells()
	last_floor_masks.clear()
	last_open_edge_set = root.graph.debug_open_edge_set()
	var visual_topology := CorridorTopologyBuilderScript.build(
		floor_set,
		last_open_edge_set,
		cell_data,
		sockets,
		_build_visual_topology_patches()
	)
	last_visual_floor_set = visual_topology.get("visual_floor_set", floor_set).duplicate(true)
	last_visual_open_edge_set = visual_topology.get("visual_open_edges", last_open_edge_set).duplicate(true)
	var visual_only_cells: Dictionary = visual_topology.get("visual_only_cells", {})
	var visual_cell_data: Dictionary = visual_topology.get("cell_data", cell_data)
	var mask_by_cell: Dictionary = visual_topology.get("mask_by_cell", {})
	last_topology_errors = visual_topology.get("errors", []).duplicate(true)
	last_wall_chain_records = visual_topology.get("wall_chains", []).duplicate(true)
	last_floor_count = floor_set.size()
	var render_cells := active_cells.duplicate(true)
	for cell in visual_only_cells.keys():
		render_cells[cell] = true
	for cell in render_cells.keys():
		var data: Dictionary = visual_cell_data.get(cell, {}).duplicate(true)
		var mask := int(mask_by_cell.get(cell, -1))
		if mask >= 0:
			last_floor_masks[cell] = mask
		cells.append({
			"global_cell": cell,
			"rect": root.graph.tile_cell_rect(cell).grow(-2.0),
			"data": data,
			"mask": mask
		})
	cells.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["global_cell"]
		var cb: Vector2i = b["global_cell"]
		if ca.x + ca.y == cb.x + cb.y:
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	last_connection_bridge_records = _build_connection_bridge_records(sockets)
	last_room_wall_records = _build_room_wall_records(root.graph.debug_object_slots(), sockets)
	last_wall_edge_records = _build_wall_edge_records(visual_topology.get("boundary_edges", []))
	last_wall_vertex_records = _build_wall_vertex_records(
		visual_topology.get("wall_vertices", []),
		last_wall_edge_records
	)
	return {
		"cells": cells,
		"floor_set": last_visual_floor_set,
		"walk_set": walk_set,
		"blocked_set": blocked_set,
		"active_set": active_cells,
		"open_edge_set": last_visual_open_edge_set,
		"sockets": sockets,
		"objects": root.graph.debug_object_slots(),
		"wall_edges": last_wall_edge_records,
		"wall_vertices": last_wall_vertex_records,
		"wall_chains": last_wall_chain_records,
		"room_walls": last_room_wall_records,
		"connection_bridges": last_connection_bridge_records
	}

func _build_visual_topology_patches() -> Array:
	var patches: Array = []
	if _active_castle_art_stage() != "stage_01_cave":
		return patches
	var connector := _v122_defender_connector_data()
	if not bool(connector.get("built", false)):
		return patches
	var connector_cells := _v122_defender_connector_cells(connector)
	if connector_cells.is_empty():
		return patches
	var min_y := connector_cells[0].y
	var max_y := connector_cells[0].y
	for cell in connector_cells:
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)
	var external_openings: Array = []
	for cell in connector_cells:
		if cell.y == min_y:
			external_openings.append({"cell": cell, "side": "N"})
		if cell.y == max_y:
			external_openings.append({"cell": cell, "side": "S"})
	patches.append({
		"id": str(connector.get("connector_id", "rear_cross_lane_connector")),
		"cells": connector_cells,
		"cell_data": {
			"active": true,
			"cell_type": "floor",
			"walkable": false,
			"room_id": str(connector.get("connector_id", "rear_cross_lane_connector")),
			"is_corridor": true,
			"visual_only": true,
			"defender_only": true,
			"has_socket": false,
			"socket_state": "none"
		},
		"external_openings": external_openings
	})
	return patches

func _build_room_wall_records(objects: Array, sockets: Array) -> Array:
	var records: Array = []
	var connected_socket_edges = _connected_socket_edge_set(sockets)
	for slot in objects:
		if not _is_full_grid_room_slot(slot):
			continue
		var instance_id = str(slot.get("instance_id", ""))
		var cells = _object_footprint_cells(slot)
		var cell_set: Dictionary = {}
		for cell in cells:
			cell_set[cell] = true
		for cell in cells:
			var rect = root.graph.tile_cell_rect(cell)
			for side in ["N", "E", "S", "W"]:
				if cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
					continue
				var edge_key = AutoTileMaskScript.edge_key(cell, side)
				var state = "door" if connected_socket_edges.has("%s|%s" % [instance_id, edge_key]) else "wall"
				records.append({
					"instance_id": instance_id,
					"slot_id": str(slot.get("id", "")),
					"cell": cell,
					"side": side,
					"state": state,
					"layer": _wall_render_layer(side),
					"rect": rect
				})
	records.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["cell"]
		var cb: Vector2i = b["cell"]
		if ca.x + ca.y == cb.x + cb.y:
			if ca.x == cb.x:
				return _side_sort_index(str(a["side"])) < _side_sort_index(str(b["side"]))
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	return records

func _connected_socket_edge_set(sockets: Array) -> Dictionary:
	var result: Dictionary = {}
	for socket in sockets:
		if str(socket.get("state", "")) != "connected":
			continue
		var instance_id = str(socket.get("instance_id", ""))
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var side = str(socket.get("side", ""))
		result["%s|%s" % [instance_id, AutoTileMaskScript.edge_key(cell, side)]] = true
	return result

func _build_connection_bridge_records(sockets: Array) -> Array:
	var records: Array = []
	for pair in root.graph.connection_pairs():
		var from_socket = _socket_record_for_ref(sockets, str(pair.get("from_instance", "")), str(pair.get("from_socket", "")))
		var to_socket = _socket_record_for_ref(sockets, str(pair.get("to_instance", "")), str(pair.get("to_socket", "")))
		if from_socket.is_empty() or to_socket.is_empty():
			continue
		if str(from_socket.get("state", "")) != "connected" or str(to_socket.get("state", "")) != "connected":
			continue
		var from_cell: Vector2i = from_socket.get("cell", Vector2i.ZERO)
		var to_cell: Vector2i = to_socket.get("cell", Vector2i.ZERO)
		var from_rect = root.graph.tile_cell_rect(from_cell).grow(-4.0)
		var to_rect = root.graph.tile_cell_rect(to_cell).grow(-4.0)
		records.append({
			"from_instance": str(pair.get("from_instance", "")),
			"from_socket": str(pair.get("from_socket", "")),
			"from_side": str(from_socket.get("side", "")),
			"from_cell": from_cell,
			"from_rect": from_rect,
			"to_instance": str(pair.get("to_instance", "")),
			"to_socket": str(pair.get("to_socket", "")),
			"to_side": str(to_socket.get("side", "")),
			"to_cell": to_cell,
			"to_rect": to_rect,
			"start": from_rect.get_center(),
			"end": to_rect.get_center(),
			"cell_height": minf(from_rect.size.y, to_rect.size.y),
			"group_key": _connection_bridge_group_key(pair, from_socket, to_socket)
		})
	return records

func _connection_bridge_group_key(pair: Dictionary, from_socket: Dictionary, to_socket: Dictionary) -> String:
	var a = "%s:%s" % [str(pair.get("from_instance", "")), str(from_socket.get("side", ""))]
	var b = "%s:%s" % [str(pair.get("to_instance", "")), str(to_socket.get("side", ""))]
	var values = [a, b]
	values.sort()
	return "%s|%s" % [values[0], values[1]]

func _build_wall_edge_records(topology_edges: Array) -> Array:
	var records: Array = []
	for topology_edge_value in topology_edges:
		if not topology_edge_value is Dictionary:
			continue
		var topology_edge: Dictionary = topology_edge_value
		var cell: Vector2i = topology_edge.get("cell", Vector2i.ZERO)
		var side := str(topology_edge.get("side", ""))
		var raw_rect: Rect2 = root.graph.tile_cell_rect(cell)
		var points := _edge_points(_diamond(raw_rect), side)
		if points.size() < 2:
			continue
		var edge_record := topology_edge.duplicate(true)
		var state := str(edge_record.get("state", "closed"))
		var join_start := bool(edge_record.get("join_start", false))
		var join_end := bool(edge_record.get("join_end", false))
		edge_record["rect"] = raw_rect
		edge_record["start"] = points[0]
		edge_record["end"] = points[1]
		# 기존 texture variant 이름과의 호환을 유지한다.
		edge_record["join_prev"] = join_start
		edge_record["join_next"] = join_end
		if state in ["closed", "open_placeholder"]:
			var structural_slot := _structural_edge_slot(side)
			edge_record["variant"] = "segment"
			edge_record["structural_asset_id"] = str(structural_slot.get("asset_id", ""))
			edge_record["texture_key"] = "wall_%s_structural_segment" % side
			edge_record["marker_overlay_state"] = ""
			if str(structural_slot.get("layer", "")) in ["wall_back", "wall_front"]:
				edge_record["layer"] = str(structural_slot["layer"])
		else:
			# 실제로 열린 connected 경계는 바닥만 남기고 어떤 world 장식도 소유하지 않는다.
			edge_record["variant"] = state
			edge_record["texture_key"] = ""
		records.append(edge_record)
	records.sort_custom(func(a, b) -> bool:
		var ca: Vector2i = a["cell"]
		var cb: Vector2i = b["cell"]
		if ca.x + ca.y == cb.x + cb.y:
			if ca.x == cb.x:
				return _side_sort_index(str(a["side"])) < _side_sort_index(str(b["side"]))
			return ca.x < cb.x
		return ca.x + ca.y < cb.x + cb.y
	)
	return records

func _build_wall_vertex_records(topology_vertices: Array, wall_edges: Array) -> Array:
	var edges_by_id: Dictionary = {}
	for edge_value in wall_edges:
		if edge_value is Dictionary:
			edges_by_id[str(edge_value.get("id", ""))] = edge_value
	var result: Array = []
	for vertex_value in topology_vertices:
		if not vertex_value is Dictionary:
			continue
		var vertex: Dictionary = vertex_value.duplicate(true)
		var edge_ids: Array = vertex.get("edge_ids", [])
		if edge_ids.is_empty():
			continue
		var edge: Dictionary = edges_by_id.get(str(edge_ids[0]), {})
		if edge.is_empty():
			continue
		var vertex_key := str(vertex.get("key", ""))
		vertex["screen_position"] = (
			edge.get("start", Vector2.ZERO)
			if str(edge.get("start_key", "")) == vertex_key
			else edge.get("end", Vector2.ZERO)
		)
		vertex["reference_rect"] = edge.get("rect", Rect2())
		vertex["reference_edge_start"] = edge.get("start", Vector2.ZERO)
		vertex["reference_edge_end"] = edge.get("end", Vector2.ZERO)
		vertex["reference_segment_asset_id"] = str(edge.get("structural_asset_id", ""))
		var layer := "wall_back"
		for edge_id_value in edge_ids:
			var incident: Dictionary = edges_by_id.get(str(edge_id_value), {})
			if str(incident.get("layer", "")) == "wall_front":
				layer = "wall_front"
				break
		vertex["layer"] = layer
		var vertex_asset_id := _structural_vertex_asset_id(
			str(vertex.get("kind", "")),
			str(vertex.get("orientation_key", ""))
		)
		vertex["structural_asset_id"] = vertex_asset_id
		vertex["texture_key"] = (
			"wall_vertex_%s_structural" % str(vertex.get("kind", ""))
			if vertex_asset_id != ""
			else ""
		)
		result.append(vertex)
	return result

func _draw_active_rock_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var data: Dictionary = record["data"]
		if str(data.get("cell_type", "")) == "floor":
			continue
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var fill = Color("#17131d72") if str(data.get("cell_type", "")) == "rock" else Color("#07060936")
		root.draw_polygon(diamond, PackedColorArray([fill.lightened(0.04), fill, fill.darkened(0.08), fill.darkened(0.03)]))
		if str(data.get("cell_type", "")) == "rock":
			root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#33294358"), 1.0)

func _draw_floor_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		if int(record["mask"]) < 0:
			continue
		var rect: Rect2 = record["rect"]
		var mask := int(record["mask"])
		var data: Dictionary = record["data"]
		var is_corridor = bool(data.get("is_corridor", false))
		var alpha := 0.98 if is_corridor else 0.42
		var texture = _floor_tile_texture(mask)
		if texture != null:
			root.draw_texture_rect(texture, rect.grow(3.0), false, _active_profile_color_with_alpha("floor_modulate", Color.WHITE, alpha))
		else:
			_draw_placeholder_floor(rect, mask)

func _draw_room_footprint_layer(tile_grid: Dictionary) -> void:
	for slot in tile_grid.get("objects", []):
		if not _is_full_grid_room_slot(slot):
			continue
		var cells = _object_footprint_cells(slot)
		if cells.is_empty():
			continue
		var cell_set: Dictionary = {}
		for cell in cells:
			cell_set[cell] = true
		cells.sort_custom(func(a, b) -> bool:
			if a.x + a.y == b.x + b.y:
				return a.x < b.x
			return a.x + a.y < b.x + b.y
		)
		var fill = _room_footprint_fill(str(slot.get("id", "")))
		for cell in cells:
			var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
			var diamond = _diamond(rect)
			var cell_fill = _room_boundary_fill(fill) if _is_room_boundary_cell(cell, cell_set) else fill
			root.draw_polygon(diamond, PackedColorArray([
				cell_fill.lightened(0.12),
				cell_fill.lightened(0.03),
				cell_fill.darkened(0.08),
				cell_fill
			]))
			var grid_alpha := 0.46 if _is_room_boundary_cell(cell, cell_set) else 0.32
			if render_profile != RENDER_PROFILE_MOBILE:
				root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), fill.lightened(0.28), grid_alpha)
		_draw_room_footprint_perimeter(cells, cell_set, fill)

func _draw_room_footprint_perimeter(cells: Array, cell_set: Dictionary, fill: Color) -> void:
	var dark = Color("#09070bd8")
	var light = fill.lightened(0.28).lerp(Color("#847978a8"), 0.55)
	for cell in cells:
		var rect = root.graph.tile_cell_rect(cell).grow(-1.0)
		var diamond = _diamond(rect)
		for side in ["N", "E", "S", "W"]:
			if cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
				continue
			var points = _edge_points(diamond, side)
			if points.size() < 2:
				continue
			root.draw_line(points[0], points[1], dark, 5.4, true)
			if render_profile == RENDER_PROFILE_FULL:
				_draw_rough_room_footprint_edge(cell, side, points[0], points[1], light)

func _draw_rough_room_footprint_edge(cell: Vector2i, side: String, start: Vector2, end: Vector2, color: Color) -> void:
	var segment_count := 3
	for index in range(segment_count):
		var edge_noise = _room_edge_noise(cell, side, 23 + index)
		if edge_noise < 0.18:
			continue
		var u0 = float(index) / float(segment_count) + 0.035
		var u1 = float(index + 1) / float(segment_count) - 0.035
		var offset_y = (edge_noise - 0.5) * 1.8
		var a = start.lerp(end, u0) + Vector2(0, offset_y)
		var b = start.lerp(end, u1) + Vector2(0, -offset_y * 0.55)
		var width = 1.0 + edge_noise * 1.2
		root.draw_line(a, b, color.darkened(edge_noise * 0.22), width, true)
		if edge_noise > 0.67:
			var chip = a.lerp(b, 0.5)
			root.draw_circle(chip, 1.1, Color("#100c12be"))

func _is_room_boundary_cell(cell: Vector2i, cell_set: Dictionary) -> bool:
	for side in ["N", "E", "S", "W"]:
		if not cell_set.has(cell + AutoTileMaskScript.DIRS[side]):
			return true
	return false

func _room_boundary_fill(fill: Color) -> Color:
	return fill.darkened(0.22).lerp(Color("#2b2830e8"), 0.48)

func _room_footprint_fill(slot_id: String) -> Color:
	match slot_id:
		"throne_f":
			return Color("#5a283ab8")
		"entrance_gate_f":
			return Color("#3e4050b8")
		"weapon_rack":
			return Color("#4d4639b8")
		"recovery_nest_f":
			return Color("#344a3fb8")
		"treasure_pile_large":
			return Color("#5b4a2cb8")
		"foundation_marks":
			return Color("#40314db0")
		"heart_core_placeholder":
			return Color("#5f284fb8")
	return Color("#423b40b0")

func _draw_room_wall_layer(tile_grid: Dictionary, layer_name: String) -> void:
	# Stage 01은 같은 석벽 bitmap을 방과 통로 외곽에 함께 사용한다.
	# 구형 절차 벽까지 겹치면 벽 높이와 돌 크기가 달라지고 이중 윤곽이 생긴다.
	if str(_active_spatial_profile().get("room_wall_mode", "")) == "shared_bitmap_edges":
		return
	for record in tile_grid.get("room_walls", []):
		if str(record.get("layer", "")) != layer_name:
			continue
		if str(record.get("state", "")) != "wall":
			continue
		_draw_room_boundary_wall(record)

func _draw_room_boundary_wall(record: Dictionary) -> void:
	var rect: Rect2 = record.get("rect", Rect2())
	var side = str(record.get("side", ""))
	var points = _edge_points(_diamond(rect.grow(-1.0)), side)
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var height = maxf(13.0, rect.size.y * 0.52)
	var top_start = start + Vector2(0, -height - _room_wall_noise(record, 11) * 6.0)
	var top_end = end + Vector2(0, -height - _room_wall_noise(record, 17) * 6.0)
	var face_dark = Color("#120f15cc")
	var face_mid = Color("#28242bdd")
	var face_low = Color("#0a070ce8")
	root.draw_polygon(
		PackedVector2Array([top_start, top_end, end, start]),
		PackedColorArray([face_mid.lightened(0.05), face_mid, face_low, face_dark])
	)
	if render_profile == RENDER_PROFILE_FULL:
		_draw_room_wall_stone_courses(record, top_start, top_end, start, end)
		_draw_room_wall_top_stones(record, top_start, top_end, start, end)
		_draw_room_wall_spilled_rubble(record, start, end)
	root.draw_line(start, end, Color("#0503079a"), 3.2, true)

func _draw_room_wall_stone_courses(record: Dictionary, top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2) -> void:
	var course_count := 4
	for course in range(course_count):
		var v0 = float(course) / float(course_count)
		var v1 = float(course + 1) / float(course_count)
		var block_count = 2 + int(_room_wall_noise(record, 31 + course) * 3.99)
		var offset = (_room_wall_noise(record, 44 + course) - 0.5) * 0.22
		for block_index in range(block_count):
			var width_jitter = 0.78 + _room_wall_noise(record, 52 + course * 9 + block_index) * 0.55
			var row_span = 1.0 / float(block_count)
			var u_center = (float(block_index) + 0.5) / float(block_count) + offset
			var u0 = u_center - row_span * width_jitter * 0.46
			var u1 = u_center + row_span * width_jitter * 0.46
			if u1 <= 0.0 or u0 >= 1.0:
				continue
			u0 = clampf(u0, 0.0, 1.0)
			u1 = clampf(u1, 0.0, 1.0)
			var gap_u = minf(0.012, (u1 - u0) * 0.10)
			var gap_v = 0.018 + _room_wall_noise(record, 64 + course * 9 + block_index) * 0.030
			var shade = _room_wall_noise(record, 80 + course * 7 + block_index)
			var color = Color("#403a3ce5").lerp(Color("#1b171ee8"), shade)
			if course == 0:
				color = color.lightened(0.04)
			elif course == course_count - 1:
				color = color.darkened(0.10)
			var lean = (_room_wall_noise(record, 95 + course * 9 + block_index) - 0.5) * 0.028
			var top_lift = (_room_wall_noise(record, 101 + course * 9 + block_index) - 0.5) * 0.035
			var p0 = _room_wall_face_point(top_start, top_end, start, end, u0 + gap_u + lean, v0 + gap_v + top_lift)
			var p1 = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.52) + lean * 0.4, v0 + gap_v - top_lift * 0.8)
			var p2 = _room_wall_face_point(top_start, top_end, start, end, u1 - gap_u + lean, v0 + gap_v + top_lift * 0.55)
			var p3 = _room_wall_face_point(top_start, top_end, start, end, u1 - gap_u - lean * 0.3, v1 - gap_v)
			var p4 = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.44) - lean * 0.2, v1 - gap_v + top_lift * 0.45)
			var p5 = _room_wall_face_point(top_start, top_end, start, end, u0 + gap_u - lean, v1 - gap_v)
			root.draw_polygon(PackedVector2Array([p0, p1, p2, p3, p4, p5]), PackedColorArray([
				color.lightened(0.10),
				color.lightened(0.08),
				color.lightened(0.03),
				color.darkened(0.15),
				color.darkened(0.20),
				color.darkened(0.08)
			]))
			root.draw_line(p0, p1, Color("#887d7460"), 0.7, true)
			root.draw_line(p5, p4, Color("#070509aa"), 0.8, true)
			if shade > 0.64:
				var crack_start = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.35), lerpf(v0, v1, 0.32))
				var crack_mid = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.48), lerpf(v0, v1, 0.55))
				var crack_end = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.40), lerpf(v0, v1, 0.78))
				root.draw_polyline(PackedVector2Array([crack_start, crack_mid, crack_end]), Color("#09070ccc"), 0.9, true)

func _draw_room_wall_top_stones(record: Dictionary, top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2) -> void:
	var cap_count = 4 + int(_room_wall_noise(record, 121) * 4.99)
	for index in range(cap_count):
		var u_center = (float(index) + 0.5) / float(cap_count) + (_room_wall_noise(record, 133 + index) - 0.5) * 0.11
		var half_width = (0.33 + _room_wall_noise(record, 137 + index) * 0.24) / float(cap_count)
		var u0 = clampf(u_center - half_width, 0.0, 1.0)
		var u1 = clampf(u_center + half_width, 0.0, 1.0)
		if u1 - u0 < 0.04:
			continue
		var lift = 1.5 + _room_wall_noise(record, 140 + index) * 7.2
		var drop = 0.14 + _room_wall_noise(record, 144 + index) * 0.13
		var p0 = _room_wall_face_point(top_start, top_end, start, end, u0, 0.04) + Vector2(0, -lift * 0.70)
		var p1 = _room_wall_face_point(top_start, top_end, start, end, u1, 0.05) + Vector2(0, -lift * 0.42)
		var p2 = _room_wall_face_point(top_start, top_end, start, end, u1, drop)
		var p3 = _room_wall_face_point(top_start, top_end, start, end, u0, drop)
		var cap_color = Color("#5d555add").lerp(Color("#2f2932dd"), _room_wall_noise(record, 170 + index))
		var cap_width = 3.2 + _room_wall_noise(record, 174 + index) * 3.8
		root.draw_line(p0, p1, cap_color.lightened(0.05), cap_width, true)
		root.draw_line(p3, p2, cap_color.darkened(0.28), maxf(1.4, cap_width * 0.34), true)
		if _room_wall_noise(record, 176 + index) > 0.52:
			var crown = _room_wall_face_point(top_start, top_end, start, end, lerpf(u0, u1, 0.48), 0.02) + Vector2(0, -lift * 0.88)
			_draw_small_rubble_stone(crown, 1.2 + _room_wall_noise(record, 178 + index) * 1.8, cap_color.lightened(0.04))
		if _room_wall_noise(record, 181 + index) > 0.36:
			root.draw_line(p0.lerp(p1, 0.18), p0.lerp(p1, 0.82), Color("#a69c8c8f"), 0.9, true)
		root.draw_line(p3, p2, Color("#09060aaa"), 1.0, true)
	if _room_wall_noise(record, 211) > 0.58:
		var glow_u = _room_wall_noise(record, 213)
		var glow = _room_wall_face_point(top_start, top_end, start, end, glow_u, 0.72)
		root.draw_circle(glow, 1.8, Color("#a56cff74"))

func _draw_room_wall_spilled_rubble(record: Dictionary, start: Vector2, end: Vector2) -> void:
	var pebble_count = 2 + int(_room_wall_noise(record, 230) * 3.99)
	for index in range(pebble_count):
		var u = _room_wall_noise(record, 240 + index)
		var point = start.lerp(end, u)
		var fall = 1.2 + _room_wall_noise(record, 250 + index) * 5.8
		var side_offset = (_room_wall_noise(record, 260 + index) - 0.5) * 7.0
		point += Vector2(side_offset, fall)
		var size = 1.1 + _room_wall_noise(record, 270 + index) * 2.2
		var color = Color("#312b30cc").lerp(Color("#18141acc"), _room_wall_noise(record, 280 + index))
		_draw_small_rubble_stone(point, size, color)

func _draw_small_rubble_stone(center: Vector2, size: float, color: Color) -> void:
	var radius := maxf(0.8, size * 0.62)
	root.draw_circle(center, radius, color.darkened(0.08))
	root.draw_line(center + Vector2(-radius * 0.45, -radius * 0.22), center + Vector2(radius * 0.36, -radius * 0.38), color.lightened(0.18), maxf(0.7, radius * 0.22), true)

func _room_wall_face_point(top_start: Vector2, top_end: Vector2, start: Vector2, end: Vector2, u: float, v: float) -> Vector2:
	var top_point = top_start.lerp(top_end, clampf(u, 0.0, 1.0))
	var bottom_point = start.lerp(end, clampf(u, 0.0, 1.0))
	return top_point.lerp(bottom_point, clampf(v, 0.0, 1.0))

func _room_wall_noise(record: Dictionary, salt: int) -> float:
	var cell: Vector2i = record.get("cell", Vector2i.ZERO)
	return _room_edge_noise(cell, str(record.get("side", "")), salt)

func _room_edge_noise(cell: Vector2i, side: String, salt: int) -> float:
	var side_code = _side_sort_index(side) + 1
	var value = absi(cell.x * 92837111 + cell.y * 689287499 + side_code * 283923481 + salt * 104729)
	value = int((value * 1103515245 + 12345) % 2147483647)
	return float(value % 1000) / 999.0

func _stage01_spatial_enabled() -> bool:
	return (
		str(_active_spatial_profile().get("special_visuals", "")) == "stage_01_cave"
		and has_stage01_spatial_textures()
	)

func _has_stage_corridor_visual(stage_id: String) -> bool:
	if stage_id == "":
		return false
	return (
		stage_spatial_textures.has("%s:corridor_autotile_atlas" % stage_id)
		or (
			stage_spatial_textures.has("%s:corridor:00" % stage_id)
			and stage_spatial_textures.has("%s:corridor:10" % stage_id)
			and stage_spatial_textures.has("%s:corridor:01" % stage_id)
			and stage_spatial_textures.has("%s:corridor:11" % stage_id)
		)
	)

func _active_stage_spatial_enabled() -> bool:
	return _has_stage_corridor_visual(_active_stage_visual_id())

func _stage_corridor_texture(stage_id: String, cell: Vector2i) -> Texture2D:
	var variant := "%d%d" % [posmod(cell.x, 2), posmod(cell.y, 2)]
	return stage_spatial_textures.get("%s:corridor:%s" % [stage_id, variant], null)

func _stage_corridor_variant_index(cell: Vector2i) -> int:
	var variant := "%d%d" % [posmod(cell.x, 2), posmod(cell.y, 2)]
	return maxi(0, CORRIDOR_AUTOTILE_VARIANTS.find(variant))

func _draw_stage_corridor_surface(rect: Rect2, cell: Vector2i, mask: int, alpha: float) -> bool:
	var stage_id := _active_stage_visual_id()
	if stage_id == "":
		return false
	var atlas := stage_spatial_textures.get("%s:corridor_autotile_atlas" % stage_id, null) as Texture2D
	var modulate := _active_profile_color_with_alpha("corridor_modulate", Color.WHITE, alpha)
	if atlas != null:
		var mask_index := clampi(mask, 0, CORRIDOR_AUTOTILE_MASK_COUNT - 1)
		var variant_index := _stage_corridor_variant_index(cell)
		var source_rect := Rect2(
			Vector2(mask_index * CORRIDOR_AUTOTILE_CELL_SIZE.x, variant_index * CORRIDOR_AUTOTILE_CELL_SIZE.y),
			CORRIDOR_AUTOTILE_CELL_SIZE
		)
		root.draw_texture_rect_region(atlas, rect.grow(2.0), source_rect, modulate)
		return true
	var corridor_texture := _stage_corridor_texture(stage_id, cell)
	if corridor_texture == null:
		return false
	root.draw_texture_rect(corridor_texture, rect.grow(2.0), false, modulate)
	return true

func _draw_stage01_corridor_surface(rect: Rect2, cell: Vector2i, mask: int, alpha: float) -> bool:
	return _draw_stage_corridor_surface(rect, cell, mask, alpha)

func _draw_corridor_path_layer(tile_grid: Dictionary) -> void:
	var floor_mode := str(_active_spatial_profile().get("corridor_floor_mode", "legacy_procedural"))
	for record in tile_grid["cells"]:
		if int(record["mask"]) < 0:
			continue
		var data: Dictionary = record["data"]
		if not bool(data.get("is_corridor", false)):
			continue
		var rect: Rect2 = record["rect"]
		if floor_mode == "stage_atlas" and _active_stage_spatial_enabled():
			var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
			if _draw_stage_corridor_surface(rect, cell, int(record.get("mask", 0)), 0.97):
				continue
		if floor_mode == "tile_variant_mask":
			continue
		var diamond = _diamond(rect.grow(-7.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color("#7d6b56a8"),
			Color("#655646aa"),
			Color("#3f342eb4"),
			Color("#564736aa")
		]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#c7ad7a5c"), 1.1)
		_draw_corridor_path_seam(rect)

func _draw_corridor_path_seam(rect: Rect2) -> void:
	var diamond = _diamond(rect.grow(-15.0))
	var center = rect.get_center()
	root.draw_line(center.lerp(diamond[0], 0.42), center.lerp(diamond[2], 0.42), Color("#211b19aa"), 1.0, true)
	root.draw_line(center.lerp(diamond[1], 0.42), center.lerp(diamond[3], 0.42), Color("#9b836151"), 1.0, true)

func _draw_outside_approach_layer(tile_grid: Dictionary) -> void:
	var floor_mode := str(_active_spatial_profile().get("corridor_floor_mode", "legacy_procedural"))
	var outside_cells: Dictionary = {}
	var outside_records: Array = []
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != "outside_approach":
			continue
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		outside_cells[cell] = true
		outside_records.append(record)
	for record in outside_records:
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		var rect: Rect2 = record.get("rect", Rect2())
		if floor_mode == "stage_atlas" and _active_stage_spatial_enabled():
			if _draw_stage_corridor_surface(rect, cell, int(record.get("mask", 0)), 0.92):
				continue
		if floor_mode == "tile_variant_mask":
			continue
		var diamond = _diamond(rect.grow(-5.0))
		root.draw_polygon(diamond, PackedColorArray([
			Color("#8f7860b8"),
			Color("#6f5f50ba"),
			Color("#322b2dc2"),
			Color("#56483fb8")
		]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#e0bd807c"), 1.35)
		_draw_corridor_path_seam(rect)

func _draw_outside_mouth_overlay_layer(tile_grid: Dictionary) -> void:
	var outside_cells: Dictionary = {}
	var outside_records: Array = []
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != "outside_approach":
			continue
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		outside_cells[cell] = true
		outside_records.append(record)
	for record in outside_records:
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		if outside_cells.has(cell + AutoTileMaskScript.DIRS["W"]):
			continue
		_draw_outside_cave_mouth(record.get("rect", Rect2()), cell)

func _draw_outside_cave_mouth(rect: Rect2, cell: Vector2i) -> void:
	var points = _edge_points(_diamond(rect.grow(-2.0)), "W")
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var center = start.lerp(end, 0.5)
	var height = maxf(18.0, rect.size.y * 0.58)
	var arch_top = center + Vector2(0, -height)
	root.draw_line(start, end, Color("#020104fb"), maxf(12.0, rect.size.y * 0.30), true)
	root.draw_line(start, arch_top, Color("#050307f6"), maxf(8.0, rect.size.y * 0.20), true)
	root.draw_line(arch_top, end, Color("#050307f6"), maxf(8.0, rect.size.y * 0.20), true)
	root.draw_line(start, end, Color("#d0a06fee"), maxf(4.0, rect.size.y * 0.09), true)
	for index in range(4):
		var t = (float(index) + 0.5) / 4.0
		var point = start.lerp(end, t) + Vector2(_outside_noise(cell, index) * 5.0 - 2.5, -2.0 - _outside_noise(cell, index + 11) * 6.0)
		var radius = 1.7 + _outside_noise(cell, index + 21) * 2.4
		_draw_small_rubble_stone(point, radius, Color("#7d706ad8").lerp(Color("#2a242adc"), _outside_noise(cell, index + 31)))
	var glow = Color("#946cff88")
	root.draw_circle(center + Vector2(0, -height * 0.26), maxf(9.0, rect.size.y * 0.22), glow)
	root.draw_line(center + Vector2(-rect.size.x * 0.17, -height * 0.18), center + Vector2(rect.size.x * 0.20, height * 0.10), Color("#f0c988b8"), 2.5, true)

func _outside_noise(cell: Vector2i, salt: int) -> float:
	var value = absi(cell.x * 374761393 + cell.y * 668265263 + salt * 1442695041)
	value = int((value * 1103515245 + 12345) % 2147483647)
	return float(value % 1000) / 999.0

func _draw_placeholder_floor(rect: Rect2, mask: int) -> void:
	var diamond = _diamond(rect)
	var fill = Color("#242833").lerp(Color("#4b3d2f"), float(mask % 5) / 8.0)
	root.draw_polygon(diamond, PackedColorArray([fill.lightened(0.10), fill.lightened(0.04), fill.darkened(0.05), fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#6e5d7a66"), 1.0)

func _draw_edge_skirt_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var cell: Vector2i = record["global_cell"]
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect)
		var side_points = {
			"N": [diamond[0], diamond[1]],
			"E": [diamond[1], diamond[2]],
			"S": [diamond[2], diamond[3]],
			"W": [diamond[3], diamond[0]]
		}
		_draw_floor_corner_overlays(cell, rect)
		for side in ["N", "E", "S", "W"]:
			if _edge_open(cell, side):
				continue
			var texture = edge_tile_textures.get(_edge_texture_key(side), null)
			if texture is Texture2D:
				root.draw_texture_rect(texture, rect.grow(4.0), false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, 0.56))
			else:
				var points: Array = side_points[side]
				root.draw_line(points[0], points[1], Color("#0a080ed9"), 2.0)

func _draw_connection_bridge_layer(tile_grid: Dictionary) -> void:
	# Stage 01의 인접 셀은 autotile 포트와 문턱이 직접 이어진다.
	# 두 셀 중심 사이에 임의 각도의 strip을 덧그리면 복도가 도로처럼 보인다.
	if str(_active_spatial_profile().get("connection_mode", "")) == "grid_cells":
		return
	for record in tile_grid.get("connection_bridges", []):
		_draw_connection_bridge(record.get("start", Vector2.ZERO), record.get("end", Vector2.ZERO), float(record.get("cell_height", 24.0)))


func _draw_v122_defender_connector() -> void:
	var connector := _v122_defender_connector_data()
	if connector.is_empty():
		return
	if _active_castle_art_stage() != "stage_01_cave":
		_draw_legacy_v122_defender_connector(connector)
		return
	# 건설 완료 상태는 공용 topology builder에 전달하는 visual patch가 실제 2x2 통로 셀로 합성한다.
	# 여기서는 건설 전 위치 표식만 그린다.
	if bool(connector.get("built", false)):
		return
	if root.current_screen != Constants.SCREEN_MANAGEMENT:
		return
	var connector_cells := _v122_defender_connector_cells(connector)
	if connector_cells.is_empty():
		return
	var center := Vector2.ZERO
	var cell_size := Vector2.ZERO
	for cell in connector_cells:
		var rect: Rect2 = root.graph.tile_cell_rect(cell)
		center += rect.get_center()
		cell_size = rect.size
	center /= float(connector_cells.size())
	var unlocked := bool(connector.get("unlocked", false))
	var tint := Color(0.52, 0.43, 0.31, 0.72) if unlocked else Color(0.31, 0.29, 0.34, 0.52)
	if _draw_stage01_defender_connector_junction(center, tint, cell_size * Vector2(0.94, 0.94)):
		return
	root.draw_circle(center, maxf(4.0, cell_size.y * 0.18), tint)


func _draw_legacy_v122_defender_connector(connector: Dictionary) -> void:
	var route_points = connector.get("route_points", [])
	if not route_points is Array or route_points.size() != 3:
		return
	var points: Array[Vector2] = []
	for point_value in route_points:
		if not point_value is Array or point_value.size() != 2:
			return
		points.append(Vector2(float(point_value[0]), float(point_value[1])))
	if bool(connector.get("built", false)):
		_draw_connection_bridge(points[0], points[1], 24.0)
		_draw_connection_bridge(points[1], points[2], 24.0)
		root.draw_circle(points[1], 9.0, Color("#78d8c6d9"))
		root.draw_circle(points[1], 4.0, Color("#fff0b0"))
		return
	if root.current_screen != Constants.SCREEN_MANAGEMENT:
		return
	var unlocked := GameState.day >= int(connector.get("unlock_day", 1))
	var edge_color := Color("#d8ad4cb8") if unlocked else Color("#655a6678")
	var center_color := Color("#ffd36ad9") if unlocked else Color("#7b6c7b99")
	root.draw_line(points[0], points[0].lerp(points[1], 0.38), edge_color, 8.0, true)
	root.draw_line(points[2], points[2].lerp(points[1], 0.38), edge_color, 8.0, true)
	root.draw_circle(points[1], 8.0, Color("#100d14e8"))
	root.draw_circle(points[1], 5.0, center_color)


func _v122_defender_connector_data() -> Dictionary:
	var battle_plan: Dictionary = root.get_meta("v122_battle_plan", {})
	var connector_value = battle_plan.get("defender_connector", {})
	if (
		(not connector_value is Dictionary or connector_value.is_empty())
		and root.has_method("_v122_defender_connector")
	):
		connector_value = root._v122_defender_connector()
	if not connector_value is Dictionary or connector_value.is_empty():
		return {}
	return connector_value


func _v122_defender_connector_cells(connector: Dictionary) -> Array[Vector2i]:
	var origin_value = connector.get("grid_origin", [])
	if not origin_value is Array or origin_value.size() != 2:
		return []
	var origin := Vector2i(int(origin_value[0]), int(origin_value[1]))
	return [
		origin,
		origin + Vector2i(1, 0),
		origin + Vector2i(0, 1),
		origin + Vector2i(1, 1)
	]


func _socket_record_for_ref(sockets: Array, instance_id: String, socket_id: String) -> Dictionary:
	for socket in sockets:
		if str(socket.get("instance_id", "")) == instance_id and str(socket.get("socket_id", "")) == socket_id:
			return socket
	return {}

func _draw_connection_bridge(start: Vector2, end: Vector2, cell_height: float) -> void:
	var base_width = maxf(18.0, cell_height * 0.82)
	if _stage01_spatial_enabled():
		root.draw_line(start, end, Color("#100e14e8"), base_width + 6.0, true)
		root.draw_line(start, end, Color("#34313bdd"), base_width, true)
		root.draw_line(start, end, Color("#574f6080"), maxf(2.0, base_width * 0.10), true)
		return
	root.draw_line(start, end, Color("#130f12e2"), base_width + 8.0, true)
	root.draw_line(start, end, Color("#5d5248df"), base_width, true)
	root.draw_line(start, end, Color("#b5a079aa"), maxf(4.0, base_width * 0.18), true)
	root.draw_circle(start.lerp(end, 0.5), maxf(5.0, base_width * 0.18), Color("#c3ad7d9a"))
func _draw_stage01_defender_connector_junction(center: Vector2, modulate: Color, draw_size: Vector2) -> bool:
	var texture := stage_spatial_textures.get("stage_01_cave:defender_connector_junction", null) as Texture2D
	if texture == null:
		return false
	root.draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, modulate)
	return true

func _draw_connected_path_mouth_layer(tile_grid: Dictionary) -> void:
	for record in tile_grid.get("connection_bridges", []):
		_draw_path_mouth(record.get("from_rect", Rect2()), str(record.get("from_side", "")))
		_draw_path_mouth(record.get("to_rect", Rect2()), str(record.get("to_side", "")))

func _draw_path_mouth(rect: Rect2, side: String) -> void:
	if str(_active_spatial_profile().get("connection_mode", "")) == "grid_cells":
		return
	if rect.size == Vector2.ZERO:
		return
	var diamond = _diamond(rect.grow(-5.0))
	var points = _edge_points(diamond, side)
	if points.size() < 2:
		return
	var start: Vector2 = points[0]
	var end: Vector2 = points[1]
	var center = start.lerp(end, 0.5)
	var mouth_start = center.lerp(start, 0.38)
	var mouth_end = center.lerp(end, 0.38)
	var width = maxf(4.0, rect.size.y * 0.16)
	root.draw_line(mouth_start, mouth_end, Color("#100c0ecf"), width + 4.0, true)
	root.draw_line(mouth_start, mouth_end, Color("#d3bc83c6"), width, true)
	root.draw_line(mouth_start, mouth_end, Color("#fff0b06f"), maxf(1.5, width * 0.22), true)

func _draw_stage01_threshold_layer(tile_grid: Dictionary, render_layer: String) -> void:
	if not _stage01_spatial_enabled():
		return
	var cell_data_by_cell: Dictionary = {}
	for cell_record in tile_grid.get("cells", []):
		cell_data_by_cell[cell_record.get("global_cell", Vector2i.ZERO)] = cell_record.get("data", {})
	var grouped: Dictionary = {}
	for bridge_record in tile_grid.get("connection_bridges", []):
		var group_key := str(bridge_record.get("group_key", ""))
		if group_key == "":
			continue
		if not grouped.has(group_key):
			grouped[group_key] = []
		grouped[group_key].append(bridge_record)
	for group_records_value in grouped.values():
		var group_records: Array = group_records_value
		if group_records.size() < 2:
			continue
		var room_side := ""
		var patch_cells: Dictionary = {}
		for bridge_record in group_records:
			var from_cell: Vector2i = bridge_record.get("from_cell", Vector2i.ZERO)
			var to_cell: Vector2i = bridge_record.get("to_cell", Vector2i.ZERO)
			var from_data: Dictionary = cell_data_by_cell.get(from_cell, {})
			var to_data: Dictionary = cell_data_by_cell.get(to_cell, {})
			var from_is_corridor := bool(from_data.get("is_corridor", false))
			var to_is_corridor := bool(to_data.get("is_corridor", false))
			if from_is_corridor == to_is_corridor:
				continue
			room_side = (
				str(bridge_record.get("to_side", ""))
				if from_is_corridor
				else str(bridge_record.get("from_side", ""))
			)
			patch_cells[from_cell] = true
			patch_cells[to_cell] = true
		if room_side == "" or patch_cells.size() != 4 or _socket_render_layer(room_side) != render_layer:
			continue
		var texture := stage_spatial_textures.get("stage_01_cave:threshold:%s" % room_side, null) as Texture2D
		if texture == null:
			continue
		var center := Vector2.ZERO
		var first_cell := Vector2i.ZERO
		var has_first_cell := false
		for cell in patch_cells.keys():
			if not has_first_cell:
				first_cell = cell
				has_first_cell = true
			center += root.graph.tile_cell_rect(cell).get_center()
		center /= float(patch_cells.size())
		var cell_size: Vector2 = root.graph.tile_cell_rect(first_cell).size
		var draw_rect := Rect2(center - cell_size, cell_size * 2.0)
		root.draw_texture_rect(texture, draw_rect, false, Color(1, 1, 1, 0.98))
		var shadow := stage_spatial_textures.get("stage_01_cave:occlusion", null) as Texture2D
		if shadow != null:
			root.draw_texture_rect(shadow, draw_rect, false, Color(1, 1, 1, 0.42))

func _draw_back_wall_layer(tile_grid: Dictionary, draw_target: CanvasItem = null) -> void:
	for record in tile_grid.get("wall_edges", []):
		if str(record.get("side", "")) not in ["N", "W"]:
			continue
		if str(record.get("state", "closed")) not in ["closed", "open_placeholder"]:
			continue
		_draw_wall_edge_record(record, draw_target)
	if _structural_vertex_asset_overlays_enabled():
		_draw_wall_vertex_body_layer(tile_grid, draw_target, "rear")

func _draw_socket_cap_layer(
	_tile_grid: Dictionary,
	_render_layer: String,
	_draw_target: CanvasItem = null
) -> void:
	# 연결부는 완전 공백이다. placeholder도 낮은 구조벽이 직접 막으므로
	# 구형 문틀·횃불·석주 marker PNG를 합성하지 않는다.
	pass

func _draw_socket_layer(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
		var side = str(socket.get("side", ""))
		var state = str(socket.get("state", "closed"))
		var point = _socket_point(rect, side)
		if (
			state == "connected"
			and str(_active_spatial_profile().get("connection_mode", "")) != "grid_cells"
		):
			_draw_doorway_threshold(side, rect)

func _draw_object_layer(tile_grid: Dictionary, layer_name: String, draw_target: CanvasItem = null) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	_prune_finished_trap_animations()
	for slot in tile_grid["objects"]:
		var slot_id = str(slot.get("id", ""))
		var texture_key = _object_texture_key_for_layer(slot, slot_id, layer_name)
		if texture_key == "":
			if slot_id == "heart_core_placeholder" and layer_name == "front":
				_draw_heart_core_placeholder(slot, target)
			continue
		var texture = object_sprite_textures.get(texture_key, null)
		if not texture is Texture2D:
			continue
		var projection_safe_full_grid = _is_full_grid_room_slot(slot) and _object_texture_uses_projection_safe_room_sprite(texture_key)
		var placement := _object_placement(slot_id, layer_name)
		var full_grid_room_fallback = (
			_is_full_grid_room_slot(slot)
			and not projection_safe_full_grid
			and bool(placement.get("full_grid_fallback", true))
		)
		var rect = _object_draw_rect(slot, texture_key)
		_draw_object_texture(texture, rect, slot_id, layer_name, full_grid_room_fallback, projection_safe_full_grid, target)
		_draw_object_connection_marks(slot, rect, slot_id, layer_name, target)

func _draw_heart_core_placeholder(slot: Dictionary, draw_target: CanvasItem = null) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	var cell: Vector2i = slot.get("cell", Vector2i.ZERO)
	var rect: Rect2 = root.graph.tile_cell_rect(cell)
	if _show_heart_core_art(rect):
		return
	var center := rect.get_center() + Vector2(0, -rect.size.y * 0.36)
	var radius := maxf(8.0, rect.size.y * 0.3)
	target.draw_circle(center, radius * 1.55, Color("#a13f8870"))
	target.draw_circle(center, radius, Color("#6f183f"))
	target.draw_circle(center + Vector2(-radius * 0.26, -radius * 0.2), radius * 0.42, Color("#dc6b9b"))
	target.draw_polyline(PackedVector2Array([
		center + Vector2(-radius * 0.9, radius * 0.55),
		center + Vector2(-radius * 0.3, radius * 1.35),
		center + Vector2(radius * 0.25, radius * 0.72),
		center + Vector2(radius * 0.92, radius * 1.45)
	]), Color("#e69fca"), 3.0, true)

func _show_heart_core_art(rect: Rect2) -> bool:
	var sheet_path := "res://assets/sprites/hearts/heart_props_sheet.png"
	if not ResourceLoader.exists(sheet_path):
		return false
	var active_run_value = root.get("update3_active_run")
	var heart_id := str(active_run_value.get("heart", {}).get("heart_id", "")) if active_run_value is Dictionary else ""
	var row := int({"heart_stonebone": 0, "heart_hungry_maw": 1, "heart_dream_lantern": 2}.get(heart_id, -1))
	if row < 0:
		return false
	if heart_core_sprite == null:
		heart_core_sprite = Sprite2D.new()
		heart_core_sprite.name = "Update3HeartCoreArt"
		heart_core_sprite.centered = true
		heart_core_sprite.z_as_relative = false
		heart_core_sprite.z_index = 32
		var material := ShaderMaterial.new()
		if heart_chroma_shader == null:
			heart_chroma_shader = Shader.new()
			heart_chroma_shader.code = "shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); float m=min(c.r,c.b)-c.g; float balance=1.0-smoothstep(0.10,0.32,abs(c.r-c.b)); float k=smoothstep(0.10,0.34,m)*balance; c.a*=1.0-k; COLOR=c; }"
		material.shader = heart_chroma_shader
		heart_core_sprite.material = material
		var layer := root.get_node_or_null("ObjectFrontLayer")
		if layer == null:
			return false
		layer.add_child(heart_core_sprite)
	var sheet := ResourceLoader.load(sheet_path) as Texture2D
	if sheet == null:
		return false
	var stage := 2
	if root.has_method("_castle_stage_index"):
		stage = clampi(int(root.call("_castle_stage_index")), 2, 4)
	var cell_size := Vector2(sheet.get_width() / 4.0, sheet.get_height() / 3.0)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(stage - 2, row) * cell_size, cell_size)
	heart_core_sprite.texture = atlas
	heart_core_sprite.position = rect.get_center() + Vector2(0, -rect.size.y * 0.26)
	heart_core_sprite.scale = Vector2.ONE * (rect.size.y * 1.15 / cell_size.y)
	heart_core_sprite.visible = true
	return true

func _object_texture_key_for_layer(slot: Dictionary, slot_id: String, layer_name: String) -> String:
	var slot_layer := str(slot.get("layer", "front"))
	var trap_key = _idle_trap_texture_key(slot_id)
	if trap_key != "":
		return trap_key if slot_layer == layer_name else ""
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	var variant := str(slot.get("connection_variant", ""))
	var connection_sprites: Dictionary = prop.get("connection_sprites", {})
	if variant != "" and connection_sprites.has(variant) and _connection_sprite_projection_safe(slot_id, variant):
		var variant_entry: Dictionary = connection_sprites.get(variant, {})
		if variant_entry.has(layer_name):
			return "prop:%s:%s:%s" % [slot_id, variant, layer_name]
		return ""
	var facing := str(slot.get("facing", prop.get("default_facing", "")))
	var stage_variant_match := _stage_variant_match(prop, facing, slot)
	if not stage_variant_match.is_empty():
		var stage_variant_entry: Dictionary = stage_variant_match.get("entry", {})
		var stage_variant_key := str(stage_variant_match.get("variant_key", "default"))
		if stage_variant_entry.has(layer_name) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return "propstagevariant:%s:%s:%s:%s:%s" % [slot_id, _active_castle_art_stage(), facing, stage_variant_key, layer_name]
		if bool(stage_variant_entry.get("_complete_override", false)) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return ""
	var stage_entry := _stage_facing_entry(prop, facing)
	if not stage_entry.is_empty():
		if stage_entry.has(layer_name) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return "propstage:%s:%s:%s:%s" % [slot_id, _active_castle_art_stage(), facing, layer_name]
		if bool(stage_entry.get("_complete_override", false)) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return ""
	var facing_sprites: Dictionary = prop.get("facing_sprites", {})
	if facing != "" and facing_sprites.has(facing):
		var facing_entry: Dictionary = facing_sprites.get(facing, {})
		if facing_entry.has(layer_name) and _prop_can_draw_layer(prop, slot_layer, layer_name):
			return "prop:%s:%s:%s" % [slot_id, facing, layer_name]
	var sprites: Dictionary = prop.get("sprites", {})
	if sprites.has(layer_name):
		return "prop:%s:%s" % [slot_id, layer_name]
	if slot_layer != layer_name:
		return ""
	var direct_key = "prop:%s:%s" % [slot_id, layer_name]
	if object_sprite_textures.has(direct_key):
		return direct_key
	if layer_name == "front" and object_sprite_textures.has("prop:%s:back" % slot_id):
		return "prop:%s:back" % slot_id
	return ""

func _active_castle_art_stage() -> String:
	if root == null:
		return ""
	return str(root.get("castle_art_stage"))

func _active_spatial_profile() -> Dictionary:
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	var stage_profiles: Dictionary = manifest.get("stage_spatial_profiles", {})
	var stage_entry: Dictionary = stage_profiles.get(_active_castle_art_stage(), {})
	if stage_entry.is_empty():
		return {}
	var profile_id := str(stage_entry.get("asset_profile", ""))
	var asset_profiles: Dictionary = manifest.get("spatial_asset_profiles", {})
	var result: Dictionary = asset_profiles.get(profile_id, {}).duplicate(true)
	result.merge(stage_entry, true)
	result["profile_id"] = profile_id
	return result

func _active_stage_visual_id() -> String:
	return str(_active_spatial_profile().get("special_visuals", ""))

func _stage_spatial_visuals(stage_id: String) -> Dictionary:
	if stage_id == "":
		return {}
	var visuals: Dictionary = DataRegistry.quarter_asset_manifest.get("stage_spatial_visuals", {})
	return visuals.get(stage_id, {})

func _active_profile_color(key: String, fallback: Color) -> Color:
	var value = _active_spatial_profile().get(key, null)
	if value is String and str(value) != "":
		return Color(str(value))
	if value is Array and value.size() >= 3:
		return Color(
			float(value[0]),
			float(value[1]),
			float(value[2]),
			float(value[3]) if value.size() >= 4 else fallback.a
		)
	return fallback

func _active_profile_color_with_alpha(key: String, fallback: Color, alpha: float) -> Color:
	var color := _active_profile_color(key, fallback)
	color.a *= alpha
	return color

func _stage_facing_entry(prop: Dictionary, facing: String) -> Dictionary:
	var stage = _active_castle_art_stage()
	if stage == "" or facing == "":
		return {}
	var stage_sprites: Dictionary = prop.get("stage_facing_sprites", {})
	if not stage_sprites.has(stage):
		return {}
	var stage_facings: Dictionary = stage_sprites.get(stage, {})
	if not stage_facings.has(facing):
		return {}
	return stage_facings.get(facing, {})

func _stage_variant_match(prop: Dictionary, facing: String, slot: Dictionary) -> Dictionary:
	var stage = _active_castle_art_stage()
	if stage == "" or facing == "":
		return {}
	var stage_sprites: Dictionary = prop.get("upgrade_stage_sprites", {})
	if not stage_sprites.has(stage):
		return {}
	var stage_entry: Dictionary = stage_sprites.get(stage, {})
	if not stage_entry.has(facing):
		return {}
	var facing_entry: Dictionary = stage_entry.get(facing, {})
	if _sprite_entry_has_visual_layer(facing_entry):
		return {"variant_key": "default", "entry": facing_entry}
	for variant_key in _stage_variant_lookup_keys(slot):
		if facing_entry.has(variant_key) and facing_entry[variant_key] is Dictionary:
			return {"variant_key": variant_key, "entry": facing_entry[variant_key]}
	return {}

func _stage_variant_lookup_keys(slot: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var variant = str(slot.get("connection_variant", "closed"))
	if variant == "":
		variant = "closed"
	var open_mask = _open_mask_for_slot(slot)
	for key in [
		"open_mask_%02d" % open_mask,
		"open_mask_%d" % open_mask,
		"mask_%02d" % open_mask,
		"mask_%d" % open_mask,
		variant,
		"default"
	]:
		if not result.has(str(key)):
			result.append(str(key))
	return result

func _open_mask_for_slot(slot: Dictionary) -> int:
	var mask := 0
	for side_value in slot.get("connected_sides", []):
		match str(side_value).to_upper():
			"N":
				mask |= 1
			"E":
				mask |= 2
			"S":
				mask |= 4
			"W":
				mask |= 8
	return mask

func _sprite_entry_has_visual_layer(entry: Dictionary) -> bool:
	for layer_name in ["back", "front"]:
		if entry.has(layer_name):
			return true
	return false

func _draw_front_wall_layer(tile_grid: Dictionary, draw_target: CanvasItem = null) -> void:
	var alpha := _front_wall_alpha()
	for record in tile_grid.get("wall_edges", []):
		if str(record.get("side", "")) not in ["E", "S"]:
			continue
		if str(record.get("state", "closed")) not in ["closed", "open_placeholder"]:
			continue
		_draw_wall_edge_record(record, draw_target, alpha)
	if _structural_vertex_asset_overlays_enabled():
		_draw_wall_vertex_body_layer(tile_grid, draw_target, "front", alpha)

func _draw_active_overlay(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var rect: Rect2 = record["rect"]
		var diamond = _diamond(rect.grow(2.0))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#9f7cff66"), 1.0)

func _draw_walkable_overlay(tile_grid: Dictionary) -> void:
	_draw_cell_set_overlay(tile_grid, tile_grid["walk_set"], Color("#4fc36b42"), Color("#9afaa777"))

func _draw_cell_set_overlay(tile_grid: Dictionary, cell_set: Dictionary, fill: Color, outline: Color) -> void:
	for record in tile_grid["cells"]:
		if not cell_set.has(record["global_cell"]):
			continue
		var diamond = _diamond(record["rect"].grow(2.0))
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.6)

func _draw_floor_mask_overlay(tile_grid: Dictionary) -> void:
	for record in tile_grid["cells"]:
		var mask := int(record["mask"])
		if mask < 0:
			continue
		var rect: Rect2 = record["rect"]
		root.draw_string(UI_FONT, rect.get_center() + Vector2(-9, 4), str(mask), HORIZONTAL_ALIGNMENT_LEFT, 32, 12, Color("#fff6d6"))

func _draw_socket_overlay(tile_grid: Dictionary) -> void:
	for socket in tile_grid["sockets"]:
		var cell: Vector2i = socket.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell).grow(-2.0)
		var point = _socket_point(rect, str(socket.get("side", "")))
		var state = str(socket.get("state", "closed"))
		var color = Color("#80d6ffdd") if state == "connected" else Color("#d8a6ffcc") if state == "open_placeholder" else Color("#6f6277cc")
		root.draw_circle(point, 6.0, color)
		root.draw_string(UI_FONT, point + Vector2(8, 3), state.substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, 24, 11, color)

func _draw_room_id_overlay(_tile_grid: Dictionary) -> void:
	for instance_id in root.graph.module_instance_ids():
		var rect = root.graph.rect(str(instance_id))
		var module = root.graph.module_data_for_instance(str(instance_id))
		var label = "%s\n%s" % [str(instance_id), str(module.get("id", ""))]
		root.draw_string(UI_FONT, rect.position + Vector2(8, 20), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 12, Color("#f5ecd8cc"))

func _draw_map_editor_overlay() -> void:
	_draw_map_editor_route_overlay()
	_draw_map_editor_socket_visibility_overlay()
	_draw_map_editor_gap_path_preview()
	_draw_map_editor_gap_path_socket_pair()


func _draw_map_editor_planning_grid(tile_grid: Dictionary) -> void:
	var active_set: Dictionary = tile_grid.get("active_set", {})
	if active_set.is_empty():
		return
	var planning_cells: Dictionary = {}
	var offsets := [Vector2i.ZERO, Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for cell_value in active_set.keys():
		var cell: Vector2i = cell_value
		for offset in offsets:
			planning_cells[cell + offset] = true
	for cell_value in planning_cells.keys():
		var cell: Vector2i = cell_value
		var rect: Rect2 = root.graph.tile_cell_rect(cell).grow(-3.0)
		var diamond := _diamond(rect)
		var is_active := active_set.has(cell)
		var fill := Color("#6d55a016") if is_active else Color("#5f88a00d")
		var outline := Color("#cda8ff3d") if is_active else Color("#7bdcff24")
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), outline, 1.0, true)


func _draw_map_editor_route_overlay() -> void:
	if root.graph == null or not root.has_method("_main_route_instance_ids"):
		return
	var route: Array = root._main_route_instance_ids()
	if route.size() < 2:
		return
	var points: Array = root.graph.path_points(str(route.front()), str(route.back())) if root.graph.has_method("path_points") else []
	if points.size() < 2:
		for instance_id_value in route:
			points.append(root.graph.center(str(instance_id_value)))
	if points.size() < 2:
		return
	var packed := PackedVector2Array()
	for point_value in points:
		packed.append(Vector2(point_value))
	root.draw_polyline(packed, Color("#07050acc"), 10.0, true)
	root.draw_polyline(packed, Color("#ffd36ad9"), 4.0, true)
	for index in range(points.size() - 1):
		var from_point := Vector2(points[index])
		var to_point := Vector2(points[index + 1])
		var segment := to_point - from_point
		if segment.length() < 18.0:
			continue
		var direction := segment.normalized()
		var normal := Vector2(-direction.y, direction.x)
		var arrow_center := from_point.lerp(to_point, 0.58)
		var arrow := PackedVector2Array([
			arrow_center + direction * 9.0,
			arrow_center - direction * 7.0 + normal * 6.0,
			arrow_center - direction * 7.0 - normal * 6.0
		])
		root.draw_colored_polygon(arrow, Color("#fff2c9e8"))
	var start := Vector2(points.front())
	var finish := Vector2(points.back())
	root.draw_circle(start, 9.0, Color("#7bdcfff2"))
	root.draw_circle(finish, 9.0, Color("#ffd36af2"))


func _draw_main_route_overlay() -> void:
	if root.graph == null or not root.has_method("_main_route_instance_ids"):
		return
	var route: Array = root._main_route_instance_ids()
	if route.size() < 2:
		return
	var points: Array = []
	if root.graph.has_method("path_points"):
		points = root.graph.path_points(str(route[0]), str(route[route.size() - 1]))
	if points.size() < 2:
		for instance_id_value in route:
			points.append(root.graph.center(str(instance_id_value)))
	if points.size() < 2:
		return
	var packed_points := PackedVector2Array()
	for point in points:
		packed_points.append(point)
	# 실제 석재 도로를 덮지 않는 보조 안내선이다. 도로보다 밝거나 굵게 보이면
	# 플레이어가 이 선을 물리적인 통로로 오해하므로 낮은 대비로 유지한다.
	root.draw_polyline(packed_points, Color("#08060952"), 3.0, true)
	root.draw_polyline(packed_points, Color("#c7a45e42"), 1.0, true)
	for instance_id_value in route:
		var center = root.graph.center(str(instance_id_value))
		root.draw_circle(center, 2.0, Color("#d9bd7b52"))

func _draw_selected_module_highlight(tile_grid: Dictionary) -> void:
	if root.selected_room == "":
		return
	var color = Color("#c9ad72d9")
	if root.map_editor_active and not root.map_editor_errors.is_empty():
		color = Color("#ff5d6cf0")
	var fill = Color(color.r, color.g, color.b, 0.07)
	var selected_records: Array = []
	var selected_cells: Dictionary = {}
	for record in tile_grid.get("cells", []):
		var data: Dictionary = record.get("data", {})
		if str(data.get("room_id", "")) != root.selected_room:
			continue
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		selected_records.append(record)
		selected_cells[cell] = true
		var rect: Rect2 = record.get("rect", Rect2()).grow(-1.0)
		var diamond = _diamond(rect)
		root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	for record in selected_records:
		var cell: Vector2i = record.get("global_cell", Vector2i.ZERO)
		var rect: Rect2 = record.get("rect", Rect2()).grow(-1.0)
		var diamond = _diamond(rect)
		_draw_selected_room_outer_edge(cell, selected_cells, Vector2i(0, -1), diamond[0], diamond[1], Color(color.r, color.g, color.b, 0.62), 1.4)
		_draw_selected_room_outer_edge(cell, selected_cells, Vector2i(1, 0), diamond[1], diamond[2], Color(color.r, color.g, color.b, 0.62), 1.4)
		_draw_selected_room_outer_edge(cell, selected_cells, Vector2i(0, 1), diamond[2], diamond[3], Color(color.r, color.g, color.b, 0.62), 1.4)
		_draw_selected_room_outer_edge(cell, selected_cells, Vector2i(-1, 0), diamond[3], diamond[0], Color(color.r, color.g, color.b, 0.62), 1.4)

func _draw_selected_room_outer_edge(cell: Vector2i, cell_lookup: Dictionary, neighbor_offset: Vector2i, from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	if cell_lookup.has(cell + neighbor_offset):
		return
	root.draw_line(from_point, to_point, color, width, true)

func _draw_map_editor_socket_visibility_overlay() -> void:
	if not root.has_method("_map_editor_socket_visibility_markers"):
		return
	var markers: Array = root._map_editor_socket_visibility_markers()
	for marker in markers:
		var cell: Vector2i = marker.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell)
		var state = str(marker.get("state", ""))
		var color = Color("#7bdcfff0")
		if state == "blocked":
			color = Color("#ff5d6ce8")
		elif state == "connected":
			color = Color("#80ffaaee")
		_draw_map_editor_socket_state_marker(rect, str(marker.get("side", "")), color)

func _draw_map_editor_socket_state_marker(rect: Rect2, side: String, color: Color) -> void:
	var diamond = _diamond(rect.grow(1.5))
	var fill = Color(color.r, color.g, color.b, 0.12)
	root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 1.7, true)
	var side_points = _edge_points(diamond, side)
	if side_points.size() >= 2:
		root.draw_line(side_points[0], side_points[1], color, 3.2, true)

func _draw_map_editor_gap_path_preview() -> void:
	if not root.has_method("_map_editor_preview_gap_path_candidate"):
		return
	var candidate: Dictionary = root._map_editor_preview_gap_path_candidate()
	if candidate.is_empty():
		return
	var module: Dictionary = DataRegistry.quarter_module(str(candidate.get("module_id", "")))
	if module.is_empty():
		return
	var origin: Vector2i = candidate.get("origin", Vector2i.ZERO)
	for value in module.get("floor_cells", []):
		if not (value is Array) or value.size() < 2:
			continue
		var cell = origin + Vector2i(int(value[0]), int(value[1]))
		var rect = root.graph.tile_cell_rect(cell).grow(-3.0)
		var diamond = _diamond(rect)
		root.draw_polygon(diamond, PackedColorArray([Color("#7bdcff35"), Color("#7bdcff35"), Color("#7bdcff35"), Color("#7bdcff35")]))
		root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#7bdcffdd"), 2.0)

func _draw_map_editor_gap_path_socket_pair() -> void:
	if not root.has_method("_map_editor_preview_gap_path_socket_markers"):
		return
	var markers: Array = root._map_editor_preview_gap_path_socket_markers()
	if markers.is_empty():
		return
	var prepared: Array = []
	for marker in markers:
		var cell: Vector2i = marker.get("cell", Vector2i.ZERO)
		var rect = root.graph.tile_cell_rect(cell)
		var role = str(marker.get("role", ""))
		var color = Color("#ffd36af2") if role == "source" else Color("#7bdcfff2")
		prepared.append({
			"rect": rect,
			"side": str(marker.get("side", "")),
			"color": color
		})
	if prepared.size() == 2:
		root.draw_line(
			prepared[0]["rect"].get_center(),
			prepared[1]["rect"].get_center(),
			Color("#f7efe184"),
			2.0,
			true
		)
	for item in prepared:
		_draw_map_editor_socket_pair_marker(item["rect"], str(item["side"]), item["color"])

func _draw_map_editor_socket_pair_marker(rect: Rect2, side: String, color: Color) -> void:
	var diamond = _diamond(rect.grow(5.0))
	var fill = Color(color.r, color.g, color.b, 0.18)
	root.draw_polygon(diamond, PackedColorArray([fill, fill, fill, fill]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), color, 2.6)
	var side_points = _edge_points(diamond, side)
	if side_points.size() < 2:
		return
	root.draw_line(side_points[0], side_points[1], color, 5.0, true)
	root.draw_line(side_points[0].lerp(side_points[1], 0.5), rect.get_center(), Color(color.r, color.g, color.b, 0.74), 2.0, true)

func _draw_unit_or_cursor_cell(tile_grid: Dictionary) -> void:
	var point = _mouse_world_position()
	if root.selected_unit != null and is_instance_valid(root.selected_unit):
		point = root.selected_unit.global_position
	var best_record = _nearest_record(tile_grid, point)
	if best_record.is_empty():
		return
	var rect: Rect2 = best_record["rect"]
	var diamond = _diamond(rect.grow(4.0))
	root.draw_polygon(diamond, PackedColorArray([Color("#7cf58f36"), Color("#7cf58f36"), Color("#7cf58f36"), Color("#7cf58f36")]))
	root.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color("#7cf58fe8"), 2.0)
	var cell: Vector2i = best_record["global_cell"]
	root.draw_string(UI_FONT, rect.position + Vector2(0, -6), "%d,%d" % [cell.x, cell.y], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 12, Color("#fff6d6"))

func _draw_path_overlay() -> void:
	if root.selected_unit == null or not is_instance_valid(root.selected_unit):
		return
	var points: Array = [root.selected_unit.global_position]
	points.append_array(root.selected_unit.path_points)
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		root.draw_line(points[index], points[index + 1], Color("#6fe7ffcc"), 2.0)
		root.draw_circle(points[index + 1], 4.0, Color("#d6fbffcc"))

func _load_floor_tile_textures() -> void:
	floor_tile_textures.clear()
	missing_floor_tile_masks.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var manifest_theme := str(manifest.get("theme_id", "cave_f"))
	var floor_mask: Dictionary = manifest.get("floor_mask", {})
	for mask in range(16):
		var entry: Dictionary = floor_mask.get(str(mask), {})
		var file_hint := str(entry.get("file_hint", "floor_%s_mask_%02d.png" % [manifest_theme, mask]))
		var path = "res://assets/tiles/%s/floor/%s" % [manifest_theme, file_hint]
		if not ResourceLoader.exists(path):
			missing_floor_tile_masks.append(mask)
			continue
		var texture = ResourceLoader.load(path)
		if texture is Texture2D:
			floor_tile_textures[mask] = texture
		else:
			missing_floor_tile_masks.append(mask)

func _load_addon_tile_textures() -> void:
	edge_tile_textures.clear()
	corner_overlay_textures.clear()
	missing_addon_tiles.clear()
	var manifest: Dictionary = DataRegistry.quarter_tile_variant_manifest
	var theme := str(manifest.get("theme_id", "cave_f"))
	_load_named_tile_group(theme, "edge", manifest.get("edges", {}), edge_tile_textures)
	_load_named_tile_group(theme, "overlay", manifest.get("corner_overlays", {}), corner_overlay_textures)
	# 과거 walls/wall_mask는 연결 계약이 없는 장식·임시 자산이다.
	# tile manifest의 quarantine 기록에는 남기되 런타임 벽 후보로 로드하지 않는다.


func _load_structural_wall_textures() -> void:
	structural_wall_textures.clear()
	structural_wall_front_occluder_textures.clear()
	structural_wall_asset_entries.clear()
	missing_structural_wall_asset_ids.clear()
	var catalog: Dictionary = DataRegistry.quarter_wall_asset_catalog
	var assets: Dictionary = catalog.get("assets", {})
	for asset_id_value in assets.keys():
		var asset_id := str(asset_id_value)
		var entry_value = assets.get(asset_id_value, {})
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		if (
			str(entry.get("usage", "")) != "structural_boundary"
			or str(entry.get("status", "")) != "runtime"
		):
			continue
		var path := str(entry.get("path", ""))
		if path == "":
			missing_structural_wall_asset_ids.append(asset_id)
			continue
		if not path.begins_with("res://"):
			path = "res://%s" % path
		if not ResourceLoader.exists(path):
			missing_structural_wall_asset_ids.append(asset_id)
			continue
		var texture = ResourceLoader.load(path)
		if not texture is Texture2D:
			missing_structural_wall_asset_ids.append(asset_id)
			continue
		structural_wall_textures[asset_id] = texture
		structural_wall_asset_entries[asset_id] = entry.duplicate(true)
		_load_structural_wall_front_occluder(asset_id, entry, texture)


func _load_structural_wall_front_occluder(asset_id: String, entry: Dictionary, body_texture: Texture2D) -> void:
	var path := str(entry.get("front_occluder_path", ""))
	if path == "":
		return
	if not path.begins_with("res://"):
		path = "res://%s" % path
	if not ResourceLoader.exists(path):
		missing_structural_wall_asset_ids.append("%s:front_occluder" % asset_id)
		return
	var texture = ResourceLoader.load(path)
	if not texture is Texture2D or texture.get_size() != body_texture.get_size():
		missing_structural_wall_asset_ids.append("%s:front_occluder" % asset_id)
		return
	structural_wall_front_occluder_textures[asset_id] = texture


func _active_structural_wall_set() -> Dictionary:
	var wall_kit_id := str(_active_spatial_profile().get("wall_kit_id", ""))
	if wall_kit_id == "":
		return {}
	var sets: Dictionary = DataRegistry.quarter_wall_asset_catalog.get("structural_wall_sets", {})
	var set_value = sets.get(wall_kit_id, {})
	return set_value if set_value is Dictionary else {}


func _active_boundary_marker_set() -> Dictionary:
	var marker_set_id := str(_active_structural_wall_set().get("marker_set", ""))
	if marker_set_id == "":
		return {}
	var marker_sets: Dictionary = DataRegistry.quarter_wall_asset_catalog.get("boundary_marker_sets", {})
	var marker_set_value = marker_sets.get(marker_set_id, {})
	return marker_set_value if marker_set_value is Dictionary else {}


func _structural_edge_slot(side: String) -> Dictionary:
	var wall_set := _active_structural_wall_set()
	var slots_value = wall_set.get("edge_segments", {})
	if not slots_value is Dictionary:
		return {}
	var slot_value = slots_value.get(side, {})
	if not slot_value is Dictionary:
		return {}
	var slot: Dictionary = slot_value
	var asset_id := str(slot.get("asset_id", ""))
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	if (
		entry.is_empty()
		or str(entry.get("usage", "")) != "structural_boundary"
		or str(entry.get("piece_kind", "")) != "edge_segment"
		or not entry.get("directions", []).has(side)
	):
		return {}
	return slot


func _structural_vertex_asset_id(kind: String, orientation_key: String) -> String:
	if not kind in ["corner", "cap", "junction"]:
		return ""
	var wall_set := _active_structural_wall_set()
	var vertices_value = wall_set.get("vertices", {})
	if not vertices_value is Dictionary:
		return ""
	var kind_slots_value = vertices_value.get(kind, {})
	if not kind_slots_value is Dictionary:
		return ""
	var kind_slots: Dictionary = kind_slots_value
	var asset_id := str(kind_slots.get(orientation_key, ""))
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	var expected_piece_kind := str({
		"corner": "vertex_corner",
		"cap": "vertex_end",
		"junction": "vertex_junction"
	}.get(kind, ""))
	if (
		entry.is_empty()
		or str(entry.get("usage", "")) != "structural_boundary"
		or str(entry.get("piece_kind", "")) != expected_piece_kind
		or str(entry.get("orientation_key", "")) != orientation_key
	):
		return ""
	return asset_id


func _load_named_tile_group(theme: String, folder_name: String, entries: Dictionary, target: Dictionary) -> void:
	for key in entries.keys():
		var file_hint := str(entries[key])
		var path = "res://assets/tiles/%s/%s/%s" % [theme, folder_name, file_hint]
		if ResourceLoader.exists(path):
			var texture = ResourceLoader.load(path)
			if texture is Texture2D:
				target[str(key)] = texture
			else:
				missing_addon_tiles.append("%s:%s" % [folder_name, key])
		else:
			missing_addon_tiles.append("%s:%s" % [folder_name, key])

func _load_background_plate_textures() -> void:
	background_plate_textures.clear()
	missing_background_plates.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	for background_id in manifest.get("backgrounds", {}).keys():
		var entry: Dictionary = manifest.get("backgrounds", {})[background_id]
		_load_background_plate(str(background_id), str(entry.get("path", "")))

func _load_background_plate(background_id: String, file_hint: String) -> void:
	if file_hint == "":
		missing_background_plates.append(background_id)
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_background_plates.append(background_id)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		background_plate_textures[background_id] = texture
	else:
		missing_background_plates.append(background_id)

func _load_socket_cap_textures() -> void:
	# V2는 connected/open_placeholder에 구형 world marker를 사용하지 않는다.
	socket_cap_textures.clear()
	missing_socket_caps.clear()

func _load_socket_cap(texture_key: String, file_hint: String) -> void:
	if file_hint == "":
		missing_socket_caps.append(texture_key)
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_socket_caps.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		socket_cap_textures[texture_key] = texture
	else:
		missing_socket_caps.append(texture_key)

func _load_stage_spatial_textures() -> void:
	stage_spatial_textures.clear()
	var stage_visuals: Dictionary = DataRegistry.quarter_asset_manifest.get("stage_spatial_visuals", {})
	for stage_id_value in stage_visuals.keys():
		var stage_id := str(stage_id_value)
		var entry: Dictionary = stage_visuals.get(stage_id, {})
		var corridor_autotile: Dictionary = entry.get("corridor_autotile", {})
		var corridor_atlas_key := "%s:corridor_autotile_atlas" % stage_id
		_load_stage_spatial_texture(corridor_atlas_key, str(corridor_autotile.get("atlas", "")))
		if not stage_spatial_textures.has(corridor_atlas_key):
			var corridor_cells: Dictionary = entry.get("corridor_cells", {})
			for cell_id in corridor_cells.keys():
				_load_stage_spatial_texture(
					"%s:corridor:%s" % [stage_id, str(cell_id)],
					str(corridor_cells[cell_id])
				)
		var defender_connector: Dictionary = entry.get("defender_connector", {})
		_load_stage_spatial_texture(
			"%s:defender_connector_junction" % stage_id,
			str(defender_connector.get("junction", ""))
		)
		var thresholds: Dictionary = entry.get("thresholds", {})
		for side in thresholds.keys():
			_load_stage_spatial_texture(
				"%s:threshold:%s" % [stage_id, str(side)],
				str(thresholds[side])
			)
		_load_stage_spatial_texture(
			"%s:occlusion" % stage_id,
			str(entry.get("common_occlusion_shadow", ""))
		)
		var edge_config: Dictionary = entry.get("cavern_edge_mask", {})
		_load_stage_spatial_texture(
			"%s:edge_mask" % stage_id,
			str(edge_config.get("path", ""))
		)

func _load_stage_spatial_texture(texture_key: String, file_hint: String) -> void:
	if file_hint == "":
		return
	var path := file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		return
	var texture := ResourceLoader.load(path)
	if texture is Texture2D:
		stage_spatial_textures[texture_key] = texture

func _load_object_sprite_textures() -> void:
	object_sprite_textures.clear()
	missing_object_sprites.clear()
	trap_animation_frame_counts.clear()
	var manifest: Dictionary = DataRegistry.quarter_asset_manifest
	for prop_id in manifest.get("props", {}).keys():
		var prop: Dictionary = manifest.get("props", {})[prop_id]
		for layer_name in prop.get("sprites", {}).keys():
			_load_object_sprite("prop:%s:%s" % [prop_id, layer_name], str(prop.get("sprites", {})[layer_name]))
		for variant in prop.get("connection_sprites", {}).keys():
			if not _connection_sprite_projection_safe(str(prop_id), str(variant)):
				continue
			var variant_entry: Dictionary = prop.get("connection_sprites", {})[variant]
			for layer_name in variant_entry.keys():
				_load_object_sprite("prop:%s:%s:%s" % [prop_id, variant, layer_name], str(variant_entry[layer_name]))
		for facing in prop.get("facing_sprites", {}).keys():
			var facing_entry: Dictionary = prop.get("facing_sprites", {})[facing]
			for layer_name in facing_entry.keys():
				_load_object_sprite("prop:%s:%s:%s" % [prop_id, facing, layer_name], str(facing_entry[layer_name]))
		for stage in prop.get("stage_facing_sprites", {}).keys():
			var stage_facings: Dictionary = prop.get("stage_facing_sprites", {})[stage]
			for facing in stage_facings.keys():
				var facing_entry: Dictionary = stage_facings[facing]
				for layer_name in facing_entry.keys():
					if str(layer_name).begins_with("_"):
						continue
					_load_object_sprite("propstage:%s:%s:%s:%s" % [prop_id, stage, facing, layer_name], str(facing_entry[layer_name]))
		for stage in prop.get("upgrade_stage_sprites", {}).keys():
			var stage_facings: Dictionary = prop.get("upgrade_stage_sprites", {})[stage]
			for facing in stage_facings.keys():
				var facing_entry: Dictionary = stage_facings[facing]
				if _sprite_entry_has_visual_layer(facing_entry):
					for layer_name in facing_entry.keys():
						if str(layer_name).begins_with("_"):
							continue
						_load_object_sprite("propstagevariant:%s:%s:%s:default:%s" % [prop_id, stage, facing, layer_name], str(facing_entry[layer_name]))
					continue
				for variant_key in facing_entry.keys():
					if str(variant_key).begins_with("_") or not facing_entry[variant_key] is Dictionary:
						continue
					var variant_entry: Dictionary = facing_entry[variant_key]
					for layer_name in variant_entry.keys():
						if str(layer_name).begins_with("_"):
							continue
						_load_object_sprite("propstagevariant:%s:%s:%s:%s:%s" % [prop_id, stage, facing, variant_key, layer_name], str(variant_entry[layer_name]))
	for trap_id in manifest.get("traps", {}).keys():
		var trap: Dictionary = manifest.get("traps", {})[trap_id]
		for animation_name in trap.get("frames", {}).keys():
			var loaded_count := 0
			var frames: Array = trap.get("frames", {})[animation_name]
			for index in range(frames.size()):
				var texture_key = "trap:%s:%s:%02d" % [trap_id, animation_name, index]
				_load_object_sprite(texture_key, str(frames[index]))
				if object_sprite_textures.has(texture_key):
					loaded_count += 1
			trap_animation_frame_counts["%s:%s" % [trap_id, animation_name]] = loaded_count

func _load_object_sprite(texture_key: String, file_hint: String) -> void:
	if _is_rejected_runtime_sprite(file_hint):
		return
	var path = file_hint if file_hint.begins_with("res://") else "res://%s" % file_hint
	if not ResourceLoader.exists(path):
		missing_object_sprites.append(texture_key)
		return
	var texture = ResourceLoader.load(path)
	if texture is Texture2D:
		object_sprite_textures[texture_key] = texture
	else:
		missing_object_sprites.append(texture_key)

func _is_rejected_runtime_sprite(file_hint: String) -> bool:
	var normalized_path := file_hint
	if normalized_path.begins_with("res://"):
		normalized_path = normalized_path.substr(6)
	var policy: Dictionary = DataRegistry.quarter_asset_manifest.get("rejected_visual_material_policy", {})
	for rejected_path in policy.get("must_not_load_as_runtime_sprites", []):
		if str(rejected_path) == normalized_path:
			return true
	return false

func _floor_tile_texture(mask: int) -> Texture2D:
	return floor_tile_textures.get(mask, null)

func _edge_open(cell: Vector2i, side: String) -> bool:
	return last_visual_open_edge_set.has(AutoTileMaskScript.edge_key(cell, side))

func _edge_points(diamond: PackedVector2Array, side: String) -> Array:
	match side:
		"N":
			return [diamond[0], diamond[1]]
		"E":
			return [diamond[1], diamond[2]]
		"S":
			return [diamond[2], diamond[3]]
		"W":
			return [diamond[3], diamond[0]]
	return []

func _wall_render_layer(side: String) -> String:
	return "wall_front" if ["E", "S"].has(side) else "wall_back"

func _side_sort_index(side: String) -> int:
	match side:
		"N":
			return 0
		"W":
			return 1
		"E":
			return 2
		"S":
			return 3
	return 4

func _edge_texture_key(side: String) -> String:
	match side:
		"N":
			return "ne_lip"
		"E":
			return "se_lip"
		"S":
			return "sw_lip"
		"W":
			return "nw_lip"
	return ""

func _draw_floor_corner_overlays(cell: Vector2i, rect: Rect2) -> void:
	if corner_overlay_textures.is_empty():
		return
	var open = {
		"N": _edge_open(cell, "N"),
		"E": _edge_open(cell, "E"),
		"S": _edge_open(cell, "S"),
		"W": _edge_open(cell, "W")
	}
	var closed = {
		"N": not bool(open["N"]),
		"E": not bool(open["E"]),
		"S": not bool(open["S"]),
		"W": not bool(open["W"])
	}
	_draw_corner_overlay_if_needed("outer_nw", bool(closed["N"]) and bool(closed["W"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_ne", bool(closed["N"]) and bool(closed["E"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_se", bool(closed["S"]) and bool(closed["E"]), rect, 0.42)
	_draw_corner_overlay_if_needed("outer_sw", bool(closed["S"]) and bool(closed["W"]), rect, 0.42)
	_draw_corner_overlay_if_needed("inner_nw", bool(open["N"]) and bool(open["W"]) and (bool(closed["E"]) or bool(closed["S"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_ne", bool(open["N"]) and bool(open["E"]) and (bool(closed["S"]) or bool(closed["W"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_se", bool(open["S"]) and bool(open["E"]) and (bool(closed["N"]) or bool(closed["W"])), rect, 0.30)
	_draw_corner_overlay_if_needed("inner_sw", bool(open["S"]) and bool(open["W"]) and (bool(closed["N"]) or bool(closed["E"])), rect, 0.30)

func _draw_corner_overlay_if_needed(key: String, should_draw: bool, rect: Rect2, alpha: float) -> void:
	if not should_draw:
		return
	var texture = corner_overlay_textures.get(key, null)
	if texture is Texture2D:
		root.draw_texture_rect(texture, rect.grow(2.0), false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, alpha))

func _socket_cap_key(state: String, side: String) -> String:
	return "%s:%s" % [state, side]

func _socket_render_layer(side: String) -> String:
	return "front" if ["E", "S"].has(side) else "back"

func _draw_socket_cap_texture(
	state: String,
	side: String,
	rect: Rect2,
	alpha: float,
	draw_target: CanvasItem = null
) -> bool:
	var texture = socket_cap_textures.get(_socket_cap_key(state, side), null)
	if not texture is Texture2D:
		return false
	var draw_rect = _socket_cap_rect(texture, state, side, rect)
	var target: CanvasItem = draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return false
	target.draw_texture_rect(texture, draw_rect, false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, alpha))
	return true

func _socket_cap_rect(texture: Texture2D, state: String, side: String, rect: Rect2) -> Rect2:
	var width = rect.size.x
	var point = _socket_point(rect, side)
	var bottom_y = point.y + rect.size.y * 0.18
	match state:
		"connected":
			width = rect.size.x * 0.74
			bottom_y = point.y + rect.size.y * 0.22
		"open_placeholder":
			width = rect.size.x * 0.58
			bottom_y = point.y + rect.size.y * 0.18
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	match side:
		"N":
			point.x += rect.size.x * 0.06
		"W":
			point.x -= rect.size.x * 0.06
		"E":
			point.x += rect.size.x * 0.05
		"S":
			point.x -= rect.size.x * 0.05
	return Rect2(Vector2(point.x - width * 0.5, bottom_y - height), Vector2(width, height))

func _draw_wall_edge_record(
	record: Dictionary,
	draw_target: CanvasItem = null,
	alpha_override: float = -1.0
) -> bool:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return false
	var state := str(record.get("state", "closed"))
	if state not in ["closed", "open_placeholder"]:
		return false
	# 닫힌 경계와 open_placeholder는 모두 catalog의 structural_boundary만 사용한다.
	# marker는 별도 socket 레이어가 한 번만 그리며 벽 본체를 대신하지 않는다.
	var asset_id := str(record.get("structural_asset_id", ""))
	var texture = structural_wall_textures.get(asset_id, null)
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	if not texture is Texture2D or str(entry.get("piece_kind", "")) != "edge_segment":
		return false
	var structural_rect := _structural_edge_draw_rect(texture, entry, record)
	var alpha := alpha_override if alpha_override >= 0.0 else _wall_edge_alpha("closed")
	target.draw_texture_rect(texture, structural_rect, false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, alpha))
	return true


func _draw_wall_edge_front_occluder(record: Dictionary, draw_target: CanvasItem = null) -> bool:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return false
	var asset_id := str(record.get("structural_asset_id", ""))
	var body_texture = structural_wall_textures.get(asset_id, null)
	var occluder_texture = structural_wall_front_occluder_textures.get(asset_id, null)
	var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
	if (
		not body_texture is Texture2D
		or not occluder_texture is Texture2D
		or str(entry.get("piece_kind", "")) != "edge_segment"
	):
		# 높은 벽 본체를 앞층 fallback으로 그리지 않는다.
		return false
	var structural_rect := _structural_edge_draw_rect(body_texture, entry, record)
	target.draw_texture_rect(occluder_texture, structural_rect, false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, _wall_edge_alpha("closed")))
	return true


func _draw_wall_vertex_body_layer(
	tile_grid: Dictionary,
	draw_target: CanvasItem = null,
	render_scope: String = "all",
	alpha_override: float = -1.0
) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	for vertex_value in tile_grid.get("wall_vertices", []):
		if not vertex_value is Dictionary:
			continue
		var vertex: Dictionary = vertex_value
		var kind := str(vertex.get("kind", ""))
		if not kind in ["corner", "cap", "junction"]:
			continue
		var front_facing := _vertex_has_front_incident(vertex)
		if render_scope == "rear" and front_facing:
			continue
		if render_scope == "front" and not front_facing:
			continue
		var asset_id := str(vertex.get("structural_asset_id", ""))
		var texture = structural_wall_textures.get(asset_id, null)
		var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
		if not texture is Texture2D or entry.is_empty():
			continue
		var draw_rect := _structural_vertex_draw_rect(texture, entry, vertex)
		var alpha := alpha_override if alpha_override >= 0.0 else _wall_edge_alpha("closed")
		target.draw_texture_rect(texture, draw_rect, false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, alpha))


func _draw_wall_vertex_front_occluder_layer(tile_grid: Dictionary, draw_target: CanvasItem = null) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	for vertex_value in tile_grid.get("wall_vertices", []):
		if not vertex_value is Dictionary:
			continue
		var vertex: Dictionary = vertex_value
		var kind := str(vertex.get("kind", ""))
		if not kind in ["corner", "cap", "junction"] or not _vertex_has_front_incident(vertex):
			continue
		var asset_id := str(vertex.get("structural_asset_id", ""))
		var body_texture = structural_wall_textures.get(asset_id, null)
		var occluder_texture = structural_wall_front_occluder_textures.get(asset_id, null)
		var entry: Dictionary = structural_wall_asset_entries.get(asset_id, {})
		if not body_texture is Texture2D or not occluder_texture is Texture2D or entry.is_empty():
			# 정점도 높은 본체를 앞층 fallback으로 올리지 않는다.
			continue
		var draw_rect := _structural_vertex_draw_rect(body_texture, entry, vertex)
		target.draw_texture_rect(occluder_texture, draw_rect, false, _active_profile_color_with_alpha("wall_modulate", Color.WHITE, _wall_edge_alpha("closed")))


func _vertex_has_front_incident(vertex: Dictionary) -> bool:
	for direction_value in vertex.get("incident_directions", []):
		if str(direction_value) in ["E", "S"]:
			return true
	return false


func _structural_vertex_asset_overlays_enabled() -> bool:
	return str(_active_structural_wall_set().get("vertex_render_policy", "asset_overlay")) == "asset_overlay"


func _structural_edge_draw_rect(texture: Texture2D, entry: Dictionary, record: Dictionary) -> Rect2:
	var scale := _structural_edge_scale(texture, entry, record)
	var fallback_anchor := _structural_asset_anchor(entry)
	var source_start := _catalog_vector2(entry.get("connector_start_px", []), fallback_anchor)
	var source_end := _catalog_vector2(entry.get("connector_end_px", []), fallback_anchor)
	var source_anchor := source_start.lerp(source_end, 0.5)
	var start: Vector2 = record.get("start", Vector2.ZERO)
	var end: Vector2 = record.get("end", Vector2.ZERO)
	var target_anchor := start.lerp(end, 0.5)
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(target_anchor - source_anchor * scale, draw_size)


func _structural_vertex_draw_rect(texture: Texture2D, entry: Dictionary, vertex: Dictionary) -> Rect2:
	var reference_asset_id := str(vertex.get("reference_segment_asset_id", ""))
	var reference_texture = structural_wall_textures.get(reference_asset_id, null)
	var reference_entry: Dictionary = structural_wall_asset_entries.get(reference_asset_id, {})
	var scale := 1.0
	if reference_texture is Texture2D and not reference_entry.is_empty():
		scale = _structural_edge_scale(reference_texture, reference_entry, {
			"rect": vertex.get("reference_rect", Rect2()),
			"start": vertex.get("reference_edge_start", Vector2.ZERO),
			"end": vertex.get("reference_edge_end", Vector2.ZERO),
			"structural_asset_id": reference_asset_id
		})
	var source_anchor := _structural_asset_anchor(entry)
	var target_anchor: Vector2 = vertex.get("screen_position", Vector2.ZERO)
	var draw_size := Vector2(texture.get_width(), texture.get_height()) * scale
	return Rect2(target_anchor - source_anchor * scale, draw_size)


func _structural_edge_scale(_texture: Texture2D, entry: Dictionary, record: Dictionary) -> float:
	var start: Vector2 = record.get("start", Vector2.ZERO)
	var end: Vector2 = record.get("end", Vector2.ZERO)
	var edge_length := maxf(1.0, start.distance_to(end))
	var fallback_anchor := _structural_asset_anchor(entry)
	var source_start := _catalog_vector2(entry.get("connector_start_px", []), fallback_anchor)
	var source_end := _catalog_vector2(entry.get("connector_end_px", []), fallback_anchor)
	var connector_length := maxf(1.0, source_start.distance_to(source_end))
	var reference_rect: Rect2 = record.get("rect", Rect2())
	var join_profile := _structural_join_profile(entry)
	var tile_size := _catalog_vector2(join_profile.get("tile_size_px", []), Vector2(128.0, 64.0))
	var runtime_scale := minf(
		reference_rect.size.x / maxf(1.0, tile_size.x),
		reference_rect.size.y / maxf(1.0, tile_size.y)
	)
	var overlap := float(join_profile.get("connector_overlap_px", 0.0)) * maxf(0.0, runtime_scale)
	return (edge_length + overlap) / connector_length


func _structural_asset_anchor(entry: Dictionary) -> Vector2:
	var join_profile := _structural_join_profile(entry)
	return _catalog_vector2(entry.get("anchor_px", join_profile.get("anchor_px", [])), Vector2(128.0, 232.0))


func _structural_join_profile(entry: Dictionary) -> Dictionary:
	var profile_id := str(entry.get("join_profile", ""))
	var profiles: Dictionary = DataRegistry.quarter_wall_asset_catalog.get("join_profiles", {})
	var profile_value = profiles.get(profile_id, {})
	return profile_value if profile_value is Dictionary else {}


func _catalog_vector2(value, fallback: Vector2) -> Vector2:
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _wall_edge_alpha(state: String) -> float:
	var settings := _wall_render_settings()
	if not settings.is_empty():
		return (
			float(settings.get("placeholder_alpha", 0.78))
			if state == "open_placeholder"
			else float(settings.get("closed_alpha", 0.98))
		)
	if state == "open_placeholder":
		return 0.46
	return 0.56

func _front_wall_alpha() -> float:
	var settings := _wall_render_settings()
	return clampf(float(settings.get("front_occlusion_alpha", 0.46)), 0.30, 0.58)

func _wall_render_settings() -> Dictionary:
	var profile := _active_spatial_profile()
	var settings = profile.get("wall_render", {})
	return settings if settings is Dictionary else {}

func _draw_doorway_threshold(side: String, rect: Rect2) -> void:
	var diamond = _diamond(rect.grow(-2.0))
	var start: Vector2
	var end: Vector2
	match side:
		"N":
			start = diamond[0]
			end = diamond[1]
		"E":
			start = diamond[1]
			end = diamond[2]
		"S":
			start = diamond[2]
			end = diamond[3]
		"W":
			start = diamond[3]
			end = diamond[0]
		_:
			return
	var center = start.lerp(end, 0.5)
	root.draw_line(center.lerp(start, 0.38), center.lerp(end, 0.38), Color("#8d746066"), 1.4)

func _object_slot_rect(slot: Dictionary) -> Rect2:
	var cell: Vector2i = slot.get("cell", Vector2i.ZERO)
	var bounds = root.graph.tile_cell_rect(cell).grow(-2.0)
	for value in slot.get("footprint", [[0, 0]]):
		if not value is Array:
			continue
		var footprint_cell = cell + Vector2i(int(value[0]), int(value[1]))
		bounds = bounds.merge(root.graph.tile_cell_rect(footprint_cell).grow(-2.0))
	return bounds

func _object_draw_rect(slot: Dictionary, texture_key: String) -> Rect2:
	if _is_full_grid_room_slot(slot) and not _object_texture_uses_projection_safe_room_sprite(texture_key):
		return _object_full_grid_room_rect(slot)
	return _object_slot_rect(slot)

func _object_full_grid_room_rect(slot: Dictionary) -> Rect2:
	return _object_slot_rect(slot).grow(6.0)

func _object_footprint_cells(slot: Dictionary) -> Array:
	var base_cell: Vector2i = slot.get("cell", Vector2i.ZERO)
	var cells: Array = []
	for value in slot.get("footprint", [[0, 0]]):
		if value is Array:
			cells.append(base_cell + Vector2i(int(value[0]), int(value[1])))
	return cells

func _is_full_grid_room_slot(slot: Dictionary) -> bool:
	return slot.get("footprint", []).size() >= 25 and str(slot.get("id", "")) != "spike_floor"

func _draw_object_texture(
	texture: Texture2D,
	rect: Rect2,
	slot_id: String,
	layer_name: String,
	full_grid_room_fallback: bool = false,
	projection_safe_full_grid: bool = false,
	draw_target: CanvasItem = null
) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	var draw_rect := _object_texture_draw_rect(texture, rect, slot_id, layer_name, full_grid_room_fallback, projection_safe_full_grid)
	var placement = _object_placement(slot_id, layer_name)
	target.draw_texture_rect(texture, draw_rect, false, _active_profile_color_with_alpha("object_modulate", Color.WHITE, float(placement.get("alpha", 0.98))))

func _object_texture_draw_rect(
	texture: Texture2D,
	rect: Rect2,
	slot_id: String,
	layer_name: String,
	full_grid_room_fallback: bool = false,
	projection_safe_full_grid: bool = false
) -> Rect2:
	var placement = _object_placement(slot_id, layer_name)
	var width_scale_value = float(placement.get("fit_width", _object_texture_width_scale(slot_id)))
	if full_grid_room_fallback:
		width_scale_value = maxf(width_scale_value, _full_grid_room_width_scale(slot_id, layer_name))
	elif projection_safe_full_grid:
		width_scale_value = 1.0
	var width_scale_max := 1.72 if full_grid_room_fallback else 1.18
	var width_scale = clampf(width_scale_value, 0.10, width_scale_max)
	var width = rect.size.x * width_scale
	var height = width * float(texture.get_height()) / float(maxi(1, texture.get_width()))
	var max_height_value = float(placement.get("max_height", 0.78))
	if full_grid_room_fallback:
		max_height_value = maxf(max_height_value, _full_grid_room_max_height(slot_id, layer_name))
	elif projection_safe_full_grid:
		max_height_value = 2.02
	var max_height_scale_max := 2.04 if projection_safe_full_grid else (1.90 if full_grid_room_fallback else 1.16)
	var max_height = rect.size.y * clampf(max_height_value, 0.10, max_height_scale_max)
	if max_height > 1.0 and height > max_height:
		var shrink = max_height / height
		width *= shrink
		height = max_height
	var bottom_offset_value = float(placement.get("bottom_offset", _object_texture_bottom_offset(slot_id, layer_name)))
	if full_grid_room_fallback:
		bottom_offset_value = _full_grid_room_bottom_offset(slot_id, layer_name)
	elif projection_safe_full_grid:
		bottom_offset_value = 0.05
	var bottom_offset = clampf(bottom_offset_value, -0.46, 0.18)
	var x_offset = float(placement.get("x_offset", 0.0))
	var center_x = rect.get_center().x + rect.size.x * x_offset
	var bottom_y = rect.end.y + rect.size.y * bottom_offset
	return Rect2(Vector2(center_x - width * 0.5, bottom_y - height), Vector2(width, height))

func _full_grid_room_width_scale(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 1.58
		"entrance_gate_f":
			return 1.54
		"weapon_rack":
			return 1.50
		"recovery_nest_f", "treasure_pile_large":
			return 1.42
		"foundation_marks":
			return 1.34
	return 1.46

func _full_grid_room_max_height(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 1.90
		"entrance_gate_f":
			return 1.70
		"weapon_rack":
			return 1.62
		"recovery_nest_f", "treasure_pile_large":
			return 1.48
		"foundation_marks":
			return 1.28
	return 1.52

func _full_grid_room_bottom_offset(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"throne_f":
			return 0.06 if layer_name == "front" else 0.02
		"entrance_gate_f", "weapon_rack":
			return 0.00
		"recovery_nest_f", "treasure_pile_large":
			return 0.04
		"foundation_marks":
			return 0.00
	return 0.02

func _draw_object_connection_marks(
	slot: Dictionary,
	rect: Rect2,
	slot_id: String,
	layer_name: String,
	draw_target: CanvasItem = null
) -> void:
	var target := draw_target if draw_target != null else root as CanvasItem
	if target == null:
		return
	var sides: Array = slot.get("connected_sides", [])
	if _is_full_grid_room_slot(slot) or sides.is_empty() or _has_connection_sprite_for_variant(slot_id, str(slot.get("connection_variant", ""))) or not _should_draw_object_connection_marks(slot_id, slot, layer_name):
		return
	var diamond = _diamond(rect.grow(-4.0))
	var mark_width = maxf(5.0, rect.size.y * 0.045)
	for side_value in sides:
		var side = str(side_value)
		var points = _edge_points(diamond, side)
		if points.size() < 2:
			continue
		var start = points[0].lerp(points[1], 0.34)
		var end = points[0].lerp(points[1], 0.66)
		target.draw_line(start, end, Color("#100b0dcc"), mark_width + 4.0, true)
		target.draw_line(start, end, Color("#b99a67bb"), mark_width, true)
		target.draw_line(start, end, Color("#f0dda488"), maxf(1.5, mark_width * 0.24), true)

func _should_draw_object_connection_marks(slot_id: String, slot: Dictionary, layer_name: String) -> bool:
	if layer_name == "front":
		return true
	var slot_layer = str(slot.get("layer", "front"))
	return slot_layer == layer_name and not _object_has_front_visual(slot_id)

func _object_has_front_visual(slot_id: String) -> bool:
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	if prop.get("sprites", {}).has("front"):
		return true
	for stacked_layer in prop.get("stack_layers", []):
		if str(stacked_layer) == "front":
			return true
	for facing_entry in prop.get("facing_sprites", {}).values():
		if facing_entry is Dictionary and facing_entry.has("front"):
			return true
	for stage_entry in prop.get("stage_facing_sprites", {}).values():
		if not stage_entry is Dictionary:
			continue
		for facing_entry in stage_entry.values():
			if facing_entry is Dictionary and facing_entry.has("front"):
				return true
	for stage_entry in prop.get("upgrade_stage_sprites", {}).values():
		if not stage_entry is Dictionary:
			continue
		for facing_entry in stage_entry.values():
			if not facing_entry is Dictionary:
				continue
			if facing_entry.has("front"):
				return true
			for variant_entry in facing_entry.values():
				if variant_entry is Dictionary and variant_entry.has("front"):
					return true
	return false

func _has_connection_sprite_for_variant(slot_id: String, variant: String) -> bool:
	if variant == "":
		return false
	return _connection_sprite_projection_safe(slot_id, variant)

func _connection_sprite_projection_safe(slot_id: String, variant: String) -> bool:
	if variant == "":
		return false
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	if not prop.get("connection_sprites", {}).has(variant):
		return false
	var projection_value = prop.get("connection_sprite_projection", "")
	if projection_value is Dictionary:
		projection_value = projection_value.get(variant, "")
	return str(projection_value) == "iso_diamond_5x5"

func _object_texture_uses_projection_safe_room_sprite(texture_key: String) -> bool:
	if texture_key == "propstage:throne_f:stage_01_cave:SW:back":
		return true
	var parts = texture_key.split(":")
	if parts.size() != 4 or str(parts[0]) != "prop":
		return false
	return _connection_sprite_projection_safe(str(parts[1]), str(parts[2]))

func _prop_can_draw_layer(prop: Dictionary, slot_layer: String, layer_name: String) -> bool:
	if slot_layer == layer_name:
		return true
	for stacked_layer in prop.get("stack_layers", []):
		if str(stacked_layer) == layer_name:
			return true
	return false

func _object_placement(slot_id: String, layer_name: String) -> Dictionary:
	var props: Dictionary = DataRegistry.quarter_asset_manifest.get("props", {})
	var prop: Dictionary = props.get(slot_id, {})
	var placement_root: Dictionary = prop.get("placement", {})
	var result: Dictionary = {}
	for key in placement_root.get("default", {}).keys():
		result[key] = placement_root["default"][key]
	if placement_root.has(layer_name):
		var layer_placement: Dictionary = placement_root[layer_name]
		for key in layer_placement.keys():
			result[key] = layer_placement[key]
	var stage_placement_root: Dictionary = prop.get("stage_placement", {})
	var stage_placement: Dictionary = stage_placement_root.get(_active_castle_art_stage(), {})
	for key in stage_placement.get("default", {}).keys():
		result[key] = stage_placement["default"][key]
	if stage_placement.has(layer_name):
		var stage_layer_placement: Dictionary = stage_placement[layer_name]
		for key in stage_layer_placement.keys():
			result[key] = stage_layer_placement[key]
	return result

func _object_texture_width_scale(slot_id: String) -> float:
	match slot_id:
		"small_brazier":
			return 0.88
		"foundation_marks":
			return 1.08
		"spike_floor":
			return 1.02
		"treasure_pile_large":
			return 1.26
		"recovery_nest_f":
			return 1.22
		"weapon_rack":
			return 1.32
		"entrance_gate_f":
			return 1.30
		"throne_f":
			return 1.18
		"watch_post":
			return 1.04
	return 0.96

func _object_texture_bottom_offset(slot_id: String, layer_name: String) -> float:
	match slot_id:
		"spike_floor", "foundation_marks":
			return 0.00
		"small_brazier":
			return 0.02
		"entrance_gate_f", "weapon_rack":
			return 0.00
		"throne_f":
			return 0.08 if layer_name == "front" else 0.02
		"treasure_pile_large", "recovery_nest_f":
			return 0.04
		"watch_post":
			return 0.04
	return 0.02 if layer_name == "front" else -0.01

func _spawn_trap_animation_sprite(instance_id: String, trap_id: String, animation_key: String) -> void:
	if root == null:
		return
	var parent := root.get("world_overlay_layer") as Node2D
	if parent == null:
		return
	var slot: Dictionary = {}
	for slot_value in _tile_grid_for_draw().get("objects", []):
		if not slot_value is Dictionary:
			continue
		if str(slot_value.get("instance_id", "")) == instance_id and str(slot_value.get("id", "")) == trap_id:
			slot = slot_value
			break
	if slot.is_empty():
		return
	var frames := SpriteFrames.new()
	frames.add_animation("trigger")
	frames.set_animation_loop("trigger", false)
	frames.set_animation_speed("trigger", 1000.0 / float(TRAP_TRIGGER_FRAME_MSEC))
	var first_texture: Texture2D
	for frame_index in range(_trap_animation_frame_count(trap_id, "trigger")):
		var texture := object_sprite_textures.get("trap:%s:trigger:%02d" % [trap_id, frame_index], null) as Texture2D
		if texture == null:
			continue
		if first_texture == null:
			first_texture = texture
		frames.add_frame("trigger", texture)
	if first_texture == null or frames.get_frame_count("trigger") <= 0:
		return
	var previous := trap_animation_sprites.get(animation_key, null) as AnimatedSprite2D
	if previous != null and is_instance_valid(previous):
		previous.queue_free()
	var layer_name := str(slot.get("layer", "front"))
	var slot_rect := _object_draw_rect(slot, "trap:%s:trigger:00" % trap_id)
	var draw_rect := _object_texture_draw_rect(first_texture, slot_rect, trap_id, layer_name)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "TrapAnimation_%s" % animation_key.replace(":", "_")
	sprite.sprite_frames = frames
	sprite.animation = "trigger"
	sprite.centered = true
	sprite.position = draw_rect.get_center()
	sprite.scale = draw_rect.size / first_texture.get_size()
	sprite.modulate = _active_profile_color_with_alpha("object_modulate", Color.WHITE, float(_object_placement(trap_id, layer_name).get("alpha", 0.98)))
	parent.add_child(sprite)
	trap_animation_sprites[animation_key] = sprite
	sprite.animation_finished.connect(_on_trap_animation_sprite_finished.bind(animation_key, sprite))
	sprite.play("trigger")

func _on_trap_animation_sprite_finished(animation_key: String, sprite: AnimatedSprite2D) -> void:
	if trap_animation_sprites.get(animation_key, null) == sprite:
		trap_animation_sprites.erase(animation_key)
	active_trap_animations.erase(animation_key)
	if sprite != null and is_instance_valid(sprite):
		sprite.queue_free()

func _idle_trap_texture_key(trap_id: String) -> String:
	if _trap_animation_frame_count(trap_id, "idle") > 0:
		return "trap:%s:idle:00" % trap_id
	return ""

func _active_trap_texture_key(instance_id: String, trap_id: String) -> String:
	var animation_key = _trap_animation_key(instance_id, trap_id)
	if active_trap_animations.has(animation_key):
		var frame_count = _trap_animation_frame_count(trap_id, "trigger")
		var elapsed = maxi(0, int(Time.get_ticks_msec()) - int(active_trap_animations[animation_key]))
		var frame_index = int(elapsed / TRAP_TRIGGER_FRAME_MSEC)
		if frame_index >= frame_count:
			active_trap_animations.erase(animation_key)
		else:
			return "trap:%s:trigger:%02d" % [trap_id, frame_index]
	return _idle_trap_texture_key(trap_id)

func _trap_animation_frame_count(trap_id: String, animation_name: String) -> int:
	return int(trap_animation_frame_counts.get("%s:%s" % [trap_id, animation_name], 0))

func _trap_animation_key(instance_id: String, trap_id: String) -> String:
	return "%s:%s" % [instance_id, trap_id]

func _prune_finished_trap_animations() -> void:
	for animation_key in active_trap_animations.keys():
		var trap_id = str(animation_key).get_slice(":", 1)
		var frame_count = _trap_animation_frame_count(trap_id, "trigger")
		var elapsed = maxi(0, int(Time.get_ticks_msec()) - int(active_trap_animations[animation_key]))
		if frame_count <= 0 or int(elapsed / TRAP_TRIGGER_FRAME_MSEC) >= frame_count:
			active_trap_animations.erase(animation_key)

func _socket_point(rect: Rect2, side: String) -> Vector2:
	var center = rect.get_center()
	match side:
		"N":
			return Vector2(center.x + rect.size.x * 0.18, rect.position.y + rect.size.y * 0.08)
		"E":
			return Vector2(rect.end.x - rect.size.x * 0.08, center.y + rect.size.y * 0.18)
		"S":
			return Vector2(center.x - rect.size.x * 0.18, rect.end.y - rect.size.y * 0.08)
		"W":
			return Vector2(rect.position.x + rect.size.x * 0.08, center.y - rect.size.y * 0.18)
	return center

func _nearest_record(tile_grid: Dictionary, point: Vector2) -> Dictionary:
	var best_record: Dictionary = {}
	var best_distance = INF
	for record in tile_grid["cells"]:
		var distance = record["rect"].get_center().distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best_record = record
	return best_record

func _mouse_world_position() -> Vector2:
	var screen_point = root.get_viewport().get_mouse_position()
	if root.current_screen == Constants.SCREEN_COMBAT:
		return root._combat_screen_to_world(screen_point)
	return root.get_global_mouse_position()

func _diamond(rect: Rect2) -> PackedVector2Array:
	var center = rect.get_center()
	return PackedVector2Array([
		Vector2(center.x, rect.position.y),
		Vector2(rect.end.x, center.y),
		Vector2(center.x, rect.end.y),
		Vector2(rect.position.x, center.y)
	])
