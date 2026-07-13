extends Node

const GameRootScene = preload("res://scenes/game/GameRoot.tscn")
const FRAME_GROUPS := {"idle_down": 2, "move_down": 4, "attack_down": 4, "skill_down": 4, "down": 2}
const MEMORY_IDS := ["toktok_spare_plate", "toktok_polish_day", "toktok_heart_patch"]

var failed := false
var assertion_count := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DataRegistry.load_all()
	_test_character_data()
	_test_art_files()
	await _test_memory_unlocks_and_runtime_vfx()
	print("TOKTOK_PHASE25C_TEST: %s (%d assertions)" % ["FAIL" if failed else "PASS", assertion_count])
	get_tree().quit(1 if failed else 0)


func _test_character_data() -> void:
	var monster: Dictionary = DataRegistry.monster("armored_beetle")
	var character: Dictionary = DataRegistry.characters.get("CHR_TOKTOK", {})
	_expect(str(monster.get("sprite", "")).contains("monster_armored_beetle") and not bool(monster.get("placeholder_art", true)), "톡톡 전용 전투 스프라이트 연결·임시 그림 해제")
	_expect(character.get("portrait", {}).get("variants", {}).size() == 2 and not bool(character.get("placeholder_art", true)), "톡톡 초상화 기본 1종·감정 변형 2종 연결")
	var specializations: Array = monster.get("specialization_ids", [])
	_expect(specializations.size() == 2, "톡톡 전술 특화 2종 유지")
	for specialization_id in specializations:
		_expect(str(DataRegistry.specializations.get(str(specialization_id), {}).get("badge", "")).contains("badge_toktok_"), "%s 전용 배지 연결" % specialization_id)
	for skill_id in monster.get("skills", []):
		_expect(str(DataRegistry.skill(str(skill_id)).get("vfx", "")).contains("fx_armored_beetle_"), "%s 톡톡 전용 효과 연결" % skill_id)
	_expect(monster.get("bond_memory_ids", {}).values() == MEMORY_IDS, "유대 1~3단계가 계획서의 톡톡 기억 3종과 순서대로 연결")
	for index in range(MEMORY_IDS.size()):
		var memory: Dictionary = DataRegistry.memory_entries.get(MEMORY_IDS[index], {})
		_expect(str(memory.get("monster_id", "")) == "armored_beetle" and int(memory.get("bond_rank", 0)) == index + 1 and not bool(memory.get("placeholder", false)), "%s 정식 유대 기억 데이터" % MEMORY_IDS[index])


func _test_art_files() -> void:
	var hashes: Dictionary = {}
	var total_frames := 0
	for animation_name in FRAME_GROUPS.keys():
		for frame_index in range(int(FRAME_GROUPS[animation_name])):
			var path := "res://assets/sprites/monsters/monster_armored_beetle_%s_%02d.png" % [animation_name, frame_index]
			var image := Image.new()
			var error := image.load(ProjectSettings.globalize_path(path))
			_expect(error == OK and image.get_size() == Vector2i(192, 192) and image.get_format() == Image.FORMAT_RGBA8, "%s 192×192 RGBA 형식" % path.get_file())
			if error == OK:
				var alpha_min := 255
				var alpha_max := 0
				for y in range(image.get_height()):
					for x in range(image.get_width()):
						var alpha := image.get_pixel(x, y).a8
						alpha_min = mini(alpha_min, alpha)
						alpha_max = maxi(alpha_max, alpha)
				_expect(alpha_min == 0 and alpha_max == 255, "%s 투명 가장자리와 불투명 본체 공존" % path.get_file())
			hashes[FileAccess.get_sha256(ProjectSettings.globalize_path(path))] = true
			total_frames += 1
	_expect(total_frames == 16 and hashes.size() == 16, "전투 프레임 16장 모두 서로 다른 해시")
	for path in [
		"res://assets/sprites/portraits/update3/portrait_armored_beetle_base.png",
		"res://assets/sprites/portraits/update3/portrait_armored_beetle_happy.png",
		"res://assets/sprites/portraits/update3/portrait_armored_beetle_determined.png",
		"res://assets/ui/specializations/update3/badge_toktok_shell_breaker.png",
		"res://assets/ui/specializations/update3/badge_toktok_castle_mason.png",
		"res://assets/sprites/effects/fx_armored_beetle_carapace_impact_00.png",
		"res://assets/sprites/effects/fx_armored_beetle_patch_shield_00.png",
		"res://assets/sprites/effects/fx_armored_beetle_scrap_rivets_00.png",
		"res://assets/source/imagegen/toktok/SOURCE.md"
	]:
		_expect(FileAccess.file_exists(path), "%s 존재" % path.get_file())


func _test_memory_unlocks_and_runtime_vfx() -> void:
	var game = GameRootScene.instantiate()
	add_child(game)
	await get_tree().process_frame
	game._set_campaign_save_path_for_tests("")
	game.monster_roster["armored_beetle"] = {"bond": 0, "bond_rank": 0, "unlocked_memory_ids": [], "level": 1, "exp": 0}
	for expected_memory_id in MEMORY_IDS:
		var result: Dictionary = game._grant_monster_bond("armored_beetle", 25)
		_expect(str(result.get("unlocked_memory_id", "")) == expected_memory_id, "%s 해당 유대 단계에서 1회 해금" % expected_memory_id)
	var rank_four: Dictionary = game._grant_monster_bond("armored_beetle", 25)
	var unlocked: Array = game.monster_roster["armored_beetle"].get("unlocked_memory_ids", [])
	_expect(str(rank_four.get("unlocked_memory_id", "")) == "" and unlocked == MEMORY_IDS, "추가 유대에도 계획 밖 기억을 만들거나 중복 해금하지 않음")
	var repeated: Dictionary = game._grant_monster_bond("armored_beetle", 0)
	_expect(str(repeated.get("unlocked_memory_id", "")) == "" and game.monster_roster["armored_beetle"].get("unlocked_memory_ids", []).size() == 3, "이미 본 톡톡 기억 반복 방지")
	_expect(game.effect_textures.get("toktok_impact") != null and game.effect_textures.get("toktok_patch") != null and game.effect_textures.get("toktok_scrap") != null, "런타임이 톡톡 효과 3종을 실제 텍스처로 불러옴")
	var toktok = game._create_unit("armored_beetle", DataRegistry.monster("armored_beetle"), Constants.FACTION_MONSTER, "entrance")
	_expect(toktok.sprite.sprite_frames.get_frame_count("idle_down") == 2 and toktok.sprite.sprite_frames.get_frame_count("move_down") == 4 and toktok.sprite.sprite_frames.get_frame_count("attack_down") == 4 and toktok.sprite.sprite_frames.get_frame_count("skill_down") == 4 and toktok.sprite.sprite_frames.get_frame_count("down") == 2, "실제 유닛 애니메이션에 16프레임 전부 로드")
	toktok.queue_free()
	game.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	assertion_count += 1
	if condition:
		print("  [PASS] %s" % message)
		return
	failed = true
	push_error("[ToktokPhase25C] FAIL: %s" % message)
