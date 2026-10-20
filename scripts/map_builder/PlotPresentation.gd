extends RefCounted

const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")
const STONE = preload("res://assets/dungeon_quarter/prepared_maze/torchlit_flagstone.png")
const BRAZIER = preload("res://assets/props/decor/prop_small_brazier_back.png")
const ROAD_COLOR := Color("#b6ad96")
const GROUND_COLOR := Color("#302c38")
static var stone_texture: CanvasTexture

# Scenery encloses the existing screen-aligned build mask in cell axes.
# Never reshape that mask or change the graph's walkable cells.
static func surface_cells(graph) -> Rect2:
	if graph.has_meta("plot_visual_cells"): return graph.get_meta("plot_visual_cells")
	var result := Rect2()
	var first := true
	for cell: Vector2i in graph.layout.get("plot_mask",{}):
		var tile := Rect2(Vector2(cell)-Vector2(0.5,0.5),Vector2.ONE)
		result = tile if first else result.merge(tile)
		first = false
	graph.set_meta("plot_visual_cells",result)
	return result

static func surface_polygon(graph, cells: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var step: Vector2 = graph.tile_size*graph.tile_visual_scale*0.5
	for cell: Vector2 in [cells.position,Vector2(cells.end.x,cells.position.y),cells.end,Vector2(cells.position.x,cells.end.y)]:
		points.append(graph.tile_world_origin+Vector2((cell.x-cell.y)*step.x,(cell.x+cell.y)*step.y))
	return points

static func locked_cells(graph) -> Rect2:
	if int(graph.layout.plot_grid.grade_index)>=3: return Rect2()
	var cells := surface_cells(graph)
	return Rect2(Vector2(cells.end.x,cells.position.y),Vector2(6,cells.size.y))

static func bounds(graph) -> Rect2:
	if graph.has_meta("plot_visual_bounds"): return graph.get_meta("plot_visual_bounds")
	var result := Rect2()
	for point in surface_polygon(graph,surface_cells(graph)):
		result = Rect2(point,Vector2.ZERO) if result==Rect2() else result.expand(point)
	graph.set_meta("plot_visual_bounds",result)
	return result

static func view_bounds(graph) -> Rect2:
	var rect := bounds(graph)
	if locked_cells(graph).has_area():
		for point in surface_polygon(graph,locked_cells(graph)): rect = rect.expand(point)
	return Rect2(rect.position-Vector2(12,78),rect.size+Vector2(24,104))

static func draw_ground(renderer) -> void:
	var target: CanvasItem = renderer.root
	var graph = renderer.root.graph
	var cells := surface_cells(graph)
	var polygon := surface_polygon(graph,cells)
	_draw_surface(target,graph,cells,GROUND_COLOR)
	var locked := locked_cells(graph)
	var outer := polygon
	if locked.has_area():
		_draw_surface(target,graph,locked,Color("#0c0912"))
		# Clip each hatch to the reserved cell rectangle; keep the lock anchor.
		for offset in range(0,int(locked.size.y)+1,2):
			var strip := Rect2(locked.position+Vector2(0,offset),Vector2(locked.size.x,0))
			var points := surface_polygon(graph,strip)
			target.draw_line(points[0],points[1],Color(0.48,0.40,0.55,0.42),2.5)
		var outline := surface_polygon(graph,locked)
		outline.append(outline[0])
		target.draw_polyline(outline,Color("#9a83a5"),4.0)
		var p: Vector2 = (outline[0]+outline[2])*0.5
		target.draw_arc(p-Vector2(0,9),12,PI,TAU,12,Color("#b4a6bd"),3)
		target.draw_style_box(_lock_box(),Rect2(p-Vector2(15,9),Vector2(30,23)))
		outer = surface_polygon(graph,Rect2(cells.position,Vector2(cells.size.x+locked.size.x,cells.size.y)))
	# The open and reserved land share a continuous camera-facing foundation.
	for edge in [[outer[1],outer[2]],[outer[2],outer[3]]]:
		target.draw_colored_polygon(PackedVector2Array([edge[0],edge[1],edge[1]+Vector2(0,18),edge[0]+Vector2(0,18)]),Color("#211d2b"))
		target.draw_line(edge[0],edge[1],Color("#918477"),5.0)
	# Draw behind rooms, so rear scenery cannot cover room art or actors.
	_draw_rear_wall(target,polygon[3],polygon[0])
	_draw_rear_wall(target,polygon[0],polygon[1])

static func _draw_surface(target: CanvasItem, graph, cells: Rect2, tint: Color) -> void:
	var polygon := surface_polygon(graph,cells)
	target.draw_colored_polygon(polygon,tint)
	if stone_texture==null:
		stone_texture = CanvasTexture.new()
		stone_texture.diffuse_texture = STONE
		stone_texture.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Bitmap and joints use cell coordinates, never screen-space brick rows.
	var uv := PackedVector2Array([cells.position/8,Vector2(cells.end.x,cells.position.y)/8,cells.end/8,Vector2(cells.position.x,cells.end.y)/8])
	target.draw_polygon(polygon,PackedColorArray([tint.lightened(0.18)]),uv,stone_texture)

static func _draw_rear_wall(target: CanvasItem, a: Vector2, b: Vector2) -> void:
	var height := Vector2(0,42)
	target.draw_colored_polygon(PackedVector2Array([a,b,b-height,a-height]),Color("#302936"))
	var cap_depth := Vector2(0,6)
	target.draw_colored_polygon(PackedVector2Array([a-height,b-height,b-height-cap_depth,a-height-cap_depth]),Color("#645668"))
	for row in range(3):
		target.draw_line(a-height+Vector2(0,row*14),b-height+Vector2(0,row*14),Color("#15121d"),2)
	var count := maxi(1,int(ceil(a.distance_to(b)/76.0)))
	for i in range(count):
		var p := a.lerp(b,float(i)/count)
		var q := a.lerp(b,float(i+1)/count)
		target.draw_line(p-height,q-height,Color("#80717c"),7)
		for row in range(3):
			var joint := a.lerp(b,(i+0.5*(row%2))/count)-height+Vector2(0,row*14)
			target.draw_line(joint,joint+Vector2(0,14),Color("#1e1925"),2)
		if i%5==0 or i==count-1:
			var pillar := Rect2(p-Vector2(9,54),Vector2(18,54))
			target.draw_rect(pillar,Color("#4d4055"))
			target.draw_line(pillar.position,pillar.position+Vector2(0,54),Color("#80717c"),3)
			target.draw_rect(Rect2(pillar.position-Vector2(4,0),Vector2(26,8)),Color("#8e7c87"))
		if i%6==2:
			target.draw_texture_rect(BRAZIER,Rect2((p+q)*0.5-Vector2(18,48),Vector2(36,48)),false)

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
