extends Node2D

var root: Node
var debug_draw_invocation_count := 0


func setup(game_root: Node) -> void:
	root = game_root


func _draw() -> void:
	debug_draw_invocation_count += 1
	if root != null and root.has_method("_draw_world_overlay"):
		root._draw_world_overlay(self)


func debug_reset_draw_invocation_count() -> void:
	debug_draw_invocation_count = 0


func debug_draw_invocations() -> int:
	return debug_draw_invocation_count
