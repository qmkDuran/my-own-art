class_name BotFacts
## Gathers the facts the bot's utility scoring looks at, all from its own senses, memory and body (never from the
## player's hidden state): distance and line of sight to the player's last known spot, life (its own, and the
## player's as last seen), cooldowns, being shot at, cover and ambush spots nearby, height, its snare, learned habits.


## Time-since values are capped so curves get a finite number.
const INF_SECONDS: float = 99.0


static func gather(brain: BotBrain) -> Dictionary:
	var bot: Creature = brain.bot
	var senses: Perception = brain.senses
	var clue: Vector3 = senses.last_known_position
	var facts: Dictionary = {
		"sees": _flag(senses.sees_target), "has_lead": _flag(senses.has_lead),
		"distance": bot.global_position.distance_to(clue), "since_seen": minf(senses.time_since_seen, INF_SECONDS),
		"own_life": bot.health.fraction(), "enemy_life": senses.target_life_seen,
		"bite_ready": _flag(bot.bite.is_ready()), "spit_ready": _flag(bot.spit.is_ready()),
		"snare_ready": _flag(bot.trap.is_ready() and not _snare_set(bot)), "own_snare_set": _flag(_snare_set(bot)),
		"clear_shot": _flag(senses.sees_target and Sight.clear(bot.get_world_3d(), bot.mouth_position(),
				clue + Vector3.UP * Tuning.f("perception", "chest_height"))),
		"under_fire": _flag(_under_fire(brain)), "target_facing_me": _flag(senses.target_facing_me()),
		"target_approaching": _flag(senses.has_lead and senses.target_approaching()),
		"height_advantage": bot.global_position.y - clue.y,
		"cover_ready": _flag(brain.state_name == "cover" or brain.since_cover >= Tuning.f("bot", "cover_cooldown")),
		"retreat_ready": _flag(brain.state_name == "retreat"
				or brain.since_retreat >= Tuning.f("bot", "retreat_cooldown")),
		"punish_window": _punish_window(brain), "memory_known_spot": _known_spot(brain),
	}
	facts["cover_quality"] = _quality(brain, "cover", bot.global_position) if facts["under_fire"] > 0.0 else 0.0
	var lurking: bool = senses.has_lead and not senses.sees_target
	facts["ambush_quality"] = _quality(brain, "ambush", brain.predicted_target()) if lurking else 0.0
	return facts


static func _flag(value: bool) -> float:
	return 1.0 if value else 0.0


static func _snare_set(bot: Creature) -> bool:
	return is_instance_valid(bot.trap.snare) and not bot.trap.snare.sprung


## Shot at just now, or still sheltering from it (taking cover lasts until the cover plan is finished).
static func _under_fire(brain: BotBrain) -> bool:
	if brain.state_name == "cover" and not brain.current_done():
		return true
	return brain.since_spit_hit <= Tuning.f("bot", "hit_memory") or brain.reflexes.incoming_spit() != null


## 1 right after the player was seen rolling (it cannot roll again yet); otherwise lower against players the bot has
## learned roll early, so it holds its bite for the roll.
static func _punish_window(brain: BotBrain) -> float:
	if brain.senses.since_roll_seen <= Tuning.ai_f("prediction", "roll_punish_window"):
		return 1.0
	return 1.0 - brain.memory_use() * brain.model.early_roll_share()


static func _known_spot(brain: BotBrain) -> float:
	return brain.memory_use() if brain.model.has_favourite() else 0.0


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
