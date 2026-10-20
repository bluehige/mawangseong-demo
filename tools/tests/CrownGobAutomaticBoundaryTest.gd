extends "res://tools/tests/CrownGobRecoveryTest.gd"

func _ready() -> void:
	get_tree().create_timer(90).timeout.connect(func(): push_error("Gob auto boundary timeout"); get_tree().quit(1))
	call_deferred("run")

func run() -> void:
	expect(ProjectSettings.globalize_path("user://").contains("skill_action_review"), "isolated auto boundary userdata")
	if not failures.is_empty(): get_tree().quit(1); return
	DataRegistry.load_all(); UISettings.reset_skill_cutscene_history(false)
	check_tooltip_locales()
	var manual: Dictionary = await chain_outcome(false)
	var automatic: Dictionary = await chain_outcome(true)
	expect(manual == automatic, "actual production AI and manual outcome equality")
	output_dir = "res://tmp/crown_gob_automatic_boundary"
	var file := FileAccess.open(output_dir + "/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"manual":manual,"automatic":automatic,"checks":checks,"failures":failures}, "\t"))
	print("CROWN_GOB_AUTOMATIC_BOUNDARY: %s (%d/%d)" % ["PASS" if failures.is_empty() else "FAIL", checks-failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_tooltip_locales() -> void:
	var expected := {
		"night_relay": {
			"ko":"1층의 다른 위험 방에 있는 아군에게 걸어가, 도착하면 둘 모두 5초 동안 빠르게 움직이고 공격합니다.",
			"en":"Walk to an ally in another threatened room on the first floor. On arrival, both move and attack faster for 5 seconds.",
			"zh_CN":"步行前往一楼另一处危险房间的伙伴身旁。到达后，两人在 5 秒内加速移动与攻击。"},
		"royal_emergency_plating": {
			"ko":"1층에서 같은 방 또는 닿을 수 있는 가까운 손상 시설 중 HP 비율이 가장 낮은 시설을 최대 HP 30% 수리하고, 8초 동안 받는 피해를 30% 줄입니다.",
			"en":"Among damaged first-floor facilities in the same room or within nearby reachable range, repair the one with the lowest HP ratio by up to 30% of max HP and reduce its incoming damage by 30% for 8 seconds.",
			"zh_CN":"在同一房间或附近可达的一楼受损设施中，选择 HP 比例最低的设施，最多修复其最大 HP 的 30%，并在 8 秒内使其受到的伤害减少 30%。"}}
	var tooltip := Control.new(); add_child(tooltip)
	for locale in ["ko", "en", "zh_CN"]:
		LanguageSettings.set_locale(locale, false)
		for id in expected:
			# HUDController assigns this authored description to tooltip_text;
			# Godot's tooltip translation uses this same TranslationServer lookup.
			tooltip.tooltip_text = str(DataRegistry.skill(id).description)
			expect(tooltip.tr(tooltip.tooltip_text) == expected[id][locale], "localized tooltip " + id + " " + locale)
	LanguageSettings.set_locale("ko", false); tooltip.queue_free()

func chain_outcome(automatic: bool) -> Dictionary:
	await gob("always")
	output_dir = "res://tmp/crown_gob_automatic_boundary"; DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var secondary = additional(); var combat = game.combat_scene; var runtime = combat.crown_command; var action = combat.skill_actions
	var primary_hp: int = enemy.hp; var secondary_hp: int = secondary.hp; var origin: Vector2 = caster.global_position
	var expected: int = combat.DamageService.compute(caster, enemy, 1.0)
	expect(request("royal_no_second_cut", automatic), "production request " + str(automatic))
	expect(action.is_active() and action.actors[0].sprite_frames == caster.sprite.sprite_frames and caster.sprite_path.contains("crown_gob"), "current crown native presentation " + str(automatic))
	expect(enemy.hp == primary_hp and caster.get_meta("royal_chain_uses", 0) == 0 and combat.ledger_debt_recorded == 0, "preparation has no hit/use/debt")
	action.tick(.56); await capture("gob_auto_boundary_" + ("auto" if automatic else "manual")); action.skip(); action.skip()
	for unit in game.monster_units + game.enemy_units: unit.set_physics_process(false)
	runtime.tick(.01)
	expect(enemy.hp == primary_hp-expected and secondary.hp == secondary_hp and caster.get_meta("royal_chain_uses",0) == 1 and combat.ledger_debt_recorded == 1, "first actual contact commits once")
	var interval: float = caster.effective_attack_interval(); advance(interval-.1)
	expect(secondary.hp == secondary_hp, "secondary waits normal interval")
	advance(.2); advance(1.0)
	expect(secondary.hp == secondary_hp-expected and combat.ledger_debt_recorded == 1, "actual secondary normal hit and no extra debt")
	expect(not runtime.owned(caster) and caster.global_position.distance_to(origin) <= caster.PATH_POINT_REACHED_RADIUS, "actual return and chain release")
	expect(GameState.mana == 500 and caster.get_meta("royal_chain_uses",0) == 1 and runtime.defense_factor(caster) == .85, "same mana/use/post defense")
	var result := {"primary_hp_loss":primary_hp-enemy.hp,"secondary_hp_loss":secondary_hp-secondary.hp,"mana":GameState.mana,"uses":caster.get_meta("royal_chain_uses",0),"debt":combat.ledger_debt_recorded,"contacts":int(runtime.contributions[caster.get_instance_id()].royal_chain_contacts),"returned":not runtime.owned(caster) and caster.global_position.distance_to(origin) <= caster.PATH_POINT_REACHED_RADIUS,"defense_factor":runtime.defense_factor(caster)}
	await dispose_case()
	return result
