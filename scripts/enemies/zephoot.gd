class_name Zephoot
extends SpeciesEnemy
## A Zephoot: a bound wind Glimra that floats on a little cloud and shoots from range.
##
## It keeps its distance from the player (ZephootFloat), puffs up, then blows a slow gust orb
## at them (ZephootGustShot). Right after a shot it is slow to move: that's the player's
## chance to close in.
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

@export_group("After a shot")
## Seconds after firing when it is slow to back away (the counterplay window).
@export var shot_recovery_time: float = 0.8
## Its speed while recovering, as a share of its floating speed.
@export var recovery_speed_share: float = 0.25

@export_group("Getting hit")
## Seconds it is stunned after being hit.
@export var hit_recover_time: float = 0.35

@onready var floating: ZephootFloat = $Float
@onready var gust_shot: ZephootGustShot = $GustShot
@onready var death_drops: DeathDrops = $DeathDrops


func _ready() -> void:
	super._ready()
	state_timer.enter(State.HOVERING, 0.0)


func _physics_process(delta: float) -> void:
	state_timer.advance(delta)
	floating.drift_and_bob(delta)
	var is_alert := _is_alert()
	if state_timer.state != State.DYING and is_alert:
		gust_shot.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match state_timer.state:
		State.HOVERING:
			_hover(_can_act(is_alert), delta)
		State.WINDING_UP:
			_wind_up()
		State.RECOVERING:
			_recover(delta)
		State.DYING:
			_slow_down_by(knockback_friction, delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _hover(is_active: bool, delta: float) -> void:
	if not is_active:
		velocity = floating.eased_velocity(velocity, Vector2.ZERO, delta)
	elif gust_shot.should_shoot():
		_start_wind_up()
		return
	else:
		var wanted := floating.preferred_direction() * floating.float_speed
		velocity = floating.eased_velocity(velocity, wanted, delta)
	sprite.show_animation("move" if floating.is_moving(velocity) else "idle")


func _start_wind_up() -> void:
	velocity = Vector2.ZERO
	gust_shot.start()
	sprite.replay_animation("attack")
	state_timer.enter(State.WINDING_UP, gust_shot.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	if gust_shot.update(state_timer.elapsed):
		state_timer.enter(State.RECOVERING, shot_recovery_time)


## Slow to react: after a shot it only creeps away; after a hit it slides with the knockback.
func _recover(delta: float) -> void:
	var creep := floating.preferred_direction() * floating.float_speed * recovery_speed_share
	velocity = velocity.move_toward(creep, knockback_friction * delta)
	if state_timer.is_over():
		state_timer.enter(State.HOVERING, 0.0)


## Debug (enemies passive): a wind-up is called off and it just hovers.
func _stop_acting() -> void:
	if state_timer.state != State.WINDING_UP:
		return
	gust_shot.cancel()
	state_timer.enter(State.HOVERING, 0.0)


# --- Reactions ------------------------------------------------------------

func _react_to_hit(source_position: Vector2) -> void:
	if state_timer.state == State.WINDING_UP:
		gust_shot.cancel()
	_knock_back_from(source_position)
	# A hit never cuts the slow spell after a shot short.
	var still_slow_for := state_timer.seconds_left() if state_timer.state == State.RECOVERING else 0.0
	state_timer.enter(State.RECOVERING, maxf(hit_recover_time, still_slow_for))


func _die() -> void:
	death_drops.drop()
	state_timer.enter(State.DYING, death_fade_time)
	_fade_out_and_free()
