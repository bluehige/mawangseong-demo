extends RefCounted
## Deterministic daily rations for unique individuals. No save I/O.
const VERSION := 1
const COSTS := {"slime":1,"goblin":1,"imp":1,"kobold_scout":1,"spore_healer":2,"war_drummer":2,"ghost_housemaid":2,"bat_courier":2,"spider_tailor":2,"stone_sentinel":3,"mimic_porter":3,"moon_tracker":3,"graveyard_hound":3,"armored_beetle":3}

static func stage(day: int) -> int:
	return 1 if day<15 else 2 if day<20 else 3 if day<27 else 4

static func income(day: int) -> int: return [15,23,30,34][stage(day)-1]
static func capacity(day: int) -> int: return [30,45,60,75][stage(day)-1]

static func fresh() -> Dictionary:
	return {"version":VERSION,"hungry":[],"last_day":0,"last":{},"owned":[],"contracts":[]}

static func migrate(value, day: int) -> Dictionary:
	var state := fresh()
	if not value is Dictionary: return state
	if value.get("hungry") is Array:
		for id in value.hungry:
			if id is String and COSTS.has(id) and id not in state.hungry: state.hungry.append(id)
	if value.get("contracts") is Array:
		for species in value.contracts:
			if species is String and species in ["spore_healer","stone_sentinel","war_drummer","moon_tracker","mimic_porter"] and species not in state.contracts and state.contracts.size()<2: state.contracts.append(species)
	if value.get("owned") is Array:
		for id in value.owned:
			if id is String and id not in state.owned: state.owned.append(id)
	if value.get("last_day") is int or value.get("last_day") is float: state.last_day = clampi(int(value.last_day),0,day)
	if value.get("last") is Dictionary: state.last = value.last.duplicate(true)
	return state

static func settle(food: int, day: int, deployed: Array, state_value: Dictionary, bonus: int = 0) -> Dictionary:
	var state := migrate(state_value,day)
	if int(state.last_day)>=day: return {"food":food,"state":state,"ledger":state.last,"already_settled":true}
	var gained := maxi(0,income(day)+bonus)
	var available := maxi(0,food)+gained
	var due := 0; var paid := 0; var rows: Array = []; var hungry: Array = []
	# Stable catalog order is also the published allocation priority.
	for species in COSTS:
		if species not in deployed: continue
		var cost: int = COSTS[species]
		var ration := mini(cost,available)
		available -= ration; paid += ration; due += cost
		if ration<cost: hungry.append(species)
		rows.append({"species":species,"due":cost,"paid":ration,"hungry":ration<cost})
	var overflow := maxi(0,available-capacity(day))
	var ledger := {"day":day,"before":food,"income":gained,"capacity":capacity(day),"due":due,"paid":paid,"shortfall":due-paid,"overflow":overflow,"after":mini(available,capacity(day)),"rows":rows,"hungry":hungry}
	# Waiting members eat nothing and recover at the next daily settlement.
	state.hungry = hungry; state.last_day = day; state.last = ledger
	return {"food":ledger.after,"state":state,"ledger":ledger,"already_settled":false}

static func lines(ledger: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if ledger.is_empty(): return result
	result.append("식량 정산: %d + 수입 %d − 유지비 %d = %d / 창고 %d" % [ledger.before,ledger.income,ledger.paid,ledger.after,ledger.capacity])
	var names: Array[String] = []
	for row in ledger.rows:
		var definition: Dictionary = DataRegistry.monster(row.species)
		var name := str(definition.get("display_name",definition.get("name",row.species)))
		for member in DataRegistry.monster_instances.values():
			if member.get("species_id","")==row.species: name = str(member.get("display_name",name)); break
		names.append("%s %d/%d%s" % [name,row.paid,row.due," 굶주림" if row.hungry else ""])
	if not names.is_empty(): result.append("유지비 지급: "+" · ".join(names))
	if int(ledger.shortfall)>0: result.append("미지급 %d · 굶주림: 다음 전투 공격 −20%% / 회복 둥지 회복 불가" % ledger.shortfall)
	if int(ledger.overflow)>0: result.append("창고 초과 식량 %d 소실" % ledger.overflow)
	return result
