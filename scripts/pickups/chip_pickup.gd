class_name ChipPickup
extends Node2D
## A hacked control chip a Warden dropped (see ChipDrop): a small cyan chip that pops out of
## the body, lands and blinks softly until Emberoo walks over it. Then it goes into the
## Link Rod's storage (C). With storage full it waits on the ground.

const TEXTURE := preload("res://art/pickups/hacked_chip.png")
## How close the player must be to pick it up, in pixels.
const PICKUP_RADIUS := 10.0
## The pop out of the body: up and to one side, then down under gravity.
const POP_SPEED_UP := 70.0
const POP_SPEED_SIDE := 30.0
const GRAVITY := 260.0
## Seconds before it can be picked up, so it is seen landing first.
const PICKUP_DELAY := 0.4
const BOB_SPEED := 3.0
const GLOW_RADIUS := 6.0
const PULSE_SECONDS := 1.2
## The sprite's centre sits this far above its spot on the ground.
const REST_HEIGHT := 6.0

var chip: Chip

var _age: float = 0.0
## Height above the ground (positive is up) and its speed, during the pop.
var _height: float = 0.0
var _rise_speed: float = POP_SPEED_UP
var _side_speed: float = 0.0
var _has_landed: bool = false
## Whether the player was standing on it last frame (a full storage warns once per visit).
var _is_touched: bool = false


func _ready() -> void:
	z_index = 1
	_side_speed = randf_range(-POP_SPEED_SIDE, POP_SPEED_SIDE)


func _process(delta: float) -> void:
	_age += delta
	if not _has_landed:
		_fly(delta)
	elif _age >= PICKUP_DELAY:
		_try_pickup()
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 - 0.5 * cos(TAU * _age / PULSE_SECONDS)
	var bob := roundf(sin(_age * BOB_SPEED)) if _has_landed else 0.0
	var centre := Vector2(0, -REST_HEIGHT - roundf(_height) + bob)
	draw_circle(Vector2(0, 1), 4.0, Color(ApolloPalette.OUTLINE, 0.35))  # ground shadow
	draw_circle(centre, GLOW_RADIUS, Color(ApolloPalette.SKY, 0.10 + 0.15 * pulse))
	draw_texture(TEXTURE, (centre - TEXTURE.get_size() / 2.0).round())


func _fly(delta: float) -> void:
	_rise_speed -= GRAVITY * delta
	_height += _rise_speed * delta
	position.x += _side_speed * delta
	if _height <= 0.0:
		_height = 0.0
		_has_landed = true
		position = position.round()


func _try_pickup() -> void:
	var player := PlayerFinder.find(self)
	var was_touched := _is_touched
	_is_touched = player != null and player.global_position.distance_to(global_position) <= PICKUP_RADIUS
	if not _is_touched or was_touched or chip == null:
		return
	if LinkRod.add_chip(chip):
		queue_free()
