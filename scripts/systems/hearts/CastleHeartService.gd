extends RefCounted
class_name CastleHeartService

const ChargePolicyScript = preload("res://scripts/systems/hearts/HeartChargePolicy.gd")
const STONEBONE_ID := "heart_stonebone"
const HUNGRY_MAW_ID := "heart_hungry_maw"
const DREAM_LANTERN_ID := "heart_dream_lantern"
const ACTIVE_SKILL_ID := "castle_brace"
const HUNGRY_ACTIVE_SKILL_ID := "devouring_corridor"
const DREAM_ACTIVE_SKILL_ID := "false_corridor"
const PASSIVE_DAMAGE_SCALE := 0.88
const REPAIR_SCALE := 1.25
const ACTIVE_SECONDS := 6.0
const ACTIVE_ROOM_SHIELD := 45
const ACTIVE_MONSTER_DAMAGE_SCALE := 0.88
const HUNGER_REQUIRED := 5
const HUNGER_WAVE_LIMIT := 3
const HUNGER_WAVE_DAMAGE := 12
const HUNGER_WAVE_BOSS_DAMAGE := 6
const HUNGER_WAVE_MORALE_DAMAGE := 8
const HUNGER_WAVE_INFAMY := 3
const HUNGRY_HEAL_SCALE := 0.92
const HUNGRY_DAILY_FOOD_COST := 2
const HUNGRY_ACTIVE_SECONDS := 5.0
const HUNGRY_ACTIVE_DAMAGE_PER_SECOND := 6
const HUNGRY_ACTIVE_SLOW_SCALE := 0.85
const HUNGRY_ACTIVE_BOSS_SLOW_SCALE := 0.92
const HUNGRY_ACTIVE_THRONE_COST := 35
const DREAM_SKILL_COOLDOWN_SCALE := 0.92
const DREAM_FIRST_CONTROL_SCALE := 1.15
const DREAM_THRONE_MAX_HP_SCALE := 0.90
const DREAM_CHAMBER_MAX_HP_SCALE := 0.85
const DREAM_ACTIVE_SECONDS := 6.0
const DREAM_BOSS_SLOW_SECONDS := 3.0
const DREAM_BOSS_SLOW_SCALE := 0.88


static func select_heart(profile: Dictionary, active_run_value: Dictionary, heart_id: String, catalog: Dictionary) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	if not catalog.has(heart_id):
		return {"ok": false, "error": "존재하지 않는 마왕성 심장 ID입니다: %s" % heart_id, "active_run": active_run}
	if not profile.get("hearts", {}).get("unlocked", []).has(heart_id):
		return {"ok": false, "error": "아직 해금되지 않은 마왕성 심장입니다.", "active_run": active_run}
	var current_id := str(active_run.get("heart", {}).get("heart_id", ""))
	if current_id != "" and current_id != heart_id:
		return {"ok": false, "error": "이 회차에서 선택한 심장은 변경할 수 없습니다.", "active_run": active_run}
	var heart := _normalized_heart(active_run.get("heart", {}))
	heart["heart_id"] = heart_id
	active_run["heart"] = heart
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	if not metrics.has("selected_heart_mastery_before_run"):
		metrics["selected_heart_mastery_before_run"] = int(profile.get("hearts", {}).get("mastery", {}).get(heart_id, 0))
	active_run["run_metrics_update3"] = metrics
	active_run["heart_event_candidate_id"] = str(catalog.get(heart_id, {}).get("event_candidate_id", ""))
	active_run["update3_enabled"] = true
	return {"ok": true, "error": "", "active_run": active_run, "profile": ensure_mastery_record(profile, heart_id)}


static func ensure_mastery_record(profile_value: Dictionary, heart_id: String) -> Dictionary:
	var profile := profile_value.duplicate(true)
	var hearts: Dictionary = profile.get("hearts", {}).duplicate(true)
	var records: Dictionary = hearts.get("records", {}).duplicate(true)
	if not records.has(heart_id) or not (records.get(heart_id) is Dictionary):
		records[heart_id] = {
			"selected_count": 0,
			"first_clear": false,
			"active_uses": 0,
			"day30_no_chamber_disable": false
		}
	var record: Dictionary = records[heart_id].duplicate(true)
	record["selected_count"] = int(record.get("selected_count", 0)) + 1
	records[heart_id] = record
	hearts["records"] = records
	profile["hearts"] = hearts
	return _refresh_mastery_score(profile, heart_id)


static func record_active_use(profile_value: Dictionary, active_run_value: Dictionary) -> Dictionary:
	var profile := profile_value.duplicate(true)
	var active_run := active_run_value.duplicate(true)
	var heart_id := str(active_run.get("heart", {}).get("heart_id", ""))
	if heart_id == "":
		return {"profile": profile, "active_run": active_run}
	var hearts: Dictionary = profile.get("hearts", {}).duplicate(true)
	var records: Dictionary = hearts.get("records", {}).duplicate(true)
	var record: Dictionary = records.get(heart_id, {}).duplicate(true)
	record["selected_count"] = maxi(1, int(record.get("selected_count", 0)))
	record["first_clear"] = bool(record.get("first_clear", false))
	record["active_uses"] = int(record.get("active_uses", 0)) + 1
	record["day30_no_chamber_disable"] = bool(record.get("day30_no_chamber_disable", false))
	records[heart_id] = record
	hearts["records"] = records
	profile["hearts"] = hearts
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_active_uses"] = int(metrics.get("heart_active_uses", 0)) + 1
	active_run["run_metrics_update3"] = metrics
	return {"profile": _refresh_mastery_score(profile, heart_id), "active_run": active_run}


static func record_chamber_disabled(active_run_value: Dictionary) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_chamber_disable_count"] = int(metrics.get("heart_chamber_disable_count", 0)) + 1
	active_run["run_metrics_update3"] = metrics
	return active_run


static func record_campaign_clear(profile_value: Dictionary, active_run_value: Dictionary) -> Dictionary:
	var profile := profile_value.duplicate(true)
	var heart_id := str(active_run_value.get("heart", {}).get("heart_id", ""))
	if heart_id == "":
		return profile
	var hearts: Dictionary = profile.get("hearts", {}).duplicate(true)
	var records: Dictionary = hearts.get("records", {}).duplicate(true)
	var record: Dictionary = records.get(heart_id, {}).duplicate(true)
	record["selected_count"] = maxi(1, int(record.get("selected_count", 0)))
	record["first_clear"] = true
	record["active_uses"] = int(record.get("active_uses", 0))
	if int(active_run_value.get("run_metrics_update3", {}).get("heart_chamber_disable_count", 0)) == 0:
		record["day30_no_chamber_disable"] = true
	records[heart_id] = record
	hearts["records"] = records
	profile["hearts"] = hearts
	return _refresh_mastery_score(profile, heart_id)


static func _refresh_mastery_score(profile_value: Dictionary, heart_id: String) -> Dictionary:
	var profile := profile_value.duplicate(true)
	var hearts: Dictionary = profile.get("hearts", {}).duplicate(true)
	var records: Dictionary = hearts.get("records", {})
	var record: Dictionary = records.get(heart_id, {})
	var score := 0
	if bool(record.get("first_clear", false)):
		score += 33
	if int(record.get("active_uses", 0)) >= 10:
		score += 33
	if bool(record.get("day30_no_chamber_disable", false)):
		score += 34
	var mastery: Dictionary = hearts.get("mastery", {}).duplicate(true)
	mastery[heart_id] = score
	hearts["mastery"] = mastery
	profile["hearts"] = hearts
	return profile


static func awaken(active_run_value: Dictionary, day: int) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	var awakened_now := false
	if str(heart.get("heart_id", "")) != "" and day >= 4 and not bool(heart.get("awakened", false)):
		heart["awakened"] = true
		heart["awakened_day"] = day
		awakened_now = true
	active_run["heart"] = heart
	return {"active_run": active_run, "awakened_now": awakened_now}


static func start_battle(active_run_value: Dictionary, battle_id: String, stage_index: int) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	heart["active_used_this_battle"] = false
	heart["active_remaining"] = 0.0
	heart["room_shields"] = {}
	heart["battle_charge_dedupe"] = {}
	heart["battle_id"] = battle_id
	heart["hunger"] = 0
	heart["hunger_waves"] = 0
	heart["hunger_finish_ids"] = {}
	heart["hungry_damage_tokens"] = {}
	heart["hungry_infamy_earned"] = 0
	heart["active_room_id"] = ""
	heart["active_tick_accumulator"] = 0.0
	heart["dream_charge_dedupe"] = {}
	heart["false_corridor_targets"] = {}
	heart["charge_suppressed_remaining"] = 0.0
	heart["debt_disabled_remaining"] = 0.0
	heart["active_locked_remaining"] = 0.0
	if bool(heart.get("chamber_spawned", false)) and stage_index >= 2:
		heart["chamber_hp"] = int(heart.get("chamber_max_hp", 0))
		heart["disabled_this_battle"] = false
	active_run["heart"] = heart
	return active_run


static func passive_active(active_run: Dictionary) -> bool:
	var heart: Dictionary = active_run.get("heart", {})
	return str(heart.get("heart_id", "")) == STONEBONE_ID and _heart_available(heart)


static func hungry_active(active_run: Dictionary) -> bool:
	var heart: Dictionary = active_run.get("heart", {})
	return str(heart.get("heart_id", "")) == HUNGRY_MAW_ID and _heart_available(heart)


static func dream_active(active_run: Dictionary) -> bool:
	var heart: Dictionary = active_run.get("heart", {})
	return str(heart.get("heart_id", "")) == DREAM_LANTERN_ID and _heart_available(heart)


static func _heart_available(heart: Dictionary) -> bool:
	return bool(heart.get("awakened", false)) \
		and not bool(heart.get("disabled_this_battle", false)) \
		and float(heart.get("debt_disabled_remaining", 0.0)) <= 0.0


static func apply_debt_disable_and_lock(active_run_value: Dictionary, disable_seconds: float, lock_seconds: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	heart["debt_disabled_remaining"] = maxf(float(heart.get("debt_disabled_remaining", 0.0)), maxf(0.0, disable_seconds))
	heart["active_locked_remaining"] = maxf(float(heart.get("active_locked_remaining", 0.0)), maxf(0.0, lock_seconds))
	active_run["heart"] = heart
	return active_run


static func active_locked(active_run: Dictionary) -> bool:
	return float(active_run.get("heart", {}).get("active_locked_remaining", 0.0)) > 0.0


static func suppress_charge(active_run_value: Dictionary, seconds: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	heart["charge_suppressed_remaining"] = maxf(float(heart.get("charge_suppressed_remaining", 0.0)), maxf(0.0, seconds))
	active_run["heart"] = heart
	return active_run


static func charge_suppressed(active_run: Dictionary) -> bool:
	return float(active_run.get("heart", {}).get("charge_suppressed_remaining", 0.0)) > 0.0


static func charge_gain_multiplier(active_run: Dictionary) -> float:
	return clampf(float(active_run.get("heart", {}).get("charge_gain_multiplier", 1.0)), 0.0, 1.0)


static func record_charge(active_run_value: Dictionary, source_id: String, amount: int, event_token: String, time_seconds: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	if not passive_active(active_run) or bool(active_run.get("heart", {}).get("disabled_this_battle", false)):
		return {"active_run": active_run, "gain": 0, "duplicate": false}
	if charge_suppressed(active_run):
		return {"active_run": active_run, "gain": 0, "duplicate": false, "suppressed": true}
	var adjusted_amount := int(floor(float(amount) * charge_gain_multiplier(active_run)))
	var charged := ChargePolicyScript.apply(active_run.get("heart", {}), source_id, adjusted_amount, event_token, time_seconds)
	active_run["heart"] = charged.get("heart", {}).duplicate(true)
	var gain := int(charged.get("gain", 0))
	if gain > 0:
		var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
		metrics["heart_charge_gained"] = int(metrics.get("heart_charge_gained", 0)) + gain
		active_run["run_metrics_update3"] = metrics
	return {"active_run": active_run, "gain": gain, "duplicate": bool(charged.get("duplicate", false))}


static func record_hungry_damage(active_run_value: Dictionary, actual_damage: int, attack_token: String) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	if not hungry_active(active_run) or actual_damage <= 0:
		return {"active_run": active_run, "gain": 0, "duplicate": false}
	var heart := _normalized_heart(active_run.get("heart", {}))
	var tokens: Dictionary = heart.get("hungry_damage_tokens", {}).duplicate(true)
	var token := attack_token if attack_token != "" else "damage_%d" % tokens.size()
	if tokens.has(token):
		return {"active_run": active_run, "gain": 0, "duplicate": true}
	tokens[token] = true
	heart["hungry_damage_tokens"] = tokens
	var gain := 0 if charge_suppressed(active_run) else int(floor(float(int(floor(float(actual_damage) / 35.0)) * 2) * charge_gain_multiplier(active_run)))
	var before := int(heart.get("charge", 0))
	heart["charge"] = clampi(before + gain, 0, ChargePolicyScript.MAX_CHARGE)
	active_run["heart"] = heart
	_record_charge_metric(active_run, int(heart["charge"]) - before)
	return {"active_run": active_run, "gain": int(heart["charge"]) - before, "duplicate": false}


static func record_hungry_finish(active_run_value: Dictionary, enemy_token: String) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	if not hungry_active(active_run) or enemy_token == "":
		return {"active_run": active_run, "counted": false, "wave": false, "infamy": 0, "charge_gain": 0}
	var heart := _normalized_heart(active_run.get("heart", {}))
	var finish_ids: Dictionary = heart.get("hunger_finish_ids", {}).duplicate(true)
	if finish_ids.has(enemy_token):
		return {"active_run": active_run, "counted": false, "wave": false, "infamy": 0, "charge_gain": 0}
	finish_ids[enemy_token] = true
	heart["hunger_finish_ids"] = finish_ids
	var charge_before := int(heart.get("charge", 0))
	var allow_charge := not charge_suppressed(active_run)
	heart["charge"] = clampi(charge_before + (int(floor(6.0 * charge_gain_multiplier(active_run))) if allow_charge else 0), 0, ChargePolicyScript.MAX_CHARGE)
	var wave := false
	var infamy := 0
	if int(heart.get("hunger_waves", 0)) < HUNGER_WAVE_LIMIT:
		heart["hunger"] = int(heart.get("hunger", 0)) + 1
		if int(heart["hunger"]) >= HUNGER_REQUIRED:
			heart["hunger"] = int(heart["hunger"]) - HUNGER_REQUIRED
			heart["hunger_waves"] = int(heart.get("hunger_waves", 0)) + 1
			heart["charge"] = clampi(int(heart["charge"]) + (int(floor(8.0 * charge_gain_multiplier(active_run))) if allow_charge else 0), 0, ChargePolicyScript.MAX_CHARGE)
			heart["hungry_infamy_earned"] = mini(HUNGER_WAVE_LIMIT * HUNGER_WAVE_INFAMY, int(heart.get("hungry_infamy_earned", 0)) + HUNGER_WAVE_INFAMY)
			wave = true
			infamy = HUNGER_WAVE_INFAMY
	else:
		heart["hunger"] = mini(HUNGER_REQUIRED - 1, int(heart.get("hunger", 0)))
	active_run["heart"] = heart
	var charge_gain := int(heart["charge"]) - charge_before
	_record_charge_metric(active_run, charge_gain)
	if wave:
		var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
		metrics["hungry_waves"] = int(metrics.get("hungry_waves", 0)) + 1
		metrics["hungry_infamy"] = int(metrics.get("hungry_infamy", 0)) + infamy
		active_run["run_metrics_update3"] = metrics
	return {"active_run": active_run, "counted": true, "wave": wave, "infamy": infamy, "charge_gain": charge_gain}


static func healing_multiplier(active_run: Dictionary) -> float:
	return HUNGRY_HEAL_SCALE if hungry_active(active_run) else 1.0


static func skill_recovery_multiplier(active_run: Dictionary) -> float:
	return 1.0 / DREAM_SKILL_COOLDOWN_SCALE if dream_active(active_run) else 1.0


static func first_control_multiplier(active_run: Dictionary) -> float:
	return DREAM_FIRST_CONTROL_SCALE if dream_active(active_run) else 1.0


static func record_dream_charge(active_run_value: Dictionary, source_id: String, event_token: String) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	if not dream_active(active_run) or source_id not in ["skill_hit", "effective_heal", "first_status", "goal_changed"]:
		return {"active_run": active_run, "gain": 0, "duplicate": false}
	var heart := _normalized_heart(active_run.get("heart", {}))
	var dedupe: Dictionary = heart.get("dream_charge_dedupe", {}).duplicate(true)
	var token := "%s:%s" % [source_id, event_token]
	if event_token != "" and dedupe.has(token):
		return {"active_run": active_run, "gain": 0, "duplicate": true}
	if event_token != "":
		dedupe[token] = true
	heart["dream_charge_dedupe"] = dedupe
	var gain_by_source := {"skill_hit": 3, "effective_heal": 3, "first_status": 5, "goal_changed": 8}
	var before := int(heart.get("charge", 0))
	var gain := 0 if charge_suppressed(active_run) else int(floor(float(gain_by_source[source_id]) * charge_gain_multiplier(active_run)))
	heart["charge"] = clampi(before + gain, 0, ChargePolicyScript.MAX_CHARGE)
	active_run["heart"] = heart
	var applied_gain := int(heart["charge"]) - before
	_record_charge_metric(active_run, applied_gain)
	return {"active_run": active_run, "gain": applied_gain, "duplicate": false, "suppressed": gain <= 0}


static func apply_dream_max_hp(active_run_value: Dictionary, throne_hp: int, throne_max_hp: int, chamber_base_max_hp: int = 0) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	if str(heart.get("heart_id", "")) != DREAM_LANTERN_ID or not bool(heart.get("awakened", false)):
		return {"active_run": active_run, "throne_hp": throne_hp, "throne_max_hp": throne_max_hp}
	var saved_adjusted := int(heart.get("dream_adjusted_throne_max_hp", 0))
	var saved_base := int(heart.get("dream_base_throne_max_hp", 0))
	var base := saved_base if saved_adjusted > 0 and throne_max_hp == saved_adjusted else maxi(1, throne_max_hp)
	var adjusted := maxi(1, int(floor(float(base) * DREAM_THRONE_MAX_HP_SCALE)))
	heart["dream_base_throne_max_hp"] = base
	heart["dream_adjusted_throne_max_hp"] = adjusted
	if chamber_base_max_hp > 0 and bool(heart.get("chamber_spawned", false)):
		var old_chamber_max := maxi(1, int(heart.get("chamber_max_hp", chamber_base_max_hp)))
		var chamber_ratio := float(heart.get("chamber_hp", old_chamber_max)) / float(old_chamber_max)
		var chamber_adjusted := maxi(1, int(floor(float(chamber_base_max_hp) * DREAM_CHAMBER_MAX_HP_SCALE)))
		heart["chamber_max_hp"] = chamber_adjusted
		heart["chamber_hp"] = clampi(int(round(chamber_ratio * float(chamber_adjusted))), 0, chamber_adjusted)
	active_run["heart"] = heart
	return {"active_run": active_run, "throne_hp": mini(throne_hp, adjusted), "throne_max_hp": adjusted}


static func apply_daily_upkeep(active_run_value: Dictionary, day: int, food: int) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	if str(heart.get("heart_id", "")) != HUNGRY_MAW_ID or not bool(heart.get("awakened", false)) or day <= int(heart.get("last_upkeep_day", 0)):
		return {"active_run": active_run, "food": food, "paid": 0}
	var paid := mini(HUNGRY_DAILY_FOOD_COST, maxi(0, food))
	heart["last_upkeep_day"] = day
	active_run["heart"] = heart
	return {"active_run": active_run, "food": maxi(0, food - HUNGRY_DAILY_FOOD_COST), "paid": paid}


static func apply_room_damage(active_run_value: Dictionary, room_id: String, raw_damage: int, event_token: String, time_seconds: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	var remaining := maxi(0, raw_damage)
	var shields: Dictionary = heart.get("room_shields", {}).duplicate(true)
	var shield_before := int(shields.get(room_id, 0))
	var shield_absorbed := mini(shield_before, remaining)
	remaining -= shield_absorbed
	shields[room_id] = shield_before - shield_absorbed
	heart["room_shields"] = shields
	var reduced := 0
	if passive_active(active_run) and remaining > 0:
		var modified := maxi(1, int(round(float(remaining) * PASSIVE_DAMAGE_SCALE)))
		reduced = remaining - modified
		remaining = modified
	active_run["heart"] = heart
	var charged := record_charge(active_run, "facility_damage_taken", remaining, event_token, time_seconds)
	active_run = charged.get("active_run", active_run)
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["stonebone_facility_damage_reduced"] = int(metrics.get("stonebone_facility_damage_reduced", 0)) + reduced + shield_absorbed
	metrics["heart_metric_contribution"] = int(metrics.get("heart_metric_contribution", 0)) + reduced + shield_absorbed
	active_run["run_metrics_update3"] = metrics
	return {"active_run": active_run, "damage": remaining, "reduced": reduced, "shield_absorbed": shield_absorbed, "charge_gain": int(charged.get("gain", 0))}


static func apply_repair(active_run_value: Dictionary, raw_repair: int, event_token: String, time_seconds: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var repaired := maxi(0, raw_repair)
	var bonus := 0
	if passive_active(active_run):
		var modified := int(round(float(repaired) * REPAIR_SCALE))
		bonus = modified - repaired
		repaired = modified
	var charged := record_charge(active_run, "facility_repaired", repaired, event_token, time_seconds)
	active_run = charged.get("active_run", active_run)
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["stonebone_repair_bonus"] = int(metrics.get("stonebone_repair_bonus", 0)) + bonus
	active_run["run_metrics_update3"] = metrics
	return {"active_run": active_run, "repair": repaired, "bonus": bonus, "charge_gain": int(charged.get("gain", 0))}


static func activate(active_run_value: Dictionary, active_room_ids: Array, target_room_id: String = "", throne_hp: int = 0, dream_targets: Array = []) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	if float(heart.get("active_locked_remaining", 0.0)) > 0.0:
		return {"ok": false, "error": "부채 표식 때문에 심장 액티브가 %.1f초 잠겼습니다." % float(heart.get("active_locked_remaining", 0.0)), "active_run": active_run}
	if hungry_active(active_run):
		return _activate_hungry(active_run, heart, target_room_id, throne_hp)
	if dream_active(active_run):
		return _activate_dream(active_run, heart, target_room_id, dream_targets)
	if not passive_active(active_run):
		return {"ok": false, "error": "선택한 심장이 비활성 상태입니다.", "active_run": active_run}
	if bool(heart.get("active_used_this_battle", false)):
		return {"ok": false, "error": "심장 액티브는 전투당 1회만 사용할 수 있습니다.", "active_run": active_run}
	if int(heart.get("charge", 0)) < ChargePolicyScript.MAX_CHARGE:
		return {"ok": false, "error": "심장 충전도가 100이 아닙니다.", "active_run": active_run}
	var shields: Dictionary = {}
	for room_id_value in active_room_ids:
		var room_id := str(room_id_value)
		if room_id != "":
			shields[room_id] = ACTIVE_ROOM_SHIELD
	heart["charge"] = 0
	heart["active_used_this_battle"] = true
	heart["active_remaining"] = ACTIVE_SECONDS
	heart["room_shields"] = shields
	active_run["heart"] = heart
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_active_uses"] = int(metrics.get("heart_active_uses", 0)) + 1
	active_run["run_metrics_update3"] = metrics
	return {"ok": true, "error": "", "active_run": active_run, "skill_id": ACTIVE_SKILL_ID, "shielded_rooms": shields.size()}


static func _activate_hungry(active_run: Dictionary, heart: Dictionary, target_room_id: String, throne_hp: int) -> Dictionary:
	if bool(heart.get("active_used_this_battle", false)):
		return {"ok": false, "error": "심장 액티브는 전투당 1회만 사용할 수 있습니다.", "active_run": active_run}
	if int(heart.get("charge", 0)) < ChargePolicyScript.MAX_CHARGE:
		return {"ok": false, "error": "심장 충전도가 100이 아닙니다.", "active_run": active_run}
	if target_room_id == "":
		return {"ok": false, "error": "포식할 방을 선택해야 합니다.", "active_run": active_run}
	if throne_hp < HUNGRY_ACTIVE_THRONE_COST + 1:
		return {"ok": false, "error": "왕좌 HP가 36 미만이라 포식 복도를 사용할 수 없습니다.", "active_run": active_run}
	heart["charge"] = 0
	heart["active_used_this_battle"] = true
	heart["active_remaining"] = HUNGRY_ACTIVE_SECONDS
	heart["active_room_id"] = target_room_id
	heart["active_tick_accumulator"] = 0.0
	active_run["heart"] = heart
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_active_uses"] = int(metrics.get("heart_active_uses", 0)) + 1
	metrics["hungry_throne_hp_spent"] = int(metrics.get("hungry_throne_hp_spent", 0)) + HUNGRY_ACTIVE_THRONE_COST
	active_run["run_metrics_update3"] = metrics
	return {"ok": true, "error": "", "active_run": active_run, "skill_id": HUNGRY_ACTIVE_SKILL_ID, "target_room_id": target_room_id, "throne_hp": throne_hp - HUNGRY_ACTIVE_THRONE_COST}


static func _activate_dream(active_run: Dictionary, heart: Dictionary, target_room_id: String, target_entries: Array) -> Dictionary:
	if bool(heart.get("active_used_this_battle", false)):
		return {"ok": false, "error": "심장 액티브는 전투당 1회만 사용할 수 있습니다.", "active_run": active_run}
	if int(heart.get("charge", 0)) < ChargePolicyScript.MAX_CHARGE:
		return {"ok": false, "error": "심장 충전도가 100이 아닙니다.", "active_run": active_run}
	if target_room_id == "":
		return {"ok": false, "error": "미끼 방을 선택해야 합니다.", "active_run": active_run}
	if target_entries.is_empty() or target_entries.size() > 2:
		return {"ok": false, "error": "가짜 복도는 적 1~2명에게 사용해야 합니다.", "active_run": active_run}
	var stored: Dictionary = {}
	var changed := 0
	for entry_value in target_entries:
		if not (entry_value is Dictionary):
			continue
		var entry: Dictionary = entry_value
		var token := str(entry.get("token", ""))
		if token == "":
			continue
		var boss := bool(entry.get("boss", false))
		stored[token] = {
			"original_goal": str(entry.get("original_goal", "")), "bait_room": target_room_id,
			"remaining": DREAM_BOSS_SLOW_SECONDS if boss else DREAM_ACTIVE_SECONDS,
			"boss": boss, "unit_id": str(entry.get("unit_id", ""))
		}
		if not boss:
			changed += 1
	heart["charge"] = 0
	heart["active_used_this_battle"] = true
	heart["active_remaining"] = DREAM_ACTIVE_SECONDS
	heart["active_room_id"] = target_room_id
	heart["false_corridor_targets"] = stored
	active_run["heart"] = heart
	for entry_value in target_entries:
		if entry_value is Dictionary and not bool(entry_value.get("boss", false)):
			var charged := record_dream_charge(active_run, "goal_changed", str(entry_value.get("token", "")))
			active_run = charged.get("active_run", active_run)
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_active_uses"] = int(metrics.get("heart_active_uses", 0)) + 1
	metrics["dream_goal_changes"] = int(metrics.get("dream_goal_changes", 0)) + changed
	active_run["run_metrics_update3"] = metrics
	return {"ok": true, "error": "", "active_run": active_run, "skill_id": DREAM_ACTIVE_SKILL_ID, "target_room_id": target_room_id, "target_count": stored.size(), "goal_changes": changed}


static func tick(active_run_value: Dictionary, delta: float) -> Dictionary:
	return tick_events(active_run_value, delta).get("active_run", active_run_value).duplicate(true)


static func tick_events(active_run_value: Dictionary, delta: float) -> Dictionary:
	var active_run := active_run_value.duplicate(true)
	var heart := _normalized_heart(active_run.get("heart", {}))
	var before := float(heart.get("active_remaining", 0.0))
	var step := minf(before, maxf(0.0, delta))
	var pulse_count := 0
	var dream_restore_entries: Array[Dictionary] = []
	if hungry_active(active_run) and before > 0.0:
		var carry := float(heart.get("active_tick_accumulator", 0.0)) + step
		pulse_count = int(floor(carry))
		heart["active_tick_accumulator"] = carry - float(pulse_count)
	heart["active_remaining"] = maxf(0.0, before - maxf(0.0, delta))
	heart["charge_suppressed_remaining"] = maxf(0.0, float(heart.get("charge_suppressed_remaining", 0.0)) - maxf(0.0, delta))
	heart["debt_disabled_remaining"] = maxf(0.0, float(heart.get("debt_disabled_remaining", 0.0)) - maxf(0.0, delta))
	heart["active_locked_remaining"] = maxf(0.0, float(heart.get("active_locked_remaining", 0.0)) - maxf(0.0, delta))
	if dream_active(active_run):
		var false_targets: Dictionary = heart.get("false_corridor_targets", {}).duplicate(true)
		for token_value in false_targets.keys():
			var token := str(token_value)
			var entry: Dictionary = false_targets[token].duplicate(true)
			entry["remaining"] = maxf(0.0, float(entry.get("remaining", 0.0)) - maxf(0.0, delta))
			if float(entry["remaining"]) <= 0.0:
				entry["token"] = token
				dream_restore_entries.append(entry)
				false_targets.erase(token)
			else:
				false_targets[token] = entry
		heart["false_corridor_targets"] = false_targets
	if float(heart["active_remaining"]) <= 0.0:
		heart["room_shields"] = {}
	active_run["heart"] = heart
	return {"active_run": active_run, "hungry_pulses": pulse_count, "target_room_id": str(heart.get("active_room_id", "")), "dream_restore_entries": dream_restore_entries}


static func monster_damage(active_run: Dictionary, raw_damage: int, inside_room: bool) -> Dictionary:
	var damage := maxi(0, raw_damage)
	if not passive_active(active_run) or not inside_room or float(active_run.get("heart", {}).get("active_remaining", 0.0)) <= 0.0:
		return {"damage": damage, "reduced": 0}
	var modified := maxi(1, int(round(float(damage) * ACTIVE_MONSTER_DAMAGE_SCALE)))
	return {"damage": modified, "reduced": damage - modified}


static func _normalized_heart(value) -> Dictionary:
	var heart: Dictionary = value.duplicate(true) if value is Dictionary else {}
	var defaults := {
		"heart_id": "", "awakened": false, "awakened_day": 0, "chamber_spawned": false,
		"chamber_hp": 0, "chamber_max_hp": 0, "disabled_this_battle": false,
		"charge": 0, "active_used_this_battle": false, "active_remaining": 0.0,
		"room_shields": {}, "battle_charge_dedupe": {}, "battle_id": "",
		"hunger": 0, "hunger_waves": 0, "hunger_finish_ids": {}, "hungry_damage_tokens": {},
		"hungry_infamy_earned": 0, "active_room_id": "", "active_tick_accumulator": 0.0,
		"last_upkeep_day": 0, "charge_suppressed_remaining": 0.0,
		"debt_disabled_remaining": 0.0, "active_locked_remaining": 0.0
		,"dream_charge_dedupe": {}, "false_corridor_targets": {},
		"dream_base_throne_max_hp": 0, "dream_adjusted_throne_max_hp": 0
	}
	for key in defaults.keys():
		if not heart.has(key):
			heart[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary else defaults[key]
	return heart


static func _record_charge_metric(active_run: Dictionary, gain: int) -> void:
	if gain <= 0:
		return
	var metrics: Dictionary = active_run.get("run_metrics_update3", {}).duplicate(true)
	metrics["heart_charge_gained"] = int(metrics.get("heart_charge_gained", 0)) + gain
	active_run["run_metrics_update3"] = metrics
