class_name ToxicSplat
extends Node2D
## A toad bursting into toxic goo: droplets fly out and a small puddle fades on the ground.
##
## Spawn it where the toad died and call play(). It removes itself when done.

@export var droplet_count: int = 14
## How long the puddle stays before it has fully faded, in seconds.
@export var puddle_time: float = 1.2
## Puddle size in pixels (width, height); it's a flat ellipse on the ground.
@export var puddle_size: Vector2 = Vector2(14, 5)
@export var dark_goo: Color = ApolloPalette.GREEN
@export var light_goo: Color = ApolloPalette.GREEN_LIGHT

var _elapsed: float = 0.0


func play() -> void:
	_burst_droplets()
	var fade := create_tween()
	fade.tween_interval(puddle_time * 0.5)
	fade.tween_property(self, "modulate:a", 0.0, puddle_time * 0.5)
	fade.tween_callback(queue_free)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


## The puddle spreads out quickly, then stays while it fades.
func _draw() -> void:
	var spread := clampf(_elapsed / 0.15, 0.0, 1.0)
	var size := puddle_size * (0.4 + 0.6 * spread)
	_draw_ellipse(Vector2.ZERO, size, dark_goo)
	_draw_ellipse(Vector2(-1, -0.5), size * 0.55, light_goo)


func _draw_ellipse(centre: Vector2, size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for step in 16:
		var angle := TAU * step / 16.0
		points.append(centre + Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	draw_colored_polygon(points, color)


func _burst_droplets() -> void:
	var droplets := CPUParticles2D.new()
	droplets.position = Vector2(0, -5)
	droplets.one_shot = true
	droplets.explosiveness = 1.0
	droplets.amount = droplet_count
	droplets.lifetime = 0.45
	droplets.direction = Vector2.UP
	droplets.spread = 80.0
	droplets.initial_velocity_min = 30.0
	droplets.initial_velocity_max = 65.0
	droplets.gravity = Vector2(0, 220)
	droplets.scale_amount_min = 1.0
	droplets.scale_amount_max = 2.0
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([light_goo, dark_goo, Color(dark_goo, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	droplets.color_ramp = ramp
	add_child(droplets)
	droplets.emitting = true
