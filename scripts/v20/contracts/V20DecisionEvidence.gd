class_name V20DecisionEvidence
extends RefCounted

const SCHEMA_VERSION := 1
const EVIDENCE_KIND := "v20_decision_proxy"


static func stable_index(seed_value: int, scope_key: String, option_count: int) -> int:
	if option_count <= 0:
		return -1
	var state := posmod(seed_value, 2147483647)
	for index in range(scope_key.length()):
		state = posmod(state * 1103515245 + scope_key.unicode_at(index) + 12345, 2147483647)
	return posmod(state, option_count)


static func build(seed_value: int, run_id: String, commit_sha: String, configuration: Dictionary, decisions: Array, outcome: Dictionary, metrics: Dictionary) -> Dictionary:
	var report := {
		"schema_version": SCHEMA_VERSION,
		"evidence_kind": EVIDENCE_KIND,
		"run_id": run_id,
		"commit_sha": commit_sha,
		"seed": seed_value,
		"configuration": configuration.duplicate(true),
		"decisions": decisions.duplicate(true),
		"outcome": outcome.duplicate(true),
		"metrics": metrics.duplicate(true)
	}
	report["fingerprint"] = fingerprint(report)
	return report


static func validate(report) -> Dictionary:
	var errors: Array[String] = []
	if not (report is Dictionary):
		return {"ok": false, "errors": ["decision evidence must be a Dictionary"]}
	if int(report.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version must be %d" % SCHEMA_VERSION)
	if str(report.get("evidence_kind", "")) != EVIDENCE_KIND:
		errors.append("evidence_kind must be %s" % EVIDENCE_KIND)
	if str(report.get("run_id", "")).strip_edges() == "":
		errors.append("run_id is required")
	var commit_sha := str(report.get("commit_sha", ""))
	if commit_sha.length() != 40 or not commit_sha.is_valid_hex_number(false):
		errors.append("commit_sha must be a 40-character hexadecimal SHA")
	for key in ["configuration", "outcome", "metrics"]:
		if not (report.get(key) is Dictionary):
			errors.append("%s must be a Dictionary" % key)
	if not (report.get("decisions") is Array):
		errors.append("decisions must be an Array")
	var expected_fingerprint := fingerprint(report)
	if str(report.get("fingerprint", "")) != expected_fingerprint:
		errors.append("fingerprint does not match the canonical report payload")
	return {"ok": errors.is_empty(), "errors": errors}


static func fingerprint(report: Dictionary) -> String:
	var payload := report.duplicate(true)
	payload.erase("fingerprint")
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(canonical_json(payload).to_utf8_buffer())
	return context.finish().hex_encode()


static func canonical_json(value) -> String:
	return JSON.stringify(_canonical_value(value), "", true)


static func _canonical_value(value):
	if value is Dictionary:
		var result: Dictionary = {}
		var keys: Array = value.keys()
		keys.sort_custom(func(a, b): return str(a) < str(b))
		for key_value in keys:
			result[str(key_value)] = _canonical_value(value.get(key_value))
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_canonical_value(item))
		return result
	return value
