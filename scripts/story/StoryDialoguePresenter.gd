extends RefCounted
class_name StoryDialoguePresenter

const UIFontScript = preload("res://scripts/ui/UIFont.gd")

var root = null
var hud = null


func setup(root_node, hud_controller) -> void:
	root = root_node
	hud = hud_controller


func build_fullscreen() -> void:
	var cue: Dictionary = root.story_director.current_cue()
	var scene: Dictionary = root.story_director.current_scene()
	var screen = root._onboarding_screen_panel(Color("#050407e8"))
	screen.name = "StoryDialogueScreen"
	root._onboarding_add_scene_illustration(
		screen,
		root._onboarding_rect("S02_DIALOGUE", "SceneIllustration", Rect2(0, 0, 1920, 1080)),
		root._onboarding_dialogue_scene_path({})
	)
	_build_frame(screen, cue, scene, false)


func build_combat_overlay() -> void:
	if root.ui_layer == null or not root.story_director.is_active():
		return
	var existing: Node = root.ui_layer.get_node_or_null("StoryCombatDialogueOverlay")
	if existing != null:
		root.ui_layer.remove_child(existing)
		existing.queue_free()
	var cue: Dictionary = root.story_director.current_cue()
	var scene: Dictionary = root.story_director.current_scene()
	var overlay = hud.panel(Rect2(0, 0, 1920, 1080), Color("#0000008f"), Color("#00000000"), "StoryCombatDialogueOverlay", "flat")
	overlay.name = "StoryCombatDialogueOverlay"
	overlay.z_index = 3500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_build_frame(overlay, cue, scene, true)


func clear_combat_overlay() -> void:
	if root == null or root.ui_layer == null:
		return
	var existing: Node = root.ui_layer.get_node_or_null("StoryCombatDialogueOverlay")
	if existing != null:
		root.ui_layer.remove_child(existing)
		existing.queue_free()


func _build_frame(parent: Control, cue: Dictionary, scene: Dictionary, combat_overlay: bool) -> void:
	var touch_ui := UISettings.is_touch_ui()
	var speaker_id := str(cue.get("speaker_id", "NARRATOR"))
	var speaker_name := str(cue.get("speaker_label", ""))
	if speaker_name == "":
		speaker_name = root._onboarding_speaker_name(speaker_id)
	if speaker_id == "CHR_DARKLORD_PLAYER":
		speaker_name = root._onboarding_player_name()
	var title := str(scene.get("title", "메인 시나리오"))
	var header_y := 46.0 if not combat_overlay else 54.0
	hud.label(parent, title, Vector2(72, header_y), Vector2(920, 42), 24, Color("#d8d1df"), HORIZONTAL_ALIGNMENT_LEFT, "StoryDialogueHeader", UIFontScript.ROLE_EMPHASIS)
	if combat_overlay:
		hud.label(parent, "대화 중 · 전투 완전 정지", Vector2(1220, header_y), Vector2(620, 42), 18, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_RIGHT, "StoryCombatPausedLabel", UIFontScript.ROLE_EMPHASIS)
	var portrait_rect := Rect2(72, 612, 292, 396)
	var portrait_panel = root._onboarding_add_portrait(parent, portrait_rect, speaker_id, speaker_name, str(cue.get("portrait_emotion", "")), false)
	portrait_panel.name = "StoryDialoguePortraitPanel"
	var box_rect := Rect2(392, 660, 1454, 326)
	var dialogue_panel = root._onboarding_child_panel(parent, box_rect, Color("#100d14f7"), Color("#9b6a27"))
	dialogue_panel.name = "StoryDialogueTextPanel"
	hud.label(parent, speaker_name, Vector2(432, 696), Vector2(760, 46), 29, Color("#ffd36a"), HORIZONTAL_ALIGNMENT_LEFT, "StorySpeakerLabel", UIFontScript.ROLE_EMPHASIS)
	var text := str(cue.get("text_ko", "")).replace("{{player_name}}", root._onboarding_player_name())
	var text_rect := Rect2(432, 756, 1000, 180) if touch_ui else Rect2(432, 756, 1180, 134)
	var dialogue_label = hud.rich_label(parent, text, text_rect.position, text_rect.size, 24, Color("#f7efe1"), UIFontScript.ROLE_DIALOGUE, TextServer.AUTOWRAP_WORD_SMART, VERTICAL_ALIGNMENT_CENTER, "StoryDialogueText", 16)
	dialogue_label.add_theme_constant_override("line_separation", 4)
	var next_rect := Rect2(1460, 820, 328, 144) if touch_ui else Rect2(1542, 908, 246, 56)
	hud.label(
		parent,
		"%d / %d" % [root.story_director.cursor + 1, root.story_director.cue_count()],
		Vector2(1300, 934) if touch_ui else Vector2(1402, 920),
		Vector2(136, 28) if touch_ui else Vector2(116, 28),
		20 if touch_ui else 16,
		Color("#bfb7cc"),
		HORIZONTAL_ALIGNMENT_RIGHT,
		"StoryCueProgress"
	)
	hud.button(parent, "다음", next_rect, Callable(root, "_story_advance_dialogue").bind(true), 30 if touch_ui else 21, "StoryNextButton")
	var auto_label := "Auto 끄기" if root.story_director.auto_enabled else "Auto"
	hud.button(parent, auto_label, Rect2(1080, 820, 300, 144) if touch_ui else Rect2(1284, 908, 200, 56), Callable(root, "_story_toggle_auto"), 22 if touch_ui else 16, "StoryAutoButton")
	if root.story_director.skip_allowed():
		hud.button(parent, "읽은 장면 스킵", Rect2(730, 820, 320, 144) if touch_ui else Rect2(1060, 908, 200, 56), Callable(root, "_story_skip_dialogue"), 22 if touch_ui else 15, "StorySkipButton")
