class_name Berry
extends Node2D
## A glowing berry an enemy dropped. Walking over it refills one Trainer's Aid charge.
## If the player's Aid is already full, the berry waits on the ground.

## How close the player must be to pick it up, in pixels.
@export var pickup_radius: float = 10.0
## Seconds before it disappears if nobody picks it up (it blinks first).
@export var lifetime: float = 25.0

## 7×7 pixel berry: '#' outline, 'r' red, 'd' dark red, 'h' highlight, 'g' leaf.
const PIXELS := ["...gg..", "..##g..", ".#rrr#.", "#rhrrd#", "#rrrdd#", ".#rdd#.", "..###.."]
const COLORS := {
	"#": ApolloPalette.OUTLINE, "r": ApolloPalette.RED_LIGHT, "d": ApolloPalette.RED,
	"h": ApolloPalette.CREAM, "g": ApolloPalette.GREEN,
}
## Where the berry's top-left pixel sits, from its spot on the ground (centred, resting on it).
const TOP_LEFT := Vector2(-3.5, -9.0)
## Seconds before it disappears in which it blinks.
const BLINK_SECONDS := 4.0

var _age: float = 0.0


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	visible = _age < lifetime - BLINK_SECONDS or int(_age * 8.0) % 2 == 0
	_try_pickup()
	queue_redraw()


func _draw() -> void:
	var bob := roundf(sin(_age * 4.0))
	draw_circle(Vector2(0, 1), 3.0, Color(ApolloPalette.OUTLINE, 0.35))     # little ground shadow
	PixelShape.draw_map(self, PIXELS, COLORS, TOP_LEFT + Vector2(0, bob))


func _try_pickup() -> void:
	var player := PlayerFinder.find(self)
	if player == null or player.global_position.distance_to(global_position) > pickup_radius:
		return
	var aid: TrainerAid = player.get_node_or_null("TrainerAid")
	if aid == null or not aid.has_room():
		return
	aid.add_charge()
	queue_free()
