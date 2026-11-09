class_name Toad
extends SpeciesEnemy
## A toxic toad: hops toward the player, puffs up as a warning, then lashes its tongue
## (the attack lives in ToadTongueAttack).
##
## Behaviour is a small state machine. Each state has a length; when it runs out,
## the toad decides what to do next.
##   RESTING    -> sits for a moment, then hops closer or starts an attack
##   HOPPING    -> one hop toward the player (along the path around obstacles), in an arc
##   PUFFING    -> the warning: holds its puffed-up pose, then glints just before striking
##   LASHING    -> tongue shoots out; hits the player if they're still in the way
##   RECOVERING -> a short pause after attacking or being hit
##   DYING      -> fades away (DeathDrops leaves the goo and maybe a berry)
##
## Until it notices the player (they come within `notice_distance`, it gets hit, or a Warden
## summons it), it just sits. While DebugControls.enemies_passive is on, it only sits (RESTING)
## and reacts to hits.

enum State { RESTING, HOPPING, PUFFING, LASHING, RECOVERING, DYING }

@export_group("Hopping")
## Farthest a single hop goes, in pixels.
@export var hop_distance: float = 22.0
## Seconds per hop (the hop animation's length).
@export var hop_duration: float = 0.44
## How high each hop peaks, in pixels.
@export var hop_height: float = 6.0
## Shortest and longest pause between hops, in seconds.
@export var rest_time_range: Vector2 = Vector2(0.25, 0.7)
## A hop stops short of the player by this share of the tongue's reach, so it never lands on them.
@export var hop_stop_short_share: float = 0.7

@export_group("Getting hit")
## Seconds the toad pauses after attacking or being hit.
@export var recover_time: float = 0.5

var _hop_velocity: Vector2 = Vector2.ZERO

@onready var tongue_attack: ToadTongueAttack = $TongueAttack
@onready var death_drops: DeathDrops = $DeathDrops


func _ready() -> void:
	super._ready()
	_timer.enter(State.RESTING, _random_rest_time())


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
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
	if not _timer.is_over() or DebugControls.enemies_passive:
		return
	if _is_alert():
		_choose_next_move()
	else:
		_timer.enter(State.RESTING, _random_rest_time())


func _hop() -> void:
	velocity = _hop_velocity
	sprite.lift(sin(PI * _timer.progress()) * hop_height)
	if _timer.is_over():
		sprite.lift(0.0)
		_timer.enter(State.RESTING, _random_rest_time())


## The wind-up: the toad holds its puffed-up pose, then glints just before striking.
func _puff() -> void:
	velocity = Vector2.ZERO
	tongue_attack.update_puff(_timer.seconds_left())
	if _timer.is_over():
		tongue_attack.lash()
		_timer.enter(State.LASHING, tongue_attack.lash_time)


func _lash() -> void:
	velocity = Vector2.ZERO
	tongue_attack.update_lash()
	if _timer.is_over():
		_timer.enter(State.RECOVERING, recover_time)


func _slow_down(delta: float) -> void:
	_slow_down_by(knockback_friction, delta)
	if _timer.state == State.RECOVERING:
		sprite.show_animation("idle")
		if _timer.is_over():
			_timer.enter(State.RESTING, _random_rest_time())


## Debug (enemies passive): a hop or an attack in progress stops at once and the toad sits.
## Recovering from a hit and dying carry on as normal.
func _stop_acting() -> void:
	if _timer.state != State.HOPPING and _timer.state != State.PUFFING and _timer.state != State.LASHING:
		return
	tongue_attack.cancel()
	sprite.lift(0.0)
	_timer.enter(State.RESTING, _random_rest_time())


# --- Decisions ------------------------------------------------------------

func _choose_next_move() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		_timer.enter(State.RESTING, _random_rest_time())
		return

	# Measured along the path: a player just across a wall is not in tongue reach.
	var player_body := ToadTongueAttack.aim_point(player)
	var hop_direction := path_mover.direction_toward(player_body)
	var distance_to_player := path_mover.distance_to(player_body)
	if distance_to_player <= tongue_attack.tongue_reach:
		_start_attack(player_body - global_position)
	else:
		_start_hop(hop_direction, distance_to_player)


func _start_attack(to_player: Vector2) -> void:
	tongue_attack.start_puff(to_player)
	sprite.replay_animation("attack")
	_timer.enter(State.PUFFING, tongue_attack.puff_time)


## Hops toward the player, but not so far that it lands on top of them.
func _start_hop(direction: Vector2, distance_to_player: float) -> void:
	var distance := minf(hop_distance, distance_to_player - tongue_attack.tongue_reach * hop_stop_short_share)
	_hop_velocity = direction * distance / hop_duration
	sprite.replay_animation("hop")
	_timer.enter(State.HOPPING, hop_duration)


func _random_rest_time() -> float:
	return randf_range(rest_time_range.x, rest_time_range.y)


# --- Reactions ------------------------------------------------------------

func _react_to_hit(source_position: Vector2) -> void:
	tongue_attack.cancel()
	sprite.lift(0.0)
	_knock_back_from(source_position)
	_timer.enter(State.RECOVERING, recover_time)


func _die() -> void:
	death_drops.drop()
	_timer.enter(State.DYING, death_fade_time)
	_fade_out_and_free()
