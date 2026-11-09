class_name EliteAura
extends Node2D
## An elite's aura: a slow cyan pulse on the ground at its feet and a few light pixels
## drifting up. Quieter than attack cues and the boss's aura (see DESIGN.md, "Visual hierarchy").

## Size of the ground pulse, in pixels (width, height of the ellipse).
@export var pulse_size: Vector2 = Vector2(14, 5)
## Seconds for one slow pulse.
@export var pulse_period: float = 2.0
@export var pixel_count: int = 3
## How far from the centre the pixels start, sideways, in pixels.
@export var pixel_spread: float = 7.0
## How far the pixels rise before fading, in pixels.
@export var pixel_rise: float = 14.0
## Seconds a pixel takes to rise and fade.
@export var pixel_lifetime: float = 1.5
@export var colors: Array[Color] = [ApolloPalette.SKY, ApolloPalette.SKY_LIGHT]
## The highest the pulse and the pixels get.
@export var max_alpha: float = 0.5

const ELLIPSE_STEPS := 20

var _elapsed: float = 0.0
## Each pixel: { "x": float, "age": float, "color": Color }
var _pixels: Array[Dictionary] = []


func _ready() -> void:
	for pixel_number in pixel_count:
		_pixels.append(_new_pixel(randf() * pixel_lifetime))


func _process(delta: float) -> void:
	_elapsed += delta
	for index in _pixels.size():
		_pixels[index]["age"] += delta
		if _pixels[index]["age"] >= pixel_lifetime:
			_pixels[index] = _new_pixel(0.0)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 - 0.5 * cos(TAU * _elapsed / pulse_period)
	var ring_size := pulse_size * (0.85 + 0.25 * pulse)
	var points := PackedVector2Array()
	for step in ELLIPSE_STEPS + 1:
		var angle := TAU * step / ELLIPSE_STEPS
		points.append(Vector2(cos(angle) * ring_size.x / 2.0, sin(angle) * ring_size.y / 2.0))
	draw_polyline(points, Color(ApolloPalette.SKY, max_alpha * (0.35 + 0.5 * pulse)), 1.0)
	for pixel in _pixels:
		var progress: float = pixel["age"] / pixel_lifetime
		var at := Vector2(pixel["x"], -3.0 - pixel_rise * progress).round()
		draw_rect(Rect2(at, Vector2.ONE), Color(pixel["color"], max_alpha * sin(PI * progress)))


func _new_pixel(age: float) -> Dictionary:
	return {"x": roundf(randf_range(-pixel_spread, pixel_spread)), "age": age, "color": colors.pick_random()}
