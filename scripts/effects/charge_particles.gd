class_name ChargeParticles
extends Node2D
## Energy gathering into a point: small sparks appear around it and get pulled in.
##
## Used for the Warden charging his rod before a ground slam. The point is this
## node's position, so attach it where the energy should gather (e.g. the rod tip).

## How far from the point new sparks appear, in pixels (min, max).
@export var spawn_distance: Vector2 = Vector2(14, 26)
## Seconds between new sparks.
@export var spawn_interval: float = 0.03
## Seconds a spark takes to reach the point.
@export var travel_time: float = 0.25
## Spark colours, picked at random. Red energy by default.
@export var colors: Array[Color] = [ApolloPalette.RED, ApolloPalette.RED_LIGHT, ApolloPalette.ORANGE]

var _is_charging: bool = false
var _seconds_until_spark: float = 0.0
## Each spark: { "start": Vector2, "age": float, "color": Color }
var _sparks: Array[Dictionary] = []


func start_charging() -> void:
	_is_charging = true
	_seconds_until_spark = 0.0


func stop_charging() -> void:
	_is_charging = false


func _process(delta: float) -> void:
	if _is_charging:
		_spawn_sparks_over_time(delta)
	_age_sparks(delta)
	queue_redraw()


func _draw() -> void:
	for spark in _sparks:
		var progress: float = spark["age"] / travel_time
		# Ease in: sparks start slow and speed up as they're pulled in.
		var position_now: Vector2 = spark["start"].lerp(Vector2.ZERO, progress * progress)
		draw_rect(Rect2(position_now.round(), Vector2.ONE), spark["color"])


func _spawn_sparks_over_time(delta: float) -> void:
	_seconds_until_spark -= delta
	while _seconds_until_spark <= 0.0:
		_seconds_until_spark += spawn_interval
		var distance := randf_range(spawn_distance.x, spawn_distance.y)
		_sparks.append({
			"start": Vector2.from_angle(randf() * TAU) * distance,
			"age": 0.0,
			"color": colors.pick_random(),
		})


func _age_sparks(delta: float) -> void:
	var still_travelling: Array[Dictionary] = []
	for spark in _sparks:
		spark["age"] += delta
		if spark["age"] < travel_time:
			still_travelling.append(spark)
	_sparks = still_travelling
