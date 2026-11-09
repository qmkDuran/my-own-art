class_name BarkWard
extends Node2D
## Mossdillo's Bark Ward on a teammate: bark plates circle it and soak up the next
## `HITS` hits whole (Health.shield_hits) for `SECONDS`, cracking off one by one.

const NODE_NAME := "BarkWard"
const HITS := 2
const SECONDS := 3.0
const ORBIT := Vector2(9, 4)
const PLATE_HEIGHT := -6.0
const CHIPS: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.GREEN_LIGHT]
const CHIP_PIXELS := 10
const PLATES_PER_HIT := 2
## How fast the plates circle, in radians per second.
const ORBIT_SPEED := 4.0
## In its last moments it blinks (this many times a second, counting on and off).
const BLINK_SECONDS := 0.6
const BLINK_RATE := 20.0
## The faint leafy ring around the body.
const RING_CENTRE := Vector2(0, -1)
const RING_RADIUS := 8.0
const RING_ALPHA := 0.5

var _health: Health
var _seconds_left: float = SECONDS
var _age: float = 0.0


## Wraps `member` in a fresh Bark Ward (replacing one it still has).
static func wrap(member: PlayableCreature) -> void:
	var old := member.get_node_or_null(NODE_NAME)
	if old != null:
		old.free()
	var ward := BarkWard.new()
	ward.name = NODE_NAME
	ward.z_index = 2
	ward._health = member.health_component()
	member.add_child(ward)


func _ready() -> void:
	_health.shield_hits = HITS
	_health.shield_absorbed.connect(_on_absorbed)


func _physics_process(delta: float) -> void:
	_age += delta
	_seconds_left -= delta
	if _seconds_left <= 0.0 or _health.shield_hits <= 0:
		_health.shield_hits = 0
		queue_free()
		return
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(_health) and _health.shield_absorbed.is_connected(_on_absorbed):
		_health.shield_absorbed.disconnect(_on_absorbed)


func _on_absorbed() -> void:
	PixelDebris.spray(get_parent().get_parent(), global_position + Vector2(0, PLATE_HEIGHT), CHIPS, CHIP_PIXELS, Vector2.UP, 200.0)


## Plates (2×2 bark chips) orbiting the body, one per hit left, plus a faint leafy ring.
func _draw() -> void:
	var is_blinked_out := _seconds_left < BLINK_SECONDS and int(_age * BLINK_RATE) % 2 == 0
	if is_blinked_out:
		return
	var plates := _health.shield_hits * PLATES_PER_HIT
	for plate in plates:
		var angle := _age * ORBIT_SPEED + TAU * plate / plates
		var spot := Vector2(cos(angle) * ORBIT.x, PLATE_HEIGHT + sin(angle) * ORBIT.y).round()
		draw_rect(Rect2(spot, Vector2(2, 2)), ApolloPalette.CORK)
		draw_rect(Rect2(spot, Vector2.ONE), ApolloPalette.GREEN_LIGHT)
	draw_arc(RING_CENTRE, RING_RADIUS, 0.0, TAU, 16, Color(ApolloPalette.GREEN_LIGHT, RING_ALPHA), 1.0)
