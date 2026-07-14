extends RefCounted
class_name MonsterBondEventService


static func eligible_event_ids(instance: Dictionary, profile_value, catalog: Dictionary) -> Array[String]:
	var profile: Dictionary = profile_value if profile_value is Dictionary else {}
	var species_id := str(instance.get("species_id", instance.get("monster_id", "")))
	var bond := int(instance.get("bond", 0))
	var seen: Array = profile.get("update4_bond_events_seen", [])
	var candidates: Array[Dictionary] = []
	for event_id_value in catalog.keys():
		var event = catalog.get(event_id_value)
		if not (event is Dictionary) or str(event.get("species_id", "")) != species_id:
			continue
		var event_id := str(event_id_value)
		if seen.has(event_id) or bond < int(event.get("bond_threshold", 0)):
			continue
		candidates.append({"id": event_id, "threshold": int(event.get("bond_threshold", 0))})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.threshold) < int(b.threshold))
	var result: Array[String] = []
	for candidate in candidates:
		result.append(str(candidate.id))
	return result


static func complete(profile_value, instance: Dictionary, event_id: String, catalog: Dictionary) -> Dictionary:
	var profile: Dictionary = profile_value.duplicate(true) if profile_value is Dictionary else {}
	var event = catalog.get(event_id, {})
	if not (event is Dictionary) or event.is_empty():
		return {"ok": false, "reason": "unknown_event", "profile": profile}
	var species_id := str(instance.get("species_id", instance.get("monster_id", "")))
	if species_id != str(event.get("species_id", "")):
		return {"ok": false, "reason": "wrong_species", "profile": profile}
	if int(instance.get("bond", 0)) < int(event.get("bond_threshold", 0)):
		return {"ok": false, "reason": "bond_threshold", "profile": profile}
	var seen: Array = profile.get("update4_bond_events_seen", []).duplicate()
	if seen.has(event_id):
		return {"ok": false, "reason": "already_seen", "profile": profile}
	seen.append(event_id)
	profile["update4_bond_events_seen"] = seen
	var unlocked_memories: Array = profile.get("unlocked_memory_ids", []).duplicate()
	var memory_id := str(event.get("memory_id", ""))
	if memory_id != "" and not unlocked_memories.has(memory_id):
		unlocked_memories.append(memory_id)
	profile["unlocked_memory_ids"] = unlocked_memories
	var codex_ids: Array = profile.get("monster_codex_unlocked_ids", []).duplicate()
	if not codex_ids.has(species_id):
		codex_ids.append(species_id)
	profile["monster_codex_unlocked_ids"] = codex_ids
	return {"ok": true, "reason": "", "profile": profile, "memory_id": memory_id, "autosave_required": true}


static func codex_entry(species_id: String, catalog: Dictionary) -> Dictionary:
	for entry_value in catalog.values():
		if entry_value is Dictionary and str(entry_value.get("species_id", "")) == species_id:
			return entry_value.duplicate(true)
	return {}
