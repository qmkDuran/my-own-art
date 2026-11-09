class_name Toad
extends CharacterBody2D
## A toxic toad: hops toward the player, puffs up as a warning, then lashes its tongue.
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

@export_group("Creature info")
## Shown when the player first meets this species, and in the Creature Log.
@export var species_id: String = "toxlop"
@export var display_name: String = "Toxlop"
@export var element: String = "Toxic"
@export var portrait: Texture2D

@export_group("Noticing the player")
## It wakes up once the player comes this close, in pixels (then alerts its pack).
@export var notice_distance: float = 110.0

@export_group("Hopping")
## Farthest a single hop goes, in pixels.
@export var hop_distance: float = 22.0
## Seconds per hop (the hop animation's length).
@export var hop_duration: float = 0.44
## How high each hop peaks, in pixels.
@export var hop_height: float = 6.0
## Shortest and longest pause between hops, in seconds.
@export var rest_time_range: Vector2 = Vector2(0.25, 0.7)

@export_group("Tongue attack")
## How far the tongue reaches, in pixels. The toad attacks once the player is this close.
@export var tongue_reach: float = 40.0
## Seconds of warning before the tongue comes out (the attack animation's first frame).
@export var puff_time: float = 0.80
## The toad glints once this many seconds before the tongue fires (the last-moment cue to dodge).
@export var glint_before_strike: float = 0.12
## Colour of that glint.
@export var glint_color: Color = ApolloPalette.LIME_PALE
## Seconds the tongue is out (the rest of the attack animation).
@export var lash_time: float = 0.32
## How close to the tongue the player's body must be to get hit, in pixels.
@export var tongue_hit_radius: float = 5.0
@export var tongue_damage: int = 1
## Seconds the toad pauses after attacking or being hit.
@export var recover_time: float = 0.5

@export_group("Getting hit")
## Speed the toad is knocked back at when hit, in pixels per second.
@export var knockback_speed: float = 120.0
## How fast the knockback slows down, in pixels per second squared.
@export var knockback_friction: float = 600.0
## Seconds to fade out after dying.
@export var death_fade_time: float = 0.3

var _timer := StateTimer.new()
var _hop_velocity: Vector2 = Vector2.ZERO
var _lash_direction: Vector2 = Vector2.DOWN
var _has_hit_this_lash: bool = false
var _has_glinted: bool = false
var _awareness := PlayerAwareness.new()

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var tongue: ToadTongue = $Tongue
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var death_drops: DeathDrops = $DeathDrops
@onready var path_mover: PathMover = $PathMover


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
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


## Wakes it up (e.g. a Warden just summoned it, or a packmate spotted the player).
func notice_player() -> void:
	_awareness.notice(self)


## Name, element and portrait, for the discovery card and the Creature Log.
func creature_info() -> Dictionary:
	return {"species": species_id, "name": display_name, "element": element, "portrait": portrait}


# --- States ---------------------------------------------------------------

func _rest() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("idle")
	if not _timer.is_over() or DebugControls.enemies_passive:
		return
	if _awareness.has_noticed_player(self, notice_distance):
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
	_glint_just_before_strike()
	if _timer.is_over():
		_has_hit_this_lash = false
		tongue.lash(_lash_direction, tongue_reach, lash_time)
		_timer.enter(State.LASHING, lash_time)


func _lash() -> void:
	velocity = Vector2.ZERO
	if tongue.is_fully_extended() and not _has_hit_this_lash:
		_has_hit_this_lash = true
		_try_to_hit_player()
	if _timer.is_over():
		_timer.enter(State.RECOVERING, recover_time)


func _slow_down(delta: float) -> void:
	velocity = EnemyReactions.slowed_down(velocity, knockback_friction, delta)
	if _timer.state == State.RECOVERING:
		sprite.show_animation("idle")
		if _timer.is_over():
			_timer.enter(State.RESTING, _random_rest_time())


## Debug (enemies passive): a hop or an attack in progress stops at once and the toad sits.
## Recovering from a hit and dying carry on as normal.
func _stop_acting() -> void:
	if _timer.state != State.HOPPING and _timer.state != State.PUFFING and _timer.state != State.LASHING:
		return
	tongue.retract_now()
	sprite.lift(0.0)
	_timer.enter(State.RESTING, _random_rest_time())


# --- Decisions ------------------------------------------------------------

func _choose_next_move() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		_timer.enter(State.RESTING, _random_rest_time())
		return

	# Measured along the path: a player just across a wall is not in tongue reach.
	var player_body := _player_body_position(player)
	var hop_direction := path_mover.direction_toward(player_body)
	var distance_to_player := path_mover.distance_to(player_body)
	if distance_to_player <= tongue_reach:
		_start_attack(player_body - global_position)
	else:
		_start_hop(hop_direction, distance_to_player)


func _start_attack(to_player: Vector2) -> void:
	_has_glinted = false
	_lash_direction = to_player.normalized()
	sprite.replay_animation("attack")
	_timer.enter(State.PUFFING, puff_time)


## Hops toward the player, but not so far that it lands on top of them.
func _start_hop(direction: Vector2, distance_to_player: float) -> void:
	var distance := minf(hop_distance, distance_to_player - tongue_reach * 0.7)
	_hop_velocity = direction * distance / hop_duration
	sprite.replay_animation("hop")
	_timer.enter(State.HOPPING, hop_duration)


func _try_to_hit_player() -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		return
	if not tongue.reaches(_player_body_position(player), tongue_hit_radius):
		return

	var player_health: Health = player.get_node_or_null("Health")
	if player_health != null:
		player_health.take_damage(tongue_damage, global_position)


## Like most trash mobs, the toad mainly telegraphs with its pose (the held puff).
## One quick glint right before the strike is the final cue.
func _glint_just_before_strike() -> void:
	if not _has_glinted and _timer.seconds_left() <= glint_before_strike:
		_has_glinted = true
		hit_flash.flash(glint_color)


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _timer.state == State.DYING:
		return
	notice_player()

	tongue.retract_now()
	sprite.lift(0.0)
	velocity = EnemyReactions.knockback_velocity(self, source_position, knockback_speed)
	_timer.enter(State.RECOVERING, recover_time)


## Throws the toad with this velocity, harder than a jab's knockback (e.g. Flame Uppercut).
## Works on a toad that just died too, so the body flies while it fades.
func knock_back(push_velocity: Vector2) -> void:
	velocity = push_velocity


func _on_died() -> void:
	death_drops.drop()
	_timer.enter(State.DYING, death_fade_time)
	EnemyReactions.fade_out_and_free(self, sprite, collision_shape, death_fade_time)


# --- Helpers --------------------------------------------------------------

func _random_rest_time() -> float:
	return randf_range(rest_time_range.x, rest_time_range.y)


func _player_body_position(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0, Creature.BODY_HEIGHT)
