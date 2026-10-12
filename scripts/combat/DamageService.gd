extends RefCounted
class_name DamageService

static func compute(attacker: Node, defender: Node, multiplier: float = 1.0) -> int:
	var defender_def = defender.effective_def() if defender.has_method("effective_def") else defender.def
	var attacker_atk=attacker.effective_atk() if attacker.has_method("effective_atk") else attacker.atk
	var raw_damage = float(attacker_atk) * multiplier - float(defender_def) * 0.5
	return max(1, int(round(raw_damage)))

