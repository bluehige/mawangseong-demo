extends "res://scripts/ui/ManagementWorkspaceUI.gd"

const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const BACKGROUND_CATALOG := "res://data/ui/title_backgrounds.json"

func build_title() -> void:
	root._refresh_campaign_save_status()
	var screen := panel(Rect2(0, 0, 1920, 1080), "TitleWorkspace")
	screen.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var backgrounds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BACKGROUND_CATALOG))
	var background_id := choose_background_id(root.campaign_profile, root.update3_profile, backgrounds)
	screen.set_meta("background_id", background_id)
	var art: TextureRect = hud.texture(screen, str(backgrounds.images.get(background_id, backgrounds.images.default)), Rect2(0, 0, 1920, 1080))
	art.name = "TitleBackgroundIllustration"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var roomy := UISettings.is_touch_ui() or UISettings.text_scale > 1.1
	var logo: TextureRect = hud.texture(screen, "res://assets/ui/v1213/logo_%s.png" % LanguageSettings.locale, Rect2(510, 120 if root.start_flow.menu_open else (160 if roomy else 250), 900, 235))
	logo.name = "TitleLogo"
	if LanguageSettings.locale == "en":
		# Measured wordmark bounds plus 12px. Keep the original alpha pixels;
		# its alpha=1 fringe otherwise makes the visible English title too small.
		var cropped := AtlasTexture.new()
		cropped.atlas = logo.texture
		cropped.region = Rect2(100, 93, 997, 267)
		logo.texture = cropped
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	screen.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.anchor_top = 0.43 if root.start_flow.menu_open else 0.58
	center.anchor_bottom = 0.90
	center.grow_vertical = Control.GROW_DIRECTION_BEGIN
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu := VBoxContainer.new()
	menu.name = "TitleMenu"
	menu.custom_minimum_size.x = 520
	menu.add_theme_constant_override("separation", 12)
	center.add_child(menu)
	var valid: bool = root.campaign_save_status==root.CampaignSaveStoreScript.STATUS_VALID and root.campaign_save_notice==""
	var primary: Button
	if not root.start_flow.menu_open:
		primary = _menu_button(menu,root.start_flow.text("start"),Callable(root.start_flow,"open_menu"),"TitleStartButton","",true)
	else:
		primary = _menu_button(menu,root.start_flow.text("new"),Callable(root,"_onboarding_start_new_game"),"CampaignNewGameButton","",true)
		var continuing := _menu_button(menu,root.start_flow.text("continue"),Callable(root,"_continue_campaign_save"),"CampaignContinueButton")
		continuing.disabled = not valid
		if valid:
			var summary: Dictionary = root.campaign_save_summary
			var grade: String = str(summary.get("map_grade",["F","E","D","C"][clampi(int(summary.get("castle_stage_index",1))-1,0,3)]))
			var duration: String = root.start_flow.text("old_time")
			if summary.has("play_seconds"):
				var seconds := int(summary.play_seconds)
				duration = root.start_flow.text("time")+" %02d:%02d" % [seconds/3600,(seconds%3600)/60]
			var info := Label.new(); info.name = "ContinueSaveSummary"
			info.text = "DAY %02d · %s · %s" % [int(summary.get("day",1)),grade,duration]
			info.add_theme_font_override("font",UIFont.font_for_role(UIFont.ROLE_BODY)); info.add_theme_font_size_override("font_size",20)
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; menu.add_child(info)
		_menu_button(menu,root.start_flow.text("settings"),Callable(root,"_open_settings_screen"),"TitleSettingsButton")
		_menu_button(menu,root.start_flow.text("achievements"),Callable(AchievementService,"open_screen"),"TitleAchievementsButton")
		_menu_button(menu,root.start_flow.text("quit"),Callable(root,"_onboarding_quit_requested"),"TitleQuitButton")
	var language_margin := MarginContainer.new()
	language_margin.name = "TitleLanguages"
	screen.add_child(language_margin)
	language_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	language_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	language_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for side in ["left", "right", "top", "bottom"]: language_margin.add_theme_constant_override("margin_" + side, 24)
	var languages := HBoxContainer.new()
	languages.add_theme_constant_override("separation", 6)
	language_margin.add_child(languages)
	var globe := Kit.image("language", 56)
	globe.name = "TitleLanguageGlobe"
	globe.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	languages.add_child(globe)
	for locale in LanguageSettings.SUPPORTED_LOCALES:
		var language_button = _menu_button(languages, LanguageSettings.display_name(locale), Callable(LanguageSettings, "set_locale").bind(locale), "TitleLanguage_" + locale)
		language_button.toggle_mode = true
		language_button.set_pressed_no_signal(LanguageSettings.locale == locale)
		language_button.custom_minimum_size.x = 146
		language_button.tooltip_text = root.continuity.localized("언어 · 즉시 적용하고 저장합니다.", "Language · apply and save immediately.", "语言 · 立即应用并保存。")
	Kit.apply_scale(menu, UISettings.text_scale, UISettings.is_touch_ui())
	for child in menu.get_children():
		if child is Button: child.add_theme_font_size_override("font_size",32)

	Kit.apply_scale(language_margin, UISettings.text_scale, UISettings.is_touch_ui())
	for child in languages.get_children():
		if child is Button:
			child.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			child.custom_minimum_size.x = 170 * Kit.Tokens.geometry_scale(UISettings.text_scale, UISettings.is_touch_ui())
	if root.pending_title_reset_mode == "": _focus_title_if_visible.call_deferred(primary)
	else:
		_disable_menu_input(screen)
		root._build_title_reset_confirmation()

func _menu_button(parent: Control, caption: String, callback: Callable, id: String, icon: String = "", primary: bool = false) -> Button:
	var result: Button = root.start_flow.button(parent,caption,Rect2(0,0,520 if parent is VBoxContainer else 170,76),callback if callback.is_valid() else func(): pass,id)
	result.set_meta("title_icon",icon)
	if primary: result.add_theme_color_override("font_color",GOLD)
	return result

static func choose_background_id(profile: Dictionary, update3: Dictionary, catalog: Dictionary) -> String:
	# Only reached endings may select a data hook. Locked ending information is never rendered.
	var unlocked: Array = profile.get("ending_catalog_codes", {}).values()
	unlocked.append_array(update3.get("update3_endings_seen", []))
	for entry in catalog.get("ending_backgrounds", []):
		if entry.get("ending_id", "") in unlocked:
			return str(entry.get("background_id", "default"))
	return "default"

func _disable_menu_input(node: Node) -> void:
	if node is BaseButton:
		node.disabled = true
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children(): _disable_menu_input(child)

static func _focus_title_if_visible(button: BaseButton) -> void:
	if is_instance_valid(button) and button.is_inside_tree() and not button.is_queued_for_deletion() and button.is_visible_in_tree():
		button.grab_focus()
