extends Node
## --smoke: headless checks of the real game scene. Loads the woods, then checks movement, spit (blocked by a tree,
## hits in the open), bite range, the ambush bonus, snares (root, and the bot avoiding one it saw set), hiding
## (the bot loses you in a bush it did not see you enter), search-then-find, taking cover from spit, win, lose and
## restart. Prints "SMOKE ok/FAIL: ..." per check, then SMOKE PASS or SMOKE FAIL.

const SETTLE_TIME: float = 0.5

var m: Main
var stage: Stage
var finder: SpotFinder
var _fails: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func expect(ok: bool, what: String) -> void:
	print("SMOKE ok: " if ok else "SMOKE FAIL: ", what)
	if not ok:
		_fails.append(what)


func _run() -> void:
	await _fresh_match()
	_scene_loads()
	await _player_moves()
	await SmokeCombat.new(self).run()
	await SmokeStealth.new(self).run()
	await SmokeBot.new(self).run()
	await _win_lose_restart()
	print("SMOKE PASS" if _fails.is_empty() else "SMOKE FAIL (%d): %s" % [_fails.size(), ", ".join(_fails)])
	get_tree().quit(0 if _fails.is_empty() else 1)


## A brand new match, straight into play, with the bot's mind paused (each check decides what the bot does).
func _fresh_match() -> void:
	Main.skip_intro = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	m = Main.current
	stage = Stage.new(m)
	finder = SpotFinder.new(m)
	await stage.frames(3)
	stage.freeze_bot()
	m.controller.set_physics_process(false)


func fresh_match() -> void:
	await _fresh_match()


func _scene_loads() -> void:
	expect(m != null and m.flow.phase == MatchFlow.Phase.PLAYING, "the main scene loads straight into play")
	expect(m.woods.tree_spots.size() >= 200, "the woods have %d trees" % m.woods.tree_spots.size())
	expect(m.woods.hiding_spots.size() >= 15, "there are %d hiding spots" % m.woods.hiding_spots.size())
	var path: PackedVector3Array = NavigationServer3D.map_get_path(m.woods.nav_map(), m.woods.player_spawn,
			m.woods.bot_spawn, true)
	expect(path.size() > 1 and path[-1].distance_to(m.woods.bot_spawn) < 1.0, "the navmesh links both spawns")


func _player_moves() -> void:
	m.controller.set_physics_process(true)
	var start: Vector3 = m.player.global_position
	Input.action_press("move_forward")
	await stage.seconds(1.0)
	Input.action_release("move_forward")
	var moved: float = Stage.ground_xz(m.player.global_position).distance_to(Stage.ground_xz(start))
	expect(moved > 2.5 and moved < Tuning.f("creature", "run_speed") * 1.05,
			"the player moves at a moderate pace (%.2f m in 1 s)" % moved)
	await stage.seconds(SETTLE_TIME)
	start = m.player.global_position
	Input.action_press("move_forward")
	Input.action_press("sneak")
	await stage.seconds(1.0)
	Input.action_release("move_forward")
	Input.action_release("sneak")
	moved = Stage.ground_xz(m.player.global_position).distance_to(Stage.ground_xz(start))
	expect(moved < Tuning.f("creature", "sneak_speed") * 1.05, "sneaking is slower (%.2f m in 1 s)" % moved)
	m.controller.set_physics_process(false)


func _win_lose_restart() -> void:
	await _fresh_match()
	m.bot.take_hit(m.bot.health.maximum * 2.0, m.player, false, "bite")
	await get_tree().process_frame
	expect(m.flow.phase == MatchFlow.Phase.WON, "beating the bot wins")
	m.flow.restart()
	await get_tree().process_frame
	await get_tree().process_frame
	m = Main.current
	await get_tree().physics_frame
	expect(m.flow.phase == MatchFlow.Phase.PLAYING and not get_tree().paused, "restart starts a new match")
	expect(m.bot.health.fraction() == 1.0 and not m.bot.is_dead(), "the restarted bot is fresh")
	m.player.take_hit(m.player.health.maximum * 2.0, m.bot, false, "bite")
	await get_tree().process_frame
	expect(m.flow.phase == MatchFlow.Phase.LOST, "losing all life loses")
	m.flow.restart()
	await get_tree().process_frame
	await get_tree().process_frame
	m = Main.current
	expect(m.player.health.fraction() == 1.0 and m.flow.phase == MatchFlow.Phase.PLAYING, "restart after a loss works")


## Waits until the condition holds (true) or the time runs out (false).
func wait_until(condition: Callable, max_seconds: float) -> bool:
	var frames_left: int = ceili(max_seconds * Engine.physics_ticks_per_second)
	while frames_left > 0:
		if condition.call():
			return true
		await get_tree().physics_frame
		frames_left -= 1
	return condition.call()


## Fires a spit from the player at a point and returns how it landed ("hit", "blocked", "ground", ...).
func spit_and_watch(aim: Vector3) -> String:
	var outcome: Dictionary = { "result": "none" }
	m.player.aim_point = aim
	stage.face(m.player, aim)
	m.player.try_spit()
	var fired: bool = await wait_until(func() -> bool: return not get_tree().get_nodes_in_group("spit").is_empty(), 2.0)
	if not fired:
		return "not fired"
	var glob: SpitProjectile = get_tree().get_nodes_in_group("spit")[0]
	glob.landed.connect(func(result: String, _where: Vector3) -> void: outcome["result"] = result)
	await wait_until(func() -> bool: return outcome["result"] != "none", 4.0)
	return outcome["result"]
