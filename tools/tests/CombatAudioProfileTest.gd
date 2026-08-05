extends Node

const ProfileScript = preload("res://scripts/audio/CombatAudioProfile.gd")
const CatalogScript = preload("res://scripts/audio/AudioCatalogApi.gd")

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ProfileScript.attack_family("goblin", "melee") == ProfileScript.FAMILY_BLADE, "goblin basic attack uses the blade family")
	_expect(ProfileScript.attack_family("slime", "melee") == ProfileScript.FAMILY_BLUNT_SHIELD, "slime body impact does not reuse the blade family")
	_expect(ProfileScript.attack_family("stone_sentinel", "melee") == ProfileScript.FAMILY_BLUNT_SHIELD, "stone sentinel uses the blunt family")
	_expect(ProfileScript.attack_family("moon_tracker", "melee") == ProfileScript.FAMILY_CLAW_BITE, "creature melee uses the claw and bite family")
	_expect(ProfileScript.attack_family("imp", "projectile") == ProfileScript.FAMILY_FIRE_MAGIC, "imp projectile uses the fire and magic family")
	_expect(ProfileScript.attack_event_for_family(ProfileScript.FAMILY_BLADE, 1) == "combat.attack.blade.01", "blade cycle starts at variation 01")
	_expect(ProfileScript.attack_event_for_family(ProfileScript.FAMILY_BLADE, 2) == "combat.attack.blade.02", "blade cycle advances to variation 02")
	_expect(ProfileScript.attack_event_for_family(ProfileScript.FAMILY_BLADE, 3) == "combat.attack.blade.03", "blade cycle advances to variation 03")
	_expect(ProfileScript.attack_event_for_family(ProfileScript.FAMILY_BLADE, 4) == "combat.attack.blade.01", "blade cycle deterministically wraps to variation 01")
	_expect(ProfileScript.impact_material("explorer") == ProfileScript.MATERIAL_BODY, "ordinary target uses body impact")
	_expect(ProfileScript.impact_material("official_hero_leon") == ProfileScript.MATERIAL_METAL, "armored hero uses metal impact")
	_expect(ProfileScript.impact_material("stone_sentinel") == ProfileScript.MATERIAL_STONE, "stone sentinel uses stone impact")
	_expect(ProfileScript.impact_material("", "facility") == ProfileScript.MATERIAL_STONE, "facility contact uses stone impact")
	_expect(ProfileScript.impact_event(ProfileScript.MATERIAL_BODY) == "combat.impact.body", "body material maps to the body event")
	_expect(ProfileScript.impact_event(ProfileScript.MATERIAL_METAL) == "combat.impact.metal", "metal material maps to the metal event")
	_expect(ProfileScript.impact_event(ProfileScript.MATERIAL_STONE) == "combat.impact.stone", "stone material maps to the stone event")
	for outcome_id in ["down", "critical", "reward"]:
		_expect(ProfileScript.outcome_event(outcome_id) == "combat.outcome.%s" % outcome_id, "%s outcome has a stable event ID" % outcome_id)
	for action_id in ["click", "select", "confirm", "cancel", "fail", "danger"]:
		_expect(ProfileScript.ui_event(action_id) == "ui.%s" % action_id, "%s UI action has a stable event ID" % action_id)
	CatalogScript.reset_for_test()
	_expect(CatalogScript.has_event("music.combat.normal"), "catalog presence check finds an existing event")
	_expect(CatalogScript.has_event("combat.attack.blade.01"), "approved attack event is connected to a runtime asset")
	for event_id in [
		"combat.attack.blunt_shield.01",
		"combat.attack.claw_bite.01",
		"combat.attack.fire_magic.01",
		"combat.impact.body",
		"combat.impact.metal",
		"combat.impact.stone",
		"combat.outcome.down",
		"combat.outcome.critical",
		"combat.outcome.reward",
		"ui.click",
		"ui.select",
		"ui.confirm",
		"ui.cancel",
		"ui.fail",
		"ui.danger"
	]:
		_expect(CatalogScript.has_event(event_id), "%s is connected to a runtime asset" % event_id)
	_expect(CatalogScript.diagnostics().is_empty(), "catalog presence check does not emit false missing-event errors")

	if failed:
		print("COMBAT_AUDIO_PROFILE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("COMBAT_AUDIO_PROFILE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)
