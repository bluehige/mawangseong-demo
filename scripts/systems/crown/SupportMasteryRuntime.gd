extends RefCounted
# Three unique role achievements; actor evidence stays transient until victory.
const SPECIES:=["spore_healer","armored_beetle","bat_courier"]
const MILESTONES:=["support","survive","bond80"]
var _root_ref:WeakRef
var game:
	get:return _root_ref.get_ref() if _root_ref!=null else null
var active:=false
var pending:Dictionary={}
var bond_pending:Dictionary={}
func setup(value:Node)->void:_root_ref=weakref(value)
static func normalize_crown(value)->Dictionary:
	var crown:Dictionary=value.duplicate(true) if value is Dictionary else {}
	var milestones:Dictionary=crown.get("species_milestones",{}).duplicate(true) if crown.get("species_milestones",{}) is Dictionary else {}
	var mastery:Dictionary=crown.get("species_mastery",{}).duplicate(true) if crown.get("species_mastery",{}) is Dictionary else {}
	for species in SPECIES:
		var entry:Dictionary=milestones.get(species,{}).duplicate(true) if milestones.get(species,{}) is Dictionary else {}
		var count:=0
		for key in MILESTONES:
			entry[key]=entry.get(key,false) is bool and bool(entry.get(key,false))
			if bool(entry[key]):count+=1
		milestones[species]=entry
		var prior=mastery.get(species,0)
		mastery[species]=maxi(count,maxi(0,int(prior)) if typeof(prior) in [TYPE_INT,TYPE_FLOAT] else 0)
	crown.species_milestones=milestones;crown.species_mastery=mastery
	return crown
func begin_battle()->void:
	pending.clear();bond_pending.clear();active=true
func discard()->void:
	pending.clear();bond_pending.clear();active=false
func participant(unit)->bool:
	return game!=null and is_instance_valid(unit) and not unit.is_queued_for_deletion() and str(unit.unit_id) in SPECIES and str(unit.faction)=="monster" and game.monster_units.has(unit) and game.monster_roster.has(str(unit.unit_id)) and game._monster_available_for_defense(str(unit.unit_id)) and game._monster_deployed_for_defense(str(unit.unit_id))
func entry(unit)->Dictionary:
	var id:int=unit.get_instance_id()
	if not pending.has(id):pending[id]={"actor_id":id,"species":str(unit.unit_id),"support":false,"hp_loss":0,"events":[]}
	return pending[id]
func record_support(unit,event:String,actual:float)->void:
	if not active or actual<=0 or not participant(unit) or not unit.is_alive() or game.current_screen!="combat":return
	var row:Dictionary=entry(unit);row.support=true
	if not row.events.has(event):row.events.append(event)
func record_hp_loss(unit,actual:int)->void:
	if not active or actual<=0 or not participant(unit) or game.current_screen!="combat":return
	var row:Dictionary=entry(unit);row.hp_loss=int(row.hp_loss)+actual
func record_bond(species:String,before:int,after:int)->void:
	if species not in SPECIES or after<80 or after<=before or game==null:return
	if active:
		for unit in game.monster_units:
			if participant(unit) and str(unit.unit_id)==species:bond_pending[unit.get_instance_id()]=species
	else:_merge({species:{"bond80":true}})
func settle(win:bool)->Array[String]:
	if not active:return []
	active=false
	if not win:discard();return []
	var earned:Dictionary={}
	for unit in game.monster_units:
		if not participant(unit):continue
		var species:String=str(unit.unit_id);var id:int=unit.get_instance_id();var row:Dictionary=pending.get(id,{})
		var flags:Dictionary=earned.get(species,{})
		if bool(row.get("support",false)):
			flags.support=true
			if int(row.get("hp_loss",0))>0 and unit.is_alive():flags.survive=true
		if int(game.monster_roster[species].get("bond",0))>=80 or bond_pending.has(id):flags.bond80=true
		earned[species]=flags
	var lines:Array[String]=_merge(earned)
	pending.clear();bond_pending.clear();return lines
func _merge(earned:Dictionary)->Array[String]:
	var crown:Dictionary=normalize_crown(game.update4_profile.get("crown_evolution",{}));var lines:Array[String]=[]
	for species in earned:
		var before:int=int(crown.species_mastery.get(species,0));var row:Dictionary=crown.species_milestones.get(species,{}).duplicate(true)
		for key in MILESTONES:
			if bool(earned[species].get(key,false)):row[key]=true
		crown.species_milestones[species]=row
		var count:=0
		for key in MILESTONES:
			if bool(row.get(key,false)):count+=1
		crown.species_mastery[species]=maxi(before,count)
		if int(crown.species_mastery[species])>before:
			lines.append("%s · %s"%[str(DataRegistry.monster(species).get("display_name",species)),_summary(crown,species)])
	game.update4_profile.crown_evolution=crown
	return lines
func _summary(crown:Dictionary,species:String)->String:
	var row:Dictionary=crown.species_milestones.get(species,{})
	var labels:Array[String]=[]
	for pair in [["support",game.continuity.localized("실제 지원","Support","实际支援")],["survive",game.continuity.localized("부상 후 승리","Hurt and won","受伤后胜利")],["bond80",game.continuity.localized("유대80","Bond80","羁绊80")]]:
		labels.append(str(pair[1])+(" ✓" if bool(row.get(str(pair[0]),false)) else " —"))
	return game.continuity.localized("왕관 숙련 %d · 필요 2 · %s","Crown mastery %d · need 2 · %s","王冠熟练 %d · 需要2 · %s")%[int(crown.species_mastery.get(species,0))," · ".join(labels)]
func summary(species:String)->String:
	if species not in SPECIES or game==null:return ""
	return _summary(normalize_crown(game.update4_profile.get("crown_evolution",{})),species)
