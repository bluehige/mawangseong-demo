extends "res://scenes/map_builder/ApprovedMapPreview.gd"
## Explicit branch-only test entry. All campaign save flags remain disabled.
func _ready() -> void:
	# Use actual client pixels in this isolated branch preview, including 16:10.
	get_window().content_scale_size = Vector2i.ZERO
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	ProjectSettings.set_setting("debug/approved_map_step2",true)
	super._ready()
