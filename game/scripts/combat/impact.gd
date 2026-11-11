class_name Impact
extends RefCounted
## The weight of a hit, scaled by how big it was (`k`: the hit's share of the target's life, 0..1): an expanding
## flash and a light pulse on the ground, sparks along the blow, an ember burst, a scorch on the floor that fades,
## a 2-4 frame hit-stop, and a camera kick on big hits.

const FRAME: float = 1.0 / 60.0
const STOP_FRAMES := Vector2(2.0, 4.0)
const KICK_AT: float = 0.18             ## hits worth this share of a life or more kick the camera
const KICK: float = 0.18
const SCORCH_TIME: float = 2.4
const SCORCH_MIN: float = 9.0
const SCORCH_MAX: float = 22.0


static func hit(at: Vector2, dir: Vector2, k: float, col: Color, crit: bool) -> void:
	var g: Game = Game.current
	k = clampf(k, 0.0, 1.0)
	var size: float = 0.8 + k * 1.6 + (0.4 if crit else 0.0)
	Fx.halo(g.fx_layer, at, 26.0 * size, Color(col, 0.85), 0.18)
	Fx.flash(g.fx_layer, at, 50.0 * size, col, 0.9 + k, 0.16)
	Fx.hit_sparks(g.fx_layer, at, dir, crit)
	Fx.burst(g.fx_layer, at, int(4 + 10 * k), Vector2(30, 110 * size), 0.45, [Pal.c("gold"), Pal.c("flame"), Pal.c("ember", 0.0)],
		Vector2.UP, 160.0, Vector2(1, 2))
	scorch(at + Vector2(0, 14), lerpf(SCORCH_MIN, SCORCH_MAX, k))
	HitStop.trigger(g.get_tree(), FRAME * lerpf(STOP_FRAMES.x, STOP_FRAMES.y, k) * (1.5 if crit else 1.0))
	if k >= KICK_AT or crit:
		CameraRig.shake(KICK * (0.6 + k))


## A dark mark on the floor where the light struck; it fades away.
static func scorch(at: Vector2, r: float) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.shadow()
	s.position = at
	s.scale = Vector2(r / 12.0, r / 20.0)
	s.modulate = Color(0.12, 0.06, 0.04, 0.8)
	s.z_index = -14
	s.z_as_relative = false
	Game.current.fx_layer.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(SCORCH_TIME * 0.5)
	tw.tween_property(s, "modulate:a", 0.0, SCORCH_TIME * 0.5)
	tw.tween_callback(s.queue_free)
