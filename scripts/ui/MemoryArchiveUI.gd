extends "res://scripts/ui/ManagementWorkspaceUI.gd"
var selected_by_monster: Dictionary = {}

func loc(ko: String, en: String, zh: String) -> String:
	return root.continuity.localized(ko,en,zh)

func build_archive() -> void:
	# Old screen IDs enter the same companion workspace without changing saves.
	root.management_scene.monster_ui.active_tab = "memory"
	root.management_scene.monster_ui.list_mode = "owned"
	root.management_scene.monster_ui.inspected_id = root.selected_monster_id
	root.management_scene.monster_ui.build_monster()

func build_tab(parent: Control, id: String) -> void:
	shared_theme = null
	parent.theme = kit_theme()
	var ui = root.management_scene.monster_ui
	var roster: Dictionary = root.monster_roster.get(id,{})
	var ids: Array = roster.get("unlocked_memory_ids",[])
	var selected := str(selected_by_monster.get(id,""))
	if not ids.has(selected): selected = str(ids[0]) if not ids.is_empty() else ""
	selected_by_monster[id] = selected
	var intro: Control = ui.card(parent,"MemoryOverviewCard")
	kit_line(intro,loc("기억 조각 · 유대 기억 / 회차 계승 / 합동 기억","Memory fragments · Bond / Cycle inheritance / Duo memories","记忆碎片 · 羁绊 / 周目继承 / 合击记忆"),"MemoryArchiveTitle",GOLD)
	kit_line(intro,loc("유대 %d/100 · 해금된 기억 %d개","Bond %d/100 · %d unlocked memories","羁绊 %d/100 · 已解锁 %d段记忆") % [int(roster.get("bond",0)),ids.size()],"MemoryBond")
	var source := kit_line(intro,loc("함께한 시간 → 유대 → 기억","Time together → Bond → Memories","共同经历 → 羁绊 → 记忆"),"MemorySource",MUTED)
	source.mouse_filter = Control.MOUSE_FILTER_PASS
	source.tooltip_text = loc("함께 방어·원정 → 유대 단계 → 기억 ID 저장. 읽기는 보상 재지급이나 장착이 아닙니다.","Defense and expeditions build bond; rank gains unlock saved memory IDs. Reading grants no reward and equips nothing.","共同防御与远征提升羁绊；阶段提升后保存解锁记忆ID。阅读不重复发奖，也不是装备。")
	var locks := GridContainer.new()
	locks.name = "MemoryLockChips"
	locks.columns = 2
	locks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	locks.add_theme_constant_override("h_separation",12)
	locks.add_theme_constant_override("v_separation",8)
	parent.add_child(locks)
	for rank in range(1,5):
		var custom: Dictionary = DataRegistry.monster(id).get("bond_memory_ids",{})
		var memory_id := str(custom.get(str(rank),"")) if not custom.is_empty() else "bond_%s_rank_%d" % [id,rank]
		if memory_id != "" and not ids.has(memory_id): ui.chip(locks,loc("미해금 · 유대 %d에서 기억 단계 %d","Locked · Bond %d for memory rank %d","未解锁 · 羁绊 %d开启第%d阶段记忆") % [rank*25,rank],"MemoryLocked%d" % rank,MUTED)
	for value in ids:
		var memory_id := str(value)
		var entry := DataRegistry.memory_entry(memory_id)
		var b := kit_button(parent,_title(entry),Rect2(),_select.bind(id,memory_id),"MemoryChoice_"+memory_id)
		b.set_meta("kit_selected",memory_id == selected)
	if selected == "":
		kit_line(parent,loc("아직 해금된 기억이 없습니다.","No memories unlocked yet.","尚无已解锁的记忆。"),"MemoryEmptyState",MUTED)
	else:
		var entry := DataRegistry.memory_entry(selected)
		var detail: Control = ui.card(parent,"MemoryDetailCard",24)
		kit_line(detail,_title(entry),"MemorySelectedTitle",GOLD)
		kit_line(detail,loc("회차 계승 · %d회차","Cycle inheritance · Cycle %d","周目继承 · 第%d周目") % int(entry.get("source_cycle",0)) if int(entry.get("source_cycle",0)) > 0 else loc("이번 진행 · 유대 기억","Current run · Bond memory","本次进度 · 羁绊记忆"),"MemoryOrigin",MUTED)
		kit_line(detail,LanguageSettings.ui_text(str(entry.get("summary","기억의 내용이 아직 기록되지 않았습니다."))),"MemorySelectedDetail")
		kit_line(detail,LanguageSettings.ui_text(str(entry.get("quote","..."))),"MemoryQuote",GOLD)
	kit_button(parent,loc("합동 기억의 해금 상태 보기","View duo memory unlocks","查看合击记忆解锁状态"),Rect2(),root.management_scene.monster_ui._tab.bind("duo"),"MemoryDuoButton")

func _title(entry: Dictionary) -> String:
	var title := LanguageSettings.ui_text(str(entry.get("title","기록되지 않은 기억")))
	if int(entry.get("source_cycle",0)) > 0: title += loc(" · %d회차"," · Cycle %d"," · 第%d周目") % int(entry.source_cycle)
	return title

func _select(id: String, memory_id: String) -> void:
	if not root.monster_roster.get(id,{}).get("unlocked_memory_ids",[]).has(memory_id): return
	if root.v130r_story.memory(root,id,memory_id): return
	selected_by_monster[id] = memory_id
	root.management_scene.monster_ui.active_tab = "memory"
	root._set_screen(Constants.SCREEN_MONSTER)
