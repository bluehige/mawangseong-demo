extends Node
## Exercise actual catalog templates after gameplay has substituted values.
var failures: Array[Dictionary] = []
func render(template: String, english: bool) -> String:
	var result := ""
	var offset := 0
	for token in LanguageSettings.english_translation.tokens.search_all(template):
		result += template.substr(offset, token.get_start() - offset).replace("%%", "%")
		var key: String = token.get_string()
		if key.ends_with("s") or key.begins_with("{{"):
			# Adjacent strings are optional suffixes (e.g. " · support Gob").
			if token.get_start() == offset and offset > 0:
				result += " · "
			result += "Gob" if english else "곱"
		else:
			result += key % (7.5 if key.ends_with("f") else 7)
		offset = token.get_end()
	return result + template.substr(offset).replace("%%", "%")
func _ready() -> void:
	LanguageSettings.set_locale("en", false)
	var translation = LanguageSettings.english_translation
	var count := 0
	for template in translation.entries:
		if translation.tokens.search(str(template)) == null: continue
		var source := render(str(template), false)
		var actual := LanguageSettings.ui_text(source)
		count += 1
		if translation.hangul.search(actual.replace("한국어", "")) != null:
			failures.append({"template":template, "source":source, "actual":actual, "expected":render(str(translation.entries[template]), true)})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp/full_english_validation"))
	var file := FileAccess.open("res://tmp/full_english_validation/formatted_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"templates":count,"failures":failures}, "\t"))
	file.close()
	print("UI_ENGLISH_FORMATTED_TEST: %s (%d templates, %d issues)" % ["PASS" if failures.is_empty() else "FAIL", count, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
