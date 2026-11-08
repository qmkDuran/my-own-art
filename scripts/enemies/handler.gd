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
##   SHOVING   -> player too close: raises the rod overhead while red energy gathers into it,
##                then slams it into the ground; the shockwave knocks the player back
##                (hits don't interrupt it: super armour)
##   RECOVERING-> knocked back after being hit
##   DYING     -> fades away

enum State { WATCHING, RETREATING, SUMMONING, SHOVING, RECOVERING, DYING }

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
@export var summon_interval: float = 7.0
## He only summons again once this many of his creatures (or fewer) are left alive,
## so the player can clear most of a wave first.
@export var summon_when_alive_at_most: int = 1
## Seconds before his first summon.
@export var first_summon_delay: float = 1.0
## Seconds the summon gesture takes; creatures appear at the end (the summon animation's length).
@export var summon_duration: float = 0.6
## Creatures per summon.
@export var creatures_per_summon: int = 4
## Most of his creatures allowed alive at once.
@export var max_creatures: int = 5
## How far from him new creatures appear, in pixels (min, max).
@export var summon_radius: Vector2 = Vector2(14, 36)
## How bright his rod tip flares while he summons.
@export var rod_flare_energy: float = 1.3

@export_group("Rod shove")
## If the player stays this close (pixels), he shoves them away.
@export var shove_trigger_distance: float = 22.0
## How far the shockwave reaches, in pixels.
@export var shove_radius: float = 30.0
## Seconds the rod glows before the shockwave (the player's chance to dodge).
@export var shove_windup: float = 0.5
## Seconds he stays in the pose after the shockwave.
@export var shove_follow_through: float = 0.15
## He glints this many seconds before the shockwave (the last-moment cue).
@export var shove_glint_before: float = 0.12
@export var shove_glint_color: Color = Color(0.812, 0.341, 0.235)
## Colour of the slam's shockwave ring.
@export var shockwave_color: Color = Color(0.812, 0.341, 0.235, 0.9)
## Where the rod hits the ground, relative to his feet. The shockwave starts here.
@export var slam_point: Vector2 = Vector2(0, -2)
@export var shove_damage: int = 1
## Speed the player is knocked back at, in pixels per second.
@export var shove_push_speed: float = 170.0
## Seconds the push controls the player.
@export var shove_push_time: float = 0.25
## Seconds before he can shove again.
@export var shove_cooldown: float = 2.5
## The ring effect shown when he shoves.
@export var shockwave_scene: PackedScene

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
var _seconds_until_shove_ready: float = 0.0
var _has_released_shove: bool = false
var _has_glinted: bool = false
## Untyped on purpose: it can briefly hold creatures that have already been freed.
var _summoned_creatures: Array = []
## Name, element and portrait of the creature he summons (read from the creature scene).
var _creature_info: Dictionary = {}
var _has_called_out: bool = false

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var charge_particles: ChargeParticles = $ChargeParticles
@onready var rod_flare: PixelLight = $RodFlare
@onready var visor_glow: PixelLight = $VisorGlow
@onready var speech_bubble: SpeechBubble = $SpeechBubble
@onready var collision_shape: CollisionShape2D = $CollisionShape


func _ready() -> void:
	_read_creature_info()
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_seconds_until_summon = first_summon_delay
	_enter(State.WATCHING, 0.0)


func _physics_process(delta: float) -> void:
	_time_in_state += delta
	if _state != State.DYING:
		_seconds_until_summon -= delta
		_seconds_until_shove_ready = maxf(0.0, _seconds_until_shove_ready - delta)

	match _state:
		State.WATCHING, State.RETREATING:
			_keep_distance_or_summon(delta)
		State.SHOVING:
			_shove()
		State.SUMMONING:
			_summon()
		State.RECOVERING, State.DYING:
			_slow_down(delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _keep_distance_or_summon(delta: float) -> void:
	if _should_shove():
		_start_shove()
		return
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


# --- Rod shove ------------------------------------------------------------

func _should_shove() -> bool:
	var player := _find_player()
	if player == null or _seconds_until_shove_ready > 0.0:
		return false
	return global_position.distance_to(player.global_position) <= shove_trigger_distance


func _start_shove() -> void:
	_has_released_shove = false
	_has_glinted = false
	sprite.replay_animation("shove", "summon")
	charge_particles.start_charging()
	_enter(State.SHOVING, shove_windup + shove_follow_through)


func _shove() -> void:
	velocity = Vector2.ZERO
	var time_to_release := shove_windup - _time_in_state
	if not _has_glinted and time_to_release <= shove_glint_before:
		_has_glinted = true
		hit_flash.flash(shove_glint_color)
	if not _has_released_shove and time_to_release <= 0.0:
		_has_released_shove = true
		_release_shockwave()
	if _is_state_over():
		_seconds_until_shove_ready = shove_cooldown
		_enter(State.WATCHING, 0.0)


func _release_shockwave() -> void:
	charge_particles.stop_charging()
	_spawn_shockwave_effect()
	var player := _find_player()
	if player == null:
		return
	var from_warden := player.global_position - (global_position + slam_point)
	if from_warden.length() > shove_radius:
		return

	var player_health: Health = player.get_node_or_null("Health")
	if player_health == null or player_health.is_invulnerable:
		return  # dodged through it
	player_health.take_damage(shove_damage, global_position)
	if player.has_method("push"):
		var direction := from_warden.normalized() if from_warden.length() > 0.1 else Vector2.DOWN
		player.push(direction * shove_push_speed, shove_push_time)


func _spawn_shockwave_effect() -> void:
	if shockwave_scene == null:
		return
	var ring: Shockwave = shockwave_scene.instantiate()
	get_parent().add_child(ring)
	ring.global_position = global_position + slam_point
	ring.play(shove_radius, 0.2, shockwave_color)


# --- Summoning ------------------------------------------------------------

func _is_time_to_summon() -> bool:
	return _seconds_until_summon <= 0.0 and _creatures_alive() <= summon_when_alive_at_most


func _start_summon() -> void:
	# His first summon of the fight comes with a shout.
	if not _has_called_out and not _creature_info.is_empty():
		_has_called_out = true
		speech_bubble.say("Go, %s!" % _creature_info["name"])
	sprite.replay_animation("summon")
	rod_flare.flash(rod_flare_energy, summon_duration)
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
	# The first time the player ever sees this species, the HUD announces it.
	if not _creature_info.is_empty():
		CreatureLog.discover(_creature_info)


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


func _read_creature_info() -> void:
	if creature_scene == null:
		return
	var probe := creature_scene.instantiate()
	if probe.has_method("creature_info"):
		_creature_info = probe.creature_info()
	probe.free()


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
	# Super armour: once the shove is winding up, hits hurt but don't interrupt it.
	# Otherwise holding attack would cancel it every time.
	if _state == State.SHOVING:
		return
	velocity = (global_position - source_position).normalized() * knockback_speed
	_enter(State.RECOVERING, recover_time)


func _on_died() -> void:
	charge_particles.stop_charging()
	_enter(State.DYING, death_fade_time)
	remove_from_group("enemies")
	collision_shape.set_deferred("disabled", true)

	var fade := create_tween()
	fade.tween_property(sprite, "modulate:a", 0.0, death_fade_time)
	fade.tween_callback(queue_free)
	visor_glow.fade_out(death_fade_time)


# --- Helpers --------------------------------------------------------------

func _enter(new_state: State, length: float) -> void:
	_state = new_state
	_time_in_state = 0.0
	_state_length = length


func _is_state_over() -> bool:
	return _time_in_state >= _state_length


func _find_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")
