extends Node
## --duel: a long headless duel between the real bot (its default loadout) and a simple scripted player (walks a
## loop of points on the navmesh, spits when it sees the bot, snaps up close). Logs the bot's state changes and
## checks that the bot is
## never stuck: while it is trying to walk, it always makes progress. Prints DUEL PASS or DUEL FAIL.

const DUEL_SECONDS: float = 150.0
const STUCK_WINDOW: float = 3.0
const STUCK_PROGRESS: float = 0.5
const MIN_STATES: int = 4
const WAYPOINT_REACHED: float = 1.2
const BITE_REACH: float = 3.0
const MELEE_CONTACT: float = 2.0

var m: Main
var stage: Stage
var _route: Array[Vector3] = []
var _leg: int = 0
var _path: PackedVector3Array = PackedVector3Array()
var _visited: Dictionary = {}
var _stuck_events: int = 0
var _clock: float = 0.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	Main.skip_intro = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().process_frame
	await get_tree().process_frame
	m = Main.current
	stage = Stage.new(m)
	stage.script_player()
	stage.kit(m.player, ["snap", "glob", "leap", "keen_ears"])
	_route = m.woods.patrol_points.duplicate()
	_route.reverse()
	m.brain.state_changed.connect(_on_state)
	var frames: int = ceili(DUEL_SECONDS * Engine.physics_ticks_per_second)
	var window: int = ceili(STUCK_WINDOW * Engine.physics_ticks_per_second)
	var history: Array[Vector3] = []
	var walking_frames: Array[bool] = []
	for k: int in frames:
		if m.flow.phase != MatchFlow.Phase.PLAYING:
			break
		_drive_player()
		await get_tree().physics_frame
		_clock += 1.0 / Engine.physics_ticks_per_second
		history.append(m.bot.global_position)
		walking_frames.append(_bot_walking())
		if history.size() > window:
			history.pop_front()
			walking_frames.pop_front()
			if not walking_frames.has(false) and _check_progress(history):
				history.clear()
				walking_frames.clear()
	_report()


func _drive_player() -> void:
	var player: Creature = m.player
	if m.sight.sees_bot:
		player.aim_point = m.bot.chest_position()
		player.look_target = m.bot.global_position
		player.has_look_target = true
		if player.global_position.distance_to(m.bot.global_position) < BITE_REACH:
			stage.use(player, "snap")
		else:
			stage.use(player, "glob")
	else:
		player.has_look_target = false
	_walk_route(player)


func _walk_route(player: Creature) -> void:
	if _path.is_empty():
		_path = NavigationServer3D.map_get_path(m.woods.nav_map(), player.global_position, _route[_leg], true)
	var at: Vector2 = Stage.ground_xz(player.global_position)
	while not _path.is_empty() and Stage.ground_xz(_path[0]).distance_to(at) < WAYPOINT_REACHED:
		_path.remove_at(0)
	if _path.is_empty():
		_leg = (_leg + 1) % _route.size()
		player.move_intent = Vector3.ZERO
		return
	var toward: Vector3 = _path[0] - player.global_position
	player.move_intent = Vector3(toward.x, 0.0, toward.z).normalized()


## The bot means to walk (and is not just pressing into the player in melee).
func _bot_walking() -> bool:
	var in_melee: bool = m.bot.global_position.distance_to(m.player.global_position) < MELEE_CONTACT
	return m.bot.move_intent.length() > 0.0 and not m.bot.busy() and not m.bot.is_rooted() and not in_melee


## A stuck event: the bot meant to walk for a whole window but hardly moved.
func _check_progress(history: Array[Vector3]) -> bool:
	if history[0].distance_to(history[-1]) >= STUCK_PROGRESS:
		return false
	_stuck_events += 1
	print("DUEL stuck at ", m.bot.global_position, " in ", m.brain.state_name)
	return true


func _on_state(state: String) -> void:
	_visited[state] = int(_visited.get(state, 0)) + 1
	print("DUEL %6.1fs  %-8s bot %3d  player %3d" % [_clock, state,
			roundi(m.bot.health.current), roundi(m.player.health.current)])


func _report() -> void:
	print("DUEL states: ", _visited, "  outcome: ", MatchFlow.Phase.keys()[m.flow.phase])
	print("DUEL log ", m.session_log.write("timeout"))
	var ok: bool = _stuck_events == 0 and _visited.size() >= MIN_STATES
	print("DUEL PASS" if ok else "DUEL FAIL (stuck %d, states %d)" % [_stuck_events, _visited.size()])
	get_tree().quit(0 if ok else 1)
