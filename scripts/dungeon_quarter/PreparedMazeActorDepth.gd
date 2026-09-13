extends RefCounted
# One cached technical depth buffer for the existing masonry, independent of camera/UI scale.
const ACTOR_SHADER = preload("res://scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader")
const DEPTH_SHADER = preload("res://scripts/dungeon_quarter/prepared_maze_depth_write.gdshader")
const WALL_SHADER = preload("res://scripts/dungeon_quarter/prepared_maze_wall_reveal.gdshader")
var color_viewport: SubViewport
var color_canvas: Node2D
var base_viewports: Array[SubViewport] = []
var wall_materials: Array[ShaderMaterial] = []
var overlay: Node2D
var bodies: Dictionary = {}
var masonry_ref
var map_root: Node2D
var freeze_regions := false
var previous_regions := ""
var viewport: SubViewport
var canvas: Node2D
var bounds := Rect2()
var depth_range := Vector2.ZERO
var generation := 0
var polygons: Array = []

func rebuild(parent: Node, masonry) -> void:
	masonry_ref = masonry
	map_root = parent
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
			depths.append(Vector2(inverse_lerp(depth_range.x, depth_range.y, masonry._depth_at(face, point)), (0.25 if bool(face.front) else 0.0) + (0.5 if bool(face.top) else 0.0)))
		polygons.append({"points": points, "depths": depths})
	canvas.queue_redraw()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	generation += 1
	_rebuild_wall_color(parent)

func _draw_depth() -> void:
	for polygon: Dictionary in polygons:
		canvas.draw_polygon(polygon.points, PackedColorArray([Color.WHITE]), polygon.depths)

func bind(item: CanvasItem, foot: Vector2, map_root: Node2D, chroma: bool = false, reveal_body: bool = false) -> void:
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
	mat.set_shader_parameter("reveal_occluded_body", reveal_body)
	if reveal_body: bodies[item.get_instance_id()] = weakref(item)

func _make_viewport(parent: Node, title: String) -> SubViewport:
	var result := SubViewport.new()
	result.name = title
	result.world_2d = World2D.new()
	result.disable_3d = true
	result.transparent_bg = true
	result.gui_disable_input = true
	result.handle_input_locally = false
	parent.add_child(result)
	return result

func _rebuild_wall_color(parent: Node) -> void:
	if not is_instance_valid(color_viewport):
		color_viewport = _make_viewport(parent, "PreparedMazeWallColor")
		color_canvas = Node2D.new()
		color_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		color_viewport.add_child(color_canvas)
		color_canvas.draw.connect(func():
			masonry_ref.draw(color_canvas, false)
			masonry_ref.draw(color_canvas, true)
		)
		for pass_id in range(3):
			var material := ShaderMaterial.new()
			material.shader = WALL_SHADER
			material.set_shader_parameter("wall_pass", pass_id)
			material.set_shader_parameter("face_opacity", 0.42)
			material.set_shader_parameter("cap_opacity", 0.72)
			wall_materials.append(material)
			if pass_id < 2:
				var base := _make_viewport(parent, "PreparedMazeWallBase"+str(pass_id))
				var sprite := Sprite2D.new()
				sprite.centered = false
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				sprite.material = material
				base.add_child(sprite)
				base_viewports.append(base)
		overlay = Node2D.new()
		overlay.name = "PreparedMazeForegroundWalls"
		overlay.z_index = 108
		overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		overlay.material = wall_materials[2]
		parent.add_child(overlay)
		overlay.draw.connect(func(): overlay.draw_texture_rect(color_viewport.get_texture(), bounds, false))
	color_viewport.size = viewport.size
	var scale := Vector2(viewport.size) / bounds.size
	color_canvas.transform = Transform2D(Vector2(scale.x,0),Vector2(0,scale.y),-bounds.position*scale)
	color_canvas.queue_redraw()
	color_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for material in wall_materials:
		material.set_shader_parameter("wall_depth", viewport.get_texture())
		material.set_shader_parameter("wall_origin", bounds.position)
		material.set_shader_parameter("wall_size", bounds.size)
		material.set_shader_parameter("depth_range", depth_range)
	for base in base_viewports:
		base.size = viewport.size
		base.get_child(0).texture = color_viewport.get_texture()
		base.render_target_update_mode = SubViewport.UPDATE_ONCE
	overlay.queue_redraw()
	previous_regions = ""

func draw_base(target: CanvasItem, front: bool) -> void:
	target.draw_texture_rect(base_viewports[1 if front else 0].get_texture(), bounds, false)

func update_reveal_regions() -> void:
	if not is_instance_valid(overlay) or freeze_regions: return
	overlay.visible = map_root.use_quarter_module_map and map_root.quarter_renderer._prepared_maze() and map_root.quarter_renderer.stage01_world_layers_visible
	if not overlay.visible: return
	var rectangles := PackedVector4Array()
	var feet := PackedFloat32Array()
	for id in bodies.keys():
		var body = bodies[id].get_ref()
		if not is_instance_valid(body):
			bodies.erase(id)
			continue
		if not body.is_visible_in_tree(): continue
		if rectangles.size() >= 128:
			body.material.set_shader_parameter("reveal_occluded_body",false)
			continue
		var rect := Rect2()
		if body is Sprite2D:
			rect = body.get_rect()
		elif body is AnimatedSprite2D:
			var texture: Texture2D = body.sprite_frames.get_frame_texture(body.animation, body.frame)
			if texture == null: continue
			var size := texture.get_size()
			rect = Rect2(body.offset - (size*0.5 if body.centered else Vector2.ZERO), size)
		else: continue
		rect = (map_root.global_transform.affine_inverse()*body.global_transform)*rect
		rect = rect.grow(8.0)
		var center := rect.get_center()
		rectangles.append(Vector4(center.x,center.y,rect.size.x*0.5,rect.size.y*0.5))
		feet.append(float(body.material.get_shader_parameter("foot_depth")))
		body.material.set_shader_parameter("reveal_occluded_body",true)
	var signature := str(rectangles)+str(feet)+str(overlay.visible)
	if signature == previous_regions: return
	previous_regions = signature
	for material in wall_materials:
		material.set_shader_parameter("body_count",rectangles.size())
		material.set_shader_parameter("body_rects",rectangles)
		material.set_shader_parameter("body_feet",feet)
	for base in base_viewports: base.render_target_update_mode = SubViewport.UPDATE_ONCE
