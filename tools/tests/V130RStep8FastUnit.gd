extends "res://scripts/units/ApprovedBattleUnit.gd"
## Headless trials omit only raster pose/depth/occlusion, never combat or movement.
var omit_raster := false
func _apply_visual_pose() -> void:
	if not omit_raster: super._apply_visual_pose()
func _update_animation() -> void:
	if not omit_raster: super._update_animation()
func refresh_depth_slot() -> void:
	if not omit_raster: super.refresh_depth_slot()
