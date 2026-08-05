extends SceneTree

const UNIT_PATH := "res://scripts/units/Unit.gd"
const COMBAT_PATH := "res://scripts/game/CombatSceneController.gd"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var unit_source := _read_source(UNIT_PATH)
	var combat_source := _read_source(COMBAT_PATH)
	var checks: Array[String] = [
		_check(unit_source.contains("func combat_anchor_local(anchor_name: String) -> Vector2"), "Unit provides local foot/body/head anchors"),
		_check(unit_source.contains("func combat_anchor_global(anchor_name: String) -> Vector2"), "Unit provides global anchor conversion"),
		_check(unit_source.contains("func debug_ui_anchor_contract() -> Dictionary"), "Unit exposes the anchor contract for inspection"),
		_check(unit_source.contains('"name_anchor": "head"') and unit_source.contains('"hp_anchor": "head"') and unit_source.contains('"damage_anchor": "head"'), "name HP damage share the head anchor"),
		_check(unit_source.contains('combat_anchor_local("head") + COMBAT_NAME_ANCHOR_OFFSET'), "Unit name label consumes the head anchor"),
		_check(unit_source.contains('combat_anchor_local("head") + COMBAT_HP_ANCHOR_OFFSET'), "Unit HP bar consumes the head anchor"),
		_check(unit_source.contains("_refresh_combat_ui_anchors()"), "UI anchors refresh after visual pose changes"),
		_check(unit_source.contains("visual_body.position = pose_position"), "Anchor body follows the resolved visual pose"),
		_check(combat_source.contains("func spawn_damage_number(position: Vector2, damage: int, target_faction: String, anchor_target = null) -> void"), "Damage number accepts an anchor target"),
		_check(combat_source.contains('anchor_target.combat_anchor_global("head")'), "Damage number consumes the target head anchor"),
		_check(combat_source.contains("spawn_damage_number(target.global_position, damage, target.faction, target)"), "Combat hit feedback passes the target to damage number"),
		_check(combat_source.contains("damage_label.position = anchor_position + Vector2") and not combat_source.contains("position + Vector2(-label_size.x * 0.5, -112.0"), "Fixed unit-origin damage offset is removed")
	]
	var failures := checks.filter(func(result: String) -> bool: return result.begins_with("FAIL"))
	if failures.is_empty():
		print("V122_V4_B_UI_ANCHOR_CONTRACT_TEST: PASS (%d checks)" % checks.size())
	else:
		for failure in failures:
			push_error(failure)
		print("V122_V4_B_UI_ANCHOR_CONTRACT_TEST: FAIL (%d/%d failed)" % [failures.size(), checks.size()])
		quit(1)
		return
	quit(0)

func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _check(condition: bool, label: String) -> String:
	return "PASS: %s" % label if condition else "FAIL: %s" % label
