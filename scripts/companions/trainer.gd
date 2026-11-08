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
## How the trainer looks; the default look if left empty.
@export var look: TrainerLook

var _target: Node2D

@onready var sprite: LayeredTrainerSprite = $Sprite


func _ready() -> void:
	add_to_group("trainer")
	if look != null:
		sprite.apply_look(look)


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
			sprite.set_flipped(to_spot.x < 0.0)
	sprite.play(&"walk" if is_walking else &"idle")


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

