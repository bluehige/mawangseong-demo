class_name AudioDirector
extends Node

## 오디오 catalog를 실제 일회성 재생으로 연결하는 공통 감독자.
## 호출자는 파일 경로를 직접 열지 않고 event ID만 넘긴다. 감독자는
## catalog 해석, voice 예산, 중복 토큰, 플레이어 수명 관리를 한 곳에서 맡는다.

const CatalogScript = preload("res://scripts/audio/AudioCatalogApi.gd")
const AllocatorScript = preload("res://scripts/audio/AudioVoiceAllocator.gd")

var effect_root: Node = null
var allocator = AllocatorScript.new()
var _players: Dictionary = {}
var _serial := 0


func setup(effect_root_value: Node) -> void:
	effect_root = effect_root_value


func play_event(
	event_id: String,
	volume_db: float = -8.0,
	category: String = "",
	priority: int = -1,
	event_group: String = "",
	instance_key: String = "",
	pitch_scale: float = 1.0
) -> Dictionary:
	var resolved: Dictionary = CatalogScript.resolve_event(event_id)
	if resolved.is_empty():
		return _rejected(event_id, "catalog_unresolved")
	var event: Dictionary = resolved.get("event", {})
	var asset: Dictionary = resolved.get("asset", {})
	var resolved_path := str(resolved.get("runtime_path", ""))
	if resolved_path == "":
		return _rejected(event_id, "runtime_path_missing")
	var normalized_category := _category_for(event_id, event, asset, category)
	var normalized_priority := _priority_for(event_id, event, asset, priority)
	var normalized_group := event_group.strip_edges()
	if normalized_group == "":
		normalized_group = event_id.strip_edges()
	var voice_id := instance_key.strip_edges()
	if voice_id == "":
		_serial += 1
		voice_id = "%s#%d" % [event_id.strip_edges(), _serial]
	var admission: Dictionary = allocator.admit_voice(
		voice_id,
		normalized_category,
		normalized_priority,
		normalized_group,
		Time.get_ticks_usec() / 1000000.0
	)
	if not bool(admission.get("accepted", false)):
		return _rejected(event_id, str(admission.get("reason", "voice_rejected")), admission)
	var evicted_id := str(admission.get("evicted_id", ""))
	if evicted_id != "":
		_stop_player(evicted_id)
	var stream := load(resolved_path) as AudioStream
	if stream == null:
		allocator.release_voice(voice_id)
		return _rejected(event_id, "stream_load_failed")
	if effect_root == null or not is_instance_valid(effect_root):
		allocator.release_voice(voice_id)
		return _rejected(event_id, "effect_root_missing")
	var player := AudioStreamPlayer.new()
	player.name = "AudioDirector_%s" % _safe_node_token(voice_id)
	player.stream = stream
	player.bus = _bus_for(event, asset)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	effect_root.add_child(player)
	_players[voice_id] = player
	player.finished.connect(Callable(self, "_on_voice_finished").bind(voice_id))
	player.play()
	return {
		"accepted": true,
		"event_id": event_id,
		"asset_id": str(event.get("asset_id", "")),
		"voice_id": voice_id,
		"evicted_id": evicted_id,
		"player": player,
		"reason": str(admission.get("reason", "admitted"))
	}


func play_asset(
	asset_id: String,
	volume_db: float = -8.0,
	category: String = "",
	priority: int = -1,
	event_group: String = "",
	instance_key: String = "",
	pitch_scale: float = 1.0
) -> Dictionary:
	var asset: Dictionary = CatalogScript.find_asset(asset_id)
	if asset.is_empty():
		return _rejected(asset_id, "catalog_asset_missing")
	var event_ids = asset.get("events", [])
	if not event_ids is Array or event_ids.is_empty():
		return _rejected(asset_id, "asset_unconnected")
	return play_event(str(event_ids[0]), volume_db, category, priority, event_group, instance_key, pitch_scale)


func active_voice_count() -> int:
	return allocator.active_count()


func active_voice_ids() -> Array:
	return allocator.active_voice_ids()


func stop_voice(voice_id: String) -> bool:
	var normalized_id := voice_id.strip_edges()
	var was_active := allocator.release_voice(normalized_id)
	_stop_player(normalized_id)
	return was_active


func stop_all() -> void:
	var voice_ids: Array = allocator.active_voice_ids()
	for voice_id_value in voice_ids:
		_stop_player(str(voice_id_value))
	allocator.clear()
	_players.clear()


func _on_voice_finished(voice_id: String) -> void:
	allocator.release_voice(voice_id)
	var player = _players.get(voice_id)
	_players.erase(voice_id)
	if player != null and is_instance_valid(player):
		player.queue_free()


func _stop_player(voice_id: String) -> void:
	var player = _players.get(voice_id)
	_players.erase(voice_id)
	if player != null and is_instance_valid(player):
		player.stop()
		player.queue_free()


func _category_for(event_id: String, event: Dictionary, asset: Dictionary, requested: String) -> String:
	var explicit := requested.strip_edges().to_lower()
	if explicit in AllocatorScript.VALID_CATEGORIES:
		return explicit
	var metadata := str(event.get("voice_category", asset.get("voice_category", ""))).strip_edges().to_lower()
	if metadata in AllocatorScript.VALID_CATEGORIES:
		return metadata
	if event_id.begins_with("ui.") or event_id.contains(".ui."):
		return AllocatorScript.CATEGORY_UI
	if event_id.contains("footstep") or event_id.contains("step"):
		return AllocatorScript.CATEGORY_FOOTSTEP
	return AllocatorScript.CATEGORY_GENERAL


func _priority_for(event_id: String, event: Dictionary, asset: Dictionary, requested: int) -> int:
	if requested >= 0:
		return requested
	var metadata = event.get("voice_priority", asset.get("voice_priority", null))
	if metadata != null:
		return int(metadata)
	var lowered := event_id.to_lower()
	if lowered.contains("boss") or lowered.contains("warning") or lowered.contains("alarm"):
		return AllocatorScript.PRIORITY_CRITICAL
	if lowered.begins_with("ui.") or lowered.contains(".ui."):
		return AllocatorScript.PRIORITY_UI
	if lowered.contains("skill") or lowered.contains("crown") or lowered.contains("duo"):
		return AllocatorScript.PRIORITY_UNIQUE
	if lowered.contains("footstep") or lowered.contains("step"):
		return AllocatorScript.PRIORITY_FOOTSTEP
	return AllocatorScript.PRIORITY_GENERAL


func _bus_for(event: Dictionary, asset: Dictionary) -> String:
	var requested := str(event.get("bus", asset.get("bus", AudioSettings.SFX_BUS)))
	if AudioServer.get_bus_index(requested) >= 0:
		return requested
	return AudioSettings.SFX_BUS


func _safe_node_token(value: String) -> String:
	var token := value.replace("/", "_").replace(":", "_").replace(" ", "_")
	return token if token != "" else "voice"


func _rejected(event_id: String, reason: String, details: Dictionary = {}) -> Dictionary:
	var result := {
		"accepted": false,
		"event_id": event_id,
		"voice_id": "",
		"evicted_id": "",
		"reason": reason
	}
	for key in details.keys():
		result[str(key)] = details[key]
	return result
