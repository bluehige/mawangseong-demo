extends RefCounted

const Catalog = preload("res://scripts/audio/AudioCatalogApi.gd")
const PLAYLIST_PATH := "res://data/audio/music_playlists.json"
var playlists: Dictionary = {}
var cursor_by_scene: Dictionary = {}
var last_path := ""

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PLAYLIST_PATH))
	if parsed is Dictionary: playlists = parsed.get("scenes",{})

func candidates(scene: String) -> Array[String]:
	var result: Array[String] = []
	var paths: Array[String] = []
	for event in playlists.get(scene,{}).get("events",[]):
		var resolved := Catalog.resolve_event(str(event))
		var path := str(resolved.get("runtime_path",""))
		if path != "" and ResourceLoader.exists(path) and not paths.has(path):
			result.append(str(event)); paths.append(path)
	return result

func next_event(scene: String, preferred: String = "") -> String:
	var events := candidates(scene)
	if events.is_empty(): return ""
	var index := int(cursor_by_scene.get(scene,0)) % events.size()
	if events.has(preferred): index = events.find(preferred)
	for offset in events.size():
		var candidate := (index+offset)%events.size()
		var path := str(Catalog.resolve_event(events[candidate]).get("runtime_path",""))
		if path == last_path and events.size()>1: continue
		cursor_by_scene[scene] = (candidate+1)%events.size()
		last_path = path
		return events[candidate]
	return ""
