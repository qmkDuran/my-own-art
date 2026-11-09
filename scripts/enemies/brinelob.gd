class_name Brinelob
extends Machine
## A Clamplate (Tide machine; the scene and code keep the old Brinelob name): a crab walker that
## holds its two shield claws up as a wall. Hits from
## in front plink off (BrinelobShellGuard); circle it, hit it from behind, spin (the Spinning
## Hook) or burn it. Up close it throws its claws wide and claps them (BrinelobClawSnap), and
## right after a snap its guard is down for a moment: the opening.
##
## States:
##   STANDING   -> waits (hasn't noticed the player, or enemies are paused)
##   WALKING    -> sidles toward the player, turning its shell to face them
##   WINDING_UP -> claws thrown wide, the clap's reach on the ground (super armour)
##   OPEN       -> just clapped: its guard is down and it stands still
##   RECOVERING -> knocked back by a hit that got through

enum State { STANDING, WALKING, WINDING_UP, OPEN, RECOVERING }

@export_group("Walking")
@export var walk_speed: float = 22.0

@export_group("After a snap")
## Seconds its guard stays down after a snap (the opening).
@export var guard_down_time: float = 1.0
## Seconds of that it holds the clapped pose.
@export var snap_pose_time: float = 0.25

@export_group("Getting hit")
@export var hit_recover_time: float = 0.25
## Seconds it shows its guard pose after a hit plinks off.
@export var plink_pose_time: float = 0.25

var _seconds_showing_guard: float = 0.0

@onready var shell_guard: BrinelobShellGuard = $ShellGuard
@onready var claw_snap: BrinelobClawSnap = $ClawSnap


func _ready() -> void:
	super._ready()
	health.deflected.connect(_on_deflected)
	_timer.enter(State.STANDING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	_seconds_showing_guard = maxf(0.0, _seconds_showing_guard - delta)
	var is_alert := _is_alert()
	if is_alert:
		claw_snap.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.STANDING, State.WALKING:
			_walk_or_snap(_can_act(is_alert), delta)
		State.WINDING_UP:
			_wind_up()
		State.OPEN:
			_stand_open()
		State.RECOVERING:
			_slide_then(State.RECOVERING, State.WALKING, delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _walk_or_snap(can_act: bool, delta: float) -> void:
	var player := PlayerFinder.find(self)
	if player != null and _is_alert():
		shell_guard.turn_toward(player.global_position, delta)
	if not can_act or player == null:
		velocity = Vector2.ZERO
		_show_pose("idle")
		_timer.state = State.STANDING
	elif claw_snap.should_strike():
		_start_wind_up()
	else:
		velocity = path_mover.direction_toward(player.global_position) * walk_speed
		_show_pose("move")
		_timer.state = State.WALKING


func _start_wind_up() -> void:
	velocity = Vector2.ZERO
	claw_snap.start()
	sprite.replay_animation("windup")
	_timer.enter(State.WINDING_UP, claw_snap.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	claw_snap.update(_timer.elapsed)
	if _timer.is_over():
		claw_snap.strike()
		shell_guard.drop_for(guard_down_time)
		sprite.replay_animation("snap")
		_timer.enter(State.OPEN, guard_down_time)


func _stand_open() -> void:
	velocity = Vector2.ZERO
	if _timer.elapsed >= snap_pose_time:
		sprite.show_animation("idle")
	if _timer.is_over():
		_timer.enter(State.WALKING, 0.0)


## Its walking or idle pose, unless it's still showing the guard pose after a plink.
func _show_pose(action: String) -> void:
	sprite.show_animation("guard" if _seconds_showing_guard > 0.0 else action)


## Debug (enemies passive): a wind-up is called off.
func _stop_acting() -> void:
	if _timer.state != State.WINDING_UP:
		return
	claw_snap.cancel()
	_timer.enter(State.STANDING, 0.0)


# --- Reactions ------------------------------------------------------------

func _has_super_armour() -> bool:
	return _timer.state == State.WINDING_UP


## A hit that got round the shell: knocked back, unless it's winding up (super armour).
func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.WINDING_UP:
		return
	_knock_back_from(source_position)
	_timer.enter(State.RECOVERING, maxf(hit_recover_time, _timer.seconds_left() if _timer.state == State.OPEN else 0.0))


## A front hit plinked off: it braces behind its claws for a moment, and has seen the player.
func _on_deflected(_source_position: Vector2) -> void:
	notice_player()
	_seconds_showing_guard = plink_pose_time
	if _timer.state == State.STANDING or _timer.state == State.WALKING:
		sprite.show_animation("guard")


func _call_off_attacks() -> void:
	claw_snap.cancel()
