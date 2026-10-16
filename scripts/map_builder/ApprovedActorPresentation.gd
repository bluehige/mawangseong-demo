extends RefCounted
## Visible body size in map-world pixels, shared by placement and live combat.
const BODY_SIZE := Vector2(76,88)
const BOSS_MULTIPLIER := 1.25
const BOSSES := ["official_hero_leon","selen_trainee_paladin"]
const Art = preload("res://scripts/ui/UIUXActorArt.gd")

static func multiplier(id: String) -> float:
	return BOSS_MULTIPLIER if id in BOSSES else 1.0

static func body_scale(bounds: Rect2, id: String = "") -> float:
	return minf(BODY_SIZE.x/maxf(1,bounds.size.x),BODY_SIZE.y/maxf(1,bounds.size.y))*multiplier(id)

static func depth(point: Vector2) -> int:
	return clampi(roundi(point.y),1,3500)
