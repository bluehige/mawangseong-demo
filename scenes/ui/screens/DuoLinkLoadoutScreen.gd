extends Control
class_name DuoLinkLoadoutScreen

signal link_toggled(link_id: String)
signal auto_use_changed(enabled: bool)
signal preset_saved(slot_index: int)
signal preset_loaded(slot_index: int)
signal auto_recommend_requested
signal confirmed
signal canceled

const UXTheme = preload("res://scripts/ui/UIUXTheme.gd")
const UIFontScript = preload("res://scripts/ui/UIFont.gd")
const DESIGN_SIZE := Vector2(1920, 1080)
const LINK_CARD_RECTS := [
	Rect2(150, 310, 510, 240),
	Rect2(690, 310, 510, 240),
	Rect2(1230, 310, 510, 240),
	Rect2(150, 560, 510, 240),
	Rect2(690, 560, 510, 240),
	Rect2(1230, 560, 510, 240),
]

var profile: Dictionary = {}
var active_run: Dictionary = {}
var catalog: Dictionary = {}
var deployed_instance_ids: Array = []
var content_root: Control
var member_progress: Dictionary = {}
var selected_member_id := ""
var editable := true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_design_canvas)
	_build()
	call_deferred("_fit_design_canvas")


func setup(profile_value: Dictionary, active_run_value: Dictionary, catalog_value: Dictionary, deployed_value: Array) -> void:
	profile = profile_value.duplicate(true)
	active_run = active_run_value.duplicate(true)
	catalog = catalog_value.duplicate(true)
	deployed_instance_ids = deployed_value.duplicate()
	if is_node_ready():
		_build()


func slot_contract() -> Dictionary:
	var equipped: Array = active_run.get("equipped_duo_links", [])
	return {
		"slot_1": str(equipped[0]) if equipped.size() > 0 else "",
		"slot_2": str(equipped[1]) if equipped.size() > 1 else "",
		"max_slots": 2
	}


func loc(ko: String, en: String, zh: String) -> String:
	match LanguageSettings.locale:
		"en": return en
		"zh_CN": return zh
		_: return ko

func _build() -> void:
	if content_root != null and is_instance_valid(content_root):
		remove_child(content_root)
		content_root.queue_free()
	content_root = Control.new()
	content_root.name = "DuoLinkLoadoutDesignCanvas"
	content_root.size = DESIGN_SIZE
	content_root.theme = load("res://scripts/ui/kit/UIKit.gd").scaled_theme(UISettings.text_scale,UISettings.is_touch_ui())
	add_child(content_root)
	var panel: Control = load("res://scripts/ui/kit/KitPanel.gd").new()
	panel.position = Vector2(40,40)
	panel.size = Vector2(1840,1000)
	content_root.add_child(panel)
	var column: Control = panel.content
	_line(column,loc("합동기 편성","Duo link loadout","合击编组"),"DuoTitle")
	_line(column,loc("최대 2슬롯 · 같은 동료 중복 불가 · 변경은 즉시 반영됩니다.","Maximum 2 slots · No shared members · Changes apply immediately.","最多2槽位 · 伙伴不可重复 · 更改立即生效。"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	build_embedded(_box(scroll,true))
	_build_preset_controls(column)
	var footer := _box(column,false)
	_button(footer,loc("이전","Back","返回"),_cancel,"DuoCancelButton")
	_button(footer,loc("편성 확정","Confirm loadout","确认编组"),_confirm,"DuoConfirmButton")
	load("res://scripts/ui/kit/UIKit.gd").apply_scale(content_root,UISettings.text_scale,UISettings.is_touch_ui())
	_fit_design_canvas()

func build_embedded(parent: Control) -> void:
	_build_slots(parent)
	if editable:
		var auto_toggle := CheckButton.new()
		auto_toggle.name = "DuoLinkAutoUseToggle"
		auto_toggle.text = loc("게이지 100에서 자동 사용","Auto use at 100 gauge","量表100时自动使用")
		auto_toggle.tooltip_text = auto_toggle.text
		auto_toggle.button_pressed = bool(active_run.get("duo_link_auto_use",false))
		auto_toggle.toggled.connect(_on_auto_use_toggled)
		parent.add_child(auto_toggle)
		if bool(profile.get("duo_link_auto_recommendation_unlocked",false)): _button(parent,loc("자동 추천","Recommend loadout","自动推荐"),_request_auto_recommend,"DuoLinkAutoRecommendButton")
	else:
		_line(parent,loc("자동 사용","Auto use","自动使用")+" · "+(loc("켜짐","On","开启") if bool(active_run.get("duo_link_auto_use",false)) else loc("꺼짐","Off","关闭")))
	var order: Array = catalog.keys()
	order.sort_custom(func(a,b): return catalog[a].get("member_instance_ids",[]).has(selected_member_id) and not catalog[b].get("member_instance_ids",[]).has(selected_member_id))
	for value in order:
		_build_link_card(str(value),parent)
	for warning in _deployment_warnings(): _line(parent,warning)

func _build_slots(parent: Control) -> void:
	var equipped: Array = active_run.get("equipped_duo_links",[])
	var slots := _card(parent,"DuoSlotCard")
	_line(slots,loc("현재 팀 장착 %d/2","Team equipped %d/2","全队已装备 %d/2") % equipped.size(),"DuoSlots")
	var row := _box(slots,false)
	for index in range(2):
		var link_id: String = str(equipped[index]) if equipped.size() > index else ""
		var slot := _card(row,"DuoSlotPanel%d" % (index+1),10)
		_line(slot,loc("슬롯 %d · %s","Slot %d · %s","槽位%d · %s") % [index+1,LanguageSettings.ui_text(str(catalog.get(link_id,{}).get("display_name","비어 있음")))],"DuoSlot%d" % (index+1))

func _build_link_card(link_id: String, host: Control) -> void:
	var parent := _card(host,"DuoPanel_"+link_id)
	var definition: Dictionary = catalog.get(link_id,{})
	var unlocked: bool = profile.get("duo_links",{}).get("unlocked",[]).has(link_id)
	var equipped: bool = active_run.get("equipped_duo_links",[]).has(link_id)
	_line(parent,LanguageSettings.ui_text(str(definition.get("display_name",link_id)))+" · "+loc("기록 해금됨","Record unlocked","记录已解锁") if unlocked else loc("잠긴 합동기","Locked duo link","锁定合击"),"DuoCard_"+link_id)
	# Unknown partners stay silhouettes/roles rather than exposing a locked identity.
	var members: Array[String] = []
	for value in definition.get("member_instance_ids",[]):
		var instance := DataRegistry.monster_instance(str(value))
		var species := str(instance.get("species_id",""))
		var progress: Dictionary = member_progress.get(str(value),{})
		var known := not progress.is_empty() and bool(progress.get("owned",false))
		members.append(LanguageSettings.ui_text(str(instance.get("display_name",species))) if known else "??? ("+LanguageSettings.ui_text(str(DataRegistry.monster(species).get("role","")))+")")
	_line(parent," + ".join(members))
	_line(parent,_effect_summary(link_id,definition),"DuoEffect_"+link_id)
	var conditions := GridContainer.new()
	conditions.columns = 2
	conditions.name = "DuoConditions_"+link_id
	conditions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conditions.add_theme_constant_override("h_separation",12)
	conditions.add_theme_constant_override("v_separation",8)
	parent.add_child(conditions)
	var condition: Dictionary = definition.get("unlock_condition",{})
	for value in definition.get("member_instance_ids",[]):
		var progress: Dictionary = member_progress.get(str(value),{})
		_chip(conditions,loc("유대 %d/%d · 개인 기억 %d/%d","Bond %d/%d · Personal memories %d/%d","羁绊 %d/%d · 个人记忆 %d/%d") % [progress.get("bond",0),condition.get("bond_each",45),progress.get("unlocked_memory_ids",[]).size(),condition.get("personal_memory_each",1)],int(progress.get("bond",0)) >= int(condition.get("bond_each",45)) and progress.get("unlocked_memory_ids",[]).size() >= int(condition.get("personal_memory_each",1)))
	var metrics: Dictionary = active_run.get("run_metrics_update3",{})
	_chip(parent,loc("함께 출전 %d/%d일 · 역할 조합 %d/%d회","Together %d/%d days · Role combos %d/%d","共同出战 %d/%d天 · 角色组合 %d/%d次") % [metrics.get("duo_deployed_days",{}).get(link_id,[]).size(),condition.get("deployed_together_days",3),metrics.get("duo_role_progress",{}).get(link_id,{}).get("combo_count",0),condition.get("role_combo_count",5)],metrics.get("duo_deployed_days",{}).get(link_id,[]).size() >= int(condition.get("deployed_together_days",3)) and int(metrics.get("duo_role_progress",{}).get(link_id,{}).get("combo_count",0)) >= int(condition.get("role_combo_count",5)))
	_line(parent,loc("합동 기억 이벤트","Duo memory event","合击记忆事件")+" · "+loc("확인 완료","Completed","已完成") if profile.get("duo_links",{}).get("memory_events_seen",[]).has(str(condition.get("event_id",""))) else loc("합동 기억 미확인 · 조건 충족 뒤 기존 이벤트에서 해금","Duo memory pending · Unlock through the existing event after requirements","合击记忆未确认 · 满足条件后通过原有事件解锁"))
	_line(parent,LanguageSettings.ui_text(str(definition.get("tradeoff",""))))
	if editable:
		var b := _button(parent,loc("장착 해제","Unequip","卸下") if equipped else loc("장착","Equip","装备"),_toggle.bind(link_id),"DuoEquip_"+link_id)
		b.disabled = not unlocked

func _card(parent: Control, id: String, padding: int = 18) -> VBoxContainer:
	var pane := PanelContainer.new()
	pane.name = id
	pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075,0.045,0.115,0.80)
	style.border_color = Color(0.47,0.35,0.55,0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,padding)
	pane.add_theme_stylebox_override("panel",style)
	parent.add_child(pane)
	return _box(pane,true) as VBoxContainer

func _chip(parent: Control, text: String, met: bool) -> void:
	var content := _card(parent,"DuoConditionChip",10)
	_line(content,("✓ " if met else "○ ")+text)
	(content.get_child(0) as Label).add_theme_color_override("font_color",Color("#64e58e") if met else Color("#c0b2c6"))

func _effect_summary(_link_id: String, definition: Dictionary) -> String:
	var parts: Array[String] = []
	var names := {"radius":["반경","Radius","半径"],"shield":["보호막","Shield","护盾"],"duration":["지속 초","Duration s","持续秒"],"heal_per_second":["초당 회복","Heal/s","每秒治疗"],"cleanse_count":["정화","Cleanse","净化"],"redirect_fraction":["피해 대납 비율","Damage redirect fraction","伤害转移比例"],"direct_damage_cap":["직접 피해 상한","Direct damage cap","直接伤害上限"],"damage":["피해","Damage","伤害"],"normal_def_reduction":["일반 방어 감소","Normal defense reduction","普通防御降低"],"boss_def_reduction":["보스 방어 감소","Boss defense reduction","首领防御降低"],"def_reduction_seconds":["방어 감소 초","Defense reduction s","减防秒"],"taunt_max_targets":["유인 최대","Max lured","最多诱导"],"mark_duration":["표식 초","Mark s","标记秒"],"ally_def_bonus":["아군 방어","Ally defense","友军防御"]}
	for key in definition.get("effect",{}):
		if names.has(key): parts.append(loc(names[key][0],names[key][1],names[key][2])+" "+str(definition.effect[key]))
	return " · ".join(parts) if not parts.is_empty() else " / ".join(definition.get("role_tags",[]))

func _deployment_warnings() -> Array[String]:
	var warnings: Array[String] = []
	for value in active_run.get("equipped_duo_links",[]):
		for member in catalog.get(str(value),{}).get("member_instance_ids",[]):
			if not deployed_instance_ids.has(member):
				warnings.append(loc("파트너 미출전 · 전투에서 비활성","Partner not deployed · Inactive in combat","伙伴未出战 · 战斗中无法使用"))
				break
	return warnings

func _box(parent: Control, vertical: bool) -> BoxContainer:
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",16)
	parent.add_child(box)
	return box

func _line(parent: Control, text: String, id: String = "") -> void:
	var label: Label = load("res://scripts/ui/kit/UIKit.gd").label(text,"support",true)
	label.name = id if id != "" else "DuoText"
	label.tooltip_text = text
	label.set_meta("hud_text_fit",true)
	parent.add_child(label)

func _button(parent: Control, text: String, callback: Callable, id: String) -> Button:
	var b: Button = load("res://scripts/ui/kit/KitButton.gd").new().configure(text)
	b.name = id
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _toggle(link_id: String) -> void:
	link_toggled.emit(link_id)


func _on_auto_use_toggled(enabled: bool) -> void:
	auto_use_changed.emit(enabled)


func _build_preset_controls(parent: Control) -> void:
	var count := clampi(int(profile.get("duo_link_preset_slots",0)),0,2)
	for index in range(count):
		var row := _box(parent,false)
		_button(row,loc("프리셋 %d 불러오기","Load preset %d","读取预设%d") % (index+1),_load_preset.bind(index),"DuoPresetLoad%d" % (index+1))
		_button(row,loc("현재 편성 저장","Save current loadout","保存当前编组"),_save_preset.bind(index),"DuoPresetSave%d" % (index+1))


func _save_preset(slot_index: int) -> void:
	preset_saved.emit(slot_index)


func _load_preset(slot_index: int) -> void:
	preset_loaded.emit(slot_index)


func _request_auto_recommend() -> void:
	auto_recommend_requested.emit()


func _confirm() -> void:
	confirmed.emit()


func _cancel() -> void:
	canceled.emit()


func _fit_design_canvas() -> void:
	if content_root == null or size.x <= 0 or size.y <= 0: return
	var factor := minf(size.x / DESIGN_SIZE.x,size.y / DESIGN_SIZE.y)
	content_root.scale = Vector2.ONE*factor
	content_root.position = (size-DESIGN_SIZE*factor)*0.5

func link_card_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	var offset := (viewport_size - DESIGN_SIZE * factor) * 0.5
	var result: Array[Rect2] = []
	for rect in LINK_CARD_RECTS:
		result.append(Rect2(offset + rect.position * factor, rect.size * factor))
	return result
