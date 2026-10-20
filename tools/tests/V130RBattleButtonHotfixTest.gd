extends "res://tools/tests/V130RFixB01Test.gd"
## Exercise the real DAY1–3 flow, blocked CTA, explicit navigation and save reload.

func required_specialization() -> Dictionary:
	if not game._early_specialization_required_for_current_day(): return {}
	var original_locale := LanguageSettings.locale
	for language in ["ko","en","zh_CN"]:
		LanguageSettings.set_locale(language,false)
		var v := view()
		v.monster_ui.auto_place()
		v.update_battle_readiness()
		var ready: Dictionary = game._management_start_state(true)
		expect(ready.reason_code=="specialization","DAY2 blocked specifically by required specialization")
		var before_screen: String = game.current_screen
		expect(not v.start_battle(),language+": unprepared CTA does not start")
		expect(game.current_screen==before_screen and view()==v,language+": CTA never silently navigates")
		expect(is_instance_valid(v.battle_start_notice),language+": visible decision popup")
		var reason: Label = v.battle_start_notice.find_child("BattleStartBlockedReason",true,false)
		expect(reason.text==v.battle_block_reason(ready),language+": localized reason in popup")
		expect(v.status_text.text==reason.text,language+": status explains gate")
		expect(v.chrome.find_child("ApprovedDayAction",true,false).tooltip_text==reason.text,language+": CTA tooltip explains gate")
		var notice: Control = v.battle_start_notice
		expect(not v.start_battle() and v.battle_start_notice==notice,language+": repeated click does not stack popup")
		notice.find_child("BattleStartNoticeClose",true,false).pressed.emit()
		await frames(3)
		expect(not is_instance_valid(v.battle_start_notice) and view()==v,language+": Close keeps deployment")
	LanguageSettings.set_locale(original_locale,false)
	var v := view()
	# The same explicit decision is required for the older first-promotion blocker.
	v.show_battle_start_notice({"reason_code":"first_promotion","required_action_id":"monsters","blocked_reason":"첫 승급을 먼저 완료하세요."})
	expect(view()==v and game.current_screen=="management","first promotion does not silently navigate")
	v.close_battle_start_notice(); await frames(2)
	v.start_battle()
	v.battle_start_notice.find_child("BattleStartNoticeGo",true,false).pressed.emit()
	await frames(6)
	expect(game.current_screen==Constants.SCREEN_MONSTER,"Go opens specialization screen only after choice")
	expect(game.management_scene.monster_ui.active_tab=="skills","Go selects skills/specialization tab")
	var instruction: Control = game.ui_layer.find_child("RequiredSpecializationNotice",true,false)
	expect(instruction!=null and instruction.is_visible_in_tree(),"DAY2–3 requirement visible on monster screen")
	var species: String = game.management_scene.monster_ui.inspected_id
	var options: Array = game._specializations_for_monster(species)
	expect(not options.is_empty(),"inspected companion has specialization choices")
	if options.is_empty(): return {}
	var spec_id: String = str(options[0].id)
	var choose := game.ui_layer.find_child("MonsterSpecialization_"+spec_id,true,false) as BaseButton
	expect(choose!=null and not choose.disabled,"actual specialization choice button enabled")
	if choose==null: return {}
	choose.pressed.emit(); await frames(6)
	expect(not game._early_specialization_required_for_current_day(),"one actual choice clears gate without a loop")
	game._set_screen(Constants.SCREEN_MANAGEMENT,false); await frames(6)
	v=view(); v.update_battle_readiness()
	expect(game._management_start_state(true).can_start,"battle readiness restored after returning")
	expect(v.status_text.text=="","stale blocked status cleared")
	return {"species":species,"id":spec_id}
