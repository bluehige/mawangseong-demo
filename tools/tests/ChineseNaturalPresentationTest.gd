extends Node

const Summary = preload("res://scripts/ui/DefensePreparationSummary.gd")
const Effects = preload("res://scripts/ui/FacilityEffectText.gd")
var checks := 0
var failures: Array[String] = []

class FakeGraph extends RefCounted:
	var layout := {"combat_topology":{"defense_zones":[{"zone_id":"front","room_ids":["entrance"],"anchor_room_id":"entrance"},{"zone_id":"rear","room_ids":["throne"],"anchor_room_id":"throne"}]}}
	func path_between(_from: String, _to: String) -> Array: return ["entrance","throne"]

class FakeGame extends Node:
	var graph := FakeGraph.new()
	var maze_route_forecasts := [{"id":"main","spawn_room_id":"entrance","target_room_id":"throne"}]
	var maze_route_id := "main"
	var maze_deployments: Dictionary = {}
	var monster_roster: Dictionary = {}
	var names: Dictionary = {}
	func _maze_zone_name(id: String) -> String: return "정문 가시 길목" if id == "front" else "왕좌 앞 회랑"
	func _monster_companion_name(id: String) -> String: return str(names[id])

func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message); push_error(message)

func clean(source: String, message: String) -> void:
	var hangul := RegEx.new()
	hangul.compile("[가-힣]|Lv\\." if LanguageSettings.locale == "zh_CN" else "[가-힣]")
	expect(hangul.search(source) == null,message+": "+source)

func _ready() -> void: call_deferred("run")

func run() -> void:
	var user_path := ProjectSettings.globalize_path("user://")
	expect(user_path.contains("zh_cn_natural_fix_20261007") or user_path.contains("zh_cn_release_final_20261007"),"Isolated test profile required")
	if not failures.is_empty(): get_tree().quit(1); return
	var previous := LanguageSettings.locale
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/tests/fixtures/chinese_natural_presentation_baseline.json"))
	expect(baseline.get("baseline_head","") == "b06be967aa763199ac631729eb65cacbe9489c26","Captured ko/en baseline provenance")
	var sample := FakeGame.new()
	var names := ["곱","핀","푸딩","로로","바티","니아"]
	for level in [1,2,11,99]:
		for count in [0,1,2,3,6]:
			sample.maze_deployments.clear(); sample.monster_roster.clear(); sample.names.clear()
			for index in range(count):
				var id := "m%d" % index
				sample.maze_deployments[id] = {"defense_zone_id":"front" if index % 2 == 0 else "rear"}
				sample.monster_roster[id] = {"level":level}
				sample.names[id] = names[index]
			for locale in ["ko","en","zh_CN"]:
				LanguageSettings.set_locale(locale,false)
				var actual: Dictionary = Summary.selected_route(sample)
				expect(actual.count == count,"Placement count stays semantic")
				if locale == "ko":
					# JSON fixtures do not preserve typed arrays or integer Variant types.
					var serialized_actual: Variant = JSON.parse_string(JSON.stringify(actual))
					expect(serialized_actual == baseline.summary["%s/%d/%d" % [locale,level,count]],"Korean summary bytes and metadata unchanged")
				else:
					clean(LanguageSettings.ui_text(actual.text),"Joined summary count%d level%d" % [count,level])
					for member in actual.members: expect(str(member).contains("%d级" % level if locale == "zh_CN" else "Lv.%d" % level),"Actual level preserved")
					if locale == "en" and count > 2: expect(LanguageSettings.ui_text(actual.text).contains("and %d more" % (count-2)),"English remainder reads naturally for one or several companions")
	var catalog := JSON.parse_string(FileAccess.get_file_as_string("res://data/v122/facility_zone_effects.json")) as Dictionary
	var topology := {"defense_zones":[{"zone_id":"front"}],"facility_slots":[{"linked_zone_ids":["front"]}]}
	for scale in [0.95,1.0,1.15,1.4,1.7]:
		for role in catalog.facilities:
			var definition := {"effect_summary":"체력 350 / 몬스터 2명 배치. 시험"}
			if role == "treasure": definition.effect_summary = "체력 350 / 몬스터 2명 배치. 도둑은 이 방을 목표로 이동합니다. 5초 방치되면 금화 100을 잃습니다."
			for locale in ["ko","en","zh_CN"]:
				LanguageSettings.set_locale(locale,false)
				var value: String = Effects.for_topology(definition,str(role),topology,scale)
				if locale == "ko": expect(value == baseline.effects["%s/%s/%.2f" % [locale,role,scale]],"Korean facility fragments unchanged")
				else:
					var body := value.substr(value.find(". ")+2) if value.begins_with("체력 ") and value.contains(". ") else value
					clean(LanguageSettings.ui_text(body),"Facility role %s/scale%s" % [role,scale])
					if role == "recovery": expect(body.contains("%.1f" % (8.0*scale)),"Healing numeric scale retained")
	LanguageSettings.set_locale("en",false)
	for lane in ["정문","측문","연결"]:
		for suffix in [" 진입 복도"," 안쪽 복도"," 합류 복도"," 통로"]:
			clean(LanguageSettings.ui_text(lane+suffix+" → 통로"),"English generated/result corridor")
	for seconds in [1,5,12]:
		for gold in [5,100,999]:
			var warning := LanguageSettings.ui_text("도둑은 이 방을 목표로 이동합니다. %d초 방치되면 금화 %d을 잃습니다." % [seconds,gold])
			clean(warning,"English treasure warning")
			expect(warning.contains("%d seconds" % seconds) and warning.contains("%d gold" % gold),"English warning preserves independent numbers")
	LanguageSettings.set_locale("zh_CN",false)
	for lane in ["정문","측문","연결"]:
		for suffix in [" 진입 복도"," 안쪽 복도"," 합류 복도"," 통로"]:
			clean(LanguageSettings.ui_text(lane+suffix),"Generated corridor")
			clean(LanguageSettings.ui_text(lane+suffix+" → 통로"),"Result joined corridor")
	for seconds in [1,5,12]:
		for gold in [5,100,999]:
			var translated := LanguageSettings.ui_text("도둑은 이 방을 목표로 이동합니다. %d초 방치되면 금화 %d을 잃습니다." % [seconds,gold])
			clean(translated,"Treasure warning")
			expect(translated.contains("%d秒" % seconds) and translated.contains("%d金币" % gold),"Warning retains independent numbers")
	for attack in [5,10,23]:
		for defense in [3,8,17]:
			clean(LanguageSettings.ui_text("이 방에 배치된 아군은 인접 방 방어 중에도 공격 +%d%%, 받는 피해 -%d%%." % [attack,defense]),"Legacy barracks tail")
	for value in [3.0,8.0,9.2,13.6]:
		clean(LanguageSettings.ui_text("내부 초당 %.1f, 배치 아군이 인접 방에서 싸울 때 초당 %.1f 회복합니다." % [value,value/2.0]),"Legacy recovery tail")
	sample.free()
	LanguageSettings.set_locale(previous,false)
	print("CHINESE_NATURAL_PRESENTATION_TEST: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAIL",checks])
	get_tree().quit(0 if failures.is_empty() else 1)
