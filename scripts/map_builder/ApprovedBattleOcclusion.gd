extends RefCounted
## One static alpha/depth pass of the same elevated map pieces as the live map.
var viewport: SubViewport
var bounds := Rect2()
const DEPTH_RANGE := Vector2(0,3500)

func build(view: Control, parent: Node) -> void:
	var pieces: Array[Sprite2D] = []
	for child in view.world.get_children():
		if child.has_meta("map_depth"): child.z_index = int(child.get_meta("map_depth"))
		if child is Sprite2D and child.has_meta("map_depth") and not str(child.get_meta("map_asset")).begins_with("traps/"):
			pieces.append(child)
			var rect: Rect2 = child.transform*child.get_rect()
			bounds = rect if pieces.size()==1 else bounds.merge(rect)
	viewport = SubViewport.new(); viewport.name = "ApprovedBuildingDepth"
	viewport.world_2d = World2D.new(); viewport.disable_3d = true; viewport.transparent_bg = true
	viewport.handle_input_locally = false; viewport.gui_disable_input = true
	viewport.size = Vector2i(bounds.size.ceil())
	parent.add_child(viewport)
	pieces.sort_custom(func(a,b): return a.z_index<b.z_index)
	for source in pieces:
		var clone := Sprite2D.new(); clone.texture = source.texture; clone.centered = source.centered
		clone.transform = source.transform; clone.position -= bounds.position
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/camera/plot_wall_depth.gdshader")
		var encoded := roundi(float(source.z_index)/DEPTH_RANGE.y*65535)
		material.set_shader_parameter("packed_depth",Vector2(encoded/256,encoded%256)/255.0)
		clone.material = material; viewport.add_child(clone)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func bind(unit: Node) -> void:
	var material: ShaderMaterial = unit.silhouette.material
	material.set_shader_parameter("wall_depth",viewport.get_texture())
	material.set_shader_parameter("wall_origin",bounds.position)
	material.set_shader_parameter("wall_size",bounds.size)
	material.set_shader_parameter("chroma_key",unit.requires_sprite_chroma)
	material.set_shader_parameter("silhouette_color",Color(.4,.78,1,.4) if unit.faction=="monster" else Color(1,.3,.3,.4))
