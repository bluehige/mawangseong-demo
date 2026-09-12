extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_title() -> void:
	root._refresh_campaign_save_status()
	var screen := panel(Rect2(0, 0, 1920, 1080), "TitleWorkspace")
	root._onboarding_add_scene_illustration(screen, Rect2(0, 0, 1920, 1080), root.ONBOARDING_START_SCENE)
	var menu: Panel = hud.child_panel(screen, Rect2(72, 76, 748, 928), Color("#17121ff2"), LINE)
	copy(menu, "마왕성", Rect2(44, 32, 660, 46), 28, GOLD)
	copy(menu, "마왕님,\n마왕성은 누가 지켜요?", Rect2(44, 98, 660, 166), 44, PAPER, "TitleHeading")
	copy(menu, "방을 짓고, 동료를 배치하고.\n다가오는 침입을 나만의 방어로 막아내세요.", Rect2(44, 290, 660, 106), 26, MUTED)
	var valid: bool = root.campaign_save_status == root.CampaignSaveStoreScript.STATUS_VALID and root.campaign_save_notice == ""
	var label: String = "새 회차" if root._title_campaign_mode_available() else "새 게임"
	var callback := Callable(root, "_open_campaign_mode_from_title") if root._title_campaign_mode_available() else Callable(root, "_onboarding_start_new_game")
	var primary: Button
	if valid:
		primary = button(menu, "이어하기 · DAY %02d" % int(root.campaign_save_summary.get("day", 1)), Rect2(44, 426, 660, 84), Callable(root, "_continue_campaign_save"), "CampaignContinueButton", "primary")
		button(menu, label, Rect2(44, 526, 660, 64), callback, "CampaignNewGameButton")
	else:
		primary = button(menu, label, Rect2(44, 426, 660, 84), callback, "CampaignNewGameButton", "primary")
	if root.pending_title_reset_mode == "":
		primary.call_deferred("grab_focus")
	button(menu, "설정", Rect2(44, 628, 320, 60), Callable(root, "_open_settings_screen"), "TitleSettingsButton")
	button(menu, "엔딩 도감", Rect2(384, 628, 320, 60), Callable(root, "_open_ending_archive"), "EndingArchiveButton")
	if not UISettings.is_touch_ui():
		button(menu, "종료", Rect2(44, 706, 660, 56), Callable(root, "_onboarding_quit_requested"), "TitleQuitButton")
	var notice: String = root._campaign_title_save_status_text()
	copy(menu, notice, Rect2(44, 794, 660, 104), 20, Color("#f6a597") if root.campaign_save_notice != "" or root.campaign_save_status in [root.CampaignSaveStoreScript.STATUS_CORRUPT,root.CampaignSaveStoreScript.STATUS_UNSUPPORTED] else MUTED, "TitleSaveStatus")
	copy(screen, "버전 1.2", Rect2(72, 1022, 748, 34), 18, MUTED)
	copy(screen, "내가 준비한 방어가\n동료들의 이야기가 됩니다.", Rect2(952, 116, 856, 120), 34, PAPER)
	for i in range(3):
		var id: String = ["slime","goblin","imp"][i]
		var path: String = root.management_scene.monster_portrait_path(id)
		if path == "":
			continue
		var frame: Panel = hud.child_panel(screen, Rect2(896 + i * 300, 540 + (28 if i == 1 else 0), 276, 360), Color("#17121fe8"), LINE)
		var art: TextureRect = hud.texture(frame, path, Rect2(12, 12, 252, 280))
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		copy(frame, ["푸딩","곱","핀"][i], Rect2(20, 306, 236, 40), 24, GOLD)
	if root._qa_title_actions_enabled():
		button(screen, "QA · 빠른 시작", Rect2(1510, 980, 338, 64), Callable(root, "_onboarding_start_quick_game"), "CampaignQuickStartButton")
	if root.pending_title_reset_mode != "":
		_disable_menu_input(screen)
		root._build_title_reset_confirmation()

func _disable_menu_input(node: Node) -> void:
	if node is BaseButton:
		node.disabled = true
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_menu_input(child)
