extends Node
## --probe (with --demo): reports how the recorded demo went (falls, boss, Nim) so the video can be trusted
## before spending time recording it.

var _falls: int = 0
var _seen: Game


func _process(_delta: float) -> void:
	var g: Game = Game.current
	if g == null:
		return
	if g != _seen:
		_seen = g
		g.player.died_and_rose.connect(func() -> void:
			_falls += 1
			print("PROBE fall at %.1f s game time" % (Engine.get_physics_frames() / 60.0)))
		g.tree_exiting.connect(_report.bind(g))


var _trace_t: float = 0.0


func _physics_process(delta: float) -> void:
	var g: Game = Game.current
	_trace_t -= delta
	if g == null or _trace_t > 0.0 or not OS.get_cmdline_user_args().has("--trace"):
		return
	_trace_t = 0.5
	var near: Dictionary = {}
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.global_position.distance_to(g.player.global_position) < 200.0:
			near[e.kind + "/" + e.rank] = int(near.get(e.kind + "/" + e.rank, 0)) + 1
	print("TRACE %.1f %s life %d light %d tonics %d near %s" % [Engine.get_physics_frames() / 60.0, g.zone_id, g.player.life,
		g.player.light.value, g.player.tonics, near])


func _report(g: Game) -> void:
	print("PROBE %s: falls %d  boss_down %s  level %d  quests %s" % [g.zone_id, _falls, g.flags.has("boss_down"), g.player.prog.level,
		Session.campaign.quests])
