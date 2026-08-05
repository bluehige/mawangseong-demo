extends Node

const GameRootScript = preload("res://scripts/game/GameRoot.gd")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var game = GameRootScript.new()
	game.monster_roster = {
		"moon_tracker": {"level": 1, "defense_enabled": true},
		"spore_healer": {"level": 1, "defense_enabled": true}
	}
	game.selected_contract_ids.append_array(["moon_tracker", "spore_healer"])
	game.contract_board_offer_ids.append_array(["moon_tracker", "spore_healer", "war_drummer", "mimic_porter"])
	game.contract_board_pending_ids.append_array(game.selected_contract_ids)
	game.deployed_instance_ids.append_array(["mon_contract_lumi", "mon_contract_mori"])

	game._sanitize_unready_contract_combat_assets()
	var available := game._available_update2_contracts()
	_expect(not available.has("moon_tracker"), "루미는 전용 전투 외형 전까지 신규 계약 후보에서 빠져야 한다")
	_expect(game.selected_contract_ids.has("moon_tracker"), "기존 저장의 루미 계약 기록은 보존해야 한다")
	_expect(not game.deployed_instance_ids.has("mon_contract_lumi"), "기존 저장의 루미는 방어 출전에서 제거해야 한다")
	_expect(not game._monster_available_for_defense("moon_tracker"), "루미는 잘못된 공유 이미지로 방어전에 나가면 안 된다")
	_expect(bool(game.monster_roster["moon_tracker"].get("combat_asset_pending", false)), "기존 루미 roster에 전투 외형 대기 상태를 남겨야 한다")
	_expect(game._monster_available_for_defense("spore_healer"), "준비된 다른 계약 몬스터는 방어 가능 상태를 유지해야 한다")
	game.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("V122_MOON_TRACKER_COMBAT_ASSET_GATE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_MOON_TRACKER_COMBAT_ASSET_GATE_TEST: FAIL")
	get_tree().quit(1)
