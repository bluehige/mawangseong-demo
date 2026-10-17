extends RefCounted
## Shared data-only specialization math. Legacy skill_upgrade stays compatible.
const CELL := 71.554175

static func apply_stats(rule: Dictionary, stats: Dictionary) -> void:
	for field in rule.get("stat_multipliers",{}):
		stats[field] = float(stats.get(field,0))*float(rule.stat_multipliers[field])
	for field in rule.get("stat_bonuses",{}):
		stats[field] = float(stats.get(field,0))+float(rule.stat_bonuses[field])
	for field in ["max_hp","atk","def"]:
		if stats.has(field): stats[field] = roundi(stats[field])

static func delta(rule: Dictionary, skill: String, field: String) -> float:
	var mods: Dictionary = rule.get("skill_mods",{}).get(skill,{})
	if mods.has(field): return float(mods[field])
	var old: Dictionary = rule.get("skill_upgrade",{})
	return float(old.get(field,0)) if str(old.get("skill_id",""))==skill else 0.0

static func value(rule: Dictionary, skill: String, field: String, base: float) -> float:
	return base+delta(rule,skill,field)

static func flag(rule: Dictionary, key: String, fallback: Variant = null) -> Variant:
	return rule.get("flags",{}).get(key,rule.get(key,fallback))

static func valid_choices(raw: Variant) -> Dictionary:
	var clean := {}
	if not raw is Dictionary: return clean
	for species in raw:
		var id := str(raw[species])
		if str(DataRegistry.specialization(id).get("monster_id",""))==str(species): clean[species] = id
	return clean

static func preview(rule: Dictionary, stats: Dictionary) -> Array[String]:
	var after := stats.duplicate(true); apply_stats(rule,after)
	var result: Array[String] = []
	for field in ["max_hp","atk","def","move_speed","attack_range","attack_interval"]:
		if float(after.get(field,0))!=float(stats.get(field,0)):
			result.append("%s %s → %s" % [{"max_hp":"체력","atk":"공격","def":"방어","move_speed":"이동","attack_range":"사거리","attack_interval":"공격 간격"}[field],str(stats.get(field,0)),str(after[field])])
	var defaults := {
		"tongue_snag":{"range":3*CELL,"root_seconds":1.5},"puddle_song":{"radius_cells":2,"def_bonus":3},
		"slime_trail":{"trap_count":1,"cooldown":12},"shell_retreat":{"reduction":.6},
		"no_passage":{"radius_cells":1.5,"duration":3},"hero_pose":{"cooldown":10,"max_targets":3},
		"peekaboo":{"duration":2.5,"fear_radius_cells":0},"wax_drip":{"burn_seconds":0,"burn_radius_cells":0,"burn_dps":0},
		"tunnel_hop":{"ally_guard_seconds":0,"ally_guard_bonus":0,"ally_guard_radius_cells":2},"undermine":{"interrupt_seconds":2.5},
		"wrong_way":{"duration":4},"map_spread":{"radius_cells":2,"move_multiplier":1.15},"swarm":{"hits":3,"cooldown":9},
		"stitch_curse":{"duration":6,"damage_taken_multiplier":1.2,"attack_multiplier":.85},"proxy_pain":{"redirect_ratio":.3,"max_targets":1},
		"spore_mend":{"heal_multiplier":1,"max_targets":1},"cleansing_bloom":{"heal_multiplier":1,"immunity_seconds":0},
		"stone_pulse":{"radius":180,"stun_seconds":0},"war_rhythm":{"radius":180,"enemy_attack_interval_multiplier":1},
		"false_treasure":{"duration_bonus":5},"false_footprints":{"radius":260,"slow_factor":.62},
		"slime_shield":{"duration_bonus":5,"reduction_bonus":.4},"quick_slash":{"damage_multiplier_bonus":1.9},
		"fireball":{"damage_bonus":52,"range_bonus":320},"flame_zone":{"damage_bonus":34,"slow_seconds_bonus":2.5,"slow_factor_bonus":.7},
		"spectral_transfer":{"shield_bonus":20},"haunted_broom_whirl":{"damage_multiplier_bonus":.9,"knockback_bonus":24},
		"scent_lock":{"marked_basic_attack_multiplier_bonus":1.1,"duration_bonus":7},"home_guard_bark":{"shield_bonus":18,"max_targets_bonus":2},
		"carapace_ram":{"def_reduction_bonus":2,"damage_multiplier_bonus":1,"distance_penalty":110},"patch_plates":{"facility_repair_bonus":35,"ally_shield_bonus":28}}
	var names := {"range":"사거리","radius":"범위","radius_cells":"범위(칸)","root_seconds":"속박(초)","def_bonus":"방어","trap_count":"함정 수","cooldown":"재사용(초)","reduction":"피해 감소율","duration":"지속(초)","max_targets":"대상 수","fear_radius_cells":"공포 범위(칸)","burn_seconds":"화상(초)","burn_radius_cells":"화상 범위(칸)","burn_dps":"초당 화상","ally_guard_seconds":"보호(초)","ally_guard_bonus":"아군 방어","ally_guard_radius_cells":"보호 범위(칸)","interrupt_seconds":"행동 방해(초)","move_multiplier":"이동 배율","hits":"연타 수","damage_taken_multiplier":"받는 피해 배율","attack_multiplier":"공격 배율","redirect_ratio":"이전 비율","heal_multiplier":"회복 배율","immunity_seconds":"면역(초)","stun_seconds":"기절(초)","enemy_attack_interval_multiplier":"적 공격 간격","duration_bonus":"지속(초)","slow_factor":"이동 배율","reduction_bonus":"감소율","damage_multiplier_bonus":"피해 계수","damage_bonus":"피해","range_bonus":"사거리","slow_seconds_bonus":"둔화(초)","slow_factor_bonus":"이동 배율","shield_bonus":"보호막","knockback_bonus":"밀침","marked_basic_attack_multiplier_bonus":"표식 피해 배율","max_targets_bonus":"대상 수","def_reduction_bonus":"방어 감소","distance_penalty":"돌진 거리","facility_repair_bonus":"시설 수리","ally_shield_bonus":"보호막","slow_multiplier":"이동 배율","fire_hits_to_remove":"내구","max_slow_targets":"대상 수","shield_max_hp_ratio":"보호막 비율","facility_repair":"시설 수리","attack_interval_multiplier":"공격 간격 배율","hold_seconds":"보류(초)"}
	for skill in rule.get("skill_mods",{}):
		for field in rule.skill_mods[skill]:
			if field not in names: continue
			var base := float(defaults.get(skill,{}).get(field,DataRegistry.skill(skill).get(field,0)))
			var change := float(rule.skill_mods[skill][field])
			if field in ["slow_factor_bonus","distance_penalty"]: change = -change
			result.append("%s %s → %s" % [names[field],str(snappedf(base,.01)),str(snappedf(base+change,.01))])
	var flags: Dictionary = rule.get("flags",{})
	for key in ["position_defense","stealth_heal_per_second","aura_damage_multiplier","marked_damage_multiplier","lured_first_hit_multiplier","raid_risk_reduction","raid_infamy_bonus","team_mark_move_multiplier","recovery_gold_multiplier","toll_recovery_ratio"]:
		if not flags.has(key): continue
		var label: String = {"position_defense":"조건부 방어","stealth_heal_per_second":"초당 회복","aura_damage_multiplier":"주변 피해 배율","marked_damage_multiplier":"표식 피해 배율","lured_first_hit_multiplier":"첫 타격 배율","raid_risk_reduction":"위험 감소 단계","raid_infamy_bonus":"추가 악명 비율","team_mark_move_multiplier":"추적 이동 배율","recovery_gold_multiplier":"회수 금화 배율","toll_recovery_ratio":"정산 회수 비율"}[key]
		var base := 1 if "multiplier" in key else 0
		var after_value: float = float(flags[key].bonus) if key=="position_defense" else float(flags[key])
		result.append("%s %s → %s" % [label,str(base),str(after_value)])
	return result

var controller_ref: WeakRef
var controller: RefCounted:
	get: return controller_ref.get_ref() if controller_ref!=null else null

func setup(battle: RefCounted) -> void:
	controller_ref = weakref(battle)
	for unit in battle.root.monster_units:
		unit.set_meta("specialization",battle.root._monster_specialization(unit.unit_id).duplicate(true))

func rule(unit: Node) -> Dictionary:
	return unit.get_meta("specialization",{})

func tick(delta_time: float) -> void:
	for unit in controller.root.monster_units:
		if not unit.is_alive(): continue
		var spec := rule(unit)
		var position_rule: Dictionary = flag(spec,"position_defense",{})
		var defense := 0
		if not position_rule.is_empty():
			var inside := false
			if position_rule.has("room"): inside = unit.position.distance_to(controller.map.center(position_rule.room))<=float(position_rule.radius_cells)*CELL
			else: inside = str(unit.get_cell_tags().get(position_rule.tag,""))==str(position_rule.value)
			if inside: defense = int(position_rule.bonus)
		unit.set_meta("spec_position_def",defense)
		if bool(flag(spec,"team_mark_tracking",false)) and unit.has_meta("spec_mark_target"):
			var marked = instance_from_id(int(unit.get_meta("spec_mark_target")))
			if is_instance_valid(marked) and marked.is_alive() and marked.new_skill_clock<float(marked.get_meta("spec_mark_until",0)):
				for ally in controller.root.monster_units:
					if not ally.is_alive(): continue
					ally.set_meta("spec_team_target",marked.get_instance_id())
					ally.set_meta("spec_team_until",ally.new_skill_clock+.2)
					ally.set_meta("spec_team_move",float(flag(spec,"team_mark_move_multiplier",1.0)))
		var heal := float(flag(spec,"stealth_heal_per_second",0))
		if heal>0 and unit.stealthed():
			var carry := float(unit.get_meta("spec_heal_carry",0))+delta_time*heal
			var amount := floori(carry); unit.set_meta("spec_heal_carry",carry-amount)
			if amount>0:
				for ally in controller.monster_skills.allies(unit,float(flag(spec,"stealth_heal_radius_cells",2))): ally.heal(amount)
		var radius := float(flag(spec,"reveal_radius_cells",0))
		if radius>0:
			for enemy in controller.monster_skills.enemies(unit,radius): enemy.set_meta("revealed_until",enemy.new_skill_clock+.2)
			for ally in controller.monster_skills.allies(unit,radius):
				ally.set_meta("spec_aura_until",ally.new_skill_clock+.2)
				ally.set_meta("spec_aura_damage",float(flag(spec,"aura_damage_multiplier",1)))
	for enemy in controller.root.enemy_units:
		if not enemy.is_alive() or enemy.new_skill_clock>=float(enemy.get_meta("spec_burn_until",0)): continue
		var carry := float(enemy.get_meta("spec_burn_carry",0))+delta_time*float(enemy.get_meta("spec_burn_dps",0))
		var amount := floori(carry); enemy.set_meta("spec_burn_carry",carry-amount)
		if amount>0: enemy.receive_magic_damage(amount)

func damage_multiplier(attacker: Node, victim: Node) -> float:
	if not is_instance_valid(attacker) or not is_instance_valid(victim): return 1.0
	var result := 1.0
	if attacker.new_skill_clock<float(attacker.get_meta("spec_aura_until",0)): result *= float(attacker.get_meta("spec_aura_damage",1))
	if victim.new_skill_clock<float(victim.get_meta("spec_mark_until",0)):
		result *= float(rule(attacker).get("flags",{}).get("marked_damage_multiplier",1.0))
	if victim.new_skill_clock<float(victim.get_meta("spec_lured_until",0)) and int(victim.get_meta("spec_lured_by",0))==attacker.get_instance_id():
		var multiplier := float(flag(rule(attacker),"lured_first_hit_multiplier",1.0))
		if multiplier>1:
			var used: Array = attacker.get_meta("spec_lure_hits",[])
			var token := str(victim.get_instance_id())+":"+str(victim.get_meta("spec_lured_until"))
			if token not in used: result *= multiplier; used.append(token); attacker.set_meta("spec_lure_hits",used)
	if victim.new_skill_clock<float(victim.get_meta("spec_bag_until",0)) and int(victim.get_meta("spec_bag_carrier",0))==attacker.get_instance_id():
		result *= float(flag(rule(attacker),"held_thief_damage_multiplier",1))
	return result

func after_legacy_skill(caster: Node, id: String, victim: Node) -> void:
	if id=="moon_mark" and is_instance_valid(victim):
		victim.set_meta("spec_mark_until",victim.new_skill_clock+6)
		caster.set_meta("spec_mark_target",victim.get_instance_id())
	if id=="false_treasure":
		for enemy in controller.monster_skills.enemies(caster,250/CELL):
			enemy.set_meta("spec_lured_until",enemy.new_skill_clock+5+delta(rule(caster),id,"duration_bonus"))
			enemy.set_meta("spec_lured_by",caster.get_instance_id())

func refund_tolls() -> int:
	var total := 0
	for unit in controller.root.monster_units:
		var amount := int(unit.get_meta("spec_toll_pending",0))
		if amount>0: total += amount; unit.set_meta("spec_toll_pending",0)
	GameState.gold += total
	controller.root.treasure_gold_stolen_this_battle = maxi(0,controller.root.treasure_gold_stolen_this_battle-total)
	return total

func guard_ally(unit: Node) -> Node:
	var result: Node = null
	var lowest := .7
	for ally in controller.root.monster_units:
		if ally==unit or not ally.is_alive() or ally.position.distance_to(controller.home(unit))>controller.leash_radius(unit): continue
		var ratio := float(ally.hp)/maxi(1,ally.max_hp)
		if ratio<lowest: lowest = ratio; result = ally
	return result
