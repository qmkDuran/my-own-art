class_name Zephoot
extends CharacterBody2D
## A Zephoot: a bound wind Glimra that floats on a little cloud and shoots from range.
##
## It keeps its distance from the player (backing off when they come close, drifting in when
## they're far), puffs up, then blows a slow gust orb at them. Right after a shot it is slow
## to move: that's the player's chance to close in. The shot itself lives in ZephootGustShot.
##
## States:
##   HOVERING   -> keeps a comfortable distance, drifting gently
##   WINDING_UP -> stops and puffs up, glints, then the orb comes out
##   RECOVERING -> just fired (or got hit): drifts slowly, can't shoot
##   DYING      -> fades away
##
## Until it notices the player (they come within `notice_distance`, or it gets hit), it just
## hovers in place. While DebugControls.enemies_passive is on, it only hovers in place and
## reacts to hits.

enum State { HOVERING, WINDING_UP, RECOVERING, DYING }

@export_group("Creature info")
## Shown when the player first meets this species, and in the Creature Log.
@export var species_id: String = "zephoot"
@export var display_name: String = "Zephoot"
@export var element: String = "Wind"
## None painted yet: the discovery card shows its sprite instead.
@export var portrait: Texture2D

@export_group("Noticing the player")
## It wakes up once the player comes this close, in pixels (then alerts its pack).
@export var notice_distance: float = 130.0

@export_group("Keeping distance")
## It likes to stay between these distances from the player, in pixels (closest, farthest).
@export var preferred_distance: Vector2 = Vector2(70, 110)
## Floating speed, in pixels per second. Slower than the player, so it can be caught.
@export var float_speed: float = 34.0
## Sideways drift while it's at a comfortable distance, in pixels per second.
@export var drift_speed: float = 8.0
## Seconds before the sideways drift changes direction.
@export var drift_turn_time: float = 2.5
## How quickly it changes speed, in pixels per second squared (gentle, like a cloud).
@export var float_acceleration: float = 120.0

@export_group("Hovering")
## How high the cloud floats above its shadow, in pixels.
@export var hover_height: float = 3.0
## How far it bobs up and down, in pixels.
@export var bob_height: float = 1.0
## Seconds for one bob up and down.
@export var bob_period: float = 1.6

@export_group("After a shot")
## Seconds after firing when it is slow to back away (the counterplay window).
@export var shot_recovery_time: float = 0.8
## Its speed while recovering, as a share of `float_speed`.
@export var recovery_speed_share: float = 0.25

@export_group("Getting hit")
@export var knockback_speed: float = 110.0
@export var knockback_friction: float = 500.0
## Seconds it is stunned after being hit.
@export var hit_recover_time: float = 0.35
@export var death_fade_time: float = 0.3

var _timer := StateTimer.new()
var _awareness := PlayerAwareness.new()
var _drift_sign: float = 1.0
var _seconds_until_drift_turn: float = 0.0
var _seconds_hovering: float = 0.0

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var gust_shot: ZephootGustShot = $GustShot
@onready var death_drops: DeathDrops = $DeathDrops


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_drift_sign = 1.0 if randf() < 0.5 else -1.0
	_seconds_hovering = randf() * bob_period
	_timer.enter(State.HOVERING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	_bob(delta)
	_turn_drift_now_and_then(delta)
	var is_alert := _awareness.has_noticed_player(self, notice_distance)
	if _timer.state != State.DYING and is_alert:
		gust_shot.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.HOVERING:
			_hover(is_alert and not DebugControls.enemies_passive, delta)
		State.WINDING_UP:
			_wind_up()
		State.RECOVERING:
			_recover(delta)
		State.DYING:
			velocity = EnemyReactions.slowed_down(velocity, knockback_friction, delta)

	move_and_slide()


## Wakes it up (e.g. a packmate spotted the player).
func notice_player() -> void:
	_awareness.notice(self)


## Name, element and picture, for the discovery card and the Creature Log.
func creature_info() -> Dictionary:
	return CreatureInfo.describe(species_id, display_name, element, portrait, sprite)


# --- States ---------------------------------------------------------------

func _hover(is_active: bool, delta: float) -> void:
	if not is_active:
		_float_toward(Vector2.ZERO, delta)
	elif gust_shot.should_shoot():
		_start_wind_up()
		return
	else:
		_float_toward(_preferred_direction() * float_speed, delta)
	sprite.show_animation("move" if velocity.length() > drift_speed else "idle")


func _start_wind_up() -> void:
	velocity = Vector2.ZERO
	gust_shot.start()
	sprite.replay_animation("attack")
	_timer.enter(State.WINDING_UP, gust_shot.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	if gust_shot.update(_timer.elapsed):
		_timer.enter(State.RECOVERING, shot_recovery_time)


## Slow to react: after a shot it only creeps away; after a hit it slides with the knockback.
func _recover(delta: float) -> void:
	var creep := _preferred_direction() * float_speed * recovery_speed_share
	velocity = velocity.move_toward(creep, knockback_friction * delta)
	if _timer.is_over():
		_timer.enter(State.HOVERING, 0.0)


## Debug (enemies passive): a wind-up is called off and it just hovers.
func _stop_acting() -> void:
	if _timer.state != State.WINDING_UP:
		return
	gust_shot.cancel()
	_timer.enter(State.HOVERING, 0.0)


# --- Moving ---------------------------------------------------------------

## Away from the player when they're too close, toward them when too far, and a slow
## sideways drift in between. Zero without a player.
func _preferred_direction() -> Vector2:
	var player := PlayerFinder.find(self)
	if player == null:
		return Vector2.ZERO
	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance < preferred_distance.x:
		return -to_player.normalized()
	if distance > preferred_distance.y:
		return to_player.normalized()
	return to_player.normalized().orthogonal() * _drift_sign * (drift_speed / float_speed)


## Swaps the sideways drift's direction every `drift_turn_time` seconds.
func _turn_drift_now_and_then(delta: float) -> void:
	_seconds_until_drift_turn -= delta
	if _seconds_until_drift_turn <= 0.0:
		_seconds_until_drift_turn = drift_turn_time
		_drift_sign = -_drift_sign


func _float_toward(target_velocity: Vector2, delta: float) -> void:
	velocity = velocity.move_toward(target_velocity, float_acceleration * delta)


## The cloud floats above its shadow and bobs gently (a lift, not a hop).
func _bob(delta: float) -> void:
	_seconds_hovering += delta
	sprite.lift(hover_height + sin(TAU * _seconds_hovering / bob_period) * bob_height)


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _timer.state == State.DYING:
		return
	notice_player()
	if _timer.state == State.WINDING_UP:
		gust_shot.cancel()
	velocity = EnemyReactions.knockback_velocity(self, source_position, knockback_speed)
	# A hit never cuts the slow spell after a shot short.
	var still_slow_for := _timer.seconds_left() if _timer.state == State.RECOVERING else 0.0
	_timer.enter(State.RECOVERING, maxf(hit_recover_time, still_slow_for))


## Throws it with this velocity, harder than a jab's knockback (e.g. Flame Uppercut).
func knock_back(push_velocity: Vector2) -> void:
	velocity = push_velocity


func _on_died() -> void:
	death_drops.drop()
	_timer.enter(State.DYING, death_fade_time)
	EnemyReactions.fade_out_and_free(self, sprite, collision_shape, death_fade_time)
