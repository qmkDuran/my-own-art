class_name MayorBrain
extends EnemyBrain
## The Mayor of Tuesday (Act 3 boss). He keeps his distance and keeps time: HANDS (two clock-hand lanes sweep out
## from him, warned first), REWIND (he steps back to where he stood a few seconds ago and gets back the life he
## lost since — unless you hit him hard enough meanwhile), APPOINTMENTS (Repeaters arrive for their four o'clock),
## STOP (time stops for you: a heavy slow). Below half life his hands come in fours.

const STOP_DIM: float = 0.7              ## STOP: the world dims while time holds still
const PATTERN: Array[String] = ["hands", "appointments", "hands", "rewind", "stop", "hands"]
const HOLD: float = 200.0
const HISTORY: float = 4.0
const REWIND_MAX: float = 0.08
const HAND_LEN: float = 360.0
const PHASE2_AT: float = 0.5

var _i: int = 0
var _action: String = ""
var _trail: Array = []                ## [time, position, life]
var _clock: float = 0.0
var phase2: bool = false


func _think(delta: float) -> Vector2:
	var d: Dictionary = e.data
	_clock += delta
	_trail.append([_clock, e.global_position, e.life])
	while not _trail.is_empty() and _clock - float(_trail[0][0]) > HISTORY:
		_trail.pop_front()
	if not phase2 and e.life < e.max_life * PHASE2_AT:
		phase2 = true
		Game.current.hud.notice("The Mayor's watch runs fast — his hands come in fours")
	match state:
		"windup":
			if t <= 0.0:
				_fire(d)
				state = "recover"
				t = float(d["cooldown"])
			return Vector2.ZERO
		"recover":
			if t <= 0.0:
				state = "chase"
				t = float(d["walk"])
			return _keep_distance()
	if t <= 0.0:
		_begin(PATTERN[_i % PATTERN.size()], d)
		_i += 1
		return Vector2.ZERO
	return _keep_distance()


func _keep_distance() -> Vector2:
	var v: Vector2 = to_player()
	return v.normalized() * (v.length() - HOLD) * 0.02 * e.speed + v.normalized().orthogonal() * e.speed * 0.4


func _begin(action: String, d: Dictionary) -> void:
	_action = action
	state = "windup"
	t = float(d["windup"])
	var fx: Node = Game.current.fx_layer
	if action == "hands":
		var n: int = 4 if phase2 else 2
		var a0: float = to_player().angle()
		for k: int in n:
			var dir: Vector2 = Vector2.RIGHT.rotated(a0 + TAU * k / n)
			Telegraph.line(fx, e.global_position, e.global_position + dir * HAND_LEN, t)
		Audio.sfx("boss_wind", -6.0, 1.4)


func _fire(d: Dictionary) -> void:
	match _action:
		"hands":
			_hands(d)
		"rewind":
			_rewind()
		"appointments":
			_appointments(int(d["call"]))
		"stop":
			player().slow(0.75, float(d["stop_time"]))
			Game.current.shift_darkness(Game.current.darkness * STOP_DIM, 0.3, 1.0)
			Game.current.hud.caption("Time stops for you. Not for him.")


## The lanes fire: anyone in one is struck.
func _hands(d: Dictionary) -> void:
	var p: Player = player()
	var fx: Node2D = Game.current.fx_layer
	for n: Node in fx.get_children():
		var tg := n as Telegraph
		if tg != null and tg.lane != Vector2.ZERO and tg.global_position.distance_to(e.global_position) < 4.0:
			Fx.burst(fx, tg.global_position + tg.lane * 0.5, 16, Vector2(40, 140), 0.4, [Pal.c("bone"), Pal.c("gold"), Pal.c("stone", 0.0)],
				tg.lane.normalized(), 20.0)
	Audio.sfx("crack", -2.0, 0.6)
	CameraRig.shake(0.3)
	var a0: float = to_player().angle()
	var count: int = 4 if phase2 else 2
	for k: int in count:
		var dir: Vector2 = Vector2.RIGHT.rotated(a0 + TAU * k / count)
		var q: Vector2 = Geometry2D.get_closest_point_to_segment(p.global_position, e.global_position, e.global_position + dir * HAND_LEN)
		if q.distance_to(p.global_position) < Telegraph.LANE_W:
			Combat.hit_player(e, e.damage * float(d["hand_mult"]), "blunt", e.global_position)


## Back to where he stood HISTORY seconds ago, with the life he had then (capped: hit him hard and it won't all come back).
func _rewind() -> void:
	if _trail.is_empty():
		return
	var then: Array = _trail[0]
	var fx: Node2D = Game.current.fx_layer
	Fx.halo(fx, e.global_position, 60.0, Pal.c("bone", 0.7), 0.4)
	e.global_position = Game.current.layout.free_spot_near(then[1], e.radius)
	e.life = minf(e.max_life, maxf(e.life, minf(float(then[2]), e.life + e.max_life * REWIND_MAX)))
	Fx.halo(fx, e.global_position, 60.0, Pal.c("bone", 0.7), 0.4)
	Game.current.hud.notice("The Mayor winds himself back")
	Audio.sfx("dash", -2.0, 0.5)


func _appointments(n: int) -> void:
	for k: int in n:
		var at: Vector2 = Game.current.layout.free_spot_near(player().global_position + Vector2.RIGHT.rotated(TAU * k / n) * 140.0, 14.0)
		Game.current.spawner.spawn("repeater", at, "normal", [], e.level).wake()
		Fx.burst(Game.current.fx_layer, at, 10, Vector2(20, 70), 0.5, [Pal.c("bone"), Pal.c("pale", 0.0)])
