class_name GustOrb
extends Area2D
## A Zephoot's gust orb: a slow ball of packed wind that flies in a straight line.
##
## It hurts the player and gives them a small push (the Wind effect, Buffeted: a player
## pushed by a gust can't be pushed by another for a moment), then bursts. It also bursts on a wall or
## an obstacle, and fades away after `lifetime`. Other enemies don't stop it. A player who
## is dodging (invulnerable) passes straight through it.
##
## This node sits on the ground (so it hits walls and feet); its Sprite is raised to the
## height it was blown from, with a small shadow below.

## Flying speed, in pixels per second. Slow enough to see coming and step aside.
@export var speed: float = 55.0
## Seconds before it fades away on its own.
@export var lifetime: float = 3.0
@export var damage: int = 1
## Speed of the small push it gives the player, in pixels per second.
@export var push_speed: float = 70.0
## Seconds the push controls the player.
@export var push_time: float = 0.15
## The little ring shown when it bursts.
@export var burst_scene: PackedScene
@export var burst_color: Color = ApolloPalette.SKY_LIGHT
## Size of that ring, in pixels.
@export var burst_radius: float = 5.0
## Seconds the burst ring lasts.
@export var burst_time: float = 0.15

var _direction: Vector2 = Vector2.DOWN
var _age: float = 0.0

@onready var sprite: SingleViewAnimator = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.show_animation("orb")


## Sends the orb off in `direction`.
func launch(direction: Vector2) -> void:
	_direction = direction.normalized() if direction.length() > 0.1 else Vector2.DOWN


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position += _direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(EnemyReactions.ENEMIES_GROUP):
		return  # flies past its own side
	if body.is_in_group(PlayerFinder.GROUP):
		_try_to_hit_player(body)
	else:
		_burst()  # a wall or an obstacle


func _try_to_hit_player(player: Node2D) -> void:
	if not PlayerHit.try_to_hurt(player, damage, global_position):
		return  # dodged through it
	Buffeted.apply_to(PlayerHit.health_of(player), _direction * push_speed, push_time)
	_burst()


func _burst() -> void:
	if burst_scene != null:
		Shockwave.spawn(burst_scene, get_parent(), sprite.global_position, burst_radius, burst_time, burst_color)
	set_deferred("monitoring", false)
	queue_free()
