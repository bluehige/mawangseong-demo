extends RefCounted
class_name RunMetricsTracker

var definitions: Dictionary = {}
var metrics: Dictionary = {}


func setup(metric_definitions: Dictionary) -> Array[String]:
	definitions = metric_definitions.duplicate(true)
	metrics.clear()
	var errors: Array[String] = []
	for metric_id_value in definitions.keys():
		var metric_id := str(metric_id_value)
		var definition = definitions.get(metric_id_value)
		if not (definition is Dictionary):
			errors.append("지표 %s의 정의가 사전 형식이 아닙니다." % metric_id)
			continue
		var metric_type := str(definition.get("type", "number"))
		if metric_type not in ["number", "bool", "string", "array"]:
			errors.append("지표 %s의 자료형을 지원하지 않습니다: %s" % [metric_id, metric_type])
			continue
		var default_value = definition.get("default", _default_for_type(metric_type))
		if not _matches_type(default_value, metric_type):
			errors.append("지표 %s의 기본값 자료형이 올바르지 않습니다." % metric_id)
			continue
		metrics[metric_id] = _copy_value(default_value)
	return errors


func add(metric_id: String, delta: float) -> bool:
	if not definitions.has(metric_id) or str(definitions.get(metric_id, {}).get("type", "number")) != "number":
		return false
	var definition: Dictionary = definitions.get(metric_id, {})
	var next_value := float(metrics.get(metric_id, 0.0)) + delta
	next_value = max(float(definition.get("min", -INF)), next_value)
	next_value = min(float(definition.get("max", INF)), next_value)
	metrics[metric_id] = next_value
	return true


func set_value(metric_id: String, value) -> bool:
	if not definitions.has(metric_id):
		return false
	var definition: Dictionary = definitions.get(metric_id, {})
	var metric_type := str(definition.get("type", "number"))
	if not _matches_type(value, metric_type):
		return false
	if metric_type == "number":
		value = clamp(float(value), float(definition.get("min", -INF)), float(definition.get("max", INF)))
	metrics[metric_id] = _copy_value(value)
	return true


func snapshot() -> Dictionary:
	return metrics.duplicate(true)


func restore(saved_metrics: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for metric_id_value in saved_metrics.keys():
		var metric_id := str(metric_id_value)
		if not definitions.has(metric_id):
			errors.append("저장에 알 수 없는 지표가 있습니다: %s" % metric_id)
			continue
		if not set_value(metric_id, saved_metrics.get(metric_id_value)):
			errors.append("저장 지표 %s의 자료형이 올바르지 않습니다." % metric_id)
	return errors


static func _default_for_type(metric_type: String):
	match metric_type:
		"bool": return false
		"string": return ""
		"array": return []
		_: return 0.0


static func _matches_type(value, metric_type: String) -> bool:
	match metric_type:
		"number": return value is int or value is float
		"bool": return value is bool
		"string": return value is String
		"array": return value is Array
	return false


static func _copy_value(value):
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value
