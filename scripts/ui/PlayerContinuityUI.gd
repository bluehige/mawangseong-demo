extends RefCounted
# Read-only dialogue history and shared campaign controls. History never replays actions.
var root: Node
var history: Array[Dictionary] = []
var last_key := ""
var backlog_open := false
var confirmation_action := ""
var update_open := false
var menu_feedback := ""
var promotion_uses: Dictionary = {}
var promotion_damage := 0
var promotion_notice_remaining := 0.0
var prototype_ambush_enabled := false
const UPDATE_ID := "1.2.10-continuity-20261011"

func setup(value: Node) -> void:
	root = value
	prototype_ambush_enabled = OS.get_cmdline_user_args().has("--prototype-ambush-backline")

func reset_combat() -> void:
	promotion_uses.clear()
	promotion_damage = 0
	promotion_notice_remaining = 0.0
	remove("PromotionContributionNotice")

func record_promoted_slash(unit: Node, actual_damage: int) -> void:
	if str(root.monster_roster.get(unit.unit_id, {}).get("promotion_id", "")) != "goblin_ambush_captain": return
	var key := "goblin_ambush_captain:quick_slash"
	var first := not promotion_uses.has(key)
	promotion_uses[key] = int(promotion_uses.get(key, 0)) + 1
	promotion_damage += maxi(0, actual_damage)
	root._log(localized("승급 빠른 베기 · 실제 피해 %d · 이번 전투 누적 %d", "Promoted Quick Slash · damage %d · battle total %d", "晋升快速斩击 · 实际伤害 %d · 本场合计 %d") % [actual_damage, promotion_damage])
	if not first: return
	remove("PromotionContributionNotice")
	var panel: Panel = root.hud.panel(Rect2(1150, 182, 708, 122), Color("#241526f5"), Color("#ffd36a"), "PromotionContributionNotice", "flat")
	panel.name = "PromotionContributionNotice"
	panel.z_index = 620
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text: Label = root.hud.label(panel, localized("매복대장 · 첫 강화 베기!\n기본 1.90 → 승급 2.15배 · 실제 피해 %d", "Ambush Captain · first upgraded slash!\nBase 1.90 → promoted 2.15 multiplier · damage %d", "伏击队长 · 首次强化斩击！\n基础 1.90 → 晋升 2.15 倍 · 实际伤害 %d") % actual_damage, Vector2(20, 16), Vector2(668, 92), 22, Color("#ffe4b0"), HORIZONTAL_ALIGNMENT_LEFT, "PromotionFirstUseText", "body", VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 3)
	text.name = "PromotionFirstUseText"
	promotion_notice_remaining = 5.0

func tick(delta: float) -> void:
	if root.current_screen != "combat" or root.combat_paused: return
	if promotion_notice_remaining > 0.0:
		promotion_notice_remaining -= delta
		if promotion_notice_remaining <= 0.0: remove("PromotionContributionNotice")

func promotion_explanation(rule: Dictionary) -> String:
	if str(rule.get("id", "")) != "goblin_ambush_captain": return str(rule.get("role_summary", ""))
	return localized("기본 곱도 도둑을 추격합니다. 승급 후 빠른 베기 피해배율 1.90→2.15, 이동 +5%. 첫 강화 베기와 실제 피해를 전투에서 표시합니다.", "Base Gob also pursues thieves. Promotion raises Quick Slash from 1.90 to 2.15 and speed by 5%. The first upgraded slash and actual damage are shown in battle.", "基础哥布也追击盗贼。晋升后快速斩击由1.90变为2.15倍，移动+5%。战斗中显示首次强化斩击和实际伤害。")

func localized(ko: String, en: String, zh: String) -> String:
	return en if LanguageSettings.locale == "en" else (zh if LanguageSettings.locale == "zh_CN" else ko)

func record(key: String, speaker: String, text: String) -> void:
	if key == last_key or text == "": return
	last_key = key
	history.append({"speaker": speaker, "text": text, "day": GameState.day})

func record_story() -> void:
	if not root.story_director.is_active(): return
	var cue: Dictionary = root.story_director.current_cue()
	var speaker: Dictionary = root._story_resolve_cue_speaker(cue)
	record("%s:%s" % [root.story_director.current_scene_id, root.story_director.cursor], LanguageSettings.story_speaker(speaker, root._onboarding_player_name()), LanguageSettings.story_text(cue, root._onboarding_player_name()))

func add_dialogue_buttons(parent: Control) -> void:
	root.hud.button(parent, localized("대화 로그", "Dialogue log", "对话记录"), Rect2(1400, 112, 210, 54), Callable(self, "open_backlog"), 19, "DialogueBacklogButton")
	root.hud.button(parent, localized("메뉴", "Menu", "菜单"), Rect2(1630, 112, 210, 54), Callable(root, "_open_pause_menu"), 19, "DialogueMenuButton")

func open_backlog() -> void:
	if backlog_open: return
	backlog_open = true
	var panel := modal("DialogueBacklogOverlay", localized("대화 로그 · 읽기 전용", "Dialogue log · read only", "对话记录 · 只读"))
	var scroll := ScrollContainer.new()
	scroll.name = "DialogueBacklogScroll"
	scroll.position = Vector2(44, 110)
	scroll.size = Vector2(1112, 540)
	panel.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 18)
	scroll.add_child(rows)
	for entry in history:
		var label := Label.new()
		label.text = "DAY %02d · %s\n%s" % [entry.day, entry.speaker, entry.text]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(1060, 0)
		label.add_theme_font_override("font", root.hud.UI_FONT)
		label.add_theme_font_size_override("font_size", 25)
		rows.add_child(label)
	root.hud.button(panel, localized("닫고 대화로 돌아가기", "Close and resume dialogue", "关闭并返回对话"), Rect2(340, 680, 520, 60), Callable(self, "close_backlog"), 22, "BacklogCloseButton")
	scroll.set_deferred("scroll_vertical", 1000000)

func close_backlog() -> void:
	remove("DialogueBacklogOverlay")
	backlog_open = false
	root._story_reset_auto_timer()

func modal(name: String, title: String) -> Panel:
	var overlay: Panel = root.hud.panel(Rect2(0, 0, 1920, 1080), Color("#020104dd"), Color.TRANSPARENT, name, "flat")
	overlay.name = name
	overlay.z_index = 4000
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel: Panel = root.hud.child_panel(overlay, Rect2(360, 140, 1200, 800), Color("#100d18fa"), Color("#796284"), 2)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.hud.label(panel, title, Vector2(44, 32), Vector2(1112, 64), 30, Color("#ffd36a"))
	return panel

func remove(name: String) -> void:
	var node: Node = root.ui_layer.find_child(name, true, false)
	if node != null:
		node.get_parent().remove_child(node)
		node.queue_free()

func checkpoint_text() -> String:
	if root.campaign_save_status != root.CampaignSaveStoreScript.STATUS_VALID:
		return localized("복원 가능한 저장 기록이 없습니다.", "No restorable checkpoint.", "没有可恢复的存档。")
	var summary: Dictionary = root.campaign_save_summary
	var stamp := str(summary.get("saved_at_text", ""))
	return "DAY %02d · %s\n%s" % [int(summary.get("day", 1)), str(summary.get("checkpoint_label", "")), stamp]

func loss_text() -> String:
	if root.current_screen == "combat" or root.pause_menu_source_screen == "combat":
		return localized("전투 중간 저장은 지원하지 않습니다. 불러오면 마지막 체크포인트부터 다시 시작하며 이번 전투 진행은 사라집니다.", "Mid-battle saves are unavailable. Loading restores the last checkpoint and loses this battle's progress.", "不支持战斗中途存档。读档将返回最近检查点，本次战斗进度会丢失。")
	return localized("불러오거나 저장 없이 나가면 위 체크포인트 이후의 변경이 사라집니다.", "Loading or leaving without saving loses changes since this checkpoint.", "读档或不保存离开会丢失此检查点之后的更改。")

func build_menu() -> void:
	if not root.pause_menu_open or root.current_screen != root.pause_menu_source_screen: return
	if root.ui_layer.find_child("PauseMenuOverlay", true, false) != null: return
	var panel := modal("PauseMenuOverlay", localized("게임 메뉴", "Game menu", "游戏菜单"))
	root.hud.label(panel, checkpoint_text() + "\n" + loss_text(), Vector2(44, 110), Vector2(1112, 150), 22, Color("#d5c9df"), HORIZONTAL_ALIGNMENT_LEFT, "MenuCheckpoint", "body", VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 5)
	var actions := [
		[localized("계속", "Resume", "继续"), Callable(root, "_close_pause_menu"), "PauseResumeButton"],
		[localized("저장", "Save", "保存"), Callable(self, "save_now"), "PauseSaveButton"],
		[localized("불러오기", "Load", "读取"), Callable(self, "confirm").bind("load"), "PauseLoadButton"],
		[localized("설정", "Settings", "设置"), Callable(root, "_open_settings_screen").bind(true), "PauseSettingsButton"],
		[localized("타이틀", "Title", "标题"), Callable(self, "confirm").bind("title"), "PauseTitleButton"],
		[localized("종료", "Quit", "退出"), Callable(self, "confirm").bind("quit"), "PauseQuitButton"]]
	for i in range(actions.size()):
		root.hud.button(panel, actions[i][0], Rect2(64 + (i % 2) * 560, 310 + (i / 2) * 116, 512, 80), actions[i][1], 25, actions[i][2])
	var feedback: String = root.campaign_save_notice if root.campaign_save_notice != "" else menu_feedback
	if feedback != "":
		root.hud.label(panel, feedback, Vector2(44, 688), Vector2(1112, 88), 20, Color("#ffa89f"), HORIZONTAL_ALIGNMENT_LEFT, "MenuSaveNotice", "body", VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 4)

func save_now() -> bool:
	if not root._campaign_safe_save_screen(root.current_screen) or root.story_combat_overlay_open:
		menu_feedback = localized("현재 화면에서는 저장하지 않습니다. 마지막 체크포인트를 불러올 수 있습니다.", "Saving is unavailable here. You can restore the last checkpoint.", "此画面无法保存。可以读取最近检查点。")
		refresh_menu()
		return false
	root._schedule_campaign_autosave(root.current_screen)
	var ok: bool = root._flush_campaign_autosave()
	if ok: menu_feedback = localized("저장 완료 · ", "Saved · ", "保存完成 · ") + checkpoint_text()
	refresh_menu()
	return ok

func refresh_menu() -> void:
	remove("PauseMenuOverlay")
	build_menu()

func settings_menu() -> void:
	root._cancel_settings_changes()
	if root.current_screen == "title":
		root.pause_menu_open = true
		root.pause_menu_source_screen = "title"
		build_menu()
	else:
		root._open_pause_menu()

func confirm(action: String) -> void:
	confirmation_action = action
	var panel := modal("CampaignLeaveConfirmation", localized("진행 손실 확인", "Confirm progress loss", "确认进度损失"))
	root.hud.label(panel, checkpoint_text() + "\n\n" + loss_text(), Vector2(64, 150), Vector2(1072, 250), 26, Color("#eee1d2"), HORIZONTAL_ALIGNMENT_LEFT, "LeaveLossText", "body", VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 8)
	root.hud.button(panel, localized("취소 · 계속 플레이", "Cancel · keep playing", "取消 · 继续游戏"), Rect2(64, 448, 1072, 76), Callable(self, "cancel_confirmation"), 24, "LeaveCancelButton")
	if action != "load" and root._campaign_safe_save_screen(root.current_screen) and not root.story_combat_overlay_open:
		root.hud.button(panel, localized("저장하고 이동", "Save and leave", "保存后离开"), Rect2(64, 546, 1072, 76), Callable(self, "leave").bind(true), 24, "LeaveSaveButton")
	root.hud.button(panel, localized("마지막 저장 기준으로 이동", "Leave using last checkpoint", "按最近存档离开"), Rect2(64, 644, 1072, 76), Callable(self, "leave").bind(false), 24, "LeaveCheckpointButton")

func cancel_confirmation() -> void:
	remove("CampaignLeaveConfirmation")
	confirmation_action = ""

func leave(save_first: bool) -> void:
	if save_first and not save_now():
		cancel_confirmation()
		return
	var action := confirmation_action
	cancel_confirmation()
	root.campaign_autosave_pending = false
	root.pause_menu_open = false
	root.pause_menu_source_screen = ""
	root.pause_menu_combat_was_paused = false
	root.story_combat_overlay_open = false
	root.story_pending_combat_scenes.clear()
	root.story_director.cancel_active_scene()
	root.combat_story_feed.clear()
	# A failed new write does not make an intact previous checkpoint unusable.
	root.campaign_save_notice = ""
	if action == "load": root._continue_campaign_save()
	elif action == "quit": root.get_tree().quit()
	else: root._set_screen("title", false)

func update_acknowledged() -> bool:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	return str(config.get_value("updates", "acknowledged", "")) == UPDATE_ID

func show_update() -> void:
	if update_open or root.current_screen != "title": return
	update_open = true
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var panel := modal("UpdateNotesOverlay", localized("업데이트 내역 · ", "Update notes · ", "更新记录 · ") + version)
	var notes := localized("• 전투 자막이 설정 복귀와 배속에서 덜 끊기도록 개선했습니다.\n\n• 게임 메뉴에서 저장·불러오기·타이틀·종료를 찾을 수 있습니다.\n\n• 저장 체크포인트와 진행 손실 범위를 표시합니다.\n\n• 대화 로그를 읽는 동안 자동진행을 멈춥니다.", "• Combat captions survive settings and remain readable at higher speed.\n\n• The game menu provides save, load, title and quit controls.\n\n• Checkpoints and the scope of progress loss are shown.\n\n• Dialogue auto-play stops while reading the dialogue log.", "• 改善战斗字幕，设置返回和加速时保持可读。\n\n• 游戏菜单提供保存、读档、标题和退出。\n\n• 显示存档检查点及进度损失范围。\n\n• 阅读对话记录时暂停自动对话。")
	root.hud.label(panel, notes, Vector2(64, 132), Vector2(1072, 500), 26, Color("#eee1d2"), HORIZONTAL_ALIGNMENT_LEFT, "UpdateNotesText", "body", VERTICAL_ALIGNMENT_TOP, TextServer.AUTOWRAP_WORD_SMART, 16)
	root.hud.button(panel, localized("확인", "OK", "确定"), Rect2(340, 680, 520, 60), Callable(self, "acknowledge_update"), 24, "UpdateNotesConfirm")

func acknowledge_update() -> void:
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("updates", "acknowledged", UPDATE_ID)
	if config.save("user://settings.cfg") != OK: return
	remove("UpdateNotesOverlay")
	update_open = false

func input(event: InputEvent) -> bool:
	if backlog_open or confirmation_action != "" or update_open:
		if event is InputEventKey:
			if event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
				if backlog_open: close_backlog()
				elif confirmation_action != "": cancel_confirmation()
				else: acknowledge_update()
			return true
		# Let GUI controls receive pointer input, but block world handlers.
		return true
	if root.pause_menu_open and root.current_screen != "settings":
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE: root._close_pause_menu()
		return true
	return false
