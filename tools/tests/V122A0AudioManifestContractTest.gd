extends SceneTree

const MANIFEST_PATH := "res://tools/audio/lyria_v122_manifest.json"
const PIPELINE_PATH := "res://tools/audio/lyria_pipeline.py"
const PREVIOUS_MANIFEST_PATH := "res://tools/audio/lyria_v05_manifest.json"
const PREVIOUS_MANIFEST_SHA256 := "B3D17C58746448439F92886C81D01DCAC129E059FEA663AA02024F77D04C47F3"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manifest := _read_manifest()
	var pipeline_source := _read_text(PIPELINE_PATH)
	var assets: Array = manifest.get("assets", [])
	var defaults: Dictionary = manifest.get("defaults", {})
	var checks: Array[String] = [
		_check(manifest.get("schema_version") == 1, "manifest schema_version is 1"),
		_check(manifest.get("target_version") == "v1.2.2", "target version is v1.2.2"),
		_check(manifest.get("previous_manifest") == "tools/audio/lyria_v05_manifest.json", "previous manifest is preserved"),
		_check(FileAccess.file_exists(PREVIOUS_MANIFEST_PATH) and _sha256(PREVIOUS_MANIFEST_PATH) == PREVIOUS_MANIFEST_SHA256, "previous manifest hash is unchanged"),
		_check(manifest.get("source_root") == "assets/source/audio/lyria/v1.2.2/", "v1.2.2 source root is declared"),
		_check(manifest.get("generation_policy") == "plan-only-until-owner-approval", "generation requires owner approval policy"),
		_check(int(defaults.get("takes", 0)) == 2 and bool(defaults.get("store_interactions", true)) == false, "safe generation defaults are declared"),
		_check(assets.size() == 76, "manifest declares 76 audio assets"),
		_check(_asset_ids_and_paths_are_unique(assets), "asset IDs and runtime paths are unique"),
		_check(_runtime_paths_are_wavs_under_assets(assets), "runtime paths stay under assets/audio and use WAV"),
		_check(_count_wavs("res://assets/audio") == assets.size(), "manifest covers every current runtime WAV"),
		_check(pipeline_source.contains("if not args.execute:"), "generate is dry-run unless --execute is present"),
		_check(pipeline_source.contains("if not confirm:"), "promotion requires explicit --confirm")
	]
	var failures: Array[String] = []
	for result in checks:
		if result.begins_with("FAIL"):
			failures.append(result)
	if failures.is_empty():
		print("V122_A0_AUDIO_MANIFEST_CONTRACT_TEST: PASS (%d checks)" % checks.size())
	else:
		for failure in failures:
			push_error(failure)
		print("V122_A0_AUDIO_MANIFEST_CONTRACT_TEST: FAIL (%d/%d failed)" % [failures.size(), checks.size()])
		quit(1)
		return
	quit(0)

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _read_manifest() -> Dictionary:
	var parsed = JSON.parse_string(_read_text(MANIFEST_PATH))
	return parsed if parsed is Dictionary else {}

func _sha256(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(file.get_buffer(file.get_length()))
	return context.finish().hex_encode().to_upper()

func _asset_ids_and_paths_are_unique(assets: Array) -> bool:
	var ids := {}
	var paths := {}
	for asset in assets:
		if not asset is Dictionary:
			return false
		var asset_id := str(asset.get("id", ""))
		var runtime_path := str(asset.get("runtime_path", ""))
		if asset_id == "" or runtime_path == "" or ids.has(asset_id) or paths.has(runtime_path):
			return false
		ids[asset_id] = true
		paths[runtime_path] = true
	return true

func _runtime_paths_are_wavs_under_assets(assets: Array) -> bool:
	for asset in assets:
		var runtime_path := str(asset.get("runtime_path", ""))
		if not runtime_path.begins_with("assets/audio/") or not runtime_path.to_lower().ends_with(".wav"):
			return false
	return true

func _count_wavs(path: String) -> int:
	var directory := DirAccess.open(path)
	if directory == null:
		return 0
	var count := 0
	directory.list_dir_begin()
	while true:
		var entry := directory.get_next()
		if entry == "":
			break
		if entry == "." or entry == "..":
			continue
		var child_path := path.path_join(entry)
		if directory.current_is_dir():
			count += _count_wavs(child_path)
		elif entry.to_lower().ends_with(".wav"):
			count += 1
	directory.list_dir_end()
	return count

func _check(condition: bool, label: String) -> String:
	return "PASS: %s" % label if condition else "FAIL: %s" % label
