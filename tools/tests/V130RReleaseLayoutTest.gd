extends "res://tools/tests/V130SavePlotTest.gd"
const Toast = preload("res://scripts/achievements/AchievementToast.gd")

func run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("v130r_release_blockers"):
		get_tree().quit(2); return
	await spawn()
	game._set_screen("management",false)
	for locale in ["en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		game._open_settings_screen()
		for category in ["general","display","combat","accessibility","audio"]:
			game.settings_category=category; game._rebuild_settings_screen(); await settle()
			var fields: Control = game.ui_layer.find_child("SettingsFields",true,false)
			var cards: Array=[]
			for node in fields.get_children():
				if node.has_meta("settings_field_card"): cards.append(node)
			cards.sort_custom(func(a,b): return a.position.y<b.position.y)
			for i in cards.size():
				var card: Control = cards[i]
				var next_y: float = cards[i+1].position.y if i+1<cards.size() else INF
				expect(card.position.y+card.size.y<next_y,"separate cards "+locale+" "+category+" "+str(i))
				for child in fields.get_children():
					if child is Label and child.position.y>=card.position.y and child.position.y<next_y:
						expect(child.position.y+child.size.y+10<=card.position.y+card.size.y,"label bottom padding "+locale+" "+category+" "+child.text.left(20)+" label="+str(child.get_rect())+" card="+str(card.get_rect()))
			if category=="general" and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				var img := get_viewport().get_texture().get_image()
				img.resize(960,540,Image.INTERPOLATE_LANCZOS)
				img.save_png("res://tmp/v130r_release_blockers/settings_"+locale+".png")
		game._cancel_settings_changes(); await settle()
	var toast := Toast.new(); add_child(toast); toast.service=AchievementService
	toast.queue.append(str(AchievementService.catalog.achievements[0].api_name)); toast.show_next(); await settle()
	expect(toast.current.position.y>=160,"toast below top menu/back navigation")
	expect(toast.current.mouse_filter==Control.MOUSE_FILTER_IGNORE,"toast remains click-through")
	toast.queue_free(); await release()
	write_json("res://tmp/v130r_release_blockers/layout_checks.json",{"checks":checks,"failures":failures})
	print("RELEASE_LAYOUT ",checks," checks; failures=",failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
