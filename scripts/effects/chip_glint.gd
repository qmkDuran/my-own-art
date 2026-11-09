class_name ChipGlint
extends Node2D
## The cyan glint of an implanted control chip (at the Warden Captain's temple), shown only
## while it fails: `flicker` makes it blink, faster and faster, as the chip overloads; `crack`
## leaves it dead grey with a stray spark now and then. Chips are otherwise invisible in the
## art (see DESIGN.md), so this sits on the sprite as its own tiny effect.

## Blinks per second when it starts to flicker, and just before it cracks.
const BLINK_RATE := Vector2(4.0, 18.0)
## Chance per frame that the cracked chip throws a one-pixel spark.
const CRACKED_SPARK_CHANCE := 0.06
## How far a stray spark lands from the chip, in pixels.
const CRACKED_SPARK_REACH := 3

enum Look { HIDDEN, FLICKERING, CRACKED }

var _look: Look = Look.HIDDEN
var _elapsed: float = 0.0
var _flicker_seconds: float = 1.0


func _ready() -> void:
	z_index = 1


## Starts blinking; the blinks speed up over `seconds` (the time until it cracks).
func flicker(seconds: float) -> void:
	_look = Look.FLICKERING
	_elapsed = 0.0
	_flicker_seconds = maxf(seconds, 0.01)


## The chip is broken: the light goes out, the odd spark stays.
func crack() -> void:
	_look = Look.CRACKED


func _process(delta: float) -> void:
	if _look == Look.HIDDEN:
		return
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	match _look:
		Look.FLICKERING:
			var progress := minf(_elapsed / _flicker_seconds, 1.0)
			var rate := lerpf(BLINK_RATE.x, BLINK_RATE.y, progress)
			if fmod(_elapsed * rate, 1.0) < 0.6:
				_draw_halo(ApolloPalette.SKY)
				_draw_chip(ApolloPalette.WHITE, ApolloPalette.SKY_LIGHT)
		Look.CRACKED:
			_draw_chip(ApolloPalette.GREY, ApolloPalette.STONE_LIGHT)
			if randf() < CRACKED_SPARK_CHANCE:
				var spark := Vector2(randi_range(-CRACKED_SPARK_REACH, CRACKED_SPARK_REACH), randi_range(-CRACKED_SPARK_REACH, 0))
				draw_rect(Rect2(spark, Vector2.ONE), ApolloPalette.WHITE)


## A one-pixel glow on each side of the 2×2 chip, so it reads against his blue hood.
func _draw_halo(glow: Color) -> void:
	for pixel: Vector2 in [Vector2(-1, 0), Vector2(-1, 1), Vector2(2, 0), Vector2(2, 1), Vector2(0, -1), Vector2(1, -1), Vector2(0, 2), Vector2(1, 2)]:
		draw_rect(Rect2(pixel, Vector2.ONE), glow)


## A 2×2 chip: one bright pixel, three in its glow colour.
func _draw_chip(bright: Color, glow: Color) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(2, 2)), glow)
	draw_rect(Rect2(Vector2.ZERO, Vector2.ONE), bright)
