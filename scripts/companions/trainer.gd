class_name Trainer
extends Node2D
## The player's trainer: follows Emberoo a few steps behind and supports him (Trainer's Aid).
##
## Enemies ignore the trainer: Warden visors only see Glimra light, and the trainer has none.
## (So the trainer has no collision and isn't in the "player" or "enemies" groups.)

## How far behind Emberoo the trainer likes to stay, in pixels.
@export var follow_distance: float = 22.0
## Walking speed in pixels per second; a bit faster than Emberoo so they keep up.
@export var walk_speed: float = 70.0
## Beyond this distance the trainer hurries to catch up.
@export var catch_up_distance: float = 70.0
@export var tonic_scene: PackedScene

var _target: Node2D
var _walk_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite
var _sprite_rest: Vector2


func _ready() -> void:
	add_to_group("trainer")
	_sprite_rest = sprite.position


func _physics_process(delta: float) -> void:
	if _target == null:
		_target = get_tree().get_first_node_in_group("player")
		return
	var to_spot := _follow_spot() - global_position
	var distance := to_spot.length()
	var speed := walk_speed * (1.8 if distance > catch_up_distance else 1.0)
	var is_walking := distance > 3.0
	if is_walking:
		global_position += to_spot.normalized() * minf(distance, speed * delta)
		if absf(to_spot.x) > 1.0:
			sprite.flip_h = to_spot.x < 0.0
	_bob(delta, is_walking)


## Throws a healing tonic at the creature; `on_land` runs when it arrives.
func toss_tonic(at: Node2D, on_land: Callable) -> void:
	if tonic_scene == null:
		on_land.call()
		return
	var tonic: TonicToss = tonic_scene.instantiate()
	get_parent().add_child(tonic)
	tonic.global_position = global_position + Vector2(0, -14)
	tonic.fly_to(at, on_land)


## A spot behind Emberoo, opposite the way he's facing.
func _follow_spot() -> Vector2:
	var facing := Vector2.DOWN
	if _target.has_node("Facing"):
		facing = (_target.get_node("Facing") as Facing).as_vector()
	return _target.global_position - facing * follow_distance


## A small walking bob (placeholder until the trainer has a walk animation).
func _bob(delta: float, is_walking: bool) -> void:
	if is_walking:
		_walk_time += delta
		sprite.position = _sprite_rest + Vector2(0, -roundf(absf(sin(_walk_time * 12.0))))
	else:
		_walk_time = 0.0
		sprite.position = _sprite_rest
