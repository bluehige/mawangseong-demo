extends RefCounted
## Explicit, data-only predicates. An absent field never satisfies a rule.
const PATH := "res://data/v130r/achievements/runtime_rules.json"
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))

func matches(id: String, event: String, facts: Dictionary) -> bool:
	if not rules.has(id) or rules[id].event != event: return false
	for term in rules[id].terms:
		var key: String = term[0]
		if not facts.has(key): return false
		var actual: Variant = facts[key]
		match str(term[1]):
			"eq":
				if actual != term[2]: return false
			"gte":
				if not (actual is int or actual is float) or float(actual) < float(term[2]): return false
			"prefix":
				if not str(actual).begins_with(str(term[2])): return false
	return true
