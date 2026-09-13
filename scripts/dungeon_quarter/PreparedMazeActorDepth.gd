extends RefCounted
# One cached technical depth buffer for the existing masonry, independent of camera/UI scale.
const ACTOR_SHADER = preload("res://scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader")
const DEPTH_SHADER = preload("res://scripts/dungeon_quarter/prepared_maze_depth_write.gdshader")
var viewport: SubViewport
var canvas: Node2D
var bounds := Rect2()
var depth_range := Vector2.ZERO
var generation := 0
var polygons: Array = []

func rebuild(parent: Node, masonry) -> void:
	polygons.clear()
	var faces: Array = masonry.visible_back_faces + masonry.visible_front_faces
	if faces.is_empty(): return
	bounds = Rect2(faces[0].points[0], Vector2.ZERO)
	depth_range = Vector2(INF, -INF)
	for face: Dictionary in faces:
		for point: Vector2 in face.points:
			bounds = bounds.expand(point)
			var depth: float = masonry._depth_at(face, point)
			depth_range.x = minf(depth_range.x, depth)
			depth_range.y = maxf(depth_range.y, depth)
	bounds = bounds.grow(2.0)
	depth_range += Vector2(-2.0, 2.0)
	if not is_instance_valid(viewport):
		viewport = SubViewport.new()
		viewport.name = "PreparedMazeWallDepth"
		viewport.world_2d = World2D.new()
		viewport.disable_3d = true
		viewport.transparent_bg = true
		viewport.handle_input_locally = false
		viewport.gui_disable_input = true
		parent.add_child(viewport)
		canvas = Node2D.new()
		canvas.material = ShaderMaterial.new()
		canvas.material.shader = DEPTH_SHADER
		viewport.add_child(canvas)
		canvas.draw.connect(_draw_depth)
	# Two samples per world pixel, capped for late castles. No frame-by-frame readback.
	var density := minf(2.0, 4096.0 / maxf(bounds.size.x, bounds.size.y))
	viewport.size = Vector2i((bounds.size * density).ceil())
	canvas.transform = Transform2D(Vector2(viewport.size.x / bounds.size.x, 0), Vector2(0, viewport.size.y / bounds.size.y), Vector2.ZERO)
	for face: Dictionary in faces:
		var points := PackedVector2Array()
		var depths := PackedVector2Array()
		for point: Vector2 in face.points:
			points.append(point - bounds.position)
			depths.append(Vector2(inverse_lerp(depth_range.x, depth_range.y, masonry._depth_at(face, point)), 0))
		polygons.append({"points": points, "depths": depths})
	canvas.queue_redraw()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	generation += 1

func _draw_depth() -> void:
	for polygon: Dictionary in polygons:
		canvas.draw_polygon(polygon.points, PackedColorArray([Color.WHITE]), polygon.depths)

func bind(item: CanvasItem, foot: Vector2, map_root: Node2D, chroma: bool = false) -> void:
	if not is_instance_valid(viewport): return
	var mat := item.material as ShaderMaterial
	if mat == null or mat.shader != ACTOR_SHADER:
		mat = ShaderMaterial.new()
		mat.shader = ACTOR_SHADER
		item.material = mat
	if int(mat.get_meta("depth_generation", -1)) != generation:
		mat.set_shader_parameter("wall_depth", viewport.get_texture())
		mat.set_shader_parameter("wall_origin", bounds.position)
		mat.set_shader_parameter("wall_size", bounds.size)
		mat.set_shader_parameter("depth_range", depth_range)
		mat.set_meta("depth_generation", generation)
	var inverse := map_root.global_transform.affine_inverse()
	mat.set_shader_parameter("map_x", Vector3(inverse.x.x, inverse.y.x, inverse.origin.x))
	mat.set_shader_parameter("map_y", Vector3(inverse.x.y, inverse.y.y, inverse.origin.y))
	mat.set_shader_parameter("foot_depth", foot.y)
	mat.set_shader_parameter("chroma_key", chroma)
