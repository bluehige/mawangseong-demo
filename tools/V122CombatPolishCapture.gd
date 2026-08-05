extends Node2D

const Constants = preload("res://scripts/core/Constants.gd")
const UnitScript = preload("res://scripts/units/Unit.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

const INVENTORY_PATH := "res://tmp/v122_release_polish/f0_v/f0_v_inventory.json"
const OUTPUT_DIR := "res://tmp/v122_release_polish/v1_b"
const OUTPUT_IMAGE := "v1_b_combat_visual_contact_sheet_1280x720.png"
const OUTPUT_MANIFEST := "v1_b_capture_manifest.json"
const REFERENCE_VIEWPORT := Vector2i(1280, 720)
const GRID_COLUMNS := 7
const CELL_SIZE := Vector2(182.0, 90.0)
const GRID_ORIGIN := Vector2(94.0, 88.0)

var capture_records: Array = []
var profile_catalog: Dictionary = {}
var capture_status := "NOT_STARTED"
var capture_image_size := Vector2i.ZERO
var capture_path := ""
var units: Array[Node] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(REFERENCE_VIEWPORT)
	get_window().content_scale_size = REFERENCE_VIEWPORT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DataRegistry.load_all()
	profile_catalog = DataRegistry.combat_visual_profiles.duplicate(true)
	capture_records = _load_inventory_records()
	if profile_catalog.is_empty() or capture_records.is_empty():
		capture_status = "INVALID_INPUT"
		_write_manifest()
		print("V122_COMBAT_POLISH_CAPTURE: INVALID_INPUT")
		get_tree().quit(1)
		return

	_build_contact_sheet()
	queue_redraw()
	await _settle()
	await _save_capture()
	_write_manifest()
	print("V122_COMBAT_POLISH_CAPTURE: %s records=%d image=%s" % [capture_status, capture_records.size(), capture_image_size])
	get_tree().quit(0 if capture_status == "PASS" else 1)


func _load_inventory_records() -> Array:
	if not FileAccess.file_exists(INVENTORY_PATH):
		push_error("Missing F0-V inventory: %s" % INVENTORY_PATH)
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH))
	if not (parsed is Dictionary):
		push_error("Invalid F0-V inventory: %s" % INVENTORY_PATH)
		return []
	var records = parsed.get("records", [])
	if not (records is Array):
		push_error("F0-V inventory records are not an array")
		return []
	return records


func _build_contact_sheet() -> void:
	for index in range(capture_records.size()):
		var record: Dictionary = capture_records[index]
		var unit_id := str(record.get("id", ""))
		var sprite_path := str(record.get("sprite", ""))
		if unit_id == "" or sprite_path == "":
			continue
		var unit := UnitScript.new()
		unit.name = "CombatPolishContact_%s" % unit_id
		add_child(unit)
		var source_kind := str(record.get("source", ""))
		var faction := Constants.FACTION_ENEMY if source_kind.contains("enemy") else Constants.FACTION_MONSTER
		unit.setup(
			unit_id,
			{
				"display_name": unit_id,
				"max_hp": 100,
				"sprite": sprite_path,
				"role": "visual_audit"
			},
			faction,
			"visual_audit"
		)
		unit.set_physics_process(false)
		unit.set_process(false)
		unit.visible = true
		var row := index / GRID_COLUMNS
		var column := index % GRID_COLUMNS
		unit.global_position = GRID_ORIGIN + Vector2(column * CELL_SIZE.x + CELL_SIZE.x * 0.5, row * CELL_SIZE.y + CELL_SIZE.y * 0.58)
		unit.stop_navigation()
		unit._apply_visual_pose()
		unit.queue_redraw()
		units.append(unit)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(REFERENCE_VIEWPORT)), Color("#0c0d13"), true)
	draw_string(UI_FONT, Vector2(28, 28), "v1.2.2 V1-B 전투 시각 정규화 기준판", HORIZONTAL_ALIGNMENT_LEFT, 620, 18, Color("#f2e6ca"))
	draw_string(UI_FONT, Vector2(28, 51), "profile=%s · source=F0-V inventory · viewport=1280×720 · runtime asset 변경 없음" % str(profile_catalog.get("profile_id", "")), HORIZONTAL_ALIGNMENT_LEFT, 1060, 11, Color("#aaa5b5"))
	draw_string(UI_FONT, Vector2(1040, 28), "PASS", HORIZONTAL_ALIGNMENT_LEFT, 60, 11, Color("#90d99b"))
	draw_string(UI_FONT, Vector2(1100, 28), "NEEDS_NORMALIZATION", HORIZONTAL_ALIGNMENT_LEFT, 155, 11, Color("#e4bd76"))
	for index in range(capture_records.size()):
		var record: Dictionary = capture_records[index]
		var row := index / GRID_COLUMNS
		var column := index % GRID_COLUMNS
		var cell_rect := Rect2(GRID_ORIGIN + Vector2(column * CELL_SIZE.x, row * CELL_SIZE.y), CELL_SIZE - Vector2(4, 4))
		var status := str(record.get("status", "UNKNOWN"))
		var fill := Color("#14251b") if status == "PASS" else Color("#2c2415") if status == "NEEDS_NORMALIZATION" else Color("#321a20")
		var outline := Color("#4e9b63") if status == "PASS" else Color("#a17b38") if status == "NEEDS_NORMALIZATION" else Color("#a64e5e")
		draw_rect(cell_rect, fill, true)
		draw_rect(cell_rect, outline, false, 1.0)
		draw_string(UI_FONT, cell_rect.position + Vector2(5, 14), str(record.get("id", "")), HORIZONTAL_ALIGNMENT_LEFT, cell_rect.size.x - 10, 10, Color("#eee8df"))
		var mode := "flying" if bool(record.get("runtime_flying", false)) else "grounded"
		draw_string(UI_FONT, cell_rect.position + Vector2(5, cell_rect.size.y - 7), "%s · %s" % [status, mode], HORIZONTAL_ALIGNMENT_LEFT, cell_rect.size.x - 10, 9, outline)


func _save_capture() -> void:
	for _index in range(12):
		await get_tree().process_frame
	var texture := get_viewport().get_texture()
	if texture == null:
		capture_status = "CAPTURE_BLOCKED"
		push_error("V1-B viewport texture is unavailable; run without --headless for the actual comparison board")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		capture_status = "CAPTURE_BLOCKED"
		push_error("V1-B capture viewport is empty; run without --headless for the actual comparison board")
		return
	capture_image_size = image.get_size()
	if capture_image_size != REFERENCE_VIEWPORT:
		capture_status = "CAPTURE_SIZE_MISMATCH"
		push_error("V1-B capture size mismatch: %s" % capture_image_size)
		return
	capture_path = ProjectSettings.globalize_path(OUTPUT_DIR).path_join(OUTPUT_IMAGE)
	var error := image.save_png(capture_path)
	if error != OK:
		capture_status = "CAPTURE_SAVE_FAILED"
		push_error("V1-B capture save failed: %s" % error)
		return
	capture_status = "PASS"


func _write_manifest() -> void:
	var ids: Array[String] = []
	var audit_records: Array[Dictionary] = []
	for record_value in capture_records:
		var record: Dictionary = record_value
		var unit_id := str(record.get("id", ""))
		ids.append(unit_id)
		audit_records.append({
			"id": unit_id,
			"source": str(record.get("source", "")),
			"sprite": str(record.get("sprite", "")),
			"dimensions": str(record.get("dimensions", "")),
			"status": str(record.get("status", "")),
			"runtime_flying": bool(record.get("runtime_flying", false)),
			"motion_profile": "normal_flying" if bool(record.get("runtime_flying", false)) else "normal_grounded",
			"normalization_required": str(record.get("status", "")) != "PASS"
		})
	ids.sort()
	var manifest := {
		"schema_version": 1,
		"capture_status": capture_status,
		"source_inventory": INVENTORY_PATH,
		"profile_id": str(profile_catalog.get("profile_id", "")),
		"viewport_px": [REFERENCE_VIEWPORT.x, REFERENCE_VIEWPORT.y],
		"grid": {"columns": GRID_COLUMNS, "cell_px": [CELL_SIZE.x, CELL_SIZE.y], "origin_px": [GRID_ORIGIN.x, GRID_ORIGIN.y]},
		"record_count": capture_records.size(),
		"sorted_ids": ids,
		"image_path": OUTPUT_DIR.path_join(OUTPUT_IMAGE),
		"image_size": [capture_image_size.x, capture_image_size.y],
		"records": audit_records
	}
	var manifest_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(OUTPUT_MANIFEST)
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("V1-B manifest open failed: %s" % manifest_path)
		return
	file.store_string(JSON.stringify(manifest, "  ", true))
	file.store_string("\n")
	file.close()


func _settle() -> void:
	for _index in range(12):
		await get_tree().process_frame
