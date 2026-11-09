class_name WindShot
extends Area2D
## Zephoot's gust orb when it fights for you (GustShot): a fast ball of wind that hurts and
## nudges the first enemy it reaches, bursts on walls and obstacles, and fades after
## `lifetime`. Like the enemy's GustOrb it sits on the ground with its Sprite raised.

@export var speed: float = 170.0
@export var lifetime: float = 0.75
@export var damage: int = 1
@export var knockback_speed: float = 110.0
## How close an enemy's feet must come to the orb to be hit, in pixels.
@export var hit_radius: float = 8.0
@export var burst_scene: PackedScene

var _direction: Vector2 = Vector2.DOWN
var _age: float = 0.0
## Who fired it (for crits), found as the player when it was launched.
var _shooter: Node2D

@onready var sprite: SingleViewAnimator = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.show_animation("orb")


func launch(direction: Vector2) -> void:
	_direction = direction.normalized() if direction.length() > 0.1 else Vector2.DOWN
	_shooter = PlayerFinder.find(self)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += _direction * speed * delta
	var targets := AbilityTargets.within(self, global_position, hit_radius)
	if not targets.is_empty():
		_hit(targets[0])


func _hit(target_health: Health) -> void:
	var targets: Array[Health] = [target_health]
	var attacker := _shooter if is_instance_valid(_shooter) else self
	AbilityTargets.hurt_all(attacker, targets, damage)
	AbilityTargets.knock_back_all(targets, global_position - _direction * 8.0, knockback_speed)
	_burst()


## Walls and obstacles stop it; creatures on either side don't (enemies are hit by distance).
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(AbilityTargets.ENEMIES_GROUP) or body is PlayableCreature:
		return
	_burst()


func _burst() -> void:
	if burst_scene != null:
		Shockwave.spawn(burst_scene, get_parent(), sprite.global_position, 6.0, 0.15, ApolloPalette.SKY_LIGHT)
	set_deferred("monitoring", false)
	queue_free()
