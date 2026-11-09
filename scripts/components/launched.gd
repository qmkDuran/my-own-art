class_name Launched
extends ImpairingEffect
## An enemy thrown up into the air by a swap Outro (e.g. Zephoot's updraft): its sprite
## floats up and hangs there with a swirl of wind below, a clear "set-up" that the next
## creature's Intro cashes in (e.g. Emberoo's uppercut does bonus damage to launched enemies).
## Attached at runtime by `Launched.apply_to`; lifts the sprite through its `offset`, so it
## never fights the enemy's own hop or bob.

const NODE_NAME := "Launched"
## How high the sprite floats, in pixels, and how long it takes to rise and to drop.
const LIFT_HEIGHT := 10.0
const RISE_SECONDS := 0.15
## How fast the swirl under it spins, in radians per second.
const SWIRL_SPIN_SPEED := 9.0

var _sprite: AnimatedSprite2D
var _age: float = 0.0


## Launches the enemy with `target_health` for `seconds`. False when it didn't take.
static func apply_to(target_health: Health, seconds: float) -> bool:
	var launched := _find_or_add(target_health, NODE_NAME, func() -> StatusEffect: return Launched.new()) as Launched
	if launched == null or launched.is_active():
		return false
	launched.start(seconds)
	return true


func _init() -> void:
	immunity_seconds = 0.0


func _ready() -> void:
	z_index = 1
	_sprite = target().get_node_or_null(SPRITE_NODE) as AnimatedSprite2D


func _advance(delta: float) -> void:
	super._advance(delta)
	_age += delta
	if _sprite != null:
		_sprite.offset.y = -roundf(LIFT_HEIGHT * _height_share())
	queue_redraw()


func _end() -> void:
	if is_instance_valid(_sprite):
		_sprite.offset.y = 0.0


## 0 on the ground, 1 at full height: a quick rise, a hang and a quick drop at the end.
func _height_share() -> float:
	var rising := clampf(_age / RISE_SECONDS, 0.0, 1.0)
	var dropping := clampf(seconds_left() / RISE_SECONDS, 0.0, 1.0)
	return minf(rising, dropping)


## A small swirl of wind at its feet while it hangs.
func _draw() -> void:
	if not is_active():
		return
	var spin := _age * SWIRL_SPIN_SPEED
	draw_arc(Vector2.ZERO, 5.0, spin, spin + PI * 1.2, 8, ApolloPalette.SKY_LIGHT, 1.0)
	draw_arc(Vector2(0, -3), 3.0, -spin, -spin + PI, 6, ApolloPalette.WHITE, 1.0)
