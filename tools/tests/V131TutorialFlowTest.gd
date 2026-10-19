extends "res://tools/tests/V130RBattleButtonHotfixTest.gd"
## Keep the real DAY1–3 combat/specialization replay and check its live guide targets.
func required_specialization() -> Dictionary:
	if game._early_specialization_required_for_current_day():
		var v := view()
		v.monster_ui.auto_place()
		v.start_battle(); await frames(3)
		var go: Control = v.battle_start_notice.find_child("BattleStartNoticeGo",true,false)
		expect(go.has_node("TutorialButtonGlow"),"DAY2–3 required navigation visibly glows")
		v.close_battle_start_notice(); await frames(3)
	var selected := await super.required_specialization()
	if GameState.day in [2,3]:
		expect(not game._early_specialization_required_for_current_day(),"DAY2–3 completed guidance stays off")
	return selected
