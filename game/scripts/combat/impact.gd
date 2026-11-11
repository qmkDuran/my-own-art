class_name Impact
extends RefCounted
## The weight of a hit, scaled by how big it was (`k`: the hit's share of the target's life, 0..1), sized to read
## at 1x: a white core for two frames, a halo, a shockwave ring on the ground, a strong light pulse on the floor,
## 10-20 sparks along the blow and embers, a scorch that fades, a 2-4 frame hit-stop (3-5 on a kill), and on big
## hits, crits and kills a shake plus a punch of the view toward the target.

const FRAME: float = 1.0 / 60.0
const STOP_FRAMES := Vector2(2.0, 4.0)
const KILL_STOP_FRAMES := Vector2(3.0, 5.0)
const KICK_AT: float = 0.18             ## hits worth this share of a life or more kick the camera
const KICK: float = 0.18
const PUNCH := Vector2(3.0, 7.0)        ## px the view lurches toward the target on big hits and kills
const BURST_R := Vector2(30.0, 38.0)    ## the impact's radius (60-76 px across), small hit to big
const CORE_TIME: float = 0.06           ## a few frames of white at the point of contact
const RING_TIME: float = 0.24
const GROUND_LIGHT := Vector2(120.0, 180.0)
const SPARKS := Vector2(10.0, 20.0)
const SCORCH_TIME: float = 2.4
const SCORCH_MIN: float = 14.0
const SCORCH_MAX: float = 26.0


## `sparks` recolours the sparks and embers (light, mid, fading dark), e.g. by a creature's element; gold by default.
static func hit(at: Vector2, dir: Vector2, k: float, col: Color, crit: bool, kill: bool = false, sparks: Array[Color] = []) -> void:
	var fx: Node2D = Fx.layer
	k = clampf(k, 0.0, 1.0)
	var big: float = maxf(k * 3.0, 1.0 if kill or crit else 0.0)
	var r: float = lerpf(BURST_R.x, BURST_R.y, minf(big, 1.0))
	Fx.core(fx, at, r * 0.9, CORE_TIME)
	Fx.halo(fx, at, r * 2.2, Color(col, 1.0), 0.26)
	Fx.ring(fx, at + Vector2(0, 10), r * 0.4, r * 2.2, Color(Pal.c("sun"), 1.0), RING_TIME)
	Fx.flash(fx, at + Vector2(0, 10), lerpf(GROUND_LIGHT.x, GROUND_LIGHT.y, minf(big, 1.0)), col, 3.0 + k * 2.0, 0.32)
	var n: int = int(lerpf(SPARKS.x, SPARKS.y, minf(big, 1.0)))
	var cols: Array[Color] = sparks if sparks.size() == 3 else [Pal.c("sun"), Pal.c("gold"), Pal.c("flame", 0.0)]
	Fx.burst(fx, at, n, Vector2(120, 280), 0.36, cols, dir, 70.0, Vector2(1.5, 2.5))
	Fx.burst(fx, at, n / 2 + 4, Vector2(50, 150), 0.6, [cols[1], Color(cols[2], 1.0), Color(cols[2], 0.0)],
		Vector2.UP, 180.0, Vector2(1, 2))
	scorch(at + Vector2(0, 14), lerpf(SCORCH_MIN, SCORCH_MAX, minf(big, 1.0)))
	var stop: Vector2 = KILL_STOP_FRAMES if kill else STOP_FRAMES
	HitStop.trigger(fx.get_tree(), FRAME * lerpf(stop.x, stop.y, minf(big, 1.0)) * (1.25 if crit else 1.0))
	if k >= KICK_AT or crit or kill:
		CameraRig.shake(KICK * (0.6 + k))
		CameraRig.punch(dir * lerpf(PUNCH.x, PUNCH.y, minf(big, 1.0)))


## A dark mark on the floor where the light struck; it fades away.
static func scorch(at: Vector2, r: float) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.shadow()
	s.position = at
	s.scale = Vector2(r / 12.0, r / 20.0)
	s.modulate = Color(0.12, 0.06, 0.04, 0.8)
	s.z_index = -14
	s.z_as_relative = false
	Fx.layer.add_child(s)
	var tw := s.create_tween()
	tw.tween_interval(SCORCH_TIME * 0.5)
	tw.tween_property(s, "modulate:a", 0.0, SCORCH_TIME * 0.5)
	tw.tween_callback(s.queue_free)
