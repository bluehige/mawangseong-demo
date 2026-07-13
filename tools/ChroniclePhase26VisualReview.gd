extends Node

const FrontServiceScript = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const ChronicleServiceScript = preload("res://scripts/systems/chronicle/ChronicleService.gd")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")

var screen: Control
var failed := false
var output_dir := ""


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	output_dir = ProjectSettings.globalize_path("res://tmp/update3_phase26")
	DirAccess.make_dir_recursive_absolute(output_dir)
	var profile := _review_profile()
	screen = ChronicleScreenScene.instantiate()
	screen.setup(profile, {"fronts": DataRegistry.update3_fronts, "castle_hearts": DataRegistry.update3_castle_hearts, "duo_links": DataRegistry.update3_duo_links}, DataRegistry.update3_chronicle_goals)
	add_child(screen)
	await _capture(Vector2i(1920, 1080), "chronicle_1920x1080.png")
	await _capture(Vector2i(1366, 768), "chronicle_1366x768.png")
	print("CHRONICLE_PHASE26_VISUAL_REVIEW: %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _review_profile() -> Dictionary:
	var profile := FrontServiceScript.default_update3_profile()
	profile["fronts"]["unlocked"] = ["front_hero_oath", "front_holy_purification", "front_guild_repossession"]
	profile["fronts"]["mastery"] = {"front_hero_oath": 100, "front_holy_purification": 68, "front_guild_repossession": 34}
	profile["fronts"]["clear_counts"] = {"front_hero_oath": 3, "front_holy_purification": 2, "front_guild_repossession": 1}
	profile["fronts"]["epilogues_seen"] = ["epilogue_hero_oath", "epilogue_holy_purification"]
	profile["hearts"]["mastery"] = {"heart_stonebone": 100, "heart_hungry_maw": 66, "heart_dream_lantern": 33}
	profile["rival_relations"] = {"leon": 80, "selen": 52, "roman": 39}
	profile["duo_links"]["unlocked"] = ["link_spore_jelly_shelter", "link_ghostly_evacuate", "link_moon_scent_hunt"]
	var active := FrontServiceScript.new_cycle_active_run(1)
	active["front_id"] = "front_hero_oath"
	active["heart"]["heart_id"] = "heart_stonebone"
	for cycle in range(1, 6):
		profile = ChronicleServiceScript.record_run_summary(profile, active, cycle, "true_demon_castle", DataRegistry.ending_rules, DataRegistry.update3_fronts)
	return profile


func _capture(window_size: Vector2i, file_name: String) -> void:
	DisplayServer.window_set_size(window_size)
	screen._queue_rebuild()
	for _index in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or absi(image.get_width() - window_size.x) > 1 or absi(image.get_height() - window_size.y) > 1:
		failed = true
		var actual := Vector2i.ZERO if image == null else Vector2i(image.get_width(), image.get_height())
		push_error("연대기 예상 해상도 %s 캡처 실패 · 실제 %s" % [window_size, actual])
		return
	image.convert(Image.FORMAT_RGB8)
	if image.save_png(output_dir.path_join(file_name)) != OK:
		failed = true
		push_error("연대기 캡처 저장 실패: %s" % file_name)
