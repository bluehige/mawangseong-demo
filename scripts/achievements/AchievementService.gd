extends Node
signal unlocked(id: String)
signal progress_changed
const Rules = preload("res://scripts/achievements/AchievementRules.gd")
const Bridge = preload("res://scripts/achievements/SteamAchievementBridge.gd")
const Retro = preload("res://scripts/achievements/AchievementRetro.gd")
const Screen = preload("res://scripts/achievements/AchievementScreen.gd")
const Toast = preload("res://scripts/achievements/AchievementToast.gd")
const CATALOG_PATH := "res://data/v130r/achievements/achievements.json"
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
var judge := Rules.new()
var profile := {"version":1,"unlocked":{},"stats":{},"unique":{},"pending":{},"pending_stats":{}}
var run := {"defeats":0,"hunger_days":0,"complete_history":false,"zero_food":false}
var bridge: Node
var storage_path := "user://achievements_v130.json"
var storage_enabled := true
var storage_error := OK
var inflight := {}
var inflight_seconds := 0.0
var dirty := false
var persist_seconds := 0.0
var transmit_seconds := 0.0
var toast: CanvasLayer
var battle_throne_damage := 0
var steam_reset_requested := false

func _ready() -> void:
	load_profile()
	bridge = Bridge.new(); add_child(bridge)
	bridge.stats_ready.connect(_online)
	bridge.stats_stored.connect(_stored)
	toast = Toast.new(); add_child(toast); toast.setup(self)
	if OS.has_feature("debug") and OS.get_cmdline_user_args().has("--ach-reset-local"):
		debug_reset(false)
	if OS.has_feature("debug") and OS.get_cmdline_user_args().has("--ach-reset-steam"):
		steam_reset_requested = true

func fresh_campaign() -> void:
	run = {"campaign_id":"%d_%d" % [Time.get_unix_time_from_system()*1000,Time.get_ticks_usec()],"defeats":0,"hunger_days":0,"hunger_seen":{},"complete_history":true,"zero_food":false}

func note_hunger(day: int, hungry: bool) -> void:
	if not hungry: return
	var seen: Dictionary = run.get("hunger_seen",{})
	if not seen.has(str(day)):
		seen[str(day)] = true; run.hunger_seen = seen
		run.hunger_days = int(run.get("hunger_days",0))+1
	remember_run()

func remember_run() -> void:
	var id := str(run.get("campaign_id",""))
	if id == "": return
	var histories: Dictionary = profile.get("runs",{})
	var previous: Dictionary = histories.get(id,{})
	for key in ["defeats","hunger_days"]: run[key] = maxi(int(run.get(key,0)),int(previous.get(key,0)))
	var seen: Dictionary = run.get("hunger_seen",{}).duplicate()
	seen.merge(previous.get("hunger_seen",{})); run.hunger_seen = seen
	histories[id] = {"defeats":run.defeats,"hunger_days":run.hunger_days,"hunger_seen":seen.duplicate()}
	profile.runs = histories; dirty = true

func _process(delta: float) -> void:
	persist_seconds += delta
	if dirty and persist_seconds >= 1:
		persist_seconds = 0; persist()
	if not inflight.is_empty():
		inflight_seconds += delta
		if inflight_seconds >= 15: inflight.clear()
	transmit_seconds += delta
	if transmit_seconds >= 60:
		transmit_seconds = 0
		flush()

func record(event: String, facts: Dictionary = {}) -> void:
	for row in catalog.achievements:
		if row.api_name == "ACH_100" and profile.unlocked.size() < 99: continue
		if not profile.unlocked.has(row.api_name) and judge.matches(row.api_name,event,facts): _unlock(row.api_name)
	if profile.unlocked.size() == 99 and not profile.unlocked.has("ACH_100"): _unlock("ACH_100")
	dirty = true
	progress_changed.emit()

func _unlock(id: String) -> void:
	if profile.unlocked.has(id): return
	profile.unlocked[id] = int(Time.get_unix_time_from_system())
	profile.pending[id] = true
	dirty = true; unlocked.emit(id)
	if is_inside_tree(): flush.call_deferred()

func count(stat: String, amount: int = 1, unique_id: String = "") -> void:
	if amount <= 0: return
	var valid := false
	for row in catalog.stats:
		if row.api_name == stat: valid = true; break
	if not valid: return
	if unique_id != "":
		var seen: Dictionary = profile.unique.get(stat,{})
		if seen.has(unique_id): return
		seen[unique_id] = true; profile.unique[stat] = seen
	set_total(stat,mini(2147483647,int(profile.stats.get(stat,0))+amount))

func set_total(stat: String, value: int) -> void:
	if value <= int(profile.stats.get(stat,0)): return
	profile.stats[stat] = value; profile.pending_stats[stat] = value
	record("progress",profile.stats)

func snapshot() -> Dictionary:
	remember_run()
	return {"profile":profile.duplicate(true),"run":run.duplicate(true)}

func restore_snapshot(saved: Dictionary) -> void:
	var other: Dictionary = saved.get("profile",{})
	for id in other.get("unlocked",{}):
		if judge.rules.has(id) and not profile.unlocked.has(id):
			profile.unlocked[id] = other.unlocked[id]; profile.pending[id] = true
	for stat in other.get("stats",{}): set_total(stat,int(other.stats[stat]))
	for stat in other.get("unique",{}):
		var merged: Dictionary = profile.unique.get(stat,{})
		merged.merge(other.unique[stat]); profile.unique[stat] = merged
	var histories: Dictionary = profile.get("runs",{})
	for id in other.get("runs",{}):
		var previous: Dictionary = histories.get(id,{})
		var received: Dictionary = other.runs[id]
		var seen: Dictionary = previous.get("hunger_seen",{}).duplicate()
		seen.merge(received.get("hunger_seen",{}))
		histories[id] = {"defeats":maxi(int(previous.get("defeats",0)),int(received.get("defeats",0))),"hunger_days":maxi(int(previous.get("hunger_days",0)),int(received.get("hunger_days",0))),"hunger_seen":seen}
	profile.runs = histories
	if saved.get("run") is Dictionary: run = saved.run.duplicate(true)
	remember_run()
	dirty = true

func retroactive(payload: Dictionary, update4: Dictionary = {}) -> void:
	Retro.apply(self,payload,update4)

func observe_game(game: Node) -> void:
	Retro.observe(self,game)

func persist() -> bool:
	if not storage_enabled: dirty = false; return true
	var temporary := storage_path+".tmp"
	var file := FileAccess.open(temporary,FileAccess.WRITE)
	if file == null: storage_error = FileAccess.get_open_error(); return false
	file.store_string(JSON.stringify(profile)); file.flush(); file.close()
	var backup := storage_path+".bak"
	if FileAccess.file_exists(storage_path):
		storage_error = DirAccess.copy_absolute(storage_path,backup)
		if storage_error != OK: return false
	storage_error = DirAccess.rename_absolute(temporary,storage_path)
	if storage_error == OK: dirty = false
	return storage_error == OK

func load_profile() -> void:
	if not storage_enabled: return
	for path in [storage_path,storage_path+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK: continue
		var value: Variant = parser.data
		if not value is Dictionary: continue
		var valid := true
		for key in ["unlocked","stats","unique","pending","pending_stats"]:
			if not value.get(key) is Dictionary: valid = false
		if valid:
			profile = value; return

func _online() -> void:
	if steam_reset_requested:
		steam_reset_requested = false; debug_reset(true); return
	for row in catalog.achievements:
		if bridge.achieved(row.api_name) and not profile.unlocked.has(row.api_name):
			profile.unlocked[row.api_name] = int(Time.get_unix_time_from_system()); dirty = true
	# Reconcile every local high water stat; Steam progress never regresses.
	profile.pending_stats.merge(profile.stats,true)
	if profile.unlocked.size() == 99 and not profile.unlocked.has("ACH_100"): _unlock("ACH_100")
	flush()

func flush() -> void:
	if bridge == null or not bridge.stats_available or not inflight.is_empty(): return
	if profile.pending.is_empty() and profile.pending_stats.is_empty(): return
	# Write ahead of Steam; only a successful store callback acknowledges this batch.
	if not persist(): return
	inflight = {"unlocks":profile.pending.keys(),"stats":profile.pending_stats.duplicate(true)}
	inflight_seconds = 0
	if not bridge.send(inflight.unlocks,inflight.stats,catalog.achievements): inflight.clear()

func _stored(ok: bool) -> void:
	if inflight.is_empty(): return
	if ok:
		for id in inflight.unlocks: profile.pending.erase(id)
		for key in inflight.stats:
			if profile.pending_stats.get(key,-1) == inflight.stats[key]: profile.pending_stats.erase(key)
		dirty = true; persist()
	inflight.clear()

func debug_reset(steam_too: bool = false) -> bool:
	if not OS.has_feature("debug"): return false
	if steam_too and (bridge == null or not bridge.debug_clear(judge.rules.keys())): return false
	profile = {"version":1,"unlocked":{},"stats":{},"unique":{},"pending":{},"pending_stats":{}}
	inflight.clear(); fresh_campaign(); dirty = true; persist(); progress_changed.emit()
	return true

func open_screen() -> void:
	var screen := Screen.new(); add_child(screen); screen.setup(self)

func _exit_tree() -> void:
	if dirty: persist()
