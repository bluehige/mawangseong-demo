extends RefCounted
class_name TutorialManager

const ACTION_BY_BLOCK = {
	"name_valid": "name_valid",
	"dialogue_closed": "dialogue_closed",
	"unit_selected": "unit_selected",
	"unit_deployed": "unit_deployed",
	"global_directive_set": "global_directive_set",
	"room_directive_set": "room_directive_set",
	"direct_control_once": "direct_control_once",
	"log_event_seen": "log_event_seen",
	"room_selected": "room_selected",
	"goblin_attacks_once": "goblin_attacks_once",
	"imp_casts_fireball": "imp_casts_fireball",
	"boss_hp_50": "boss_hp_50"
}

var steps: Array = []
var current_index := 0
var completed: Dictionary = {}
var active := false

func setup(step_rows: Array) -> void:
	steps.clear()
	completed.clear()
	current_index = 0
	for row in step_rows:
		if row is Dictionary:
			steps.append(row.duplicate(true))
	active = not steps.is_empty()

func reset() -> void:
	current_index = 0
	completed.clear()
	active = not steps.is_empty()

func current_step() -> Dictionary:
	if not active or current_index < 0 or current_index >= steps.size():
		return {}
	return steps[current_index]

func current_step_id() -> String:
	return str(current_step().get("id", ""))

func current_stage() -> String:
	return str(current_step().get("stage", ""))

func current_focus() -> String:
	return str(current_step().get("focus", ""))

func current_text() -> String:
	return str(current_step().get("text", ""))

func current_block_until() -> String:
	return str(current_step().get("block_until", ""))

func is_active_for_stage(stage_id: String) -> bool:
	return active and current_stage() == stage_id

func expected_action() -> String:
	return str(ACTION_BY_BLOCK.get(current_block_until(), ""))

func handle_action(action_id: String, payload: Dictionary = {}) -> bool:
	if not active:
		return false
	var step = current_step()
	if step.is_empty():
		return false
	if not _matches_step(step, action_id, payload):
		return false
	var step_id = str(step.get("id", ""))
	if step_id != "":
		completed[step_id] = true
	current_index += 1
	if current_index >= steps.size():
		active = false
	return true

func allows_action(action_id: String, payload: Dictionary = {}) -> bool:
	if not active:
		return true
	var step = current_step()
	if step.is_empty():
		return true
	var expected = expected_action()
	if expected == "":
		return true
	if action_id == expected and _payload_is_valid_for_step(step, action_id, payload):
		return true
	return _is_passive_allowed(action_id)

func _matches_step(step: Dictionary, action_id: String, payload: Dictionary) -> bool:
	var expected = str(ACTION_BY_BLOCK.get(str(step.get("block_until", "")), ""))
	if expected == "":
		return false
	if action_id != expected:
		return false
	return _payload_is_valid_for_step(step, action_id, payload)

func _payload_is_valid_for_step(step: Dictionary, action_id: String, payload: Dictionary) -> bool:
	var focus = str(step.get("focus", ""))
	match action_id:
		"name_valid", "dialogue_closed", "log_event_seen", "boss_hp_50":
			return true
		"direct_control_once":
			return str(payload.get("unit_id", "")) != ""
		"goblin_attacks_once":
			return str(payload.get("unit_id", "")) == "goblin"
		"imp_casts_fireball":
			return str(payload.get("unit_id", "")) == "imp" and str(payload.get("skill_id", "")) == "fireball"
		"unit_selected":
			if focus == "CHR_PUDDING":
				return str(payload.get("unit_id", payload.get("monster_id", ""))) == "slime"
			if focus == "CHR_GOB":
				return str(payload.get("unit_id", payload.get("monster_id", ""))) == "goblin"
			if focus == "CHR_PYNN":
				return str(payload.get("unit_id", payload.get("monster_id", ""))) == "imp"
			return true
		"unit_deployed":
			if focus == "ROOM_ENTRANCE":
				return str(payload.get("room_id", "")) == "entrance"
			return true
		"global_directive_set":
			if focus == "GLOBAL_DIRECTIVE_DEFEND":
				return str(payload.get("directive", "")) == "defense"
			return true
		"room_directive_set":
			if focus == "ROOM_DIRECTIVE_BLOCK_ENTRANCE":
				return str(payload.get("directive", "")) == "entry_block"
			if focus == "ROOM_DIRECTIVE_TRAP_LURE":
				return str(payload.get("directive", "")) == "trap_lure"
			if focus == "ROOM_DIRECTIVE_RETREAT_LINE":
				return str(payload.get("directive", "")) == "retreat"
			return true
		"room_selected":
			if focus == "ROOM_TREASURE":
				return str(payload.get("room_id", "")) == "treasure"
			if focus == "ROOM_RECOVERY_NEST":
				return str(payload.get("room_id", "")) == "recovery"
			return true
		_:
			return true

func _is_passive_allowed(action_id: String) -> bool:
	return action_id in [
		"screen_opened",
		"log_event_seen",
		"battle_finished",
		"enemy_spawned",
		"boss_hp_50"
	]
