extends Node

const CrownScript = preload("res://scripts/systems/crown/CrownEvolutionService.gd")

const CROWN_IDS := [
	"crown_pudding_royal_bastion",
	"crown_gob_midnight_marshal",
	"crown_pynn_castle_flame_sage",
	"crown_mori_grand_mycelial_priest",
	"crown_toktok_royal_armorer",
	"crown_popo_grand_night_courier"
]

var failed := false
var assertion_count := 0
var loaded_atlases: Array[Image] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_catalog_and_runtime_assets()
	_test_crown_events()
	_write_runtime_capture()
	if failed:
		print("UPDATE4_CROWN_ASSETS_PHASE29_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_CROWN_ASSETS_PHASE29_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_catalog_and_runtime_assets() -> void:
	var crowns: Dictionary = DataRegistry.update4_crown_evolutions
	var manifest: Dictionary = DataRegistry.update4_asset_manifest
	_expect(crowns.size() == 6 and CROWN_IDS.all(func(crown_id): return manifest.has(str(crowns[crown_id].get("asset_manifest_id", "")))), "왕관 그래픽·매니페스트 정확히 6종")
	var total_frames := 0
	var total_portraits := 0
	for crown_id in CROWN_IDS:
		var crown: Dictionary = crowns.get(crown_id, {})
		var entry: Dictionary = manifest.get(str(crown.get("asset_manifest_id", "")), {})
		var appearance := CrownScript.runtime_appearance(crown_id, crowns)
		_expect(not bool(crown.get("placeholder_art", true)) and bool(appearance.get("ok", false)), "%s 최종 그래픽 연결" % crown_id)
		var sprite_path := str(entry.get("combat_sprite", ""))
		var atlas := Image.new()
		var load_error := atlas.load(sprite_path)
		_expect(load_error == OK and atlas.get_size() == Vector2i(768, 768), "%s 4×4 런타임 시트 768px" % crown_id)
		if load_error == OK:
			loaded_atlases.append(atlas)
			var hashes := {}
			var cells_valid := true
			for index in range(16):
				var cell := atlas.get_region(Rect2i((index % 4) * 192, (index / 4) * 192, 192, 192))
				var digest := _image_digest(cell)
				if hashes.has(digest) or cell.get_used_rect().size == Vector2i.ZERO:
					cells_valid = false
				hashes[digest] = true
				for point in [Vector2i(0, 0), Vector2i(191, 0), Vector2i(0, 191), Vector2i(191, 191)]:
					if cell.get_pixelv(point).a > 0.01:
						cells_valid = false
			_expect(cells_valid and hashes.size() == 16, "%s 16프레임 고유 해시·투명 모서리" % crown_id)
			total_frames += 16
		var portraits: Array = entry.get("portraits", [])
		var portraits_valid := portraits.size() == 2
		for portrait_path_value in portraits:
			var portrait := Image.new()
			portraits_valid = portraits_valid and portrait.load(str(portrait_path_value)) == OK and portrait.get_size() == Vector2i(512, 512)
		_expect(portraits_valid, "%s 의회·승리 초상 2개" % crown_id)
		total_portraits += portraits.size()
		var vfx_frames: Array = entry.get("vfx_frames", [])
		_expect(vfx_frames.size() == 4 and vfx_frames.all(func(path): return FileAccess.file_exists(str(path))), "%s 왕관 VFX 4프레임" % crown_id)
		_expect(FileAccess.file_exists(str(entry.get("sfx", ""))) and FileAccess.get_file_as_bytes(str(entry.get("sfx", ""))).size() > 1000, "%s 왕관 SFX" % crown_id)
		var source_record := str(entry.get("source_record", ""))
		var source_text := FileAccess.get_file_as_string(source_record)
		_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.contains("Generated date: 2026-07-14") and source_text.contains("Target version: v0.4"), "%s SOURCE 정책 필드" % crown_id)
		_expect(source_text.count("Source image path:") == 2 and source_text.count("Runtime image path:") == 7, "%s 원본 2개·런타임 이미지 7개 출처 연결" % crown_id)
	_expect(total_frames == 96 and total_portraits == 12, "전투 96프레임·초상 12개 총계")


func _test_crown_events() -> void:
	var events: Dictionary = DataRegistry.update4_crown_events
	_expect(events.size() == 6, "왕관 진화 사건 정확히 6개")
	for crown_id in CROWN_IDS:
		var event := CrownScript.crown_event_for_form(crown_id, events)
		_expect(not event.is_empty() and event.get("scenes", []).size() == 3 and int(event.get("unlock_day", 0)) == 23, "%s 3장면·DAY23 사건" % crown_id)
	var profile := {"crown_evolution": {"forms_unlocked": [], "forms_seen": [], "memories_unlocked": []}}
	var active := {"day": 23, "council_season": {"crown_form_id": CROWN_IDS[0]}}
	var completed := CrownScript.complete_crown_event(profile, active, events)
	_expect(bool(completed.get("ok", false)) and bool(completed.get("autosave_required", false)), "왕관 사건 완료 자동저장")
	_expect(completed.profile.crown_evolution.forms_unlocked == [CROWN_IDS[0]] and completed.profile.crown_evolution.forms_seen == [CROWN_IDS[0]] and completed.profile.crown_evolution.memories_unlocked.size() == 1, "도감 형태·본 사건·기억 기록")
	_expect(not bool(CrownScript.complete_crown_event(completed.profile, completed.active_run, events).get("ok", false)), "같은 왕관 사건 중복 완료 금지")


func _write_runtime_capture() -> void:
	if loaded_atlases.size() != 6:
		_expect(false, "런타임 캡처용 시트 6종 로드")
		return
	var capture := Image.create_empty(1536, 1152, false, Image.FORMAT_RGBA8)
	capture.fill(Color("17131f"))
	for row in range(6):
		var atlas: Image = loaded_atlases[row]
		for column in range(4):
			var frame := atlas.get_region(Rect2i(column * 192, 0, 192, 192))
			capture.blend_rect(frame, Rect2i(0, 0, 192, 192), Vector2i(288 + column * 240, row * 192))
	var output_path := "res://tmp/phase29_crown_runtime_capture.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var save_error := capture.save_png(output_path)
	_expect(save_error == OK and FileAccess.file_exists(output_path), "실제 런타임 텍스처 캡처 생성")


func _image_digest(image: Image) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(image.get_data())
	return context.finish().hex_encode()


func _expect(condition: bool, label: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		failed = true
		push_error("[Update4CrownAssetsPhase29] FAIL: %s" % label)
