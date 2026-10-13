extends RefCounted
class_name UIKitLayers
const BACKGROUND_MAP := 0
const MAP_MARKERS := 5
const HUD := 10
const DETAILS := 20
const MODAL := 30
const CUTSCENE := 40
const TOAST_TOOLTIP := 50
var _hidden: Dictionary = {}
var cutscene_active := false

func set_cutscene_active(active: bool, hud_controls: Array) -> void:
	# Repeated active calls also hide newly-created HUD. Restore original visibility.
	cutscene_active = active
	if active:
		for control in hud_controls:
			if not is_instance_valid(control): continue
			if not _hidden.has(control): _hidden[control] = control.visible
			control.hide()
	else:
		for control in _hidden:
			if is_instance_valid(control): control.visible = _hidden[control]
		_hidden.clear()

func track_hud(control: CanvasItem) -> void:
	if cutscene_active: set_cutscene_active(true, [control])
