extends Node2D
var advance: Callable
func _process(delta: float) -> void:
	if advance.is_valid(): advance.call(delta)
