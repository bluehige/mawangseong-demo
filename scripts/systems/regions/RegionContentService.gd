extends RefCounted
class_name RegionContentService


static func event_for_chapter(region: Dictionary, events: Dictionary, chapter_slot: int) -> Dictionary:
	var event_ids: Array = region.get("event_ids", [])
	if event_ids.is_empty() or chapter_slot < 1 or chapter_slot > 3:
		return {}
	var event_id := str(event_ids[(chapter_slot - 1) % event_ids.size()])
	var event: Dictionary = events.get(event_id, {}).duplicate(true)
	var valid_position := false
	for position in event.get("chapter_positions", []):
		if int(position) == chapter_slot:
			valid_position = true
			break
	if not valid_position:
		return {}
	event["id"] = event_id
	return event


static func wave_for_chapter(region_id: String, chapter_slot: int, templates: Dictionary) -> Dictionary:
	for template_id_value in templates.keys():
		var template: Dictionary = templates[template_id_value]
		if str(template.get("region_id", "")) == region_id and int(template.get("chapter_slot", 0)) == chapter_slot:
			var result := template.duplicate(true)
			result["id"] = str(template_id_value)
			return result
	return {}


static func charter_completed(region: Dictionary, metrics: Dictionary) -> bool:
	var charter: Dictionary = region.get("charter", {})
	var metric_id := str(charter.get("metric", ""))
	var operator := str(charter.get("operator", ""))
	var target := float(charter.get("value", 0.0))
	if metric_id == "treasure_loss_or_security":
		return float(metrics.get("treasure_loss", 0.0)) <= target or str(metrics.get("security_grade", "F")) in ["A", "S"]
	var actual := float(metrics.get(metric_id, 0.0))
	match operator:
		"lte": return actual <= target
		"gte": return actual >= target
		"eq": return is_equal_approx(actual, target)
	return false


static func recompute_wave_threat(template: Dictionary, enemies: Dictionary) -> float:
	var total := 0.0
	for enemy_id in template.get("enemy_counts", {}).keys():
		total += float(enemies.get(enemy_id, {}).get("threat", 0.0)) * int(template.enemy_counts[enemy_id])
	return total


static func simulate_region_selection(regions: Dictionary, trials: int, seed_value: int) -> Dictionary:
	var region_ids: Array = regions.keys()
	region_ids.sort()
	var counts := {}
	for region_id in region_ids:
		counts[region_id] = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for _trial in range(maxi(0, trials)):
		if region_ids.is_empty():
			break
		var selected = region_ids[rng.randi_range(0, region_ids.size() - 1)]
		counts[selected] = int(counts[selected]) + 1
	var rates := {}
	for region_id in region_ids:
		rates[region_id] = float(counts[region_id]) / maxf(1.0, float(trials))
	return {"counts": counts, "rates": rates}


static func reward_balance(regions: Dictionary) -> Dictionary:
	var values: Array[float] = []
	for region in regions.values():
		values.append(float(region.get("simulation_reward_score", 0.0)))
	var average := 0.0
	for value in values:
		average += value
	average /= maxf(1.0, float(values.size()))
	var max_deviation := 0.0
	for value in values:
		max_deviation = maxf(max_deviation, absf(value - average) / maxf(1.0, average))
	return {"average": average, "max_deviation_ratio": max_deviation, "balanced": max_deviation <= 0.10}


static func settlement_progress(selected_regions: int, completed_charters: int, seals: int) -> Dictionary:
	var selected := clampi(selected_regions, 0, 3)
	var completed := clampi(completed_charters, 0, selected)
	var seal_count := clampi(seals, 0, 3)
	return {
		"ratio": float(completed) / 3.0,
		"label": "지역 %d/3 · 헌장 %d/3 · 인장 %d/3" % [selected, completed, seal_count]
	}
