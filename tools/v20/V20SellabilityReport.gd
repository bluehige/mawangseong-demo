extends Node

const SellabilityGate = preload("res://scripts/v20/playtest/V20SellabilityGate.gd")
const DEFAULT_RESULTS_PATH := "res://docs/playtest/v20/RESULTS.json"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := DEFAULT_RESULTS_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--results="):
			path = argument.trim_prefix("--results=")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("V20 sellability results file could not be opened: %s" % path)
		get_tree().quit(1)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	var report := SellabilityGate.evaluate(parsed)
	print(JSON.stringify(report, "\t"))
	get_tree().quit(1 if str(report.get("status", "")) == SellabilityGate.STATUS_INVALID else 0)
