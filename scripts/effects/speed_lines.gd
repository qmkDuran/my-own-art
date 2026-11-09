class_name SpeedLines
extends Node
## Anime-style speed lines: short streaks that flick out behind a fast move and fade.
##
## Each burst places a few thin lines behind the target, pointing along the
## direction of travel, scattered side to side so they read as rushing air.

## What the lines appear behind.
@export var target: Node2D
## Where on the target the lines centre, e.g. the middle of the body.
@export var center_offset: Vector2 = Vector2(0, -8)
## Seconds between bursts of lines.
@export var spawn_interval: float = 0.03
## How many lines appear in each burst.
@export var lines_per_burst: int = 2
## Shortest and longest a line can be, in pixels.
@export var line_length_range: Vector2 = Vector2(6, 12)
## How far lines scatter to either side of the path, in pixels.
@export var side_spread: float = 7.0
## How far behind the target lines start, in pixels.
@export var distance_behind: float = 6.0
## How far each line drifts backward while fading, in pixels.
@export var drift_distance: float = 5.0
## Seconds each line takes to fade away.
@export var fade_time: float = 0.15
@export var line_color: Color = Color(ApolloPalette.WHITE, 0.9)
@export var line_width: float = 1.0


func play_for(duration: float, travel_direction: Vector2) -> void:
	var direction := travel_direction.normalized()
	var time_left := duration
	while time_left > 0.0:
		_spawn_burst(direction)
		await Wait.seconds(self, spawn_interval)
		time_left -= spawn_interval


func _spawn_burst(direction: Vector2) -> void:
	for line_number in lines_per_burst:
		_spawn_line(direction)


func _spawn_line(direction: Vector2) -> void:
	var line := Line2D.new()
	# top_level makes the points world coordinates, so the line stays where it was drawn.
	line.top_level = true
	line.width = line_width
	line.default_color = line_color
	# Same layer as the ground but added later, so it draws on the ground and under creatures.
	line.z_index = 0

	var start := _random_start_point(direction)
	var length := randf_range(line_length_range.x, line_length_range.y)
	line.add_point(start)
	line.add_point(start - direction * length)
	target.get_parent().add_child(line)

	var fade := line.create_tween().set_parallel()
	fade.tween_property(line, "modulate:a", 0.0, fade_time)
	fade.tween_property(line, "position", -direction * drift_distance, fade_time)
	fade.chain().tween_callback(line.queue_free)


func _random_start_point(direction: Vector2) -> Vector2:
	var sideways := direction.orthogonal() * randf_range(-side_spread, side_spread)
	var behind := -direction * distance_behind
	return target.global_position + center_offset + behind + sideways
