class_name Bramole
extends SpeciesEnemy
## A Bramole: a bound Bloom Glimra, a mole whose leafy hood passes for a bush. It sits hidden
## until the player walks close, its eyes peek out, then it bursts up claws-first and slams
## roots into the ground (BramoleRootSlam). After a slam it stands exposed for a moment (the
## punish window), then burrows after the player to ambush again.
##
## States:
##   HIDDEN     -> a bush; only the pink bud gives it away. Waits for the player to come close
##   PEEKING    -> the late tell: its eyes peek out of the bush
##   WINDING_UP -> claws up, bud open, the snare's reach on the ground (super armour)
##   EXPOSED    -> just slammed: stands there, open to hits
##   BURROWING  -> half sunk, scoots after the player along the path; pops again once close
##                 enough for the snare to reach
##   RECOVERING -> knocked back by a hit
##   DYING      -> fades away
##
## While DebugControls.enemies_passive is on, it stays (or goes back) hidden and only reacts to hits.

enum State { HIDDEN, PEEKING, WINDING_UP, EXPOSED, BURROWING, RECOVERING, DYING }

@export_group("Ambush")
## It pops out once the player is this close, in pixels.
@export var ambush_distance: float = 40.0
## Seconds its eyes peek out before it pops (the late tell).
@export var peek_time: float = 0.3
## Seconds it stands exposed after a slam (the punish window).
@export var exposed_time: float = 1.2
## Seconds of that it holds the slam pose before standing up.
@export var slam_pose_time: float = 0.35
## Speed it burrows after the player, in pixels per second.
@export var burrow_speed: float = 24.0
## Burrowing, it comes up again once this close (well inside its snare's reach), in pixels.
@export var resurface_distance: float = 18.0

@export_group("Getting hit")
@export var hit_recover_time: float = 0.3

@onready var root_slam: BramoleRootSlam = $RootSlam
@onready var death_drops: DeathDrops = $DeathDrops


func _ready() -> void:
	super._ready()
	_timer.enter(State.HIDDEN, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	if DebugControls.enemies_passive:
		_stop_acting()
	var can_act := _can_act(_is_alert())

	match _timer.state:
		State.HIDDEN:
			_hide(can_act)
		State.PEEKING:
			_peek()
		State.WINDING_UP:
			_wind_up()
		State.EXPOSED:
			_stand_exposed()
		State.BURROWING:
			_burrow(can_act)
		State.RECOVERING, State.DYING:
			_slide(delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _hide(can_act: bool) -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("hidden")
	if can_act and _is_player_within(ambush_distance):
		_start_peek()


func _start_peek() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("peek")
	_timer.enter(State.PEEKING, peek_time)


func _peek() -> void:
	if _timer.is_over():
		_start_wind_up()


func _start_wind_up() -> void:
	velocity = Vector2.ZERO
	root_slam.start()
	sprite.replay_animation("windup")
	_timer.enter(State.WINDING_UP, root_slam.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	root_slam.update(_timer.elapsed)
	if _timer.is_over():
		root_slam.strike()
		sprite.replay_animation("slam")
		_timer.enter(State.EXPOSED, exposed_time)


func _stand_exposed() -> void:
	velocity = Vector2.ZERO
	if _timer.elapsed >= slam_pose_time:
		sprite.show_animation("idle")
	if _timer.is_over():
		_timer.enter(State.BURROWING, 0.0)


func _burrow(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		velocity = Vector2.ZERO
		sprite.show_animation("idle")
		return
	if _is_player_within(resurface_distance):
		_start_peek()
		return
	velocity = path_mover.direction_toward(player.global_position) * burrow_speed
	sprite.show_animation("move")


func _slide(delta: float) -> void:
	_slow_down_by(knockback_friction, delta)
	if _timer.state == State.RECOVERING and _timer.is_over():
		_timer.enter(State.BURROWING, 0.0)


## Debug (enemies passive): an attack in progress is called off and it hides again.
func _stop_acting() -> void:
	if _timer.state == State.DYING or _timer.state == State.HIDDEN:
		return
	root_slam.cancel()
	_timer.enter(State.HIDDEN, 0.0)


func _is_player_within(distance: float) -> bool:
	var player := PlayerFinder.find(self)
	return player != null and global_position.distance_to(player.global_position) <= distance


# --- Reactions ------------------------------------------------------------

## Mid wind-up the claws are already coming: hits hurt but don't stop it.
func _has_super_armour() -> bool:
	return _timer.state == State.WINDING_UP


## Struck while hiding or peeking, it pops straight into its slam; otherwise it's knocked back.
func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.WINDING_UP:
		return
	if (_timer.state == State.HIDDEN or _timer.state == State.PEEKING) and not DebugControls.enemies_passive:
		_start_wind_up()
		return
	_knock_back_from(source_position)
	sprite.show_animation("idle")
	_timer.enter(State.RECOVERING, hit_recover_time)


func _die() -> void:
	root_slam.cancel()
	death_drops.drop()
	_timer.enter(State.DYING, death_fade_time)
	_fade_out_and_free()
