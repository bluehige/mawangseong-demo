extends Node
var game: Node
var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	run.call_deferred()

func settle() -> void:
	for i in 8: await get_tree().process_frame

func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); print("FAIL ",message)

func ids() -> Array:
	var result: Array = []
	for name in ["DialogueText","DialogueSpeakerLabel","LegacyNextButton","DialogueToolbar","DialogueBackground","DialogueStandingLeft","DialogueStandingRight"]:
		var control: Node = game.ui_layer.find_child(name,true,false)
		result.append(control.get_instance_id() if control != null else 0)
	return result

func run() -> void:
	game = load("res://scenes/game/GameRoot.tscn").instantiate()
	game.campaign_save_enabled = false; game.campaign_auxiliary_save_enabled = false
	game.campaign_save_v5_enabled = false; game.campaign_save_v6_enabled = false
	add_child(game); await settle()
	game.set_process(false); game.set_physics_process(false); game.start_flow.set_process(false)
	game.story_feature_enabled = false; game.tutorial_gate_enabled = false; game.tutorial_manager.active = false
	game.campaign_cycle_index = 2
	for locale in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(locale,false)
		var lines: Array = []
		for i in 12:
			lines.append({"speaker":["CHR_BATI","CHR_THIEF_NIA","CHR_GOLDIN"][i%3],"emotion":"teasing","trigger":"opening_start","text":"한글 English 中文 대화 페이지 내용. ".repeat(20)+str(i),"background":"res://assets/ui/v1213/dialogue_throne.png" if i%2==0 else "res://assets/ui/onboarding/scenes/scene_demon_castle_dialogue.png"})
		game._onboarding_begin_dialogue(lines,"title","")
		await settle()
		var stable_ids := ids()
		var initial_textures: Dictionary = game.story_presenter.standing_textures.duplicate()
		var first_body: RichTextLabel = game.story_presenter.page_body
		for i in 10:
			while game.story_presenter.page_index+1<game.story_presenter.text_pages.size():
				game._onboarding_advance_dialogue()
			game._onboarding_advance_dialogue(); await settle()
			expect(ids()==stable_ids,locale+" dialogue controls reused")
			expect(game.story_presenter.standing_textures==initial_textures,locale+" no lazy portrait load after entry")
			expect(game.story_presenter.page_body.get_meta("dialogue_full_text")==lines[i+1].text,locale+" exact source")
			var background: TextureRect = game.ui_layer.find_child("DialogueBackground",true,false)
			expect(background.texture==game.story_presenter.background_textures[lines[i+1].background],locale+" background changes")
			for page in game.story_presenter.text_pages:
				first_body.text=page.strip_edges()
				expect(first_body.get_content_height()<=first_body.size.y+1,locale+" no rendered overflow")
			game.story_presenter._show_page()
		var history: int = game.continuity.history.size()
		var cache_count: int = game.story_presenter.pagination_cache.size()
		game._story_refresh_dialogue_ui(); await settle()
		expect(game.continuity.history.size()==history,locale+" refresh does not duplicate history")
		expect(game.story_presenter.pagination_cache.size()==cache_count,locale+" repeated measurement cached")
		game.continuity.open_backlog(); await settle()
		var index: int = game.onboarding_dialogue_index
		game._onboarding_advance_dialogue(); expect(game.onboarding_dialogue_index==index,locale+" log blocks")
		game.continuity.close_backlog(); await settle()
		expect(ids()==stable_ids,locale+" log preserves frame")
		get_window().size=Vector2i(1280,720); await settle()
		expect(game.story_presenter.page_body.get_meta("dialogue_full_text")==lines[index].text,locale+" resize preserves text")
		get_window().size=Vector2i(1920,1080); await settle()
		UISettings.set_text_scale(1.15,false)
		game._story_refresh_dialogue_ui(); await settle()
		expect(ids()!=stable_ids,locale+" scale invalidates frame")
		expect(game.story_presenter.page_body.get_meta("dialogue_full_text")==lines[index].text,locale+" scale preserves text")
		UISettings.set_text_scale(1.0,false)
		game._onboarding_skip_dialogue(); await settle()
		expect(game.current_screen=="title",locale+" skip completes")
	# The combat overlay also keeps its controls and pause layers during a cue.
	game.onboarding_dialogue_queue.clear(); game.story_feature_enabled=true
	game.story_director.current_scene_id="STORY_D01_MANAGEMENT_ENTRY"
	game.story_director.current_cue_id="PERF_CORE_1"
	game.story_director._active_cues.assign([
		{"id":"PERF_CORE_1","speaker_id":"CHR_BATI","text_ko":"첫 대사"},
		{"id":"PERF_CORE_2","speaker_id":"CHR_BATI","text_ko":"다음 대사"}])
	game.hud.clear(); game.current_screen="combat"; game.story_combat_overlay_open=true
	game.story_presenter.build_combat_overlay(); await settle()
	var overlay: Node = game.ui_layer.get_node("StoryCombatDialogueOverlay")
	var body_id: int = game.story_presenter.page_body.get_instance_id()
	game._story_advance_dialogue(); await settle()
	expect(game.ui_layer.get_node("StoryCombatDialogueOverlay")==overlay,"combat overlay reused")
	expect(game.story_presenter.page_body.get_instance_id()==body_id,"combat text reused")
	expect(game.story_director.current_cue_id=="PERF_CORE_2","combat cue advances")
	game.story_presenter.clear_combat_overlay()
	game.campaign_autosave_pending=false; game._shutdown_audio_for_exit()
	print("PASS V131DialogueReuse checks=",checks," failures=",failures.size())
	game.queue_free(); await settle()
	get_tree().quit(0 if failures.is_empty() else 1)
