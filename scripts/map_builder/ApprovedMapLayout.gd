extends RefCounted
## Approved visual layout only. Campaign topology and save schema stay owned by
## the existing services until the placement/combat integration stages.
const DATA := "res://data/maps/v130r_step1/layout.json"
const ART := "res://assets/maps/v130r_step1/"
const TILE := Vector2(128, 64)
const DEFAULT_SCALE := 0.75 # 96x48 displayed pixels; 2x the design's 48x24 overview.
const FULL_SCALE := 0.48 # The approved mockup's exact comparison camera.

static func enabled() -> bool:
	return bool(ProjectSettings.get_setting("debug/approved_map_step1", false)) or OS.get_cmdline_user_args().has("--approved-map-step1")

static func read(grade: String = "E") -> Dictionary:
	var path := "res://data/maps/v130r_step5/layout_f.json" if grade=="F" else DATA
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if grade=="F" and data is Dictionary:
		var base: Dictionary = read()
		base.merge(data,true)
		return base
	return data if data is Dictionary else {}

static func project(cell: Vector2, width: int = 32) -> Vector2:
	var iso := Vector2(cell.y, float(width)-cell.x)
	return Vector2((iso.x-iso.y)*TILE.x/2.0, (iso.x+iso.y)*TILE.y/2.0)+Vector2(2304,512)

static func unproject(point: Vector2, width: int = 32) -> Vector2:
	var local := point-Vector2(2304,512)
	var iso := Vector2(local.x/TILE.x+local.y/TILE.y, local.y/TILE.y-local.x/TILE.x)
	return Vector2(float(width)-iso.y, iso.x)

static func cells(data: Dictionary, chars: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(data.rows.size()):
		for x in range(data.rows[y].length()):
			if chars.contains(data.rows[y][x]): found.append(Vector2i(x,y))
	return found
