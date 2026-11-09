class_name Zephoot
extends Machine
## A Gusteret (Wind machine; the scene and code keep the old Zephoot name): a hovering fan turret
## that shoots gusts from range.
##
## It keeps its distance from the player (ZephootFloat), spins up, then blows a slow gust orb
## at them (ZephootGustShot). Right after a shot it is slow to move: that's the player's
## chance to close in.
##
## States:
##   HOVERING   -> keeps a comfortable distance, drifting gently
##   WINDING_UP -> stops and spins up its fan, glints, then the orb comes out
##   RECOVERING -> just fired (or got hit): drifts slowly, can't shoot
##
## Until it notices the player (they come within `notice_distance`, or it gets hit), it just
## hovers in place. While DebugControls.enemies_passive is on, it only hovers in place and
## reacts to hits.

enum State { HOVERING, WINDING_UP, RECOVERING }

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


func _ready() -> void:
	super._ready()
	_timer.enter(State.HOVERING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	floating.drift_and_bob(delta)
	var is_alert := _is_alert()
	if is_alert:
		gust_shot.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.HOVERING:
			_hover(_can_act(is_alert), delta)
		State.WINDING_UP:
			_wind_up()
		State.RECOVERING:
			_recover(delta)

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
	_timer.enter(State.WINDING_UP, gust_shot.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	if gust_shot.update(_timer.elapsed):
		_timer.enter(State.RECOVERING, shot_recovery_time)


## Slow to react: after a shot it only creeps away; after a hit it slides with the knockback.
func _recover(delta: float) -> void:
	var creep := floating.preferred_direction() * floating.float_speed * recovery_speed_share
	velocity = velocity.move_toward(creep, knockback_friction * delta)
	if _timer.is_over():
		_timer.enter(State.HOVERING, 0.0)


## Debug (enemies passive): a wind-up is called off and it just hovers.
func _stop_acting() -> void:
	if _timer.state != State.WINDING_UP:
		return
	gust_shot.cancel()
	_timer.enter(State.HOVERING, 0.0)


# --- Reactions ------------------------------------------------------------

func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.WINDING_UP:
		gust_shot.cancel()
	_knock_back_from(source_position)
	# A hit never cuts the slow spell after a shot short.
	var still_slow_for := _timer.seconds_left() if _timer.state == State.RECOVERING else 0.0
	_timer.enter(State.RECOVERING, maxf(hit_recover_time, still_slow_for))


func _call_off_attacks() -> void:
	gust_shot.cancel()
