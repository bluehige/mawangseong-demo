extends RefCounted
class_name EndingConditionEvaluator

const ALLOWED_OPERATORS := ["==", "!=", ">", ">=", "<", "<=", "contains"]


static func validate_rules(rules: Dictionary, metric_definitions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var fallback_count := 0
	var catalog_codes: Dictionary = {}
	for ending_id_value in rules.keys():
		var ending_id := str(ending_id_value)
		var value = rules.get(ending_id_value)
		if not (value is Dictionary):
			errors.append("엔딩 %s의 규칙이 사전 형식이 아닙니다." % ending_id)
			continue
		var rule: Dictionary = value
		if ending_id == "" or str(rule.get("id", "")) != ending_id:
			errors.append("엔딩 키와 id가 일치하지 않습니다: %s" % ending_id)
		if str(rule.get("display_name", "")).strip_edges() == "":
			errors.append("엔딩 %s의 표시 이름이 비어 있습니다." % ending_id)
		var catalog_code := str(rule.get("catalog_code", ""))
		if catalog_code.length() != 3 or not catalog_code.begins_with("E") or not catalog_code.substr(1).is_valid_int():
			errors.append("엔딩 %s의 도감 코드가 E00 형식이 아닙니다." % ending_id)
		elif catalog_codes.has(catalog_code):
			errors.append("엔딩 도감 코드가 중복됩니다: %s" % catalog_code)
		else:
			catalog_codes[catalog_code] = ending_id
		if bool(rule.get("fallback", false)):
			fallback_count += 1
		if not _is_number(rule.get("priority", 0)):
			errors.append("엔딩 %s의 우선순위가 숫자가 아닙니다." % ending_id)
		_validate_condition(rule.get("requirements", {}), metric_definitions, "엔딩 %s" % ending_id, errors)
		var weights = rule.get("score_weights", {})
		if not (weights is Dictionary):
			errors.append("엔딩 %s의 점수 가중치가 사전 형식이 아닙니다." % ending_id)
		else:
			for metric_id_value in weights.keys():
				var metric_id := str(metric_id_value)
				if not metric_definitions.has(metric_id):
					errors.append("엔딩 %s가 알 수 없는 지표를 참조합니다: %s" % [ending_id, metric_id])
				if not _is_number(weights.get(metric_id_value)):
					errors.append("엔딩 %s의 지표 가중치가 숫자가 아닙니다: %s" % [ending_id, metric_id])
	if fallback_count != 1:
		errors.append("fallback 엔딩은 정확히 하나여야 합니다. 현재 %d개입니다." % fallback_count)
	return errors


static func evaluate(condition, metrics: Dictionary) -> Dictionary:
	if not (condition is Dictionary):
		return {"ok": false, "value": false, "error": "조건이 사전 형식이 아닙니다."}
	if condition.is_empty():
		return {"ok": true, "value": true, "error": ""}
	if condition.has("all"):
		var all_conditions = condition.get("all")
		if not (all_conditions is Array):
			return {"ok": false, "value": false, "error": "all 조건은 배열이어야 합니다."}
		for child in all_conditions:
			var child_result := evaluate(child, metrics)
			if not bool(child_result.get("ok", false)):
				return child_result
			if not bool(child_result.get("value", false)):
				return {"ok": true, "value": false, "error": ""}
		return {"ok": true, "value": true, "error": ""}
	if condition.has("any"):
		var any_conditions = condition.get("any")
		if not (any_conditions is Array):
			return {"ok": false, "value": false, "error": "any 조건은 배열이어야 합니다."}
		for child in any_conditions:
			var child_result := evaluate(child, metrics)
			if not bool(child_result.get("ok", false)):
				return child_result
			if bool(child_result.get("value", false)):
				return {"ok": true, "value": true, "error": ""}
		return {"ok": true, "value": false, "error": ""}
	if condition.has("not"):
		var not_result := evaluate(condition.get("not"), metrics)
		if not bool(not_result.get("ok", false)):
			return not_result
		return {"ok": true, "value": not bool(not_result.get("value", false)), "error": ""}
	var metric_id := str(condition.get("metric", ""))
	var operator := str(condition.get("op", ""))
	if metric_id == "" or not metrics.has(metric_id):
		return {"ok": false, "value": false, "error": "알 수 없는 지표입니다: %s" % metric_id}
	if operator not in ALLOWED_OPERATORS:
		return {"ok": false, "value": false, "error": "허용되지 않은 비교 연산자입니다: %s" % operator}
	if not condition.has("value"):
		return {"ok": false, "value": false, "error": "비교 값이 없습니다."}
	var left = metrics.get(metric_id)
	var right = condition.get("value")
	return _compare(left, operator, right)


static func resolve(rules: Dictionary, metrics: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var fallback_id := ""
	for ending_id_value in rules.keys():
		var ending_id := str(ending_id_value)
		var rule: Dictionary = rules.get(ending_id_value, {})
		if bool(rule.get("fallback", false)):
			fallback_id = ending_id
			continue
		var requirement_result := evaluate(rule.get("requirements", {}), metrics)
		if not bool(requirement_result.get("ok", false)):
			return {"ok": false, "ending_id": "", "error": str(requirement_result.get("error", "조건 평가 실패")), "candidates": []}
		if not bool(requirement_result.get("value", false)):
			continue
		var score := float(rule.get("base_score", 0.0))
		for metric_id_value in rule.get("score_weights", {}).keys():
			var metric_id := str(metric_id_value)
			var metric_value = metrics.get(metric_id, 0.0)
			if _is_number(metric_value):
				score += float(metric_value) * float(rule.get("score_weights", {}).get(metric_id_value, 0.0))
		candidates.append({"id": ending_id, "score": score, "priority": int(rule.get("priority", 0))})
	if candidates.is_empty():
		return {"ok": fallback_id != "", "ending_id": fallback_id, "error": "" if fallback_id != "" else "fallback 엔딩이 없습니다.", "candidates": []}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.get("score", 0.0)), float(b.get("score", 0.0))):
			return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
		if int(a.get("priority", 0)) != int(b.get("priority", 0)):
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return {"ok": true, "ending_id": str(candidates[0].get("id", fallback_id)), "error": "", "candidates": candidates}


static func _validate_condition(condition, metric_definitions: Dictionary, context: String, errors: Array[String]) -> void:
	if not (condition is Dictionary):
		errors.append("%s의 조건이 사전 형식이 아닙니다." % context)
		return
	if condition.is_empty():
		return
	var structural_keys := 0
	for key in ["all", "any", "not"]:
		if condition.has(key):
			structural_keys += 1
	if structural_keys > 1:
		errors.append("%s의 조건 조합은 all/any/not 중 하나만 사용할 수 있습니다." % context)
		return
	if condition.has("all") or condition.has("any"):
		var key := "all" if condition.has("all") else "any"
		var children = condition.get(key)
		if not (children is Array) or children.is_empty():
			errors.append("%s의 %s 조건은 비어 있지 않은 배열이어야 합니다." % [context, key])
			return
		for child in children:
			_validate_condition(child, metric_definitions, context, errors)
		return
	if condition.has("not"):
		_validate_condition(condition.get("not"), metric_definitions, context, errors)
		return
	var metric_id := str(condition.get("metric", ""))
	if metric_id == "" or not metric_definitions.has(metric_id):
		errors.append("%s가 알 수 없는 지표를 참조합니다: %s" % [context, metric_id])
	if str(condition.get("op", "")) not in ALLOWED_OPERATORS:
		errors.append("%s가 허용되지 않은 연산자를 사용합니다: %s" % [context, str(condition.get("op", ""))])
	if not condition.has("value"):
		errors.append("%s의 비교 값이 없습니다." % context)


static func _compare(left, operator: String, right) -> Dictionary:
	match operator:
		"==":
			return {"ok": true, "value": left == right, "error": ""}
		"!=":
			return {"ok": true, "value": left != right, "error": ""}
		"contains":
			if left is Array or left is Dictionary or left is String:
				return {"ok": true, "value": left.has(right) if not (left is String) else str(left).contains(str(right)), "error": ""}
			return {"ok": false, "value": false, "error": "contains는 배열, 사전, 문자열에만 사용할 수 있습니다."}
		_:
			if not _is_number(left) or not _is_number(right):
				return {"ok": false, "value": false, "error": "%s 비교는 숫자에만 사용할 수 있습니다." % operator}
			match operator:
				">": return {"ok": true, "value": float(left) > float(right), "error": ""}
				">=": return {"ok": true, "value": float(left) >= float(right), "error": ""}
				"<": return {"ok": true, "value": float(left) < float(right), "error": ""}
				"<=": return {"ok": true, "value": float(left) <= float(right), "error": ""}
	return {"ok": false, "value": false, "error": "비교할 수 없습니다."}


static func _is_number(value) -> bool:
	return value is int or value is float
