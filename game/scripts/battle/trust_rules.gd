class_name TrustRules
extends RefCounted
## Befriending maths. A wild creature shows a mood each turn; gentle actions that match it build a lot of Trust,
## others a little; treats it likes count extra; a good timing press helps. Hurting it when it is already low
## costs Trust, and a fair fight earns a little respect once. At FULL it chooses to join.

const FULL: int = 100
const MATCH_GAIN: int = 30
const MISMATCH_GAIN: int = 10
const SLEEPY_GAIN: int = 4
const LIKED_MULT: float = 1.6
const TIMING_MULT: Dictionary = {"perfect": 1.5, "good": 1.2, "miss": 1.0}
const BEST_MOOD: Dictionary = {"calm": "wary", "play": "playful", "treat": "hungry"}
const SOFT_ON_SLEEPY: String = "calm"
const OVERHURT_RATIO: float = 0.3
const OVERHURT_LOSS: int = 20
const RESPECT_RATIO: float = 0.6
const RESPECT_GAIN: int = 10
const WATCH_TRUST: int = 50
const WATCH_CHANCE: float = 0.4
const DOZE_CHANCE: float = 0.5
const MOODS: Array[String] = ["wary", "playful", "hungry", "sleepy"]


static func roll_mood(species_id: String, rng: RandomNumberGenerator) -> String:
	var weights: Dictionary = Db.species[species_id]["moods"]
	var total: float = 0.0
	for m: String in MOODS:
		total += float(weights.get(m, 0))
	var pick: float = rng.randf() * total
	for m: String in MOODS:
		pick -= float(weights.get(m, 0))
		if pick <= 0.0:
			return m
	return MOODS[0]


## Trust gained by a gentle action ("calm", "play", "treat") given the mood, the press and the treat.
static func gain(action: String, mood: String, species_id: String, grade: String, treat: String = "") -> int:
	var base: int = MISMATCH_GAIN
	if mood == "sleepy":
		base = MATCH_GAIN / 2 if action == SOFT_ON_SLEEPY else SLEEPY_GAIN
	elif BEST_MOOD[action] == mood:
		base = MATCH_GAIN
	var amount: float = base * float(TIMING_MULT[grade]) / float(Db.species[species_id]["shyness"])
	if treat != "" and likes(species_id, treat):
		amount *= LIKED_MULT
	return int(round(amount))


static func likes(species_id: String, treat: String) -> bool:
	return Array(Db.species[species_id]["likes"]).has(treat)


## Trust change when a wild creature is hit: respect once for a fair fight, a loss when it is hurt too much.
static func on_hit(target: Battler, ratio_before: float) -> int:
	var after: float = target.hp_ratio()
	if after <= 0.0:
		return 0
	if ratio_before < OVERHURT_RATIO or after < OVERHURT_RATIO:
		return -OVERHURT_LOSS
	if not target.respected and after <= RESPECT_RATIO:
		target.respected = true
		return RESPECT_GAIN
	return 0


static func add(target: Battler, amount: int) -> void:
	target.trust = clampi(target.trust + amount, 0, FULL)


static func is_won(target: Battler) -> bool:
	return target.trust >= FULL
