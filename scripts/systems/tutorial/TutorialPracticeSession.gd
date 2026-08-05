extends RefCounted
class_name TutorialPracticeSession

const SUPPORTED_STEP_IDS := [
	"TUT_010_NAME",
	"TUT_020_THRONE_HP",
	"TUT_030_SELECT_SLIME",
	"TUT_040_DEPLOY_SLIME",
	"TUT_090_RESULT_GROWTH",
	"TUT_110_TRAP_CORRIDOR",
	"TUT_120_TRAP_LURE",
	"TUT_130_GOBLIN_CONTROL",
	"TUT_210_RECOVERY_NEST",
	"TUT_220_RETREAT_LINE",
	"TUT_230_IMP_FIREBALL",
	"TUT_240_BOSS_HP"
]
const OBSERVATION_STEP_IDS := [
	"TUT_130_GOBLIN_CONTROL",
	"TUT_230_IMP_FIREBALL",
	"TUT_240_BOSS_HP"
]

var steps: Array = []
var current_index := 0
var completed := false
var guidance_level := "full"


func setup(source_steps: Array, requested_guidance_level: String) -> void:
	steps.clear()
	current_index = 0
	completed = false
	guidance_level = requested_guidance_level
	if guidance_level == "off":
		return
	for value in source_steps:
		if not (value is Dictionary):
			continue
		var step: Dictionary = value
		var step_id := str(step.get("id", ""))
		if step_id not in SUPPORTED_STEP_IDS:
			continue
		if guidance_level == "core" and step_id in OBSERVATION_STEP_IDS:
			continue
		steps.append(step.duplicate(true))


func current_step() -> Dictionary:
	if completed or current_index < 0 or current_index >= steps.size():
		return {}
	return steps[current_index]


func current_step_id() -> String:
	return str(current_step().get("id", ""))


func step_count() -> int:
	return steps.size()


func can_go_previous() -> bool:
	return not completed and current_index > 0


func is_last_step() -> bool:
	return not completed and not steps.is_empty() and current_index == steps.size() - 1


func advance() -> void:
	if completed or steps.is_empty():
		return
	if is_last_step():
		completed = true
		return
	current_index += 1


func go_previous() -> void:
	if can_go_previous():
		current_index -= 1


func restart() -> void:
	current_index = 0
	completed = false


func step_ids() -> Array[String]:
	var result: Array[String] = []
	for step in steps:
		result.append(str(step.get("id", "")))
	return result
