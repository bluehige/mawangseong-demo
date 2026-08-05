extends Node

const TARGET_VERSION := "1.2.3"
const WINDOWS_VERSION := "1.2.3.0"
const PROJECT_PATH := "res://project.godot"
const EXPORT_PATH := "res://export_presets.cfg"
const READINESS_PATH := "res://docs/audit/v122/V122_RELEASE_READINESS.json"
const CLOSURE_PATH := "res://docs/audit/v122/V122_IMPLEMENTATION_CLOSURE_MATRIX.json"
const STEAM_CONFIG_PATH := "res://steam/release_config.json"
const SUITE_PATH := "res://tools/tests/core_verification_suite.json"
const OWNER_CHECKLIST_PATH := "res://docs/qa/V122_OWNER_FINAL_REVIEW_CHECKLIST.md"
const LEGACY_USER_DIR := "Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo"

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_audit_project()
	_audit_export_presets()
	_audit_release_readiness_record()
	_audit_steam_contract()
	_audit_suite_registration()
	var engine := Engine.get_version_info()
	_expect(int(engine.get("major", 0)) == 4 and int(engine.get("minor", 0)) >= 5, "Godot runtime is 4.5 or newer")
	print(
		"V122_RELEASE_READINESS_COVERAGE: %s"
		% JSON.stringify({
			"target_version": TARGET_VERSION,
			"platform_presets": 4,
			"owner_checklist": FileAccess.file_exists(OWNER_CHECKLIST_PATH),
			"release_artifacts_created": 0
		})
	)
	if failed:
		print("V122_RELEASE_READINESS_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("V122_RELEASE_READINESS_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _audit_project() -> void:
	var source := FileAccess.get_file_as_string(PROJECT_PATH)
	_expect(source.contains('config/version="%s"' % TARGET_VERSION), "project technical version is 1.2.3")
	_expect(source.contains('config/name="마왕님, 마왕성은 누가 지켜요?"'), "product display name is preserved")
	_expect(source.contains('config/custom_user_dir_name="%s"' % LEGACY_USER_DIR), "legacy save directory is preserved")
	_expect(source.contains('run/main_scene="res://scenes/main/Main.tscn"'), "main scene remains configured")
	_expect(FileAccess.file_exists("res://scenes/main/Main.tscn"), "main scene exists")
	_expect(FileAccess.file_exists("res://assets/sprites/ui/ui_icon_infamy.png"), "product icon exists")


func _audit_export_presets() -> void:
	var config := ConfigFile.new()
	_expect(config.load(EXPORT_PATH) == OK, "export presets parse")
	var web := _preset_index(config, "Web")
	var windows := _preset_index(config, "Windows Desktop")
	var mobile := _preset_index(config, "Web Mobile")
	var steam := _preset_index(config, "Windows Steam")
	_expect(web >= 0 and windows >= 0 and mobile >= 0 and steam >= 0, "all four platform presets exist")

	_expect(str(config.get_value("preset.%d" % web, "platform", "")) == "Web", "PC Web platform")
	_expect(str(config.get_value("preset.%d" % web, "export_path", "")) == "web_Demo/index.html", "PC Web export path")
	_expect(bool(config.get_value("preset.%d.options" % web, "vram_texture_compression/for_desktop", false)), "PC Web desktop compression")

	_expect(str(config.get_value("preset.%d" % windows, "platform", "")) == "Windows Desktop", "Windows desktop platform")
	_expect(str(config.get_value("preset.%d" % windows, "export_path", "")) == "builds/MawangCastle_v1.2.3/MawangCastle_v1.2.3.exe", "Windows desktop versioned path")
	_audit_windows_options(config, windows, true)

	_expect(str(config.get_value("preset.%d" % mobile, "platform", "")) == "Web", "Mobile Web platform")
	_expect(str(config.get_value("preset.%d" % mobile, "custom_features", "")) == "mobile_web", "Mobile Web feature flag")
	_expect(str(config.get_value("preset.%d" % mobile, "export_path", "")) == "tmp/mobile_web_export/index.html", "Mobile Web review path")
	_expect(int(config.get_value("preset.%d.options" % mobile, "progressive_web_app/orientation", 0)) == 1, "Mobile Web landscape orientation")

	_expect(str(config.get_value("preset.%d" % steam, "platform", "")) == "Windows Desktop", "Steam Windows platform")
	_expect(str(config.get_value("preset.%d" % steam, "export_path", "")) == "builds/steam/windows/MawangCastle.exe", "Steam depot executable path")
	_audit_windows_options(config, steam, false)

	for index in [web, windows, mobile, steam]:
		var excluded := str(config.get_value("preset.%d" % index, "exclude_filter", ""))
		for required in ["assets/source/*", "docs/*", "tmp/*", "tools/*"]:
			_expect(excluded.contains(required), "%s excludes %s" % [str(config.get_value("preset.%d" % index, "name", "")), required])


func _audit_windows_options(config: ConfigFile, index: int, require_versioned_description: bool) -> void:
	var section := "preset.%d.options" % index
	_expect(str(config.get_value(section, "binary_format/architecture", "")) == "x86_64", "Windows preset is x86_64")
	_expect(not bool(config.get_value(section, "codesign/enable", true)), "Windows signing is an explicit external owner gate")
	_expect(bool(config.get_value(section, "application/modify_resources", false)), "Windows resources are enabled")
	_expect(str(config.get_value(section, "application/file_version", "")) == WINDOWS_VERSION, "Windows file version is 1.2.3.0")
	_expect(str(config.get_value(section, "application/product_version", "")) == WINDOWS_VERSION, "Windows product version is 1.2.3.0")
	var icon := str(config.get_value(section, "application/icon", ""))
	_expect(icon != "" and FileAccess.file_exists(icon), "Windows icon exists")
	if require_versioned_description:
		_expect(str(config.get_value(section, "application/file_description", "")).contains("v1.2.3"), "Windows desktop description carries v1.2.3")


func _audit_release_readiness_record() -> void:
	var readiness := _load_json(READINESS_PATH)
	_expect(int(readiness.get("schema_version", 0)) == 1, "readiness schema")
	_expect(str(readiness.get("target_version", "")) == TARGET_VERSION, "readiness target version")
	_expect(str(readiness.get("source_rc_state", "")) == "READY_FOR_OWNER_FINAL_QA", "source RC is ready for owner QA")
	_expect(str(readiness.get("windows_file_version", "")) == WINDOWS_VERSION, "readiness Windows version")
	var project: Dictionary = readiness.get("project", {})
	_expect(bool(project.get("legacy_user_data_path_preserved", false)), "readiness records save-path preservation")
	_expect(str(project.get("custom_user_dir_name", "")) == LEGACY_USER_DIR, "readiness save path matches project")
	var artifacts: Dictionary = readiness.get("release_artifact_names", {})
	_expect(str(artifacts.get("windows_zip", "")) == "MawangCastle-v1.2.3-Windows.zip", "Windows ZIP contract")
	_expect(str(artifacts.get("web_zip", "")) == "mawangseong-v1.2.3-web.zip", "Web ZIP contract")
	_expect(str(artifacts.get("tag", "")) == "v1.2.3", "tag contract")
	_expect(str(artifacts.get("github_release", "")) == "마왕성 v1.2.3", "GitHub Release contract")
	var boundary: Dictionary = readiness.get("execution_boundary", {})
	for key in ["full_verification", "day01_30_manual_play", "windows_export", "web_export", "mobile_web_export", "steam_export", "tag", "github_release", "public_deploy"]:
		_expect(str(boundary.get(key, "")) != "" and not str(boundary.get(key, "")).contains("PASS"), "%s remains outside P17 execution" % key)
	var preservation: Dictionary = readiness.get("preservation", {})
	_expect(str(preservation.get("v1.2.1_tag", "")) == "IMMUTABLE", "v1.2.1 tag stays immutable")
	_expect(str(preservation.get("v1.2.1_release", "")) == "IMMUTABLE", "v1.2.1 Release stays immutable")
	_expect(FileAccess.file_exists(OWNER_CHECKLIST_PATH), "owner final-review checklist exists")

	var closure := _load_json(CLOSURE_PATH)
	var forbidden: Array = closure.get("forbidden_statuses", [])
	var forbidden_count := 0
	for feature_value in closure.get("features", []):
		if feature_value is Dictionary and forbidden.has(str(feature_value.get("status", ""))):
			forbidden_count += 1
	_expect(forbidden_count == 0, "P16 forbidden implementation status remains zero")


func _audit_steam_contract() -> void:
	var steam := _load_json(STEAM_CONFIG_PATH)
	var product: Dictionary = steam.get("product", {})
	var build: Dictionary = steam.get("build", {})
	var cloud: Dictionary = steam.get("cloud", {})
	_expect(str(build.get("godot_version", "")) == "4.5.2", "Steam Godot version contract")
	_expect(str(build.get("export_preset", "")) == "Windows Steam", "Steam preset contract")
	_expect(str(build.get("architecture", "")) == "x86_64", "Steam architecture contract")
	_expect(product.get("supported_os", []).has("windows"), "Steam supported OS contract")
	_expect(str(cloud.get("subdirectory", "")) == LEGACY_USER_DIR, "Steam Cloud preserves legacy save directory")
	_expect(int(product.get("app_id", -1)) == 0 and int(product.get("windows_depot_id", -1)) == 0, "unassigned Steam IDs remain explicit owner gates")
	var external_gate_count := 0
	for value in steam.get("release_gates", {}).values():
		if value is bool and not value:
			external_gate_count += 1
	_expect(external_gate_count == 11, "all 11 Steam owner gates remain explicit")
	_expect(FileAccess.file_exists("res://tools/release/PrepareSteamBuild.ps1"), "Steam build tool exists")
	_expect(FileAccess.file_exists("res://tools/release/validate_steam_release.py"), "Steam validator exists")


func _audit_suite_registration() -> void:
	var suite := _load_json(SUITE_PATH)
	var found := false
	for check_value in suite.get("checks", []):
		if not check_value is Dictionary:
			continue
		var check: Dictionary = check_value
		if str(check.get("id", "")) != "v122_release_readiness":
			continue
		found = true
		_expect(check.get("modes", []).has("quick") and check.get("modes", []).has("full"), "release readiness is in Quick and Full")
		_expect(str(check.get("scene", "")) == "res://tools/tests/V122ReleaseReadinessTest.tscn", "release readiness scene is canonical")
	_expect(found, "release readiness check is registered")


func _preset_index(config: ConfigFile, target_name: String) -> int:
	for index in range(8):
		if str(config.get_value("preset.%d" % index, "name", "")) == target_name:
			return index
	return -1


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		return
	failed = true
	push_error(message)
