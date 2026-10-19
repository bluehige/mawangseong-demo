extends RefCounted
class_name StoryDialoguePresenter

const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const KitPanelScript = preload("res://scripts/story/DialogueStrip.gd")
# Keep the button factory out of GameRoot's compile-time preload graph.
var icon_button_script: Script = load("res://scripts/ui/kit/KitIconButton.gd")
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
const TextLayout = preload("res://scripts/ui/DialogueLayout.gd")
const THRONE_BACKGROUND := "res://assets/ui/v1213/dialogue_throne.png"
const LONG_STORY_TRIGGERS := ["opening", "new_game", "management_entered", "precombat_confirmed", "result_win"]

var root = null
var hud = null
var participant_key := ""
var participants: Array[String] = []
var participant_emotions: Dictionary = {}
var legacy_auto_enabled := false
var legacy_auto_remaining := 0.0
var auto_at_end := false
var combat_layers := Layers.new()
var page_key := ""
var page_index := 0
var text_pages: Array[String] = []
var page_body: RichTextLabel
var page_counter: Label

func setup(root_node, hud_controller) -> void:
	root = root_node
	hud = hud_controller

func build_fullscreen() -> void:
	var cue: Dictionary = root.story_director.current_cue()
	var scene: Dictionary = root.story_director.current_scene()
	var screen = root._onboarding_screen_panel(Kit.Tokens.BACKGROUND)
	screen.name = "StoryDialogueScreen"
	screen.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_background(screen, scene)
	_build_frame(screen, cue, scene, false)

func build_legacy() -> void:
	var screen = root._onboarding_screen_panel(Kit.Tokens.BACKGROUND)
	screen.name = "LegacyDialogueScreen"
	screen.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var line: Dictionary = {} if root.onboarding_dialogue_queue.is_empty() else root.onboarding_dialogue_queue[clampi(root.onboarding_dialogue_index, 0, root.onboarding_dialogue_queue.size() - 1)]
	if line.get("v130r_text",false):
		var localized: Dictionary = root.v130r_story.localized_entry(str(line.get("id","")))
		if not localized.is_empty(): line = localized
	_background(screen, line)
	var speaker_id := str(line.get("speaker", "NARRATOR"))
	var speaker_name := str(line.get("speaker_name", root._onboarding_speaker_name(speaker_id)))
	if speaker_id == "CHR_DARKLORD_PLAYER": speaker_name = LanguageSettings.player_display_name(root._onboarding_player_name())
	else: speaker_name = LanguageSettings.ui_text(speaker_name)
	var text: String = root._onboarding_line_text(line) if not line.is_empty() else root.continuity.localized("표시할 대사가 없습니다.", "No dialogue is available.", "没有可显示的对白。")
	root.continuity.record("legacy:%s:%d" % [str(root.onboarding_dialogue_queue.hash()), root.onboarding_dialogue_index], speaker_name, text)
	_build_shared_frame(screen, speaker_id, speaker_name, str(line.get("emotion", "")), text, false, true)

func build_combat_overlay() -> void:
	if root.ui_layer == null or not root.story_director.is_active() or root.current_screen != "combat": return
	clear_combat_overlay()
	var controls: Array = []
	for child in root.ui_layer.get_children():
		if child is Control and str(child.name) not in ["PauseMenuOverlay", "DialogueBacklogOverlay", "CampaignLeaveConfirmation", "CampaignSaveNoticeOverlay", "UpdateNotesOverlay"]:
			controls.append(child)
	combat_layers.set_cutscene_active(true, controls)
	var overlay = hud.panel(Rect2(0, 0, 1920, 1080), Color("#00000040"), Color.TRANSPARENT, "StoryCombatDialogueOverlay", "flat")
	overlay.name = "StoryCombatDialogueOverlay"
	overlay.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	overlay.z_index = 3500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_frame(overlay, root.story_director.current_cue(), root.story_director.current_scene(), true)

func clear_combat_overlay() -> void:
	if root == null or root.ui_layer == null: return
	combat_layers.set_cutscene_active(false, [])
	var existing: Node = root.ui_layer.get_node_or_null("StoryCombatDialogueOverlay")
	if existing != null:
		root.ui_layer.remove_child(existing)
		existing.queue_free()

func _background(parent: Control, scene: Dictionary) -> void:
	var image: TextureRect = hud.texture(parent, background_path(scene), Rect2(0, 0, 1920, 1080))
	image.name = "DialogueBackground"
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE

func background_path(scene: Dictionary) -> String:
	for key in ["background", "background_path", "scene_background"]:
		var path := str(scene.get(key, ""))
		if path.begins_with("res://") and ResourceLoader.exists(path): return path
	return THRONE_BACKGROUND

func _build_frame(parent: Control, cue: Dictionary, _scene: Dictionary, combat_overlay: bool) -> void:
	root.continuity.record_story()
	var resolved: Dictionary = root._story_resolve_cue_speaker(cue)
	var speaker_id := str(resolved.get("speaker_id", "NARRATOR"))
	resolved["speaker_label"] = root._onboarding_player_name() if speaker_id == "CHR_DARKLORD_PLAYER" else str(resolved.get("speaker_label", root._onboarding_speaker_name(speaker_id)))
	var speaker_name := LanguageSettings.story_speaker(resolved, root._onboarding_player_name())
	_build_shared_frame(parent, speaker_id, speaker_name, str(resolved.get("portrait_emotion", "")), LanguageSettings.story_text(cue, root._onboarding_player_name()), combat_overlay, false)

func _build_shared_frame(parent: Control, speaker_id: String, speaker_name: String, emotion: String, text: String, combat: bool, legacy: bool) -> void:
	_update_participants(speaker_id, emotion, legacy)
	for slot in range(participants.size()): _standing(parent, participants[slot], slot, participants[slot] == speaker_id, combat)
	var strip := KitPanelScript.new()
	strip.name = "DialogueTextPanel" if legacy else "StoryDialogueTextPanel"
	strip.top_jewel = true
	var raster_only := bool(ProjectSettings.get_setting("debug/approved_map_step6",false))
	strip.raster_only = raster_only
	parent.add_child(strip)
	strip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	strip.anchor_top = 0.68 if not combat else 0.70
	strip.offset_left = 24
	strip.offset_right = -24
	strip.offset_bottom = -24
	strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	strip.mouse_filter = Control.MOUSE_FILTER_STOP
	strip.content.add_theme_constant_override("separation", 8)
	var heading := HBoxContainer.new()
	strip.content.add_child(heading)
	var speaker := Kit.label(speaker_name, "body", true)
	speaker.name = "DialogueSpeakerLabel" if legacy else "StorySpeakerLabel"
	speaker.add_theme_color_override("font_color", Kit.Tokens.HIGHLIGHT)
	speaker.add_theme_font_size_override("font_size", maxi(26, Kit.Tokens.font_size(28, UISettings.text_scale, UISettings.is_touch_ui())))
	# Wrapped names must not impose their unwrapped minimum width on the frame.
	speaker.clip_text = true
	heading.add_child(speaker)
	var counter := Kit.label("", "support")
	counter.name = "DialoguePageCounter"
	counter.size_flags_horizontal = Control.SIZE_SHRINK_END
	counter.add_theme_font_size_override("font_size",20)
	heading.add_child(counter)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	strip.content.add_child(row)
	var body := RichTextLabel.new()
	body.name = "DialogueText" if legacy else "StoryDialogueText"
	body.text = text
	body.bbcode_enabled = false
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = 116
	body.add_theme_font_override("normal_font", UIFontScript.font_for_role(UIFontScript.ROLE_DIALOGUE))
	body.add_theme_font_size_override("normal_font_size", maxi(32, Kit.Tokens.font_size(40, UISettings.text_scale, UISettings.is_touch_ui())))
	body.add_theme_color_override("default_color", Kit.Tokens.TEXT)
	body.add_theme_constant_override("line_separation", 6)
	body.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(body)
	var next = icon_button_script.new().configure_icon("play", root.continuity.localized("다음 대사 · 수동 입력은 자동 재생을 끕니다.", "Next line · manual input turns auto off.", "下一句 · 手动操作会关闭自动播放。"))
	next.set_meta("uiux_external_button", true)
	next.name = "LegacyNextButton" if legacy else "StoryNextButton"
	if auto_at_end:
		next.tooltip_text = root.continuity.localized("자동 재생 완료 · 마지막 대사를 읽고 계속합니다.", "Auto finished · read the final line and continue.", "自动播放完成 · 阅读最后一句后继续。")
	next.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(next)
	var advance := Callable(root, "_onboarding_advance_dialogue") if legacy else Callable(root, "_story_advance_dialogue").bind(true)
	if legacy and root.onboarding_dialogue_queue.is_empty():
		advance = Callable(root, "_set_screen").bind(root.onboarding_dialogue_return_screen)
	next.pressed.connect(advance)
	root._connect_dialogue_click(strip, body, advance)
	Kit.apply_scale(strip, UISettings.text_scale, UISettings.is_touch_ui())
	# Override only this surface instance; shared kit panels remain unchanged.
	var top_color := Kit.Tokens.PANEL_RAISED
	var bottom_color := Kit.Tokens.BACKGROUND
	top_color.a = 0.72
	bottom_color.a = 0.78
	strip.surface.material.set_shader_parameter("top_color", top_color)
	strip.surface.material.set_shader_parameter("bottom_color", bottom_color)
	_toolbar(parent, legacy)
	if raster_only:
		strip.surface.hide()
		preload("res://scripts/ui/ApprovedBattleUI.gd").prepare_result_controls(parent)
		# Preserve the GPT artwork's corners instead of stretching its bevel
		# underneath the copy. Only this dialogue instance receives these margins.
		var frame := preload("res://scripts/ui/ObsidianStyleBox.gd").new()
		frame.texture = preload("res://assets/ui/uiux/obsidian_panel.png")
		for side in [SIDE_LEFT,SIDE_RIGHT]: frame.set_content_margin(side,48)
		for side in [SIDE_TOP,SIDE_BOTTOM]: frame.set_content_margin(side,28)
		strip.add_theme_stylebox_override("panel",frame)
	var key := "%s:%s:%s:%s" % [legacy,root.onboarding_dialogue_index if legacy else root.story_director.current_cue_id,LanguageSettings.locale,text]
	speaker.custom_minimum_size.y = ceilf(speaker.get_theme_font("font").get_height(speaker.get_theme_font_size("font_size")))+4
	body.resized.connect(_paginate.bind(body,counter,text,key))
	_paginate.call_deferred(body,counter,text,key)
	if combat:
		var paused: Label = hud.label(parent, LanguageSettings.story_ui("combat_paused"), Vector2(32, 32), Vector2(750, 48), 24, Kit.Tokens.HIGHLIGHT, HORIZONTAL_ALIGNMENT_LEFT, "StoryCombatPausedLabel", UIFontScript.ROLE_EMPHASIS)
		paused.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _paginate(body: RichTextLabel, counter: Label, text: String, key: String) -> void:
	if not is_instance_valid(body) or not body.is_inside_tree() or body.is_queued_for_deletion() or body.size.x<16 or body.size.y<16: return
	if page_key != key:
		page_key = key; page_index = 0
	text_pages = TextLayout.pages(text,body.get_theme_font("normal_font"),body.get_theme_font_size("normal_font_size"),body.size,6)
	page_index = clampi(page_index,0,text_pages.size()-1)
	page_body = body; page_counter = counter
	_show_page()

func _show_page() -> void:
	if not is_instance_valid(page_body) or text_pages.is_empty(): return
	# Page boundaries preserve every source character. Only boundary whitespace
	# is hidden while drawing, avoiding a spurious blank row at the page edge.
	page_body.text = text_pages[page_index].strip_edges()
	page_body.set_meta("dialogue_page_count",text_pages.size())
	page_body.set_meta("dialogue_full_text","".join(text_pages))
	if is_instance_valid(page_counter):
		page_counter.text = "%d / %d" % [page_index+1,text_pages.size()] if text_pages.size()>1 else ""

func advance_page(manual: bool) -> bool:
	if not is_instance_valid(page_body) or page_index+1>=text_pages.size(): return false
	page_index += 1
	if manual:
		legacy_auto_enabled = false
		root.story_director.set_auto(false)
	_show_page()
	root._story_reset_auto_timer()
	if manual: root._story_refresh_dialogue_ui()
	return true

func _update_participants(speaker: String, emotion: String, legacy: bool) -> void:
	var key: String = "legacy:%s" % root.onboarding_dialogue_queue.hash() if legacy else "story:" + root.story_director.current_scene_id
	if participant_key != key:
		participant_key = key
		participants.clear()
		participant_emotions.clear()
		var ids: Array[String] = []
		var cues: Array = root.onboarding_dialogue_queue if legacy else root.story_director.current_scene().get("cues", [])
		for cue in cues:
			var id: String = str(cue.get("speaker", "")) if legacy else str(root._story_resolve_cue_speaker(cue).get("speaker_id", ""))
			if id != "" and id != "NARRATOR" and not ids.has(id): ids.append(id)
		if ids.has("CHR_DARKLORD_PLAYER"):
			participants.append("CHR_DARKLORD_PLAYER")
			ids.erase("CHR_DARKLORD_PLAYER")
		elif ids.size() < 2:
			participants.append("CHR_DARKLORD_PLAYER")
		for id in ids:
			if participants.size() < 2: participants.append(id)
	if speaker != "" and speaker != "NARRATOR" and not participants.has(speaker):
		if participants.size() < 2: participants.append(speaker)
		else: participants[1 if participants[0] == "CHR_DARKLORD_PLAYER" else 0] = speaker
	participant_emotions[speaker] = emotion

func _standing(parent: Control, id: String, slot: int, active: bool, combat: bool) -> void:
	var path: String = root._onboarding_speaker_portrait_path(id, str(participant_emotions.get(id, "")))
	if path == "": return
	var image := TextureRect.new()
	image.name = "DialogueStandingLeft" if slot == 0 else "DialogueStandingRight"
	image.texture = root._onboarding_portrait_texture(path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.modulate = Color.WHITE if active else Color(0.5, 0.5, 0.5, 1)
	image.set_meta("speaker_id", id)
	image.set_meta("portrait_path", path)
	parent.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.anchor_left = 0.005 if slot == 0 else 0.50
	image.anchor_right = 0.495 if slot == 0 else 1.0
	image.anchor_top = 0.02 if not combat else 0.40
	image.anchor_bottom = 0.96
	if combat:
		image.anchor_left = 0.06 if slot == 0 else 0.65
		image.anchor_right = 0.35 if slot == 0 else 0.94
	if id == "CHR_BATI":
		# A floating mascot at the lord's chest height, below the toolbar.
		image.anchor_left = 0.10 if slot == 0 else 0.58
		image.anchor_right = 0.42 if slot == 0 else 0.94
		image.anchor_top = 0.26 if not combat else 0.44
		image.anchor_bottom = 0.77

func _toolbar(parent: Control, legacy: bool) -> void:
	var margin := MarginContainer.new()
	margin.name = "DialogueToolbar"
	parent.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	_icon(row, "log", root.continuity.localized("대화 로그 · 읽기 전용, 자동 재생 일시정지", "Dialogue log · read only, pauses auto", "对白记录 · 只读，暂停自动播放"), Callable(root.continuity, "open_backlog"), "DialogueBacklogButton", root.continuity.localized("로그", "Log", "记录"))
	var automatic := legacy_auto_enabled if legacy else bool(root.story_director.auto_enabled)
	var auto = _icon(row, "auto", root.continuity.localized("자동 재생 · 켜기/끄기, 마지막 대사에서 멈춤", "Auto · on/off, stops at the final line", "自动播放 · 开/关，在最后一句停止"), Callable(self, "toggle_legacy_auto") if legacy else Callable(root, "_story_toggle_auto"), "LegacyStoryAutoButton" if legacy else "StoryAutoButton", root.continuity.localized("자동", "Auto", "自动"))
	auto.toggle_mode = true
	auto.set_pressed_no_signal(automatic)
	if automatic: auto.set_variant(icon_button_script.VariantStyle.PRIMARY)
	auto.disabled = not auto_allowed(legacy)
	if auto.disabled: auto.tooltip_text = root.continuity.localized("자동 재생 · 오프닝/관리 진입/전투 직전/승리 후 긴 묶음에 사용", "Auto · available for long opening/management/precombat/victory groups", "自动播放 · 用于开场、管理开始、战斗前及胜利后的长对白")
	var allowed: bool = root.campaign_cycle_index >= 2 and root.onboarding_dialogue_queue.size() > 1 if legacy else root.story_director.skip_allowed()
	var skip = _icon(row, "skip", root.continuity.localized("넘기기 · 읽은 대화만 허용", "Skip · available for previously read dialogue", "跳过 · 仅限已读对白"), Callable(root, "_onboarding_skip_dialogue") if legacy else Callable(root, "_story_skip_dialogue"), "LegacyStorySkipButton" if legacy else "StorySkipButton", root.continuity.localized("넘기기", "Skip", "跳过"))
	skip.disabled = not allowed
	if not allowed:
		skip.tooltip_text = ""
		skip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lock := Kit.image("lock", 28)
	lock.name = "DialogueSkipLock"
	skip.add_child(lock)
	lock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lock.visible = not allowed
	_icon(row, "menu", root.continuity.localized("게임 메뉴 · 대화 자동 재생 일시정지", "Game menu · pauses dialogue auto", "游戏菜单 · 暂停对白自动播放"), Callable(root, "_open_pause_menu"), "DialogueMenuButton", root.continuity.localized("메뉴", "Menu", "菜单"))
	Kit.apply_scale(margin, UISettings.text_scale, UISettings.is_touch_ui())

func _icon(parent: Control, icon: String, help: String, callback: Callable, id: String, caption: String) -> Button:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 4)
	parent.add_child(group)
	var button = icon_button_script.new().configure_icon(icon, help)
	button.name = id
	button.set_meta("uiux_external_button", true)
	button.icon = Kit.Icons.get_icon(icon, 64)
	button.add_theme_constant_override("icon_max_width", 64)
	group.add_child(button)
	var label := Kit.label(caption, "support")
	label.name = id + "Caption"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	group.add_child(label)
	button.pressed.connect(callback)
	return button

func auto_allowed(legacy: bool) -> bool:
	if not legacy: return str(root.story_director.current_scene().get("trigger", "")) in LONG_STORY_TRIGGERS
	if root.onboarding_dialogue_queue.size() < 2: return false
	if root.onboarding_dialogue_complete_action == root.ONBOARDING_ACTION_DAY1_MANAGEMENT: return true
	if root.onboarding_dialogue_queue.size() >= 4 and root.onboarding_dialogue_return_screen in ["intrusion_brief", "defense_start", "result"]: return true
	for line in root.onboarding_dialogue_queue:
		if str(line.get("trigger", "")) in ["opening_start", "management_open", "management_open_extended", "battle_start", "precombat_confirmed", "win", "win_no_treasure_loss", "result_win"]: return true
	return false

func reset_legacy_auto() -> void:
	legacy_auto_enabled = false
	page_key = ""; page_index = 0; text_pages.clear()
	auto_at_end = false
	reset_legacy_timer()

func reset_legacy_timer() -> void:
	if root.onboarding_dialogue_queue.is_empty(): return
	var text: String = root._onboarding_line_text(root.onboarding_dialogue_queue[root.onboarding_dialogue_index])
	legacy_auto_remaining = clampf(1.4 + text.length() * 0.045, 2.2, 7.0)

func toggle_legacy_auto() -> void:
	if not auto_allowed(true): return
	legacy_auto_enabled = not legacy_auto_enabled
	auto_at_end = false
	reset_legacy_timer()
	root._story_refresh_dialogue_ui()

func tick_legacy_auto(delta: float) -> void:
	if not legacy_auto_enabled or root.onboarding_dialogue_queue.is_empty(): return
	legacy_auto_remaining -= delta
	if legacy_auto_remaining > 0.0: return
	if page_index+1<text_pages.size():
		root._onboarding_advance_dialogue(false)
		return
	if root.onboarding_dialogue_index + 1 >= root.onboarding_dialogue_queue.size():
		legacy_auto_enabled = false
		auto_at_end = true
		root._story_refresh_dialogue_ui()
	else: root._onboarding_advance_dialogue(false)

static func dialogue_layout(_text: String, _touch: bool) -> Dictionary:
	return {"box_rect":Rect2(24,821,1872,235), "speaker_rect":Rect2(48,845,1690,44), "text_rect":Rect2(48,897,1710,132), "next_rect":Rect2(1788,972,84,84), "skip_rect":Rect2(1680,24,84,84)}
