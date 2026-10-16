extends "res://scripts/units/Unit.gd"
## Existing Unit movement/status/combat math; raster-only branch presentation.
var battle_map: RefCounted
var battle_runtime: RefCounted
var selection_art: Sprite2D
var health: TextureProgressBar
var map_visual: Node2D

func attach_map_visuals(parent: Node2D) -> void:
	# Simulation coordinates stay independent of management zoom/pan. Only the
	# existing live sprite/labels are parented to the map's presentation transform.
	map_visual = Node2D.new(); parent.add_child(map_visual)
	for child in [visual_body,name_label,selection_art,health]: child.reparent(map_visual,false)
	map_visual.position = position

func _ready() -> void:
	super._ready()
	ground_visual.hide()
	name_label.add_theme_font_override("font",preload("res://assets/fonts/NEXON_Maplestory_Light.otf"))
	name_label.add_theme_font_size_override("font_size",16)
	selection_art = Sprite2D.new()
	selection_art.texture = preload("res://assets/maps/v130r_step2/ui/cell_highlight.png")
	selection_art.modulate = Color(.3,1,.8,.8); selection_art.show_behind_parent = true
	add_child(selection_art); selection_art.hide()
	health = TextureProgressBar.new(); health.position = Vector2(-27,-9); health.size = Vector2(54,7)
	health.texture_under = preload("res://assets/ui/uiux/obsidian_button.png")
	health.texture_progress = preload("res://assets/ui/uiux/obsidian_panel.png")
	health.tint_progress = Color(.6,1,.65); health.nine_patch_stretch = true
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(health)

func _draw() -> void: pass
func _draw_contact_shadow(_target: CanvasItem = self) -> void: pass
func _draw_selection_ground_marker(_target: CanvasItem = self) -> void: pass

func _clamp_to_dungeon_point(point: Vector2) -> Vector2:
	return battle_map.clamp_to_walkable(point) if battle_map!=null else point

func _apply_visual_pose() -> void:
	super._apply_visual_pose()
	# Native GPT frames and animation retained, scaled to the approved one-cell body.
	if sprite!=null:
		sprite.scale *= .62
		visual_body.position *= .62

func refresh_depth_slot() -> void:
	z_index = clampi(int(position.y),1,3500)
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
