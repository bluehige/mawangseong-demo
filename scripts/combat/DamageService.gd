extends RefCounted
class_name DamageService

static func compute(attacker: Node, defender: Node, multiplier: float = 1.0) -> int:
	var defender_def = defender.effective_def() if defender.has_method("effective_def") else defender.def
	var raw_damage = float(attacker.atk) * multiplier - float(defender_def) * 0.5
	return max(1, int(round(raw_damage)))

