extends Node2D
class_name QuarterDungeonWallCanvas

var renderer: RefCounted
var wall_layer_name := ""
var debug_draw_count := 0


func setup(renderer_ref: RefCounted, layer_name: String) -> void:
	renderer = renderer_ref
	wall_layer_name = layer_name


func _draw() -> void:
	debug_draw_count += 1
	if renderer != null and renderer.has_method("draw_wall_canvas_layer"):
		renderer.draw_wall_canvas_layer(self, wall_layer_name)


func debug_draw_invocations() -> int:
	return debug_draw_count


func debug_occlusion_contract() -> Dictionary:
	var draw_scope := "translucent_front_wall" if wall_layer_name == "wall_front" else "compatibility_no_draw"
	if wall_layer_name == "object_front":
		draw_scope = "front_props_depth_30"
	var contract := {
		"canvas_layer": wall_layer_name,
		"draw_scope": draw_scope
	}
	if renderer != null and renderer.has_method("debug_depth_contract"):
		contract.merge(renderer.debug_depth_contract(), true)
	return contract
