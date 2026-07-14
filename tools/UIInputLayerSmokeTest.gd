extends Node

const MainScene = preload("res://scenes/main/Main.tscn")
const FrontScreenScene = preload("res://scenes/ui/screens/FrontSelectionScreen.tscn")
const HeartScreenScene = preload("res://scenes/ui/screens/HeartSelectionScreen.tscn")
const DuoLoadoutScene = preload("res://scenes/ui/screens/DuoLinkLoadoutScreen.tscn")
const ChronicleScreenScene = preload("res://scenes/ui/screens/ChronicleScreen.tscn")
const HeartHUDScene = preload("res://scenes/ui/hud/HeartCombatHUD.tscn")
const DuoHUDScene = preload("res://scenes/ui/hud/DuoLinkCombatHUD.tscn")
const CampaignModeScreenScene = preload("res://scenes/ui/screens/CampaignModeSelectionScreen.tscn")
const RegionScreenScene = preload("res://scenes/ui/screens/RegionSelectionScreen.tscn")
const OutpostScreenScene = preload("res://scenes/ui/screens/OutpostManagementScreen.tscn")
const UpperFloorScreenScene = preload("res://scenes/ui/screens/UpperFloorScreen.tscn")
const MultiFloorHUDScene = preload("res://scenes/ui/hud/MultiFloorHUD.tscn")
const OutpostBattleScene = preload("res://scenes/outpost/OutpostBattleRoot.tscn")
const FrontService = preload("res://scripts/systems/fronts/FrontCampaignService.gd")
const CampaignModeService = preload("res://scripts/systems/campaign/CampaignModeService.gd")
const HUDControllerScript = preload("res://scripts/ui/HUDController.gd")
const RegionProgressPanelScript = preload("res://scripts/ui/RegionSettlementProgressPanel.gd")
const CrownCandidatePanelScript = preload("res://scripts/ui/CrownCandidatePanel.gd")
const CouncilVoteForecastPanelScript = preload("res://scripts/ui/CouncilVoteForecastPanel.gd")

class HUDRootStub extends Node:
	var ui_layer: CanvasLayer

	func _init() -> void:
		ui_layer = CanvasLayer.new()
		add_child(ui_layer)

var failed := false
var assertion_count := 0
var probe_pressed := false
var heart_hud_state := {
	"heart": {
		"heart_id": "heart_stonebone",
		"awakened": true,
		"charge": 50,
		"disabled_this_battle": false,
		"active_used_this_battle": false,
		"active_remaining": 0.0,
	}
}
var duo_hud_state := {
	"equipped": ["link_spore_jelly_shelter"],
	"states": {
		"link_spore_jelly_shelter": {
			"charge": 100,
			"active": true,
			"used_this_battle": false,
		}
	},
	"names": {"link_spore_jelly_shelter": "포자 젤리 피난처"},
}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	await _test_component_input_contracts()
	await _test_late_decorative_panel_click_through()
	if failed:
		print("UI_INPUT_LAYER_SMOKE_TEST: FAIL (%d assertions)" % assertion_count)
		get_tree().quit(1)
	else:
		print("UI_INPUT_LAYER_SMOKE_TEST: PASS (%d assertions)" % assertion_count)
		get_tree().quit(0)


func _test_component_input_contracts() -> void:
	var profile := FrontService.default_update3_profile()
	var active_run := FrontService.new_cycle_active_run(2)

	var front = FrontScreenScene.instantiate()
	front.setup(profile, DataRegistry.update3_fronts, 2, true)
	await _mount_and_check_passive_controls(front, "front selection")

	var heart = HeartScreenScene.instantiate()
	heart.setup(profile, DataRegistry.update3_castle_hearts, "용사의 맹세 전선", true)
	await _mount_and_check_passive_controls(heart, "heart selection")

	var duo_loadout = DuoLoadoutScene.instantiate()
	duo_loadout.setup(profile, active_run, DataRegistry.update3_duo_links, [])
	await _mount_and_check_passive_controls(duo_loadout, "duo loadout")

	var chronicle = ChronicleScreenScene.instantiate()
	chronicle.setup(profile, {
		"fronts": DataRegistry.update3_fronts,
		"castle_hearts": DataRegistry.update3_castle_hearts,
		"duo_links": DataRegistry.update3_duo_links,
	}, DataRegistry.update3_chronicle_goals)
	await _mount_and_check_passive_controls(chronicle, "chronicle")

	var heart_hud = HeartHUDScene.instantiate()
	heart_hud.setup(Callable(self, "_provide_heart_hud_state"))
	await _mount_and_check_passive_controls(heart_hud, "heart combat HUD")

	var campaign = CampaignModeScreenScene.instantiate()
	campaign.setup(CampaignModeService.default_profile(), DataRegistry.update4_campaign_modes, 2, true)
	await _mount_and_check_passive_controls(campaign, "campaign mode selection")

	var council_active := CampaignModeService.default_active_run()
	council_active["campaign_mode_id"] = CampaignModeService.COUNCIL_MODE_ID
	var region = RegionScreenScene.instantiate()
	region.setup(council_active, DataRegistry.update4_regions, 4, true)
	await _mount_and_check_passive_controls(region, "region selection")

	var outpost = OutpostScreenScene.instantiate()
	outpost.setup(council_active, DataRegistry.update4_outpost_types, [], DataRegistry.monster_instances, 4)
	await _mount_and_check_passive_controls(outpost, "outpost management")

	var upper_state := _upper_state("upper_compact_guard")
	var upper = UpperFloorScreenScene.instantiate()
	upper.setup(upper_state, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	await _mount_and_check_passive_controls(upper, "upper floor selection")

	var multi_floor_hud = MultiFloorHUDScene.instantiate()
	multi_floor_hud.setup(upper_state, DataRegistry.update4_upper_floor_layouts, DataRegistry.update4_upper_floor_modules)
	await _mount_and_check_passive_controls(multi_floor_hud, "multi-floor HUD")

	var outpost_battle = OutpostBattleScene.instantiate()
	outpost_battle.setup(_outpost_state(), DataRegistry.update4_outpost_encounters.get("outpost_fixed_four_modules", {}), DataRegistry.update4_outpost_types.get("outpost_supply_burrow", {}), [], 10)
	await _mount_and_check_passive_controls(outpost_battle, "outpost battle")
	await _mount_and_check_passive_controls(RegionProgressPanelScript.new(), "region progress panel")
	var crown_candidates = CrownCandidatePanelScript.new()
	crown_candidates.configure([
		{"instance_id": "candidate_a", "display_name": "Candidate A"},
		{"instance_id": "candidate_b", "display_name": "Candidate B"},
	])
	await _mount_and_check_passive_controls(crown_candidates, "crown candidate panel")
	await _mount_and_check_passive_controls(CouncilVoteForecastPanelScript.new(), "council vote forecast")

	var duo_hud = DuoHUDScene.instantiate()
	var duo_host := Control.new()
	duo_host.size = Vector2(1920, 1080)
	add_child(duo_host)
	duo_host.add_child(duo_hud)
	await get_tree().process_frame
	duo_hud.setup(Callable(self, "_provide_duo_hud_state"), Callable())
	await get_tree().process_frame
	var duo_blockers: Array[String] = []
	_collect_passive_blockers(duo_hud, duo_blockers)
	_expect(duo_blockers.is_empty(), "duo combat HUD passive controls ignore mouse input%s" % (
		" (%s)" % ", ".join(duo_blockers) if not duo_blockers.is_empty() else ""
	))
	var duo_interactive_mismatches: Array[String] = []
	_collect_interactive_mismatches(duo_hud, duo_interactive_mismatches)
	_expect(duo_interactive_mismatches.is_empty(), "duo combat HUD interactive controls explicitly own mouse input%s" % (
		" (%s)" % ", ".join(duo_interactive_mismatches) if not duo_interactive_mismatches.is_empty() else ""
	))
	duo_host.queue_free()
	await get_tree().process_frame


func _mount_and_check_passive_controls(control: Control, context: String) -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	host.add_child(control)
	await get_tree().process_frame
	await get_tree().process_frame
	var blockers: Array[String] = []
	_collect_passive_blockers(control, blockers)
	_expect(blockers.is_empty(), "%s passive controls ignore mouse input%s" % [
		context,
		" (%s)" % ", ".join(blockers) if not blockers.is_empty() else "",
	])
	var interactive_mismatches: Array[String] = []
	_collect_interactive_mismatches(control, interactive_mismatches)
	_expect(interactive_mismatches.is_empty(), "%s interactive controls explicitly own mouse input%s" % [
		context,
		" (%s)" % ", ".join(interactive_mismatches) if not interactive_mismatches.is_empty() else "",
	])
	host.queue_free()
	await get_tree().process_frame


func _collect_passive_blockers(node: Node, blockers: Array[String]) -> void:
	if (node is Panel or node is PanelContainer or node is ColorRect or node is TextureRect or node is Label or node is RichTextLabel or node is ProgressBar) and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		blockers.append(str(node.get_path()))
	for child in node.get_children():
		_collect_passive_blockers(child, blockers)


func _collect_interactive_mismatches(node: Node, mismatches: Array[String]) -> void:
	if (node is BaseButton or node is Slider) and node.mouse_filter != Control.MOUSE_FILTER_STOP:
		mismatches.append(str(node.get_path()))
	for child in node.get_children():
		_collect_interactive_mismatches(child, mismatches)


func _test_late_decorative_panel_click_through() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(400, 300)
	add_child(viewport)
	var stub := HUDRootStub.new()
	viewport.add_child(stub)
	var hud = HUDControllerScript.new()
	hud.setup(stub)
	var button := Button.new()
	button.name = "InputLayerProbeButton"
	button.position = Vector2(70, 80)
	button.size = Vector2(260, 100)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 1
	button.pressed.connect(_on_probe_pressed)
	stub.ui_layer.add_child(button)
	var cover: Panel = hud.panel(Rect2(button.position, button.size), Color("#ffffff22"), Color("#ffffff55"), "", "flat")
	cover.name = "LateDecorativeCover"
	cover.z_index = 2
	_expect(cover.mouse_filter == Control.MOUSE_FILTER_IGNORE, "shared HUD panels are passive by default")
	await get_tree().process_frame
	await _click(viewport, button.get_global_rect().get_center())
	_expect(probe_pressed, "a button remains clickable below a later, higher decorative panel")
	viewport.queue_free()
	await get_tree().process_frame

	var main = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var game = main.get_node("GameRoot")
	var onboarding_probe_parent := Control.new()
	game.ui_layer.add_child(onboarding_probe_parent)
	var onboarding_panel: Panel = game._onboarding_child_panel(onboarding_probe_parent, Rect2(0, 0, 100, 100), Color.BLACK, Color.WHITE)
	_expect(onboarding_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "onboarding child panels are passive by default")
	game._build_title_reset_confirmation()
	await get_tree().process_frame
	var modal_backdrop: Control = game.ui_layer.get_node_or_null("TitleResetConfirmation")
	var modal_card: Control = modal_backdrop.get_child(0) if modal_backdrop != null and modal_backdrop.get_child_count() > 0 else null
	_expect(modal_backdrop != null and modal_backdrop.mouse_filter == Control.MOUSE_FILTER_STOP, "full-screen confirmation backdrop explicitly blocks input")
	_expect(modal_card != null and modal_card.mouse_filter == Control.MOUSE_FILTER_STOP, "confirmation modal explicitly owns input")
	main.queue_free()
	await get_tree().process_frame


func _click(viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	await get_tree().process_frame
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	viewport.push_input(press, true)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	viewport.push_input(release, true)
	await get_tree().process_frame


func _on_probe_pressed() -> void:
	probe_pressed = true


func _provide_heart_hud_state() -> Dictionary:
	return heart_hud_state.duplicate(true)


func _provide_duo_hud_state() -> Dictionary:
	return duo_hud_state.duplicate(true)


func _upper_state(layout_id: String) -> Dictionary:
	return {
		"unlocked": true,
		"layout_id": layout_id,
		"objective_hp": {"crown_sanctum": 600},
		"facility_role": "recovery",
		"seal_theft_count": 0,
		"graph_runtime": {"visible_floor": "1F", "entities": {}, "transition_queues": {"1F>2F": [], "2F>1F": []}},
		"crown_suppressed": false,
		"repair_cost_gold": 0,
		"layout_locked": true,
		"auto_camera_switch": true,
	}


func _outpost_state() -> Dictionary:
	return {
		"type_id": "outpost_supply_burrow",
		"level": 1,
		"current_hp": 300,
		"max_hp": 300,
		"assigned_monster_ids": [],
		"damaged": false,
	}


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[UIInputLayer] FAIL: %s" % message)
