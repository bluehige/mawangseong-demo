extends "res://tools/tests/V130SavePlotTest.gd"
## Historical save copies only; originals remain byte-for-byte unchanged.
func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("v130r_release_blockers"):
		get_tree().quit(2); return
	var sources: Array=[]
	var run_id := str(Time.get_unix_time_from_system()).replace(".","_")
	for version in range(1,7):
		var source := "res://tmp/v130_m6/original_copies/campaign_save_v%d.json" % version
		if version==6: source="res://tmp/release_audit_v130b/export_computer_use/appdata/Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo/campaign_save_v6.json"
		expect(FileAccess.file_exists(source),"historical copy v%d exists" % version)
		if not FileAccess.file_exists(source): continue
		var digest := FileAccess.get_sha256(source)
		var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
		await spawn()
		var folder := "user://legacy_"+run_id+"/v%d/" % version
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
		expect(DirAccess.copy_absolute(ProjectSettings.globalize_path(source),ProjectSettings.globalize_path(folder+"campaign_save_v%d.json" % version))==OK,"copy historical v%d" % version)
		use_paths(folder)
		expect(game.campaign_save_status=="valid","historical inspect v%d: %s" % [version,game.campaign_save_error])
		game._continue_campaign_save(); await settle()
		expect(GameState.day==int(original.summary.day),"historical v%d preserves day" % version)
		expect(game.current_screen==str(original.summary.checkpoint),"historical v%d preserves checkpoint" % version)
		expect(FileAccess.get_sha256(source)==digest,"historical v%d source unchanged" % version)
		var result := Store.inspect(folder+"campaign_save_v6.json",DataRegistry.monster_instances,DataRegistry.run_metric_definitions,game._update3_save_catalogs(),DataRegistry.update4_catalogs)
		expect(result.status=="valid","historical v%d writes valid v6" % version)
		sources.append({"version":version,"source":source,"sha256":digest,"day":GameState.day})
		await release()
	write_json("res://tmp/v130r_release_blockers/legacy_checks.json",{"checks":checks,"failures":failures,"sources":sources})
	print("RELEASE_LEGACY ",checks," checks; failures=",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
