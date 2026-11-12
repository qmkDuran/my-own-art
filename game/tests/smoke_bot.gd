class_name SmokeBot
extends RefCounted
## Smoke checks for the bot's use of the woods: it runs behind cover when spat at, and it walks around a snare it
## saw being set (while an unseen snare on the same path catches it).

const DUEL_DISTANCE: float = 11.0
const COVER_LIMIT: float = 14.0
const CROSSING: float = 4.0
const CROSS_LIMIT: float = 8.0
const EARSHOT_FACTOR: float = 4.0

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await _takes_cover()
	await _avoids_seen_snare()
	await _walks_into_unseen_snare()


func _takes_cover() -> void:
	await t.fresh_match()
	var bot_spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.bot, bot_spot, t.m.player.global_position)
	var shooter: Vector2 = t.finder.open_view_spot(t.m.bot.global_position, DUEL_DISTANCE)
	t.stage.place(t.m.player, shooter, t.m.bot.global_position)
	t.stage.face(t.m.bot, t.m.player.global_position)
	await t.stage.frames(2)
	t.m.brain.active = true
	t.m.brain.change_state("fight")
	var took_cover: bool = await t.wait_until(_shoot_until_cover, COVER_LIMIT)
	t.expect(took_cover, "spat at, the bot switches to taking cover")
	var hidden: bool = await t.wait_until(func() -> bool:
		return not Sight.clear(t.m.get_world_3d(), t.m.player.eye_position(), t.m.bot.chest_position()), COVER_LIMIT)
	t.expect(hidden, "the bot gets behind something that blocks the player's line of fire")


func _shoot_until_cover() -> bool:
	if t.m.brain.state_name == "cover":
		return true
	t.m.player.aim_point = t.m.bot.chest_position()
	t.stage.face(t.m.player, t.m.bot.global_position)
	t.m.player.try_spit()
	return false


## Sets a snare while the bot watches (or out of its sight and earshot), then sends the bot straight across it.
func _snare_crossing(bot_watches: bool) -> SnareTrap:
	await t.fresh_match()
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(0, CROSSING)))
	var watch_from: Vector2 = spot + Vector2(-CROSSING * (1.5 if bot_watches else EARSHOT_FACTOR), 0)
	var look_at: Vector3 = t.m.player.global_position if bot_watches else t.m.woods.ground_at(watch_from * 2.0 - spot)
	t.stage.place(t.m.bot, watch_from, look_at)
	t.m.player.try_trap()
	await t.stage.seconds(Tuning.f("trap", "place_time") + Tuning.f("trap", "arm_delay"))
	var snare: SnareTrap = t.m.player.trap.snare
	t.stage.place(t.m.player, spot + Vector2(0, CROSSING * 2.0), t.m.bot.global_position)
	var snare_at: Vector2 = Stage.ground_xz(snare.global_position)
	t.stage.place(t.m.bot, snare_at + Vector2(-CROSSING, 0), snare.global_position)
	await t.stage.frames(2)
	t.m.brain.mover.go_to(t.m.woods.ground_at(snare_at + Vector2(CROSSING, 0)), false)
	await t.wait_until(func() -> bool: return t.m.brain.mover.arrived() or snare.sprung, CROSS_LIMIT)
	return snare


func _avoids_seen_snare() -> void:
	var snare: SnareTrap = await _snare_crossing(true)
	t.expect(t.m.brain.senses.known_snares.size() == 1, "the bot remembers the snare it watched being set")
	t.expect(not snare.sprung and not t.m.bot.is_rooted(), "the bot walks around a snare it saw being set")
	t.expect(t.m.brain.mover.arrived(), "and still gets where it was going")


func _walks_into_unseen_snare() -> void:
	var snare: SnareTrap = await _snare_crossing(false)
	t.expect(snare.sprung and t.m.bot.is_rooted(), "the same path over an unseen snare catches the bot")
