class_name Update4CatalogLoader
extends RefCounted

const ROOT := "res://data/regular_version/update4"

const CATALOG_FILES := {
	"campaign_modes": "campaign_modes.json",
	"council_campaign_days": "council_campaign_days.json",
	"regions": "regions.json",
	"region_day_overlays": "region_day_overlays.json",
	"region_events": "region_events.json",
	"council_agendas": "council_agendas.json",
	"rival_lords": "rival_lords.json",
	"rival_events": "rival_events.json",
	"outpost_types": "outpost_types.json",
	"outpost_encounters": "outpost_encounters.json",
	"upper_floor_layouts": "upper_floor_layouts.json",
	"crown_evolutions": "crown_evolutions.json",
	"council_wave_templates": "council_wave_templates.json",
	"council_endings": "council_endings.json",
	"council_balance": "council_balance.json",
	"localization_ko": "localization_ko.json",
	"upper_floor_modules": "upper_floor_modules.json",
	"monsters": "monsters.json",
	"enemies": "enemies.json",
	"characters": "characters.json",
	"skills": "skills.json",
	"outpost_events": "outpost_events.json",
	"crown_events": "crown_events.json",
	"bond_events": "bond_events.json",
	"monster_codex": "monster_codex.json",
	"rival_letters": "rival_letters.json",
	"run_metric_definitions": "run_metric_definitions.json",
	"asset_manifest": "asset_manifest.json"
}


static func load_all(root_path: String = ROOT) -> Dictionary:
	var catalogs := {}
	var errors: Array[String] = []
	for catalog_name_value in CATALOG_FILES.keys():
		var catalog_name := str(catalog_name_value)
		var path := "%s/%s" % [root_path.trim_suffix("/"), CATALOG_FILES[catalog_name]]
		var loaded := _load_dictionary(path)
		if not bool(loaded.get("ok", false)):
			errors.append("%s: %s" % [catalog_name, loaded.get("error", "알 수 없는 로드 오류")])
			catalogs[catalog_name] = {}
			continue
		catalogs[catalog_name] = loaded.get("value", {})
	return {
		"ok": errors.is_empty(),
		"catalogs": catalogs,
		"errors": errors
	}


static func _load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "파일이 없습니다: %s" % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "파일을 열 수 없습니다: %s" % path}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		return {"ok": false, "error": "JSON 파싱 실패: %s" % path}
	if not (parsed is Dictionary):
		return {"ok": false, "error": "최상위 값은 Dictionary여야 합니다: %s" % path}
	return {"ok": true, "value": parsed}
