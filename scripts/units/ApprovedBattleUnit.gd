extends "res://scripts/units/Unit.gd"
## Existing Unit movement/status/combat math; raster-only branch presentation.
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
var battle_map: RefCounted
var battle_runtime: RefCounted
var selection_art: Sprite2D
const HPBar = preload("res://scripts/ui/PortraitHealthBar.gd")
var health: TextureProgressBar
var map_visual: Node2D
var vitals: Node2D
var idle_bounds := Rect2()
var idle_frame: Texture2D
var body_factor := 1.0
var legacy_factor := 1.0
var silhouette: Sprite2D
var vitals_link: Line2D
var head_raster_key: Array = []
var head_raster_y := 0.0
var quarter_art := false
var facing := Vector2(-1,1)
var hidden_until := 0.0
var quiet_seconds := 0.0
var stealth_broken_at := 0.0
var new_skill_clock := 0.0
var reassemble_pending := -1.0
var reassemble_used := false
var root_timer := 0.0
var first_paper_hit := true
var incoming_source: Node
var incoming_area := false
var incoming_fire := false

func setup(source_id: String, stats: Dictionary, unit_faction: String, room_id: String) -> void:
	super.setup(source_id,stats,unit_faction,room_id)
	# Keep each boss's identifying name visible inside the compact overhead label.
	if source_id=="official_hero_leon": name_label.text = "레온"
	elif source_id=="selen_trainee_paladin": name_label.text = "셀렌"
	health.setup(self)

func attach_map_visuals(parent: Node2D) -> void:
	# Simulation coordinates stay independent of management zoom/pan. Only the
	# existing live sprite/labels are parented to the map's presentation transform.
	map_visual = Node2D.new(); parent.add_child(map_visual)
	for child in [visual_body,selection_art]: child.reparent(map_visual,false)
	vitals = Node2D.new(); parent.add_child(vitals); vitals.z_index = 3800
	health.reparent(vitals,false)
	vitals.scale = Vector2.ONE*Presentation.ui_scale(unit_id)
	vitals_link = Line2D.new(); parent.add_child(vitals_link); vitals_link.z_index = 3799
	vitals_link.default_color = Color(.3,1,.8,.55) if faction=="monster" else Color(1,.47,.44,.55)
	silhouette = Sprite2D.new(); parent.add_child(silhouette); silhouette.z_index = 3700
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/units/approved_battle_silhouette.gdshader")
	silhouette.material = material
	battle_runtime.occlusion.bind(self)
	map_visual.position = position
	refresh_depth_slot()

func _exit_tree() -> void:
	if is_instance_valid(map_visual): map_visual.queue_free()
	if is_instance_valid(vitals): vitals.queue_free()
	if is_instance_valid(silhouette): silhouette.queue_free()
	if is_instance_valid(vitals_link): vitals_link.queue_free()

func _ready() -> void:
	super._ready()
	ground_visual.hide()
	name_label.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Light.otf"))
	name_label.add_theme_font_size_override("font_size",18)
	name_label.size = Vector2(116,24)
	name_label.clip_text = true; name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	selection_art = Sprite2D.new()
	selection_art.texture = preload("res://assets/maps/v130r_step2/ui/cell_highlight.png")
	selection_art.modulate = Color(.3,1,.8,.8); selection_art.show_behind_parent = true
	add_child(selection_art); selection_art.hide()
	health = HPBar.new(); add_child(health)

func _configure_combat_sprite(source_sprite_path: String) -> void:
	quarter_art = faction=="monster" and source_sprite_path.contains("/quarter_final/")
	if quarter_art:
		sprite_path = source_sprite_path
		combat_visual_profile = {}
		sprite.material = null
		var frames := warm_animation_frames(source_sprite_path).duplicate() as SpriteFrames
		var ne := warm_animation_frames(source_sprite_path.replace("_sheet.png","_sheet_ne.png"))
		for animation in ne.get_animation_names():
			if animation=="default": continue
			var name := animation+"_ne"
			frames.add_animation(name); frames.set_animation_loop(name,ne.get_animation_loop(animation))
			frames.set_animation_speed(name,ne.get_animation_speed(animation))
			for index in range(ne.get_frame_count(animation)): frames.add_frame(name,ne.get_frame_texture(animation,index))
		sprite.sprite_frames = frames
	else:
		super._configure_combat_sprite(source_sprite_path)
	# Atlas frames carry padding; mip sampling across their trimmed edges can
	# erase a few head pixels and detach labels from the measured alpha outline.
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	idle_frame = sprite.sprite_frames.get_frame_texture("idle_down",0)
	idle_bounds = Presentation.visible_bounds(idle_frame)
	body_factor = Presentation.body_scale(idle_bounds,unit_id)
	legacy_factor = float(combat_visual_profile.get("render_scale",0))
	if legacy_factor<=0: legacy_factor = FLYING_VISUAL_SCALE if _is_flying_unit() else GROUNDED_VISUAL_SCALE

func _draw() -> void: pass
func _draw_contact_shadow(_target: CanvasItem = self) -> void: pass
func _draw_selection_ground_marker(_target: CanvasItem = self) -> void: pass

func _clamp_to_dungeon_point(point: Vector2) -> Vector2:
	return battle_map.clamp_to_walkable(point) if battle_map!=null else point

func _apply_visual_pose() -> void:
	super._apply_visual_pose()
	if quarter_art: sprite.flip_h = facing.x>0 if facing.y>=0 else facing.x<0
	if sprite==null or idle_frame==null: return
	# Preserve motion/squash/recoil from Unit, but normalize the visible idle body.
	var ratio := body_factor/legacy_factor
	var motion: Dictionary = combat_visual_profile.get("motion_entry",{})
	var foot: Array = motion.get("down_foot_anchor",motion.get("foot_anchor",[])) if down else motion.get("foot_anchor",[])
	var source: Array = combat_visual_profile.get("source_frame_px",[])
	var motion_offset := Vector2.ZERO
	if foot.size()==2 and source.size()==2:
		motion_offset = visual_body.position+Vector2((float(foot[0])-.5)*float(source[0])*sprite.scale.x,(float(foot[1])-.5)*float(source[1])*sprite.scale.y)
	sprite.scale *= ratio
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame==null: frame = idle_frame
	var bounds := Presentation.visible_bounds(frame)
	if not down:
		# Different source frames and squash/rotation must not turn a readable
		# actor back into a tiny attack pose (or overshoot during a skill pulse).
		var extent := absf(sin(sprite.rotation))*bounds.size.x*sprite.scale.x+absf(cos(sprite.rotation))*bounds.size.y*sprite.scale.y
		var target := Presentation.BODY_HEIGHT*Presentation.multiplier(unit_id)
		sprite.scale *= clampf(extent,target,target*1.06)/maxf(1,extent)
	var anchor := (Vector2(bounds.get_center().x,bounds.end.y)-frame.get_size()/2)*sprite.scale
	if sprite.flip_h: anchor.x *= -1
	visual_body.position = -anchor.rotated(sprite.rotation)+motion_offset*ratio
	update_silhouette()
	_refresh_combat_ui_anchors()

func combat_anchor_local(anchor_name: String) -> Vector2:
	if idle_frame==null: return Vector2.ZERO
	var rect := visible_body_rect()
	match anchor_name:
		"head": return Vector2(rect.get_center().x,rect.position.y)-position
		"body": return rect.get_center()-position
	return Vector2.ZERO

func _refresh_combat_ui_anchors() -> void:
	# Vitals are laid out together by the battle UI, never by each pose update.
	pass

func _sync_combat_label_visibility() -> void:
	if name_label!=null: name_label.visible = is_alive()

func vitals_rect() -> Rect2:
	return vitals_rect_at(vitals.position)

func vitals_rect_at(point: Vector2) -> Rect2:
	return Rect2(point+HPBar.BOUNDS.position*vitals.scale,HPBar.BOUNDS.size*vitals.scale)

func desired_vitals_position(zoom: float) -> Vector2:
	var body := visible_body_rect()
	var top := raster_head_world_y()
	return Vector2(body.get_center().x,top-6.0/zoom-HPBar.BOUNDS.end.y*vitals.scale.y)

func raster_head_world_y() -> float:
	# At this zoom a one-pixel antenna may fall between screen samples. Match
	# the actual linear alpha sampling rather than anchoring to an invisible tip.
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame==null: return position.y
	var screen := sprite.get_global_transform_with_canvas()
	var map_screen: Transform2D = battle_runtime.view.world.get_global_transform_with_canvas()
	var key := [frame.get_instance_id(),screen,map_screen,sprite.flip_h,sprite.flip_v]
	if key==head_raster_key: return head_raster_y
	head_raster_key = key
	var rect: Rect2 = map_screen*visible_body_rect()
	var inverse := screen.affine_inverse()
	var image := Presentation.pixels(frame)
	var data: PackedByteArray = image.data
	var width: int = image.width; var height: int = image.height
	var margin: Vector2 = frame.margin.position if frame is AtlasTexture else Vector2.ZERO
	var top := rect.position.y
	var found := false
	for y in range(floori(rect.position.y),ceili(rect.end.y)):
		for x in range(floori(rect.position.x),ceili(rect.end.x)):
			var point: Vector2 = inverse*Vector2(x+.5,y+.5)
			if sprite.flip_h: point.x *= -1
			if sprite.flip_v: point.y *= -1
			point += frame.get_size()/2-margin
			if point.x<0 or point.y<0 or point.x>=width or point.y>=height: continue
			point -= Vector2(.5,.5)
			var start := Vector2i(point.floor()); var weight := point-Vector2(start)
			var alpha := 0.0
			for row in range(2):
				for column in range(2):
					var px := clampi(start.x+column,0,width-1); var py := clampi(start.y+row,0,height-1)
					alpha += data[(py*width+px)*4+3]*(weight.x if column==1 else 1-weight.x)*(weight.y if row==1 else 1-weight.y)
			if alpha>=.5: top = y; found = true; break
		if found: break
	head_raster_y = (map_screen.affine_inverse()*Vector2(rect.get_center().x,top)).y
	return head_raster_y

func set_vitals_position(point: Vector2) -> void:
	vitals.position = point
	var head := position+combat_anchor_local("head")
	var edge := Vector2(point.x,point.y+HPBar.BOUNDS.end.y*vitals.scale.y)
	vitals_link.points = PackedVector2Array([head,edge])
	vitals_link.visible = vitals.visible and is_alive() and point.distance_to(desired_vitals_position(battle_runtime.view.camera_scale))>1
	vitals_link.width = 1.5/battle_runtime.view.camera_scale

func visible_body_rect() -> Rect2:
	if sprite==null or sprite.sprite_frames==null: return Rect2(position,Vector2.ZERO)
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame==null: return Rect2(position,Vector2.ZERO)
	var transform := Transform2D(0,position+visual_body.position)*sprite.transform
	var rect := Rect2(); var first := true
	for pixel in Presentation.visible_outline(frame):
		var point: Vector2 = pixel-frame.get_size()/2
		if sprite.flip_h: point.x *= -1
		if sprite.flip_v: point.y *= -1
		point = transform*point
		if first: rect = Rect2(point,Vector2.ZERO); first = false
		else: rect = rect.expand(point)
	return rect

func update_silhouette() -> void:
	if silhouette==null or sprite.sprite_frames==null: return
	silhouette.texture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var uv := Rect2(0,0,1,1)
	var source: Texture2D = silhouette.texture
	if silhouette.texture is AtlasTexture:
		var atlas: AtlasTexture = silhouette.texture
		uv = Rect2(atlas.region.position/atlas.atlas.get_size(),atlas.region.size/atlas.atlas.get_size())
		source = atlas.atlas
	silhouette.material.set_shader_parameter("actor_texture",source)
	silhouette.material.set_shader_parameter("frame_uv",Vector4(uv.position.x,uv.position.y,uv.end.x,uv.end.y))
	silhouette.texture_filter = sprite.texture_filter
	# Use the exact live pose, including parent rotation/scale and atlas padding.
	silhouette.transform = Transform2D(0,position)*visual_body.transform*sprite.transform
	silhouette.centered = sprite.centered; silhouette.offset = sprite.offset
	silhouette.flip_h = sprite.flip_h; silhouette.flip_v = sprite.flip_v
	silhouette.visible = is_alive() and sprite.visible
	silhouette.material.set_shader_parameter("foot_depth",float(Presentation.depth(position)))
	var inverse: Transform2D = battle_runtime.view.world.global_transform.affine_inverse()
	silhouette.material.set_shader_parameter("map_x",Vector3(inverse.x.x,inverse.y.x,inverse.origin.x))
	silhouette.material.set_shader_parameter("map_y",Vector3(inverse.x.y,inverse.y.y,inverse.origin.y))

func refresh_depth_slot() -> void:
	z_index = Presentation.depth(position)
	if map_visual!=null: map_visual.position = position; map_visual.z_index = z_index
	update_silhouette()

func _physics_process(delta: float) -> void:
	root_timer = maxf(0,root_timer-delta*simulation_speed)
	var previous := position
	if faction==Constants.FACTION_ENEMY and battle_runtime!=null: battle_runtime.hold_enemy_contact(self)
	super._physics_process(delta)
	if faction==Constants.FACTION_ENEMY and battle_runtime!=null and is_alive():
		battle_runtime.block_enemy_step(self,previous)
		refresh_depth_slot()
	if health!=null:
		health.sync(0.0 if battle_runtime!=null and battle_runtime.root.combat_paused else delta*simulation_speed)
		selection_art.visible = selected and is_alive()

func get_cell_tags(target_unit: Node = null) -> Dictionary:
	return battle_map.tags_for(self,target_unit) if battle_map!=null else {}

func create_temporary_trap(c: Vector2i, kind: String, seconds: float, source_id: String = "") -> Dictionary:
	return battle_runtime.create_temporary_trap(c,kind,seconds,source_id)

func trap_duration_multiplier(c: Vector2i) -> float:
	return battle_runtime.trap_duration_multiplier(c)

func face_direction(direction: Vector2) -> void:
	if direction.length()>0.01: facing = direction
	sprite.flip_h = facing.x>0 if facing.y>=0 else facing.x<0

func _update_animation() -> void:
	if not quarter_art: super._update_animation(); return
	if not down:
		if skill_anim_timer>0 or attack_anim_timer>0: face_direction(action_direction)
		elif velocity.length()>1: face_direction(velocity)
	var animation := "down" if down else "skill_down" if skill_anim_timer>0 or presentation_skill_anim_timer>0 else "attack_down" if attack_anim_timer>0 else "move_down" if velocity.length()>1 else "idle_down"
	if facing.y<0: animation += "_ne"
	_play_animation(animation)
	_apply_visual_pose()

func stealthed() -> bool:
	return unit_id=="under_bed_shadow" and (hidden_until>new_skill_clock or quiet_seconds>=5.0)

func break_stealth() -> void:
	hidden_until = 0; quiet_seconds = 0; stealth_broken_at = new_skill_clock

func is_targetable_by(observer: Node = null) -> bool:
	if not is_alive(): return false
	if float(get_meta("revealed_until",0))>new_skill_clock: return true
	if stealthed():
		if observer==null: return false
		var definition: Dictionary = DataRegistry.enemies.get(observer.unit_id,{})
		return bool(definition.get("ignore_stealth_and_false_goals",false)) or bool(observer.get_meta("ignore_monster_stealth",false))
	return super.is_targetable_by(observer)

func effective_atk() -> int:
	var factor := 1.0
	if unit_id=="river_frog" and get_cell_tags().get("water_adjacent",false): factor = 1.1
	if unit_id=="candle_wisp" and get_cell_tags().get("water_adjacent",false): factor = .8
	if float(get_meta("curse_until",0))>new_skill_clock: factor *= float(get_meta("curse_attack_multiplier",.85))
	return roundi(super.effective_atk()*factor)

func effective_attack_interval() -> float:
	return super.effective_attack_interval()/(1.2 if unit_id=="rat_union" and hp<=max_hp*.5 else 1.0)*(float(get_meta("spec_interval_multiplier",1)) if new_skill_clock<float(get_meta("spec_interval_until",0)) else 1.0)

func damage_taken_multiplier_from(attacker: UnitActor) -> float:
	var factor := super.damage_taken_multiplier_from(attacker)
	if unit_id=="hollow_armor" and ("hero" in str(attacker.unit_id) or attacker.unit_id=="official_hero_leon"): factor *= .8
	return factor

func receive_damage(amount: int) -> int:
	var adjusted := float(amount)
	if float(get_meta("curse_until",0))>new_skill_clock: adjusted *= float(get_meta("curse_damage_multiplier",1.2))
	if unit_id=="crumpled_map" and amount>0:
		if incoming_fire: adjusted *= 1.3
		if first_paper_hit: adjusted *= .5; first_paper_hit = false
	if unit_id=="mole_digger" and incoming_area: adjusted *= .75
	incoming_fire = false; incoming_area = false
	var lost := super.receive_damage(roundi(adjusted))
	if lost>0: break_stealth()
	return lost

func apply_root(seconds: float) -> void:
	if new_skill_clock<float(get_meta("spec_immunity_until",0)): return
	root_timer = maxf(root_timer,_heart_control_duration(seconds))

func effective_move_speed(extra_multiplier: float = 1.0) -> float:
	return 0.0 if root_timer>0 else super.effective_move_speed(extra_multiplier)*(float(get_meta("spec_team_move",1)) if new_skill_clock<float(get_meta("spec_team_until",0)) else 1.0)

func receive_context_damage(amount: int, source: Node = null, area: bool = false, fire: bool = false) -> int:
	incoming_source = source; incoming_area = area; incoming_fire = fire
	if source!=null and unit_id=="hollow_armor" and ("hero" in str(source.unit_id) or source.unit_id=="official_hero_leon"): amount = roundi(amount*.8)
	return receive_magic_damage(amount) if fire else receive_damage(amount)

func cleanse_one_negative_status() -> bool:
	if root_timer>0: root_timer = 0; return true
	return super.cleanse_one_negative_status()

func negative_status_count() -> int:
	return super.negative_status_count()+(1 if root_timer>0 else 0)

func cleanse_all_negative_status() -> int:
	var extra := 1 if root_timer>0 else 0
	root_timer = 0
	return super.cleanse_all_negative_status()+extra

func effective_def() -> int:
	return super.effective_def()+int(get_meta("spec_position_def",0))

func _heart_control_duration(seconds: float) -> float:
	if new_skill_clock<float(get_meta("spec_immunity_until",0)): return 0.0
	return super._heart_control_duration(seconds)

func _hostile_status_duration(seconds: float) -> float:
	if new_skill_clock<float(get_meta("spec_immunity_until",0)): return 0.0
	return super._hostile_status_duration(seconds)
