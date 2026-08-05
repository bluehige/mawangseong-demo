extends Node

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	var catalog: Dictionary = DataRegistry.combat_visual_profiles
	_expect(not catalog.is_empty(), "전투 시각 프로필 catalog가 로드되어야 한다")
	if catalog.is_empty():
		_finish()
		return

	_expect(int(catalog.get("schema_version", 0)) == 1, "V1-A schema_version은 1이어야 한다")
	_expect(str(catalog.get("profile_id", "")) == "v122_cave_combat_visual_v1", "V1-A profile_id가 고정되어야 한다")
	var projection: Dictionary = catalog.get("projection", {})
	var tile_size: Dictionary = projection.get("tile_size_px", {})
	_expect(int(tile_size.get("width", 0)) == 128 and int(tile_size.get("height", 0)) == 64, "쿼터뷰 기준 타일은 128x64여야 한다")
	var viewport: Dictionary = projection.get("reference_viewport_px", {})
	_expect(int(viewport.get("width", 0)) == 1280 and int(viewport.get("height", 0)) == 720, "기준 화면은 1280x720이어야 한다")

	var size_classes: Dictionary = catalog.get("size_classes", {})
	for size_class in ["small", "normal", "large", "boss"]:
		var size_entry = size_classes.get(size_class, {})
		_expect(size_entry is Dictionary, "%s 크기 등급이 있어야 한다" % size_class)
		if size_entry is Dictionary:
			_expect(float(size_entry.get("nominal_height_tiles", 0.0)) > 0.0, "%s 높이 비례값이 있어야 한다" % size_class)

	var motion_modes: Dictionary = catalog.get("motion_modes", {})
	for motion_mode in ["grounded", "flying"]:
		var mode_entry = motion_modes.get(motion_mode, {})
		_expect(mode_entry is Dictionary, "%s 이동 모드가 있어야 한다" % motion_mode)
		if mode_entry is Dictionary:
			_expect((mode_entry.get("foot_anchor", []) as Array).size() == 2, "%s 발 앵커가 2축이어야 한다" % motion_mode)
			_expect((mode_entry.get("shadow_offset_tiles", []) as Array).size() == 2, "%s 그림자 오프셋이 2축이어야 한다" % motion_mode)

	var profiles: Dictionary = catalog.get("profiles", {})
	_expect(profiles.size() == 8, "크기 4종과 이동 2종의 조합 프로필 8개가 있어야 한다")
	var default_id := str(catalog.get("default_profile_id", ""))
	_expect(default_id != "" and profiles.has(default_id), "기본 프로필 ID가 실제 프로필을 가리켜야 한다")
	for profile_id in profiles.keys():
		var profile: Dictionary = profiles[profile_id]
		_expect(size_classes.has(str(profile.get("size_class", ""))), "%s가 유효한 크기 등급을 가리켜야 한다" % profile_id)
		_expect(motion_modes.has(str(profile.get("motion_mode", ""))), "%s가 유효한 이동 모드를 가리켜야 한다" % profile_id)

	var default_profile := DataRegistry.combat_visual_profile()
	_expect(default_profile == profiles[default_id], "registry 기본 조회가 catalog와 일치해야 한다")
	default_profile["size_class"] = "mutated_only_for_test"
	_expect(str(DataRegistry.combat_visual_profile().get("size_class", "")) != "mutated_only_for_test", "registry 조회는 깊은 복사여야 한다")

	var audit_contract: Dictionary = catalog.get("audit_contract", {})
	_expect((audit_contract.get("source_frame_px", []) as Array).size() == 2, "감사 기준 원본 프레임 크기가 있어야 한다")
	_expect(float(audit_contract.get("foot_jitter_limit_px", 0.0)) == 2.0, "발 흔들림 한도는 2픽셀이어야 한다")

	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: PASS")
		get_tree().quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("V122_COMBAT_VISUAL_PROFILE_CONTRACT_TEST: FAIL")
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
