class_name TonicToss
extends Node2D
## A healing tonic flying in an arc from the trainer to the creature.
## When it lands it calls back (the heal) and leaves a warm ring.

## 5×7 pixel bottle: '#' outline, 'g' glass, 'l' liquid, 'c' cork.
const BOTTLE := [".cc..", "#cc#.", "#gg#.", "#ll#.", "#ll#.", "#ll#.", ".##.."]
const COLORS := {"#": ApolloPalette.OUTLINE, "g": ApolloPalette.SILVER, "l": ApolloPalette.PINK, "c": ApolloPalette.CORK}
## Where the bottle's top-left pixel sits, so it spins around its middle.
const TOP_LEFT := Vector2(-2.5, -3.5)
## It lands this far above the creature's feet (its middle), in pixels.
const LANDING_HEIGHT := 8.0
## The warm ring at the creature's feet: its size, how long it spreads, its colour.
const RING_RADIUS := 14.0
const RING_SECONDS := 0.35
const RING_COLOR := Color(ApolloPalette.PINK, 0.9)

@export var flight_time: float = 0.45
## How high the arc rises, in pixels.
@export var arc_height: float = 18.0
@export var ring_scene: PackedScene

var _from: Vector2
var _target: Node2D
var _on_land: Callable
var _elapsed: float = 0.0


func fly_to(target: Node2D, on_land: Callable) -> void:
	_from = global_position
	_target = target
	_on_land = on_land


func _process(delta: float) -> void:
	if _target == null:
		return
	_elapsed += delta
	var progress := clampf(_elapsed / flight_time, 0.0, 1.0)
	var landing := _target.global_position + Vector2(0, -LANDING_HEIGHT)
	global_position = _from.lerp(landing, progress) + Vector2(0, -sin(PI * progress) * arc_height)
	rotation = progress * TAU
	queue_redraw()
	if progress >= 1.0:
		_land(landing)


func _draw() -> void:
	PixelShape.draw_map(self, BOTTLE, COLORS, TOP_LEFT)


func _land(at: Vector2) -> void:
	_on_land.call()
	if ring_scene != null:
		Shockwave.spawn(ring_scene, get_parent(), at + Vector2(0, LANDING_HEIGHT), RING_RADIUS, RING_SECONDS, RING_COLOR)
	queue_free()
