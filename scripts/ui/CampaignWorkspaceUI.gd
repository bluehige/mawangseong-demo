extends "res://scripts/ui/ManagementWorkspaceUI.gd"
const ContractService = preload("res://scripts/systems/contracts/ContractRosterService.gd")
var screen: Control
var detail: Control
var list: VBoxContainer
var action: Button
var notice: Label
var selected_id := ""
var expected_screen := ""
var kind := ""
var ids: Array = []
var entries: Dictionary = {}
var committed := false
var contract_selection := false

func frame(title: String, subtitle: String) -> void:
	expected_screen = root.current_screen
	screen = panel(Rect2(0,0,1920,1080),"CampaignWorkspace")
	copy(screen,title,Rect2(40,28,1840,66),40,GOLD)
	copy(screen,subtitle,Rect2(42,108,1836,56),24,MUTED)
	var nav := panel(Rect2(40,184,556,748),"CampaignChoiceList")
	list = scrolling(nav,Rect2(16,16,524,716),"CampaignChoiceScroll")
	detail = panel(Rect2(620,184,1260,748),"CampaignChoiceDetail")
	notice = copy(screen,"",Rect2(414,966,1040,86),22,MUTED,"CampaignActionNotice")
	action = button(screen,"확정",Rect2(1480,976,400,64),confirm,"CampaignConfirmButton","primary")
	button(screen,"선택 지우기 · ESC",Rect2(40,976,344,64),cancel,"CampaignCancelButton")

func scrolling(parent: Control, rect: Rect2, id: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = id
	scroll.position = rect.position
	scroll.size = rect.size
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",18)
	scroll.add_child(box)
	return box

func paragraph(parent: Control, text: String, width: float, font_size: int = 24, color: Color = PAPER, id: String = "") -> Label:
	var label := copy(parent,text,Rect2(0,0,width,40),font_size,color,id)
	var font: Font = label.get_theme_font("font")
	var actual: int = label.get_theme_font_size("font_size")
	var measured := font.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width,actual)
	label.custom_minimum_size = Vector2(width,maxf(font.get_height(actual),measured.y)+16)
	return label

func detail_content() -> VBoxContainer:
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	return scrolling(detail,Rect2(32,24,1196,700),"CampaignDetailScroll")

func active() -> bool:
	return is_instance_valid(root) and not root.is_queued_for_deletion() and is_instance_valid(screen) and screen.is_inside_tree() and not screen.is_queued_for_deletion() and root.current_screen == expected_screen and not committed

func entry(id: String, title: String, subtitle: String, portrait: Texture2D = null) -> void:
	var b := button(list,"",Rect2(0,0,496,142),select.bind(id),"CampaignChoice_"+id,"tactical")
	b.custom_minimum_size = Vector2(496,142)
	b.set_meta("choice_id",id)
	var x := 20.0
	if portrait != null:
		var art: TextureRect = hud.texture(b,"",Rect2(12,8,112,126))
		art.texture = portrait
		x = 138
	copy(b,title,Rect2(x,12,476-x,64),24,PAPER)
	copy(b,subtitle,Rect2(x,86,476-x,42),20,MUTED)

func select(id: String) -> void:
	if not active() or not ids.has(id):
		return
	selected_id = id
	root.secondary_selection_ids[expected_screen] = id
	for b in list.get_children():
		hud.apply_button_state(b,"selected" if str(b.get_meta("choice_id","")) == id else "default")
	match kind:
		"archive": archive_detail()
		"contract": contract_detail()
		_: cycle_detail()

func restore_selection() -> void:
	var saved := str(root.secondary_selection_ids.get(expected_screen,""))
	if ids.is_empty():
		paragraph(detail_content(),"표시할 항목이 없습니다.",1160,28,MUTED)
		action.disabled = true
		return
	select(saved if ids.has(saved) else str(ids[0]))
	var b := list.find_child("CampaignChoice_"+selected_id,false,false) as Button
	if b != null:
		_restore_focus.call_deferred(b)

func _restore_focus(control: Control) -> void:
	if active() and is_instance_valid(control) and control.is_inside_tree() and not control.is_queued_for_deletion():
		control.grab_focus()

func build_cycle(choice_kind: String, choice_ids: Array, title: String, intro: String) -> void:
	kind = choice_kind
	ids = choice_ids.duplicate()
	frame("%d회차 · %s" % [root.campaign_cycle_index,title],intro)
	for value in ids:
		var id := str(value)
		var data: Dictionary = root._update2_cycle_choice_data(kind,id)
		entries[id] = data
		entry(id,str(data.get("counter_title",data.get("title",title))),str(data.get("kingdom_title",data.get("effect_label",root._challenge_seal_reward_label(data)))))
	notice.text = "목록에서 항목을 선택한 뒤 확정하세요. 확정 후에는 이번 회차에서 바꿀 수 없습니다."
	restore_selection()
	# A new mandatory step needs its own selection; repeated confirm clicks must not select the next step.
	action.disabled = true

func cycle_detail() -> void:
	var data: Dictionary = entries.get(selected_id,{})
	var content := detail_content()
	paragraph(content,str(data.get("kingdom_title","회차 운영 원칙" if kind == "decree" else "DAY 30 도전")),1160,22,MUTED)
	paragraph(content,str(data.get("counter_title",data.get("title",""))),1160,38,GOLD)
	paragraph(content,str(data.get("description","")),1160,28)
	paragraph(content,"적용 효과" if kind != "seal" else "완수 보상",1160,24,MUTED)
	paragraph(content,str(data.get("effect_label",root._challenge_seal_reward_label(data))),1160,30,GOLD)
	paragraph(content,"지금은 검토 중입니다. 확정 버튼을 눌렀을 때 적용됩니다.",1160,22,MUTED)
	action.text = "도전 확정" if kind == "seal" else "선택 확정"
	action.disabled = data.is_empty()

func build_archive() -> void:
	kind = "archive"
	ids = root._ending_catalog_ids()
	entries = root._ending_archive_snapshot()
	frame("엔딩 도감","발견 %d / %d · 확인한 결말은 다음 회차에도 남습니다." % [entries.size(),ids.size()])
	for value in ids:
		var id := str(value)
		var data := DataRegistry.ending_rule(id)
		var discovered := entries.has(id)
		entry(id,str(data.get("display_name",id)) if discovered else "아직 발견하지 못한 결말",str(data.get("catalog_code","?"))+(" · 발견" if discovered else " · 미발견"),load(str(data.get("thumbnail"))) as Texture2D if discovered and ResourceLoader.exists(str(data.get("thumbnail",""))) else null)
	screen.find_child("CampaignCancelButton",true,false).hide()
	action.text = "타이틀로 돌아가기"
	notice.text = "목록을 스크롤하거나 Tab으로 이동해 결말을 선택하세요."
	restore_selection()

func archive_detail() -> void:
	var content := detail_content()
	var data := DataRegistry.ending_rule(selected_id)
	if not entries.has(selected_id):
		paragraph(content,str(data.get("catalog_code","?")),1160,64,GOLD)
		paragraph(content,"아직 발견하지 못한 결말",1160,32)
		paragraph(content,"새 결말을 발견하면 이곳에서 그림과 기록을 다시 볼 수 있습니다.",1160,24,MUTED)
		return
	paragraph(content,"%s · %s" % [data.get("catalog_code",""),data.get("display_name",selected_id)],1160,34,GOLD,"EndingDetailTitle")
	var art: TextureRect = hud.texture(content,str(data.get("illustration",data.get("thumbnail",""))),Rect2(0,0,1160,432))
	art.name = "EndingDetailArt"
	art.custom_minimum_size = Vector2(1160,432)
	var record: Dictionary = entries[selected_id]
	paragraph(content,"발견 %d회 · 최초 %d회차 · 최근 %d회차" % [record.get("seen_count",1),record.get("first_seen_cycle",1),record.get("last_seen_cycle",1)],1160,22,MUTED)
	if str(data.get("sign_text","")) != "":
		paragraph(content,str(data.sign_text),1160,28)
	for value in data.get("lines",[]):
		paragraph(content,str(value),1160,24)

func build_contract(selection_open: bool) -> void:
	kind = "contract"
	contract_selection = selection_open
	if selection_open:
		ids = root.contract_board_offer_ids.duplicate()
	else:
		root._sync_contract_reserves()
		ids = root._contract_owned_instance_ids(false)
	frame("%d회차 · 계약 동료" % root.campaign_cycle_index if selection_open else "출전·예비 편성","이번 회차에 함께할 두 동료를 선택하세요." if selection_open else "편성 변경은 즉시 적용됩니다. 출전은 방어전에 등장하고, 예비는 성장과 계약을 유지합니다.")
	for value in ids:
		var id := str(value)
		var instance_id := str(DataRegistry.update2_contract(id).get("instance_id","")) if selection_open else id
		var instance := DataRegistry.monster_instance(instance_id)
		var species := str(instance.get("species_id",id))
		var selected: bool = root.contract_board_pending_ids.has(id) if selection_open else root.deployed_instance_ids.has(id)
		var location := "계약 후보에 포함" if selected and selection_open else ("출전 중" if selected else ("후보 선택 가능" if selection_open else "예비"))
		var name := str(DataRegistry.update2_contract(id).get("display_name",id)) if selection_open else str(instance.get("display_name",species))
		entry(id,name,location,root.management_scene.monster_identity_texture(species))
	if not selection_open:
		screen.find_child("CampaignCancelButton",true,false).hide()
		action.text = "편성 완료"
	else:
		action.text = "두 계약 확정"
	refresh_contract_notice()
	restore_selection()

func refresh_contract_notice() -> void:
	if contract_selection:
		var count: int = root.contract_board_pending_ids.size()
		notice.text = "선택 %d / 2 · 확정 뒤 계약 상대는 회차가 끝날 때까지 유지됩니다." % count
		action.disabled = count != ContractService.REQUIRED_CONTRACT_COUNT
	else:
		var errors: Array = ContractService.validate_deployment(root.deployed_instance_ids,root._contract_owned_instance_ids(true),root.castle_art_stage,root._current_stage_deployment_limit()-ContractService.stage_deployment_limit(root.castle_art_stage))
		notice.text = str(errors[0]) if not errors.is_empty() else "출전 %d / 최대 %d명 · 예비 %d명" % [root.deployed_instance_ids.size(),root._current_stage_deployment_limit(),root.reserve_instance_ids.size()]
		action.disabled = not errors.is_empty()

func contract_detail() -> void:
	var content := detail_content()
	var contract := DataRegistry.update2_contract(selected_id) if contract_selection else {}
	var instance_id := str(contract.get("instance_id","")) if contract_selection else selected_id
	var instance := DataRegistry.monster_instance(instance_id)
	var species := str(instance.get("species_id",selected_id))
	var monster := DataRegistry.monster(species)
	var name := str(contract.get("display_name",instance.get("display_name",species)))
	paragraph(content,name,1160,38,GOLD)
	var portrait: Texture2D = root.management_scene.monster_identity_texture(species)
	if portrait != null:
		var art: TextureRect = hud.texture(content,"",Rect2(0,0,1160,192))
		art.texture = portrait
		art.name = "ContractDetailArt"
		art.custom_minimum_size = Vector2(1160,192)
	paragraph(content,str(contract.get("role",monster.get("role",""))),1160,28)
	paragraph(content,str(contract.get("description",monster.get("description",""))),1160,24)
	var selected: bool = root.contract_board_pending_ids.has(selected_id) if contract_selection else root.deployed_instance_ids.has(selected_id)
	var ready: bool = root._contract_combat_asset_ready(selected_id) if contract_selection else root._monster_available_for_defense(species)
	var text := ("후보에서 빼기" if selected else "함께할 후보로 선택") if contract_selection else ("예비로 전환" if selected else "출전으로 전환")
	var toggle := button(content,text,Rect2(0,0,1160,68),toggle_contract,"ContractToggleButton","tactical")
	toggle.custom_minimum_size = Vector2(1160,68)
	var full: bool = root.contract_board_pending_ids.size() >= 2 if contract_selection else root.deployed_instance_ids.size() >= root._current_stage_deployment_limit()
	toggle.disabled = not ready or (full and not selected)
	var reason := "전투 외형 준비 중 · 예비로 유지됩니다." if not ready else ("정원이 찼습니다. 다른 동료를 해제한 뒤 선택하세요." if full and not selected else ("후보 선택은 확정 전까지 바꿀 수 있습니다." if contract_selection else "버튼을 누르면 편성에 즉시 반영됩니다."))
	paragraph(content,reason,1160,22,MUTED,"ContractToggleReason")

func toggle_contract() -> void:
	if not active() or not ids.has(selected_id):
		return
	if contract_selection:
		root._toggle_contract_candidate(selected_id)
	else:
		root._toggle_contract_deployment(selected_id)

func confirm() -> void:
	if not active() or action.disabled:
		return
	if kind == "archive":
		committed = true
		root._set_screen(Constants.SCREEN_TITLE)
	elif kind == "contract":
		committed = true
		if contract_selection:
			root._confirm_contract_selection()
		else:
			root._confirm_contract_roster()
	elif ids.has(selected_id):
		committed = true
		var method := "_select_cycle_doctrine" if kind == "doctrine" else ("_select_cycle_decree" if kind == "decree" else "_select_challenge_seal")
		root.call(method,selected_id)

func cancel() -> void:
	if not active():
		return
	if kind == "archive":
		confirm()
	elif kind == "contract" and not contract_selection:
		confirm()
	elif kind == "contract":
		root.contract_board_pending_ids.clear()
		root._set_screen(expected_screen)
	else:
		selected_id = ""
		root.secondary_selection_ids.erase(expected_screen)
		for b in list.get_children():
			hud.apply_button_state(b,"default")
		paragraph(detail_content(),"선택을 지웠습니다. 목록에서 이번 회차의 방향을 다시 골라 주세요.",1160,28,MUTED)
		action.disabled = true
