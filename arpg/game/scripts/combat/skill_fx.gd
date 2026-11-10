class_name SkillFx
extends Node2D
## Hand-drawn visuals: an expanding ring (rebuke, trumpet, landing), a sword arc, and a lasting soft circle
## (the protected light around someone praying).

var kind: String
var radius: float
var color: Color
var arc_dir: float = 0.0
var arc_span: float = 0.0
var life: float
var _t: float = 0.0


static func ring(parent: Node, at: Vector2, r: float, col: Color, seconds: float = 0.45) -> SkillFx:
	return _make(parent, "ring", at, r, col, seconds)


static func arc(parent: Node, at: Vector2, r: float, dir: float, span_deg: float, col: Color) -> SkillFx:
	var f := _make(parent, "arc", at, r, col, 0.18)
	f.arc_dir = dir
	f.arc_span = deg_to_rad(span_deg)
	return f


static func circle(parent: Node, at: Vector2, r: float, col: Color) -> SkillFx:
	var f := _make(parent, "circle", at, r, col, INF)
	f.z_index = -5
	return f


static func _make(parent: Node, k: String, at: Vector2, r: float, col: Color, seconds: float) -> SkillFx:
	var f := SkillFx.new()
	f.kind = k
	f.position = at
	f.radius = r
	f.color = col
	f.life = seconds
	f.z_index = 8
	f.light_mask = 0
	f.material = SpriteFactory.additive()
	parent.add_child(f)
	return f


func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k: float = _t / life if life != INF else 0.0
	var c := Color(color, 1.0 - k)
	match kind:
		"circle":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))      # lies flat on the ground
			var pulse: float = 0.6 + 0.25 * sin(_t * 2.0)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color, 0.5 * pulse), 2.0)
			draw_circle(Vector2.ZERO, radius, Color(color, 0.07 * pulse))
		"ring":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
			var r: float = radius * (0.3 + 0.7 * k)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, c, 4.0)
			draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 64, Color(c, c.a * 0.4), 2.0)
		"arc":
			var a0: float = arc_dir - arc_span / 2.0
			var sweep: float = arc_span * minf(1.0, k * 2.0)
			for i: int in 3:
				draw_arc(Vector2.ZERO, radius - i * 7.0, a0, a0 + sweep, 24, Color(c, c.a * (1.0 - i * 0.3)), 4.0 - i)
