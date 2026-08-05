extends Node2D

const UnitScript = preload("res://scripts/units/Unit.gd")
const UI_FONT = preload("res://assets/fonts/NotoSansCJKkr-Regular.otf")

const REFERENCE_VIEWPORT := Vector2i(1280, 720)
const OUTPUT_DIR := "res://tmp/v122_release_polish/v2_p1"
const OUTPUT_IMAGE := "v2_p1_update4_runtime_contact_sheet_1280x720.png"
const OUTPUT_MANIFEST := "v2_p1_update4_runtime_capture_manifest.json"
const GRID_COLUMNS := 3
const CELL_SIZE := Vector2(378.0, 276.0)
const GRID_ORIGIN := Vector2(44.0, 98.0)
const PACKET_IDS := [
	"coal_spark",
	"dusk_courier",
	"bronze_automaton",
	"shadow_duelist",
	"spore_doll",
	"root_tender"
]

var capture_status := "NOT_STARTED"
var capture_image_size := Vector2i.ZERO
var capture_records: Array[Dictionary] = []
var units: Array[Node] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(REFERENCE_VIEWPORT)
	get_window().content_scale_size = REFERENCE_VIEWPORT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DataRegistry.load_all()
	_build_contact_sheet()
	queue_redraw()
	await _settle()
	await _save_capture()
	_write_manifest()
	print("V122_COMBAT_UPDATE4_PACKET_CAPTURE: %s records=%d image=%s" % [capture_status, capture_records.size(), capture_image_size])
	get_tree().quit(0 if capture_status == "PASS" else 1)


func _build_contact_sheet() -> void:
	for index in range(PACKET_IDS.size()):
		var unit_id := str(PACKET_IDS[index])
		var stats: Dictionary = DataRegistry.enemy(unit_id).duplicate(true)
		var source_path := str(stats.get("sprite", ""))
		var profile: Dictionary = DataRegistry.combat_visual_profile_for_unit(unit_id, source_path)
		var runtime_path := str(profile.get("runtime_path", ""))
		if stats.is_empty() or profile.is_empty() or not FileAccess.file_exists(runtime_path):
			capture_status = "INVALID_INPUT"
			push_error("Missing Update4 stats/profile/runtime asset: %s" % unit_id)
			continue
		stats["role"] = "visual_audit"

		var unit := UnitScript.new()
		unit.name = "V122Update4Packet_%s" % unit_id
		add_child(unit)
		unit.setup(unit_id, stats, "enemy", "visual_audit")
		unit.set_physics_process(false)
		unit.set_process(false)
		unit.visible = true
		var row := index / GRID_COLUMNS
		var column := index % GRID_COLUMNS
		unit.global_position = GRID_ORIGIN + Vector2(column * CELL_SIZE.x + CELL_SIZE.x * 0.5, row * CELL_SIZE.y + CELL_SIZE.y * 0.60)
		unit.stop_navigation()
		unit._apply_visual_pose()
		unit.queue_redraw()
		units.append(unit)

		capture_records.append({
			"id": unit_id,
			"source_sprite": source_path,
			"runtime_sprite": unit.sprite_path,
			"profile_id": str(profile.get("profile_id", "")),
			"motion_mode": str(profile.get("motion_mode", "")),
			"inventory_state": str(profile.get("inventory_state", "")),
			"normalization_state": str(profile.get("normalization_state", "")),
			"runtime_preparation_state": str(profile.get("runtime_preparation_state", "")),
			"median_art_height_px": float(profile.get("measured_art_height_px", 0.0)),
			"render_scale": float(profile.get("render_scale", 0.0)),
			"target_art_height_px": float(profile.get("target_art_height_px", 0.0)),
			"chroma_material_applied": unit.sprite.material != null
		})
	if capture_status == "NOT_STARTED":
		capture_status = "READY"


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, REFERENCE_VIEWPORT), Color("#0e1117"), true)
	draw_string(UI_FONT, Vector2(34, 34), "v1.2.2 Update 4 전투 런타임 6종 재검수", HORIZONTAL_ALIGNMENT_LEFT, 760, 22, Color("#f2e6ca"))
	draw_string(UI_FONT, Vector2(34, 61), "경계 복구·공통 축소율·투명 시트 재키잉 금지 확인 / 최종 접지 판정은 V3 대기", HORIZONTAL_ALIGNMENT_LEFT, 1100, 13, Color("#abb4c2"))
	draw_string(UI_FONT, Vector2(1062, 34), "1280×720", HORIZONTAL_ALIGNMENT_LEFT, 180, 13, Color("#90d99b"))
	for index in range(capture_records.size()):
		var record: Dictionary = capture_records[index]
		var row := index / GRID_COLUMNS
		var column := index % GRID_COLUMNS
		var cell_rect := Rect2(GRID_ORIGIN + Vector2(column * CELL_SIZE.x, row * CELL_SIZE.y), CELL_SIZE - Vector2(8, 8))
		var prep_pass := str(record.get("runtime_preparation_state", "")) == "RUNTIME_PREP_PASS" and not bool(record.get("chroma_material_applied", true))
		var outline := Color("#b79048") if prep_pass else Color("#b34f5a")
		draw_rect(cell_rect, Color("#282415") if prep_pass else Color("#321a20"), true)
		draw_rect(cell_rect, outline, false, 2.0)
		draw_string(UI_FONT, cell_rect.position + Vector2(12, 26), str(record.get("id", "")), HORIZONTAL_ALIGNMENT_LEFT, cell_rect.size.x - 24, 16, Color("#f0e9dd"))
		var detail := "%s · %s · V3 대기" % [str(record.get("profile_id", "")), str(record.get("motion_mode", ""))]
		draw_string(UI_FONT, cell_rect.position + Vector2(12, cell_rect.size.y - 32), detail, HORIZONTAL_ALIGNMENT_LEFT, cell_rect.size.x - 24, 11, outline)
		var metric := "median %.1fpx → target %.1fpx · scale %.3f" % [float(record.get("median_art_height_px", 0.0)), float(record.get("target_art_height_px", 0.0)), float(record.get("render_scale", 0.0))]
		draw_string(UI_FONT, cell_rect.position + Vector2(12, cell_rect.size.y - 12), metric, HORIZONTAL_ALIGNMENT_LEFT, cell_rect.size.x - 24, 10, Color("#b9c0c9"))


func _save_capture() -> void:
	for _index in range(12):
		await get_tree().process_frame
	var texture := get_viewport().get_texture()
	if texture == null:
		capture_status = "CAPTURE_BLOCKED"
		push_error("Update4 packet viewport texture is unavailable; run without --headless")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		capture_status = "CAPTURE_BLOCKED"
		push_error("Update4 packet capture viewport is empty; run without --headless")
		return
	capture_image_size = image.get_size()
	if capture_image_size != REFERENCE_VIEWPORT:
		capture_status = "CAPTURE_SIZE_MISMATCH"
		push_error("Update4 packet capture size mismatch: %s" % capture_image_size)
		return
	var capture_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(OUTPUT_IMAGE)
	var error := image.save_png(capture_path)
	if error != OK:
		capture_status = "CAPTURE_SAVE_FAILED"
		push_error("Update4 packet capture save failed: %s" % error)
		return
	capture_status = "PASS"


func _write_manifest() -> void:
	var manifest := {
		"schema_version": 1,
		"capture_status": capture_status,
		"viewport_px": [REFERENCE_VIEWPORT.x, REFERENCE_VIEWPORT.y],
		"image_path": OUTPUT_DIR.path_join(OUTPUT_IMAGE),
		"image_size": [capture_image_size.x, capture_image_size.y],
		"record_count": capture_records.size(),
		"records": capture_records
	}
	var manifest_path := ProjectSettings.globalize_path(OUTPUT_DIR).path_join(OUTPUT_MANIFEST)
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file == null:
		push_error("Update4 packet manifest open failed: %s" % manifest_path)
		return
	file.store_string(JSON.stringify(manifest, "  ", true))
	file.store_string("\n")
	file.close()


func _settle() -> void:
	for _index in range(12):
		await get_tree().process_frame
