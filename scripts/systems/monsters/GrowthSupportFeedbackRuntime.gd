extends RefCounted
# Presentation reads measured, source-owned kernel values; never changes rewards.
const KEYS:=["effective_healing","shield_absorbed","support_protection_applications","duo_shared_commits","redirect_actual_hp_taken"]
var _root_ref:WeakRef
var game:
	get:return _root_ref.get_ref() if _root_ref!=null else null
func setup(value:Node)->void:_root_ref=weakref(value)
static func normalize(value)->Dictionary:
	var result:Dictionary={}
	if not value is Dictionary:return result
	for key in KEYS:
		var number=value.get(key,0)
		result[key]=clampi(int(number),0,2147483647) if typeof(number) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(number)) else 0
	return result
func snapshot(species:String)->Dictionary:return normalize(game.battle_contribution_stats.get(species,{}))
func record_protection(caster,target,changed:bool)->void:
	if not changed or game==null or game.current_screen!="combat" or not is_instance_valid(caster) or not caster.is_alive() or not is_instance_valid(target) or not target.is_alive():return
	game._record_monster_contribution(str(caster.unit_id),"support_protection_applications",1)
	game.continuity.record_pudding_support(caster,target)
func record_duo(members:Array)->void:
	if game==null or game.current_screen!="combat":return
	var seen:Dictionary={}
	for actor in members:
		if not is_instance_valid(actor) or seen.has(actor.get_instance_id()):continue
		seen[actor.get_instance_id()]=true
		game._record_monster_contribution(str(actor.unit_id),"duo_shared_commits",1)
func contribution_text(value)->String:
	if not value is Dictionary or value.is_empty():return game.continuity.localized("지원 기록 없음","No support records","无支援记录")
	var row:Dictionary=normalize(value);var lines:Array[String]=[]
	for pair in [["effective_healing",game.continuity.localized("실제 회복 HP %d","Healed HP %d","实际治疗HP %d")],["support_protection_applications",game.continuity.localized("보호 적용 %d회","Protection applied %d","保护应用%d次")],["shield_absorbed",game.continuity.localized("실제 방어막 흡수 %d","Barrier absorbed %d","护盾实际吸收%d")],["redirect_actual_hp_taken",game.continuity.localized("대신 받은 HP 피해 %d","Redirect HP taken %d","代受HP伤害%d")],["duo_shared_commits",game.continuity.localized("합동기 공유 사용 %d회","Shared duo use %d","合技共享使用%d次")]]:
		var count:int=int(row.get(str(pair[0]),0))
		if count>0:lines.append(str(pair[1])%count)
	return " · ".join(lines.slice(0,3)) if not lines.is_empty() else game.continuity.localized("이번 전투 지원 성과 없음","No support effect this battle","本场无支援成果")
func next_choice()->String:
	var branch:String=str(game.monster_roster.get("slime",{}).get("promotion_id",""))
	if branch not in ["slime_gate_bulwark","slime_rescue_alchemy_gel"]:return ""
	var alternative:String="slime_rescue_alchemy_gel" if branch=="slime_gate_bulwark" else "slime_gate_bulwark"
	var name:String=LanguageSettings.ui_text(str(DataRegistry.evolution_rule(alternative).get("display_name",alternative)))
	var behavior:String=game.continuity.localized("부상 아군 보호","protect wounded allies","保护受伤同伴") if alternative=="slime_rescue_alchemy_gel" else game.continuity.localized("입구 방어선 유지","hold the entry line","守住入口防线")
	var text:String=game.continuity.localized("다음 회차의 다른 선택: %s · %s. DAY12/LV3%s 조건과 기존 비용을 유지합니다.","Another choice next cycle: %s · %s. Existing DAY12/LV3%s conditions and costs apply.","下周目另一选择：%s · %s。保留DAY12/LV3%s条件与原费用。")%[name,behavior,game.continuity.localized("/유대25","/Bond25","/羁绊25") if alternative=="slime_rescue_alchemy_gel" else ""]
	var owned:bool=game.monster_roster.has("spore_healer") or game.campaign_profile.get("unlocked_contract_ids",[]).has("spore_healer")
	if not owned:return text+" "+game.continuity.localized("모리는 기존 계약으로 합류할 수 있습니다. 다른 엔딩 조건은 별도로 판정됩니다.","Mori joins through the existing contract. Other ending conditions are evaluated separately.","莫里可通过原有契约加入。其他结局条件另行判定。")+seen_ending_hint()
	var link:String="link_spore_jelly_shelter"
	if game.update3_profile.get("duo_links",{}).get("unlocked",[]).has(link):
		text+=" "+game.continuity.localized("이미 해금한 푸딩+모리 피난처로 실제 회복과 보호 적용을 비교해 보세요.","Your unlocked Pudding+Mori shelter lets you compare actual healing and protection.","可用已解锁的布丁+莫里避难所比较实际治疗与保护。")
	else:
		var rule:Dictionary=DataRegistry.update3_duo_links.get(link,{}).get("unlock_condition",{})
		text+=" "+game.continuity.localized("기존 합동기는 각자 유대%d·기억%d개·함께 출전%d일·역할조합%d회에서 열립니다.","The existing duo requires Bond%d and %d memories each, %d deployed days together and %d role combinations.","原有合技条件：各自羁绊%d、%d段记忆、共同出战%d天、角色配合%d次。")%[int(rule.get("bond_each",45)),int(rule.get("personal_memory_each",1)),int(rule.get("deployed_together_days",3)),int(rule.get("role_combo_count",5))]
	return text+" "+game.continuity.localized("엔딩은 다른 조건도 함께 판정됩니다.","Endings also depend on other conditions.","结局也会同时判定其他条件。")+seen_ending_hint()
func seen_ending_hint()->String:
	var archive=game.campaign_profile.get("ending_archive",{})
	if not archive is Dictionary:return ""
	var ids:Array=archive.keys();ids.sort()
	for id in ids:
		var entry=archive[id];var rule:Dictionary=DataRegistry.ending_rules.get(str(id),{})
		if not entry is Dictionary or int(entry.get("seen_count",0))<=0 or rule.is_empty() or bool(rule.get("fallback",false)):continue
		var evaluated:Dictionary=game.EndingConditionEvaluatorScript.evaluate(rule.get("requirements",{}),game.run_metrics_tracker.snapshot())
		if not bool(evaluated.get("ok",false)):continue
		var name:String=LanguageSettings.ui_text(str(rule.get("display_name",id)))
		var status:String=game.continuity.localized("충족","met","满足") if bool(evaluated.get("value",false)) else game.continuity.localized("미충족","not met","未满足")
		return " "+game.continuity.localized("이미 본 %s의 기록 조건: 현재 %s. 확정은 전체 엔딩 판정에 따릅니다.","Known ending %s: its recorded conditions are currently %s. Final selection uses the full ending evaluation.","已见结局%s：记录条件目前%s，最终结果由全部结局判定。")%[name,status]
	return ""
