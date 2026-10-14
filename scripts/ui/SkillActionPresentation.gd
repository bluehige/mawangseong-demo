extends RefCounted
# A cosmetic clock owns a prepared action; only its commit calls gameplay.
const StageScript = preload("res://scripts/ui/SkillActionStage.gd")
const ActorArt = preload("res://scripts/ui/UIUXActorArt.gd")
const FontScript = preload("res://scripts/ui/UIFont.gd")
const FacilityVisualScript = preload("res://scripts/ui/FacilityActionVisual.gd")
const DURATION := 1.0
const CONTACT_AT := 0.54
var root: Node
var current: Dictionary = {}
var stage
var stage_layer: CanvasLayer
var actors: Array[AnimatedSprite2D] = []
var target_art: AnimatedSprite2D
var object_art:Control
var object_status:Label
var caption: Label
var age := 0.0
var committing := false
var commits := 0
var completed := 0
var epoch := 0
var last_result := false
var ui_button_states: Array[Dictionary] = []
var ui_inspector_states: Array[Dictionary] = []
var pending: Array[Dictionary] = []

func setup(value: Node) -> void: root = value
func is_active() -> bool: return not current.is_empty()
func has_key(key: String) -> bool:
	if str(current.get("key", "")) == key: return true
	for packet in pending:
		if str(packet.key) == key: return true
	return false
func protected() -> bool:
	return root.current_screen != "combat" or root.combat_paused or root.pause_menu_open or root.story_combat_overlay_open or root.continuity.backlog_open or root.continuity.update_open

func request(packet: Dictionary, effect: Callable) -> bool:
	if is_active():
		if committing and not UISettings.should_show_skill_cutscene(str(packet.key)): return bool(effect.call())
		if committing and str(packet.get("kind", "")) == "duo" and pending.size() < 2 and not has_key(str(packet.key)):
			var queued := packet.duplicate()
			queued["effect"] = effect
			pending.append(queued)
			return true
		return false
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
	_lock_gameplay_buttons()
	_build_stage()
	return true # accepted; success is published only by the commit

func tick(delta: float) -> void:
	if not is_active() or not is_instance_valid(stage): return
	if root.combat_scene.requested_pause: return
	_hide_inspectors()
	stage_layer.transform = root.get_viewport().get_canvas_transform()
	stage.global_transform = stage_layer.transform.affine_inverse()
	age += maxf(0.0, delta)
	_pose()
	var just_committed := age >= CONTACT_AT and not bool(current.committed)
	if age >= CONTACT_AT and not bool(current.committed): _commit()
	if not is_active(): return
	_hide_inspectors()
	root.combat_scene.damage_presentation.tick_action(0.0 if just_committed else delta, str(current.token))
	if age >= DURATION: _finish(true)

func _commit() -> void:
	if not is_active() or bool(current.committed): return
	current.committed = true # Set before the callback to prevent reentrant repeats.
	committing = true
	commits += 1
	var contacts_before: int = root.combat_scene.contact_feedback_events.size()
	var prior_effects: Array = root.effect_root.get_children()
	var effect: Callable = current.effect
	var success := bool(effect.call()) if effect.is_valid() else false
	committing = false
	last_result = success
	if not is_active(): return
	_move_cosmetic_effects(prior_effects)
	# Damage keeps its original world anchors while rendering on the cutscene canvas.
	for row in root.combat_scene.damage_presentation.active:
		if str(row.label.get_meta("action_scene_token", "")) == str(current.token):
			row.label.reparent(stage_layer, true)
	current.success = success
	current["hit"] = root.combat_scene.contact_feedback_events.size() > contacts_before
	if caption != null:
		if not success: caption.text = root.continuity.localized("실행 취소", "Cancelled", "已取消")
		elif bool(current.get("projectile", false)): caption.text = root.continuity.localized("발사", "Launch", "发射")
		elif bool(current.hit): caption.text = root.continuity.localized("명중", "Impact", "命中")
		else: caption.text = root.continuity.localized("효과 발동", "Effect", "效果发动")
		var result_caption:Callable=current.get("result_caption",Callable())
		if success and result_caption.is_valid():caption.text=str(result_caption.call())
	if success and is_instance_valid(object_status):
		var snapshot:Dictionary=current.get("facility_snapshot",{})
		var room:Dictionary=root.rooms.get(str(snapshot.get("room_id","")),{})
		object_status.text="%s · HP %d → %d/%d"%[str(snapshot.get("display_name","")),int(snapshot.get("hp",0)),int(room.get("hp",snapshot.get("hp",0))),int(room.get("max_hp",snapshot.get("max_hp",0)))]
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
	if is_active(): _finish(false, false)
	# Resolve accepted children before menu/load replaces or freezes this state.
	while not pending.is_empty():
		var packet: Dictionary = pending.pop_front()
		var effect: Callable = packet.effect
		if effect.is_valid(): effect.call()

func _finish(record_seen: bool, start_pending: bool = true) -> void:
	if not is_active(): return
	var key := str(current.key)
	var success := bool(current.get("success", false))
	root.combat_scene.damage_presentation.finish_action(str(current.get("token", "")))
	if is_instance_valid(stage_layer):
		for child in stage_layer.get_children():
			if child is Label: child.reparent(root.effect_root, true)
	current.clear()
	_unlock_gameplay_buttons()
	actors.clear()
	target_art = null
	object_art=null
	object_status=null
	caption = null
	if is_instance_valid(stage):
		stage.advance = Callable()
		stage.get_parent().remove_child(stage)
		stage.queue_free()
	stage = null
	if is_instance_valid(stage_layer):
		stage_layer.get_parent().remove_child(stage_layer)
		stage_layer.queue_free()
	stage_layer = null
	if record_seen and success:
		completed += 1
		if not UISettings.mark_skill_cutscene_seen(key): root._log("스킬 컷씬 본 기록을 저장하지 못했습니다. 설정 저장을 다시 확인해 주세요.")
	if start_pending and not pending.is_empty():
		var packet: Dictionary = pending.pop_front()
		var effect: Callable = packet.effect
		# This child was accepted while the parent committed at the same logical time.
		current = packet.duplicate()
		current["committed"] = false
		current["success"] = false
		current["token"] = "action:%d" % epoch
		epoch += 1
		age = 0.0
		_lock_gameplay_buttons()
		root.combat_scene.presentation_hold = true
		_build_stage()
		return
	root.combat_scene.end_presentation_hold()

func contact_anchor(target: Node, fallback: Vector2) -> Vector2:
	if not committing or not is_instance_valid(stage): return fallback
	return stage.to_global(Vector2(1300, 370))

func token_for_contact() -> String:
	return str(current.get("token", "")) if committing else ""

func _build_stage() -> void:
	stage = StageScript.new()
	stage.name = "SkillActionStage"
	stage_layer = CanvasLayer.new()
	stage_layer.name = "CombatCutsceneCanvas"
	stage_layer.layer = preload("res://scripts/ui/kit/UIKitLayers.gd").CUTSCENE
	root.add_child(stage_layer)
	stage.z_index = 0
	stage.advance = Callable(self, "tick")
	stage_layer.add_child(stage)
	stage_layer.transform = root.get_viewport().get_canvas_transform()
	stage.global_transform = stage_layer.transform.affine_inverse()
	var blocker := Control.new()
	blocker.name = "SkillActionInputBlocker"
	blocker.size = Vector2(1920, 1080)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	stage.add_child(blocker)
	var dim := ColorRect.new()
	dim.color = Color("#08091288")
	dim.size = blocker.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blocker.add_child(dim)
	var arena := Panel.new()
	arena.name = "SkillActionStyleBStrip"
	arena.position = Vector2(16, 300)
	arena.size = Vector2(1888, 480)
	arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena.theme = preload("res://scripts/ui/kit/UIKit.gd").scaled_theme(UISettings.text_scale, UISettings.is_touch_ui())
	arena.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	blocker.add_child(arena)
	var surface := preload("res://scripts/ui/kit/KitSurface.gd").new()
	arena.add_child(surface)
	surface.sync(arena, true)
	# The analytic shader sets COLOR directly; use its fill uniforms for alpha.
	var tint_top: Color=preload("res://scripts/ui/kit/UIKitTokens.gd").PANEL_RAISED
	var tint_bottom: Color=preload("res://scripts/ui/kit/UIKitTokens.gd").BACKGROUND
	tint_top.a=0.40; tint_bottom.a=0.40
	surface.material.set_shader_parameter("top_color",tint_top)
	surface.material.set_shader_parameter("bottom_color",tint_bottom)
	_label(blocker, str(current.get("name", "")), Vector2(60, 315), Vector2(1350, 65), 36)
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
	var object_snapshot:Dictionary=current.get("facility_snapshot",{})
	if not object_snapshot.is_empty():
		object_art=FacilityVisualScript.new();object_art.snapshot=object_snapshot
		object_art.position=Vector2(1070,335);object_art.size=Vector2(360,270);blocker.add_child(object_art)
		object_status=_label(blocker,"%s · HP %d/%d"%[str(object_snapshot.display_name),int(object_snapshot.hp),int(object_snapshot.max_hp)],Vector2(980,640),Vector2(540,50),22)
		if bool(object_snapshot.get("missing_art",false)):_label(blocker,root.continuity.localized("시설 그림 없음", "Facility art missing", "设施图像缺失"),Vector2(1080,455),Vector2(440,50),22)
	if is_instance_valid(target):
		target_art = _copy_actor(target)
		target_art.position = Vector2(1300, 470)
		stage.add_child(target_art)
	var skip_button: Button = load("res://scripts/ui/kit/KitButton.gd").new()
	skip_button.name = "SkillActionSkipButton"
	skip_button.tooltip_text = root.continuity.localized("기술 연출 넘기기\n연출만 닫습니다. 기술 효과는 그대로 적용됩니다.", "Skip skill presentation\nClose the animation. Skill effects still apply.", "跳过技能演出\n仅关闭演出，技能效果仍然生效。")
	skip_button.text = root.continuity.localized("스킵", "Skip", "跳过") if UISettings.is_touch_ui() else root.continuity.localized("스킵 · Space", "Skip · Space", "跳过 · Space")
	# The touch speed controls occupy the lower-right HUD on a higher canvas.
	skip_button.configure(skip_button.text, 1, "skip", skip_button.tooltip_text)
	skip_button.position = Vector2(1430, 680)
	skip_button.size = Vector2(430, 84)
	skip_button.add_theme_font_override("font", FontScript.font_for_role(FontScript.ROLE_BUTTON))
	skip_button.add_theme_font_size_override("font_size", UISettings.scaled_font_size(26))
	skip_button.pressed.connect(skip)
	blocker.add_child(skip_button)
	var menu: Button = load("res://scripts/ui/kit/KitButton.gd").new()
	menu.name = "CutsceneCombatMenu"
	menu.text = root.continuity.localized("메뉴", "Menu", "菜单")
	menu.tooltip_text = menu.text
	menu.configure(menu.text, 0, "settings", menu.tooltip_text)
	menu.position = Vector2(1620, 205)
	menu.size = Vector2(240, 84)
	menu.pressed.connect(Callable(root, "_open_pause_menu"))
	blocker.add_child(menu)
	for button in [skip_button,menu]:
		preload("res://scripts/ui/kit/UIKit.gd").inherit_theme(button,arena.theme)
		button.custom_minimum_size.y=84
		button.add_theme_constant_override("icon_max_width",48)
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
		var action_text: String = root.continuity.localized("공격", "Attack", "攻击") if str(current.get("animation", "attack_down")) == "attack_down" else root.continuity.localized("시전", "Cast", "施法")
		caption.text = action_text if age >= 0.18 else root.continuity.localized("준비", "Ready", "准备")
	for index in range(actors.size()):
		var actor := actors[index]
		var start := 0.18 + index * 0.12
		var progress := clampf((age - start) / maxf(0.06, CONTACT_AT - start), 0.0, 1.0)
		if age < start:
			actor.animation = "idle_down"
			actor.frame = 0
		elif age < CONTACT_AT:
			actor.animation = str(current.get("animation", "attack_down"))
			actor.frame = mini(3, int(progress * 4.0))
		else:
			actor.animation = str(current.get("animation", "attack_down")) if age < 0.75 else "idle_down"
			actor.frame = 3 if age < 0.75 else 0
		var lunge := sin(progress * PI * 0.5) * (560.0 if str(current.get("animation", "")) == "attack_down" else 0.0)
		if age > CONTACT_AT: lunge *= maxf(0.0, 1.0 - (age - CONTACT_AT) / 0.30)
		actor.position = Vector2(460 + index * 150 + lunge, 470 + index * 95)
		actor.rotation = 0.03 * sin(progress * PI)
	if is_instance_valid(target_art) and age > CONTACT_AT and bool(current.get("hit", false)):
		target_art.position.x = 1300.0 + 18.0 * maxf(0.0, 1.0 - (age - CONTACT_AT) / 0.20)
		target_art.modulate = Color(1.0, 0.65, 0.65).lerp(Color.WHITE, clampf((age - CONTACT_AT) / 0.18, 0.0, 1.0)) if not UISettings.reduce_combat_effects else Color.WHITE

func _lock_gameplay_buttons() -> void:
	ui_button_states.clear()
	_hide_inspectors()
	for button in root.ui_layer.find_children("*", "BaseButton", true, false):
		var text := str(button.get("text"))
		if text in ["x1", "x1.5", "x2", "x3", "메뉴", "Menu", "菜单", "일시정지", "Pause", "暂停", "재개", "Resume"] or str(button.name).contains("CombatMenu"): continue
		ui_button_states.append({"button": button, "disabled": button.disabled})
		button.disabled = true

func _unlock_gameplay_buttons() -> void:
	for state in ui_button_states:
		if is_instance_valid(state.button): state.button.disabled = bool(state.disabled)
	ui_button_states.clear()
	for state in ui_inspector_states:
		if is_instance_valid(state.panel) and not state.panel.is_queued_for_deletion():state.panel.visible=bool(state.visible)
	ui_inspector_states.clear()

func _hide_inspectors()->void:
	# The dedicated cutscene canvas owns input; hide arena-obscuring HUD too;
	# preserve their previous visibility and restore it at finish/interruption.
	var panels: Array = []
	for id in ["CombatUnitInspector", "CombatSpeedPanel", "PromotionSupportNotice", "PromotionContributionNotice", "CombatCommandFeedbackToast"]:
		panels.append_array(root.ui_layer.find_children(id,"Control",true,false))
	for child in root.ui_layer.get_children():
		if child is Control and child.get_meta("u5c_hud", false): panels.append(child)
	for panel in panels:
		if panel.is_queued_for_deletion():continue
		var recorded:=false
		for state in ui_inspector_states:
			if state.panel==panel:recorded=true;break
		if not recorded:
			if str(panel.name) in ["PromotionSupportNotice", "PromotionContributionNotice"]:
				for child in panel.get_children():
					if child is Label:
						root._log(child.text)
						child.text = root.continuity.localized("지원 효과 적용 · 전투 기록에서 상세 확인", "Support applied · Details in the battle log", "支援已生效 · 详情请查看战斗记录")
						child.position = Vector2(18,12)
						child.size = Vector2(584,92)
				panel.position = Vector2(660,180)
				panel.size = Vector2(620,116)
			ui_inspector_states.append({"panel":panel,"visible":panel.visible})
		panel.visible=false

func debug_snapshot() -> Dictionary:
	return {"active": is_active(), "pending": pending.size(), "age": age, "commits": commits, "completed": completed, "last_result": last_result, "key": current.get("key", "")}

func _move_cosmetic_effects(prior: Array) -> void:
	for effect in root.effect_root.get_children():
		if prior.has(effect) or not effect is AnimatedSprite2D or str(effect.get_meta("vfx_id", "")) == "fireball": continue
		if str(effect.get_meta("vfx_intensity", "")) == "boss": continue
		effect.reparent(stage, false)
		effect.position = object_art.position+object_art.size*.5 if is_instance_valid(object_art) else Vector2(1300, 475) if is_instance_valid(target_art) else actors[0].position if not actors.is_empty() else Vector2(800, 475)
		effect.z_index = 1
		effect.speed_scale = 1.0
		effect.play("play")
