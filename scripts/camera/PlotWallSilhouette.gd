extends RefCounted
# Cache the alpha shape and world foot depth of the actual cutaway wall art.
const ActorShader = preload("res://scripts/dungeon_quarter/prepared_maze_actor_depth.gdshader")
const DepthShader = preload("res://scripts/camera/plot_wall_depth.gdshader")
var viewport: SubViewport
var bounds := Rect2()
var depth_range := Vector2.ZERO
var graph_ref: WeakRef
var generation := 0
var wall_count := 0

func invalidate() -> void: graph_ref = null

func rebuild(renderer) -> void:
	var root: Node2D = renderer.root
	if graph_ref!=null and graph_ref.get_ref()==root.graph: return
	graph_ref=weakref(root.graph)
	if is_instance_valid(viewport): viewport.queue_free()
	viewport=SubViewport.new(); viewport.name="PlotWallSilhouetteDepth"
	viewport.world_2d=World2D.new(); viewport.disable_3d=true; viewport.transparent_bg=true
	viewport.handle_input_locally=false; viewport.gui_disable_input=true
	root.add_child(viewport)
	var walls: Array = []
	wall_count=0
	for edge in renderer._tile_grid_for_draw().get("wall_edges",[]):
		var profile: String=str(edge.get("wall_profile","none"))
		if profile=="none" or edge.get("state","closed")=="connected": continue
		var id: String=str(edge.get("structural_asset_id",""))
		var texture: Texture2D=renderer.structural_wall_textures.get(id)
		if texture==null: continue
		var rect: Rect2=renderer._structural_edge_draw_rect(texture,renderer.structural_wall_asset_entries.get(id,{}),edge)
		if profile=="low_rim": rect.position.y=rect.end.y-rect.size.y*0.22; rect.size.y*=0.22
		bounds=rect if walls.is_empty() else bounds.merge(rect)
		walls.append({"texture":texture,"rect":rect,"depth":rect.end.y})
	if walls.is_empty(): return
	depth_range=Vector2(bounds.position.y-1,bounds.end.y+1)
	var density := minf(1.5,2048.0/maxf(bounds.size.x,bounds.size.y))
	viewport.size=Vector2i((bounds.size*density).ceil())
	var canvas:=Node2D.new(); canvas.scale=Vector2(viewport.size)/bounds.size; viewport.add_child(canvas)
	walls.sort_custom(func(a,b): return a.depth<b.depth)
	for wall in walls:
		var sprite:=Sprite2D.new(); sprite.texture=wall.texture; sprite.centered=false
		sprite.position=wall.rect.position-bounds.position; sprite.scale=wall.rect.size/wall.texture.get_size()
		var material:=ShaderMaterial.new(); material.shader=DepthShader
		var encoded: int=roundi(inverse_lerp(depth_range.x,depth_range.y,wall.depth)*65535)
		material.set_shader_parameter("packed_depth",Vector2(encoded/256,encoded%256)/255.0)
		sprite.material=material; canvas.add_child(sprite)
	wall_count=walls.size(); generation+=1
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func bind(renderer,unit) -> void:
	rebuild(renderer)
	if wall_count==0: return
	var material := unit.sprite.material as ShaderMaterial
	if material==null or material.shader!=ActorShader:
		material=ShaderMaterial.new(); material.shader=ActorShader; unit.sprite.material=material
	if int(material.get_meta("plot_generation",-1))!=generation:
		material.set_shader_parameter("wall_depth",viewport.get_texture())
		material.set_shader_parameter("wall_origin",bounds.position)
		material.set_shader_parameter("wall_size",bounds.size)
		material.set_shader_parameter("depth_range",depth_range)
		material.set_meta("plot_generation",generation)
	var inverse: Transform2D=renderer.root.global_transform.affine_inverse()
	material.set_shader_parameter("map_x",Vector3(inverse.x.x,inverse.y.x,inverse.origin.x))
	material.set_shader_parameter("map_y",Vector3(inverse.x.y,inverse.y.y,inverse.origin.y))
	material.set_shader_parameter("foot_depth",renderer.root.to_local(unit.global_position).y)
	material.set_shader_parameter("chroma_key",unit.requires_sprite_chroma)
	material.set_shader_parameter("reveal_occluded_body",true)
	material.set_shader_parameter("spectator_silhouette",true)
	material.set_shader_parameter("silhouette_color",Color("#ff7971db") if unit.faction=="enemy" else Color("#78e1cfdb"))
