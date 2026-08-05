class_name MusicStateResolver
extends RefCounted

const STATE_NONE := "none"
const STATE_TITLE := "title"
const STATE_MANAGEMENT := "management"
const STATE_COMBAT_NORMAL := "combat_normal"
const STATE_COMBAT_LATE_RISK := "combat_late_risk"
const STATE_COMBAT_BOSS := "combat_boss"
const STATE_FINAL_ENDING := "final_ending"

const EVENT_BY_STATE := {
	STATE_TITLE: "music.screen.title",
	STATE_MANAGEMENT: "music.screen.management",
	STATE_COMBAT_NORMAL: "music.combat.normal",
	STATE_COMBAT_LATE_RISK: "music.combat.late_risk",
	STATE_COMBAT_BOSS: "music.combat.boss",
	STATE_FINAL_ENDING: "music.final.ending"
}


static func resolve(context: Dictionary) -> String:
	var screen_name := str(context.get("screen", ""))
	var battle_screen := bool(context.get("battle_screen", false))
	if screen_name == "ending" or bool(context.get("final_victory", false)):
		return STATE_FINAL_ENDING
	if battle_screen:
		if bool(context.get("final_battle", false)):
			return STATE_FINAL_ENDING
		if bool(context.get("has_boss", false)):
			return STATE_COMBAT_BOSS
		if bool(context.get("high_risk", false)) or bool(context.get("late_wave", false)):
			return STATE_COMBAT_LATE_RISK
		return STATE_COMBAT_NORMAL
	if screen_name == "title":
		return STATE_TITLE
	if bool(context.get("management_screen", false)):
		return STATE_MANAGEMENT
	return STATE_NONE


static func event_for_state(state_id: String) -> String:
	return str(EVENT_BY_STATE.get(state_id, ""))


static func is_late_wave(next_index: int, total_to_spawn: int) -> bool:
	if total_to_spawn < 4:
		return false
	var late_start := int(ceil(float(total_to_spawn) * 0.70))
	return next_index >= late_start
