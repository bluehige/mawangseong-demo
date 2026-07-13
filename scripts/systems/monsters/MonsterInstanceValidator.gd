extends RefCounted
class_name MonsterInstanceValidator


static func validate_catalog(instances: Dictionary, species: Dictionary, characters: Dictionary, skills: Dictionary, evolutions: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for instance_id_value in instances.keys():
		var instance_id := str(instance_id_value)
		var value = instances.get(instance_id_value)
		if not (value is Dictionary):
			errors.append("몬스터 개체 %s의 자료가 사전 형식이 아닙니다." % instance_id)
			continue
		var instance: Dictionary = value
		if instance_id == "" or str(instance.get("instance_id", "")) != instance_id:
			errors.append("몬스터 개체 키와 instance_id가 일치하지 않습니다: %s" % instance_id)
		var species_id := str(instance.get("species_id", ""))
		if species_id == "" or not species.has(species_id):
			errors.append("몬스터 개체 %s의 species_id를 찾을 수 없습니다: %s" % [instance_id, species_id])
		var character_id := str(instance.get("character_id", ""))
		if character_id != "" and not characters.has(character_id):
			errors.append("몬스터 개체 %s의 character_id를 찾을 수 없습니다: %s" % [instance_id, character_id])
		if str(instance.get("display_name", "")).strip_edges() == "":
			errors.append("몬스터 개체 %s의 표시 이름이 비어 있습니다." % instance_id)
		for numeric_key in ["level", "exp", "bond", "bond_rank"]:
			if not _is_number(instance.get(numeric_key)):
				errors.append("몬스터 개체 %s의 %s 값이 숫자가 아닙니다." % [instance_id, numeric_key])
		if _is_number(instance.get("level")) and int(instance.get("level")) < 1:
			errors.append("몬스터 개체 %s의 레벨은 1 이상이어야 합니다." % instance_id)
		if _is_number(instance.get("bond")) and (float(instance.get("bond")) < 0.0 or float(instance.get("bond")) > 100.0):
			errors.append("몬스터 개체 %s의 유대는 0~100이어야 합니다." % instance_id)
		for array_key in ["equipped_skill_ids", "unlocked_memory_ids"]:
			if not (instance.get(array_key) is Array):
				errors.append("몬스터 개체 %s의 %s 값이 배열이 아닙니다." % [instance_id, array_key])
		for skill_id_value in instance.get("equipped_skill_ids", []):
			var skill_id := str(skill_id_value)
			if skill_id == "" or not skills.has(skill_id):
				errors.append("몬스터 개체 %s의 장착 스킬을 찾을 수 없습니다: %s" % [instance_id, skill_id])
		var evolution_id := str(instance.get("evolution_id", ""))
		if evolution_id != "":
			if not evolutions.has(evolution_id):
				errors.append("몬스터 개체 %s의 진화를 찾을 수 없습니다: %s" % [instance_id, evolution_id])
			elif species_id != str(evolutions.get(evolution_id, {}).get("monster_id", "")):
				errors.append("몬스터 개체 %s의 종족과 진화 종족이 일치하지 않습니다." % instance_id)
	return errors


static func _is_number(value) -> bool:
	return value is int or value is float
