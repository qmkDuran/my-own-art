extends Node
## --probe (with --demo): reports how the recorded demo went (falls, boss, Nim) so the video can be trusted
## before spending time recording it.

var _falls: int = 0
var _hooked: bool = false


func _process(_delta: float) -> void:
	var g: Game = Game.current
	if g == null:
		return
	if not _hooked:
		_hooked = true
		g.player.died_and_rose.connect(func() -> void:
			_falls += 1
			print("PROBE fall at %.1f s game time" % (Engine.get_physics_frames() / 60.0)))
		g.tree_exiting.connect(_report.bind(g))


func _report(g: Game) -> void:
	print("PROBE falls %d  boss_down %s  slice_done %s  level %d" % [_falls, g.flags.has("boss_down"), g.flags.has("slice_done"), g.player.prog.level])
