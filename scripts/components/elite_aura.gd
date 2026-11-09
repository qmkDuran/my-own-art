class_name EliteAura
extends Node2D
## An elite's aura: a slow cyan pulse on the ground at its feet and a few light pixels
## drifting up. Quieter than attack cues and the boss's aura (see DESIGN.md, "Visual hierarchy").
## BossAura builds on it.

const RING_ALPHA_SWING := 0.5
## Blinking pixels: blinks per second of a pixel's life, and the share of each blink it's off.
const BLINK_RATE := 7.0
const BLINK_OFF_SHARE := 0.2

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

## The ground ring's shape through one pulse: its size runs from `ring_scale_low` to
## `ring_scale_low + ring_scale_swing` times `pulse_size`, and its alpha from
## `ring_alpha_low` to `ring_alpha_low + RING_ALPHA_SWING` times `max_alpha`.
var ring_scale_low: float = 0.85
var ring_scale_swing: float = 0.25
var ring_alpha_low: float = 0.35
## Straight segments the ground ring is drawn with.
var ring_segments: int = 20
## How far above the feet the pixels start, in pixels.
var pixel_start_height: float = 3.0
## Whether the pixels blink on and off now and then, like a signal.
var pixels_blink: bool = false

var _elapsed: float = 0.0
## Each pixel: { "x": float, "age": float, "color": Color }
var _pixels: Array[Dictionary] = []


func _ready() -> void:
	for pixel_number in pixel_count:
		_add_pixel_at_random_age()


func _process(delta: float) -> void:
	_elapsed += delta
	for index in _pixels.size():
		_pixels[index]["age"] += delta
		if _pixels[index]["age"] >= pixel_lifetime:
			_pixels[index] = _new_pixel(0.0)
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 - 0.5 * cos(TAU * _elapsed / pulse_period)
	var ring_size := pulse_size * (ring_scale_low + ring_scale_swing * pulse)
	var ring_alpha := max_alpha * (ring_alpha_low + RING_ALPHA_SWING * pulse)
	_draw_ellipse_outline(ring_size, Color(ApolloPalette.SKY, ring_alpha))
	for pixel in _pixels:
		var age: float = pixel["age"]
		if pixels_blink and fmod(age * BLINK_RATE, 1.0) < BLINK_OFF_SHARE:
			continue
		var progress := age / pixel_lifetime
		var at := Vector2(pixel["x"], -pixel_start_height - pixel_rise * progress).round()
		var pixel_color: Color = pixel["color"]
		draw_rect(Rect2(at, Vector2.ONE), Color(pixel_color, max_alpha * sin(PI * progress)))


func _add_pixel_at_random_age() -> void:
	_pixels.append(_new_pixel(randf() * pixel_lifetime))


func _draw_ellipse_outline(ellipse_size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for segment in ring_segments + 1:
		var angle := TAU * segment / ring_segments
		points.append(Vector2(cos(angle) * ellipse_size.x / 2.0, sin(angle) * ellipse_size.y / 2.0))
	draw_polyline(points, color, 1.0)


func _new_pixel(age: float) -> Dictionary:
	return {"x": roundf(randf_range(-pixel_spread, pixel_spread)), "age": age, "color": colors.pick_random()}
