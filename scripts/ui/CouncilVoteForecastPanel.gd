extends PanelContainer
class_name CouncilVoteForecastPanel

var title_label: Label
var votes_label: Label
var result_label: Label


func _ready() -> void:
	if title_label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 16)
	for side in ["margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 7)
	margin.add_child(stack)
	title_label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.text = "예상 표"
	title_label.add_theme_color_override("font_color", Color("f2cf78"))
	stack.add_child(title_label)
	votes_label = Label.new()
	votes_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	votes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(votes_label)
	result_label = Label.new()
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(result_label)


func show_forecast(forecast_value: Dictionary, rival_catalog: Dictionary) -> void:
	if title_label == null:
		_ready()
	var positions: Dictionary = forecast_value.get("positions", {})
	var rows: Array[String] = ["마왕: %s" % _choice_label(str(positions.get("player", "")))]
	for rival_id in rival_catalog.keys():
		rows.append("%s: %s" % [str(rival_catalog[rival_id].get("display_name", rival_id)), _choice_label(str(positions.get(rival_id, "")))])
	votes_label.text = " · ".join(rows)
	result_label.text = "통과 예상" if bool(forecast_value.get("passed", false)) else "부결 예상 · 회차는 계속됩니다"
	result_label.add_theme_color_override("font_color", Color("8fd7a7") if bool(forecast_value.get("passed", false)) else Color("e6a36f"))


func _choice_label(choice_id: String) -> String:
	return {"approve": "찬성", "amend": "수정안", "reject": "반대"}.get(choice_id, "미정")
