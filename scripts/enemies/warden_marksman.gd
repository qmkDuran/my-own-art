class_name WardenMarksman
extends SpeciesEnemy
## A Warden Marksman: a human sniper of the AI God (a Warden type, so it drops chips, see
## ChipDrop). He keeps well back, kneels and takes long, telegraphed rail shots
## (MarksmanRailShot) that walls block. After a shot he is slow to stand back up: the time to
## close in. Up close he is weak.
##
## States:
##   STANDING    -> holds his ground (unaware, enemies paused, or at a good distance)
##   WALKING     -> backs off or closes in to keep his distance
##   AIMING      -> kneeling: the lock-on line tracks, freezes, then the beam fires
##   STANDING_UP -> just fired: still kneeling, slowly getting up
##   RECOVERING  -> knocked back by a hit
##   DYING       -> fades away

enum State { STANDING, WALKING, AIMING, STANDING_UP, RECOVERING, DYING }

@export_group("Keeping distance")
## He likes to stay between these distances from the player, in pixels (closest, farthest).
@export var preferred_distance: Vector2 = Vector2(130, 160)
@export var walk_speed: float = 26.0

@export_group("After a shot")
## Seconds he stays down after firing before he can move or aim again.
@export var stand_up_time: float = 1.1
## Seconds of that he shows the firing pose.
@export var fire_pose_time: float = 0.2

@export_group("Getting hit")
@export var hit_recover_time: float = 0.35

@onready var rail_shot: MarksmanRailShot = $RailShot


func _ready() -> void:
	super._ready()
	_timer.enter(State.STANDING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	var is_alert := _is_alert()
	if _timer.state != State.DYING and is_alert:
		rail_shot.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.STANDING, State.WALKING:
			_keep_distance_or_aim(_can_act(is_alert))
		State.AIMING:
			_aim()
		State.STANDING_UP:
			_stand_up()
		State.RECOVERING, State.DYING:
			_slide_then(State.RECOVERING, State.STANDING, delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _keep_distance_or_aim(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		_hold_ground()
		return
	# Zero once he's at a good distance (or pinned with nowhere to back away to).
	var direction := RangeKeeping.direction(path_mover, self, player, preferred_distance)
	if direction == Vector2.ZERO and rail_shot.should_shoot():
		_start_aim()
	elif direction == Vector2.ZERO:
		_hold_ground()
	else:
		velocity = direction * walk_speed
		sprite.show_animation("walk")
		_timer.state = State.WALKING


func _hold_ground() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("idle")
	_timer.state = State.STANDING


func _start_aim() -> void:
	velocity = Vector2.ZERO
	rail_shot.start()
	sprite.replay_animation("aim")
	_timer.enter(State.AIMING, rail_shot.aim_time())


func _aim() -> void:
	velocity = Vector2.ZERO
	if _timer.elapsed >= rail_shot.track_time:
		sprite.show_animation("charge")
	if rail_shot.update(_timer.elapsed):
		sprite.replay_animation("fire")
		_timer.enter(State.STANDING_UP, stand_up_time)


func _stand_up() -> void:
	velocity = Vector2.ZERO
	if _timer.elapsed >= fire_pose_time:
		sprite.show_animation("aim")
	if _timer.is_over():
		_timer.enter(State.STANDING, 0.0)


## Debug (enemies passive): an aim is called off.
func _stop_acting() -> void:
	if _timer.state != State.AIMING:
		return
	rail_shot.cancel()
	_timer.enter(State.STANDING, 0.0)


# --- Reactions ------------------------------------------------------------

## A hit throws off his aim; while getting up, it doesn't hurry him.
func _react_to_hit(source_position: Vector2) -> void:
	if _timer.state == State.AIMING:
		rail_shot.cancel()
	_knock_back_from(source_position)
	var still_down_for := _timer.seconds_left() if _timer.state == State.STANDING_UP else 0.0
	sprite.show_animation("idle")
	_timer.enter(State.RECOVERING, maxf(hit_recover_time, still_down_for))


func _die() -> void:
	rail_shot.cancel()
	_enter_dying_and_fade(State.DYING)
