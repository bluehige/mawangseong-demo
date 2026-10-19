@tool
extends EditorExportPlugin

const BLOCKED_PREFIXES := [
	"res://addons/steam_release_export_filter/",
	"res://assets/source/",
	"res://builds/",
	"res://_mockup/",
	"res://docs/",
	"res://legal/",
	"res://marketing/",
	"res://output/",
	"res://steam/",
	"res://tmp/",
	"res://tools/",
	"res://web_Demo/",
	"res://참고자료/",
	"res://mawang_guideline_pack/",
	"res://mawang_quarterview_tilegrid_docs/",
]

const BLOCKED_FILES := [
	"res://castle_management_ui_reference.png",
	"res://monster_management_ui_reference.png",
	"res://topview_battle_ui_reference.png",
]


func _get_name() -> String:
	return "SteamReleaseExportFilter"


func _export_file(path: String, _type: String, features: PackedStringArray) -> void:
	# Steamworks administration CSVs are not game translations or runtime data.
	# Keep only the JSON catalog and runtime rules required by AchievementService.
	if path.begins_with("res://data/v130r/achievements/") and not path.ends_with(".json"):
		skip(); return
	if path == "res://steam_appid.txt":
		skip(); return
	if path.begins_with("res://addons/godotsteam/") and not features.has("windows"):
		skip(); return
	if not features.has("steam"):
		return
	if BLOCKED_FILES.has(path):
		skip()
		return
	for prefix in BLOCKED_PREFIXES:
		if path.begins_with(prefix):
			skip()
			return
