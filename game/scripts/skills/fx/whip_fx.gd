class_name WhipFx
extends Node2D
## The light-whip: a curved cord of sunfire from the lantern that sweeps across the arc toward the cursor and
## leaves a fading trail. Additive and unlit (it is light), with a flash where the tip cracks.

const SWEEP: float = 0.11
const FADE: float = 0.14
const TRAIL: int = 10
const SEGMENTS: int = 14
const LAG: float = 0.35

var origin: Vector2                  ## lantern, relative to `center`
var reach: float
var a0: float
var a1: float
var heavy: bool = false
var _t: float = 0.0
var _trail: Array[Vector2] = []


static func lash(parent: Node, center: Vector2, lantern: Vector2, dir: Vector2, reach_px: float, arc_deg: float, flip: bool,
		crack: bool) -> WhipFx:
	var w := WhipFx.new()
	w.position = center
	w.origin = lantern - center
	w.reach = reach_px
	var half: float = deg_to_rad(arc_deg) * 0.5
	w.a0 = dir.angle() + (half if flip else -half)
	w.a1 = dir.angle() + (-half if flip else half)
	w.heavy = crack
	w.material = Fx.glow_material()
	w.z_index = Fx.FX_Z
	parent.add_child(w)
	return w


func _process(delta: float) -> void:
	_t += delta
	if _t < SWEEP:
		_trail.push_front(_tip(_t / SWEEP))
		if _trail.size() > TRAIL:
			_trail.pop_back()
	if _t > SWEEP + FADE:
		queue_free()
	queue_redraw()


func _tip(k: float) -> Vector2:
	var e: float = 1.0 - pow(1.0 - k, 3.0)
	return Vector2.RIGHT.rotated(lerpf(a0, a1, e)) * reach


func _cord(tip: Vector2, k: float) -> PackedVector2Array:
	var lag_a: float = lerpf(a0, a1, maxf(0.0, k - LAG))
	var ctrl: Vector2 = Vector2.RIGHT.rotated(lag_a) * reach * 0.55
	var pts := PackedVector2Array()
	for i: int in SEGMENTS + 1:
		var s: float = float(i) / SEGMENTS
		pts.append(origin.lerp(ctrl, s).lerp(ctrl.lerp(tip, s), s))
	return pts


func _draw() -> void:
	var k: float = minf(1.0, _t / SWEEP)
	var fade: float = 1.0 - clampf((_t - SWEEP) / FADE, 0.0, 1.0)
	if _trail.size() > 1:
		draw_polyline(PackedVector2Array(_trail), Color(Pal.c("flame"), 0.35 * fade), 10.0 if heavy else 7.0)
		draw_polyline(PackedVector2Array(_trail), Color(Pal.c("amber"), 0.6 * fade), 3.0)
	var cord: PackedVector2Array = _cord(_tip(k), k)
	draw_polyline(cord, Color(Pal.c("flame"), 0.3 * fade), 6.0)
	draw_polyline(cord, Color(Pal.c("gold"), 0.9 * fade), 2.0)
	draw_polyline(cord, Color(Pal.c("sun"), fade), 1.0)
	draw_circle(_tip(k), (5.0 if heavy else 3.0) * fade, Color(Pal.c("sun"), fade))
