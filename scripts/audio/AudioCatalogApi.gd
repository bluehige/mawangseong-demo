class_name AudioCatalogApi
extends RefCounted

## 오디오 이벤트와 런타임 자산을 하나의 계약으로 확인하는 읽기 전용 API.
## 미등록 ID를 빈 Dictionary로 조용히 바꾸지 않고 진단 로그를 남긴다.

const CATALOG_PATH := "res://data/audio/audio_event_catalog.json"
const RUNTIME_CONNECTION := "actual_runtime"
const EVENT_STATUS_CONNECTED := "connected"

static var _catalog_cache: Dictionary = {}
static var _diagnostics: Array[String] = []


static func load_catalog(force_reload: bool = false) -> Dictionary:
	if not force_reload and not _catalog_cache.is_empty():
		return _catalog_cache
	if not FileAccess.file_exists(CATALOG_PATH):
		_diagnose("AUDIO_CATALOG_FILE_MISSING", CATALOG_PATH)
		_catalog_cache = {}
		return _catalog_cache
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not parsed is Dictionary:
		_diagnose("AUDIO_CATALOG_FORMAT_INVALID", CATALOG_PATH)
		_catalog_cache = {}
		return _catalog_cache
	_catalog_cache = parsed
	return _catalog_cache


static func find_event(event_id: String) -> Dictionary:
	var normalized_id := event_id.strip_edges()
	if normalized_id == "":
		_diagnose("AUDIO_CATALOG_MISSING_EVENT", "<empty>")
		return {}
	var catalog := load_catalog()
	var events_value = catalog.get("events", [])
	if events_value is Array:
		for event_value in events_value:
			if event_value is Dictionary and str(event_value.get("id", "")) == normalized_id:
				return event_value.duplicate(true)
	_diagnose("AUDIO_CATALOG_MISSING_EVENT", normalized_id)
	return {}


static func has_event(event_id: String) -> bool:
	var normalized_id := event_id.strip_edges()
	if normalized_id == "":
		return false
	var events_value = load_catalog().get("events", [])
	if not events_value is Array:
		return false
	for event_value in events_value:
		if event_value is Dictionary and str(event_value.get("id", "")) == normalized_id:
			return true
	return false


static func find_asset(asset_id: String) -> Dictionary:
	var normalized_id := asset_id.strip_edges()
	if normalized_id == "":
		_diagnose("AUDIO_CATALOG_MISSING_ASSET", "<empty>")
		return {}
	var catalog := load_catalog()
	var assets_value = catalog.get("assets", [])
	if assets_value is Array:
		for asset_value in assets_value:
			if asset_value is Dictionary and str(asset_value.get("id", "")) == normalized_id:
				return asset_value.duplicate(true)
	_diagnose("AUDIO_CATALOG_MISSING_ASSET", normalized_id)
	return {}


static func resolve_event(event_id: String) -> Dictionary:
	var event := find_event(event_id)
	if event.is_empty():
		return {}
	var asset_id := str(event.get("asset_id", ""))
	var asset := find_asset(asset_id)
	if asset.is_empty():
		return {}
	if str(event.get("runtime_status", "")) != EVENT_STATUS_CONNECTED:
		_diagnose("AUDIO_CATALOG_EVENT_NOT_CONNECTED", str(event.get("id", event_id)))
		return {}
	var linked_events_value = asset.get("events", [])
	if not linked_events_value is Array or not linked_events_value.has(str(event.get("id", event_id))):
		_diagnose("AUDIO_CATALOG_EVENT_ASSET_MISMATCH", str(event.get("id", event_id)))
		return {}
	var resolved_asset := resolve_asset(asset_id)
	if resolved_asset.is_empty():
		return {}
	if str(event.get("bus", "")) != str(asset.get("bus", "")):
		_diagnose("AUDIO_CATALOG_BUS_MISMATCH", str(event.get("id", event_id)))
		return {}
	return {
		"event": event,
		"asset": asset,
		"runtime_path": resolved_asset.get("runtime_path", "")
	}


static func resolve_asset(asset_id: String) -> Dictionary:
	var asset := find_asset(asset_id)
	if asset.is_empty():
		return {}
	if str(asset.get("runtime_connection", "")) != RUNTIME_CONNECTION:
		_diagnose("AUDIO_CATALOG_ASSET_NOT_RUNTIME", str(asset.get("id", asset_id)))
		return {}
	var runtime_path := _runtime_path(str(asset.get("runtime_path", "")))
	if runtime_path == "" or not ResourceLoader.exists(runtime_path):
		_diagnose("AUDIO_CATALOG_RUNTIME_FILE_MISSING", str(asset.get("id", asset_id)))
		return {}
	return {
		"asset": asset,
		"runtime_path": runtime_path
	}


static func diagnostics() -> Array[String]:
	return _diagnostics.duplicate()


static func reset_for_test() -> void:
	_catalog_cache.clear()
	_diagnostics.clear()


static func _runtime_path(path: String) -> String:
	var normalized := path.strip_edges()
	if normalized == "":
		return ""
	if normalized.begins_with("res://"):
		return normalized
	while normalized.begins_with("/"):
		normalized = normalized.substr(1)
	return "res://%s" % normalized


static func _diagnose(code: String, detail: String) -> void:
	var message := "%s: %s" % [code, detail]
	_diagnostics.append(message)
	push_error(message)
