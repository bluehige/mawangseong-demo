extends RefCounted
const Resolver = preload("res://scripts/v122/spatial/V122FacilityZoneEffectResolver.gd")
static var catalog: Dictionary = {}

static func for_topology(definition: Dictionary, role: String, topology: Dictionary, recovery_scale: float = 1.0) -> String:
	var legacy := str(definition.get("effect_summary", "성의 고정 구역입니다."))
	if topology.get("defense_zones", []).is_empty() or topology.get("facility_slots", []).is_empty(): return legacy
	for slot in topology.facility_slots:
		if slot.get("linked_zone_ids", []).is_empty(): return legacy
	if catalog.is_empty(): catalog = Resolver.load_catalog()
	var groups: Dictionary = {}
	for effect in catalog.get("facilities", {}).get(role, {}).get("effects", []):
		var scope := str({"local":"연결 구역", "adjacent":"인접 구역", "lane":"같은 전선", "global":"모든 방어 구역"}.get(str(effect.scope), ""))
		var value := float(effect.value)
		var text := ""
		match str(effect.category):
			"placement_capacity": text = "정원 +%d" % roundi(value)
			"attack": text = "공격 +%d%%" % roundi((value-1.0)*100.0)
			"defense": text = "받는 피해 -%d%%" % roundi((1.0-value)*100.0)
			"healing": text = "초당 %.1f 회복" % (value * recovery_scale)
			"slow": text = "적 이동 -%d%%" % roundi((1.0-value)*100.0)
			"detection": text = "적 노출"
			"exposure": text = "적이 받는 피해 +%d%%" % roundi((value-1.0)*100.0)
		if text == "" or scope == "": continue
		if not groups.has(scope): groups[scope] = []
		groups[scope].append(text)
	if groups.is_empty(): return legacy
	var lines: Array[String] = []
	if legacy.begins_with("체력 ") and legacy.contains(". "):
		lines.append(legacy.substr(0, legacy.find(". ")))
	for scope in groups: lines.append(str(scope) + ": " + " · ".join(groups[scope]))
	return ". ".join(lines) + "."
