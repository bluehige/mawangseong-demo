extends RefCounted
## Test-only replay of the existing global generator, without changing its stream.
## Godot 4.6 Math globals share RandomPCG; no gameplay RNG implementation is replaced.
## https://github.com/godotengine/godot/blob/4.6-stable/core/math/math_funcs.cpp
const MAX_SCAN := 4000000

static func rewind_to(seed_value: int, draws: int) -> void:
	seed(seed_value)
	for i in draws: randi()

static func fingerprint() -> Array:
	return [randi(),randi(),randi(),randi()]

static func capture(seed_value: int, minimum_draws: int = 0) -> Dictionary:
	var expected := fingerprint()
	rewind_to(seed_value,minimum_draws)
	var recent := fingerprint()
	var draws := minimum_draws
	while recent!=expected and draws-minimum_draws<MAX_SCAN:
		recent.pop_front(); recent.append(randi()); draws+=1
	if recent!=expected:
		return {"ok":false,"reason":"global RNG reseeded or scan limit exceeded"}
	rewind_to(seed_value,draws)
	return {"ok":true,"seed":seed_value,"draws":draws,"fingerprint":expected}

static func restore(state: Dictionary) -> bool:
	if not state.get("ok",false): return false
	var seed_value := int(state.seed); var draws := int(state.draws)
	rewind_to(seed_value,draws)
	var expected: Array = []
	for value in state.fingerprint: expected.append(int(value))
	var matches: bool = fingerprint()==expected
	rewind_to(seed_value,draws)
	return matches
