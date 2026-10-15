extends Node
## Created only on Android. Desktop input, timing and save behavior stay unchanged.

var game: Node
var backgrounded := false
var previous_tree_pause := false
var keep_screen_on := false

func setup(value: Node) -> void:
	game = value
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().quit_on_go_back = false
	_update_screen_awake()

func _notification(what: int) -> void:
	if game == null or not is_instance_valid(game): return
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			pause_application()
		NOTIFICATION_APPLICATION_RESUMED:
			resume_application()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			cancel_or_menu()

func pause_application() -> void:
	if backgrounded: return
	backgrounded = true
	previous_tree_pause = get_tree().paused
	# Cancel previews through the existing menu before saving committed state.
	game._open_pause_menu()
	if game._campaign_safe_save_screen(game.current_screen):
		game._schedule_campaign_autosave(game.current_screen)
		game._flush_campaign_autosave()
	# Combat is intentionally not serialized; its last safe checkpoint survives.
	UISettings.save()
	get_tree().paused = true
	_update_screen_awake()

func resume_application() -> void:
	if not backgrounded: return
	backgrounded = false
	get_tree().paused = previous_tree_pause
	# Existing pause menu stays open; the player chooses when to resume combat.
	_update_screen_awake()

func cancel_or_menu() -> void:
	if backgrounded: return
	# Reuse the complete keyboard cancel path, including modals and settings.
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	Input.parse_input_event(event)

func _process(_delta: float) -> void:
	_update_screen_awake()

func _update_screen_awake() -> void:
	if game == null or not is_instance_valid(game): return
	var next_value: bool = game.current_screen == "combat" and not backgrounded
	if next_value == keep_screen_on: return
	keep_screen_on = next_value
	DisplayServer.screen_set_keep_on(keep_screen_on)

func _exit_tree() -> void:
	if backgrounded: get_tree().paused = previous_tree_pause
	if keep_screen_on: DisplayServer.screen_set_keep_on(false)
