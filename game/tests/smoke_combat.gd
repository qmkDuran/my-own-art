class_name SmokeCombat
extends RefCounted
## Smoke checks for the moves: a spit blocked by a tree, a spit hitting in the open, bite range, the ambush bonus
## (from hiding and from behind an unaware target, with a stagger), and a snare rooting the bot.

const SHOT_RANGE: float = 6.0
const HIDE_BEHIND: float = 2.5
const OPEN_SHOT_RANGE: float = 8.0
const BITE_CLOSE: float = 1.8
const BITE_FAR: float = 6.0
const BITE_WAIT: float = 1.2
const BUSH_STRIKE: float = 3.4
const DAMAGE_TOLERANCE: float = 0.01

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await _spit_blocked_by_tree()
	await _spit_hits_in_open()
	await _bite_range()
	await _ambush_bonus()
	await _snare_roots()


func _spit_blocked_by_tree() -> void:
	await t.fresh_match()
	var setup: Dictionary = t.finder.tree_shot(SHOT_RANGE, HIDE_BEHIND)
	t.expect(not setup.is_empty(), "found a tree to shoot at")
	if setup.is_empty():
		return
	t.stage.place(t.m.player, setup["shooter"], setup["tree"])
	t.stage.place(t.m.bot, setup["behind"], t.m.player.global_position)
	await t.stage.frames(2)
	var result: String = await t.spit_and_watch(t.m.bot.chest_position())
	t.expect(result == "blocked", "a spit at a bot behind a tree hits the tree (%s)" % result)
	t.expect(t.m.bot.health.fraction() == 1.0, "the bot behind the tree is unhurt")


func _spit_hits_in_open() -> void:
	await t.fresh_match()
	var bot_spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.bot, bot_spot, t.m.player.global_position)
	var shooter: Vector2 = t.finder.open_view_spot(t.m.bot.global_position, OPEN_SHOT_RANGE)
	t.stage.place(t.m.player, shooter, t.m.bot.global_position)
	t.stage.face(t.m.bot, t.m.player.global_position)
	await t.stage.frames(2)
	t.m.bot.aware_of_opponent = true
	var result: String = await t.spit_and_watch(t.m.bot.chest_position())
	var lost: float = t.m.bot.health.maximum - t.m.bot.health.current
	t.expect(result == "hit" and absf(lost - Tuning.f("spit", "damage")) < DAMAGE_TOLERANCE,
			"a spit in the open hits for its damage (%s, -%.1f)" % [result, lost])


func _bite_range() -> void:
	await t.fresh_match()
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, -10)))
	t.stage.place(t.m.bot, spot + Vector2(0, -BITE_FAR), t.m.player.global_position)
	await _bite_at_bot()
	t.expect(t.m.bot.health.fraction() == 1.0, "a bite from %.0f m misses" % BITE_FAR)
	t.m.player.bite.cooldown_left = 0.0
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, -10)))
	t.stage.place(t.m.bot, spot + Vector2(0, -BITE_CLOSE), t.m.player.global_position)
	t.m.bot.aware_of_opponent = true
	await _bite_at_bot()
	var lost: float = t.m.bot.health.maximum - t.m.bot.health.current
	t.expect(absf(lost - Tuning.f("bite", "damage")) < DAMAGE_TOLERANCE,
			"a bite from %.1f m lands (-%.1f)" % [BITE_CLOSE, lost])


func _ambush_bonus() -> void:
	await t.fresh_match()
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, -10)))
	t.stage.place(t.m.bot, spot + Vector2(0, -BITE_CLOSE), t.m.woods.ground_at(spot + Vector2(0, -20)))
	t.m.bot.aware_of_opponent = false
	await _bite_at_bot()
	var lost: float = t.m.bot.health.maximum - t.m.bot.health.current
	var expected: float = Tuning.f("bite", "damage") * Tuning.f("stealth", "ambush_multiplier")
	t.expect(absf(lost - expected) < DAMAGE_TOLERANCE,
			"a bite on an unaware bot is an ambush (-%.1f, want -%.1f)" % [lost, expected])
	await _ambush_from_bush()


func _ambush_from_bush() -> void:
	await t.fresh_match()
	var bush: HidingSpot = t.m.woods.hiding_spots[3]
	var bot_spot: Vector2 = Stage.ground_xz(bush.global_position) + Vector2(BUSH_STRIKE, 0)
	t.stage.place(t.m.bot, bot_spot, t.m.woods.ground_at(bot_spot + Vector2(BUSH_STRIKE, 0)))
	t.stage.place(t.m.player, Stage.ground_xz(bush.global_position), t.m.woods.ground_at(bot_spot))
	await t.stage.frames(3)
	t.stage.face(t.m.bot, t.m.player.global_position)
	await t.stage.seconds(Tuning.f("stealth", "unaware_memory"))
	t.expect(t.m.player.stealth.is_hidden() and not t.m.bot.aware_of_opponent,
			"a bot %.1f m from a bush, looking at it, does not notice the player hidden inside" % BUSH_STRIKE)
	var staggered: Array[bool] = [false]
	t.m.bot.hit_taken.connect(func(_a: float, _b: Creature, _c: bool, _d: String) -> void:
		staggered[0] = t.m.bot.is_staggered())
	await _bite_at_bot()
	var expected: float = Tuning.f("bite", "damage") * Tuning.f("stealth", "ambush_multiplier")
	var lost: float = t.m.bot.health.maximum - t.m.bot.health.current
	t.expect(absf(lost - expected) < DAMAGE_TOLERANCE, "a lunging bite out of the bush is an ambush (-%.1f)" % lost)
	t.expect(staggered[0], "an ambush staggers the target")
	t.expect(not t.m.player.stealth.is_hidden(), "attacking from a bush reveals the player")


func _snare_roots() -> void:
	await t.fresh_match()
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, -10)))
	t.stage.place(t.m.bot, spot + Vector2(10, 0), t.m.player.global_position)
	t.m.player.try_trap()
	await t.stage.seconds(Tuning.f("trap", "place_time") + Tuning.f("trap", "arm_delay") + 0.2)
	var snare: SnareTrap = t.m.player.trap.snare
	t.expect(is_instance_valid(snare), "F sets a snare")
	if not is_instance_valid(snare):
		return
	t.stage.place(t.m.player, spot + Vector2(-6, 0), t.m.bot.global_position)
	t.stage.place(t.m.bot, Stage.ground_xz(snare.global_position), t.m.player.global_position)
	await t.stage.frames(3)
	var before: Vector3 = t.m.bot.global_position
	t.m.bot.move_intent = Vector3.RIGHT
	await t.stage.seconds(1.0)
	var lost: float = t.m.bot.health.maximum - t.m.bot.health.current
	t.expect(snare.sprung and t.m.bot.is_rooted(), "the snare springs on the bot and roots it")
	t.expect(t.m.bot.global_position.distance_to(before) < 0.2, "a rooted bot cannot move")
	t.expect(absf(lost - Tuning.f("trap", "damage")) < DAMAGE_TOLERANCE,
			"the snare deals its small damage (-%.1f)" % lost)


func _bite_at_bot() -> void:
	t.m.player.aim_point = t.m.bot.global_position
	t.m.player.try_bite()
	await t.stage.seconds(BITE_WAIT)
