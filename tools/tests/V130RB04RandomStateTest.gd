extends Node
const Replay = preload("res://tools/tests/V130RB04RandomState.gd")
var checks := 0
var failures: Array = []

func expect(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)

func mixed_draws(count: int) -> void:
	var values := [0,1,2,3,4,5]
	for i in count:
		match i%6:
			0: randi()
			1: randf()
			2: randi_range(-100000,100000)
			3: randf_range(-100.0,100.0)
			4: randfn(0.0,2.0)
			5: values.shuffle(); values.pick_random()

func sequence() -> Array:
	var values: Array = []
	for i in 64: values.append([randi(),randf(),randi_range(-99,99),randfn(0.0,1.0)])
	return values

func _ready() -> void:
	var cases: Array = []
	for seed_value in [130401,130406,130410]:
		for count in [0,17,1000,32000,150000]:
			seed(seed_value); mixed_draws(count)
			var expected := sequence()
			seed(seed_value); mixed_draws(count)
			var state := Replay.capture(seed_value)
			expect(state.ok,"global RNG state located")
			if not state.ok: continue
			var actual := sequence()
			expect(actual==expected,"capture preserves mixed native RNG stream")
			var serialized: Dictionary = JSON.parse_string(JSON.stringify(state))
			expect(Replay.restore(serialized),"serialized RNG fingerprint restores")
			expect(sequence()==expected,"restore reproduces all subsequent native draws")
			var later := Replay.capture(seed_value,int(state.draws))
			expect(later.ok and later.draws>state.draws,"incremental capture advances monotonically")
			cases.append({"seed":seed_value,"mixed_calls":count,"draws":state.draws})
	DirAccess.make_dir_recursive_absolute("res://tmp/v130r_b04")
	var file := FileAccess.open("res://tmp/v130r_b04/random_state_checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":cases},"\t")); file.close()
	print("B04_RANDOM_STATE: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)")
	get_tree().quit(0 if failures.is_empty() else 1)
