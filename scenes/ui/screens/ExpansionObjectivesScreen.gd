extends Control
signal closed
signal move_requested(room_id: String)
var state: Dictionary = {}
var modules: Dictionary = {}
func setup(value: Dictionary, catalog: Dictionary) -> void:
	state = value.duplicate(true); modules = catalog
	add_theme_font_override("font",preload("res://assets/fonts/NotoSansCJKkr-Regular.otf"))
	_build()
func l(ko: String, en: String, zh: String) -> String:
	return zh if LanguageSettings.locale == "zh_CN" else en if LanguageSettings.locale == "en" else ko
func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_font_size_override("font_size",24)
	var bg := ColorRect.new(); bg.color = Color("#16121a"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var column := VBoxContainer.new(); column.position = Vector2(180,100); column.size = Vector2(1100,650); column.add_theme_constant_override("separation",24); add_child(column)
	var title := Label.new(); title.text = l("확장 구역 목표", "Expansion objectives", "扩展区域目标"); title.add_theme_font_size_override("font_size",34); column.add_child(title)
	var help := Label.new(); help.text = l("성 등급이 오르면 부지가 넓어집니다. 왕관실과 금고는 같은 1층의 자동 길로 연결됩니다.","Castle grades expand the plot. The Crown Chamber and vault share automatic first-floor paths.","城堡升级会扩展地块。王冠室与金库通过同一层的自动道路连接。"); help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(help)
	var status := Label.new(); status.name="ObjectivePlacementStatus"; status.text = l("기존 부지 임시 배치 · 등급 확장 후 새 구역으로 이전", "Temporary placement · relocates after grade expansion", "现有地块临时部署 · 等级扩建后迁入新区域") if bool(state.get("temporary",true)) else l("확장 구역 배치 · 자유 이동·회전 가능", "Expansion placement · move and rotate freely", "扩展区域部署 · 可自由移动、旋转"); column.add_child(status)
	for id in ["crown_sanctum","seal_vault"]:
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation",30); column.add_child(row)
		var art := TextureRect.new(); art.custom_minimum_size = Vector2(160,160); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.name="ObjectiveArt_"+id; art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var path := str(modules.get(id,{}).get("art_states",{}).get("empty" if id == "crown_sanctum" else "normal", ""))
		if ResourceLoader.exists(path): art.texture = load(path)
		row.add_child(art)
		var label := Label.new(); label.custom_minimum_size.x = 580
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		label.text = l("왕관실", "Crown Chamber", "王冠室") + " · HP %d" % int(state.get("objective_hp",{}).get(id,0)) if id == "crown_sanctum" else l("인장 금고 · 경고 3초 / 수거 4초 / 손실 최대 1회", "Seal Vault · 3s warning / 4s channel / one loss per battle", "印章金库 · 警告3秒 / 收取4秒 / 每战最多损失一次")
		row.add_child(label)
		var move := Button.new(); move.name="ObjectiveMove_"+id; move.text = l("배치 이동", "Move placement", "移动部署"); move.tooltip_text=l("관리 화면에서 목표 방을 이동·회전합니다.","Move or rotate the objective room in management.","在管理画面移动、旋转目标房间。"); move.custom_minimum_size = Vector2(180,64); move.disabled = str(state.get("rooms",{}).get(id,"")) != id; move.pressed.connect(func(): move_requested.emit(id)); row.add_child(move)
	var back := Button.new(); back.text = l("관리로 돌아가기", "Return to management", "返回管理"); back.custom_minimum_size.y = 64; back.pressed.connect(func(): closed.emit()); column.add_child(back)
