class_name ChillBeam
extends Node2D
## A Rimoth's chill beam: a crackling line of frost from the Rimoth to the ally it is shelling,
## thin and flickering at first and brighter as the cast runs. Drawn in code, pixel by pixel,
## following both ends as they move. Event-only: the cast spawns it and ends it.

## Pixels the line wanders sideways at most.
const WANDER := 1.0
const CORE_COLOR := ApolloPalette.WHITE
const EDGE_COLOR := ApolloPalette.SKY_LIGHT

var _from: Node2D
var _to: Node2D
## How far through the cast it is, from 0 to 1 (sets how solid the line is).
var progress: float = 0.0


## Adds a beam from `from` to `to` in `world`; free it (or let either end go) to end it.
static func spawn(world: Node, from: Node2D, to: Node2D) -> ChillBeam:
	var beam := ChillBeam.new()
	beam._from = from
	beam._to = to
	beam.z_index = 2
	world.add_child(beam)
	return beam


func _process(_delta: float) -> void:
	if not is_instance_valid(_from) or not is_instance_valid(_to):
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	# From body middle to body middle, whatever their sizes (CreatureBody).
	var start := CreatureBody.middle_of(_from) - global_position
	var end := CreatureBody.middle_of(_to) - global_position
	var length := start.distance_to(end)
	if length < 1.0:
		return
	var across := (end - start).normalized().orthogonal()
	for step in ceili(length):
		# Thin and broken at first, more of it lights up as the cast runs.
		if randf() > 0.35 + 0.65 * progress:
			continue
		var at := start.lerp(end, step / length) + across * randf_range(-WANDER, WANDER)
		draw_rect(Rect2(at.round(), Vector2.ONE), CORE_COLOR if randf() < progress else EDGE_COLOR)
