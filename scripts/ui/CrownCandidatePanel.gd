extends PanelContainer
class_name CrownCandidatePanel

var candidate_list: VBoxContainer
var candidate_buttons: Array[Button] = []
var decline_button: Button


func _ready() -> void:
	if candidate_list != null:
		return
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	var title := Label.new()
	title.text = "왕관 진화 후보"
	title.add_theme_color_override("font_color", Color("f0cf73"))
	stack.add_child(title)
	candidate_list = VBoxContainer.new()
	candidate_list.add_theme_constant_override("separation", 7)
	stack.add_child(candidate_list)
	decline_button = Button.new()
	decline_button.text = "선택하지 않고 인장 사용"
	decline_button.custom_minimum_size = Vector2(360, 48)
	stack.add_child(decline_button)


func configure(candidates: Array) -> void:
	if candidate_list == null:
		_ready()
	for child in candidate_list.get_children():
		child.free()
	candidate_buttons.clear()
	for index in mini(CrownEvolutionService.MAX_VISIBLE_CANDIDATES, candidates.size()):
		var candidate: Dictionary = candidates[index]
		var button := Button.new()
		button.text = "%s  ·  %s" % [str(candidate.get("display_name", "왕관 후보")), str(candidate.get("instance_id", ""))]
		button.custom_minimum_size = Vector2(360, 48)
		candidate_list.add_child(button)
		candidate_buttons.append(button)
