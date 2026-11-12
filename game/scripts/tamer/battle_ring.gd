class_name BattleRing
extends Node2D
## The glowing barrier a battle forms around itself: your creature and the creatures in the fight stay inside; no
## other wild creature can come in (they are pushed back out). It rises when the battle starts and dissolves at the
## end.

const STEPS: int = 64
const WIDTH: float = 3.0
const RISE: float = 0.35
const PAD: float = 4.0

var radius: float = 260.0
var inside: Array[Creature] = []        ## those who fight in it
var _k: float = 0.0
var _t: float = 0.0


func raise(at: Vector2, r: float, fighters: Array[Creature]) -> void:
	global_position = at
	radius = r
	inside = fighters
	visible = true
	z_index = Fx.FX_Z - 3
	material = Fx.glow_material()
	create_tween().tween_property(self, "_k", 1.0, RISE)
	Audio.sfx("lamp_lit", -8.0, 0.8)


func dissolve() -> void:
	inside.clear()
	var tw := create_tween()
	tw.tween_property(self, "_k", 0.0, RISE)
	tw.tween_callback(func() -> void: visible = false)


func up() -> bool:
	return visible and _k > 0.0 and not inside.is_empty()


func _physics_process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()
	if not up():
		return
	for n: Node in get_tree().get_nodes_in_group("creatures"):
		var c := n as Creature
		if c.fainted_now:
			continue
		var off: Vector2 = c.global_position - global_position
		var r: float = radius - c.hit_radius() - PAD
		var mine: bool = inside.has(c) or c.side == Combatant.SIDE_TEAM
		if mine and off.length() > r:
			c.global_position = global_position + off.limit_length(r)
		elif not mine and off.length() < radius + c.hit_radius() + PAD:
			c.global_position = global_position + off.normalized() * (radius + c.hit_radius() + PAD)


func _draw() -> void:
	if _k <= 0.0:
		return
	var col: Color = Pal.c("amber", 0.7 * _k)
	var pts := PackedVector2Array()
	for i: int in STEPS + 1:
		var a: float = TAU * i / STEPS
		pts.append(Vector2(cos(a), sin(a) * Fx.RING_SQUASH) * radius * (0.6 + 0.4 * _k))
	draw_polyline(pts, Color(col, col.a * 0.4), WIDTH * 3.0)
	draw_polyline(pts, col, WIDTH)
	for i: int in 12:                                       # sparks running round the barrier
		var a: float = _t * 0.8 + TAU * i / 12.0
		draw_circle(Vector2(cos(a), sin(a) * Fx.RING_SQUASH) * radius, 2.0, Pal.c("sun", _k))
