class_name Gruntite
extends CharacterBody2D
## A Gruntite: a bound stone Glimra, a tanky boar that plods toward the player and charges.
##
## From mid range it winds up and charges in a straight line (GruntiteCharge). Ramming the
## player throws them hard. If it misses, it skids to a stop and stands dazed for a moment:
## the player's chance to punish it. A wall stops the charge early with a bonk.
## While winding up and charging it has super armour: hits hurt but don't push or stop it.
##
## States:
##   STANDING   -> waits (hasn't noticed the player, or enemies are paused)
##   PLODDING   -> walks slowly toward the player along the path around obstacles (or backs off
##                 to make room for a charge). The charge itself stays a straight line: it bonks.
##   WINDING_UP -> crest bristles, eyes go red, head down and a hoof scrape
##   CHARGING   -> thunders along the locked direction
##   RECOVERING -> slides to a stop: after a hit, a ram, a missed charge (dazed) or a bonk
##   DYING      -> fades away

enum State { STANDING, PLODDING, WINDING_UP, CHARGING, RECOVERING, DYING }

@export_group("Creature info")
## Shown when the player first meets this species, and in the Creature Log.
@export var species_id: String = "gruntite"
@export var display_name: String = "Gruntite"
@export var element: String = "Stone"
## None painted yet: the discovery card shows its sprite instead.
@export var portrait: Texture2D

@export_group("Noticing the player")
## It wakes up once the player comes this close, in pixels (then alerts its pack).
@export var notice_distance: float = 110.0

@export_group("Plodding")
## Walking speed, in pixels per second. Slow; the charge is three times this.
@export var walk_speed: float = 28.0

@export_group("After a charge")
## Seconds it stands dazed after a missed charge (the punish window), skid included.
@export var miss_daze_time: float = 1.0
## How fast the skid after a missed charge slows down, in pixels per second squared.
@export var skid_friction: float = 280.0
## Seconds it pauses after ramming the player.
@export var ram_recover_time: float = 0.5
## Speed it bounces back off a wall, in pixels per second (the bonk).
@export var bonk_bounce_speed: float = 40.0

@export_group("Getting hit")
@export var knockback_speed: float = 60.0
@export var knockback_friction: float = 500.0
@export var hit_recover_time: float = 0.25
@export var death_fade_time: float = 0.4

var _timer := StateTimer.new()
var _awareness := PlayerAwareness.new()
## How fast the current slide (knockback, skid or bounce) slows down.
var _slide_friction: float = 0.0

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var charge: GruntiteCharge = $Charge
@onready var path_mover: PathMover = $PathMover


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_timer.enter(State.STANDING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	var is_alert := _awareness.has_noticed_player(self, notice_distance)
	if _timer.state != State.DYING and is_alert:
		charge.count_down(delta)
	if DebugControls.enemies_passive:
		_stop_acting()
	var can_act := is_alert and not DebugControls.enemies_passive

	match _timer.state:
		State.STANDING, State.PLODDING:
			_plod_or_charge(can_act)
		State.WINDING_UP:
			_wind_up()
		State.CHARGING:
			_charge()
		State.RECOVERING, State.DYING:
			_slide(delta)

	move_and_slide()
	if _timer.state == State.CHARGING and get_slide_collision_count() > 0:
		_bonk()


## Wakes it up (e.g. a packmate spotted the player).
func notice_player() -> void:
	_awareness.notice(self)


## Name, element and picture, for the discovery card and the Creature Log.
func creature_info() -> Dictionary:
	return CreatureInfo.describe(species_id, display_name, element, portrait, sprite)


# --- States ---------------------------------------------------------------

func _plod_or_charge(can_act: bool) -> void:
	var player := PlayerFinder.find(self)
	if not can_act or player == null:
		_stand()
	elif charge.should_charge():
		_start_wind_up()
	else:
		# Too close to charge: it backs off a few steps to make room.
		var walk_direction := path_mover.direction_away_from(player.global_position) \
				if charge.is_player_too_close() else path_mover.direction_toward(player.global_position)
		velocity = walk_direction * walk_speed
		sprite.show_animation("move")
		_timer.state = State.PLODDING


func _stand() -> void:
	velocity = Vector2.ZERO
	sprite.show_animation("idle")
	_timer.state = State.STANDING


func _start_wind_up() -> void:
	velocity = Vector2.ZERO
	charge.start_wind_up()
	sprite.replay_animation("attack")
	_timer.enter(State.WINDING_UP, charge.wind_up)


func _wind_up() -> void:
	velocity = Vector2.ZERO
	charge.update_wind_up(_timer.elapsed)
	if _timer.is_over():
		velocity = charge.start_charge(walk_speed)
		_timer.enter(State.CHARGING, 0.0)


func _charge() -> void:
	if charge.try_to_ram_player():
		_end_charge(ram_recover_time, knockback_friction)
	elif charge.has_gone_full_distance():
		# A miss: it skids to a stop and stands dazed.
		_end_charge(miss_daze_time, skid_friction)


## It ran into a wall or an obstacle: a dull thud, a puff of dust, and it bounces back dazed.
func _bonk() -> void:
	charge.kick_up_dust()
	hit_flash.flash()
	_end_charge(miss_daze_time, knockback_friction)
	velocity = -charge.direction * bonk_bounce_speed


func _end_charge(recover_time: float, friction: float) -> void:
	charge.finish()
	_slide_friction = friction
	_timer.enter(State.RECOVERING, recover_time)


func _slide(delta: float) -> void:
	velocity = EnemyReactions.slowed_down(velocity, _slide_friction, delta)
	if _timer.state != State.RECOVERING:
		return
	if velocity.length() < 1.0:
		sprite.show_animation("idle")
	if _timer.is_over():
		_timer.enter(State.STANDING, 0.0)


## Debug (enemies passive): a wind-up or a charge in progress is called off and it stands.
func _stop_acting() -> void:
	if _timer.state != State.WINDING_UP and _timer.state != State.CHARGING:
		return
	charge.finish()
	_stand()


func _has_super_armour() -> bool:
	return _timer.state == State.WINDING_UP or _timer.state == State.CHARGING


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _timer.state == State.DYING:
		return
	notice_player()
	if _has_super_armour():
		return  # hurts, but doesn't stop the charge
	velocity = EnemyReactions.knockback_velocity(self, source_position, knockback_speed)
	_slide_friction = knockback_friction
	# A hit never cuts a daze short (that would make punishing a missed charge backfire).
	var dazed_for := _timer.seconds_left() if _timer.state == State.RECOVERING else 0.0
	_timer.enter(State.RECOVERING, maxf(hit_recover_time, dazed_for))


## Throws it with this velocity (e.g. Flame Uppercut). Super armour still holds.
func knock_back(push_velocity: Vector2) -> void:
	if not _has_super_armour():
		velocity = push_velocity


func _on_died() -> void:
	if _has_super_armour():
		charge.finish()
	_timer.enter(State.DYING, death_fade_time)
	_slide_friction = skid_friction
	EnemyReactions.fade_out_and_free(self, sprite, collision_shape, death_fade_time)
