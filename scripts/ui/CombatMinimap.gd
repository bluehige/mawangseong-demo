extends Control
# Cached physical room/road cells; camera and living units are drawn over them.
var root: Node
var bounds := Rect2()
var cells: Array = []
var suppress_mouse_until := 0

func setup(game: Node) -> void:
	root = game
	name = "CombatMinimap"
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = root.continuity.localized("미니맵 · 클릭/터치로 카메라 이동","Minimap · Click/tap to move camera","小地图 · 点击移动镜头")
	bounds = root.spectator_camera.world_bounds.grow(30)
	var cell_data: Dictionary = root.graph.debug_cell_data()
	for cell in cell_data:
		var data: Dictionary = cell_data[cell]
		if not bool(data.get("active",false)) or str(data.get("room_id",""))=="": continue
		cells.append({"point":root.graph.tile_cell_center(cell),"room":not bool(data.get("is_corridor",false))})

func map_rect() -> Rect2:
	var scale_factor := minf((size.x-16)/bounds.size.x,(size.y-16)/bounds.size.y)
	var extent := bounds.size*scale_factor
	return Rect2((size-extent)/2,extent)

func project(point: Vector2) -> Vector2:
	var rect := map_rect()
	return rect.position+(point-bounds.position)/bounds.size*rect.size

func unproject(point: Vector2) -> Vector2:
	var rect := map_rect()
	return bounds.position+(point-rect.position)/rect.size*bounds.size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		suppress_mouse_until = Time.get_ticks_msec()+400
		if event.pressed: root.spectator_camera.focus(unproject(event.position))
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Time.get_ticks_msec() >= suppress_mouse_until: root.spectator_camera.focus(unproject(event.position))
		accept_event()

func _draw() -> void:
	if root == null: return
	draw_rect(Rect2(Vector2.ZERO,size),Color("#100d18f2"))
	draw_style_box(root.hud.combat_workspace.kit_theme().get_stylebox("panel","Panel"),Rect2(Vector2.ZERO,size))
	var half: Vector2=root.graph.tile_size*root.graph.tile_visual_scale*0.5*map_rect().size/bounds.size
	for cell in cells:
		var center := project(cell.point)
		var polygon := PackedVector2Array([center-Vector2(half.x,0),center-Vector2(0,half.y),center+Vector2(half.x,0),center+Vector2(0,half.y)])
		draw_colored_polygon(polygon,Color("#8c7e95") if cell.room else Color("#c1aa70"))
	for unit in root.monster_units+root.enemy_units:
		if is_instance_valid(unit) and unit.is_alive(): draw_circle(project(unit.global_position),3.0,Color("#ff7971") if unit.faction=="enemy" else Color("#78e1cf"))
	var extent: Vector2 = root.get_viewport_rect().size/root.combat_view_zoom
	var a := project(root.combat_camera.position-extent/2)
	var b := project(root.combat_camera.position+extent/2)
	draw_rect(Rect2(a,b-a).intersection(map_rect()),Color("#f2d487"),false,1.5)
