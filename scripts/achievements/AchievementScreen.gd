extends CanvasLayer
const FontKit = preload("res://scripts/ui/UIFont.gd")
const Obsidian = preload("res://scripts/ui/ObsidianStyleBox.gd")
const PANEL = preload("res://assets/ui/uiux/obsidian_panel.png")
const BUTTON = preload("res://assets/ui/uiux/obsidian_button.png")
const LOCK = preload("res://assets/ui/kit/icons/icon_lock_128.png")
const QUESTION_PATH := "res://assets/ui/v130r/achievements/question.png"
var service: Node
var selected_set := "base_campaign"
var page: Control
var list: VBoxContainer
var tabs: Array[Button] = []
var totals: Label
var locked_material: ShaderMaterial

func locale_key() -> String:
	return "zh_cn" if LanguageSettings.locale == "zh_CN" else LanguageSettings.locale

func text(ko: String, en: String, zh: String) -> String:
	return {"ko":ko,"en":en,"zh_cn":zh}.get(locale_key(),ko)

func label(parent: Node, value: String, size_px: int, color := Color("f3e8d3")) -> Label:
	var node := Label.new(); node.text = value
	node.add_theme_font_override("font",FontKit.font_for_role("body"))
	node.add_theme_font_size_override("font_size",size_px)
	node.add_theme_color_override("font_color",color); parent.add_child(node)
	return node

func panel_style(tint := Color.WHITE, inset := 22.0) -> StyleBox:
	var style := Obsidian.new(); style.texture = PANEL; style.tint = tint
	style.set_content_margin_all(inset)
	return style

func button(parent: Node, value: String, minimum: Vector2, font_size: int) -> Button:
	var node := Button.new(); parent.add_child(node); node.text = value
	node.custom_minimum_size = minimum
	node.add_theme_font_override("font",FontKit.font_for_role("button"))
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",Color("e9ddc7"))
	node.add_theme_color_override("font_pressed_color",Color("ffe3a0"))
	for state in ["normal","hover","pressed","hover_pressed","focus"]:
		var style := Obsidian.new(); style.texture = BUTTON; style.panel_texture = PANEL
		style.button_shape = true; style.set_content_margin_all(18)
		style.content_margin_top = 8; style.content_margin_bottom = 8
		style.tint = Color(1.35,1.18,.85) if state in ["pressed","hover_pressed"] else Color(1.15,1.1,.95) if state in ["hover","focus"] else Color(.82,.82,.85)
		node.add_theme_stylebox_override(state,style)
	return node

func setup(owner_service: Node) -> void:
	service = owner_service; layer = 120
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); float g=dot(c.rgb,vec3(.299,.587,.114)); COLOR=vec4(vec3(g)*.35,c.a);}"
	locked_material = ShaderMaterial.new(); locked_material.shader = shader
	page = Control.new(); page.name = "AchievementPage"; add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var background := Panel.new(); page.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override("panel",panel_style())
	var bounds := MarginContainer.new(); page.add_child(bounds)
	bounds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: bounds.add_theme_constant_override("margin_"+side,48)
	var body := VBoxContainer.new(); body.add_theme_constant_override("separation",14); bounds.add_child(body)
	var top := HBoxContainer.new(); body.add_child(top)
	var heading := label(top,text("도전과제","Achievements","成就"),44,Color("e8c77b")); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := button(top,text("돌아가기  ·  ESC","Back  ·  ESC","返回  ·  ESC"),Vector2(280,68),25)
	close.name = "AchievementBack"; close.pressed.connect(queue_free)
	var languages := HBoxContainer.new(); body.add_child(languages); languages.add_theme_constant_override("separation",12)
	for locale in LanguageSettings.SUPPORTED_LOCALES:
		var language := button(languages,LanguageSettings.display_name(locale),Vector2(188,54),22)
		language.toggle_mode = true; language.set_pressed_no_signal(LanguageSettings.locale == locale)
		language.pressed.connect(change_language.bind(locale))
	totals = label(body,"",22,Color("c7b990"))
	var columns := HBoxContainer.new(); body.add_child(columns); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",24)
	var sets := VBoxContainer.new(); columns.add_child(sets); sets.custom_minimum_size.x = 360; sets.add_theme_constant_override("separation",10)
	for definition in service.catalog.sets:
		var tab := button(sets,"",Vector2(360,80),22); tabs.append(tab)
		tab.toggle_mode = true; tab.set_meta("set_id",definition.id)
		tab.pressed.connect(select.bind(str(definition.id)))
	var scroll := ScrollContainer.new(); columns.add_child(scroll); scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list = VBoxContainer.new(); scroll.add_child(list); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",12)
	service.progress_changed.connect(refresh)
	select(selected_set)
	close.grab_focus()

func change_language(locale: String) -> void:
	# Keep the selected collection when changing language; do not touch profile data.
	LanguageSettings.set_locale(locale)
	queue_free()
	var screen := get_script().new() as CanvasLayer
	service.add_child(screen); screen.selected_set = selected_set; screen.setup(service)

func select(id: String) -> void:
	selected_set = id; refresh()

func texture(parent: Node, art: Texture2D, minimum: Vector2) -> TextureRect:
	var node := TextureRect.new(); parent.add_child(node); node.texture = art
	node.custom_minimum_size = minimum; node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return node

func progress_bar(parent: Node, value: int, maximum: int) -> void:
	var line := HBoxContainer.new(); parent.add_child(line); line.add_theme_constant_override("separation",18)
	var bar := TextureProgressBar.new(); line.add_child(bar)
	bar.name = "AchievementProgress"; bar.custom_minimum_size = Vector2(480,28)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.texture_under = preload("res://assets/ui/v130r/hpbar/C/frame_ally.png")
	bar.texture_progress = preload("res://assets/ui/v130r/hpbar/C/fill_ally.png")
	bar.texture_over = bar.texture_under; bar.texture_progress_offset = Vector2(0,2)
	bar.nine_patch_stretch = true; bar.stretch_margin_left = 24; bar.stretch_margin_right = 24
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bar.max_value = maximum; bar.value = value
	label(line,"%d / %d" % [value,maximum],19,Color("d5c090"))

func refresh() -> void:
	if not is_instance_valid(list): return
	for child in list.get_children(): child.free()
	for index in tabs.size():
		var tab := tabs[index]; var definition: Dictionary = service.catalog.sets[index]
		var earned := 0; var count := 0
		for row in service.catalog.achievements:
			if row.set == definition.id:
				count += 1
				if service.profile.unlocked.has(row.api_name): earned += 1
		tab.text = "%s\n%d / %d" % [definition["name_"+locale_key()],earned,count]
		tab.set_pressed_no_signal(tab.get_meta("set_id") == selected_set)
	totals.text = text("전체 진행","Overall progress","总进度")+"   %d / %d" % [service.profile.unlocked.size(),service.catalog.achievements.size()]
	for row in service.catalog.achievements:
		if row.set != selected_set: continue
		var achieved: bool = service.profile.unlocked.has(row.api_name)
		var secret: bool = bool(row.hidden) and not achieved
		var panel := PanelContainer.new(); list.add_child(panel); panel.name = str(row.api_name)
		panel.custom_minimum_size.y = 142
		panel.add_theme_stylebox_override("panel",panel_style(Color(1.1,1.02,.9) if achieved else Color(.8,.8,.84),18))
		var line := HBoxContainer.new(); panel.add_child(line); line.add_theme_constant_override("separation",22)
		var icon_box := Control.new(); line.add_child(icon_box); icon_box.custom_minimum_size = Vector2(102,102)
		icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icon := texture(icon_box,load(QUESTION_PATH) if secret else load(row.icon_path),Vector2(96,96))
		icon.name = "AchievementIcon"; icon.position = Vector2(0,0); icon.size = Vector2(96,96)
		if not achieved and not secret:
			icon.material = locked_material
			var badge := texture(icon_box,LOCK,Vector2(36,36)); badge.name = "LockBadge"
			badge.position = Vector2(68,68); badge.size = Vector2(36,36)
		var copy := VBoxContainer.new(); line.add_child(copy); copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation",5)
		var title := label(copy,"???" if secret else row["name_"+locale_key()],26,Color("e9ca86") if achieved else Color("ddd5c7"))
		title.name = "AchievementName"; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var desc := label(copy,text("조건을 달성하면 공개됩니다.","Revealed when earned.","达成后揭晓。") if secret else row["desc_"+locale_key()],21,Color("b6b0a6"))
		desc.name = "AchievementDescription"; desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if row.progress_stat != null and not secret:
			var value := int(row.progress_max) if achieved else mini(int(row.progress_max),int(service.profile.stats.get(row.progress_stat,0)))
			progress_bar(copy,value,int(row.progress_max))
		if achieved:
			var date := Time.get_date_string_from_unix_time(int(service.profile.unlocked[row.api_name]))
			label(copy,text("해제일","Unlocked","解锁日期")+"  "+date,18,Color("c9c7a0")).name = "UnlockDate"
		elif row.progress_stat == null or secret:
			label(copy,text("잠김","Locked","未解锁"),18,Color("a09787"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled(); queue_free()
