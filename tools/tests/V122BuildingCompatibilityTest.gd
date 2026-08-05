extends Node

const Adapter = preload("res://scripts/v122/buildings/V122BuildingCompatibilityAdapter.gd")

var failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var rooms: Dictionary = DataRegistry.rooms.duplicate(true)
	var layout: Dictionary = DataRegistry.quarter_starting_layout.duplicate(true)
	for stage_id in ["stage_02_castle", "stage_03_keep"]:
		var expansion: Dictionary = DataRegistry.castle_stage_expansion(stage_id)
		for room_id_value in expansion.get("rooms", {}).keys():
			rooms[str(room_id_value)] = expansion.get("rooms", {}).get(room_id_value).duplicate(true)
		layout["placed_modules"].append_array(expansion.get("placed_modules", []).duplicate(true))
	var descriptors := Adapter.build_descriptors(
		rooms,
		layout,
		DataRegistry.quarter_modules,
		DataRegistry.quarter_asset_manifest,
		"stage_03_keep"
	)
	var errors := Adapter.validate_descriptors(descriptors)
	_expect(errors.is_empty(), "all product buildings resolve to runtime objects: %s" % [errors])
	for room_id in [
		"entrance",
		"throne",
		"barracks",
		"recovery",
		"treasure",
		"slot_01",
		"watch_post_01",
		"heart_chamber",
		"ward_core_01"
	]:
		_expect(descriptors.has(room_id), "%s has a compatibility descriptor" % room_id)
		if descriptors.has(room_id):
			var descriptor: Dictionary = descriptors[room_id]
			_expect(FileAccess.file_exists("res://%s" % str(descriptor.get("sprite_path", ""))), "%s sprite exists" % room_id)
			_expect(str(descriptor.get("status", "")) == "COMPLETE", "%s status is COMPLETE" % room_id)
	var watch: Dictionary = descriptors.get("watch_post_01", {})
	_expect(str(watch.get("object_id", "")) == "watch_post", "watch post uses the existing product prop")
	_expect(bool(watch.get("command_targetable", false)), "watch post can be targeted by facility command")
	_expect(bool(watch.get("engineer_targetable", false)), "watch post can be targeted by engineers")
	var heart: Dictionary = descriptors.get("heart_chamber", {})
	_expect(str(heart.get("renderer_mode", "")) == "heart_sheet", "heart chamber keeps its dedicated product renderer")
	var ward: Dictionary = descriptors.get("ward_core_01", {})
	_expect(str(ward.get("object_id", "")) == "foundation_marks", "ward core reuses the product foundation prop")
	_expect(str(ward.get("facing", "")) == "NW", "ward core selects the stage-specific NW sprite")
	_expect(Adapter.product_id_for_alias("v20_barricade") == "entrance", "barricade aliases the existing entrance object")
	_expect(Adapter.product_id_for_alias("v20_watch_post") == "watch_post", "watch alias resolves to the product role")
	_expect(Adapter.facility_visual_state({"hp": 10, "max_hp": 10}) == "default", "default facility visual state")
	_expect(Adapter.facility_visual_state({"hp": 8, "max_hp": 10}) == "damaged", "damaged facility visual state")
	_expect(Adapter.facility_visual_state({"hp": 10, "max_hp": 10, "disabled": true}) == "disabled", "disabled facility visual state")
	_expect(Adapter.facility_visual_state({"hp": 10, "max_hp": 10}, false, 0.0, true) == "engineer_target", "engineer target visual state")
	_expect(Adapter.facility_visual_state({"hp": 0, "max_hp": 10}) == "destroyed", "destroyed facility visual state")
	if failed:
		print("V122_BUILDING_COMPATIBILITY_TEST: FAIL")
		get_tree().quit(1)
	else:
		print("V122_BUILDING_COMPATIBILITY_TEST: PASS")
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
