extends "res://scripts/ui/ManagementWorkspaceUI.gd"
var selected_by_monster: Dictionary={}

func build_archive() -> void:
	var screen: Panel=panel(Rect2(0,0,1920,1080),"MemoryArchiveScreen")
	root._onboarding_add_scene_illustration(screen,Rect2(0,0,1920,1080),"res://assets/ui/onboarding/scenes/scene_rookie_cave_start.png")
	var id: String=root.selected_monster_id
	var roster: Dictionary=root.monster_roster.get(id,{})
	var ids: Array=roster.get("unlocked_memory_ids",[])
	var selected: String=str(selected_by_monster.get(id,""))
	if not ids.has(selected): selected=str(ids[0]) if not ids.is_empty() else ""
	selected_by_monster[id]=selected
	copy(screen,"%s의 기억" % root._monster_companion_name(id),Rect2(80,46,1350,66),40,PAPER,"MemoryArchiveTitle")
	copy(screen,"함께 쌓은 유대와 이전 회차의 이야기를 다시 읽습니다.",Rect2(80,116,1580,48),24,MUTED)
	var left: Panel=hud.child_panel(screen,Rect2(64,202,420,716),INK,LINE,1)
	var art: TextureRect=hud.texture(left,root.management_scene.monster_portrait_path(id),Rect2(25,24,370,442))
	art.name="MemoryCompanionArt"
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	copy(left,root._monster_companion_name(id),Rect2(32,490,356,54),32,GOLD)
	var bond: int=int(roster.get("bond",0))
	copy(left,"유대 %d/100 · %s" % [bond,root._monster_bond_rank_name(bond)],Rect2(32,554,356,70),24,PAPER,"MemoryBond")
	copy(left,"해금된 기억 %d개"%ids.size(),Rect2(32,642,356,42),22,MUTED)
	var scroll:=ScrollContainer.new()
	scroll.name="MemoryListScroll"
	scroll.position=Vector2(514,202)
	scroll.size=Vector2(420,716)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	screen.add_child(scroll)
	var list:=VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",10)
	scroll.add_child(list)
	for memory_id in ids:
		var entry:=DataRegistry.memory_entry(str(memory_id))
		var title:=_title(entry)
		var b:=button(list,title,Rect2(0,0,394,108),Callable(self,"_select").bind(id,str(memory_id)),"MemoryChoice_"+str(memory_id))
		b.custom_minimum_size=Vector2(394,108)
		b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.tooltip_text=title
		if str(memory_id)==selected: b.add_theme_stylebox_override("normal",hud.flat_style(INK,GOLD,2))
	var detail: Panel=hud.child_panel(screen,Rect2(966,202,890,716),INK,LINE,1)
	detail.name="MemorySelectedDetail"
	if selected=="":
		copy(detail,"아직 해금된 기억이 없습니다.\n함께 방어하고 원정을 마치면 유대 단계마다 새로운 기억이 열립니다.",Rect2(48,100,794,250),28,MUTED,"MemoryEmptyState")
	else:
		var entry:=DataRegistry.memory_entry(selected)
		var body_scroll:=ScrollContainer.new()
		body_scroll.name="MemoryDetailScroll"
		body_scroll.position=Vector2(42,40)
		body_scroll.size=Vector2(806,636)
		body_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		body_scroll.focus_mode=Control.FOCUS_ALL
		detail.add_child(body_scroll)
		var body:=VBoxContainer.new()
		body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		body.add_theme_constant_override("separation",38)
		body_scroll.add_child(body)
		for paragraph in [{"text":_title(entry),"size":32,"color":GOLD},{"text":str(entry.get("summary","기억의 내용이 아직 기록되지 않았습니다.")),"size":27,"color":PAPER},{"text":"“%s”"%str(entry.get("quote","...")),"size":27,"color":Color("#c9a5ff")}]:
			var label:=Label.new()
			label.custom_minimum_size.x=774
			label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			label.text=paragraph.text
			label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_override("font",UIFont.font_for_role(UIFont.ROLE_BODY))
			label.add_theme_font_size_override("font_size",UISettings.scaled_font_size(paragraph.size))
			label.add_theme_color_override("font_color",paragraph.color)
			body.add_child(label)
	button(screen,"몬스터 화면으로",Rect2(1466,958,390,72),Callable(root,"_set_screen").bind(Constants.SCREEN_MONSTER),"MemoryBackButton")
	copy(screen,"기억을 선택해 읽기 · Tab으로 목록 이동",Rect2(80,976,1180,42),22,MUTED)
func _title(entry: Dictionary) -> String:
	var title:=str(entry.get("title","기록되지 않은 기억"))
	if int(entry.get("source_cycle",0))>0: title+=" · %d회차"%int(entry.source_cycle)
	return title
func _select(id: String, memory_id: String) -> void:
	selected_by_monster[id]=memory_id
	root._set_screen(Constants.SCREEN_MEMORY_ARCHIVE)
	call_deferred("_focus_selected",memory_id)
func _focus_selected(memory_id: String) -> void:
	if root.current_screen!=Constants.SCREEN_MEMORY_ARCHIVE: return
	var b: Control=root.ui_layer.find_child("MemoryChoice_"+memory_id,true,false)
	if b!=null: b.grab_focus()
