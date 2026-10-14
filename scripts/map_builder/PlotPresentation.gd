extends RefCounted

const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const STONE = preload("res://assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png")
const BRAZIER = preload("res://assets/props/decor/prop_small_brazier_back.png")
const ROAD_COLOR := Color("#b6ad96")
const GROUND_COLOR := Color("#49434e")

static func bounds(graph) -> Rect2:
	if graph.has_meta("plot_visual_bounds"): return graph.get_meta("plot_visual_bounds")
	var result := Rect2()
	for cell in graph.layout.get("plot_mask",{}):
		var tile: Rect2 = graph.tile_cell_rect(cell)
		result = tile if not result.has_area() else result.merge(tile)
	graph.set_meta("plot_visual_bounds",result)
	return result

static func view_bounds(graph) -> Rect2:
	var rect := bounds(graph)
	return Rect2(rect.position-Vector2(12,78),rect.size+Vector2(24,104))

static func draw_ground(renderer) -> void:
	var target: CanvasItem = renderer.root
	var rect := bounds(renderer.root.graph)
	# One opaque foundation joins every room. This is scenery, never walk data.
	target.draw_rect(Rect2(rect.position+Vector2(0,18),rect.size),Color("#15101e"))
	target.draw_rect(rect,GROUND_COLOR)
	target.draw_texture_rect(STONE,rect,true,Color(0.65,0.60,0.70,0.42))
	var step: Vector2 = renderer.root.graph.tile_size*renderer.root.graph.tile_visual_scale
	for y in range(int(rect.size.y/step.y)+1):
		var py := rect.position.y+y*step.y
		target.draw_line(Vector2(rect.position.x,py),Vector2(rect.end.x,py),Color("#25232a88"),1.0)
		for x in range(int(rect.size.x/step.x)):
			var px := rect.position.x+(x+0.5*(y%2))*step.x
			target.draw_line(Vector2(px,py),Vector2(px,minf(rect.end.y,py+step.y)),Color("#25232a88"),1.0)
	# Low parapets keep the near edge legible without covering actors.
	for edge in [[rect.position,Vector2(rect.position.x,rect.end.y)],[Vector2(rect.position.x,rect.end.y),rect.end],[rect.end,Vector2(rect.end.x,rect.position.y)]]:
		target.draw_line(edge[0]+Vector2(0,8),edge[1]+Vector2(0,8),Color("#211d2b"),16.0)
		target.draw_line(edge[0],edge[1],Color("#918477"),5.0)
	var index := int(renderer.root.graph.layout.plot_grid.grade_index)
	if index < 3:
		var locked := Rect2(Vector2(rect.end.x+14,rect.position.y),Vector2(96,rect.size.y))
		target.draw_rect(locked,Color("#0c0914cc"))
		for y in range(0,int(locked.size.y),32):
			target.draw_line(locked.position+Vector2(0,y),locked.position+Vector2(96,minf(y+32,locked.size.y)),Color("#80708d44"),2)
		var p := locked.get_center()
		target.draw_arc(p-Vector2(0,9),12,PI,TAU,12,Color("#b4a6bd"),3)
		target.draw_style_box(_lock_box(),Rect2(p-Vector2(15,9),Vector2(30,23)))

static func _lock_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#b4a6bd")
	box.set_corner_radius_all(3)
	return box

static func draw_roads(renderer) -> void:
	var graph = renderer.root.graph
	for cell in graph.layout.auto_roads.road_cells:
		var rect: Rect2 = graph.tile_cell_rect(cell)
		var diamond: PackedVector2Array = renderer._diamond(rect)
		renderer.root.draw_colored_polygon(diamond,ROAD_COLOR)
		renderer.root.draw_polygon(diamond,PackedColorArray([Color(1,0.96,0.88,0.28)]),PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)]),STONE)
		renderer.root.draw_polyline(PackedVector2Array([diamond[0],diamond[1],diamond[2],diamond[3],diamond[0]]),Color("#776e60"),1.2)

static func road_patches(graph) -> Array:
	var roads: Dictionary = graph.layout.get("auto_roads", {}).get("road_cells", {})
	var openings: Array = []
	for cell: Vector2i in roads:
		for side in Mask.DIRS:
			var neighbor: Vector2i = cell + Mask.DIRS[side]
			if graph.tile_floor_cells.has(neighbor) and not roads.has(neighbor) and graph.open_edge_set.has(Mask.edge_key(cell,side)):
				openings.append({"cell":cell,"side":side})
	return [{"id":"automatic_roads", "preserve_existing":true, "cells":roads.keys(), "cell_data":{"room_id":"auto_road_network", "is_corridor":true,"wall_profile":"cutaway"}, "external_openings":openings}]

static func draw_cutaway(renderer, tile_grid: Dictionary) -> void:
	# Reuse existing structural bitmap; collapse only its vertical axis for the
	# knee-high camera-facing rim. All scenery is drawn before the actor pass.
	for edge in tile_grid["wall_edges"]:
		var profile := str(edge.get("wall_profile", "none"))
		if profile == "none" or edge.get("state", "closed") == "connected": continue
		var id := str(edge.get("structural_asset_id", ""))
		var texture: Texture2D = renderer.structural_wall_textures.get(id)
		if texture == null: continue
		var rect: Rect2 = renderer._structural_edge_draw_rect(texture,renderer.structural_wall_asset_entries.get(id,{}),edge)
		if profile == "low_rim":
			rect.position.y = rect.end.y - rect.size.y * 0.22
			rect.size.y *= 0.22
		renderer.root.draw_texture_rect(texture, rect, false)
	# The rear wall ends at the same foundation corners used by camera fitting.
	var rect := bounds(renderer.root.graph)
	var target: CanvasItem = renderer.root
	var wall := Rect2(rect.position-Vector2(0,56),Vector2(rect.size.x,56))
	target.draw_rect(wall,Color("#302936"))
	target.draw_texture_rect(STONE,wall,true,Color(0.7,0.58,0.77,0.42))
	var count := maxi(1,int(ceil(rect.size.x/76.0)))
	var width := rect.size.x/count
	for row in range(3):
		var py := wall.position.y+row*18
		target.draw_line(Vector2(wall.position.x,py),Vector2(wall.end.x,py),Color("#15121d"),2)
		for i in range(count):
			var px := wall.position.x+(i+0.5*(row%2))*width
			target.draw_line(Vector2(px,py),Vector2(px,py+18),Color("#1e1925"),2)
	for i in range(count):
		var px := wall.position.x+i*width
		var cap := Rect2(Vector2(px,wall.position.y-[0,3,1,5][i%4]),Vector2(width,8))
		target.draw_rect(cap,Color("#645668").lightened(0.02*(i%3)))
		if i%5==0 or i==count-1:
			var pillar := Rect2(Vector2(px,wall.position.y-12),Vector2(18,68))
			target.draw_rect(pillar,Color("#4d4055"))
			target.draw_line(pillar.position,pillar.position+Vector2(0,68),Color("#80717c"),3)
			target.draw_rect(Rect2(pillar.position-Vector2(4,0),Vector2(26,8)),Color("#8e7c87"))
		if i%6==2:
			target.draw_texture_rect(BRAZIER,Rect2(Vector2(px+width*0.5,wall.position.y+10)-Vector2(18,0),Vector2(36,48)),false)

static func sync_terrain(layer: Control, plate: TextureRect, size: Vector2) -> void:
	var terrain := layer.get_node_or_null("PlotTerrain") as TextureRect
	if terrain == null:
		terrain = TextureRect.new()
		terrain.name = "PlotTerrain"
		terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terrain.texture = load("res://assets/dungeon_quarter/prepared_maze/packed_earth.png")
		terrain.stretch_mode = TextureRect.STRETCH_TILE
		terrain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.add_child(terrain)
		layer.move_child(terrain,plate.get_index())
	terrain.position = Vector2.ZERO
	terrain.size = size
	terrain.modulate = Color(0.48,0.38,0.53,1.0)
	terrain.visible = true
	# The existing cave plate has opaque black vignette pixels; blending it
	# over actual earth tiles keeps rock/earth visible right to all four edges.
	plate.modulate = Color(1,1,1,0.75)
