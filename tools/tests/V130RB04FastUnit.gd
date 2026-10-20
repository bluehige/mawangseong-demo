extends "res://scripts/units/ApprovedBattleUnit.gd"
## Test process only: avoid raster measurement on every simulated 60 Hz tick.
func _apply_visual_pose() -> void: pass
func _update_animation() -> void: pass
func refresh_depth_slot() -> void: pass
func _physics_process(delta: float) -> void:
	# Keep the UI object available between ticks; ApprovedBattleUI reads it.
	var display := health
	health=null
	super._physics_process(delta)
	health=display
func _sync_combat_label_visibility() -> void: pass
