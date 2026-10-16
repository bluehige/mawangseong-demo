extends "res://scripts/units/Unit.gd"
## Existing Unit movement/status/combat math; raster-only branch presentation.
const Presentation = preload("res://scripts/map_builder/ApprovedActorPresentation.gd")
var battle_map: RefCounted
var battle_runtime: RefCounted
var selection_art: Sprite2D
var health: TextureProgressBar
var map_visual: Node2D
var vitals: Node2D
var idle_bounds := Rect2()
var idle_frame: Texture2D
var body_factor := 1.0
var legacy_factor := 1.0

func setup(source_id: String, stats: Dictionary, unit_faction: String, room_id: String) -> void:
	super.setup(source_id,stats,unit_faction,room_id)
	# Keep each boss's identifying name visible inside the compact overhead label.
	if source_id=="official_hero_leon": name_label.text = "레온"
	elif source_id=="selen_trainee_paladin": name_label.text = "셀렌"

func attach_map_visuals(parent: Node2D) -> void:
	# Simulation coordinates stay independent of management zoom/pan. Only the
	# existing live sprite/labels are parented to the map's presentation transform.
	map_visual = Node2D.new(); parent.add_child(map_visual)
	for child in [visual_body,selection_art]: child.reparent(map_visual,false)
	vitals = Node2D.new(); parent.add_child(vitals); vitals.z_index = 3800
	for child in [name_label,health]: child.reparent(vitals,false)
	map_visual.position = position
	refresh_depth_slot()

func _exit_tree() -> void:
	if is_instance_valid(map_visual): map_visual.queue_free()
	if is_instance_valid(vitals): vitals.queue_free()

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
	health = TextureProgressBar.new(); health.position = Vector2(-38,-8); health.size = Vector2(76,8)
	health.texture_under = preload("res://assets/ui/uiux/obsidian_button.png")
	# Opaque bright rim crop of the existing GPT highlight, tinted by faction.
	var fill := AtlasTexture.new()
	fill.atlas = preload("res://assets/maps/v130r_step2/ui/cell_highlight.png")
	fill.region = Rect2(76,53,8,4)
	health.texture_progress = fill
	health.tint_progress = Color(.6,1,.65); health.nine_patch_stretch = true
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(health)

func _configure_combat_sprite(source_sprite_path: String) -> void:
	super._configure_combat_sprite(source_sprite_path)
	idle_frame = sprite.sprite_frames.get_frame_texture("idle_down",0)
	idle_bounds = Presentation.Art.visible_bounds(idle_frame)
	body_factor = Presentation.body_scale(idle_bounds,unit_id)
	legacy_factor = float(combat_visual_profile.get("render_scale",0))
	if legacy_factor<=0: legacy_factor = FLYING_VISUAL_SCALE if _is_flying_unit() else GROUNDED_VISUAL_SCALE
	if health!=null:
		health.value = 100.0*hp/maxi(1,max_hp)
		health.size = Vector2(Presentation.BODY_SIZE.x*Presentation.multiplier(unit_id),8*Presentation.multiplier(unit_id))
		health.position.x = -health.size.x/2
		health.tint_progress = Color(.45,1,.6) if faction=="monster" else Color(1,.35,.3)

func _draw() -> void: pass
func _draw_contact_shadow(_target: CanvasItem = self) -> void: pass
func _draw_selection_ground_marker(_target: CanvasItem = self) -> void: pass

func _clamp_to_dungeon_point(point: Vector2) -> Vector2:
	return battle_map.clamp_to_walkable(point) if battle_map!=null else point

func _apply_visual_pose() -> void:
	super._apply_visual_pose()
	if sprite==null or idle_frame==null: return
	# Preserve motion/squash/recoil from Unit, but normalize the visible idle body.
	var ratio := body_factor/legacy_factor
	sprite.scale *= ratio
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame==null: frame = idle_frame
	var bounds := Presentation.Art.visible_bounds(frame)
	var anchor := (bounds.get_center()-frame.get_size()/2)*sprite.scale
	if sprite.flip_h: anchor.x *= -1
	var old_body := visual_body.position*ratio
	var foot_y := (bounds.end.y-frame.get_height()/2)*sprite.scale.y
	visual_body.position = Vector2(-anchor.x,-foot_y)
	# Existing profile position is the idle foot plus an animation offset.
	var motion: Dictionary = combat_visual_profile.get("motion_entry",{})
	var foot: Array = motion.get("down_foot_anchor",motion.get("foot_anchor",[])) if down else motion.get("foot_anchor",[])
	var source: Array = combat_visual_profile.get("source_frame_px",[])
	if foot.size()==2 and source.size()==2:
		visual_body.position += old_body+Vector2((float(foot[0])-.5)*float(source[0])*sprite.scale.x,(float(foot[1])-.5)*float(source[1])*sprite.scale.y)
	_refresh_combat_ui_anchors()

func combat_anchor_local(anchor_name: String) -> Vector2:
	if idle_frame==null: return Vector2.ZERO
	var height := idle_bounds.size.y*body_factor
	match anchor_name:
		"head": return Vector2(0,-height-8)
		"body": return Vector2(0,-height/2)
	return Vector2.ZERO

func _refresh_combat_ui_anchors() -> void:
	# Vitals are laid out together by the battle UI, never by each pose update.
	pass

func _sync_combat_label_visibility() -> void:
	if name_label!=null: name_label.visible = is_alive()

func vitals_rect() -> Rect2:
	return Rect2(vitals.position+Vector2(-58,-26),Vector2(116,38))

func set_vitals_position(point: Vector2) -> void:
	vitals.position = point
	name_label.position = Vector2(-58,-26)
	health.position.y = 0

func visible_body_rect() -> Rect2:
	return Rect2(position-Vector2(idle_bounds.size.x*body_factor/2,idle_bounds.size.y*body_factor),idle_bounds.size*body_factor)

func refresh_depth_slot() -> void:
	z_index = Presentation.depth(position)
	if map_visual!=null: map_visual.position = position; map_visual.z_index = z_index

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if health!=null:
		health.value = 100.0*hp/maxi(1,max_hp); health.visible = is_alive()
		selection_art.visible = selected and is_alive()

func get_cell_tags(target_unit: Node = null) -> Dictionary:
	return battle_map.tags_for(self,target_unit) if battle_map!=null else {}

func create_temporary_trap(c: Vector2i, kind: String, seconds: float, source_id: String = "") -> Dictionary:
	return battle_runtime.create_temporary_trap(c,kind,seconds,source_id)

func trap_duration_multiplier(c: Vector2i) -> float:
	return battle_runtime.trap_duration_multiplier(c)
