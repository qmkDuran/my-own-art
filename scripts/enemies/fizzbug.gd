class_name Fizzbug
extends Machine
## A Zapmite (Spark machine; the scene and code keep the old Fizzbug name): a tiny spark drone.
## It rushes at the player, stops close, glows for a moment and bursts (FizzbugBurst), hurting
## the player and any other enemy in the ring; the burst blows it apart. One jab kills it first.
##
## States:
##   WAITING  -> sits (hasn't noticed the player, or enemies are paused)
##   RUSHING  -> scuttles at the player along the path, fast
##   GLOWING  -> stopped, flashing faster and faster, the burst's reach on the ground
##   STUNNED  -> knocked back by a hit (one usually kills it)

enum State { WAITING, RUSHING, GLOWING, STUNNED }

@export_group("Rushing")
## Speed it rushes at, in pixels per second: about 1.6× a Toxlop's hopping speed.
@export var run_speed: float = 80.0

@export_group("Getting hit")
@export var hit_recover_time: float = 0.3

@onready var burst: FizzbugBurst = $Burst


func _ready() -> void:
	super._ready()
	_timer.enter(State.WAITING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	if DebugControls.enemies_passive:
		_stop_acting()
	var can_act := _can_act(_is_alert())

	match _timer.state:
		State.WAITING, State.RUSHING:
			_rush(can_act)
		State.GLOWING:
			_glow()
		State.STUNNED:
			_slide_then(State.STUNNED, State.RUSHING, delta)

	move_and_slide()


func _rush(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		velocity = Vector2.ZERO
		sprite.show_animation("idle")
		_timer.state = State.WAITING
	elif burst.is_player_close():
		_start_glow()
	else:
		velocity = path_mover.direction_toward(player.global_position) * run_speed
		sprite.show_animation("run")
		_timer.state = State.RUSHING


func _start_glow() -> void:
	velocity = Vector2.ZERO
	burst.start()
	sprite.replay_animation("glow")
	_timer.enter(State.GLOWING, burst.glow_time)


func _glow() -> void:
	velocity = Vector2.ZERO
	burst.update(_timer.elapsed)
	if _timer.is_over():
		_burst()


## Its end: the ring goes off and the drone blows apart (no light: it wasn't beaten).
func _burst() -> void:
	burst.burst()
	blow_up(false)


## Debug (enemies passive): a glow is called off and it just sits.
func _stop_acting() -> void:
	if _timer.state != State.GLOWING:
		return
	burst.cancel()
	_timer.enter(State.WAITING, 0.0)


## Once it glows it's committed: hits hurt but don't stop the burst.
func _has_super_armour() -> bool:
	return _timer.state == State.GLOWING


func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.GLOWING:
		return
	_knock_back_from(source_position)
	_timer.enter(State.STUNNED, hit_recover_time)


func _call_off_attacks() -> void:
	burst.cancel()
