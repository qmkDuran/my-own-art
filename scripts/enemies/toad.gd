class_name Toad
extends CharacterBody2D
## A toxic toad: hops toward the player, puffs up as a warning, then lashes its tongue.
##
## Behaviour is a small state machine. Each state has a length; when it runs out,
## the toad decides what to do next.
##   RESTING    -> sits for a moment, then hops closer or starts an attack
##   HOPPING    -> one hop toward the player, in an arc
##   PUFFING    -> the warning: cheeks puff up (the player's cue to dodge)
##   LASHING    -> tongue shoots out; hits the player if they're still in the way
##   RECOVERING -> a short pause after attacking or being hit
##   DYING      -> fades away

enum State { RESTING, HOPPING, PUFFING, LASHING, RECOVERING, DYING }

## Height of the player's body above their feet, used to aim and hit with the tongue.
const PLAYER_BODY_HEIGHT := -6.0

@export_group("Hopping")
## Farthest a single hop goes, in pixels.
@export var hop_distance: float = 22.0
## Seconds per hop (the hop animation's length).
@export var hop_duration: float = 0.44
## How high each hop peaks, in pixels.
@export var hop_height: float = 6.0
## Shortest and longest pause between hops, in seconds.
@export var rest_time_range: Vector2 = Vector2(0.25, 0.7)

@export_group("Tongue attack")
## How far the tongue reaches, in pixels. The toad attacks once the player is this close.
@export var tongue_reach: float = 26.0
## Seconds of warning before the tongue comes out (the attack animation's first frame).
@export var puff_time: float = 0.40
## Seconds the tongue is out (the rest of the attack animation).
@export var lash_time: float = 0.32
## How close to the tongue the player's body must be to get hit, in pixels.
@export var tongue_hit_radius: float = 5.0
@export var tongue_damage: int = 1
## Seconds the toad pauses after attacking or being hit.
@export var recover_time: float = 0.5

@export_group("Getting hit")
## Speed the toad is knocked back at when hit, in pixels per second.
@export var knockback_speed: float = 120.0
## How fast the knockback slows down, in pixels per second squared.
@export var knockback_friction: float = 600.0
## Seconds to fade out after dying.
@export var death_fade_time: float = 0.3

var _state: State = State.RESTING
var _time_in_state: float = 0.0
var _state_length: float = 0.0
var _hop_velocity: Vector2 = Vector2.ZERO
var _lash_direction: Vector2 = Vector2.DOWN
var _has_hit_this_lash: bool = false

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var tongue: ToadTongue = $Tongue
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_enter(State.RESTING, _random_rest_time())


func _physics_process(delta: float) -> void:
	_time_in_state += delta

	match _state:
		State.RESTING:
			_rest()
		State.HOPPING:
			_hop()
		State.PUFFING:
			_puff()
		State.LASHING:
			_lash()
		State.RECOVERING, State.DYING:
			_slow_down(delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _rest() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("idle")
	if _is_state_over():
		_choose_next_move()


func _hop() -> void:
	velocity = _hop_velocity
	sprite.lift(sin(PI * _state_progress()) * hop_height)
	if _is_state_over():
		sprite.lift(0.0)
		_enter(State.RESTING, _random_rest_time())


func _puff() -> void:
	velocity = Vector2.ZERO
	if _is_state_over():
		_has_hit_this_lash = false
		tongue.lash(_lash_direction, tongue_reach, lash_time)
		_enter(State.LASHING, lash_time)


func _lash() -> void:
	velocity = Vector2.ZERO
	if tongue.is_fully_extended() and not _has_hit_this_lash:
		_has_hit_this_lash = true
		_try_to_hit_player()
	if _is_state_over():
		_enter(State.RECOVERING, recover_time)


func _slow_down(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if _state == State.RECOVERING:
		sprite.show_animation("idle")
		if _is_state_over():
			_enter(State.RESTING, _random_rest_time())


# --- Decisions ------------------------------------------------------------

func _choose_next_move() -> void:
	var player := _find_player()
	if player == null:
		_enter(State.RESTING, _random_rest_time())
		return

	var to_player := _player_body_position(player) - global_position
	if to_player.length() <= tongue_reach:
		_start_attack(to_player)
	else:
		_start_hop(to_player)


func _start_attack(to_player: Vector2) -> void:
	_lash_direction = to_player.normalized()
	sprite.replay_animation("attack")
	_enter(State.PUFFING, puff_time)


## Hops toward the player, but not so far that it lands on top of them.
func _start_hop(to_player: Vector2) -> void:
	var distance := minf(hop_distance, to_player.length() - tongue_reach * 0.7)
	_hop_velocity = to_player.normalized() * distance / hop_duration
	sprite.replay_animation("hop")
	_enter(State.HOPPING, hop_duration)


func _try_to_hit_player() -> void:
	var player := _find_player()
	if player == null:
		return
	if not tongue.reaches(_player_body_position(player), tongue_hit_radius):
		return

	var player_health: Health = player.get_node_or_null("Health")
	if player_health != null:
		player_health.take_damage(tongue_damage, global_position)


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _state == State.DYING:
		return

	tongue.retract_now()
	sprite.lift(0.0)
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


## How far through the current state we are, from 0.0 to 1.0.
func _state_progress() -> float:
	return clampf(_time_in_state / _state_length, 0.0, 1.0)


func _random_rest_time() -> float:
	return randf_range(rest_time_range.x, rest_time_range.y)


func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func _player_body_position(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0, PLAYER_BODY_HEIGHT)
