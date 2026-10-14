extends RefCounted

const REAR_ROCK = preload("res://assets/tiles/cave_f/wall/wall_cave_f_nw_straight_00.png")
const Mask = preload("res://scripts/dungeon_quarter/AutoTileMask.gd")

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
	# Rear plot escarpment, using the existing cave wall bitmap. Only the top
	# projected edge owns tall pieces; roads have no walls on any side.
	var plot: Dictionary = renderer.root.graph.layout["plot_mask"]
	var min_sum := 2147483647
	for cell: Vector2i in plot:
		min_sum = mini(min_sum,cell.x+cell.y)
	var rock: Texture2D = REAR_ROCK
	if rock == null: return
	for cell: Vector2i in plot:
		if cell.x+cell.y != min_sum: continue
		var rect: Rect2 = renderer.root.graph.tile_cell_rect(cell)
		rect.position.x -= rect.size.x * 0.5
		rect.position.y -= rect.size.y * 2.5
		rect.size *= Vector2(2.0,3.5)
		renderer.root.draw_texture_rect(rock,rect,false)

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
