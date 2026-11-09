class_name CaptainAura
extends Node2D
## The Captain's elite aura (only elites and bosses get one, see DESIGN.md "Visual hierarchy"):
## a slow cyan pulse on the ground at his feet and a few data-pixels drifting up around him,
## blinking like a signal. Quiet, but it marks him as dangerous. Phase 2 makes it busier.
## Sits behind his sprite; it hides itself when he dies.

## Size of the ground pulse, in pixels (width, height of the ellipse).
@export var pulse_size: Vector2 = Vector2(16, 5)
## Seconds for one slow pulse.
@export var pulse_period: float = 2.4
## How many data-pixels drift around him (doubled in phase 2).
@export var pixel_count: int = 5
## How far from his centre the pixels start, sideways, in pixels.
@export var pixel_spread: float = 11.0
## How far the pixels rise before fading, in pixels.
@export var pixel_rise: float = 18.0
## Seconds a pixel takes to rise and fade.
@export var pixel_lifetime: float = 1.8
@export var colors: Array[Color] = [ApolloPalette.SKY, ApolloPalette.SKY_LIGHT]
## The highest the pulse and the pixels get, so the aura stays quieter than attack cues.
@export var max_alpha: float = 0.55

var _elapsed: float = 0.0
## Each pixel: { "x": float, "age": float, "color": Color }
var _pixels: Array[Dictionary] = []
var _active_pixels: int = 0
## `max_alpha` before phase 2 strengthened it.
var _calm_max_alpha: float = 0.0


func _ready() -> void:
	_calm_max_alpha = max_alpha
	_active_pixels = pixel_count
	for pixel_number in _active_pixels:
		_pixels.append(_new_pixel(randf() * pixel_lifetime))


## Back to the phase-1 aura (the fight reset after the player fell).
func calm() -> void:
	_active_pixels = pixel_count
	max_alpha = _calm_max_alpha
	_pixels.resize(mini(_pixels.size(), _active_pixels))


## Phase 2: twice the data-pixels and a stronger pulse.
func intensify() -> void:
	_active_pixels = pixel_count * 2
	max_alpha = minf(1.0, max_alpha * 1.4)
	while _pixels.size() < _active_pixels:
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
	var ring_scale := 0.8 + 0.3 * pulse
	_draw_ellipse_outline(pulse_size * ring_scale, Color(ApolloPalette.SKY, max_alpha * (0.3 + 0.5 * pulse)))
	for pixel in _pixels:
		var progress: float = pixel["age"] / pixel_lifetime
		# Blinks on and off now and then, like a signal.
		if fmod(pixel["age"] * 7.0, 1.0) < 0.2:
			continue
		var position_now := Vector2(pixel["x"], -4.0 - pixel_rise * progress).round()
		var alpha := max_alpha * sin(PI * progress)
		draw_rect(Rect2(position_now, Vector2.ONE), Color(pixel["color"], alpha))


func _draw_ellipse_outline(size: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 24
	for step in steps + 1:
		var angle := TAU * step / steps
		points.append(Vector2(cos(angle) * size.x / 2.0, sin(angle) * size.y / 2.0))
	draw_polyline(points, color, 1.0)


func _new_pixel(age: float) -> Dictionary:
	return {"x": roundf(randf_range(-pixel_spread, pixel_spread)), "age": age, "color": colors.pick_random()}
