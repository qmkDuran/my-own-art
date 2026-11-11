class_name RingWave
extends Node2D
## A toll of the bell: a ring of sound rolling outward. It hurts whoever stands on its edge as it passes (once per
## ring); it has gaps you can stand in, and Wickstep carries you through it untouched.

const WIDTH: float = 10.0
const GAPS: int = 3
const GAP_ARC: float = 0.45
const SEGMENTS: int = 72
const FADE_TAIL: float = 0.3

var speed: float
var max_r: float
var dmg: float
var r: float = 20.0
var _offset: float
var _hit: bool = false
var _src: int


static func spawn(parent: Node, at: Vector2, d: Dictionary, src: Enemy) -> RingWave:
	var w := RingWave.new()
	w.position = at
	w.speed = float(d["ring_speed"])
	w.max_r = float(d["ring_reach"])
	w.dmg = src.damage * float(d["ring_mult"])
	w._offset = randf() * TAU
	w._src = src.get_instance_id()
	w.z_index = -14
	w.z_as_relative = false
	w.material = Fx.glow_material()
	parent.add_child(w)
	return w


func _process(delta: float) -> void:
	r += speed * delta
	if r > max_r:
		queue_free()
		return
	var p: Player = Game.current.player
	var v: Vector2 = p.global_position - global_position
	if not _hit and absf(v.length() - r) < WIDTH + p.radius * 0.5 and not in_gap(v.angle()):
		_hit = true
		Combat.hit_player(instance_from_id(_src) as Enemy, dmg, "dusk", global_position)
	queue_redraw()


func in_gap(a: float) -> bool:
	for k: int in GAPS:
		var g: float = _offset + TAU * k / GAPS
		if absf(angle_difference(a, g)) < GAP_ARC * 0.5:
			return true
	return false


func _draw() -> void:
	var fade: float = clampf((1.0 - r / max_r) / FADE_TAIL, 0.0, 1.0)
	for k: int in GAPS:
		var a0: float = _offset + TAU * k / GAPS + GAP_ARC * 0.5
		var a1: float = _offset + TAU * (k + 1) / GAPS - GAP_ARC * 0.5
		draw_arc(Vector2.ZERO, r, a0, a1, SEGMENTS / GAPS, Color(Pal.c("flame"), 0.35 * fade), 9.0)
		draw_arc(Vector2.ZERO, r, a0, a1, SEGMENTS / GAPS, Color(Pal.c("gold"), 0.85 * fade), 3.0)
		draw_arc(Vector2.ZERO, r, a0, a1, SEGMENTS / GAPS, Color(Pal.c("sun"), 0.5 * fade), 1.0)
