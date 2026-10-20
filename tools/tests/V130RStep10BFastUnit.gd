extends "res://tools/tests/V130RStep8FastUnit.gd"
## Headless presentation only; status, movement and combat remain in super.
func _physics_process(delta: float) -> void:
	var display := health
	if omit_raster: health = null
	super._physics_process(delta)
	health = display

func _sync_combat_label_visibility() -> void:
	if not omit_raster: super._sync_combat_label_visibility()
