extends RefCounted
const Service = preload("res://scripts/map_builder/MapBuildService.gd")

static func formation_rooms(root: Node) -> Array[String]:
	var result: Array[String] = []
	if root.graph != null:
		for zone_id in ["zone_a_front","zone_a_rear"]:
			for slot in root.graph.layout.get("combat_topology",{}).get("facility_slots",[]):
				var id := str(slot.get("room_id",""))
				if slot.get("linked_zone_ids",[]).has(zone_id) and root.rooms.has(id) and not result.has(id):
					result.append(id)
	return result if result.size()==2 else ["barracks","recovery"]

static func register_map_targets(root: Node) -> void:
	if not Service.is_plot(root.graph): return
	root.register_tutorial_target("PLOT_ENTRANCE",root._tutorial_room_rect("entrance"))
	root.register_tutorial_target("PLOT_THRONE",root._tutorial_room_rect("throne"))
	var road := Rect2()
	for cell in root.graph.layout.auto_roads.road_cells:
		var rect: Rect2 = root.get_global_transform_with_canvas()*root.graph.tile_cell_rect(cell)
		road = rect if not road.has_area() else road.merge(rect)
	root.register_tutorial_target("AUTO_ROAD_PREVIEW",road)
	var card := root.ui_layer.find_child("FacilityCard_barracks",true,false) as Control
	if card == null or not card.is_visible_in_tree(): card = root.ui_layer.find_child("ManagementTab_build",true,false) as Control
	if card != null: root.register_tutorial_target_control("BUILD_PALETTE_CARD",card)
	var ghost: Control = root.build_placement.ghost
	if is_instance_valid(ghost) and ghost.visible:
		root.register_tutorial_target("BUILD_GHOST",ghost.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,ghost.size))
	else:
		root.register_tutorial_target("BUILD_GHOST",root._tutorial_focus_rect("DAY1_GOBLIN_FORMATION"))

static func draw(root: Node, canvas: CanvasItem) -> void:
	if not Service.is_plot(root.graph) or not root._day1_goblin_choice_active(): return
	# Guidance only: it does not add an installation action to the mandatory steps.
	for cell in root.graph.layout.auto_roads.road_cells:
		canvas.draw_colored_polygon(root.build_placement.plot._polygon(cell),Color(0.25,0.85,0.5,0.13))
	for entry in [["entrance","tutorial.plot.entrance"],["throne","tutorial.plot.throne"]]:
		root._draw_management_screen_label(canvas,root.graph.center(entry[0]),LanguageSettings.text(entry[1]),Color("#9de8bd"),18,true)

static func decorate_overlay(root: Node, overlay: Control, step: Dictionary, message_rect: Rect2) -> void:
	if not Service.is_plot(root.graph) or root.current_screen != "management": return
	for id in step.get("map_targets",[]):
		if id in ["AUTO_ROAD_PREVIEW","BUILD_GHOST"]: continue
		var rect: Rect2 = root._tutorial_focus_rect(id)
		if not rect.has_area() or rect.intersects(message_rect): continue
		var ring := Panel.new()
		ring.name = "TutorialMapTarget_"+str(id)
		ring.position = rect.position
		ring.size = rect.size
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_theme_stylebox_override("panel",root.hud.style(Color("#69da9010"),Color("#69da9080"),2))
		overlay.add_child(ring)

static func highlight_rects(root: Node, focus_id: String, fallback: Rect2) -> Array[Rect2]:
	if not Service.is_plot(root.graph) or focus_id!="DAY1_GOBLIN_FORMATION": return [fallback]
	var result: Array[Rect2] = []
	for id in formation_rooms(root):
		# Glow grows by 14px; keep it inside the floor, below the nameplate.
		result.append(root._tutorial_room_rect(id).grow(-30.0))
	return result
