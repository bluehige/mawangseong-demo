extends RefCounted
# A cosmetic clock owns a prepared action; only its commit calls gameplay.
const StageScript = preload("res://scripts/ui/SkillActionStage.gd")
const ActorArt = preload("res://scripts/ui/UIUXActorArt.gd")
const FontScript = preload("res://scripts/ui/UIFont.gd")
const DURATION := 1.0
const CONTACT_AT := 0.54
var root: Node
var current: Dictionary = {}
var stage
var actors: Array[AnimatedSprite2D] = []
var target_art: AnimatedSprite2D
var caption: Label
var age := 0.0
var committing := false
var commits := 0
var completed := 0
var epoch := 0
var last_result := false

func setup(value: Node) -> void: root = value
func is_active() -> bool: return not current.is_empty()
func protected() -> bool:
	return root.current_screen != "combat" or root.combat_paused or root.pause_menu_open or root.story_combat_overlay_open or root.continuity.backlog_open or root.continuity.update_open

func request(packet: Dictionary, effect: Callable) -> bool:
	if is_active(): return false
	if not UISettings.should_show_skill_cutscene(str(packet.key)) or protected():
		return bool(effect.call())
	current = packet.duplicate()
	current["effect"] = effect
	current["committed"] = false
	current["success"] = false
	current["token"] = "action:%d" % epoch
	epoch += 1
	age = 0.0
	last_result = false
	root.combat_scene.begin_presentation_hold()
	_build_stage()
	return true # accepted; success is published only by the commit

func tick(delta: float) -> void:
	if not is_active() or not is_instance_valid(stage): return
	if root.combat_scene.requested_pause: return
	stage.global_transform = root.get_viewport().get_canvas_transform().affine_inverse()
	age += maxf(0.0, delta)
	_pose()
	if age >= CONTACT_AT and not bool(current.committed): _commit()
	if not is_active(): return
	root.combat_scene.damage_presentation.tick_action(delta, str(current.token))
	if age >= DURATION: _finish(true)

func _commit() -> void:
	if not is_active() or bool(current.committed): return
	current.committed = true # Set before the callback to prevent reentrant repeats.
	committing = true
	commits += 1
	var effect: Callable = current.effect
	var success := bool(effect.call()) if effect.is_valid() else false
	committing = false
	last_result = success
	if not is_active(): return
	current.success = success
	if caption != null: caption.text = root.continuity.localized("명중", "Impact", "命中") if success else root.continuity.localized("실행 취소", "Cancelled", "已取消")
	if success and is_instance_valid(target_art) and target_art.sprite_frames.has_animation("down"):
		var target = current.get("target")
		target_art.animation = "down" if is_instance_valid(target) and not target.is_alive() else "idle_down"
		target_art.frame = 0

func skip() -> void:
	if not is_active(): return
	_commit()
	if is_active(): _finish(true)

func interrupt(reason: String) -> void:
	if not is_active(): return
	# Menu/scene interruptions consume an accepted action once, but are not seen.
	# Load/title replace that combat state immediately afterwards.
	_commit()
	if is_active(): _finish(false)

func _finish(record_seen: bool) -> void:
	if not is_active(): return
	var key := str(current.key)
	var success := bool(current.get("success", false))
	current.clear()
	actors.clear()
	target_art = null
	caption = null
	if is_instance_valid(stage):
		stage.advance = Callable()
		stage.get_parent().remove_child(stage)
		stage.queue_free()
	stage = null
	root.combat_scene.end_presentation_hold()
	if record_seen and success:
		completed += 1
		if not UISettings.mark_skill_cutscene_seen(key): root._log("스킬 컷씬 본 기록을 저장하지 못했습니다. 설정 저장을 다시 확인해 주세요.")

func contact_anchor(target: Node, fallback: Vector2) -> Vector2:
	if not committing or not is_instance_valid(stage): return fallback
	return stage.to_global(Vector2(1300, 370))

func token_for_contact() -> String:
	return str(current.get("token", "")) if committing else ""

func _build_stage() -> void:
	stage = StageScript.new()
	stage.name = "SkillActionStage"
	stage.z_index = 2500 # Existing real damage labels3100; all HUD/menu Canvas1 above.
	stage.advance = Callable(self, "tick")
	root.effect_root.add_child(stage)
	stage.global_transform = root.get_viewport().get_canvas_transform().affine_inverse()
	var blocker := Control.new()
	blocker.name = "SkillActionInputBlocker"
	blocker.size = Vector2(1920, 1080)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(blocker)
	var dim := ColorRect.new()
	dim.color = Color("#080912d9")
	dim.size = blocker.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocker.add_child(dim)
	var arena := Panel.new()
	arena.position = Vector2(140, 160)
	arena.size = Vector2(1640, 620)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171324f2")
	style.border_color = Color("#bfa26b")
	style.set_border_width_all(2)
	arena.add_theme_stylebox_override("panel", style)
	blocker.add_child(arena)
	_label(blocker, str(current.get("name", "")), Vector2(205, 190), Vector2(1350, 65), 36)
	caption = _label(blocker, root.continuity.localized("준비", "Ready", "准备"), Vector2(800, 695), Vector2(300, 50), 24)
	var names: Array[String] = []
	for actor in current.get("actors", []):
		if not is_instance_valid(actor): continue
		var sprite := _copy_actor(actor)
		stage.add_child(sprite)
		actors.append(sprite)
		names.append(str(actor.display_name))
	_label(blocker, " + ".join(names), Vector2(220, 710), Vector2(570, 50), 24)
	var target = current.get("target")
	if is_instance_valid(target):
		target_art = _copy_actor(target)
		target_art.position = Vector2(1300, 470)
		stage.add_child(target_art)
	var skip_button := Button.new()
	skip_button.name = "SkillActionSkipButton"
	skip_button.text = root.continuity.localized("스킵 · Space", "Skip · Space", "跳过 · Space")
	skip_button.position = Vector2(1480, 705)
	skip_button.size = Vector2(240, 48)
	skip_button.add_theme_font_override("font", FontScript.font_for_role(FontScript.ROLE_BUTTON))
	skip_button.add_theme_font_size_override("font_size", UISettings.scaled_font_size(20))
	skip_button.pressed.connect(skip)
	blocker.add_child(skip_button)
	_pose()

func _copy_actor(actor: Node) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = actor.sprite.sprite_frames
	sprite.animation = "idle_down"
	sprite.frame = 0
	sprite.speed_scale = 0.0
	sprite.set_meta("action_sprite_path", str(actor.sprite_path))
	var frame = sprite.sprite_frames.get_frame_texture("idle_down", 0)
	var body := ActorArt.visible_bounds(frame)
	sprite.scale = Vector2.ONE * (260.0 / maxf(1.0, body.size.y))
	return sprite

func _label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = LanguageSettings.ui_text(text)
	label.position = position
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FontScript.font_for_role(FontScript.ROLE_EMPHASIS))
	label.add_theme_font_size_override("font_size", UISettings.scaled_font_size(font_size))
	label.add_theme_color_override("font_color", Color("#ffe7b1"))
	parent.add_child(label)
	return label

func _pose() -> void:
	if caption != null and not bool(current.get("committed", false)):
		caption.text = root.continuity.localized("공격", "Attack", "攻击") if age >= 0.18 else root.continuity.localized("준비", "Ready", "准备")
	for index in range(actors.size()):
		var actor := actors[index]
		var start := 0.18 + index * 0.12
		var progress := clampf((age - start) / maxf(0.06, CONTACT_AT - start), 0.0, 1.0)
		if age < start:
			actor.animation = "idle_down"
			actor.frame = 0
		elif age < CONTACT_AT:
			actor.animation = "attack_down"
			actor.frame = mini(3, int(progress * 4.0))
		else:
			actor.animation = "skill_down"
			actor.frame = mini(3, int(clampf((age - CONTACT_AT) / 0.34, 0.0, 0.99) * 4.0))
		var lunge := sin(progress * PI * 0.5) * 560.0
		if age > CONTACT_AT: lunge *= maxf(0.0, 1.0 - (age - CONTACT_AT) / 0.30)
		actor.position = Vector2(460 + index * 150 + lunge, 470 + index * 95)
		actor.rotation = 0.03 * sin(progress * PI)
	if is_instance_valid(target_art) and age > CONTACT_AT and bool(current.get("success", false)):
		target_art.position.x = 1300.0 + 18.0 * maxf(0.0, 1.0 - (age - CONTACT_AT) / 0.20)

func debug_snapshot() -> Dictionary:
	return {"active": is_active(), "age": age, "commits": commits, "completed": completed, "last_result": last_result, "key": current.get("key", "")}
