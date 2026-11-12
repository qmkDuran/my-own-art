class_name OpponentTrainer
extends RefCounted
## The opposing trainer in a 3v3 arena battle (tamer.json "battle.trainers"): three creatures sent one at a time.
## It sends the creature with the advantage over yours, sends the next when one falls, and (by tier) swaps out at low
## life or into a counter. Its swaps follow your rules (a gauge segment, the swap cooldown) and it has no items in
## battle, as you have none. It stands outside the arena like you, and is never hurt.

var data: Dictionary
var tier_id: String
var team: Array[CreatureRecord] = []
var active: Creature
var stand_at: Vector2                   ## where it stands (its calls show there)
var _swapped: Dictionary = {}
var _swap_ready_at: float = 0.0


func setup(trainer_data: Dictionary, level: int, tier: String) -> OpponentTrainer:
	data = trainer_data
	tier_id = tier
	for id: String in trainer_data["team"]:
		team.append(CreatureRecord.make(id, level, false))
	return self


func display_name() -> String:
	return String(data["name"])


func T() -> Dictionary:
	return TamerData.rule("ai_tiers." + tier_id)


func has_more() -> bool:
	return team.any(func(r: CreatureRecord) -> bool: return r.life > 0.0 and (active == null or not is_instance_valid(active) or r != active.rec))


func remaining() -> int:
	return team.filter(func(r: CreatureRecord) -> bool: return r.life > 0.0).size()


## The standing creature best against yours: one with the element advantage first, then the healthiest.
func best_against(yours: Creature) -> CreatureRecord:
	var best: CreatureRecord = null
	var best_score: float = -INF
	for r: CreatureRecord in team:
		if r.life <= 0.0 or (active != null and is_instance_valid(active) and r == active.rec):
			continue
		var score: float = r.life_frac()
		if yours != null and TamerData.advantage(r.element(), yours.element_id()):
			score += 1.0
		if score > best_score:
			best_score = score
			best = r
	return best


## Between blows: a swap (out at low life, or into a counter on Hard), if its gauge can pay and the swap cooldown
## has run out. Returns the record to swap in, or null.
func decide(yours: Creature) -> CreatureRecord:
	if active == null or not is_instance_valid(active) or active.fainted_now or _swapped.has(active.rec):
		return null
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < _swap_ready_at or active.gauge + 0.001 < float(TamerData.rule("combat.gauge.swap_cost")):
		return null
	var life: float = active.rec.life_frac()
	var low: bool = life < float(T()["swap_below"])
	var counter: bool = bool(T()["counter_swap"]) and yours != null and TamerData.advantage(yours.element_id(), active.element_id())
	if (low or counter) and best_against(yours) != null:
		_swapped[active.rec] = true
		_swap_ready_at = now + float(TamerData.rule("combat.swap_cooldown"))
		return best_against(yours)
	return null
