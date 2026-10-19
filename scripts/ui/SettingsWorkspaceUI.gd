extends "res://scripts/ui/MonsterWorkspaceUI.gd"

func build_settings() -> void:
	_background()
	root.ui_layer.get_node("MonsterCastleBackground").name = "SettingsCastleBackground"
	var shell := kit_panel(Rect2(144,44,1632,1000),"SettingsWorkspace")
	_glass(shell,0.82)
	var heading := kit_copy(shell,LanguageSettings.text("settings.title"),Rect2(240,14,1152,76),52,GOLD,"SettingsHeading")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kit_copy(shell,"v"+str(ProjectSettings.get_setting("application/config/version","")),Rect2(1400,18,200,44),24,MUTED,"SettingsInstalledVersionLabel")
	var navigation := Control.new()
	navigation.position = Vector2(28,110); navigation.size = Vector2(1576,84)
	shell.add_child(navigation)
	root._build_settings_navigation(navigation)
	var pane := kit_panel(Rect2(172,254,930,650),"SettingsFieldsPanel")
	_glass(pane,0.74)
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsFieldsScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pane.add_child(scroll)
	var content := Control.new()
	content.name = "SettingsFields"
	content.custom_minimum_size = Vector2(930,1010 if root.settings_category=="combat" else (820 if root.settings_category in ["general","accessibility"] else 710))
	scroll.add_child(content)
	match root.settings_category:
		"audio": root._build_settings_audio_category(content)
		"display": root._build_settings_display_category(content)
		"combat": root._build_settings_combat_category(content)
		"accessibility": root._build_settings_accessibility_category(content)
		_: root._build_settings_general_category(content)
	_style_fields(content)
	_fit_field_cards(content)
	_fit_field_cards.call_deferred(content)
	var preview := kit_panel(Rect2(1126,254,622,650),"SettingsPreviewPanel")
	_glass(preview,0.72)
	root._build_settings_preview(preview)
	var mascot := _art(preview,"imp",Vector2(180,180))
	mascot.position = Vector2(414,430)
	kit_button(shell,LanguageSettings.text("settings.action.reset_category"),Rect2(28,922,310,64),Callable(root,"_reset_settings_category"),"ResetSettingsCategoryButton","utility","reset")
	kit_button(shell,loc("게임 메뉴","Game menu","游戏菜单"),Rect2(354,922,256,64),Callable(root.continuity,"settings_menu"),"SettingsGameMenuButton","utility","menu")
	kit_button(shell,LanguageSettings.text("settings.action.cancel"),Rect2(1030,922,270,64),Callable(root,"_cancel_settings_changes"),"CancelSettingsButton","utility","close")
	kit_button(shell,LanguageSettings.text("settings.action.apply"),Rect2(1322,922,282,64),Callable(root,"_apply_settings_changes"),"ApplySettingsButton","primary","check")
	if root.settings_write_failed:
		kit_copy(shell,loc("설정 저장 실패 · 다시 적용하거나 취소하세요.","Save failed · retry Apply or Cancel.","设置保存失败，请重试应用或取消。"),Rect2(28,858,1576,52),24,Color("#ffaaa4"),"SettingsWriteFailure")

func category(parent: Control, title: String, id: String, index: int, icon: String) -> void:
	var active: bool = root.settings_category == id
	var button := kit_button(parent,title,Rect2(index*318,0,304,78),Callable(root,"_select_settings_category").bind(id),"SettingsCategory_"+id,"primary" if active else "utility",icon)
	button.set_meta("kit_button_height",ManagementKit.Tokens.TAB_HEIGHT)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",32)
	button.add_theme_font_size_override("font_size",24)
	button._sync_surface()
	button.size = Vector2(304,78)
	button.set_meta("kit_selected",active)
	button.surface.sync(button)

func field_card(parent: Control, y: float, height: float, icon_id: String = "") -> void:
	var pane := Panel.new()
	pane.position = Vector2(22,y-18); pane.size = Vector2(886,height)
	pane.set_meta("settings_field_card",true)
	pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075,0.045,0.115,0.80)
	style.border_color = Color(0.47,0.35,0.55,0.8)
	style.set_border_width_all(1); style.set_corner_radius_all(18)
	pane.add_theme_stylebox_override("panel",style)
	parent.add_child(pane); parent.move_child(pane,0)
	if icon_id != "":
		var icon := ManagementKit.image(icon_id,32)
		icon.name = "SettingsRowIcon_"+str(int(y))
		icon.position = Vector2(38,y)
		icon.size = Vector2(32,32)
		parent.add_child(icon)
		for child in parent.get_children():
			if child is Label and absf(child.position.y-y)<10 and child.position.x<90:
				child.position.x = 84
				child.size.x -= 44
			elif child is CheckBox and absf(child.position.y-y)<10:
				child.position.x = 84
				child.size.x -= 44

func _fit_field_cards(parent: Control) -> void:
	if not is_instance_valid(parent): return
	# Labels can grow after translation. Include their full allocated height
	# and controls in the card, keeping padding above the next row.
	var cards: Array = []
	for child in parent.get_children():
		if child is Panel and child.has_meta("settings_field_card"): cards.append(child)
	cards.sort_custom(func(a,b): return a.position.y<b.position.y)
	for pane in cards:
		var next_top := INF
		for other in parent.get_children():
			if other is Panel and other.has_meta("settings_field_card") and other.position.y>pane.position.y:
				next_top = minf(next_top,other.position.y)
		var bottom: float = pane.position.y+pane.size.y
		for child in parent.get_children():
			if child is Control and not child is Panel and child.position.y>=pane.position.y and child.position.y<next_top:
				bottom = maxf(bottom,child.position.y+maxf(child.size.y,child.get_combined_minimum_size().y)+12)
		pane.size.y = bottom-pane.position.y
		if next_top<INF and bottom+14>next_top:
			var shift := bottom+14-next_top
			for child in parent.get_children():
				if child is Control and child!=pane and child.position.y>=next_top:
					child.position.y += shift
		parent.custom_minimum_size.y = maxf(parent.custom_minimum_size.y,bottom+18)

func _style_fields(node: Node) -> void:
	if node is BaseButton or node is Range:
		node.theme = kit_theme()
		for key in ["normal","hover","pressed","hover_pressed","disabled","focus","slider","grabber_area","grabber_area_highlight"]:
			node.remove_theme_stylebox_override(key)
		for key in ["arrow","grabber","grabber_highlight","grabber_disabled"]: node.remove_theme_icon_override(key)
		node.set_meta("uiux_external_button",true)
		if node is OptionButton:
			node.get_popup().theme = kit_theme()
		elif node is HSlider:
			for key in ["slider","grabber_area","grabber_area_highlight"]:
				var bar := kit_theme().get_stylebox(key,"HSlider").duplicate() as StyleBox
				bar.content_margin_top = 6; bar.content_margin_bottom = 6
				node.add_theme_stylebox_override(key,bar)
		elif node is Button and not node is CheckBox:
			node.theme_type_variation = "KitPrimary" if node.get_meta("ui_button_grade","")=="primary" else "Button"
	for child in node.get_children(): _style_fields(child)
