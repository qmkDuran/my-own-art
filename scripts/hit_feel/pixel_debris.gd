class_name PixelDebris
extends Node2D
## A spray of single pixels (dirt, water drops, leaves, bark chips) flung out from a spot,
## falling with gravity and fading. Every pixel is drawn on the whole-pixel grid.
## Fill in the fields, add it to the world and it frees itself when done.

## How fast a swaying pixel swings from side to side, in radians per second.
const SWAY_SPEED := 9.0
## Below this much life left (as a share), the pixels fade out.
const FADE_SHARE := 0.5
const CHUNK_SIZE := 2.0
const PIXEL_SIZE := 1.0


## One flying pixel.
class Pixel:
	var position: Vector2 = Vector2.ZERO
	var velocity: Vector2
	var color: Color
	## 1 for a single pixel, 2 for a 2×2 chunk.
	var size: float
	## Where in its sway it starts, in radians.
	var phase: float

## How many pixels fly out.
var count: int = 16
## Seconds until every pixel has faded.
var lifetime: float = 0.6
## Starting speed range, in pixels per second (slowest, fastest).
var speed_range: Vector2 = Vector2(40, 110)
## The main direction they fly, and how wide the spray fans out, in degrees.
var direction: Vector2 = Vector2.UP
var spread_degrees: float = 120.0
## Pull down, in pixels per second squared (leaves use a small one so they flutter).
var gravity: float = 260.0
## Pixels drift sideways like falling leaves when this is above 0 (pixels per second).
var sway: float = 0.0
var colors: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK]
## Some pixels are drawn 2×2 (bigger chunks) at this share.
var chunk_share: float = 0.25

var _age: float = 0.0
var _pixels: Array[Pixel] = []


static func spray(world: Node, at: Vector2, palette: Array[Color], amount: int, toward: Vector2 = Vector2.UP, spread: float = 120.0) -> PixelDebris:
	var debris := PixelDebris.new()
	debris.colors = palette
	debris.count = amount
	debris.direction = toward
	debris.spread_degrees = spread
	debris.z_index = 3
	world.add_child(debris)
	debris.global_position = at.round()
	return debris


func _ready() -> void:
	var half_spread := deg_to_rad(spread_degrees) / 2.0
	for pixel_number in count:
		var pixel := Pixel.new()
		var angle := direction.angle() + randf_range(-half_spread, half_spread)
		pixel.velocity = Vector2.from_angle(angle) * randf_range(speed_range.x, speed_range.y)
		pixel.color = colors.pick_random()
		pixel.size = CHUNK_SIZE if randf() < chunk_share else PIXEL_SIZE
		pixel.phase = randf() * TAU
		_pixels.append(pixel)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for pixel in _pixels:
		pixel.velocity += Vector2(0, gravity * delta)
		var drift := Vector2(sin(_age * SWAY_SPEED + pixel.phase) * sway, 0)
		pixel.position += (pixel.velocity + drift) * delta
	queue_redraw()


func _draw() -> void:
	var fade := clampf((1.0 - _age / lifetime) / FADE_SHARE, 0.0, 1.0)
	for pixel in _pixels:
		draw_rect(Rect2(pixel.position.round(), Vector2(pixel.size, pixel.size)), Color(pixel.color, fade))
