extends RefCounted
class_name HeartChargePolicy

const MAX_CHARGE := 100
const DEDUPE_WINDOW_SECONDS := 0.2
const SOURCE_RULES := {
	"monster_damage_absorbed": {"threshold": 20, "gain": 2},
	"facility_damage_taken": {"threshold": 15, "gain": 2},
	"facility_repaired": {"threshold": 10, "gain": 3}
}


static func apply(heart_value: Dictionary, source_id: String, amount: int, event_token: String, time_seconds: float) -> Dictionary:
	var heart := heart_value.duplicate(true)
	if not SOURCE_RULES.has(source_id) or amount <= 0:
		return {"heart": heart, "gain": 0, "duplicate": false}
	var bucket := int(floor(maxf(0.0, time_seconds) / DEDUPE_WINDOW_SECONDS))
	var dedupe: Dictionary = heart.get("battle_charge_dedupe", {}).duplicate(true)
	var target_token := event_token if event_token != "" else source_id
	var dedupe_key := "%s:%s:%d" % [source_id, target_token, bucket]
	if dedupe.has(dedupe_key):
		return {"heart": heart, "gain": 0, "duplicate": true}
	dedupe[dedupe_key] = true
	heart["battle_charge_dedupe"] = dedupe
	var rule: Dictionary = SOURCE_RULES[source_id]
	var gain := int(floor(float(amount) / float(rule["threshold"]))) * int(rule["gain"])
	var before := int(heart.get("charge", 0))
	heart["charge"] = clampi(before + gain, 0, MAX_CHARGE)
	return {"heart": heart, "gain": int(heart["charge"]) - before, "duplicate": false}
