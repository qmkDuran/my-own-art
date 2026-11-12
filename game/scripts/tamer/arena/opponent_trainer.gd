class_name OpponentTrainer
extends RefCounted
## The opposing trainer in a 3v3 arena battle (tamer.json "battle.trainers"): three creatures sent one at a time.
## It sends the creature with the advantage over yours, sends the next when one falls, and (by tier) swaps out at low
## life or into a counter, and uses a heal once. It stands outside the arena like you, and is never hurt.

const ITEM_BELOW: float = 0.3

var data: Dictionary
var tier_id: String
var team: Array[CreatureRecord] = []
var active: Creature
var _swapped: Dictionary = {}
var _item_used: bool = false


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


## Between blows: the heal once when low, or a swap (out at low life, or into a counter on Hard). Returns the
## record to swap in, or null.
func decide(yours: Creature) -> CreatureRecord:
	if active == null or not is_instance_valid(active) or active.fainted_now or _swapped.has(active.rec):
		return null
	var life: float = active.rec.life_frac()
	if not _item_used and life < ITEM_BELOW:
		_item_used = true
		active.rec.heal(0.4)
		TamerFx.word(active.global_position, "%s used a Honeyberry!" % display_name(), Pal.c("leaf_lt"))
		return null
	var low: bool = life < float(T()["swap_below"])
	var counter: bool = bool(T()["counter_swap"]) and yours != null and TamerData.advantage(yours.element_id(), active.element_id())
	if (low or counter) and best_against(yours) != null:
		_swapped[active.rec] = true
		return best_against(yours)
	return null
