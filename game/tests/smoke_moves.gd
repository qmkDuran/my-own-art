class_name SmokeMoves
extends RefCounted
## Smoke checks for the move system: the loadout screen's choice is what the creature fights with (and a Baby gets
## only Baby moves), Burrow works only in soft soil and hides the burrower, Leap lands on a rock, Cinder Spit sets
## tall grass alight so it hides no one, and Scent Trail hands the bot a fresh clue.

const WINDUP_SLACK: float = 0.3
const LANDED: float = 0.6
const FLIGHT: float = 1.6
const SCENT_WALK: float = 1.5
const CLUE_NEAR: float = 3.0
const BURN_WAIT: float = 1.5

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await t.fresh_match()
	_loadout_applies()
	await _burrow_needs_soft_soil()
	await _leap_lands_on_rock()
	await _cinder_burns_grass()
	await _scent_gives_clue()


func _loadout_applies() -> void:
	Loadouts.set_level("grown")
	Loadouts.assign(2, "spring")
	t.m.apply_loadouts()
	t.expect(t.m.player.moves[2].id == "spring", "the loadout screen's choice is equipped")
	Loadouts.set_level("baby")
	t.m.apply_loadouts()
	var babyish: bool = t.m.player.moves.all(func(move: Move) -> bool: return MoveLibrary.allowed(move.id, "baby")) \
			and t.m.bot.moves.all(func(move: Move) -> bool: return MoveLibrary.allowed(move.id, "baby"))
	var fewer: bool = MoveLibrary.learnable("player", "baby").size() < MoveLibrary.learnable("player", "grown").size()
	t.expect(babyish and fewer,
			"Baby creatures choose from fewer moves, by the same rule for both")
	Loadouts.set_level("grown")
	Loadouts.player_moves = []


func _burrow_needs_soft_soil() -> void:
	await t.fresh_match()
	t.stage.kit(t.m.player, ["snap", "burrow", "leap", "echo_pulse"])
	var rocky: Dictionary = t.m.woods.features.rocky_patches()[0]
	t.stage.place(t.m.player, rocky["pos"], t.m.bot.global_position)
	await t.stage.frames(2)
	t.expect(not t.stage.use(t.m.player, "burrow"), "Burrow does not work on rocky ground")
	var soil: Vector3 = t.m.woods.soft_spot_near(t.m.player.global_position, INF)
	t.stage.place(t.m.player, Stage.ground_xz(soil), t.m.bot.global_position)
	t.stage.place(t.m.bot, Stage.ground_xz(soil) + Vector2(3, 0), t.m.player.global_position)
	await t.stage.frames(2)
	t.stage.use(t.m.player, "burrow")
	await t.stage.seconds(Stage.move_number("burrow", "windup") + WINDUP_SLACK)
	t.expect(t.m.player.traversal.mode == Traversal.Mode.UNDERGROUND, "Burrow digs in on soft soil")
	t.expect(not t.m.brain.senses.sees_target, "a burrowed creature is unseen even 3 m away")


func _leap_lands_on_rock() -> void:
	await t.fresh_match()
	var jump: Dictionary = t.m.woods.features.jump_spots()[0]
	t.stage.place(t.m.player, Stage.ground_xz(jump["from"]), jump["to"])
	await t.stage.frames(3)
	var toward: Vector3 = (jump["to"] as Vector3) - t.m.player.global_position
	t.m.player.move_intent = Vector3(toward.x, 0.0, toward.z).normalized()
	t.stage.use(t.m.player, "leap")
	await t.stage.seconds(FLIGHT)
	t.m.player.move_intent = Vector3.ZERO
	await t.stage.frames(5)
	var up: float = t.m.player.global_position.y - (jump["from"] as Vector3).y
	t.expect(up > LANDED and t.m.player.is_on_floor(), "Leap lands on top of the rock (%.1f m up)" % up)


func _cinder_burns_grass() -> void:
	await t.fresh_match()
	t.stage.kit(t.m.player, ["snap", "cinder_spit", "leap", "echo_pulse"])
	var patch: HidingSpot = _grass_patch()
	var from: Vector2 = t.finder.open_view_spot(patch.global_position, patch.radius + 4.0)
	t.stage.place(t.m.player, from, patch.global_position)
	t.m.player.aim_point = patch.global_position + Vector3.UP * Tuning.f("perception", "chest_height")
	await t.stage.frames(2)
	t.stage.use(t.m.player, "cinder_spit")
	await t.stage.seconds(Stage.move_number("cinder_spit", "windup") + BURN_WAIT)
	t.expect(not patch.conceals(), "Cinder Spit sets tall grass alight; burning grass hides no one")


func _scent_gives_clue() -> void:
	await t.fresh_match()
	t.stage.kit(t.m.bot, ["snap", "glob", "burrow", "scent_trail"])
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(spot + Vector2(10, 0)))
	t.stage.place(t.m.bot, spot + Vector2(-12, 0), t.m.woods.ground_at(spot + Vector2(-30, 0)))
	t.m.player.move_intent = Vector3.RIGHT
	await t.stage.seconds(SCENT_WALK)
	t.m.player.move_intent = Vector3.ZERO
	t.m.brain.senses.has_lead = false
	t.stage.use(t.m.bot, "scent_trail")
	await t.stage.seconds(Stage.move_number("scent_trail", "windup") + WINDUP_SLACK)
	var clue: float = t.m.brain.senses.last_known_position.distance_to(t.m.player.global_position)
	t.expect(t.m.brain.senses.has_lead and clue < CLUE_NEAR,
			"Scent Trail gives the bot a fresh clue (%.1f m off)" % clue)


func _grass_patch() -> HidingSpot:
	for spot: HidingSpot in t.m.woods.hiding_spots:
		if spot.kind == "grass" and t.finder.open_view_spot(spot.global_position, spot.radius + 4.0) != Vector2.INF:
			return spot
	return null
