extends Node

const BondService = preload("res://scripts/systems/monsters/MonsterBondEventService.gd")

const SPECIES_IDS := ["spider_tailor", "bat_courier"]

var failed := false
var assertion_count := 0
var atlases: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_art_contract()
	_test_bond_events_and_codex()
	_write_context_capture("outpost", 0, "res://tmp/phase30_outpost_capture.png")
	_write_context_capture("upper_floor", 12, "res://tmp/phase30_upper_floor_capture.png")
	if failed:
		print("UPDATE4_CONTRACT_MONSTER_PRESENTATION_PHASE30_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_CONTRACT_MONSTER_PRESENTATION_PHASE30_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_art_contract() -> void:
	var total_frames := 0
	var total_portraits := 0
	for species_id in SPECIES_IDS:
		var monster: Dictionary = DataRegistry.update4_monsters.get(species_id, {})
		var character_id := str(monster.get("character_id", ""))
		var character: Dictionary = DataRegistry.update4_characters.get(character_id, {})
		var manifest: Dictionary = DataRegistry.update4_asset_manifest.get(str(monster.get("asset_manifest_id", "")), {})
		_expect(not bool(monster.get("placeholder_art", true)) and not bool(character.get("placeholder_art", true)), "%s 최종 그래픽 전환" % species_id)
		var atlas := Image.new()
		var load_error := atlas.load(str(monster.get("sprite", "")))
		_expect(load_error == OK and atlas.get_size() == Vector2i(768, 768), "%s 4×4 런타임 시트" % species_id)
		if load_error == OK:
			atlases[species_id] = atlas
			var hashes := {}
			var valid := true
			for index in range(16):
				var cell := atlas.get_region(Rect2i((index % 4) * 192, floori(index / 4.0) * 192, 192, 192))
				var digest := _image_digest(cell)
				valid = valid and not hashes.has(digest) and cell.get_used_rect().size != Vector2i.ZERO
				hashes[digest] = true
				for point in [Vector2i(0, 0), Vector2i(191, 0), Vector2i(0, 191), Vector2i(191, 191)]:
					valid = valid and cell.get_pixelv(point).a <= 0.01
			_expect(valid and hashes.size() == 16, "%s 행동별 16프레임 고유·투명 계약" % species_id)
			total_frames += 16
		var portraits: Array = manifest.get("portraits", [])
		var portraits_valid := portraits.size() == 3
		for portrait_path in portraits:
			var portrait := Image.new()
			portraits_valid = portraits_valid and portrait.load(str(portrait_path)) == OK and portrait.get_size() == Vector2i(512, 512)
		_expect(portraits_valid and character.get("portraits", {}).size() == 3, "%s 기본·기쁨·결의 초상 3개" % species_id)
		total_portraits += portraits.size()
		_expect(manifest.get("vfx_frames", []).size() == 4 and manifest.get("vfx_frames", []).all(func(path): return FileAccess.file_exists(str(path))), "%s 스킬 VFX 4프레임" % species_id)
		_expect(manifest.get("sfx", []).size() == 2 and manifest.get("sfx", []).all(func(path): return FileAccess.file_exists(str(path)) and FileAccess.get_file_as_bytes(str(path)).size() > 1000), "%s 스킬 SFX 2개" % species_id)
		var source_text := FileAccess.get_file_as_string(str(manifest.get("source_record", "")))
		_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.count("Source image path:") == 2 and source_text.count("Runtime image path:") == 8, "%s SOURCE 원본·런타임 연결" % species_id)
		_expect(manifest.get("capture_contexts", []) == ["outpost", "upper_floor"] and int(manifest.get("frame_contract", {}).get("frame_count", 0)) == 16, "%s 전초기지·상층 프레임 계약" % species_id)
	_expect(total_frames == 32 and total_portraits == 6, "실키·포포 전투 32프레임·초상 6개 총계")
	_expect(str(DataRegistry.update4_skills.stitch_stairway.vfx_id) == "fx_silky_thread" and FileAccess.file_exists(str(DataRegistry.update4_skills.emergency_thread_pull.sfx)), "실키 행동과 VFX·SFX 동기")
	_expect(str(DataRegistry.update4_skills.night_relay.vfx_id) == "fx_popo_relay" and FileAccess.file_exists(str(DataRegistry.update4_skills.echo_alarm.sfx)), "포포 행동과 VFX·SFX 동기")


func _test_bond_events_and_codex() -> void:
	var events: Dictionary = DataRegistry.update4_bond_events
	var codex: Dictionary = DataRegistry.update4_monster_codex
	_expect(events.size() == 6 and codex.size() == 2, "유대 사건 6개·도감 2종")
	for species_id in SPECIES_IDS:
		var codex_entry := BondService.codex_entry(species_id, codex)
		var instance := {"species_id": species_id, "bond": 80}
		var ids := BondService.eligible_event_ids(instance, {}, events)
		var expected_ids: Array = codex_entry.get("bond_event_ids", [])
		_expect(ids == expected_ids and ids.size() == 3, "%s 유대 30·55·80 순차 후보" % species_id)
		var profile := {"update4_bond_events_seen": [], "unlocked_memory_ids": [], "monster_codex_unlocked_ids": []}
		for event_id in ids:
			var completed := BondService.complete(profile, instance, event_id, events)
			_expect(bool(completed.get("ok", false)) and bool(completed.get("autosave_required", false)), "%s 유대 사건 저장" % event_id)
			profile = completed.profile
		var restored = JSON.parse_string(JSON.stringify(profile))
		_expect(restored.update4_bond_events_seen == expected_ids and restored.unlocked_memory_ids.size() == 3 and restored.monster_codex_unlocked_ids.has(species_id), "%s 유대·기억·도감 복원" % species_id)
		_expect(BondService.eligible_event_ids(instance, restored, events).is_empty() and not bool(BondService.complete(restored, instance, ids[0], events).get("ok", false)), "%s 유대 사건 중복 금지" % species_id)
		var entry := BondService.codex_entry(species_id, codex)
		_expect(entry.get("skill_ids", []).size() == 3 and entry.get("weaknesses", []).size() == 3 and str(entry.get("portrait", "")) != "", "%s 도감 역할·약점·초상" % species_id)
	var low := BondService.eligible_event_ids({"species_id": "spider_tailor", "bond": 29}, {}, events)
	_expect(low.is_empty(), "유대 29에서는 첫 사건 잠금")


func _write_context_capture(context_id: String, frame_index: int, output_path: String) -> void:
	if atlases.size() != 2:
		_expect(false, "%s 캡처용 런타임 시트" % context_id)
		return
	var capture := Image.create_empty(1366, 768, false, Image.FORMAT_RGBA8)
	capture.fill(Color("17131f") if context_id == "outpost" else Color("211a35"))
	var panel_color := Color("3b2b45") if context_id == "outpost" else Color("2b3156")
	for y in range(110, 670):
		for x in range(110, 1256):
			if (floori(x / 96.0) + floori(y / 64.0)) % 2 == 0:
				capture.set_pixel(x, y, panel_color)
	for index in range(SPECIES_IDS.size()):
		var atlas: Image = atlases[SPECIES_IDS[index]]
		var frame := atlas.get_region(Rect2i((frame_index % 4) * 192, floori(frame_index / 4.0) * 192, 192, 192))
		frame.resize(288, 288, Image.INTERPOLATE_LANCZOS)
		capture.blend_rect(frame, Rect2i(0, 0, 288, 288), Vector2i(330 + index * 450, 250))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var save_error := capture.save_png(output_path)
	_expect(save_error == OK and FileAccess.file_exists(output_path), "%s 1366×768 런타임 캡처" % context_id)


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
		push_error("[Update4ContractMonsterPresentationPhase30] FAIL: %s" % label)
