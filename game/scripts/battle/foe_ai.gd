class_name FoeAi
extends RefCounted
## How the other side acts: trusting wild creatures may just watch you, sleepy ones doze; otherwise pick a move,
## favouring strong matches, healing when low and boosting early.

const LOW_HP: float = 0.35
const STRONG_WEIGHT: float = 3.0
const BUFF_WEIGHT: float = 1.2
const HEAL_WEIGHT: float = 4.0


static func choose(foe: Battler, target: Battler, rng: RandomNumberGenerator) -> Dictionary:
	if foe.wild and foe.trust >= TrustRules.WATCH_TRUST and rng.randf() < TrustRules.WATCH_CHANCE:
		return {"type": "watch"}
	if foe.wild and foe.mood == "sleepy" and rng.randf() < TrustRules.DOZE_CHANCE:
		return {"type": "doze"}
	return {"type": "move", "move": _pick_move(foe, target, rng)}


static func _pick_move(foe: Battler, target: Battler, rng: RandomNumberGenerator) -> String:
	var weights: Array[float] = []
	var total: float = 0.0
	for m: String in foe.creature.moves:
		var w: float = _weight(foe, target, m)
		weights.append(w)
		total += w
	var pick: float = rng.randf() * total
	for i: int in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return foe.creature.moves[i]
	return foe.creature.moves[0]


static func _weight(foe: Battler, target: Battler, move_id: String) -> float:
	var move: Dictionary = Db.move(move_id)
	match String(move["kind"]):
		"heal":
			return HEAL_WEIGHT if foe.hp_ratio() < LOW_HP else 0.0
		"buff":
			return BUFF_WEIGHT if foe.stage(String(move["stat"])) < 1 else 0.1
		"debuff":
			return BUFF_WEIGHT if target.stage(String(move["stat"])) > -1 else 0.1
	var mult: float = BattleRules.element_mult(String(move["element"]), target.creature)
	return float(move["power"]) / 40.0 * (STRONG_WEIGHT if mult > 1.0 else (0.5 if mult < 1.0 else 1.0))
