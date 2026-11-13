class_name SmokeBot
extends RefCounted
## Smoke checks for the bot's use of the woods and its moves: it runs behind cover when shot at, it digs in and
## travels underground to ambush (a movement move), and it leaps up onto high ground from a jump spot.

const DUEL_DISTANCE: float = 11.0
const COVER_LIMIT: float = 14.0
const BURROW_LIMIT: float = 12.0
const LEAP_LIMIT: float = 8.0
const CLIMBED: float = 0.6

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await _takes_cover()
	await _burrow_ambush()
	await _takes_high_ground()


func _takes_cover() -> void:
	await t.fresh_match()
	t.stage.kit(t.m.bot, ["glob", "keen_ears", "scent_trail", "quickening"])
	var bot_spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.bot, bot_spot, t.m.player.global_position)
	var shooter: Vector2 = t.finder.open_view_spot(t.m.bot.global_position, DUEL_DISTANCE)
	t.stage.place(t.m.player, shooter, t.m.bot.global_position)
	t.stage.face(t.m.bot, t.m.player.global_position)
	await t.stage.frames(2)
	t.m.brain.active = true
	t.m.brain.change_state("ranged")
	var took_cover: bool = await t.wait_until(_shoot_until_cover, COVER_LIMIT)
	t.expect(took_cover, "shot at, the bot switches to taking cover")
	var hidden: bool = await t.wait_until(func() -> bool:
		return not Sight.clear(t.m.get_world_3d(), t.m.player.eye_position(), t.m.bot.chest_position()), COVER_LIMIT)
	t.expect(hidden, "the bot gets behind something that blocks the player's line of fire")


func _shoot_until_cover() -> bool:
	if t.m.brain.state_name == "cover":
		return true
	t.m.player.aim_point = t.m.bot.chest_position()
	t.stage.face(t.m.player, t.m.bot.global_position)
	t.stage.use(t.m.player, "glob")
	return false


## The player stands near soft soil, back turned; the bot (with Burrow) is sent to burrow-ambush it.
func _burrow_ambush() -> void:
	await t.fresh_match()
	var soil: Vector3 = t.m.woods.soft_spot_near(t.m.woods.ground_at(Vector2.ZERO), INF)
	t.stage.place(t.m.player, Stage.ground_xz(soil) + Vector2(1.5, 0), soil + Vector3.RIGHT * 10.0)
	t.stage.place(t.m.bot, Stage.ground_xz(soil) + Vector2(-8, 0), soil)
	await t.stage.frames(3)
	var went_under: Array[bool] = [false]
	t.m.brain.active = true
	t.m.brain.change_state("burrow_ambush")
	var popped: bool = await t.wait_until(func() -> bool:
		went_under[0] = went_under[0] or t.m.bot.traversal.mode == Traversal.Mode.UNDERGROUND
		return went_under[0] and t.m.bot.traversal.mode == Traversal.Mode.GROUND, BURROW_LIMIT)
	t.expect(went_under[0], "the bot uses a movement move: it burrows into soft soil")
	t.expect(popped, "and pops back up near the player")


func _takes_high_ground() -> void:
	await t.fresh_match()
	t.stage.kit(t.m.bot, ["snap", "glob", "leap", "scent_trail"])
	var jump: Dictionary = t.m.woods.features.jump_spots()[0]
	var start: Vector3 = jump["from"]
	t.stage.place(t.m.bot, Stage.ground_xz(start), jump["to"])
	t.stage.place(t.m.player, Stage.ground_xz(start) + Vector2(12, 0), jump["to"])
	await t.stage.frames(3)
	t.m.brain.active = true
	t.m.brain.change_state("high_ground")
	var up: bool = await t.wait_until(func() -> bool:
		return t.m.bot.global_position.y > (jump["from"] as Vector3).y + CLIMBED and t.m.bot.is_on_floor(), LEAP_LIMIT)
	t.expect(up, "the bot leaps up onto high ground from a jump spot")
