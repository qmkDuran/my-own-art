class_name SmokeArrival
extends Node2D
## Demons come as streaks of black smoke flying in on curving paths; the streaks swirl together and the creature
## takes shape, landing with a dark burst and dust. Reversed, a demon leaves the same way. Drawn by code.

const FLY: float = 0.85
const SWIRL: float = 0.4
const STREAKS: int = 3
const TRAIL: int = 14

var demon: Demon
var leaving: bool = false
var _t: float = 0.0
var _paths: Array = []          # per streak: [start, control, end]
var _trails: Array = []         # per streak: PackedVector2Array of recent head positions


static func arrive(parent: Node, d: Demon, delay: float = 0.0) -> SmokeArrival:
	var a := SmokeArrival.new()
	a.demon = d
	a._t = -delay
	d.set_present(false)
	parent.add_child(a)
	return a


static func depart(parent: Node, d: Demon) -> SmokeArrival:
	var a := SmokeArrival.new()
	a.demon = d
	a.leaving = true
	d.set_present(false)
	Fx.shadow_puff(parent, d.global_position + Vector2(0, -24))
	parent.add_child(a)
	return a


func _ready() -> void:
	z_index = 12
	var end: Vector2 = demon.global_position + Vector2(0, -26)
	for i: int in STREAKS:
		var ang: float = randf_range(-PI * 0.9, -PI * 0.1) + (i - 1) * 0.5
		var start: Vector2 = end + Vector2(cos(ang) * randf_range(260, 380), sin(ang) * randf_range(180, 260))
		var ctrl: Vector2 = (start + end) / 2.0 + Vector2(randf_range(-160, 160), randf_range(-120, 40))
		_paths.append([end, ctrl, start] if leaving else [start, ctrl, end])
		_trails.append(PackedVector2Array())
	if leaving:
		Audio.sfx("dash", -12.0, 0.6)


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.0:
		return
	var total: float = FLY + (0.0 if leaving else SWIRL)
	for i: int in _paths.size():
		var head: Vector2 = _head(i)
		var tr: PackedVector2Array = _trails[i]
		tr.append(head)
		if tr.size() > TRAIL:
			tr.remove_at(0)
		_trails[i] = tr
	if _t >= total:
		if leaving:
			if is_instance_valid(demon):
				demon.queue_free()
		elif is_instance_valid(demon):
			demon.set_present(true)
			Impact.death(get_parent(), demon.global_position + Vector2(0, -16), demon.rim_color(), false)
			Impact.blast(get_parent(), demon.global_position, 34.0, Color(0.3, 0.2, 0.4), 0.5)
			Audio.sfx("burst", -12.0, 0.7)
		queue_free()
	queue_redraw()


## Where streak i's head is now: along its curve, then (arriving) circling in to the landing point.
func _head(i: int) -> Vector2:
	var p: Array = _paths[i]
	var k: float = clampf(_t / FLY, 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var a: Vector2 = (p[0] as Vector2).lerp(p[1], k)
	var b: Vector2 = (p[1] as Vector2).lerp(p[2], k)
	var pos: Vector2 = a.lerp(b, k)
	if not leaving and _t > FLY:
		var s: float = (_t - FLY) / SWIRL
		var ang: float = s * TAU * 1.5 + i * TAU / STREAKS
		pos = (p[2] as Vector2) + Vector2(cos(ang), sin(ang) * 0.5) * 26.0 * (1.0 - s)
	return pos


func _draw() -> void:
	for tr: PackedVector2Array in _trails:
		for j: int in range(1, tr.size()):
			var f: float = float(j) / tr.size()
			draw_line(tr[j - 1] - global_position, tr[j] - global_position, Color(0.1, 0.06, 0.14, 0.85 * f), 2.0 + 5.0 * f)
		if tr.size() > 0:
			draw_circle(tr[tr.size() - 1] - global_position, 5.0, Color(0.12, 0.07, 0.16, 0.9))
