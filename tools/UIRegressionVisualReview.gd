extends Node

const Constants = preload("res://scripts/core/Constants.gd")
const GameRootScene = preload("res://scenes/game/GameRoot.tscn")

var game: Node
var output_dir := ""
var failed := false

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	output_dir = ProjectSettings.globalize_path("res://tmp/ui_regression_review")
	DirAccess.make_dir_recursive_absolute(output_dir)
	if _running_without_viewport_capture():
		print("UI_REGRESSION_VISUAL_REVIEW_HEADLESS_SKIP: viewport capture requires a rendering display")
		print("UI_REGRESSION_VISUAL_REVIEW: %s" % output_dir)
		get_tree().quit(0)
		return
	game = GameRootScene.instantiate()
	add_child(game)
	await _settle(4)
	game._debug_skip_onboarding()
	GameState.day = 2
	game._choose_early_specialization("goblin", "goblin_treasure_hunter")
	game._set_screen(Constants.SCREEN_MONSTER)
	await _settle(4)
	await _save("01_monster_screen.png")

	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._build_selected_slot()
	game._select_build_target_room("slot_01")
	await _settle(4)
	await _save("02_management_build.png")

	game.result_summary = {
		"win": true,
		"lines": [
			"DAY 2 방어 성공.",
			"격퇴한 적: 3 / 스폰: 3",
			"전투 시간: 20.4초 / 생존 몬스터: 3/3",
			"잔여 전력: HP 324 / 440",
			"획득 금화: 198",
			"획득 마력: 60",
			"증가 악명: 15",
			"마왕성 체력: 1500 / 1500",
			"지침 효과: 사수 피해 감소 5 / 총공격 추가 피해 +17",
			"시설 기여: 발동 없음 (방 동선과 몬스터 배치를 확인하세요)"
		]
	}
	game.result_growth_reviewed = false
	game.result_growth_choice_monster_id = ""
	game.result_growth_choice_applied = false
	game.last_growth_choice_summary.clear()
	game.last_growth_summary = [
		{
			"monster_id": "slime",
			"display_name": "슬라임",
			"level_before": 1,
			"level_after": 1,
			"levels_gained": 0,
			"exp_after": 33,
			"exp_gain": 32,
			"next_exp": 50,
			"shared_exp": 24,
			"activity_exp": 8,
			"activity_breakdown": {"attack": 3, "defense": 5}
		},
		{
			"monster_id": "goblin",
			"display_name": "고블린",
			"level_before": 1,
			"level_after": 2,
			"levels_gained": 1,
			"exp_after": 6,
			"exp_gain": 32,
			"next_exp": 80,
			"shared_exp": 24,
			"activity_exp": 8,
			"activity_breakdown": {"attack": 4, "finisher": 2, "facility": 2}
		},
		{
			"monster_id": "imp",
			"display_name": "임프",
			"level_before": 1,
			"level_after": 1,
			"levels_gained": 0,
			"exp_after": 46,
			"exp_gain": 32,
			"next_exp": 50,
			"shared_exp": 24,
			"activity_exp": 8,
			"activity_breakdown": {"attack": 8}
		}
	]
	game.result_summary["growth"] = game.last_growth_summary.duplicate(true)
	game._set_screen(Constants.SCREEN_RESULT)
	await _settle(5)
	await _save("03_result_screen.png")

	game.onboarding_enabled = true
	game.onboarding_dialogue_queue = [{
		"speaker": "CHR_GOLDIN",
		"emotion": "accounting",
		"text": "보상 정산 완료. 악명 +1, 골드 소량. 위엄은 장부상 무형자산입니다. 다음 방어 준비까지 확인하겠습니다."
	}]
	game.onboarding_dialogue_index = 0
	game._set_screen(Constants.SCREEN_DIALOGUE)
	await _settle(5)
	await _save("04_dialogue_screen.png")

	game.onboarding_enabled = false
	game._set_screen(Constants.SCREEN_MANAGEMENT)
	game._start_combat()
	await _settle(5)
	game.onboarding_enabled = true
	game.tutorial_gate_enabled = true
	game._onboarding_set_stage("LV07_DAY02_BATTLE_THIEF")
	for index in range(game.tutorial_manager.steps.size()):
		if str(game.tutorial_manager.steps[index].get("id", "")) == "TUT_130_GOBLIN_CONTROL":
			game.tutorial_manager.current_index = index
			game.tutorial_manager.active = true
			break
	game._tutorial_build_overlay()
	await _settle(5)
	await _save("05_combat_tutorial.png")

	print("UI_REGRESSION_VISUAL_REVIEW: %s" % output_dir)
	get_tree().quit(1 if failed else 0)

func _settle(frames: int) -> void:
	for _index in range(frames):
		await get_tree().process_frame
		await get_tree().physics_frame

func _running_without_viewport_capture() -> bool:
	return DisplayServer.get_name() == "headless"

func _save(file_name: String) -> void:
	await get_tree().process_frame
	await _wait_for_capture_frame()
	var texture = get_viewport().get_texture()
	if texture == null:
		push_error("화면 캡처 텍스처를 만들지 못했습니다.")
		failed = true
		return
	var image = texture.get_image()
	if image == null or image.is_empty():
		push_error("화면 캡처 이미지가 비어 있습니다.")
		failed = true
		return
	image.convert(Image.FORMAT_RGB8)
	var error = image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("%s 저장 실패: %d" % [file_name, error])
		failed = true

func _wait_for_capture_frame() -> void:
	var draw_completed: bool = false
	var mark_drawn: Callable = func() -> void:
		draw_completed = true
	RenderingServer.frame_post_draw.connect(mark_drawn, CONNECT_ONE_SHOT)
	for _index in range(30):
		await get_tree().process_frame
		if draw_completed:
			break
	if RenderingServer.frame_post_draw.is_connected(mark_drawn):
		RenderingServer.frame_post_draw.disconnect(mark_drawn)
