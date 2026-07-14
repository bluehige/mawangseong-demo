extends Node

const RivalScript = preload("res://scripts/systems/council/RivalLordService.gd")

const RIVALS := {
	"brassa": {"boss_id": "rival_brassa_council_champion", "rival_id": "rival_brassa", "character_id": "CHR_RIVAL_BRASSA"},
	"vesper": {"boss_id": "rival_vesper_council_champion", "rival_id": "rival_vesper", "character_id": "CHR_RIVAL_VESPER"},
	"mirella": {"boss_id": "rival_mirella_council_champion", "rival_id": "rival_mirella", "character_id": "CHR_RIVAL_MIRELLA"}
}

var failed := false
var assertion_count := 0
var atlases := {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_runtime_presentation()
	_test_letters_and_tone()
	_write_battle_capture(25, 8, "res://tmp/phase31_day25_boss_capture.png")
	_write_battle_capture(30, 12, "res://tmp/phase31_day30_boss_capture.png")
	if failed:
		print("UPDATE4_RIVAL_PRESENTATION_PHASE31_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UPDATE4_RIVAL_PRESENTATION_PHASE31_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_runtime_presentation() -> void:
	var total_frames := 0
	var total_portraits := 0
	for short_id in RIVALS.keys():
		var spec: Dictionary = RIVALS[short_id]
		var boss: Dictionary = DataRegistry.update4_rival_bosses.get(spec.boss_id, {})
		var character: Dictionary = DataRegistry.update4_characters.get(spec.character_id, {})
		var manifest: Dictionary = DataRegistry.update4_asset_manifest.get(str(boss.get("asset_manifest_id", "")), {})
		_expect(not bool(boss.get("placeholder_art", true)) and int(boss.get("frame_count", 0)) == 16, "%s 최종 보스 그래픽 전환" % short_id)
		var atlas_texture = ResourceLoader.load(str(manifest.get("combat_sprite", "")))
		var atlas: Image = atlas_texture.get_image() if atlas_texture is Texture2D else null
		_expect(atlas != null and atlas.get_size() == Vector2i(768, 768), "%s 4×4 런타임 시트" % short_id)
		if atlas != null:
			atlases[short_id] = atlas
			var hashes := {}
			var cells_valid := true
			for index in range(16):
				var cell := atlas.get_region(Rect2i((index % 4) * 192, floori(index / 4.0) * 192, 192, 192))
				var digest := _image_digest(cell)
				if hashes.has(digest) or cell.get_used_rect().size == Vector2i.ZERO:
					cells_valid = false
				hashes[digest] = true
				for point in [Vector2i(0, 0), Vector2i(191, 0), Vector2i(0, 191), Vector2i(191, 191)]:
					if cell.get_pixelv(point).a > 0.01:
						cells_valid = false
			_expect(cells_valid and hashes.size() == 16, "%s 행동별 16프레임 고유·투명 계약" % short_id)
			total_frames += 16
		var portraits: Array = manifest.get("portraits", [])
		_expect(portraits.size() == 4 and portraits.all(func(path): return FileAccess.file_exists(str(path))), "%s 의회·존중·도전·승리 초상 4개" % short_id)
		_expect(not bool(character.get("placeholder_art", true)) and character.get("portraits", {}).size() == 4, "%s 캐릭터 표정 연결" % short_id)
		total_portraits += portraits.size()
		_expect(manifest.get("vfx_frames", []).size() == 4 and manifest.get("vfx_frames", []).all(func(path): return FileAccess.file_exists(str(path))), "%s 보스 VFX 4프레임" % short_id)
		var motif_path := str(manifest.get("motif", ""))
		_expect(motif_path == str(boss.get("boss_motif", "")) and FileAccess.file_exists(motif_path) and FileAccess.get_file_as_bytes(motif_path).size() > 50000, "%s 보스 모티프" % short_id)
		var source_text := FileAccess.get_file_as_string(str(manifest.get("source_record", "")))
		var source_count := source_text.count("Source image path:")
		var runtime_count := source_text.count("Runtime image path:")
		_expect(source_text.contains("Generation model: GPT internal image generation") and source_text.contains("Generated date: 2026-07-14") and source_text.contains("Target version: v0.4"), "%s SOURCE 정책 필드" % short_id)
		_expect(source_count == 2 and runtime_count == 9, "%s 원본 2개·런타임 이미지 9개" % short_id)
		var capture_days: Array = manifest.get("capture_days", [])
		_expect(capture_days.size() == 2 and int(capture_days[0]) == 25 and int(capture_days[1]) == 30, "%s DAY25·30 캡처 계약" % short_id)
	_expect(total_frames == 48 and total_portraits == 12, "경쟁 마왕 전투 48프레임·초상 12개 총계")


func _test_letters_and_tone() -> void:
	var letters: Dictionary = DataRegistry.update4_rival_letters
	_expect(letters.size() == 15, "경쟁 마왕 서신 정확히 15개")
	for short_id in RIVALS.keys():
		var rival_id := str(RIVALS[short_id].rival_id)
		var rival_letters := RivalScript.unlocked_letters(letters, 30, rival_id)
		var days := rival_letters.map(func(letter): return int(letter.get("unlock_day", 0)))
		_expect(rival_letters.size() == 5 and days == [5, 13, 22, 25, 29], "%s 서신 5단계 해금 순서" % short_id)
		var tone_valid := rival_letters.all(func(letter):
			var dialogue := "%s %s" % [letter.get("subject", ""), letter.get("body", "")]
			var keywords: Array = letter.get("tone_keywords", [])
			return keywords.size() == 3 and keywords.all(func(keyword): return dialogue.contains(str(keyword)))
		)
		_expect(tone_valid, "%s 대사 톤 키워드 일치" % short_id)
	_expect(RivalScript.unlocked_letters(letters, 13).size() == 6 and RivalScript.unlocked_letters(letters, 4).is_empty(), "서신 DAY 해금 필터")
	var day29 := RivalScript.day29_letters(letters, DataRegistry.update4_rival_lords)
	_expect(day29.size() == 3 and day29.all(func(letter): return bool(letter.get("codex_only", false)) and not bool(letter.get("combat_bonus", true))), "DAY29 최종 서신 3개·도감 전용")


func _write_battle_capture(day: int, frame_index: int, output_path: String) -> void:
	if atlases.size() != 3:
		_expect(false, "DAY%d 캡처용 런타임 시트" % day)
		return
	var capture := Image.create_empty(1366, 768, false, Image.FORMAT_RGBA8)
	capture.fill(Color("17131f") if day == 25 else Color("241521"))
	var panel_color := Color("41303c") if day == 25 else Color("4c2634")
	for y in range(110, 670):
		for x in range(85, 1281):
			if (floori(x / 96.0) + floori(y / 72.0)) % 2 == 0:
				capture.set_pixel(x, y, panel_color)
	var order := ["brassa", "vesper", "mirella"]
	for index in range(order.size()):
		var short_id: String = order[index]
		var atlas: Image = atlases[short_id]
		var frame := atlas.get_region(Rect2i((frame_index % 4) * 192, floori(frame_index / 4.0) * 192, 192, 192))
		frame.resize(288, 288, Image.INTERPOLATE_LANCZOS)
		var target := Vector2i(170 + index * 405, 250)
		capture.blend_rect(frame, Rect2i(0, 0, 288, 288), target)
		if day == 30:
			var vfx_path := "res://assets/sprites/effects/update4/rivals/fx_%s_boss_03.png" % short_id
			var vfx_texture = ResourceLoader.load(vfx_path)
			if vfx_texture is Texture2D:
				var vfx: Image = vfx_texture.get_image()
				vfx.resize(240, 240, Image.INTERPOLATE_LANCZOS)
				capture.blend_rect(vfx, Rect2i(0, 0, 240, 240), target + Vector2i(24, 24))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var save_error := capture.save_png(output_path)
	_expect(save_error == OK and FileAccess.file_exists(output_path), "DAY%d 1366×768 보스 런타임 캡처" % day)


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
		push_error("[Update4RivalPresentationPhase31] FAIL: %s" % label)
