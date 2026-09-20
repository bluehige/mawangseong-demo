extends Translation
## Translates presentation strings without changing gameplay data or save identifiers.
## Formatted labels are matched against their original printf/template strings.

var entries: Dictionary = {}
var patterns: Array[Dictionary] = []
var cache: Dictionary = {}
var protected_name := ""
var hangul := RegEx.new()
var tokens := RegEx.new()

func configure(values: Dictionary) -> void:
	locale = "en"
	entries = values.duplicate()
	# A number of UI builders append values to a translated label fragment.
	for source in values.keys():
		var fragment := str(source)
		if fragment.strip_edges() != "" and not entries.has(fragment.strip_edges()):
			entries[fragment.strip_edges()] = str(values[source]).strip_edges()
		if fragment.ends_with(" ") and fragment.strip_edges() != "" and not fragment.contains("%"):
			entries[fragment + "%s"] = str(values[source]) + "%s"
		var heading := fragment.strip_edges()
		if heading.begins_with("[") and heading.ends_with("]"):
			entries[heading.trim_prefix("[").trim_suffix("]")] = str(values[source]).strip_edges().trim_prefix("[").trim_suffix("]")
	hangul.compile("[가-힣]")
	tokens.compile("%[-+0#]*[0-9]*(?:\\.[0-9]+)?[sdf]|\\{\\{[a-zA-Z_]+\\}\\}")
	patterns.clear()
	cache.clear()
	for source in entries:
		var matches := tokens.search_all(str(source))
		if matches.is_empty():
			continue
		var expression := "(?s)^"
		var offset := 0
		var anchors: Array[String] = []
		var keys: Array[String] = []
		for token in matches:
			var literal: String = str(source).substr(offset, token.get_start() - offset).replace("%%", "%")
			anchors.append(literal)
			expression += _escape(literal)
			var key := token.get_string()
			keys.append(key)
			expression += "([+-]?[0-9]+(?:\\.[0-9]+)?)" if key.ends_with("d") or key.ends_with("f") else "(.*?)"
			offset = token.get_end()
		var tail: String = str(source).substr(offset).replace("%%", "%")
		anchors.append(tail)
		expression += _escape(tail) + "$"
		anchors.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
		var matcher := RegEx.new()
		if matcher.compile(expression) == OK:
			patterns.append({"matcher": matcher, "anchor": anchors[0], "target": str(entries[source]), "keys": keys, "weight": str(source).length() - matches.size() * 2})
	patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.weight > b.weight)

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	# Godot's default fallback locale is English; never apply it in Korean mode.
	if not TranslationServer.get_locale().begins_with("en"):
		return &""
	var translated := translate_text(str(src_message))
	return StringName(translated) if translated != str(src_message) else &""

func translate_text(source: String, depth: int = 0) -> String:
	if source == "" or source == protected_name or hangul.search(source) == null:
		return source
	if entries.has(source):
		return str(entries[source])
	if cache.has(source):
		return str(cache[source])
	if depth >= 10:
		return source
	var result := source
	var trimmed := source.strip_edges()
	if trimmed != source:
		var translated := translate_text(trimmed, depth + 1)
		if translated != trimmed and hangul.search(translated) == null:
			return source.substr(0, source.find(trimmed)) + translated + source.substr(source.find(trimmed) + trimmed.length())
	for pattern in patterns:
		if not source.contains(pattern.anchor):
			continue
		var matched: RegExMatch = pattern.matcher.search(source)
		if matched == null:
			continue
		var values: Array[String] = []
		for index in range(1, matched.get_group_count() + 1):
			values.append(translate_text(matched.get_string(index), depth + 1))
		var candidate := _substitute(pattern.target, pattern.keys, values)
		if hangul.search_all(candidate).size() < hangul.search_all(result).size():
			result = candidate
		if hangul.search(result) == null:
			break
	# A broad suffix template can consume a whole joined paragraph. Prefer a
	# structural split when it resolves more of the original Korean text.
	if hangul.search(result) != null:
		var remaining := hangul.search_all(result).size()
		for separator in ["\n", "  ·  ", "  /  ", " · ", " / ", " → ", ": ", ", ", " | ", " + "]:
			if not source.contains(separator):
				continue
			var parts := source.split(separator)
			for index in range(parts.size()):
				parts[index] = translate_text(parts[index], depth + 1)
			var candidate: String = separator.join(parts)
			var count := hangul.search_all(candidate).size()
			if count < remaining:
				result = candidate
				remaining = count
			if remaining == 0: break
	# Bound the cache: battle timers and resource counters can produce many values.
	if cache.size() >= 8192:
		cache.clear()
	# Never let a depth-limited, partial nested match poison later lookups.
	if hangul.search(result) == null or depth == 0:
		cache[source] = result
	return result

func _substitute(target: String, keys: Array[String], values: Array[String]) -> String:
	var result := ""
	var offset := 0
	var index := 0
	for token in tokens.search_all(target):
		result += target.substr(offset, token.get_start() - offset).replace("%%", "%")
		var value_index := keys.find(token.get_string()) if token.get_string().begins_with("{{") else index
		result += values[value_index] if value_index >= 0 and value_index < values.size() else token.get_string()
		offset = token.get_end()
		index += 1
	return result + target.substr(offset).replace("%%", "%")

func _escape(value: String) -> String:
	var result := ""
	for character in value:
		if character in "\\.^$|?*+()[]{}":
			result += "\\"
		result += character
	return result
