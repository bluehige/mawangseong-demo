extends "res://tools/ux_audit/Audit.gd"
## Isolated actual renderer; reuse Audit.collect and scan.py geometry rules.
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const PanelScript = preload("res://scripts/ui/kit/KitPanel.gd")
const ButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
const IconButton = preload("res://scripts/ui/kit/KitIconButton.gd")
const TabsScript = preload("res://scripts/ui/kit/KitTabs.gd")
const Resources = preload("res://scripts/ui/kit/KitResourceBar.gd")
const Stat = preload("res://scripts/ui/kit/KitStatBar.gd")
const Chip = preload("res://scripts/ui/kit/KitChip.gd")
const Card = preload("res://scripts/ui/kit/KitCard.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
const Modal = preload("res://scripts/ui/kit/KitModal.gd")
const Toast = preload("res://scripts/ui/kit/KitToast.gd")
const Dock = preload("res://scripts/ui/kit/KitDock.gd")
const Drawer = preload("res://scripts/ui/kit/KitSideDrawer.gd")
var ui: Control
var scroll: ScrollContainer
var language := "ko"
var touch := false
var dimensions := Vector2i(1920, 1080)
var profile := ""
var failures: Array[String] = []
var leaf_paths: Dictionary = {}
var fully_seen: Dictionary = {}
var inventory: Dictionary = {}
const REQUIRED_COMPONENTS := ["KitPanel","KitButton","KitIconButton","KitTabs","KitResourceBar","KitStatBar","KitChip","KitCard","KitTooltip","KitModal","KitToast","KitDock","KitSideDrawer"]

func _ready() -> void:
	call_deferred("run_gallery")

func tr3(ko: String, en: String, zh: String) -> String:
	return en if language == "en" else (zh if language == "zh_CN" else ko)

func section(parent: Container, title: String) -> PanelContainer:
	var panel := PanelScript.new()
	panel.content.add_child(Kit.label(title, "number", true))
	parent.add_child(panel)
	return panel

func entries() -> Array:
	return [
		{"id":"build", "label":tr3("건설", "Build", "建造"), "icon":"build"},
		{"id":"guard", "label":tr3("수비대", "Guard", "守备"), "icon":"shield"},
		{"id":"tactics", "label":tr3("전술", "Tactics", "战术"), "icon":"attack"},
		{"id":"monster", "label":tr3("몬스터", "Monsters", "魔物"), "icon":"monster"},
		{"id":"start", "label":tr3("전투 시작", "Start battle", "开始战斗"), "icon":"resume", "disabled":true, "tooltip":tr3("배치를 마치세요.", "Finish deployment first.", "请先完成部署。")},
	]

func run_gallery() -> void:
	OUT = "res://tmp/v1213_u4/gallery"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kit-out=tmp/v1213_u4/"): OUT = "res://" + arg.trim_prefix("--kit-out=")
	var isolated := ProjectSettings.globalize_path(OUT).replace("\\", "/").trim_suffix("/") + "/"
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(isolated) or DisplayServer.get_name() == "headless":
		push_error("KitGallery requires graphical rendering and isolated APPDATA inside --kit-out")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	get_tree().create_timer(180).timeout.connect(func(): get_tree().quit(2))
	get_window().gui_embed_subwindows = true
	for resolution in [Vector2i(1920,1080), Vector2i(1280,720)]:
		dimensions = resolution
		get_window().content_scale_size = dimensions
		get_window().size = dimensions
		for touch_mode in [false, true]:
			touch = touch_mode
			for locale in ["ko", "en", "zh_CN"]:
				language = locale
				LanguageSettings.set_locale(locale, false)
				profile = "%dx%d_%s_%s" % [dimensions.x, dimensions.y, "touch" if touch else "desktop", locale]
				for page in range(4):
					build_page(page)
					await settle(12)
					var max_scroll := maxi(0, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
					var stops: Array[int] = [0]
					var offset := int(dimensions.y * 0.6)
					while offset < max_scroll:
						stops.append(offset)
						offset += int(dimensions.y * 0.6)
					if max_scroll > 0: stops.append(max_scroll)
					for i in range(stops.size()):
						scroll.scroll_vertical = stops[i]
						await save_capture("%s_p%d_%d" % [profile, page + 1, i], page)
					ui.queue_free()
					await settle(2)
	var unseen: Array = []
	for key in leaf_paths:
		if not fully_seen.has(key): unseen.append(key)
	if not unseen.is_empty(): failures.append("controls never fully visible across scroll captures: " + str(unseen))
	for key in inventory:
		for component in REQUIRED_COMPONENTS:
			if not inventory[key].has(component): failures.append(key + " missing component " + component)
	write_json("gallery_result.json", {"profiles":12,"pages":4,"captures":captures.size(),"fixture_failures":failures,"leaf_count":leaf_paths.size(),"fully_seen":fully_seen.size(),"unseen":unseen,"components":REQUIRED_COMPONENTS,"inventory":inventory,"text_scale":1.0,"touch_scale":Kit.Tokens.TOUCH_SCALE})
	print("KIT_GALLERY ", captures.size(), " captures / ", leaf_paths.size(), " leaves / failures=", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func build_page(page: int) -> void:
	ui = Control.new()
	ui.name = "Gallery"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var backdrop := ColorRect.new()
	backdrop.color = Kit.Tokens.BACKGROUND
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(margin)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var board := VBoxContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(board)
	board.add_child(Kit.label(tr3("마왕성 · 공통 UI", "Demon Castle · UI kit", "魔王城 · UI 组件"), "title", true))
	board.add_child(Kit.label("B / %s / %d×%d / %s · %d/4" % [language,dimensions.x,dimensions.y,"1.35×" if touch else "1×",page+1], "support"))
	var columns := HBoxContainer.new()
	var left := VBoxContainer.new()
	var right := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	columns.add_child(right)
	match page:
		0:
			var resources := Resources.new()
			resources.set_resources({"gold":1250,"mana":80,"food":24,"infamy":12}, {"gold":tr3("금화", "Gold", "金币"),"mana":tr3("마력", "Mana", "魔力"),"food":tr3("식량", "Food", "食物"),"infamy":tr3("악명", "Infamy", "恶名")})
			board.add_child(resources)
			board.add_child(columns)
			var states := section(left, tr3("버튼 상태", "Button states", "按钮状态"))
			var buttons := HFlowContainer.new()
			states.content.add_child(buttons)
			for state in ["normal", "hover", "pressed", "focus", "disabled"]:
				var caption: String = {"normal":tr3("기본", "Default", "默认"),"hover":tr3("호버", "Hover", "悬停"),"pressed":tr3("눌림", "Pressed", "按下"),"focus":tr3("초점", "Focus", "焦点"),"disabled":tr3("비활성", "Disabled", "禁用")}[state]
				var button := ButtonScript.new().configure(caption, ButtonScript.VariantStyle.DISABLED if state == "disabled" else ButtonScript.VariantStyle.BASIC)
				if state not in ["normal", "disabled"]:
					button.set_meta("kit_preview_state", state)
				buttons.add_child(button)
			var variants := section(right, tr3("강조 · 위험", "Primary · danger", "强调 · 危险"))
			variants.set_emphasis(true)
			var row := HFlowContainer.new()
			variants.content.add_child(row)
			row.add_child(ButtonScript.new().configure(tr3("확인", "Confirm", "确认"), ButtonScript.VariantStyle.PRIMARY, "check"))
			row.add_child(ButtonScript.new().configure(tr3("삭제", "Delete", "删除"), ButtonScript.VariantStyle.DANGER, "quit"))
			for variant in [ButtonScript.VariantStyle.PRIMARY, ButtonScript.VariantStyle.DANGER]:
				var previews := HFlowContainer.new()
				variants.content.add_child(previews)
				for state in ["hover", "pressed", "focus", "disabled"]:
					var caption: String = {"hover":tr3("호버", "Hover", "悬停"),"pressed":tr3("눌림", "Pressed", "按下"),"focus":tr3("초점", "Focus", "焦点"),"disabled":tr3("비활성", "Disabled", "禁用")}[state]
					var preview := ButtonScript.new().configure(caption, variant)
					preview.disabled = state == "disabled"
					if state != "disabled": preview.set_meta("kit_preview_state", state)
					previews.add_child(preview)
			var icons := HFlowContainer.new()
			variants.content.add_child(icons)
			for id in ["settings", "log", "save", "close"]: icons.add_child(IconButton.new().configure_icon(id, tr3("메뉴 열기", "Open menu", "打开菜单")))
			var tabs := TabsScript.new()
			tabs.set_tabs(entries(), "build")
			board.add_child(tabs)
			var dock := Dock.new().configure(entries(), "monster")
			board.add_child(dock)
		1:
			board.add_child(columns)
			var card := Card.new().configure(tr3("방패 슬라임", "Shield Slime", "盾牌史莱姆"), 5, Kit.Icons.get_icon("portrait"), 800, 1000, 65, 100)
			left.add_child(card)
			var stats := section(right, tr3("상태 · 전후 비교", "Stats · before/after", "状态 · 前后对比"))
			stats.content.add_child(Stat.new().configure("HP", 800, 1000, 1000))
			stats.content.add_child(Stat.new().configure("EXP", 65, 100, 45))
			stats.content.add_child(Stat.new().configure("HP", 0, 1000))
			stats.content.add_child(Stat.new().configure("EXP", 100, 100))
			var chips := section(left, tr3("수량 · 현재/최대", "Count · capacity", "数量 · 当前/最大"))
			var row := HFlowContainer.new()
			row.add_child(Chip.new().configure("monster", 3))
			row.add_child(Chip.new().configure("build", 2, 4))
			chips.content.add_child(row)
		2:
			board.add_child(columns)
			var title := tr3("성문 방벽", "Gate bulwark", "城门壁垒")
			var explanation := tr3("입구의 아군을 보호합니다.\n강화 효과와 비용을 확인하세요.", "Protect allies at the entrance.\nReview the upgrade effect and cost.", "保护入口处的友军。\n请确认强化效果与费用。")
			var tooltip := Tooltip.new().configure(title, explanation, {"gold":120,"mana":10}, 0)
			left.add_child(tooltip)
			var modal := Modal.new().configure(tr3("전투를 시작할까요?", "Start the battle?", "开始战斗吗？"), tr3("배치를 마치고 방어를 시작합니다.", "Finish deployment and begin defense.", "完成部署后开始防守。"), tr3("시작", "Start", "开始"), tr3("취소", "Cancel", "取消"))
			right.add_child(modal)
			board.add_child(Toast.new().configure(tr3("저장했습니다", "Progress saved", "已保存"), tr3("알림 닫기", "Dismiss notification", "关闭通知")))
		3:
			board.add_child(columns)
			var collapsed := Drawer.new().configure(tr3("상세", "Details", "详情"), tr3("상세 열기/접기", "Expand/collapse details", "展开/收起详情"))
			left.add_child(collapsed)
			var expanded := Drawer.new().configure(tr3("동료 상세", "Companion details", "伙伴详情"), tr3("상세 접기", "Collapse details", "收起详情"))
			expanded.panel.content.add_child(Kit.label(tr3("내용에 따라 높이가 늘어납니다.\n행동 설명은 툴팁으로 표시합니다.", "Height grows with content.\nAction descriptions appear in tooltips.", "高度随内容自动增加。\n操作说明显示在提示中。"), "body", true))
			expanded.set_expanded(true)
			left.add_child(expanded)
			var native := section(right, tr3("기본 Control 테마", "Native Control theme", "基础控件主题"))
			var tabbar := TabBar.new()
			for caption in [tr3("화면", "Display", "画面"), tr3("소리", "Audio", "声音")]: tabbar.add_tab(caption, Kit.Icons.get_icon("settings"))
			native.content.add_child(tabbar)
			var options := OptionButton.new()
			for caption in ["한국어", "English", "简体中文"]: options.add_item(caption)
			options.tooltip_text = tr3("언어 선택", "Choose language", "选择语言")
			native.content.add_child(options)
			var check := CheckBox.new()
			check.text = tr3("자동 재생", "Auto advance", "自动播放")
			check.button_pressed = true
			native.content.add_child(check)
			var unchecked := CheckBox.new()
			unchecked.text = tr3("안내 표시", "Show guidance", "显示指引")
			native.content.add_child(unchecked)
			var slider := HSlider.new()
			slider.value = 65
			slider.tooltip_text = tr3("음량", "Volume", "音量")
			native.content.add_child(slider)
			var inner_scroll := ScrollContainer.new()
			inner_scroll.custom_minimum_size.y = 120
			var list := VBoxContainer.new()
			list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for i in range(8): list.add_child(Kit.label(tr3("기록", "Record", "记录") + " %d" % (i+1)))
			inner_scroll.add_child(list)
			native.content.add_child(inner_scroll)
			# This bounded list intentionally demonstrates scrolling; capture its end too.
			inner_scroll.set_meta("kit_demo_scroll", true)
	Kit.apply_scale(ui, 1.0, touch)
	# Static visual previews use each button variant's actual scaled style resource.
	for child in ui.find_children("*", "Button", true, false):
		if child.has_meta("kit_preview_state"): child.add_theme_stylebox_override("normal", child.get_theme_stylebox(child.get_meta("kit_preview_state")))
	var expected_buttons: int = [29, 0, 3, 5][page]
	if ui.find_children("*", "Button", true, false).size() != expected_buttons:
		failures.append(profile + "/p%d missing button payload" % page)
	if not inventory.has(profile): inventory[profile] = {}
	_collect_inventory(ui)
	# Minimum viewport width is shared equally; wrapped labels decide their height.
	for child in [left, right]: child.size_flags_stretch_ratio = 1.0

func _collect_inventory(node: Node) -> void:
	var script: Script = node.get_script()
	if script != null and script is GDScript:
		var component := str(script.get_global_name())
		if component in REQUIRED_COMPONENTS: inventory[profile][component] = inventory[profile].get(component, 0) + 1
	for child in node.get_children(): _collect_inventory(child)

func effective_rect(control: Control) -> Rect2:
	var rect: Rect2 = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,control.size)
	var visible := rect.intersection(Rect2(Vector2.ZERO, Vector2(dimensions)))
	var parent := control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents: visible = visible.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return visible

func save_capture(id: String, page: int, scan_list: bool = true) -> void:
	await settle(8)
	await RenderingServer.frame_post_draw
	var rendered := get_viewport().get_texture().get_image()
	if rendered.get_size() != dimensions: failures.append("capture size mismatch: " + id)
	rendered.save_png(OUT.path_join(id + ".png"))
	var controls: Array = []
	collect(ui, controls)
	for record in controls:
		if record.type in ["Label", "Button", "OptionButton", "CheckBox", "TabBar", "HSlider", "ProgressBar", "TextureRect"]:
			var key: String = profile + "/p%d" % page + record.path.trim_prefix(str(ui.get_path()))
			# Internal scroll rows are separately demonstrated at the end below.
			leaf_paths[key] = true
			if not record.clipped: fully_seen[key] = true
	var entry := {"id":id,"screen":"kit_gallery","profile":profile,"page":page,"locale":language,"touch":touch,"resolution":[dimensions.x,dimensions.y],"controls":controls}
	write_json(id + ".json", entry)
	captures.append(entry)
	write_json("captures.json", captures)
	# Capture intermediate positions too so every list row is fully visible.
	for child in ui.find_children("*", "ScrollContainer", true, false):
		if scan_list and child.get_meta("kit_demo_scroll", false):
			var maximum := int(child.get_v_scroll_bar().max_value - child.get_v_scroll_bar().page)
			var offset := int(child.size.y / 2)
			while offset < maximum:
				child.scroll_vertical = offset
				await save_capture(id + "_list_%d" % offset, page, false)
				offset += int(child.size.y / 2)
			child.scroll_vertical = maximum
			await save_capture(id + "_list_end", page, false)
			child.scroll_vertical = 0
