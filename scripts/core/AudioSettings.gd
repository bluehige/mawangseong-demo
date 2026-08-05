extends Node

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "audio"
const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const UI_BUS: StringName = &"UI"
const AMBIENCE_BUS: StringName = &"Ambience"
const MASTER_LIMITER_CEILING_DB := -1.0
const DEFAULT_MASTER_VOLUME = 0.85
const DEFAULT_MUSIC_VOLUME = 0.55
const DEFAULT_SFX_VOLUME = 0.90

var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME

func _ready() -> void:
	_ensure_audio_buses()
	_load_settings()
	_apply_all()

func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(MASTER_BUS, master_volume)
	if persist:
		_save_settings()

func set_sfx_volume(value: float, persist: bool = true) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_apply_bus_volume(UI_BUS, sfx_volume)
	_apply_bus_volume(AMBIENCE_BUS, sfx_volume)
	if persist:
		_save_settings()

func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	if persist:
		_save_settings()

func reset_defaults(persist: bool = true) -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	_apply_all()
	if persist:
		_save_settings()

func snapshot() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume
	}

func apply_snapshot(value: Dictionary, persist: bool = false) -> void:
	master_volume = clampf(float(value.get("master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(value.get("music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(value.get("sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	_apply_all()
	if persist:
		_save_settings()

func save() -> void:
	_save_settings()

func _ensure_audio_buses() -> void:
	for bus_config in [
		{"name": MUSIC_BUS, "send": MASTER_BUS},
		{"name": SFX_BUS, "send": MASTER_BUS},
		{"name": UI_BUS, "send": SFX_BUS},
		{"name": AMBIENCE_BUS, "send": SFX_BUS}
	]:
		var bus_name: StringName = bus_config["name"]
		if AudioServer.get_bus_index(bus_name) >= 0:
			var existing_index := AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_send(existing_index, bus_config["send"])
			continue
		AudioServer.add_bus()
		var bus_index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, bus_config["send"])
	_ensure_master_limiter()

func _ensure_master_limiter() -> void:
	var master_index := AudioServer.get_bus_index(MASTER_BUS)
	if master_index < 0:
		return
	var limiter: AudioEffectLimiter = null
	for effect_index in AudioServer.get_bus_effect_count(master_index):
		var effect := AudioServer.get_bus_effect(master_index, effect_index)
		if effect is AudioEffectLimiter:
			limiter = effect
			break
	if limiter == null:
		limiter = AudioEffectLimiter.new()
		AudioServer.add_bus_effect(master_index, limiter)
	limiter.ceiling_db = MASTER_LIMITER_CEILING_DB

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value(SETTINGS_SECTION, "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value(SETTINGS_SECTION, "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value(SETTINGS_SECTION, "sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, "master_volume", master_volume)
	config.set_value(SETTINGS_SECTION, "music_volume", music_volume)
	config.set_value(SETTINGS_SECTION, "sfx_volume", sfx_volume)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("오디오 설정을 저장하지 못했습니다: %s" % error_string(error))

func _apply_all() -> void:
	_ensure_audio_buses()
	_apply_bus_volume(MASTER_BUS, master_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_apply_bus_volume(UI_BUS, sfx_volume)
	_apply_bus_volume(AMBIENCE_BUS, sfx_volume)

func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var muted := value <= 0.0001
	AudioServer.set_bus_mute(bus_index, muted)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
