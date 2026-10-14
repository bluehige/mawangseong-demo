extends "res://scripts/ui/ManagementWorkspaceUI.gd"

const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const KitButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
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
	var logo: TextureRect = hud.texture(screen, "res://assets/ui/v1213/logo_%s.png" % LanguageSettings.locale, Rect2(510, 160 if roomy else 250, 900, 235))
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
	center.anchor_top = 0.48
	center.anchor_bottom = 0.86
	center.grow_vertical = Control.GROW_DIRECTION_BEGIN
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu := VBoxContainer.new()
	menu.name = "TitleMenu"
	menu.custom_minimum_size.x = 430
	menu.add_theme_constant_override("separation", 12)
	center.add_child(menu)
	var valid: bool = root.campaign_save_status == root.CampaignSaveStoreScript.STATUS_VALID and root.campaign_save_notice == ""
	var label: String = "새 회차" if root._title_campaign_mode_available() else "새 게임"
	var callback := Callable(root, "_open_campaign_mode_from_title") if root._title_campaign_mode_available() else Callable(root, "_onboarding_start_new_game")
	var primary := _menu_button(menu, LanguageSettings.ui_text(label), callback, "CampaignNewGameButton", "throne", true)
	primary.set_meta("title_workspace_owner", self) # Keep the deferred focus callback alive for this screen.
	var continue_button := _menu_button(menu, root.continuity.localized("이어하기", "Continue", "继续游戏"), Callable(root, "_continue_campaign_save"), "CampaignContinueButton", "load")
	continue_button.disabled = not valid
	continue_button.tooltip_text = LanguageSettings.ui_text(root._campaign_title_save_status_text())
	_menu_button(menu, LanguageSettings.ui_text("설정"), Callable(root, "_open_settings_screen"), "TitleSettingsButton", "settings")
	_menu_button(menu, root.continuity.localized("도감", "Codex", "图鉴"), Callable(root, "_open_ending_archive"), "EndingArchiveButton", "encyclopedia")
	if not UISettings.is_touch_ui():
		_menu_button(menu, LanguageSettings.ui_text("종료"), Callable(root, "_onboarding_quit_requested"), "TitleQuitButton", "quit")
	var language_margin := MarginContainer.new()
	language_margin.name = "TitleLanguages"
	screen.add_child(language_margin)
	language_margin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	language_margin.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	language_margin.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for side in ["left", "right", "top", "bottom"]: language_margin.add_theme_constant_override("margin_" + side, 24)
	var languages := HBoxContainer.new()
	languages.add_theme_constant_override("separation", 12)
	language_margin.add_child(languages)
	languages.add_child(Kit.image("language", 48))
	for locale in LanguageSettings.SUPPORTED_LOCALES:
		var language_button := _menu_button(languages, LanguageSettings.display_name(locale), Callable(LanguageSettings, "set_locale").bind(locale), "TitleLanguage_" + locale)
		language_button.pressed.connect(Callable(root, "_set_screen").bind(Constants.SCREEN_TITLE, false))
		language_button.toggle_mode = true
		language_button.set_pressed_no_signal(LanguageSettings.locale == locale)
		language_button.custom_minimum_size.x = 146
		language_button.tooltip_text = root.continuity.localized("언어 · 즉시 적용하고 저장합니다.", "Language · apply and save immediately.", "语言 · 立即应用并保存。")
	Kit.apply_scale(menu, UISettings.text_scale, UISettings.is_touch_ui())
	Kit.apply_scale(language_margin, UISettings.text_scale, UISettings.is_touch_ui())
	for child in languages.get_children():
		if child is Button:
			child.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			child.custom_minimum_size.x = 170 * Kit.Tokens.geometry_scale(UISettings.text_scale, UISettings.is_touch_ui())
	var notice: String = root._campaign_title_save_status_text()
	if valid:
		notice = "DAY %02d · %s" % [int(root.campaign_save_summary.get("day", 1)), str(root.campaign_save_summary.get("player_name", ""))]
	elif root.campaign_save_notice != "" or root.campaign_save_status in [root.CampaignSaveStoreScript.STATUS_CORRUPT, root.CampaignSaveStoreScript.STATUS_UNSUPPORTED]:
		notice = root.continuity.localized("이어하기 불가 · 저장 파일을 확인하세요.", "Cannot continue · check the saved game.", "无法继续 · 请检查存档。")
	var status := copy(screen, LanguageSettings.ui_text(notice), Rect2(560, 408 if roomy else 930, 800, 48), 24, MUTED, "TitleSaveStatus")
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy(screen, "v" + str(ProjectSettings.get_setting("application/config/version", "")), Rect2(32, 1016, 150, 34), 24, MUTED, "InstalledVersionLabel")
	var notes := _menu_button(screen, root.continuity.localized("업데이트 내역", "Update notes", "更新记录"), Callable(root.continuity, "show_update"), "TitleUpdateNotesButton", "info")
	notes.position = Vector2(32, 932)
	Kit.apply_scale(notes, UISettings.text_scale, UISettings.is_touch_ui())
	if root._qa_title_actions_enabled():
		var quick := _menu_button(screen, "QA", Callable(root, "_onboarding_start_quick_game"), "CampaignQuickStartButton")
		quick.position = Vector2(32, 32)
	if root.pending_title_reset_mode == "": call_deferred("focus_if_visible", primary)
	else:
		_disable_menu_input(screen)
		root._build_title_reset_confirmation()

func _menu_button(parent: Control, caption: String, callback: Callable, id: String, icon: String = "", primary: bool = false) -> Button:
	var result := KitButtonScript.new().configure(caption, KitButtonScript.VariantStyle.PRIMARY if primary else KitButtonScript.VariantStyle.BASIC, icon, caption)
	result.name = id
	result.add_theme_constant_override("icon_max_width", 40)
	parent.add_child(result)
	result.pressed.connect(callback)
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
