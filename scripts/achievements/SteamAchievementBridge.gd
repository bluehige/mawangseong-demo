extends Node
## Never restarts Steam or waits for a network response. Callbacks own readiness.
signal stats_ready
signal stats_stored(ok: bool)
const APP_ID := 5267750
var api: Object
var stats_available := false
var initialized := false
var initialize_msec := 0.0
var status := "offline"
var retry_seconds := 0.0
var store_pending := false
var progress_pending := false
var progress_queue: Array = []
var prepared_progress: Array = []
var notified_progress := {}

func _ready() -> void:
	set_process(false)
	if OS.get_environment("MAWANG_DISABLE_STEAM") == "1": return
	if Engine.is_editor_hint() or OS.get_name() != "Windows": return
	call_deferred("initialize")

func initialize() -> void:
	if not Engine.has_singleton("Steam"): return
	api = Engine.get_singleton("Steam")
	api.connect("user_stats_received",_received)
	api.connect("user_stats_stored",_stored)
	var started := Time.get_ticks_usec()
	var result: Dictionary = api.call("steamInitEx",APP_ID,false)
	initialize_msec = (Time.get_ticks_usec()-started)/1000.0
	initialized = int(result.get("status",-1)) == 0
	if not initialized:
		status = "offline"; return
	status = "requesting_stats"
	# SDK 1.65 preloads local stats; requestCurrentStats was removed from 4.23.1.
	api.call("requestUserStats",api.call("getSteamID"))
	set_process(true)

func _process(delta: float) -> void:
	if not initialized: return
	api.call("run_callbacks")
	if not stats_available:
		retry_seconds += delta
		if retry_seconds >= 30:
			retry_seconds = 0; api.call("requestUserStats",api.call("getSteamID"))

func _received(game: int, result: int, user: int) -> void:
	if game != APP_ID or user != int(api.call("getSteamID")): return
	stats_available = result == 1
	status = "stats_available" if stats_available else "offline"
	if stats_available: stats_ready.emit()

func _stored(game: int, result: int) -> void:
	if game != APP_ID: return
	# Progress popups also emit user_stats_stored. Keep them outside durable batches.
	if progress_pending:
		progress_pending = false; _next_progress(); return
	if not store_pending: return
	store_pending = false
	stats_stored.emit(result == 1)
	if result == 1:
		progress_queue = prepared_progress.duplicate(true); _next_progress()
	prepared_progress.clear()

func _next_progress() -> void:
	while not progress_queue.is_empty():
		var entry: Dictionary = progress_queue.pop_front()
		if notified_progress.get(entry.id,-1) == entry.amount: continue
		notified_progress[entry.id] = entry.amount
		progress_pending = true
		if bool(api.call("indicateAchievementProgress",entry.id,entry.amount,entry.maximum)): return
		progress_pending = false

func achieved(id: String) -> bool:
	if not stats_available: return false
	var value: Dictionary = api.call("getAchievement",id)
	return bool(value.get("ret",false)) and bool(value.get("achieved",false))

func send(unlocks: Array, stats: Dictionary, catalog: Array) -> bool:
	if not stats_available or store_pending or progress_pending: return false
	var ok := true
	for key in stats:
		var remote: int = api.call("getStatInt",str(key))
		ok = bool(api.call("setStatInt",str(key),maxi(remote,int(stats[key])))) and ok
	prepared_progress.clear()
	for row in catalog:
		var stat := str(row.get("progress_stat",""))
		if stat == "" or stat == "<null>" or not stats.has(stat): continue
		var maximum := int(row.progress_max)
		var amount := mini(maximum,maxi(int(stats[stat]),int(api.call("getStatInt",stat))))
		if amount > 0 and amount < maximum and not achieved(row.api_name):
			prepared_progress.append({"id":row.api_name,"amount":amount,"maximum":maximum})
	for id in unlocks:
		if not achieved(str(id)): ok = bool(api.call("setAchievement",str(id))) and ok
	if not ok: return false
	store_pending = bool(api.call("storeStats"))
	return store_pending

func debug_clear(ids: Array) -> bool:
	if not OS.has_feature("debug") or not stats_available: return false
	for id in ids: api.call("clearAchievement",str(id))
	return bool(api.call("resetAllStats",true))

func _exit_tree() -> void:
	if initialized: api.call("steamShutdown")
