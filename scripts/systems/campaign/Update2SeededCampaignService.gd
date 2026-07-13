extends RefCounted
class_name Update2SeededCampaignService


static func event_deck(data: Dictionary, cycle_seed: int) -> Array[String]:
	var events: Dictionary = data.get("events", {})
	var ids: Array[String] = []
	for event_id_value in events.keys():
		ids.append(str(event_id_value))
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(events.get(a, {}).get("order", 0)) < int(events.get(b, {}).get("order", 0))
	)
	return _shuffled(ids, cycle_seed ^ 0x4D3A2B1C)


static func wave_variant_ids(data: Dictionary, cycle_seed: int) -> Array[String]:
	var variants: Dictionary = data.get("wave_variants", {})
	var by_day: Dictionary = {}
	for variant_id_value in variants.keys():
		var variant_id := str(variant_id_value)
		var day := int(variants.get(variant_id, {}).get("day", 0))
		if day <= 0:
			continue
		if not by_day.has(day):
			by_day[day] = []
		by_day[day].append(variant_id)
	var days: Array = by_day.keys()
	days.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = cycle_seed ^ 0x13579BDF
	var result: Array[String] = []
	for day_value in days:
		var candidates: Array = by_day[day_value]
		candidates.sort_custom(func(a, b): return int(variants.get(a, {}).get("order", 0)) < int(variants.get(b, {}).get("order", 0)))
		if not candidates.is_empty():
			result.append(str(candidates[rng.randi_range(0, candidates.size() - 1)]))
	return result


static func event_for_day(data: Dictionary, deck: Array, day: int) -> Dictionary:
	var event_days: Array = data.get("event_days", [])
	var index := -1
	for candidate_index in range(event_days.size()):
		if int(event_days[candidate_index]) == day:
			index = candidate_index
			break
	if index < 0 or index >= deck.size():
		return {}
	var event_id := str(deck[index])
	var event: Dictionary = data.get("events", {}).get(event_id, {}).duplicate(true)
	if event.is_empty():
		return {}
	event["id"] = event_id
	event["day"] = day
	return event


static func wave_variant_for_day(data: Dictionary, selected_ids: Array, day: int) -> Dictionary:
	var variants: Dictionary = data.get("wave_variants", {})
	for variant_id_value in selected_ids:
		var variant_id := str(variant_id_value)
		var variant: Dictionary = variants.get(variant_id, {})
		if int(variant.get("day", 0)) == day:
			var result := variant.duplicate(true)
			result["id"] = variant_id
			return result
	return {}


static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var events: Dictionary = data.get("events", {})
	var event_days: Array = data.get("event_days", [])
	if events.size() != event_days.size():
		errors.append("사건 수와 사건 발생 날짜 수가 다릅니다.")
	var variants: Dictionary = data.get("wave_variants", {})
	var day_counts: Dictionary = {}
	for variant_id_value in variants.keys():
		var variant: Dictionary = variants.get(variant_id_value, {})
		var day := int(variant.get("day", 0))
		day_counts[day] = int(day_counts.get(day, 0)) + 1
		for entry_value in variant.get("extra_waves", []):
			if not (entry_value is Dictionary):
				errors.append("웨이브 변형 항목 형식이 잘못됐습니다: %s" % variant_id_value)
				continue
			for scale_key in ["hp_scale", "atk_scale", "def_scale", "reward_scale"]:
				if entry_value.has(scale_key) and float(entry_value.get(scale_key, 1.0)) > 1.10:
					errors.append("웨이브 변형 수치가 1.10 상한을 넘습니다: %s/%s" % [variant_id_value, scale_key])
	for required_day in [10, 15, 20, 25, 30]:
		if int(day_counts.get(required_day, 0)) < 2:
			errors.append("DAY %d 웨이브 후보가 2개 미만입니다." % required_day)
	return errors


static func _shuffled(source: Array[String], seed: int) -> Array[String]:
	var result := source.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index in range(result.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held: String = result[index]
		result[index] = result[swap_index]
		result[swap_index] = held
	return result
