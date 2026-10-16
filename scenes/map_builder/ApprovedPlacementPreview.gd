extends "res://scenes/map_builder/ApprovedMapPreview.gd"
## Explicit branch-only test entry. All campaign save flags remain disabled.
func _ready() -> void:
	ProjectSettings.set_setting("debug/approved_map_step2",true)
	super._ready()
