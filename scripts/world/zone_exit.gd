class_name ZoneExit
extends Area2D
## A way out of the zone (see ZoneTravel): walking into it fades out, loads `target_zone` and
## puts Emberoo at its ZoneEntry `target_entry_id`. On the ground a few faint chevrons point
## the way while it's open.
##
## It stays shut, with a short HUD message instead of the trip, while `required_flag` isn't set
## (e.g. the Warden Captain still stands) or while the target zone doesn't exist yet
## ("PATH BLOCKED (COMING SOON)").

const COMING_SOON_TEXT := "PATH BLOCKED (COMING SOON)"
## Seconds after the zone starts before the exit reacts, so arriving never trips one.
const ARM_SECONDS := 0.6
const CHEVRON_COUNT := 3
## Pixels between chevrons along the way out.
const CHEVRON_SPACING := 6.0
## Seconds for one pulse to run along the chevrons.
const PULSE_SECONDS := 1.6

@export_file("*.tscn") var target_zone: String = ""
## The `checkpoint_id` of the ZoneEntry to arrive at in the target zone.
@export var target_entry_id: String = ""
## A StoryFlags flag that must be set before the exit opens ("" = always open).
@export var required_flag: String = ""
## What the HUD says while `required_flag` isn't set.
@export var locked_text: String = "THE WAY IS BARRED"
## The trigger's size in pixels, centred on this node.
@export var size: Vector2 = Vector2(32, 24)
## Which way is out (the chevrons point this way).
@export var direction: Vector2 = Vector2.LEFT
@export var chevron_color: Color = ApolloPalette.CREAM

var _armed_in: float = ARM_SECONDS
var _elapsed: float = 0.0


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_armed_in = maxf(0.0, _armed_in - delta)
	_elapsed += delta
	queue_redraw()


## Open: the flag is set (or none is needed) and the target zone exists.
func is_open() -> bool:
	return _target_exists() and (required_flag == "" or StoryFlags.has(required_flag))


func _target_exists() -> bool:
	return target_zone != "" and ResourceLoader.exists(target_zone)


func _on_body_entered(body: Node2D) -> void:
	if _armed_in > 0.0 or ZoneTravel.is_travelling or not body.is_in_group(PlayerFinder.GROUP):
		return
	if not _target_exists():
		CheckpointToast.show_message(self, COMING_SOON_TEXT)
	elif not is_open():
		CheckpointToast.show_message(self, locked_text)
	else:
		ZoneTravel.travel(target_zone, target_entry_id)


## Chevrons on the ground pointing out, a soft pulse running along them.
func _draw() -> void:
	if not is_open():
		return
	var way := direction.normalized()
	var side := way.orthogonal()
	var first := -way * CHEVRON_SPACING * (CHEVRON_COUNT - 1) / 2.0
	for index in CHEVRON_COUNT:
		var phase := fposmod(_elapsed / PULSE_SECONDS - float(index) / CHEVRON_COUNT, 1.0)
		var alpha := 0.35 + 0.55 * (1.0 - phase)
		var tip := (first + way * CHEVRON_SPACING * index).round()
		for step in range(-2, 3):
			var spot := (tip - way * absf(step) + side * step).round()
			draw_rect(Rect2(spot, Vector2.ONE), Color(chevron_color, alpha))
