extends RefCounted
class_name LeonAdaptationService

const STANCE_KEYS := ["facility", "backline", "sustain", "direct"]


static func default_adaptation() -> Dictionary:
	return {
		"stance_id": "",
		"announced_day": 0,
		"locked": false,
		"analysis": {},
		"retry_seed": 0,
		"applied_count": 0
	}


static func choose_stance(stances: Dictionary, analysis_value, retry_seed: int) -> Dictionary:
	var analysis: Dictionary = analysis_value.duplicate(true) if analysis_value is Dictionary else {}
	var ordered_ids := stance_ids(stances)
	var best_id := ""
	var best_score := -INF
	for stance_id_value in ordered_ids:
		var stance_id := str(stance_id_value)
		var key := str(stances.get(stance_id, {}).get("analysis_key", ""))
		var score := float(analysis.get(key, 0.0))
		if score > best_score:
			best_score = score
			best_id = stance_id
	var result := default_adaptation()
	result["stance_id"] = best_id
	result["announced_day"] = 24
	result["locked"] = best_id != ""
	result["analysis"] = analysis
	result["retry_seed"] = retry_seed
	return result


static func normalize(value, stances: Dictionary) -> Dictionary:
	var result := default_adaptation()
	if not (value is Dictionary):
		return result
	for key in result.keys():
		if value.has(key) and typeof(value.get(key)) == typeof(result.get(key)):
			result[key] = value.get(key).duplicate(true) if value.get(key) is Dictionary else value.get(key)
	var stance_id := str(result.get("stance_id", ""))
	if stance_id != "" and not stances.has(stance_id):
		return default_adaptation()
	result["announced_day"] = maxi(0, int(result.get("announced_day", 0)))
	result["retry_seed"] = maxi(0, int(result.get("retry_seed", 0)))
	result["applied_count"] = maxi(0, int(result.get("applied_count", 0)))
	result["locked"] = stance_id != "" and bool(result.get("locked", false))
	return result


static func validate(stances: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if stances.size() != 4:
		errors.append("레온 자세는 정확히 4종이어야 합니다.")
	var seen_keys: Dictionary = {}
	for stance_id_value in stance_ids(stances):
		var stance_id := str(stance_id_value)
		var stance = stances.get(stance_id)
		if not (stance is Dictionary):
			errors.append("레온 자세 자료가 사전 형식이 아닙니다: %s" % stance_id)
			continue
		var key := str(stance.get("analysis_key", ""))
		if key not in STANCE_KEYS or seen_keys.has(key):
			errors.append("레온 자세 분석 기준이 중복되거나 올바르지 않습니다: %s" % stance_id)
		seen_keys[key] = true
		if not (stance.get("effects") is Dictionary) or stance.get("effects", {}).is_empty():
			errors.append("레온 자세에 실제 전투 효과가 없습니다: %s" % stance_id)
		for text_key in ["display_name", "analysis_notice", "combat_notice", "weakness_notice"]:
			if str(stance.get(text_key, "")) == "":
				errors.append("레온 자세 안내 문구가 없습니다: %s/%s" % [stance_id, text_key])
	return errors


static func stance_ids(stances: Dictionary) -> Array:
	var ids := stances.keys()
	ids.sort_custom(func(a, b): return int(stances[a].get("order", 0)) < int(stances[b].get("order", 0)))
	return ids
