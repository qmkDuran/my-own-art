class_name Handler
extends CharacterBody2D
## A Handler: an early-game grunt who serves the AI God.
##
## He never attacks. He keeps his distance from the player, backing away when
## they get close, and every few seconds raises his control rod to summon
## bound creatures (toads), up to a limit. Killing him stops the summoning;
## creatures already out keep fighting.
##
## States:
##   WATCHING  -> stands still, keeping an eye on the player
##   RETREATING-> walks away because the player is too close (tires out after a bit)
##   SUMMONING -> raises the rod; creatures appear at the end
##   RECOVERING-> knocked back after being hit
##   DYING     -> fades away

enum State { WATCHING, RETREATING, SUMMONING, RECOVERING, DYING }

@export_group("Keeping distance")
## If the player gets closer than this (pixels), he backs away.
@export var comfortable_distance: float = 50.0
## Walking speed in pixels per second. Much slower than the player, so you can catch him.
@export var walk_speed: float = 22.0
## Longest he keeps backing away before he has to stop, in seconds.
@export var max_retreat_time: float = 1.2
## Seconds he stands still to catch his breath after retreating that long.
@export var catch_breath_time: float = 1.5

@export_group("Summoning")
## The creature he summons.
@export var creature_scene: PackedScene
## Seconds between summons.
@export var summon_interval: float = 6.0
## He only summons again once this many of his creatures (or fewer) are left alive,
## so the player can clear most of a wave first.
@export var summon_when_alive_at_most: int = 1
## Seconds before his first summon.
@export var first_summon_delay: float = 1.0
## Seconds the summon gesture takes; creatures appear at the end (the summon animation's length).
@export var summon_duration: float = 0.6
## Creatures per summon.
@export var creatures_per_summon: int = 3
## Most of his creatures allowed alive at once.
@export var max_creatures: int = 6
## How far from him new creatures appear, in pixels (min, max).
@export var summon_radius: Vector2 = Vector2(14, 26)

@export_group("Getting hit")
@export var knockback_speed: float = 80.0
@export var knockback_friction: float = 500.0
@export var recover_time: float = 0.25
@export var death_fade_time: float = 0.4

var _state: State = State.WATCHING
var _time_in_state: float = 0.0
var _state_length: float = 0.0
var _seconds_until_summon: float = 0.0
var _seconds_retreating: float = 0.0
var _seconds_catching_breath: float = 0.0
## Untyped on purpose: it can briefly hold creatures that have already been freed.
var _summoned_creatures: Array = []

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_seconds_until_summon = first_summon_delay
	_enter(State.WATCHING, 0.0)


func _physics_process(delta: float) -> void:
	_time_in_state += delta
	if _state != State.DYING:
		_seconds_until_summon -= delta

	match _state:
		State.WATCHING, State.RETREATING:
			_keep_distance_or_summon(delta)
		State.SUMMONING:
			_summon()
		State.RECOVERING, State.DYING:
			_slow_down(delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _keep_distance_or_summon(delta: float) -> void:
	if _is_time_to_summon():
		_start_summon()
		return

	var away_from_player := _direction_away_from_player()
	if away_from_player == Vector2.ZERO or not _can_keep_retreating(delta):
		_stand_still()
	else:
		_back_away(away_from_player)


func _stand_still() -> void:
	velocity = Vector2.ZERO
	_state = State.WATCHING
	sprite.show_animation("idle")


func _back_away(direction: Vector2) -> void:
	velocity = direction * walk_speed
	_state = State.RETREATING
	sprite.show_animation("walk")


## He tires out: after backing away for a while he must stop and catch his breath,
## which is the player's chance to catch him.
func _can_keep_retreating(delta: float) -> bool:
	if _seconds_catching_breath > 0.0:
		_seconds_catching_breath -= delta
		return false
	if _state == State.RETREATING:
		_seconds_retreating += delta
		if _seconds_retreating >= max_retreat_time:
			_seconds_retreating = 0.0
			_seconds_catching_breath = catch_breath_time
			return false
	else:
		_seconds_retreating = 0.0
	return true


func _summon() -> void:
	velocity = Vector2.ZERO
	if _is_state_over():
		_spawn_creatures()
		_seconds_until_summon = summon_interval
		_enter(State.WATCHING, 0.0)


func _slow_down(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if _state == State.RECOVERING and _is_state_over():
		_enter(State.WATCHING, 0.0)


# --- Summoning ------------------------------------------------------------

func _is_time_to_summon() -> bool:
	return _seconds_until_summon <= 0.0 and _creatures_alive() <= summon_when_alive_at_most


func _start_summon() -> void:
	sprite.replay_animation("summon")
	_enter(State.SUMMONING, summon_duration)


func _spawn_creatures() -> void:
	if creature_scene == null:
		return
	var room_left := max_creatures - _creatures_alive()
	for creature_number in mini(creatures_per_summon, room_left):
		var creature: Node2D = creature_scene.instantiate()
		get_parent().add_child(creature)
		creature.global_position = global_position + _random_spot_nearby()
		_summoned_creatures.append(creature)


func _random_spot_nearby() -> Vector2:
	var angle := randf() * TAU
	var distance := randf_range(summon_radius.x, summon_radius.y)
	return Vector2.from_angle(angle) * distance


## Counts summoned creatures that are still alive (dead ones are removed from the list).
func _creatures_alive() -> int:
	var still_alive: Array = []
	for creature in _summoned_creatures:
		if is_instance_valid(creature) and creature.is_in_group("enemies"):
			still_alive.append(creature)
	_summoned_creatures = still_alive
	return _summoned_creatures.size()


# --- Keeping distance -----------------------------------------------------

## Points away from the player when they're too close; zero when he's comfortable.
func _direction_away_from_player() -> Vector2:
	var player := _find_player()
	if player == null:
		return Vector2.ZERO
	var from_player := global_position - player.global_position
	if from_player.length() >= comfortable_distance:
		return Vector2.ZERO
	return from_player.normalized()


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _state == State.DYING:
		return
	velocity = (global_position - source_position).normalized() * knockback_speed
	_enter(State.RECOVERING, recover_time)


func _on_died() -> void:
	_enter(State.DYING, death_fade_time)
	remove_from_group("enemies")
	collision_shape.set_deferred("disabled", true)

	var fade := create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, death_fade_time)
	fade.tween_callback(queue_free)


# --- Helpers --------------------------------------------------------------

func _enter(new_state: State, length: float) -> void:
	_state = new_state
	_time_in_state = 0.0
	_state_length = length


func _is_state_over() -> bool:
	return _time_in_state >= _state_length


func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
