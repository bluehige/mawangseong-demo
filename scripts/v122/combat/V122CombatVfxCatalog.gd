extends RefCounted
class_name V122CombatVfxCatalog

## 전투 이펙트의 식별자·프레임·배치 규칙을 한 곳에서 읽는 작은 데이터 로더다.
## 실제 SpriteFrames 생성은 CombatSceneController가 담당하고, 이 파일은
## "어떤 ID가 어떤 파일을 쓰는가"와 "어디에 그려야 하는가"만 검증한다.

const CATALOG_PATH := "res://data/v122/combat_vfx_catalog.json"
const VALID_ANCHORS := ["ground", "body", "aerial"]
const VALID_DEPTHS := ["unit_fx", "front_fx", "aerial_fx"]
const VALID_INTENSITIES := ["normal", "finisher", "boss"]


static func load_catalog(path: String = CATALOG_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "catalog": {}, "errors": ["카탈로그 파일이 없습니다: %s" % path]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "catalog": {}, "errors": ["카탈로그 파일을 열 수 없습니다: %s" % path]}
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false, "catalog": {}, "errors": ["카탈로그 최상위 값은 Dictionary여야 합니다: %s" % path]}
	var validation := validate_catalog(parsed, active_ids_from_catalog(parsed))
	return {
		"ok": bool(validation.get("ok", false)),
		"catalog": parsed,
		"errors": validation.get("errors", [])
	}


static func validate_catalog(catalog: Dictionary, active_ids: Array = []) -> Dictionary:
	var errors: Array[String] = []
	var entries = catalog.get("entries", {})
	if not (entries is Dictionary) or entries.is_empty():
		return {"ok": false, "errors": ["entries가 비어 있거나 Dictionary가 아닙니다."]}
	for entry_id_value in entries.keys():
		var entry_id := str(entry_id_value)
		var entry = entries.get(entry_id_value, {})
		if not (entry is Dictionary):
			errors.append("%s: 항목이 Dictionary가 아닙니다." % entry_id)
			continue
		var frames := frame_paths(entry)
		if frames.is_empty():
			errors.append("%s: 프레임 경로가 비어 있습니다." % entry_id)
		else:
			for frame_path_value in frames:
				var frame_path := str(frame_path_value)
				if not ResourceLoader.exists(frame_path):
					errors.append("%s: 프레임 파일이 없습니다: %s" % [entry_id, frame_path])
		var anchor := str(entry.get("anchor", ""))
		if anchor not in VALID_ANCHORS:
			errors.append("%s: anchor가 잘못되었습니다: %s" % [entry_id, anchor])
		var depth := str(entry.get("depth", ""))
		if depth not in VALID_DEPTHS:
			errors.append("%s: depth가 잘못되었습니다: %s" % [entry_id, depth])
		var intensity := str(entry.get("intensity", ""))
		if intensity not in VALID_INTENSITIES:
			errors.append("%s: intensity가 잘못되었습니다: %s" % [entry_id, intensity])
		if float(entry.get("fps", 0.0)) <= 0.0:
			errors.append("%s: fps는 0보다 커야 합니다." % entry_id)
		if not (entry.get("loop", null) is bool):
			errors.append("%s: loop는 bool이어야 합니다." % entry_id)
		if not (entry.get("reduce_flash", null) is bool):
			errors.append("%s: reduce_flash는 bool이어야 합니다." % entry_id)
	for active_id_value in active_ids:
		var active_id := str(active_id_value)
		if active_id != "" and not entries.has(active_id):
			errors.append("활성 VFX ID가 카탈로그에 없습니다: %s" % active_id)
	return {"ok": errors.is_empty(), "errors": errors}


static func frame_paths(entry: Dictionary) -> Array:
	var explicit_frames = entry.get("frames", [])
	if explicit_frames is Array and not explicit_frames.is_empty():
		return explicit_frames.duplicate()
	var pattern := str(entry.get("frame_pattern", ""))
	var frame_count := maxi(0, int(entry.get("frame_count", 0)))
	var frame_start := int(entry.get("frame_start", 0))
	var result: Array = []
	if pattern == "" or frame_count <= 0:
		return result
	for index in range(frame_count):
		result.append(pattern % [frame_start + index] if "%" in pattern else pattern)
	return result


static func resolve_entry(catalog: Dictionary, effect_id: String) -> Dictionary:
	if effect_id == "":
		return {}
	var entries = catalog.get("entries", {})
	if not (entries is Dictionary):
		return {}
	var raw = entries.get(effect_id, {})
	if not (raw is Dictionary):
		return {}
	var result: Dictionary = raw.duplicate(true)
	result["vfx_id"] = effect_id
	result["frames"] = frame_paths(result)
	return result


static func active_ids_from_catalog(catalog: Dictionary) -> Array:
	var ids: Array = []
	var active = catalog.get("active_ids", [])
	if active is Array:
		for value in active:
			var id := str(value)
			if id != "" and not ids.has(id):
				ids.append(id)
	return ids
