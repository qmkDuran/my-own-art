class_name TimedAbility
extends SkillAction
## A team creature's ability with a simple timeline: a wind-up, one moment where it lands
## (`_land`), then recovery until `duration`. A dodge can cancel it until it has landed.
## Abilities fill in `_land` and, if they move the caster, `caster_velocity`.

## Seconds from pressing the key to the ability landing.
@export var wind_up: float = 0.1
## Seconds the whole move takes, start to recovery.
@export var duration: float = 0.3

var _caster: Node2D = null
var _aim_direction: Vector2 = Vector2.DOWN
var _time_casting: float = 0.0
var _has_landed: bool = false


func start(caster: Node2D, aim_direction: Vector2) -> void:
	super.start(caster, aim_direction)
	_caster = caster
	_aim_direction = aim_direction.normalized()
	_time_casting = 0.0
	_has_landed = false
	_begin()


func can_be_cancelled() -> bool:
	return not _has_landed


func _physics_process(delta: float) -> void:
	if not is_casting:
		return
	_time_casting += delta
	if not _has_landed and _time_casting >= wind_up:
		_has_landed = true
		_land()
	if _time_casting >= duration:
		is_casting = false


## How far through the wind-up it is, 0 to 1.
func _wind_up_progress() -> float:
	return clampf(_time_casting / wind_up, 0.0, 1.0) if wind_up > 0.0 else 1.0


## Where the caster's body is (above its feet), where most effects start.
func _body_position() -> Vector2:
	return _caster.global_position + Vector2(0, FrontViewCreature.BODY_HEIGHT)


# --- For each ability to fill in ----------------------------------------------

## Right when the key fires (e.g. stick the tongue out).
func _begin() -> void:
	pass


## The moment it lands: damage, effects.
func _land() -> void:
	pass
