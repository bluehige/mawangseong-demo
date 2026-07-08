extends RefCounted
class_name WaveManager

var schedule: Array = []
var elapsed: float = 0.0
var next_index: int = 0
var total_to_spawn: int = 0

func setup(day: int, waves: Dictionary, defense_modifiers: Dictionary = {}) -> void:
	schedule.clear()
	elapsed = 0.0
	next_index = 0
	total_to_spawn = 0
	var day_key = "day_%d" % day
	var day_entries: Array = waves.get(day_key, []).duplicate(true)
	for modifier in defense_modifiers.values():
		for extra_entry in modifier.get("extra_waves", []):
			day_entries.append(extra_entry.duplicate(true))
	for entry in day_entries:
		var modified_entry = _apply_modifiers_to_entry(entry, defense_modifiers)
		for i in range(int(modified_entry.get("count", 1))):
			var scheduled_entry: Dictionary = entry.duplicate(true)
			scheduled_entry.merge(modified_entry, true)
			scheduled_entry["enemy_id"] = modified_entry.get("enemy_id", "explorer")
			scheduled_entry["time"] = float(modified_entry.get("spawn_delay", 0.0)) + float(i) * float(modified_entry.get("spawn_interval", 1.2))
			schedule.append(scheduled_entry)
	total_to_spawn = schedule.size()
	schedule.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

func _apply_modifiers_to_entry(entry: Dictionary, defense_modifiers: Dictionary) -> Dictionary:
	var modified_entry := entry.duplicate(true)
	var enemy_id := str(modified_entry.get("enemy_id", "explorer"))
	for modifier in defense_modifiers.values():
		modified_entry["count"] = max(0, int(modified_entry.get("count", 1)) + _modifier_enemy_int(modifier, "count_delta_by_enemy", enemy_id))
		modified_entry["spawn_delay"] = max(0.0, float(modified_entry.get("spawn_delay", 0.0)) + float(modifier.get("spawn_delay_bonus", 0.0)) + _modifier_enemy_float(modifier, "spawn_delay_bonus_by_enemy", enemy_id))
		modified_entry["spawn_interval"] = max(0.1, float(modified_entry.get("spawn_interval", 1.2)) + float(modifier.get("spawn_interval_bonus", 0.0)) + _modifier_enemy_float(modifier, "spawn_interval_bonus_by_enemy", enemy_id))
		for scale_key in ["hp_scale", "atk_scale", "def_scale", "reward_scale"]:
			var delta_key = "%s_delta_by_enemy" % scale_key
			if modifier.has(delta_key):
				modified_entry[scale_key] = max(0.0, float(modified_entry.get(scale_key, 1.0)) + _modifier_enemy_float(modifier, delta_key, enemy_id))
	return modified_entry

func _modifier_enemy_int(modifier: Dictionary, key: String, enemy_id: String) -> int:
	var values: Dictionary = modifier.get(key, {})
	return int(values.get(enemy_id, 0))

func _modifier_enemy_float(modifier: Dictionary, key: String, enemy_id: String) -> float:
	var values: Dictionary = modifier.get(key, {})
	return float(values.get(enemy_id, 0.0))

func tick(delta: float) -> Array:
	elapsed += delta
	var ready: Array = []
	while next_index < schedule.size() and elapsed >= float(schedule[next_index]["time"]):
		ready.append(schedule[next_index])
		next_index += 1
	return ready

func is_done() -> bool:
	return next_index >= schedule.size()

