extends RefCounted
class_name DamageService

static func compute(attacker: Node, defender: Node, multiplier: float = 1.0) -> int:
	var raw_damage = float(attacker.atk) * multiplier - float(defender.def) * 0.5
	return max(1, int(round(raw_damage)))

