extends RefCounted
class_name HeartAutoProfilePolicy

const HEART_IDS := ["heart_stonebone", "heart_hungry_maw", "heart_dream_lantern"]


static func audit(profiles: Dictionary) -> Dictionary:
	var totals := {"heart_stonebone": 0.0, "heart_hungry_maw": 0.0, "heart_dream_lantern": 0.0}
	var lead_counts := {"heart_stonebone": 0, "heart_hungry_maw": 0, "heart_dream_lantern": 0}
	var errors: Array[String] = []
	for profile_id_value in profiles.keys():
		var profile_id := str(profile_id_value)
		var scores = profiles.get(profile_id, {}).get("estimated_completion", {})
		if not (scores is Dictionary):
			errors.append("%s: 예상 완주율 표가 없습니다." % profile_id)
			continue
		var best := -1.0
		for heart_id in HEART_IDS:
			if not scores.has(heart_id):
				errors.append("%s: %s 값이 없습니다." % [profile_id, heart_id])
				continue
			var score := float(scores.get(heart_id, 0.0))
			if score < 0.0 or score > 100.0:
				errors.append("%s: 예상 완주율은 0~100이어야 합니다." % profile_id)
			totals[heart_id] = float(totals[heart_id]) + score
			best = maxf(best, score)
		for heart_id in HEART_IDS:
			if is_equal_approx(float(scores.get(heart_id, -1.0)), best):
				lead_counts[heart_id] = int(lead_counts[heart_id]) + 1
	var averages: Dictionary = {}
	var lowest := 100.0
	var highest := 0.0
	for heart_id in HEART_IDS:
		var average := float(totals[heart_id]) / float(maxi(1, profiles.size()))
		averages[heart_id] = average
		lowest = minf(lowest, average)
		highest = maxf(highest, average)
	return {
		"ok": errors.is_empty() and highest - lowest < 10.0 and int(lead_counts.values().min()) > 0,
		"errors": errors,
		"averages": averages,
		"lead_counts": lead_counts,
		"average_gap": highest - lowest
	}
