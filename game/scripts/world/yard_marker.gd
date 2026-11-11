extends Node2D
## A lit marker on the yard's grass: a gold ring that pulses, with a small flame at its heart.

const R: float = 16.0


func _ready() -> void:
	material = Fx.glow_material()
	z_index = -13


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var k: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	draw_arc(Vector2.ZERO, R + k * 4.0, 0.0, TAU, 32, Pal.c("gold", 0.9), 2.0)
	draw_arc(Vector2.ZERO, R * 0.55, 0.0, TAU, 24, Pal.c("amber", 0.7), 1.0)
	draw_circle(Vector2(0, -2), 3.0, Pal.c("sun"))
