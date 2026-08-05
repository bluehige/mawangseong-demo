extends Node

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var master_index := AudioServer.get_bus_index(AudioSettings.MASTER_BUS)
	var music_index := AudioServer.get_bus_index(AudioSettings.MUSIC_BUS)
	var sfx_index := AudioServer.get_bus_index(AudioSettings.SFX_BUS)
	var ui_index := AudioServer.get_bus_index(AudioSettings.UI_BUS)
	var ambience_index := AudioServer.get_bus_index(AudioSettings.AMBIENCE_BUS)
	_expect(master_index >= 0 and music_index >= 0 and sfx_index >= 0 and ui_index >= 0 and ambience_index >= 0, "오디오 버스 5개 생성")
	_expect(AudioServer.get_bus_send(music_index) == AudioSettings.MASTER_BUS, "Music은 Master로 전송")
	_expect(AudioServer.get_bus_send(sfx_index) == AudioSettings.MASTER_BUS, "SFX는 Master로 전송")
	_expect(AudioServer.get_bus_send(ui_index) == AudioSettings.SFX_BUS, "UI는 SFX로 전송")
	_expect(AudioServer.get_bus_send(ambience_index) == AudioSettings.SFX_BUS, "Ambience는 SFX로 전송")

	var limiter: AudioEffectLimiter = null
	for effect_index in AudioServer.get_bus_effect_count(master_index):
		var effect := AudioServer.get_bus_effect(master_index, effect_index)
		if effect is AudioEffectLimiter:
			limiter = effect
			break
	_expect(limiter != null, "Master limiter 연결")
	_expect(limiter != null and is_equal_approx(limiter.ceiling_db, AudioSettings.MASTER_LIMITER_CEILING_DB), "Master limiter ceiling -1 dBFS")
	AudioSettings._ensure_audio_buses()
	_expect(_count_limiters(master_index) == 1, "오디오 버스 재확인에도 Master limiter 중복 없음")

	var old_music := AudioSettings.music_volume
	var old_sfx := AudioSettings.sfx_volume
	AudioSettings.set_music_volume(0.4, false)
	AudioSettings.set_sfx_volume(0.0, false)
	_expect(AudioServer.is_bus_mute(sfx_index) and AudioServer.is_bus_mute(ui_index) and AudioServer.is_bus_mute(ambience_index), "SFX 0%는 SFX·UI·Ambience를 모두 무음")
	_expect(not AudioServer.is_bus_mute(music_index), "SFX 0%에서도 Music은 유지")
	AudioSettings.set_sfx_volume(0.35, false)
	var expected_sfx_db := linear_to_db(0.35)
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_index), expected_sfx_db), "SFX 설정값이 SFX 버스에 전파")
	_expect(is_equal_approx(AudioServer.get_bus_volume_db(ui_index), expected_sfx_db) and is_equal_approx(AudioServer.get_bus_volume_db(ambience_index), expected_sfx_db), "SFX 설정값이 UI·Ambience 버스에 전파")
	AudioSettings.set_music_volume(old_music, false)
	AudioSettings.set_sfx_volume(old_sfx, false)

	if failed:
		print("AUDIO_BUS_CONTRACT_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("AUDIO_BUS_CONTRACT_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  PASS - %s" % message)
		return
	failed = true
	push_error("  FAIL - %s" % message)


func _count_limiters(bus_index: int) -> int:
	var count := 0
	for effect_index in AudioServer.get_bus_effect_count(bus_index):
		if AudioServer.get_bus_effect(bus_index, effect_index) is AudioEffectLimiter:
			count += 1
	return count
