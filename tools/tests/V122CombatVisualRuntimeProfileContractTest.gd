extends Node

const UnitActorScript = preload("res://scripts/units/Unit.gd")

var failures: Array[String] = []
const TARGET_PROFILE_IDS := ["moon_tracker"]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var normal_target := 68.04 * 1.15
	var small_target := normal_target * (0.72 / 0.95)
	var expected := {
		# DAY1~5 core defenders. Their existing 192px frames remain source assets;
		# V3 owns the final pixel normalization decision.
		"slime": {
			"profile_key": "slime", "stats_id": "slime", "profile_id": "small_grounded",
			"motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION",
			"runtime_path": "res://assets/sprites/monsters/monster_slime_idle_down_00.png",
			"scale": small_target / 118.5
		},
		"goblin": {
			"profile_key": "goblin", "stats_id": "goblin", "profile_id": "normal_grounded",
			"motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION",
			"runtime_path": "res://assets/sprites/monsters/monster_goblin_idle_down_00.png",
			"scale": normal_target / 150.0, "idle_bbox": [23, 22, 163, 179], "down_bbox": [24, 31, 179, 170], "idle_anchor": [0.5, 0.932292], "down_anchor": [0.5, 0.885417]
		},
		"imp": {
			"profile_key": "imp", "stats_id": "imp", "profile_id": "small_flying",
			"motion_mode": "flying", "normalization_state": "NEEDS_NORMALIZATION",
			"runtime_path": "res://assets/sprites/monsters/monster_imp_idle_down_00.png",
			"scale": small_target / 143.5, "idle_bbox": [25, 27, 163, 170], "down_bbox": [27, 34, 171, 176], "idle_anchor": [0.5, 0.885417], "down_anchor": [0.5, 0.916667]
		},
		# DAY12 first promotion choices. UnitActor still receives the base species
		# ID, so the exact promoted runtime path must select the promoted profile.
		"slime_gate_bulwark": {
			"profile_key": "slime_gate_bulwark", "stats_id": "slime", "profile_id": "normal_grounded",
			"motion_mode": "grounded", "normalization_state": "PASS",
			"runtime_path": "res://assets/sprites/monsters/monster_slime_gate_bulwark_idle_down_00.png",
			"scale": normal_target / 150.0, "idle_bbox": [13, 24, 189, 190], "down_bbox": [2, 41, 192, 172], "idle_anchor": [0.5, 0.989583], "down_anchor": [0.5, 0.895833]
		},
		"goblin_ambush_captain": {
			"profile_key": "goblin_ambush_captain", "stats_id": "goblin", "profile_id": "normal_grounded",
			"motion_mode": "grounded", "normalization_state": "PASS",
			"runtime_path": "res://assets/sprites/monsters/monster_goblin_ambush_captain_idle_down_00.png",
			"scale": normal_target / 149.0, "idle_bbox": [20, 17, 180, 181], "down_bbox": [8, 1, 192, 164], "idle_anchor": [0.5, 0.942708], "down_anchor": [0.5, 0.854167]
		},
		"imp_flame_adept": {
			"profile_key": "imp_flame_adept", "stats_id": "imp", "profile_id": "normal_flying",
			"motion_mode": "flying", "normalization_state": "PASS",
			"runtime_path": "res://assets/sprites/monsters/monster_imp_flame_adept_idle_down_00.png",
			"scale": normal_target / 158.0, "idle_bbox": [14, 15, 166, 174], "down_bbox": [25, 5, 146, 158], "idle_anchor": [0.5, 0.90625], "down_anchor": [0.5, 0.822917]
		},
		# This packet connects moon_tracker's flying anchors only. Other
		# enemy profiles stay outside the packet scope until their own turns.
		"explorer": {"profile_key": "explorer", "stats_id": "explorer", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_explorer_idle_down_00.png", "scale": normal_target / 160.0, "idle_bbox": [38, 23, 161, 188], "down_bbox": [26, 44, 189, 167], "idle_anchor": [0.5, 0.979167], "down_anchor": [0.5, 0.869792]},
		"thief": {"profile_key": "thief", "stats_id": "thief", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_thief_idle_down_00.png", "scale": normal_target / 140.0},
		"trainee_hero": {"profile_key": "trainee_hero", "stats_id": "trainee_hero", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_trainee_hero_idle_down_00.png", "scale": normal_target / 161.5, "idle_bbox": [25, 17, 162, 179], "down_bbox": [16, 45, 179, 180], "idle_anchor": [0.5, 0.932292], "down_anchor": [0.5, 0.9375]},
		"investigator": {"profile_key": "investigator", "stats_id": "investigator", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_investigator_idle_down_00.png", "scale": normal_target / 166.0, "idle_bbox": [47, 12, 144, 178], "down_bbox": [44, 93, 149, 184], "idle_anchor": [0.5, 0.927083], "down_anchor": [0.5, 0.958333]},
		"shieldbearer": {"profile_key": "shieldbearer", "stats_id": "shieldbearer", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_shieldbearer_idle_down_00.png", "scale": normal_target / 147.0, "idle_bbox": [23, 20, 166, 171], "down_bbox": [22, 45, 171, 177], "idle_anchor": [0.5, 0.890625], "down_anchor": [0.5, 0.921875]},
		"engineer": {"profile_key": "engineer", "stats_id": "engineer", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "PASS", "runtime_path": "res://assets/sprites/enemies/enemy_engineer_idle_down_00.png", "scale": normal_target / 152.5, "idle_bbox": [39, 15, 152, 170], "down_bbox": [8, 27, 158, 165], "idle_anchor": [0.5, 0.885417], "down_anchor": [0.5, 0.859375]},
		# DAY6~30 contract allies with transparent existing combat assets. The
		# shared base texture is intentional for this size/alpha packet; identity
		# asset replacement belongs to a separate asset decision.
		"spore_healer": {"profile_key": "spore_healer", "stats_id": "spore_healer", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/monsters/update4/monster_mori_sheet.png", "runtime_path": "res://assets/sprites/monsters/update4/monster_mori_sheet.png", "scale": normal_target / 161.0, "transparent_sheet": true, "idle_bbox": [10, 9, 182, 183], "down_bbox": [9, 100, 183, 183], "idle_anchor": [0.5, 0.953125], "down_anchor": [0.5, 0.953125]},
		"stone_sentinel": {"profile_key": "stone_sentinel", "stats_id": "stone_sentinel", "profile_id": "large_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/monsters/update4/monster_dolkong_sheet.png", "runtime_path": "res://assets/sprites/monsters/update4/monster_dolkong_sheet.png", "scale": (normal_target * (1.18 / 0.95)) / 170.5, "transparent_sheet": true, "idle_bbox": [9, 18, 183, 183], "down_bbox": [9, 26, 183, 183], "idle_anchor": [0.5, 0.953125], "down_anchor": [0.5, 0.953125]},
		"war_drummer": {"profile_key": "war_drummer", "stats_id": "war_drummer", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/monsters/update4/monster_dudum_sheet.png", "runtime_path": "res://assets/sprites/monsters/update4/monster_dudum_sheet.png", "scale": normal_target / 140.0, "transparent_sheet": true, "idle_bbox": [61, 41, 170, 185], "down_bbox": [21, 107, 182, 186], "idle_anchor": [0.5, 0.963542], "down_anchor": [0.5, 0.96875]},
		"mimic_porter": {"profile_key": "mimic_porter", "stats_id": "mimic_porter", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/monsters/update4/monster_mimi_sheet.png", "runtime_path": "res://assets/sprites/monsters/update4/monster_mimi_sheet.png", "scale": normal_target / 146.5, "transparent_sheet": true, "idle_bbox": [7, 30, 185, 183], "down_bbox": [9, 39, 183, 183], "idle_anchor": [0.5, 0.953125], "down_anchor": [0.5, 0.953125]},
		"moon_tracker": {"profile_key": "moon_tracker", "stats_id": "moon_tracker", "profile_id": "small_flying", "motion_mode": "flying", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/monsters/update4/monster_moon_sheet.png", "runtime_path": "res://assets/sprites/monsters/update4/monster_moon_sheet.png", "scale": small_target / 125.0, "transparent_sheet": true, "idle_bbox": [29, 38, 162, 183], "down_bbox": [24, 60, 167, 183], "idle_anchor": [0.5, 1.0], "down_anchor": [0.5, 0.94]},
		# V2-P1 Update4 enemy normalization remains covered by this contract.
		"coal_spark": {"profile_key": "coal_spark", "stats_id": "coal_spark", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_coal_spark_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_coal_spark_sheet.png", "scale": normal_target / 110.5, "transparent_sheet": true, "idle_bbox": [58, 58, 151, 174], "down_bbox": [40, 103, 153, 181], "idle_anchor": [0.5, 0.90625], "down_anchor": [0.5, 0.942708]},
		"dusk_courier": {"profile_key": "dusk_courier", "stats_id": "dusk_courier", "profile_id": "normal_flying", "motion_mode": "flying", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_dusk_courier_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_dusk_courier_sheet.png", "scale": normal_target / 120.0, "transparent_sheet": true, "idle_bbox": [37, 43, 163, 189], "down_bbox": [16, 79, 171, 183], "idle_anchor": [0.5, 0.984375], "down_anchor": [0.5, 0.953125]},
		"bronze_automaton": {"profile_key": "bronze_automaton", "stats_id": "bronze_automaton", "profile_id": "large_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_bronze_automaton_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_bronze_automaton_sheet.png", "scale": (normal_target * (1.18 / 0.95)) / 136.5, "transparent_sheet": true, "idle_bbox": [53, 42, 177, 187], "down_bbox": [22, 83, 176, 188], "idle_anchor": [0.5, 0.973958], "down_anchor": [0.5, 0.979167]},
		"shadow_duelist": {"profile_key": "shadow_duelist", "stats_id": "shadow_duelist", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_shadow_duelist_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_shadow_duelist_sheet.png", "scale": normal_target / 120.0, "transparent_sheet": true, "idle_bbox": [42, 36, 147, 184], "down_bbox": [10, 102, 154, 186], "idle_anchor": [0.5, 0.958333], "down_anchor": [0.5, 0.96875]},
		"spore_doll": {"profile_key": "spore_doll", "stats_id": "spore_doll", "profile_id": "normal_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_spore_doll_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_spore_doll_sheet.png", "scale": normal_target / 127.5, "transparent_sheet": true, "idle_bbox": [46, 35, 160, 170], "down_bbox": [21, 87, 176, 177], "idle_anchor": [0.5, 0.885417], "down_anchor": [0.5, 0.921875]},
		"root_tender": {"profile_key": "root_tender", "stats_id": "root_tender", "profile_id": "large_grounded", "motion_mode": "grounded", "normalization_state": "NEEDS_NORMALIZATION", "input_path": "res://assets/sprites/enemies/update4/region/enemy_root_tender_sheet.png", "runtime_path": "res://assets/sprites/enemies/update4/region/normalized/enemy_root_tender_sheet.png", "scale": (normal_target * (1.18 / 0.95)) / 123.5, "transparent_sheet": true, "idle_bbox": [47, 31, 152, 181], "down_bbox": [21, 69, 175, 184], "idle_anchor": [0.5, 0.942708], "down_anchor": [0.5, 0.958333]}
	}

	for expected_id_value in expected.keys():
		var expected_id := str(expected_id_value)
		if expected_id not in TARGET_PROFILE_IDS:
			continue
		var expectation: Dictionary = expected[expected_id]
		var stats_id := str(expectation["stats_id"])
		var runtime_path := str(expectation["runtime_path"])
		var input_path := str(expectation.get("input_path", runtime_path))
		var stats: Dictionary = DataRegistry.enemy(stats_id).duplicate(true)
		var faction := "enemy"
		if stats.is_empty():
			stats = DataRegistry.monster(stats_id).duplicate(true)
			faction = "monster"
		if stats.is_empty():
			_expect(false, "%s stats record is missing" % expected_id)
			continue
		stats["sprite"] = input_path

		var profile: Dictionary = DataRegistry.combat_visual_profile_for_unit(stats_id, input_path)
		_expect(not profile.is_empty(), "%s runtime profile is missing" % expected_id)
		_expect(str(profile.get("profile_key", "")) == str(expectation["profile_key"]), "%s profile key mismatch" % expected_id)
		_expect(str(profile.get("profile_id", "")) == str(expectation["profile_id"]), "%s profile id mismatch" % expected_id)
		_expect(str(profile.get("motion_mode", "")) == str(expectation["motion_mode"]), "%s motion mode mismatch" % expected_id)
		_expect(str(profile.get("normalization_state", "")) == str(expectation["normalization_state"]), "%s normalization state mismatch" % expected_id)
		_expect(str(profile.get("runtime_path", "")) == runtime_path, "%s runtime path mismatch" % expected_id)
		_expect(FileAccess.file_exists(runtime_path), "%s runtime asset is missing" % expected_id)
		_expect(is_equal_approx(float(profile.get("render_scale", 0.0)), float(expectation["scale"])), "%s render scale mismatch" % expected_id)

		var unit = UnitActorScript.new()
		add_child(unit)
		unit.setup(stats_id, stats, faction, "visual_audit")
		_expect(unit.sprite_path == runtime_path, "%s Unit sprite path mismatch" % expected_id)
		_expect(is_equal_approx(unit.sprite.scale.x, float(expectation["scale"])), "%s Unit scale mismatch" % expected_id)
		if bool(expectation.get("transparent_sheet", false)):
			_expect(unit.sprite.material == null, "%s transparent runtime sheet must not reuse the chroma-key shader" % expected_id)
			_expect(str(profile.get("runtime_preparation_state", "")) == "RUNTIME_PREP_PASS", "%s runtime preparation state mismatch" % expected_id)
			var sheet_metrics := _measure_runtime_sheet(runtime_path)
			_expect(bool(sheet_metrics.get("perimeter_clear", false)), "%s runtime sheet foreground must not touch a cell perimeter" % expected_id)
			_expect(is_equal_approx(float(sheet_metrics.get("median_art_height_px", -1.0)), float(profile.get("measured_art_height_px", -2.0))), "%s declared median art height must match the runtime PNG" % expected_id)
		var motion_entry: Dictionary = profile.get("motion_entry", {})
		var foot_anchor: Array = motion_entry.get("foot_anchor", [])
		if foot_anchor.size() >= 2:
			var expected_y := -(float(foot_anchor[1]) - 0.5) * 192.0 * float(expectation["scale"])
			_expect(unit.sprite.get_parent() == unit.visual_body, "%s sprite must remain under VisualBody" % expected_id)
			_expect(unit.sprite.position == Vector2.ZERO, "%s sprite local position must remain zero" % expected_id)
			_expect(is_equal_approx(unit.visual_body.position.y, expected_y), "%s idle foot anchor mismatch" % expected_id)
			var grounding_anchors: Dictionary = profile.get("grounding_anchors", {})
			var expected_idle_anchor: Array = expectation.get("idle_anchor", [])
			var expected_down_anchor: Array = expectation.get("down_anchor", [])
			var expected_idle_bbox: Array = expectation.get("idle_bbox", [])
			var expected_down_bbox: Array = expectation.get("down_bbox", [])
			# Keep the optional guard so an import-only packet can reuse this contract
			# without indexing missing bbox/anchor expectations.
			var has_grounding_expectations := expected_idle_anchor.size() >= 2 and expected_down_anchor.size() >= 2 and expected_idle_bbox.size() >= 4 and expected_down_bbox.size() >= 4
			if has_grounding_expectations:
				_expect(_array_values_match(grounding_anchors.get("idle_alpha_bbox_px", []), expected_idle_bbox), "%s idle alpha bbox mismatch" % expected_id)
				_expect(_array_values_match(grounding_anchors.get("down_alpha_bbox_px", []), expected_down_bbox), "%s down alpha bbox mismatch" % expected_id)
				_expect(is_equal_approx(float(grounding_anchors.get("idle_foot_anchor", [0.0, 0.0])[0]), float(expected_idle_anchor[0])), "%s declared idle anchor x mismatch" % expected_id)
				_expect(is_equal_approx(float(grounding_anchors.get("idle_foot_anchor", [0.0, 0.0])[1]), float(expected_idle_anchor[1])), "%s declared idle anchor mismatch" % expected_id)
				_expect(is_equal_approx(float(grounding_anchors.get("down_foot_anchor", [0.0, 0.0])[0]), float(expected_down_anchor[0])), "%s declared down anchor x mismatch" % expected_id)
				_expect(is_equal_approx(float(grounding_anchors.get("down_foot_anchor", [0.0, 0.0])[1]), float(expected_down_anchor[1])), "%s declared down anchor mismatch" % expected_id)
				_expect(str(grounding_anchors.get("runtime_consumption_state", "")) == "PENDING_V3_PROFILE_CONNECT", "%s source grounding state remains pending until the profile promotion gate" % expected_id)
			var down_anchor: Array = motion_entry.get("down_foot_anchor", [])
			if has_grounding_expectations and down_anchor.size() >= 2:
				unit.down = true
				unit._apply_visual_pose()
				var expected_down_y := -(float(down_anchor[1]) - 0.5) * 192.0 * float(expectation["scale"])
				_expect(is_equal_approx(unit.visual_body.position.y, expected_down_y), "%s down foot anchor mismatch" % expected_id)
		unit.queue_free()

	var preserved_unprofiled_forms := [
		{"unit_id": "slime", "sprite": "res://assets/sprites/monsters/monster_slime_rescue_alchemy_gel_idle_down_00.png"},
		{"unit_id": "goblin", "sprite": "res://assets/sprites/monsters/monster_goblin_vault_keeper_idle_down_00.png"},
		{"unit_id": "imp", "sprite": "res://assets/sprites/monsters/monster_imp_ember_shaman_idle_down_00.png"},
		{"unit_id": "slime", "sprite": "res://assets/sprites/monsters/update4/crowns/monster_slime_crown_bastion_sheet.png"},
		{"unit_id": "goblin", "sprite": "res://assets/sprites/monsters/update4/crowns/monster_goblin_crown_marshal_sheet.png"},
		{"unit_id": "imp", "sprite": "res://assets/sprites/monsters/update4/crowns/monster_imp_crown_flame_sage_sheet.png"},
		{"unit_id": "spore_healer", "sprite": "res://assets/sprites/monsters/update4/crowns/monster_mori_crown_priest_sheet.png"},
		{"unit_id": "spider_tailor", "sprite": "res://assets/sprites/monsters/update4/monster_spider_tailor_sheet.png"},
		{"unit_id": "bat_courier", "sprite": "res://assets/sprites/monsters/update4/monster_bat_courier_sheet.png"}
	]
	for form_value in preserved_unprofiled_forms:
		var form: Dictionary = form_value
		var form_unit_id := str(form["unit_id"])
		var form_sprite := str(form["sprite"])
		_expect(FileAccess.file_exists(form_sprite), "%s unprofiled form asset is missing" % form_sprite)
		_expect(DataRegistry.combat_visual_profile_for_unit(form_unit_id, form_sprite).is_empty(), "%s must not inherit the base form profile" % form_sprite)
		var form_unit = UnitActorScript.new()
		add_child(form_unit)
		form_unit.setup(form_unit_id, {"display_name": form_unit_id, "max_hp": 100, "sprite": form_sprite, "role": "visual_audit"}, "monster", "visual_audit")
		_expect(form_unit.sprite_path == form_sprite, "%s must keep its own combat sprite" % form_sprite)
		if form_sprite.ends_with("_sheet.png"):
			_expect(form_unit.sprite.material == null, "%s transparent sheet must not receive a chroma-key material" % form_sprite)
		form_unit.queue_free()

	_expect(DataRegistry.combat_visual_profile_for_unit("nonexistent_unit").is_empty(), "unknown unit must not inherit a profile")
	var fallback_unit = UnitActorScript.new()
	add_child(fallback_unit)
	var fallback_stats: Dictionary = {
		"display_name": "unregistered_contract",
		"max_hp": 100,
		"sprite": "res://assets/sprites/monsters/monster_slime_idle_down_00.png",
		"role": "visual_audit"
	}
	fallback_unit.setup("unregistered_contract", fallback_stats, "monster", "visual_audit")
	_expect(fallback_unit.sprite_path == str(fallback_stats.get("sprite", "")), "unregistered monster keeps its source sprite")
	_expect(is_equal_approx(fallback_unit.sprite.scale.x, 0.42), "unregistered monster keeps grounded fallback scale")
	fallback_unit.queue_free()
	_finish()


func _measure_runtime_sheet(path: String) -> Dictionary:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_width() % 4 != 0 or image.get_height() % 4 != 0:
		return {}
	var cell_width := image.get_width() / 4
	var cell_height := image.get_height() / 4
	var heights: Array[float] = []
	var perimeter_clear := true
	for frame_index in range(16):
		var origin_x := (frame_index % 4) * cell_width
		var origin_y := (frame_index / 4) * cell_height
		var min_y := cell_height
		var max_y := -1
		for local_y in range(cell_height):
			for local_x in range(cell_width):
				var alpha := int(round(image.get_pixel(origin_x + local_x, origin_y + local_y).a * 255.0))
				if alpha <= 32:
					continue
				min_y = mini(min_y, local_y)
				max_y = maxi(max_y, local_y)
				if local_x == 0 or local_y == 0 or local_x == cell_width - 1 or local_y == cell_height - 1:
					perimeter_clear = false
		if max_y < min_y:
			return {}
		heights.append(float(max_y - min_y + 1))
	heights.sort()
	return {
		"median_art_height_px": (heights[7] + heights[8]) / 2.0,
		"perimeter_clear": perimeter_clear
	}


func _finish() -> void:
	if failures.is_empty():
		print("V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_COMBAT_VISUAL_RUNTIME_PROFILE_CONTRACT_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _array_values_match(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in range(actual.size()):
		if not is_equal_approx(float(actual[index]), float(expected[index])):
			return false
	return true
