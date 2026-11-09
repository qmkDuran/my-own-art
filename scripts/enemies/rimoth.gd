class_name Rimoth
extends SpeciesEnemy
## A Rimoth: a bound Frost Glimra, a frost moth that hangs back and props up the others. It
## keeps its distance from the player, and every few seconds shells one ally in frost with a
## chill beam (RimothFrostShellCast). Cornered, it puffs frost (RimothFrostPuff). Kill it first.
##
## States:
##   HOVERING   -> keeps its distance (backing away round walls, closing in along the path)
##   CASTING    -> wings up, pouring the chill beam into an ally
##   PUFFING    -> cornered: beats its wings (the tell), then puffs frost
##   RECOVERING -> knocked back by a hit
##   DYING      -> fades away
##
## While DebugControls.enemies_passive is on, it only hovers in place and reacts to hits.

enum State { HOVERING, CASTING, PUFFING, RECOVERING, DYING }

@export_group("Keeping distance")
## It likes to stay between these distances from the player, in pixels (closest, farthest).
@export var preferred_distance: Vector2 = Vector2(80, 100)
## Flying speed, in pixels per second.
@export var fly_speed: float = 32.0
## How high it flutters above its shadow, how far it bobs, and seconds per bob.
@export var hover_height: float = 4.0
@export var bob_height: float = 1.0
@export var bob_period: float = 0.8

@export_group("Getting hit")
@export var hit_recover_time: float = 0.3

var _seconds_hovering: float = 0.0

@onready var shell_cast: RimothFrostShellCast = $ShellCast
@onready var frost_puff: RimothFrostPuff = $FrostPuff
@onready var death_drops: DeathDrops = $DeathDrops


func _ready() -> void:
	super._ready()
	_seconds_hovering = randf() * bob_period
	_timer.enter(State.HOVERING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	_bob(delta)
	var is_alert := _is_alert()
	if _timer.state != State.DYING and is_alert:
		shell_cast.count_down(delta)
		frost_puff.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.HOVERING:
			_hover(_can_act(is_alert))
		State.CASTING:
			_cast()
		State.PUFFING:
			_puff()
		State.RECOVERING, State.DYING:
			_slide_then(State.RECOVERING, State.HOVERING, delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _hover(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		velocity = Vector2.ZERO
		sprite.show_animation("idle")
		return
	if frost_puff.should_strike():
		_start(State.PUFFING, frost_puff.wind_up)
		frost_puff.start()
		return
	if shell_cast.should_cast():
		_start(State.CASTING, shell_cast.cast_time)
		shell_cast.start()
		return
	velocity = RangeKeeping.direction(path_mover, self, player, preferred_distance) * fly_speed
	sprite.show_animation("move" if velocity != Vector2.ZERO else "idle")


func _start(state: State, seconds: float) -> void:
	velocity = Vector2.ZERO
	sprite.replay_animation("cast")
	_timer.enter(state, seconds)


func _cast() -> void:
	velocity = Vector2.ZERO
	if shell_cast.update(_timer.elapsed):
		_timer.enter(State.HOVERING, 0.0)


func _puff() -> void:
	velocity = Vector2.ZERO
	frost_puff.update(_timer.elapsed)
	if _timer.is_over():
		frost_puff.strike()
		_timer.enter(State.HOVERING, 0.0)


func _bob(delta: float) -> void:
	_seconds_hovering += delta
	sprite.lift(hover_height + sin(TAU * _seconds_hovering / bob_period) * bob_height)


## Debug (enemies passive): a cast or a puff is called off.
func _stop_acting() -> void:
	_call_off_spells()
	if _timer.state == State.CASTING or _timer.state == State.PUFFING:
		_timer.enter(State.HOVERING, 0.0)


func _call_off_spells() -> void:
	if _timer.state == State.CASTING:
		shell_cast.cancel()
	elif _timer.state == State.PUFFING:
		frost_puff.cancel()


# --- Reactions ------------------------------------------------------------

## A hit breaks its concentration: the cast or puff is lost.
func _react_to_hit(source_position: Vector2) -> void:
	_call_off_spells()
	_knock_back_from(source_position)
	_timer.enter(State.RECOVERING, hit_recover_time)


func _die() -> void:
	_call_off_spells()
	death_drops.drop()
	_enter_dying_and_fade(State.DYING)
