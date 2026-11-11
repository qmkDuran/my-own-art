class_name EclipseAura
extends Node2D
## While Eclipse lasts: a ring of violet dark around the Lamplighter, wisps rising from it.

const RADIUS: float = 34.0
const SEGMENTS: int = 32

var skill: Eclipse
var _t: float = 0.0


static func attach(p: Player, s: Eclipse) -> void:
	var a := EclipseAura.new()
	a.skill = s
	a.material = Fx.unshaded()
	a.z_index = -14
	a.z_as_relative = false
	p.add_child(a)


func _process(delta: float) -> void:
	_t += delta
	if not skill.active():
		queue_free()
		return
	if int(_t * 10.0) % 3 == 0:
		Fx.burst(Game.current.fx_layer, global_position + Vector2.RIGHT.rotated(randf() * TAU) * RADIUS, 1, Vector2(10, 30), 0.6,
			[Pal.c("violet_lt", 0.8), Pal.c("violet", 0.0)], Vector2.UP, 15.0)
	queue_redraw()


func _draw() -> void:
	var pulse: float = 1.0 + sin(_t * 6.0) * 0.06
	draw_circle(Vector2.ZERO, RADIUS * pulse, Color(Pal.c("void"), 0.35))
	draw_arc(Vector2.ZERO, RADIUS * pulse, 0.0, TAU, SEGMENTS, Color(Pal.c("violet_lt"), 0.7), 1.0)
