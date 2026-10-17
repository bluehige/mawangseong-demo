extends CanvasLayer
const FontKit = preload("res://scripts/ui/UIFont.gd")
var service: Node
var selected_set := "base_campaign"
var page: Control
var list: VBoxContainer
var tabs: Array[Button] = []
var totals: Label

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

func setup(owner_service: Node) -> void:
	service = owner_service; layer = 120
	page = Control.new(); page.name = "AchievementPage"; add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var background := ColorRect.new(); page.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.color = Color("10111bf8")
	var bounds := MarginContainer.new(); page.add_child(bounds)
	bounds.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: bounds.add_theme_constant_override("margin_"+side,60)
	var body := VBoxContainer.new(); body.add_theme_constant_override("separation",22); bounds.add_child(body)
	var top := HBoxContainer.new(); body.add_child(top)
	var heading := label(top,text("도전과제","Achievements","成就"),44,Color("e8c77b")); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new(); top.add_child(close); close.text = text("돌아가기  ·  ESC","Back  ·  ESC","返回  ·  ESC")
	close.custom_minimum_size = Vector2(260,60); close.add_theme_font_size_override("font_size",25); close.pressed.connect(queue_free)
	var languages := HBoxContainer.new(); body.add_child(languages)
	for locale in LanguageSettings.SUPPORTED_LOCALES:
		var button := Button.new(); languages.add_child(button); button.text = LanguageSettings.display_name(locale)
		button.custom_minimum_size = Vector2(180,48); button.add_theme_font_size_override("font_size",23)
		button.pressed.connect(func(): LanguageSettings.set_locale(locale); queue_free(); service.open_screen())
	totals = label(body,"",23,Color("aab0c2"))
	var columns := HBoxContainer.new(); body.add_child(columns); columns.size_flags_vertical = Control.SIZE_EXPAND_FILL; columns.add_theme_constant_override("separation",36)
	var sets := VBoxContainer.new(); columns.add_child(sets); sets.custom_minimum_size.x = 330; sets.add_theme_constant_override("separation",12)
	for definition in service.catalog.sets:
		var button := Button.new(); sets.add_child(button); tabs.append(button)
		button.custom_minimum_size = Vector2(330,70); button.add_theme_font_size_override("font_size",23)
		button.add_theme_font_override("font",FontKit.font_for_role("button")); button.text = definition["name_"+locale_key()]
		button.toggle_mode = true; button.set_meta("set_id",definition.id)
		button.pressed.connect(select.bind(str(definition.id)))
	var scroll := ScrollContainer.new(); columns.add_child(scroll); scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list = VBoxContainer.new(); scroll.add_child(list); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",12)
	service.progress_changed.connect(refresh)
	select(selected_set)
	close.grab_focus()

func select(id: String) -> void:
	selected_set = id; refresh()

func refresh() -> void:
	if not is_instance_valid(list): return
	for child in list.get_children(): child.free()
	for button in tabs: button.set_pressed_no_signal(button.get_meta("set_id") == selected_set)
	totals.text = text("전체 진행","Overall progress","总进度")+"   %d / 100" % service.profile.unlocked.size()
	for row in service.catalog.achievements:
		if row.set != selected_set: continue
		var achieved: bool = service.profile.unlocked.has(row.api_name)
		var secret: bool = bool(row.hidden) and not achieved
		var panel := PanelContainer.new(); list.add_child(panel)
		var style := StyleBoxFlat.new(); style.bg_color = Color("262331") if achieved else Color("1b1c29")
		style.border_color = Color("ab8c52") if achieved else Color("3b3b50"); style.set_border_width_all(1)
		style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 14; style.content_margin_bottom = 14
		panel.add_theme_stylebox_override("panel",style)
		var line := HBoxContainer.new(); panel.add_child(line); line.add_theme_constant_override("separation",20)
		var icon := TextureRect.new(); line.add_child(icon); icon.custom_minimum_size = Vector2(86,86)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load("res://assets/ui/kit/icons/icon_lock_128.png") if secret else load(row.icon_path)
		if not achieved and not secret:
			var shader := Shader.new(); shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV);float g=dot(c.rgb,vec3(.299,.587,.114));COLOR=vec4(vec3(g)*.45,c.a);}"
			var material := ShaderMaterial.new(); material.shader = shader; icon.material = material
		var copy := VBoxContainer.new(); line.add_child(copy); copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label(copy,text("숨겨진 도전과제","Hidden achievement","隐藏成就") if secret else row["name_"+locale_key()],26,Color("e9ca86") if achieved else Color("ddd9e8"))
		var desc := label(copy,text("조건을 달성하면 공개됩니다.","Revealed when earned.","达成后揭晓。") if secret else row["desc_"+locale_key()],21,Color("a7a7bb"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if row.progress_stat != null and not secret:
			var value := mini(int(row.progress_max),int(service.profile.stats.get(row.progress_stat,0)))
			var progress := ProgressBar.new(); copy.add_child(progress); progress.custom_minimum_size.y = 14
			progress.max_value = row.progress_max; progress.value = value; progress.show_percentage = false
			label(copy,"%d / %d" % [value,int(row.progress_max)],18,Color("bfa4e2"))
		else:
			label(copy,text("달성","Unlocked","已达成") if achieved else text("잠김","Locked","未解锁"),18,Color("a9ccab") if achieved else Color("85859a"))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled(); queue_free()
