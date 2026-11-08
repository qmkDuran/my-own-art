class_name TonicToss
extends Node2D
## A healing tonic flying in an arc from the trainer to the creature.
## When it lands it calls back (the heal) and leaves a warm ring.

@export var flight_time: float = 0.45
## How high the arc rises, in pixels.
@export var arc_height: float = 18.0
@export var ring_scene: PackedScene

## 5×7 pixel bottle: '#' outline, 'g' glass, 'l' liquid, 'c' cork.
const BOTTLE := [".cc..", "#cc#.", "#gg#.", "#ll#.", "#ll#.", "#ll#.", ".##.."]
const COLORS := {"#": Color(0.035, 0.039, 0.078), "g": Color(0.78, 0.812, 0.8), "l": Color(0.875, 0.518, 0.647), "c": Color(0.678, 0.467, 0.341)}

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
	var t := clampf(_elapsed / flight_time, 0.0, 1.0)
	var landing := _target.global_position + Vector2(0, -8)
	global_position = _from.lerp(landing, t) + Vector2(0, -sin(PI * t) * arc_height)
	rotation = t * TAU
	queue_redraw()
	if t >= 1.0:
		_land(landing)


func _draw() -> void:
	for y in BOTTLE.size():
		for x in 5:
			var pixel: String = BOTTLE[y][x]
			if pixel != ".":
				draw_rect(Rect2(Vector2(x - 2.5, y - 3.5), Vector2.ONE), COLORS[pixel])


func _land(at: Vector2) -> void:
	_on_land.call()
	if ring_scene != null:
		var ring: Shockwave = ring_scene.instantiate()
		get_parent().add_child(ring)
		ring.global_position = at + Vector2(0, 8)
		ring.play(14.0, 0.35, Color(0.875, 0.518, 0.647, 0.9))
	queue_free()
