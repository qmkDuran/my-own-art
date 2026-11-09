class_name ScrapPickup
extends Node2D
## A bit of scrap from a broken Warden rod (see ChipDrop): it bursts out, hangs a moment,
## then flies to Emberoo like a light mote and adds to the Link Rod's scrap.

const DRIFT_SECONDS := 0.45
const DRIFT_FRICTION := 160.0
const HOMING_ACCELERATION := 700.0
const MAX_SPEED := 240.0
const COLLECT_RADIUS := 5.0
## Safety net: a bit this old is collected anyway.
const MAX_AGE := 4.0
## 3×3 bent metal: '#' steel, 'l' a lit edge, 'c' a cyan wire.
const PIXELS := ["l#.", "#c#", ".##"]
const COLORS := {"#": ApolloPalette.GREY, "l": ApolloPalette.SILVER, "c": ApolloPalette.SKY}

## Scrap this bit is worth.
var amount: int = 1

var _velocity: Vector2 = Vector2.ZERO
var _age: float = 0.0


func _ready() -> void:
	z_index = 1
	var angle := randf_range(-PI * 0.9, -PI * 0.1)
	_velocity = Vector2.from_angle(angle) * randf_range(35.0, 70.0)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > MAX_AGE:
		_collect()
		return
	var player := PlayerFinder.find(self)
	if _age < DRIFT_SECONDS or player == null:
		_velocity = _velocity.move_toward(Vector2.ZERO, DRIFT_FRICTION * delta)
	else:
		var to_target := CreatureBody.middle_of(player) - global_position
		if to_target.length() <= COLLECT_RADIUS:
			_collect()
			return
		_velocity = _velocity.move_toward(to_target.normalized() * MAX_SPEED, HOMING_ACCELERATION * delta)
	global_position += _velocity * delta
	queue_redraw()


func _draw() -> void:
	PixelShape.draw_map(self, PIXELS, COLORS, Vector2(-1, -1))


func _collect() -> void:
	LinkRod.add_scrap(amount)
	queue_free()
