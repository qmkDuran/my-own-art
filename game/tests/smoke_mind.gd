class_name SmokeMind
extends RefCounted
## Smoke checks for the smarter bot: utility scoring picks cover under fire in the open, tactical evaluation prefers
## concealed and covered points, a led spit hits a moving player where an unled one misses, the player model learns
## a favourite hiding spot (and persists) and that changes where the bot searches first, and the HUD shows the
## bot's life and "ambush ready" only when they apply.

## In the central clearing: the bot north of the player, who sneaks east across its view.
const LEAD_BOT: Vector2 = Vector2(2.0, 6.0)
const LEAD_PLAYER: Vector2 = Vector2(-1.0, -1.0)
const WATCH_TIME: float = 1.5
const FLIGHT_TIME: float = 2.5
const HIDES_SEEN: int = 3
const PANEL_DISTANCE: float = 8.0

var t: Node


func _init(smoke: Node) -> void:
	t = smoke


func run() -> void:
	await t.fresh_match()
	_utility_prefers_cover()
	_tactics_prefer_concealment_and_cover()
	_player_model_changes_search()
	await _hud_rules()
	await _led_spit(true)
	await _led_spit(false)


func _utility_prefers_cover() -> void:
	var facts: Dictionary = { "sees": 1.0, "has_lead": 1.0, "distance": 9.0, "own_life": 0.8, "enemy_life": 0.8,
		"melee_ready": 1.0, "ranged_ready": 0.0, "clear_shot": 1.0, "under_fire": 1.0, "cover_quality": 0.8,
		"cover_ready": 1.0, "target_facing_me": 1.0, "punish_window": 1.0, "retreat_ready": 1.0 }
	var picked: String = t.m.brain.selector.choose(facts, "ranged", 0.0, "")
	t.expect(picked == "cover", "utility scoring picks cover when shot at in the open (%s)" % picked)
	facts["under_fire"] = 0.0
	facts["ranged_ready"] = 1.0
	picked = t.m.brain.selector.choose(facts, "ranged", 0.0, "")
	t.expect(picked == "ranged", "with its shot ready and no fire coming in it shoots (%s)" % picked)


func _tactics_prefer_concealment_and_cover() -> void:
	var tactics: TacticalEval = t.m.brain.tactics
	var bush: HidingSpot = t.m.woods.hiding_spots[3]
	var threat: Vector3 = t.m.woods.ground_at(t.finder.open_view_spot(bush.global_position, PANEL_DISTANCE))
	var open: Vector3 = t.m.woods.ground_at(t.finder.open_view_spot(threat, PANEL_DISTANCE))
	var in_bush: float = tactics.score_point("ambush", bush.global_position, threat)
	t.expect(in_bush > tactics.score_point("ambush", open, threat), "an ambush spot in a bush beats one in the open")
	var setup: Dictionary = t.finder.tree_shot(6.0, 1.2)
	var behind: Vector3 = t.m.woods.ground_at(setup["behind"])
	var shooter: Vector3 = t.m.woods.ground_at(setup["shooter"])
	var exposed: Vector3 = t.m.woods.ground_at(t.finder.open_view_spot(shooter, 6.0))
	var covered: float = tactics.score_point("cover", behind, shooter)
	t.expect(covered > tactics.score_point("cover", exposed, shooter), "cover behind a trunk beats an exposed spot")


func _player_model_changes_search() -> void:
	var brain: BotBrain = t.m.brain
	brain.senses.last_known_position = t.m.woods.hiding_spots[3].global_position
	brain.senses.observed_velocity = Vector3.ZERO
	var plain: Array[HidingSpot] = (BotStates.all(brain)["search"] as SearchState).spots_to_check()
	var favourite: HidingSpot = plain[-1]
	for k: int in HIDES_SEEN:
		brain.model.note_hide(favourite)
	var learned: Array[HidingSpot] = (BotStates.all(brain)["search"] as SearchState).spots_to_check()
	t.expect(plain[0] != favourite and learned[0] == favourite,
			"after seeing the player hide there, the bot searches that spot first")
	brain.model.save()
	var reloaded := PlayerModel.new(brain.model.path)
	t.expect(reloaded.favourite_weight(favourite) > 0.0, "the bot's memory of the player persists across fights")
	t.expect(brain.barks.size() > 0, "learning shows up in the bot's barks (F3)")


func _hud_rules() -> void:
	var spot: Vector2 = Stage.ground_xz(t.m.woods.patrol_points[1])
	var bot_spot: Vector2 = t.finder.open_view_spot(t.m.woods.ground_at(spot), PANEL_DISTANCE)
	t.stage.place(t.m.player, spot, t.m.woods.ground_at(bot_spot))
	t.stage.place(t.m.bot, bot_spot, t.m.player.global_position)
	t.stage.camera_behind_player(0.0)
	await t.stage.frames(4)
	var level: BotBrain.Alert = t.m.brain.alert()
	t.expect(level == BotBrain.Alert.SEEN and not t.m.player.ambush_ready(), "SEEN never comes with AMBUSH READY")
	t.expect(t.m.hud.bot_bar.visible, "the bot's life shows while you can see it")
	t.stage.face(t.m.player, t.m.player.global_position * 2.0 - t.m.bot.global_position)
	t.stage.camera_behind_player(0.0)
	await t.stage.frames(4)
	t.expect(not t.m.hud.bot_bar.visible, "the bot's life is hidden while you cannot see it")


## The bot watches the player run sideways, then spits leading it (or not). Led spit should hit, unled miss.
func _led_spit(lead: bool) -> void:
	await t.fresh_match()
	t.stage.place(t.m.player, LEAD_PLAYER, t.m.woods.ground_at(LEAD_BOT))
	t.stage.place(t.m.bot, LEAD_BOT, t.m.player.global_position)
	t.m.player.sneaking = true
	t.m.player.move_intent = Vector3.RIGHT
	await t.stage.seconds(WATCH_TIME)
	var life: float = t.m.player.health.current
	t.stage.use(t.m.bot, "glob")
	for k: int in ceili(Stage.move_number("glob", "windup") * Engine.physics_ticks_per_second):
		_aim(lead)
		await t.stage.frames(1)
	await t.stage.seconds(FLIGHT_TIME)
	t.m.player.move_intent = Vector3.ZERO
	var hit: bool = t.m.player.health.current < life
	if lead:
		t.expect(hit, "a spit led on the player's observed movement hits it")
	else:
		t.expect(not hit, "the same spit aimed straight at the moving player misses")


func _aim(lead: bool) -> void:
	var chest: Vector3 = t.m.player.chest_position()
	var velocity: Vector3 = t.m.brain.senses.observed_velocity if lead else Vector3.ZERO
	var speed: float = Stage.move_number("glob", "speed")
	t.m.bot.aim_point = Prediction.lead_point(t.m.bot.mouth_position(), chest, velocity, speed)
	t.stage.face(t.m.bot, t.m.bot.aim_point)
