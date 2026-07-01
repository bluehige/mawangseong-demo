extends RefCounted
class_name WaveManager

var schedule: Array = []
var elapsed: float = 0.0
var next_index: int = 0
var total_to_spawn: int = 0

func setup(day: int, waves: Dictionary) -> void:
	schedule.clear()
	elapsed = 0.0
	next_index = 0
	total_to_spawn = 0
	var day_key = "day_%d" % day
	for entry in waves.get(day_key, []):
		for i in range(int(entry.get("count", 1))):
			schedule.append({
				"enemy_id": entry.get("enemy_id", "explorer"),
				"time": float(entry.get("spawn_delay", 0.0)) + float(i) * 1.2
			})
	total_to_spawn = schedule.size()
	schedule.sort_custom(func(a, b): return float(a["time"]) < float(b["time"]))

func tick(delta: float) -> Array:
	elapsed += delta
	var ready: Array = []
	while next_index < schedule.size() and elapsed >= float(schedule[next_index]["time"]):
		ready.append(schedule[next_index])
		next_index += 1
	return ready

func is_done() -> bool:
	return next_index >= schedule.size()

