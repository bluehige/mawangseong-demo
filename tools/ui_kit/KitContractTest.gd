extends Node
const Kit = preload("res://scripts/ui/kit/UIKit.gd")
const PanelScript = preload("res://scripts/ui/kit/KitPanel.gd")
const ButtonScript = preload("res://scripts/ui/kit/KitButton.gd")
const IconButton = preload("res://scripts/ui/kit/KitIconButton.gd")
const TabsScript = preload("res://scripts/ui/kit/KitTabs.gd")
const Tooltip = preload("res://scripts/ui/kit/KitTooltip.gd")
const Modal = preload("res://scripts/ui/kit/KitModal.gd")
const Toast = preload("res://scripts/ui/kit/KitToast.gd")
const Drawer = preload("res://scripts/ui/kit/KitSideDrawer.gd")
const Layers = preload("res://scripts/ui/kit/UIKitLayers.gd")
var checks := 0
var failures: Array[String] = []
var clicks := 0
var decisions := 0
var cancelled := 0
var tabs_changed := 0
var ui: Control
var button: Button

func _ready() -> void:
	call_deferred("run")

func expect(ok: bool, note: String) -> void:
	checks += 1
	if not ok: failures.append(note); print("FAIL: ", note)

func settle() -> void:
	for i in range(8): await get_tree().process_frame

func click(control: Control) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = control.get_global_rect().get_center()
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func key(action: String) -> void:
	for down in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = down
		get_viewport().push_input(event, true)
		await get_tree().process_frame

func touch_press(control: Control) -> void:
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.pressed = down
		event.position = get_viewport().get_final_transform() * control.get_global_rect().get_center()
		Input.parse_input_event(event)
		await get_tree().process_frame
	await settle()

func run() -> void:
	var isolation := ProjectSettings.globalize_path("res://tmp/v1213_u4/").replace("\\", "/")
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(isolation):
		push_error("Kit test requires isolated APPDATA")
		get_tree().quit(2)
		return
	get_tree().create_timer(60).timeout.connect(func(): get_tree().quit(2))
	get_window().content_scale_size = Vector2i(1280,720)
	get_window().size = Vector2i(1280,720)
	get_window().gui_embed_subwindows = true
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ui)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(column)
	var panel := PanelScript.new()
	column.add_child(panel)
	button = ButtonScript.new().configure("Confirm", ButtonScript.VariantStyle.PRIMARY, "build", "Confirm\nApply this choice")
	button.pressed.connect(func(): clicks += 1)
	panel.content.add_child(button)
	var long_text := Kit.label("Grow with content", "body", true)
	panel.content.add_child(long_text)
	await settle()
	expect(button.icon != null and button.size.x >= button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + Kit.Tokens.ICON_SIZE, "icon plus caption reserves minimum width")
	await click(button)
	expect(clicks == 1, "mouse activates once")
	button.grab_focus()
	await key("ui_accept")
	expect(clicks == 2, "keyboard activates once")
	button.disabled = true
	await click(button)
	await key("ui_accept")
	expect(clicks == 2, "disabled button rejects mouse and keyboard")
	button.disabled = false
	await touch_press(button)
	expect(clicks == 3, "touch-to-mouse input activates once")
	var initial := panel.get_combined_minimum_size().y
	long_text.text = "Line one\nLine two\nLine three\nLine four"
	await settle()
	expect(panel.get_combined_minimum_size().y > initial, "wrapped/multiline text increases container height")
	Kit.apply_scale(ui, 1.15, true)
	await settle()
	expect(button.get_theme_font_size("font_size") == Kit.Tokens.font_size(Kit.Tokens.BUTTON_SIZE, 1.15, true), "max user text + touch font scale")
	expect(button.size.y >= button.get_theme_font("font").get_height(button.get_theme_font_size("font_size")) + Kit.Tokens.PADDING.y * 2, "font-derived button height")
	Kit.apply_scale(ui)
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		for touch in [false,true]:
			var resource := Kit.scaled_theme(0.9, touch)
			for type in ["Label", "KitSupport", "KitTitle", "KitNumber", "Button"]: expect(resource.get_font_size("font_size", type) >= Kit.Tokens.SUPPORT_SIZE, locale + " font floor " + type)
			expect(resource.default_font == Kit.Fonts.font_for_role(Kit.Fonts.ROLE_BODY), locale + " existing locale font authority")
	LanguageSettings.set_locale("ko", false)
	var tabs := TabsScript.new()
	tabs.set_tabs([{"id":"a","label":"A","icon":"build"},{"id":"b","label":"B","icon":"shield"},{"id":"c","label":"C","disabled":true}], "a")
	tabs.tab_selected.connect(func(_id: String): tabs_changed += 1)
	panel.content.add_child(tabs)
	await settle()
	await click(tabs.get_child(1))
	expect(tabs.selected_id == "b" and tabs_changed == 1, "tab selects by actual input")
	await click(tabs.get_child(2))
	expect(tabs.selected_id == "b" and tabs_changed == 1, "disabled tab preserves selection")
	Kit.apply_scale(tabs, 1.15, true)
	tabs.set_tabs([{"id":"a","label":"Rebuilt","icon":"build"}], "a")
	await settle()
	expect(tabs.get_child(0).get_theme_font_size("font_size") == Kit.Tokens.font_size(Kit.Tokens.BUTTON_SIZE, 1.15, true), "rebuilt tabs retain parent touch/font scale")
	var tooltip := button._make_custom_tooltip("Gate\nProtect allies") as Control
	expect(tooltip is Tooltip and tooltip.content.get_child_count() == 3, "structured tooltip title/body/cost row")
	tooltip.free()
	Kit.apply_scale(button, 1.15, true)
	var scaled_tooltip := button._make_custom_tooltip("Gate\nProtect allies") as Control
	column.add_child(scaled_tooltip)
	await settle()
	expect(scaled_tooltip.description.get_theme_font_size("font_size") == Kit.Tokens.font_size(Kit.Tokens.TOOLTIP_SIZE, 1.15, true), "popup tooltip retains font/touch scale")
	scaled_tooltip.free()
	Kit.apply_scale(button)
	var floating_tooltip := Tooltip.new().configure("Gate", "Protect allies", {"gold":120})
	floating_tooltip.present_at(self, Vector2(1000,650), 1, true)
	await settle()
	expect(floating_tooltip._overlay.layer == Layers.TOAST_TOOLTIP, "manual tooltip layer above cutscene")
	expect(floating_tooltip.get_global_rect().end.x <= get_viewport().get_visible_rect().end.x and floating_tooltip.get_global_rect().end.y <= get_viewport().get_visible_rect().end.y, "tooltip clamps to viewport after content sizing")
	floating_tooltip.dismiss()
	await settle()
	var drawer := Drawer.new().configure("Details", "Expand or collapse details")
	panel.content.add_child(drawer)
	await settle()
	await click(drawer.handle)
	expect(drawer.expanded and drawer.panel.visible, "drawer opens by actual input")
	await click(drawer.handle)
	expect(not drawer.expanded and not drawer.panel.visible, "drawer collapses by actual input")
	button.grab_focus()
	var modal := Modal.new().configure("Confirm?", "Decision", "Confirm", "Cancel")
	modal.confirmed.connect(func(): decisions += 1)
	modal.cancelled.connect(func(): cancelled += 1)
	modal.present(self)
	await settle()
	expect(modal._overlay.layer == Layers.MODAL, "modal layer")
	expect(get_viewport().gui_get_focus_owner() == modal.cancel_button, "modal starts on safe cancel focus")
	await key("ui_focus_next")
	expect(get_viewport().gui_get_focus_owner() == modal.confirm_button, "modal focus cycles internally")
	await key("ui_accept")
	await settle()
	expect(decisions == 1 and cancelled == 0, "modal confirms once")
	expect(get_viewport().gui_get_focus_owner() == button, "modal restores prior focus")
	var cancel_modal := Modal.new().configure("Cancel?", "Decision", "Confirm", "Cancel")
	cancel_modal.cancelled.connect(func(): cancelled += 1)
	cancel_modal.present(self)
	await settle()
	await key("ui_cancel")
	await settle()
	expect(cancelled == 1 and decisions == 1, "escape cancels once")
	var policy := Layers.new()
	var hidden_hud := Control.new()
	ui.add_child(hidden_hud)
	hidden_hud.hide()
	policy.set_cutscene_active(true, [panel, hidden_hud])
	expect(not panel.visible, "cutscene hides HUD")
	var late_hud := Control.new()
	ui.add_child(late_hud)
	policy.track_hud(late_hud)
	expect(not late_hud.visible, "cutscene hides newly added HUD")
	policy.set_cutscene_active(true, [panel])
	policy.set_cutscene_active(false, [])
	expect(panel.visible and late_hud.visible and not hidden_hud.visible, "cutscene restores original visibility including initially hidden HUD")
	for pair in [[Layers.BACKGROUND_MAP,Layers.MAP_MARKERS],[Layers.MAP_MARKERS,Layers.HUD],[Layers.HUD,Layers.DETAILS],[Layers.DETAILS,Layers.MODAL],[Layers.MODAL,Layers.CUTSCENE],[Layers.CUTSCENE,Layers.TOAST_TOOLTIP]]: expect(pair[0] < pair[1], "layer order")
	var toast := Toast.new().configure("Saved", "Dismiss")
	toast.present(self, 0.1)
	expect(toast._overlay.layer == Layers.TOAST_TOOLTIP, "toast layer above cutscene")
	await get_tree().create_timer(0.2).timeout
	await settle()
	expect(not is_instance_valid(toast), "toast expires and frees its overlay")
	var icon := IconButton.new().configure_icon("settings", "Settings\nOpen settings")
	panel.content.add_child(icon)
	Kit.apply_scale(icon, 1, true)
	await settle()
	expect(icon.size.y >= Kit.Tokens.ICON_BUTTON_SIZE * Kit.Tokens.TOUCH_SCALE, "touch icon target")
	expect(not icon.tooltip_text.strip_edges().is_empty(), "icon tooltip")
	if OS.get_cmdline_user_args().has("--kit-empty-tooltip"):
		var empty := IconButton.new().configure_icon("close", "")
		panel.content.add_child(empty)
		await settle()
	var output := FileAccess.open("res://tmp/v1213_u4/contract_result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures}, "\t"))
	output.close()
	print("KIT_CONTRACT ", checks, " checks / failures=", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
