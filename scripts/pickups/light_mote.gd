class_name LightMote
extends Node2D
## A mote of stolen Glimra light, freed when a bound creature is defeated.
## It bursts out, hangs for a moment, then streaks to the player and becomes XP.

const SHINE := ApolloPalette.WHITE
const TRAIL_LENGTH := 4
## How fast it slows down while drifting, in pixels per second squared.
const DRIFT_FRICTION := 160.0
## Safety net: a mote this many seconds old is removed, so none lingers forever.
const MAX_AGE := 4.0

## XP this mote is worth.
@export var xp_value: int = 1
## Its glow and the trail behind it (gold by default; a machine's stolen light keeps the
## cyan or magenta of its eye, see scenes/enemies/machines/).
@export var core_color: Color = ApolloPalette.GOLD
@export var trail_color: Color = ApolloPalette.ORANGE
## Seconds it drifts after bursting out, before it homes in.
@export var drift_time: float = 0.3
## How hard it accelerates toward the player, in pixels per second squared.
@export var homing_acceleration: float = 900.0
@export var max_speed: float = 280.0
## How close it must get to be collected, in pixels.
@export var collect_radius: float = 5.0

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0
var _trail: Array[Vector2] = []


func _ready() -> void:
	# Burst outward and slightly up from where the creature fell.
	var angle := randf_range(-PI * 0.95, -PI * 0.05)
	_velocity = Vector2.from_angle(angle) * randf_range(40.0, 80.0)


func _physics_process(delta: float) -> void:
	_age += delta
	_trail.push_front(global_position)
	if _trail.size() > TRAIL_LENGTH:
		_trail.pop_back()

	var player := PlayerFinder.find(self)
	if _age < drift_time or player == null:
		_velocity = _velocity.move_toward(Vector2.ZERO, DRIFT_FRICTION * delta)
	else:
		var target := CreatureBody.middle_of(player)  # his body, whatever his form
		var to_target := target - global_position
		if to_target.length() <= collect_radius:
			Progression.add_xp(xp_value)
			queue_free()
			return
		_velocity = _velocity.move_toward(to_target.normalized() * max_speed, homing_acceleration * delta)
	global_position += _velocity * delta
	if _age > MAX_AGE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	for index in _trail.size():
		var fade := 0.5 * (1.0 - float(index) / TRAIL_LENGTH)
		draw_rect(Rect2(to_local(_trail[index]).round() - Vector2(0.5, 0.5), Vector2.ONE), Color(trail_color, fade))
	draw_rect(Rect2(Vector2(-1, -1), Vector2(2, 2)), core_color)
	draw_rect(Rect2(Vector2(-1, -1), Vector2.ONE), SHINE)
