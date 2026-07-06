extends Node

var day: int = 1
var max_day: int = 3

var gold: int = 1245
var mana: int = 320
var food: int = 18
var infamy: int = 620

var gold_income: int = 32
var mana_income: int = 18
var food_income: int = 6
var infamy_income: int = 15

var demon_lord_hp: int = 1500
var demon_lord_max_hp: int = 1500

var victory: bool = false
var defeat: bool = false
var player_name: String = ""
var onboarding_stage: String = "LV00_TITLE_BOOT"
var onboarding_complete: bool = false

func reset() -> void:
	day = 1
	gold = 1245
	mana = 320
	food = 18
	infamy = 620
	gold_income = 32
	mana_income = 18
	food_income = 6
	infamy_income = 15
	demon_lord_hp = demon_lord_max_hp
	victory = false
	defeat = false
	player_name = ""
	onboarding_stage = "LV00_TITLE_BOOT"
	onboarding_complete = false
	SignalBus.resources_changed.emit()

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

