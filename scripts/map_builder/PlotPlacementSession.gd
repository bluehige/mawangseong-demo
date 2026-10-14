extends RefCounted
# Runtime layout editing only; save format migration belongs to M6.
const Service = preload("res://scripts/map_builder/MapBuildService.gd")
const Iso = preload("res://scripts/dungeon_quarter/IsoMath.gd")
var root: Node
var moving_id := ""
var rotation := 0
var preview: Dictionary = {}
var preview_key := ""
var highlights: Dictionary = {}
var ghost_graph = null
var watch_key := ""
var watch_rooms: Array[String] = []

func watch_range() -> Array[String]:
	var ids: Array[String] = root._rooms_by_facility("watch_post")
	if ids.is_empty(): return []
	var enabled: Array = []
	for id in ids: enabled.append([id,root._facility_room_is_active(id)])
	var key := "%s:%s:%s" % [root.graph.get_instance_id(),enabled,root.get_meta("v122_command_state",{}).hash()]
	if key == watch_key: return watch_rooms
	watch_key = key
	watch_rooms = []
	var plan: Dictionary = root._v122_current_battle_plan()
	var slots: Array = plan.get("facility_slots",[])
	var by_zone: bool = not plan.get("defense_zones",[]).is_empty() and not slots.is_empty()
	for slot in slots:
		if slot.get("linked_zone_ids",[]).is_empty(): by_zone = false
	if not by_zone:
		watch_rooms = root._active_watch_post_pressure_rooms()
		return watch_rooms
	var states: Array = []
	for slot in slots:
		states.append({"slot_id":slot.slot_id,"facility_role":slot.facility_role,"disabled":not root._facility_room_is_active(slot.room_id),"power_multiplier":root.combat_scene._v122_active_facility_power(slot.slot_id)})
	var resolver = preload("res://scripts/v122/spatial/V122FacilityZoneEffectResolver.gd")
	var effects: Dictionary = resolver.resolve_by_zone(plan,states,resolver.load_catalog())
	var zones: Dictionary = root.combat_scene._v122_room_to_zone_map(plan)
	for id in root.graph.module_instance_ids():
		for effect in effects.get(zones.get(id,""),[]):
			if effect.get("category","") == "detection" and effect.get("target","") == "enemies" and effect.get("facility_role","") == "watch_post":
				watch_rooms.append(id)
				break
	watch_rooms.sort()
	return watch_rooms

func active() -> bool:
	return root != null and Service.is_plot(root.graph) and root.build_pick_mode and root.build_pick_facility_id != ""

func reset() -> void:
	moving_id = ""
	rotation = 0
	preview.clear()
	preview_key = ""
	highlights.clear()
	ghost_graph = null

func source() -> Dictionary:
	if not root.runtime_plot_layout.is_empty(): return root.runtime_plot_layout.duplicate(true)
	var result: Dictionary = root._layout_with_castle_stage_expansions(DataRegistry.quarter_layout(root.quarter_layout_id))
	result["plot_grid"] = root.graph.layout.plot_grid.duplicate(true)
	for row in result.get("placed_modules",[]):
		var placed: Dictionary = root.graph.placed_module_data(str(row.instance_id))
		if not placed.is_empty():
			var cell: Vector2i = Iso.array_to_cell(placed.grid_origin)
			row["grid_origin"] = [cell.x,cell.y]
	return result

func cell_at(point: Vector2) -> Vector2i:
	return Iso.iso_world_to_cell(point,root.graph.tile_world_origin,root.graph.tile_size.x*root.graph.tile_visual_scale,root.graph.tile_size.y*root.graph.tile_visual_scale)

func world(cell: Vector2i) -> Vector2:
	return Iso.cell_to_iso_world(cell,root.graph.tile_world_origin,root.graph.tile_size.x*root.graph.tile_visual_scale,root.graph.tile_size.y*root.graph.tile_visual_scale)

func target(point: Vector2) -> String:
	if moving_id != "": return moving_id
	var existing: String = root.build_placement.target_room(point)
	if root._can_change_room_facility(existing): return existing
	for id in root.rooms:
		if root._can_change_room_facility(id) and root.rooms[id].get("facility_role","") == "build_slot": return id
	return ""

func update(point: Vector2, over_ui: bool = false) -> void:
	if not active(): return
	var id := target(point)
	var origin := cell_at(point) - Vector2i(2,2)
	if moving_id == "" and root._can_change_room_facility(root.build_placement.target_room(point)):
		origin = Iso.array_to_cell(root.graph.placed_module_data(id).grid_origin)
	var key := "%s:%s:%s:%s:%s" % [id,origin,rotation,root.build_pick_facility_id,over_ui]
	if key == preview_key: return
	preview_key = key
	preview = assess(id,origin,rotation)
	if over_ui: preview.ok = false
	ghost_graph = null
	if preview.ok:
		ghost_graph = preload("res://scripts/dungeon_quarter/ModuleGraph.gd").new()
		ghost_graph.setup_quarter(DataRegistry.quarter_modules,preview.layout,root.rooms)
	root.queue_world_overlay_redraw()

func assess(id: String, origin: Vector2i, orientation: int) -> Dictionary:
	var result := {"ok":false,"id":id,"origin":origin,"rotation":orientation,"size":Vector2i(5,5),"reason":root.continuity.localized("빈 건설 구역이 없습니다","No open construction area","没有空闲建造区域"),"warnings":[],"cost":{},"layout":{},"source":{}}
	if id == "" or not root.rooms.has(id): return result
	var candidate := source()
	for row in candidate.placed_modules:
		if row.instance_id != id: continue
		row["grid_origin"] = [origin.x,origin.y]
		row["plot_rotation"] = orientation
		var size := Iso.array_to_cell(DataRegistry.quarter_modules[row.module_id].get("size",[5,5]))
		result.size = Vector2i(size.y,size.x) if orientation == 1 else size
	var layout := Service.prepare_layout(candidate,DataRegistry.quarter_modules,int(root.graph.layout.plot_grid.grade_index))
	result.source = candidate
	result.layout = layout
	if layout.has("map_build_errors"):
		result.reason = root.continuity.localized("건물 간격·부지·입구–왕좌 길을 확인하세요","Check spacing, plot bounds and entrance–throne road","请检查建筑间距、地块边界及入口至王座的道路")
		return result
	if moving_id == "":
		var assessment: Dictionary = root._evaluate_facility_placement(id,root.build_pick_facility_id)
		result.warnings = assessment.warnings
		result.cost = assessment.cost
		if not assessment.ok:
			result.reason = assessment.reason
			return result
	result.ok = true
	result.reason = root.continuity.localized("놓으면 즉시 설치 · 되돌리기 가능","Drop to install · Undo available","放下立即安装 · 可撤销")
	return result

func commit() -> bool:
	if not active() or preview.is_empty() or not preview.ok or root.build_placement.pointer_active: return false
	# Recheck resources and roads at the actual commit boundary.
	preview = assess(preview.id,preview.origin,preview.rotation)
	if not preview.ok: return false
	var before: Dictionary = root.runtime_plot_layout.duplicate(true)
	var id: String = preview.id
	var next_source: Dictionary = preview.source.duplicate(true)
	if moving_id != "":
		root._capture_management_undo(root.continuity.localized("건물 이동·회전","Move or rotate building","移动或旋转建筑"))
	else:
		if not root._change_room_facility(id,root.build_pick_facility_id): return false
	root.management_undo["runtime_plot_layout"] = before
	root.runtime_plot_layout = next_source
	root.selected_room = id
	root._refresh_quarter_map_from_rooms()
	root._clear_management_action_mode(false)
	root._set_screen("management",false)
	return true

func begin_move() -> void:
	var id: String = root.selected_room
	if not Service.is_plot(root.graph) or id == "entrance" or not root._can_change_room_facility(id) and id not in ["throne","crown_sanctum","seal_vault"]: return
	root._clear_management_action_mode(false)
	moving_id = id
	for row in source().placed_modules:
		if row.instance_id == id: rotation = int(row.get("plot_rotation",0))
	root.build_pick_mode = true
	root.build_pick_facility_id = str(root.rooms[id].facility_role)
	root.management_context_drawer_open = false
	root._set_screen("management",false)

func rotate() -> void:
	if active():
		rotation = 1-rotation
		preview_key = ""
		update(root.build_placement.pointer_world)
		return
	begin_move()
	if moving_id == "": return
	rotation = 1-rotation
	var origin: Vector2i = Iso.array_to_cell(root.graph.placed_module_data(moving_id).grid_origin)
	preview = assess(moving_id,origin,rotation)
	if not commit():
		root._set_management_feedback(false,preview.reason)
		root._cancel_management_action_mode()

func demolish() -> void:
	if root._can_change_room_facility(root.selected_room):
		root._change_room_facility(root.selected_room,"build_slot")
		root._set_screen("management",false)

func _polygon(cell: Vector2i) -> PackedVector2Array:
	var center := world(cell)
	var half: Vector2 = root.graph.tile_size*root.graph.tile_visual_scale*0.5
	return PackedVector2Array([center+Vector2(0,-half.y),center+Vector2(half.x,0),center+Vector2(0,half.y),center+Vector2(-half.x,0)])

func draw(target_canvas: CanvasItem) -> void:
	if not Service.is_plot(root.graph): return
	# Exact gameplay influence, including disabled facilities and grade second ring.
	for id in watch_range():
		for cell in root.graph.tile_room_floor_cells.get(id,[]):
			target_canvas.draw_colored_polygon(_polygon(cell),Color(0.3,0.65,1,0.18))
	if not active(): return
	if highlights.is_empty():
		for cell in root.graph.layout.plot_mask:
			if not preload("res://scripts/map_builder/PlotMask.gd").contains_rect({"cells":root.graph.layout.plot_mask},Rect2i(cell,Vector2i(5,5))): continue
			var free := true
			for id in root.rooms:
				if id == moving_id: continue
				var placed: Dictionary = root.graph.placed_module_data(id)
				if placed.is_empty(): continue
				var module: Dictionary = root.graph.modules[placed.module_id]
				if module.get("module_type","") != "room": continue
				if Rect2i(Iso.array_to_cell(placed.grid_origin),Iso.array_to_cell(module.size)).grow(1).intersects(Rect2i(cell,Vector2i(5,5))): free = false; break
			if free: highlights[cell+Vector2i(2,2)] = true
	for cell in highlights: target_canvas.draw_colored_polygon(_polygon(cell),Color(0.25,1,0.45,0.08))
	if preview.is_empty(): return
	var color := Color("#6bec9a") if preview.ok else Color("#ff6878")
	for x in range(preview.origin.x,preview.origin.x+preview.size.x):
		for y in range(preview.origin.y,preview.origin.y+preview.size.y):
			target_canvas.draw_colored_polygon(_polygon(Vector2i(x,y)),Color(color,0.3))
	var preview_roads: Dictionary = preview.layout.get("auto_roads",{}).get("road_cells",{})
	if not preview.ok and preview_roads.is_empty(): preview_roads = root.graph.layout.auto_roads.road_cells
	for cell in preview_roads:
		target_canvas.draw_colored_polygon(_polygon(cell),Color(color,0.25))
	root._draw_management_screen_label(target_canvas,world(preview.origin),preview.reason,color,20,true)
