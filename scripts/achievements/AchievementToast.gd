extends CanvasLayer
const FontKit = preload("res://scripts/ui/UIFont.gd")
var service: Node
var queue: Array[String] = []
var current: Control
var seconds := 0.0

func setup(owner_service: Node) -> void:
	service = owner_service; layer = 130
	service.unlocked.connect(enqueue)

func enqueue(id: String) -> void:
	queue.append(id)

func _process(delta: float) -> void:
	if is_instance_valid(current):
		seconds -= delta
		current.modulate.a = minf(1.0,seconds*2)
		if seconds <= 0: current.queue_free(); current = null
	if not is_instance_valid(current) and not queue.is_empty(): show_next()

func show_next() -> void:
	var id: String = queue.pop_front()
	var row: Dictionary = {}
	for item in service.catalog.achievements:
		if item.api_name == id: row = item; break
	if row.is_empty(): return
	current = Control.new(); current.name = "AchievementToast"; add_child(current)
	current.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	current.position = Vector2(get_viewport().get_visible_rect().size.x-660,22); current.size = Vector2(630,140)
	var frame := TextureRect.new(); current.add_child(frame); frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.texture = load("res://assets/achievements/v130/toast_frame.png"); frame.position = Vector2.ZERO; frame.size = current.size
	var icon := TextureRect.new(); current.add_child(icon); icon.position = Vector2(42,40); icon.size = Vector2(64,64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.texture = load(row.icon_path)
	var caption := Label.new(); current.add_child(caption); caption.position = Vector2(136,38)
	caption.text = {"ko":"도전과제 달성","en":"Achievement unlocked","zh_CN":"成就已解锁"}.get(LanguageSettings.locale,"")
	caption.add_theme_font_override("font",FontKit.font_for_role("body")); caption.add_theme_font_size_override("font_size",20); caption.modulate = Color("d8bd7a")
	var name_label := Label.new(); current.add_child(name_label); name_label.position = Vector2(136,64); name_label.size = Vector2(450,40)
	name_label.text = row["name_"+("zh_cn" if LanguageSettings.locale == "zh_CN" else LanguageSettings.locale)]; name_label.add_theme_font_override("font",FontKit.font_for_role("button"))
	name_label.add_theme_font_size_override("font_size",25); name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_ignore(current); seconds = 5.0

func _ignore(node: Node) -> void:
	if node is Control: node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children(): _ignore(child)
