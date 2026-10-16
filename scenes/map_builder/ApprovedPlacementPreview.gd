extends "res://scenes/map_builder/ApprovedMapPreview.gd"
## Explicit branch-only test entry. All campaign save flags remain disabled.
func _ready() -> void:
	# Use actual client pixels in this isolated branch preview, including 16:10.
	get_window().content_scale_size = Vector2i.ZERO
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	ProjectSettings.set_setting("debug/approved_map_step2",true)
	ProjectSettings.set_setting("debug/approved_map_step6",OS.get_cmdline_user_args().has("--food-system"))
	ProjectSettings.set_setting("debug/approved_map_step5",OS.get_cmdline_user_args().has("--grade-progression") or OS.get_cmdline_user_args().has("--food-system"))
	super._ready()
