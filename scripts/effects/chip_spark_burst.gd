class_name ChipSparkBurst
extends Node2D
## A burst of cyan sparks: a control chip shorting out (e.g. when the Warden Captain falls).
## An event effect: the sparks fly out, slow down, flicker and fade, then it removes itself.

## How many sparks fly out.
var spark_count: int = 28
## Seconds until every spark has faded.
var duration: float = 0.7
## Starting speed of the sparks, in pixels per second (slowest, fastest).
var speed_range: Vector2 = Vector2(40, 110)
var colors: Array[Color] = [ApolloPalette.SKY, ApolloPalette.SKY_LIGHT, ApolloPalette.WHITE]

var _elapsed: float = 0.0
## Each spark: { "velocity": Vector2, "position": Vector2, "color": Color }
var _sparks: Array[Dictionary] = []


## Adds a burst to `world` at `at` (world coordinates).
static func spawn(world: Node, at: Vector2) -> void:
	var burst := ChipSparkBurst.new()
	burst.z_index = 2
	world.add_child(burst)
	burst.global_position = at


func _ready() -> void:
	for spark_number in spark_count:
		_sparks.append({
			"velocity": Vector2.from_angle(randf() * TAU) * randf_range(speed_range.x, speed_range.y),
			"position": Vector2.ZERO,
			"color": colors.pick_random(),
		})


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	for spark in _sparks:
		spark["position"] += spark["velocity"] * delta
		spark["velocity"] *= 1.0 - 4.0 * delta
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _elapsed / duration
	for spark in _sparks:
		if randf() < 0.15:
			continue  # a flicker
		var position_now: Vector2 = spark["position"]
		var tail: Vector2 = position_now - (spark["velocity"] as Vector2) * 0.03
		draw_line(tail.round(), position_now.round(), Color(spark["color"], fade), 1.0)
