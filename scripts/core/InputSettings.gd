extends Node

signal bindings_changed(action_id: String)

const SETTINGS_PATH = "user://settings.cfg"
const SETTINGS_SECTION = "controls"

const ACTION_PAUSE: StringName = &"game_pause"
const ACTION_NEXT_MONSTER: StringName = &"next_monster"
const ACTION_DIALOGUE_ADVANCE: StringName = &"dialogue_advance"
const ACTION_CASTLE_HEART: StringName = &"castle_heart"
const ACTION_DUO_LINK_ONE: StringName = &"duo_link_one"
const ACTION_DUO_LINK_TWO: StringName = &"duo_link_two"
const ACTION_ZOOM_IN: StringName = &"combat_zoom_in"
const ACTION_ZOOM_OUT: StringName = &"combat_zoom_out"

const USER_ACTIONS = [
	ACTION_PAUSE,
	ACTION_NEXT_MONSTER,
	ACTION_DIALOGUE_ADVANCE,
	ACTION_CASTLE_HEART,
	ACTION_DUO_LINK_ONE,
	ACTION_DUO_LINK_TWO,
	ACTION_ZOOM_IN,
	ACTION_ZOOM_OUT
]

const ACTION_CONTEXT = {
	ACTION_PAUSE: "combat",
	ACTION_NEXT_MONSTER: "combat",
	ACTION_DIALOGUE_ADVANCE: "dialogue",
	ACTION_CASTLE_HEART: "combat",
	ACTION_DUO_LINK_ONE: "combat",
	ACTION_DUO_LINK_TWO: "combat",
	ACTION_ZOOM_IN: "combat",
	ACTION_ZOOM_OUT: "combat"
}

const DEFAULT_BINDINGS = {
	ACTION_PAUSE: [
		{"type": "key", "physical_keycode": KEY_SPACE}
	],
	ACTION_NEXT_MONSTER: [
		{"type": "key", "physical_keycode": KEY_TAB}
	],
	ACTION_DIALOGUE_ADVANCE: [
		{"type": "key", "physical_keycode": KEY_SPACE},
		{"type": "key", "physical_keycode": KEY_ENTER}
	],
	ACTION_CASTLE_HEART: [
		{"type": "key", "physical_keycode": KEY_H}
	],
	ACTION_DUO_LINK_ONE: [
		{"type": "key", "physical_keycode": KEY_J}
	],
	ACTION_DUO_LINK_TWO: [
		{"type": "key", "physical_keycode": KEY_K}
	],
	ACTION_ZOOM_IN: [
		{"type": "mouse", "button_index": MOUSE_BUTTON_WHEEL_UP},
		{"type": "key", "physical_keycode": KEY_EQUAL}
	],
	ACTION_ZOOM_OUT: [
		{"type": "mouse", "button_index": MOUSE_BUTTON_WHEEL_DOWN},
		{"type": "key", "physical_keycode": KEY_MINUS}
	]
}

var _bindings: Dictionary = {}

func _ready() -> void:
	_load_settings()
	_apply_all_bindings()

func event_matches(event: InputEvent, action_id: StringName) -> bool:
	return InputMap.event_is_action(event, action_id, true)

func binding_events(action_id: StringName) -> Array:
	var result: Array = []
	for binding_value in _bindings.get(action_id, []):
		var event := _event_from_binding(binding_value)
		if event != null:
			result.append(event)
	return result

func set_binding(action_id: StringName, slot: int, event: InputEvent, persist: bool = true) -> bool:
	if action_id not in USER_ACTIONS or slot < 0 or slot > 1:
		return false
	var encoded := _binding_from_event(event)
	if encoded.is_empty():
		return false
	var entries: Array = _bindings.get(action_id, []).duplicate(true)
	while entries.size() <= slot:
		entries.append({})
	entries[slot] = encoded
	entries = entries.filter(func(value): return value is Dictionary and not value.is_empty())
	_bindings[action_id] = entries.slice(0, 2)
	_apply_action_bindings(action_id)
	if persist:
		_save_settings()
	bindings_changed.emit(str(action_id))
	return true

func clear_binding(action_id: StringName, slot: int, persist: bool = true) -> bool:
	if action_id not in USER_ACTIONS or slot < 0 or slot > 1:
		return false
	var entries: Array = _bindings.get(action_id, []).duplicate(true)
	if slot >= entries.size():
		return false
	entries.remove_at(slot)
	_bindings[action_id] = entries
	_apply_action_bindings(action_id)
	if persist:
		_save_settings()
	bindings_changed.emit(str(action_id))
	return true

func conflicting_action(action_id: StringName, event: InputEvent) -> StringName:
	var encoded := _binding_from_event(event)
	if encoded.is_empty():
		return &""
	var context := str(ACTION_CONTEXT.get(action_id, ""))
	for candidate_value in USER_ACTIONS:
		var candidate := candidate_value as StringName
		if candidate == action_id or str(ACTION_CONTEXT.get(candidate, "")) != context:
			continue
		for binding_value in _bindings.get(candidate, []):
			if binding_value == encoded:
				return candidate
	return &""

func reset_defaults(persist: bool = true) -> void:
	_bindings = DEFAULT_BINDINGS.duplicate(true)
	_apply_all_bindings()
	if persist:
		_save_settings()
	for action_value in USER_ACTIONS:
		bindings_changed.emit(str(action_value))

func snapshot() -> Dictionary:
	return _bindings.duplicate(true)

func apply_snapshot(value: Dictionary, persist: bool = false) -> void:
	_bindings = _normalized_bindings(value)
	_apply_all_bindings()
	if persist:
		_save_settings()
	for action_value in USER_ACTIONS:
		bindings_changed.emit(str(action_value))

func save() -> void:
	_save_settings()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_bindings = DEFAULT_BINDINGS.duplicate(true)
		return
	var loaded = config.get_value(SETTINGS_SECTION, "bindings", {})
	_bindings = _normalized_bindings(loaded if loaded is Dictionary else {})

func _normalized_bindings(value: Dictionary) -> Dictionary:
	var result := DEFAULT_BINDINGS.duplicate(true)
	for action_value in USER_ACTIONS:
		var action_id := action_value as StringName
		var stored = value.get(str(action_id), value.get(action_id, null))
		if not stored is Array:
			continue
		var valid: Array = []
		for binding_value in stored:
			if binding_value is Dictionary and _event_from_binding(binding_value) != null:
				valid.append(binding_value.duplicate(true))
			if valid.size() >= 2:
				break
		if not valid.is_empty():
			result[action_id] = valid
	return result

func _apply_all_bindings() -> void:
	for action_value in USER_ACTIONS:
		_apply_action_bindings(action_value as StringName)

func _apply_action_bindings(action_id: StringName) -> void:
	if not InputMap.has_action(action_id):
		InputMap.add_action(action_id)
	InputMap.action_erase_events(action_id)
	for event in binding_events(action_id):
		InputMap.action_add_event(action_id, event)

func _binding_from_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var physical := key_event.physical_keycode
		if physical == KEY_NONE:
			physical = key_event.keycode
		if physical == KEY_NONE or physical == KEY_ESCAPE:
			return {}
		return {
			"type": "key",
			"physical_keycode": physical,
			"shift": key_event.shift_pressed,
			"alt": key_event.alt_pressed,
			"ctrl": key_event.ctrl_pressed,
			"meta": key_event.meta_pressed
		}
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			return {}
		return {"type": "mouse", "button_index": mouse_event.button_index}
	return {}

func _event_from_binding(value) -> InputEvent:
	if not value is Dictionary:
		return null
	match str(value.get("type", "")):
		"key":
			var physical := int(value.get("physical_keycode", KEY_NONE))
			if physical == KEY_NONE or physical == KEY_ESCAPE:
				return null
			var key_event := InputEventKey.new()
			key_event.physical_keycode = physical
			key_event.shift_pressed = bool(value.get("shift", false))
			key_event.alt_pressed = bool(value.get("alt", false))
			key_event.ctrl_pressed = bool(value.get("ctrl", false))
			key_event.meta_pressed = bool(value.get("meta", false))
			return key_event
		"mouse":
			var button_index := int(value.get("button_index", MOUSE_BUTTON_NONE))
			if button_index in [MOUSE_BUTTON_NONE, MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				return null
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = button_index
			return mouse_event
	return null

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var serialized: Dictionary = {}
	for action_value in USER_ACTIONS:
		var action_id := action_value as StringName
		serialized[str(action_id)] = _bindings.get(action_id, []).duplicate(true)
	config.set_value(SETTINGS_SECTION, "bindings", serialized)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("조작 설정을 저장하지 못했습니다: %s" % error_string(error))
