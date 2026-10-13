extends "res://scripts/ui/kit/KitPanel.gd"
class_name KitCard
const Stat = preload("res://scripts/ui/kit/KitStatBar.gd")
var portrait: TextureRect
var name_label: Label
var level_label: Label
var hp := Stat.new()
var experience := Stat.new()

func _init() -> void:
	super()
	var row := HBoxContainer.new()
	portrait = Kit.image("portrait", Kit.Tokens.PORTRAIT_SIZE)
	row.add_child(portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label = Kit.label("", "body", true)
	level_label = Kit.label("", "number")
	level_label.add_theme_color_override("font_color", Kit.Tokens.HIGHLIGHT)
	identity.add_child(name_label)
	identity.add_child(level_label)
	row.add_child(identity)
	content.add_child(row)
	content.add_child(experience)
	content.add_child(hp)

func configure(display_name: String, level: int, portrait_texture: Texture2D, hp_value: float, hp_max: float, exp_value: float, exp_max: float) -> KitCard:
	name_label.text = display_name
	level_label.text = "Lv. %d" % level
	portrait.texture = portrait_texture
	hp.configure("HP", hp_value, hp_max)
	experience.configure("EXP", exp_value, exp_max)
	return self
