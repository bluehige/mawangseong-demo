extends Node

const TUTORIAL_FINAL_DAY := 3
const REGULAR_CAMPAIGN_FINAL_DAY := 30
const BASE_DEMON_LORD_MAX_HP := 1500

var day: int = 1
var max_day: int = TUTORIAL_FINAL_DAY

var gold: int = 1245
var mana: int = 320
var food: int = 18
var infamy: int = 620

var gold_income: int = 32
var mana_income: int = 18
var food_income: int = 6
var infamy_income: int = 15

var demon_lord_hp: int = BASE_DEMON_LORD_MAX_HP
var demon_lord_max_hp: int = BASE_DEMON_LORD_MAX_HP

var victory: bool = false
var defeat: bool = false
var player_name: String = ""
var onboarding_stage: String = "LV00_TITLE_BOOT"
var onboarding_complete: bool = false

func reset() -> void:
	day = 1
	max_day = TUTORIAL_FINAL_DAY
	gold = 1245
	mana = 320
	food = 18
	infamy = 620
	gold_income = 32
	mana_income = 18
	food_income = 6
	infamy_income = 15
	demon_lord_max_hp = BASE_DEMON_LORD_MAX_HP
	demon_lord_hp = demon_lord_max_hp
	victory = false
	defeat = false
	player_name = ""
	onboarding_stage = "LV00_TITLE_BOOT"
	onboarding_complete = false
	SignalBus.resources_changed.emit()

func campaign_snapshot() -> Dictionary:
	return {
		"day": day,
		"gold": gold,
		"mana": mana,
		"food": food,
		"infamy": infamy,
		"gold_income": gold_income,
		"mana_income": mana_income,
		"food_income": food_income,
		"infamy_income": infamy_income,
		"demon_lord_hp": demon_lord_hp,
		"demon_lord_max_hp": demon_lord_max_hp,
		"victory": victory,
		"defeat": defeat,
		"player_name": player_name,
		"onboarding_stage": onboarding_stage,
		"onboarding_complete": onboarding_complete
	}

func restore_campaign_snapshot(snapshot: Dictionary) -> bool:
	var numeric_keys := [
		"day",
		"gold",
		"mana",
		"food",
		"infamy",
		"gold_income",
		"mana_income",
		"food_income",
		"infamy_income",
		"demon_lord_hp",
		"demon_lord_max_hp"
	]
	for key in numeric_keys:
		if not snapshot.has(key) or not _campaign_number(snapshot.get(key)):
			return false
	for key in ["victory", "defeat", "onboarding_complete"]:
		if not snapshot.has(key) or not (snapshot.get(key) is bool):
			return false
	for key in ["player_name", "onboarding_stage"]:
		if not snapshot.has(key) or not (snapshot.get(key) is String):
			return false
	var restored_day := int(snapshot.get("day"))
	if restored_day < 1 or restored_day > REGULAR_CAMPAIGN_FINAL_DAY:
		return false
	for key in ["gold", "mana", "food", "infamy", "gold_income", "mana_income", "food_income", "infamy_income"]:
		if int(snapshot.get(key)) < 0:
			return false
	var restored_max_hp := int(snapshot.get("demon_lord_max_hp"))
	var restored_hp := int(snapshot.get("demon_lord_hp"))
	if restored_max_hp < 1 or restored_hp < 0 or restored_hp > restored_max_hp:
		return false
	if snapshot.get("victory") and snapshot.get("defeat"):
		return false
	day = restored_day
	max_day = TUTORIAL_FINAL_DAY
	gold = int(snapshot.get("gold"))
	mana = int(snapshot.get("mana"))
	food = int(snapshot.get("food"))
	infamy = int(snapshot.get("infamy"))
	gold_income = int(snapshot.get("gold_income"))
	mana_income = int(snapshot.get("mana_income"))
	food_income = int(snapshot.get("food_income"))
	infamy_income = int(snapshot.get("infamy_income"))
	demon_lord_max_hp = restored_max_hp
	demon_lord_hp = restored_hp
	victory = snapshot.get("victory")
	defeat = snapshot.get("defeat")
	player_name = snapshot.get("player_name")
	onboarding_stage = snapshot.get("onboarding_stage")
	onboarding_complete = snapshot.get("onboarding_complete")
	SignalBus.resources_changed.emit()
	return true


func _campaign_number(value) -> bool:
	return value is int or value is float

func can_pay(cost: Dictionary) -> bool:
	return gold >= int(cost.get("gold", 0)) and mana >= int(cost.get("mana", 0)) and food >= int(cost.get("food", 0)) and infamy >= int(cost.get("infamy", 0))

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	gold -= int(cost.get("gold", 0))
	mana -= int(cost.get("mana", 0))
	food -= int(cost.get("food", 0))
	infamy -= int(cost.get("infamy", 0))
	SignalBus.resources_changed.emit()
	return true

func add_rewards(reward: Dictionary) -> void:
	gold += int(reward.get("gold", 0))
	mana += int(reward.get("mana", 0))
	food += int(reward.get("food", 0))
	infamy += int(reward.get("infamy", 0))
	SignalBus.resources_changed.emit()

func advance_day() -> void:
	day += 1
	gold += gold_income
	mana += mana_income
	food += food_income
	infamy += infamy_income
	SignalBus.resources_changed.emit()

func damage_throne(amount: int) -> void:
	demon_lord_hp = max(0, demon_lord_hp - amount)
	if demon_lord_hp <= 0:
		defeat = true
	SignalBus.resources_changed.emit()

