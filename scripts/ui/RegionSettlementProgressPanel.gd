extends PanelContainer
class_name RegionSettlementProgressPanel

var progress_bar: ProgressBar
var progress_label: Label


func _ready() -> void:
	if progress_label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)
	progress_label = Label.new()
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.text = "지역 0/3 · 헌장 0/3 · 인장 0/3"
	progress_label.add_theme_color_override("font_color", Color("e9ddc5"))
	stack.add_child(progress_label)
	progress_bar = ProgressBar.new()
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.step = 0.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(260, 10)
	stack.add_child(progress_bar)


func set_progress(progress: Dictionary) -> void:
	if progress_label == null:
		_ready()
	progress_label.text = str(progress.get("label", "지역 진행 정보 없음"))
	progress_bar.value = clampf(float(progress.get("ratio", 0.0)), 0.0, 1.0)
