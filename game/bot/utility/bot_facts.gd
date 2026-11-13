class_name BotFacts
## Gathers the facts the bot's utility scoring looks at, all from its own senses, memory, body and equipped moves
## (never from the player's hidden state): distance and line of sight to the player's last known spot, life (its own,
## and the player's as last seen), which of its moves are ready and in range, being shot at, cover and ambush spots,
## height, soft soil / climbable trees / ledges / suspicious grass nearby, and the player's learned habits.

## Time-since values are capped so curves get a finite number.
const INF_SECONDS: float = 99.0
const ROLES: Array[String] = ["melee", "ranged", "area", "buff", "debuff", "defend", "sense", "leap", "burrow",
	"climb"]


static func gather(brain: BotBrain) -> Dictionary:
	var bot: Creature = brain.bot
	var senses: Perception = brain.senses
	var clue: Vector3 = senses.last_known_position
	var distance: float = bot.global_position.distance_to(clue)
	var facts: Dictionary = {
		"sees": _flag(senses.sees_target), "has_lead": _flag(senses.has_lead), "distance": distance,
		"since_seen": minf(senses.time_since_seen, INF_SECONDS), "own_life": bot.health.fraction(),
		"enemy_life": senses.target_life_seen, "under_fire": _flag(_under_fire(brain)),
		"clear_shot": _flag(senses.sees_target and Sight.clear(bot.get_world_3d(), bot.mouth_position(),
				clue + Vector3.UP * Tuning.f("perception", "chest_height"))),
		"target_facing_me": _flag(senses.target_facing_me()),
		"target_approaching": _flag(senses.has_lead and senses.target_approaching()),
		"target_winding_up": _flag(senses.target_winding_up()),
		"height_advantage": bot.global_position.y - clue.y,
		"cover_ready": _flag(brain.state_name == "cover" or brain.since_cover >= Tuning.f("bot", "cover_cooldown")),
		"retreat_ready": _flag(brain.state_name == "retreat"
				or brain.since_retreat >= Tuning.f("bot", "retreat_cooldown")),
		"punish_window": _punish_window(brain),
		"buffed": _flag(bot.effects.has("damage_out") or bot.effects.has("speed")),
	}
	for role: String in ROLES:
		facts[role + "_ready"] = _flag(_move_ready(bot, role, distance))
	facts["fire_ready"] = _flag(brain.fire_move() != null and brain.fire_move().is_ready())
	_add_terrain_facts(brain, facts)
	_add_habit_facts(brain, facts)
	facts["cover_quality"] = _quality(brain, "cover", bot.global_position) if facts["under_fire"] > 0.0 else 0.0
	var lurking: bool = senses.has_lead and not senses.sees_target
	facts["ambush_quality"] = _quality(brain, "ambush", brain.predicted_target()) if lurking else 0.0
	return facts


static func _add_terrain_facts(brain: BotBrain, facts: Dictionary) -> void:
	var woods: Woods = brain.woods
	var guess: Vector3 = brain.predicted_target()
	var reach: float = Tuning.ai_f("tactics", "near_feature_reach")
	facts["soft_ground_near"] = _flag(woods.soft_spot_near(guess, reach) != Vector3.INF)
	facts["climb_tree_near"] = _flag(woods.climbable_near(guess, reach) != Vector3.INF)
	facts["ledge_near"] = _flag(not woods.jump_spots_near(brain.bot.global_position, reach).is_empty())
	facts["grass_suspect"] = _flag(brain.suspect_grass() != null)


static func _add_habit_facts(brain: BotBrain, facts: Dictionary) -> void:
	var use: float = brain.memory_use()
	facts["player_ranged_share"] = brain.model.role_share("ranged") * use
	facts["player_melee_share"] = brain.model.role_share("melee") * use
	facts["player_hide_share"] = brain.model.hide_share() * use


static func _flag(value: bool) -> float:
	return 1.0 if value else 0.0


## An equipped move of this role that is ready, usable here, and (for attacks) in range.
static func _move_ready(bot: Creature, role: String, distance: float) -> bool:
	var move: Move = bot.move_with_role(role)
	if move == null or not move.is_ready() or not move.usable():
		return false
	return distance <= effective_range(move)


## How far a move reaches: a shot's reach, an area's radius, a strike's range plus lunge; self moves reach anywhere.
static func effective_range(move: Move) -> float:
	if move.spec.has("reach") and move is ProjectileMove:
		return move.number("reach")
	if move.spec.has("radius") and move is AreaMove:
		return move.number("radius")
	if move is MeleeMove:
		return move.number("range") + move.number("lunge")
	return INF


## Shot at just now, or still sheltering from it (taking cover lasts until the cover plan is finished).
static func _under_fire(brain: BotBrain) -> bool:
	if brain.state_name == "cover" and not brain.current_done():
		return true
	return brain.since_shot_hit <= Tuning.f("bot", "hit_memory") or brain.reflexes.incoming_shot() != null


## 1 right after the player was seen rolling (it cannot roll again yet); otherwise lower against players the bot has
## learned roll early, so it holds its bite for the roll.
static func _punish_window(brain: BotBrain) -> float:
	if brain.senses.since_roll_seen <= Tuning.ai_f("prediction", "roll_punish_window"):
		return 1.0
	return 1.0 - brain.memory_use() * brain.model.early_roll_share()


## How good the best spot for a purpose is, 0..1 (its score over the purpose's best possible score).
static func _quality(brain: BotBrain, purpose: String, around: Vector3) -> float:
	var best: Dictionary = brain.tactics.best(purpose, around, brain.senses.last_known_position)
	if best.is_empty():
		return 0.0
	var weights: Dictionary = Tuning.ai["tactics"]["purposes"][purpose]
	var possible: float = 0.0
	for key: String in ["cover", "sightline", "concealment", "high_ground", "escape", "band", "cut_off"]:
		possible += maxf(float(weights.get(key, 0.0)), 0.0)
	return clampf(float(best["score"]) / possible, 0.0, 1.0)
