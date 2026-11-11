extends Node
## --replay: Act 1 end to end through the real game. From the title screen (New Game, the intro cards) the
## DemoBot plays each main-quest step in turn: it is moved to where the tracker points (the marker's target, or
## the exit toward another zone — walking between places is skipped, the places are not), then does the step for real: talks through
## the dialogue, uses the exit, walks into the boss ring and fights, relights lamps and holds them through their
## waves. The character is levelled and geared to each zone's intended level on arrival. Prints one REPLAY line
## per step and REPLAY PASS / FAIL; any step that does not move the quest on within its time is a failure.

const LAST: Array = ["moth_hollow", 2]            ## Act 1 ends when this step is done (back to Ottilie)
const STEP_TIMEOUT: float = 150.0
const POLL: float = 0.25
const RETURN_RANGE: float = 600.0                  ## after a death, the bot is walked back if it woke farther
const BOSS_STAND: Vector2 = Vector2(0, 120)
const MAX_STEPS: int = 20

var g: Game
var _deaths: int = 0
var _fails: Array[String] = []
var _zone_built: String = ""
var _played: float = 0.0
var _steps: int = 0
var _boss_built: String = ""


func _ready() -> void:
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, false).timeout


func _run() -> void:
	await _title()
	add_child(DemoBot.new())
	for i: int in MAX_STEPS:
		if Session.campaign.past(String(LAST[0]), int(LAST[1])):
			break
		await _play_step()
	var done: bool = Session.campaign.past(String(LAST[0]), int(LAST[1]))
	if not done:
		_fails.append("Act 1 did not finish")
	elif not Session.campaign.active().has("upward_river"):
		_fails.append("Act 2 (The Upward River) did not open after Act 1")
	print("REPLAY %s: Act 1 in %d steps, %.0f s of play, deaths %d%s" % ["PASS" if _fails.is_empty() else "FAIL",
		_steps, _played, _deaths, "" if _fails.is_empty() else " | " + " | ".join(_fails)])
	get_tree().quit(0 if _fails.is_empty() else 1)


## The title screen: New Game, then every intro card, into the game.
func _title() -> void:
	await _wait(0.5)
	var title: Node = get_tree().current_scene
	title.call("_choose", "new")
	for i: int in 20:
		if Game.current != null:
			break
		title.call("_next_card")
		await _wait(0.1)
	while Game.current == null:
		await get_tree().process_frame
	await _wait(1.0)
	_attach()


func _attach() -> void:
	g = Game.current
	if not g.player.died_and_rose.is_connected(_on_died):
		g.player.died_and_rose.connect(_on_died)
	if _zone_built != g.zone_id:
		_zone_built = g.zone_id
		var lv: Array = GameData.zone(g.zone_id)["level"]
		var level: int = maxi(g.player.prog.level, int((int(lv[0]) + int(lv[1])) / 2))
		ShotHelper.new(g).player_build(level)


func _on_died() -> void:
	_deaths += 1


## One step of the main quest: go where the tracker points and do what it says, until the step moves on.
func _play_step() -> void:
	var id: String = Session.campaign.active()[0]
	var index: int = Session.campaign.step_index(id)
	var st: Dictionary = Session.campaign.step(id)
	var t: float = 0.0
	var deaths0: int = _deaths
	while Session.campaign.step_index(id) == index and not Session.campaign.is_done(id) and t < STEP_TIMEOUT:
		await _act(st)
		await _wait(POLL)
		t += POLL
	var ok: bool = Session.campaign.step_index(id) != index or Session.campaign.is_done(id)
	_steps += 1
	_played += t
	print("REPLAY %s %d \"%s\" in %s at level %d: %s (%.0f s, deaths %d)" % [id, index, st["text"], g.zone_id,
		g.player.prog.level, "ok" if ok else "STUCK", t, _deaths - deaths0])
	if not ok:
		_fails.append("%s step %d stuck in %s" % [id, index, g.zone_id])


func _act(st: Dictionary) -> void:
	_clear_modal()
	if String(st["target"]["zone"]) != g.zone_id:
		await _travel(String(st["target"]["zone"]))
		return
	var goal: Array = st["goal"]
	var at: Vector2 = Objectives.place(g, String(st["target"]["at"]))
	match String(goal[0]):
		"talk": _talk(String(goal[1]))
		"boss_seen", "boss_down": _to_ring()
		"lamp_lit": _relight(at)
		"enter_zone": await _travel(String(goal[1]))


## Dialogue and notes are read through, as a player clicking on.
func _clear_modal() -> void:
	for i: int in 30:
		if not g.hud.messages.advance():
			return


func _talk(npc: String) -> void:
	for n: Node in get_tree().get_nodes_in_group("interactables"):
		if n is Npc and (n as Npc).npc_id == npc:
			ShotHelper.new(g).place_player((n as Npc).stand_point())
			(n as Npc).use(g)
			_clear_modal()
			return


func _travel(zone: String) -> void:
	var hop: String = Objectives.next_hop(g.zone_id, zone)
	for e: ZoneExit in g.exits:
		if e.to == hop:
			var left: Game = g
			ShotHelper.new(g).place_player(e.stand_point())
			e.use(g)
			while Game.current == left or Game.current == null:
				await get_tree().process_frame
			await _wait(1.0)
			_attach()
			return
	_fails.append("no exit from %s toward %s" % [g.zone_id, zone])


## By the boss a player has reached the top of the zone's range (as in the balance runs).
func _to_ring() -> void:
	if _boss_built != g.zone_id:
		_boss_built = g.zone_id
		ShotHelper.new(g).player_build(int(GameData.zone(g.zone_id)["level"][1]))
	var c: Vector2 = g.layout.circle_center()
	if g.player.global_position.distance_to(c) > RETURN_RANGE or not g.flags.has("boss"):
		ShotHelper.new(g).place_player(c + BOSS_STAND)


## Stand at the nearest unlit lamp and light it; the bot holds it through the waves.
func _relight(at: Vector2) -> void:
	for l: Waylamp in g.lamps:
		if l.global_position.distance_to(at) < 1.0 and not l.lit:
			if g.player.global_position.distance_to(l.global_position) > RETURN_RANGE * 0.5:
				ShotHelper.new(g).place_player(l.stand_point())
			if not l.relighting:
				l.use(g)
			return
