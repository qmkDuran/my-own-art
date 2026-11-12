class_name SmokeStealth
extends RefCounted
## Smoke checks for hiding: the bot loses sight of a player who slips into a bush while it looks away (but keeps
## sight if it watched them go in), and the bot searches a lead and then finds the player hiding there.

const WATCH_DISTANCE: float = 8.0
const BESIDE_BUSH: float = 3.2
const HEARD_FROM: float = 12.0
const SEARCH_LIMIT: float = 40.0

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await _loses_sight_in_bush()
	await _watched_entry_keeps_sight()
	await _search_then_find()


func _setup_by_bush() -> HidingSpot:
	var bush: HidingSpot = _bush_with_view()
	var bot_spot: Vector2 = t.finder.open_view_spot(bush.global_position, WATCH_DISTANCE)
	t.stage.place(t.m.bot, bot_spot, bush.global_position)
	var beside: Vector2 = Stage.ground_xz(bush.global_position) \
			+ (bot_spot - Stage.ground_xz(bush.global_position)).normalized().orthogonal() * BESIDE_BUSH
	t.stage.place(t.m.player, beside, t.m.bot.global_position)
	await t.stage.frames(3)
	return bush


func _loses_sight_in_bush() -> void:
	await t.fresh_match()
	var bush: HidingSpot = await _setup_by_bush()
	await _sense(3)
	t.expect(t.m.brain.senses.sees_target, "the bot sees the player next to the bush")
	t.stage.face(t.m.bot, t.m.bot.global_position * 2.0 - bush.global_position)
	await _sense(3)
	t.expect(not t.m.brain.senses.sees_target, "the bot looking away does not see the player")
	t.stage.place(t.m.player, Stage.ground_xz(bush.global_position), t.m.bot.global_position)
	await _sense(4)
	t.stage.face(t.m.bot, bush.global_position)
	await _sense(4)
	t.expect(t.m.player.stealth.is_hidden(), "the player is hidden in the bush")
	t.expect(not t.m.brain.senses.sees_target, "facing the bush again, the bot no longer sees the hidden player")


func _watched_entry_keeps_sight() -> void:
	await t.fresh_match()
	var bush: HidingSpot = await _setup_by_bush()
	await _sense(3)
	t.stage.place(t.m.player, Stage.ground_xz(bush.global_position), t.m.bot.global_position)
	await _sense(4)
	t.expect(t.m.player.stealth.is_hidden() and t.m.brain.senses.sees_target,
			"a bot that watched the player walk into a bush still sees them there")


func _search_then_find() -> void:
	await t.fresh_match()
	var bush: HidingSpot = _bush_with_view()
	t.stage.place(t.m.player, Stage.ground_xz(bush.global_position), t.m.bot.global_position)
	var bot_spot: Vector2 = t.finder.open_view_spot(bush.global_position, HEARD_FROM)
	t.stage.place(t.m.bot, bot_spot, t.m.woods.ground_at(bot_spot * 2.0 - Stage.ground_xz(bush.global_position)))
	await t.stage.frames(3)
	var visited: Array[String] = []
	t.m.brain.state_changed.connect(func(state: String) -> void: visited.append(state))
	t.m.brain.active = true
	NoiseBus.emit_noise(t.m.player, t.m.player.global_position, HEARD_FROM * 1.5, "step")
	var found: bool = await t.wait_until(func() -> bool: return visited.has("search") and t.m.brain.senses.sees_target,
			SEARCH_LIMIT)
	t.expect(visited.has("search"), "a heard noise sends the bot into its search state (%s)" % ", ".join(visited))
	t.expect(found, "searching, the bot finds the player hiding in the bush")


## A bush with open ground around it, inside the arena.
func _bush_with_view() -> HidingSpot:
	for spot: HidingSpot in t.m.woods.hiding_spots:
		if spot.kind == "bush" and t.finder.open_view_spot(spot.global_position, HEARD_FROM) != Vector2.INF \
				and t.finder.open_view_spot(spot.global_position, WATCH_DISTANCE) != Vector2.INF:
			return spot
	return t.m.woods.hiding_spots[0]


## Ticks the bot's senses by hand (its mind is paused in these checks).
func _sense(count: int) -> void:
	for k: int in count:
		await t.stage.frames(1)
		t.m.brain.senses.tick(1.0 / Engine.physics_ticks_per_second)
