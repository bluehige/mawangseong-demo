@tool
extends EditorExportPlugin

const BLOCKED_PREFIXES := [
	"res://addons/steam_release_export_filter/",
	"res://assets/source/",
	"res://docs/",
	"res://legal/",
	"res://marketing/",
	"res://output/",
	"res://steam/",
	"res://stove/",
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
	if not features.has("steam") and not features.has("stove"):
		return
	if BLOCKED_FILES.has(path):
		skip()
		return
	for prefix in BLOCKED_PREFIXES:
		if path.begins_with(prefix):
			skip()
			return
