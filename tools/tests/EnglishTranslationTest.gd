extends Node

const English = preload("res://scripts/core/EnglishTranslation.gd")
var failures: Array[String] = []
var checks := 0

func expect(actual: Variant, expected: Variant, label: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s: expected <%s>, got <%s>" % [label, expected, actual])

func _ready() -> void:
	var translation := English.new()
	translation.configure({"마왕성": "Demon Castle", "왕좌": "Throne", "곱": "Gob", "방어 +%d": "DEF +%d", "속도 %.1f%%": "Speed %.1f%%", "DAY %02d · %s 준비": "DAY %02d · Prepare %s", "{{hero}}와 {{room}}": "{{room}} and {{hero}}", "이름: %s": "Name: %s"})
	expect(translation.translate_text("마왕성"), "Demon Castle", "Exact text")
	expect(translation.translate_text("DAY 03 · 왕좌 준비"), "DAY 03 · Prepare Throne", "Formatted number and nested name")
	expect(translation.translate_text("방어 +10"), "DEF +10", "Literal plus and number")
	expect(translation.translate_text("속도 7.5%"), "Speed 7.5%", "Decimal and escaped percent")
	expect(translation.translate_text("곱와 왕좌"), "Throne and Gob", "Named placeholders can change order")
	expect(translation.translate_text("왕좌\n방어 +10"), "Throne\nDEF +10", "Composed paragraphs")
	expect(translation.translate_text("미등록 문자열"), "미등록 문자열", "Unknown source remains intact")
	translation.protected_name = "곱"
	translation.cache.clear()
	expect(translation.translate_text("이름: 곱"), "Name: 곱", "User name is preserved")
	var old_locale := TranslationServer.get_locale()
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("en")
	var label := Label.new()
	label.text = "마왕성"
	add_child(label)
	expect(label.tr(label.text), "Demon Castle", "Native Control translation")
	expect(label.text, "마왕성", "Presentation does not mutate model source")
	expect(LanguageSettings.english_translation.translate_text("—  5개 지역 중 3개 선택"), "—  5 Regions: Choose 3", "Specific choice text wins over generic selection suffix")
	expect(LanguageSettings.english_translation.translate_text("• 철종 협곡  Lv.0"), "• Ironbell Gorge  Lv.0", "Chronicle mastery name and level")
	expect(LanguageSettings.english_translation.translate_text("마왕성 1/4 · 신생 마굴 | 구역 6 · 시설 Lv.2"), "Demon Castle 1/4 · New Demon Den | 6 Zones · Facilities Lv.2", "Joined castle progression notice")
	expect(LanguageSettings.english_translation.translate_text("현재 방어 편성 대비 · 왕국 조사관 1→0 / 첫 등장 +4.0초"), "Compared to the current defense lineup · Kingdom Investigator 1→0 / First arrival +4.0s", "Raid modifiers preserve signed timing")
	expect(LanguageSettings.english_translation.translate_text("• 일일 식량 유지비 +2\n• 직접·지속 회복량 -8%\n• 파동의 보스 피해는 6"), "• Daily Food Upkeep +2\n• Direct/Over-Time Healing -8%\n• Pulse damage to bosses is 6", "All three heart modifier bullets")
	TranslationServer.set_locale("ko")
	expect(label.tr(label.text), "마왕성", "Korean mode remains intact")
	TranslationServer.remove_translation(translation)
	TranslationServer.set_locale(old_locale)
	for failure in failures: push_error(failure)
	print("ENGLISH_TRANSLATION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	get_tree().quit(0 if failures.is_empty() else 1)
