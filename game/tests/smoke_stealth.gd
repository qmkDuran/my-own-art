class_name SmokeStealth
extends RefCounted
## Smoke checks for hiding: the bot loses sight of a player who slips into a bush while it looks away (but keeps
## sight if it watched them go in), the bot searches a lead and then finds the player hiding there, the lock-on
## breaks when the bot hides, and an unseen bot moving close by gives itself away (the rustle cue).

const WATCH_DISTANCE: float = 8.0
const BESIDE_BUSH: float = 3.2
const HEARD_FROM: float = 12.0
const SEARCH_LIMIT: float = 40.0
const LOCK_SLACK: float = 0.5
const RUSTLE_FROM: float = 4.0

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await _loses_sight_in_bush()
	await _watched_entry_keeps_sight()
	await _search_then_find()
	await _lock_breaks_when_bot_hides()
	await _rustle_cue()


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


func _lock_breaks_when_bot_hides() -> void:
	await t.fresh_match()
	var bush: HidingSpot = _bush_with_view()
	var player_spot: Vector2 = t.finder.open_view_spot(bush.global_position, WATCH_DISTANCE)
	var beside: Vector2 = Stage.ground_xz(bush.global_position) \
			+ (player_spot - Stage.ground_xz(bush.global_position)).normalized().orthogonal() * BESIDE_BUSH
	t.stage.place(t.m.bot, beside, t.m.woods.ground_at(player_spot))
	t.stage.place(t.m.player, player_spot, bush.global_position)
	t.stage.camera_behind_player(0.0)
	await t.stage.frames(5)
	t.m.lock_on.toggle()
	t.expect(t.m.lock_on.target_locked(), "Tab locks on to a bot in plain view")
	t.stage.place(t.m.bot, Stage.ground_xz(bush.global_position), t.m.player.global_position)
	await t.stage.seconds(Tuning.f("lock_on", "lose_sight_time") + LOCK_SLACK)
	t.expect(not t.m.lock_on.target_locked(), "the lock breaks once the bot hides in a bush")


func _rustle_cue() -> void:
	await t.fresh_match()
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, -10)))
	t.stage.camera_behind_player(0.0)
	t.stage.place(t.m.bot, spot + Vector2(0, RUSTLE_FROM), t.m.player.global_position)
	t.m.brain.mover.go_to(t.m.woods.ground_at(spot + Vector2(RUSTLE_FROM, RUSTLE_FROM)), true)
	await t.stage.seconds(LOCK_SLACK)
	t.expect(not t.m.sight.sees_bot and t.m.sight.rustling, "a bot sneaking unseen behind the player rustles")


## A bush with open ground around it, inside the arena.
func _bush_with_view() -> HidingSpot:
	for spot: HidingSpot in t.m.woods.hiding_spots:
		if spot.kind == "bush" and t.finder.open_view_spot(spot.global_position, HEARD_FROM) != Vector2.INF \
				and t.finder.open_view_spot(spot.global_position, WATCH_DISTANCE) != Vector2.INF:
			return spot
	return t.m.woods.hiding_spots[0]


## Lets the bot's senses (which keep working while its mind is paused) take in the scene.
func _sense(count: int) -> void:
	await t.stage.frames(count)
