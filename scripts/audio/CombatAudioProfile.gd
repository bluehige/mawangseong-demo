class_name CombatAudioProfile
extends RefCounted

const FAMILY_BLADE := "blade"
const FAMILY_BLUNT_SHIELD := "blunt_shield"
const FAMILY_CLAW_BITE := "claw_bite"
const FAMILY_FIRE_MAGIC := "fire_magic"

const MATERIAL_BODY := "body"
const MATERIAL_METAL := "metal"
const MATERIAL_STONE := "stone"

const BLUNT_IDS := [
	"slime", "stone_sentinel", "war_drummer", "mimic_porter", "armored_beetle",
	"shieldbearer", "ward_breaker", "engineer"
]
const CLAW_IDS := ["kobold_scout", "spore_healer", "moon_tracker"]
const METAL_IDS := [
	"armored_beetle", "shieldbearer", "ward_breaker", "engineer",
	"trainee_hero", "official_hero_leon", "selen_trainee_paladin"
]


static func attack_family(attacker_id: String, contact_kind: String) -> String:
	var normalized_id := attacker_id.to_lower()
	if normalized_id == "imp" and contact_kind in ["projectile", "area"]:
		return FAMILY_FIRE_MAGIC
	if normalized_id in BLUNT_IDS or normalized_id.contains("automaton") or normalized_id.contains("shield"):
		return FAMILY_BLUNT_SHIELD
	if normalized_id in CLAW_IDS or normalized_id.contains("hound") or normalized_id.contains("beast"):
		return FAMILY_CLAW_BITE
	return FAMILY_BLADE


static func attack_event_for_family(family_id: String, sequence: int) -> String:
	var variant := posmod(maxi(sequence, 1) - 1, 3) + 1
	return "combat.attack.%s.%02d" % [family_id, variant]


static func impact_material(target_id: String, target_kind: String = "unit") -> String:
	var normalized_id := target_id.to_lower()
	if target_kind in ["facility", "room", "structure"] or normalized_id.contains("stone"):
		return MATERIAL_STONE
	if normalized_id in METAL_IDS or normalized_id.contains("automaton") or normalized_id.contains("armored"):
		return MATERIAL_METAL
	return MATERIAL_BODY


static func impact_event(material_id: String) -> String:
	return "combat.impact.%s" % material_id


static func outcome_event(outcome_id: String) -> String:
	if outcome_id in ["down", "critical", "reward"]:
		return "combat.outcome.%s" % outcome_id
	return ""


static func ui_event(action_id: String) -> String:
	if action_id in ["click", "select", "confirm", "cancel", "fail", "danger"]:
		return "ui.%s" % action_id
	return ""
