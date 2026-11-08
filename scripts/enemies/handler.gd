class_name Handler
extends CharacterBody2D
## A Handler: an early-game grunt who serves the AI God.
##
## He never attacks. He keeps his distance from the player, backing away when
## they get close, and every few seconds raises his control rod to summon
## bound creatures (toads), up to a limit. Killing him stops the summoning;
## creatures already out keep fighting.
##
## This script runs his state machine; the summoning and the rod shove are child
## components (HandlerSummoner, HandlerRodShove).
##
## States:
##   WATCHING  -> stands still, keeping an eye on the player
##   RETREATING-> walks away because the player is too close (tires out after a bit)
##   SUMMONING -> raises the rod; creatures appear at the end
##   SHOVING   -> player too close: raises the rod overhead while red energy gathers into it,
##                then slams it into the ground; the shockwave knocks the player back
##                (hits don't interrupt it: super armour)
##   RECOVERING-> knocked back after being hit
##   DYING     -> fades away
##
## While DebugControls.enemies_passive is on, he only stands (WATCHING) and reacts to hits.

enum State { WATCHING, RETREATING, SUMMONING, SHOVING, RECOVERING, DYING }

@export_group("Keeping distance")
## If the player gets closer than this (pixels), he backs away.
@export var comfortable_distance: float = 50.0
## Walking speed in pixels per second. Much slower than the player, so you can catch him.
@export var walk_speed: float = 22.0
## Longest he keeps backing away before he has to stop, in seconds.
@export var max_retreat_time: float = 1.2
## Seconds he stands still to catch his breath after retreating that long.
@export var catch_breath_time: float = 1.5

@export_group("Summoning")
## Seconds before his first summon (the rest of the summoning is set on his Summoner).
@export var first_summon_delay: float = 1.0

@export_group("Getting hit")
@export var knockback_speed: float = 80.0
@export var knockback_friction: float = 500.0
@export var recover_time: float = 0.25
@export var death_fade_time: float = 0.4

var _timer := StateTimer.new()
var _seconds_retreating: float = 0.0
var _seconds_catching_breath: float = 0.0

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var charge_particles: ChargeParticles = $ChargeParticles
@onready var speech_bubble: SpeechBubble = $SpeechBubble
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var summoner: HandlerSummoner = $Summoner
@onready var rod_shove: HandlerRodShove = $RodShove


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	summoner.wait_before_next_summon(first_summon_delay)
	_timer.enter(State.WATCHING, 0.0)


func _physics_process(delta: float) -> void:
	_timer.advance(delta)
	if _timer.state != State.DYING:
		summoner.count_down(delta)
		rod_shove.count_down(delta)

	if DebugControls.enemies_passive:
		_stop_acting()

	match _timer.state:
		State.WATCHING, State.RETREATING:
			if DebugControls.enemies_passive:
				_stand_still()
			else:
				_keep_distance_or_summon(delta)
		State.SHOVING:
			_shove()
		State.SUMMONING:
			_summon()
		State.RECOVERING, State.DYING:
			_slow_down(delta)

	move_and_slide()


# --- States ---------------------------------------------------------------

func _keep_distance_or_summon(delta: float) -> void:
	if rod_shove.should_shove():
		_start_shove()
		return
	if summoner.is_time_to_summon():
		_start_summon()
		return

	var away_from_player := _direction_away_from_player()
	if away_from_player == Vector2.ZERO or not _can_keep_retreating(delta):
		_stand_still()
	else:
		_back_away(away_from_player)


func _stand_still() -> void:
	velocity = Vector2.ZERO
	_timer.state = State.WATCHING
	sprite.show_animation("idle")


func _back_away(direction: Vector2) -> void:
	velocity = direction * walk_speed
	_timer.state = State.RETREATING
	sprite.show_animation("walk")


## He tires out: after backing away for a while he must stop and catch his breath,
## which is the player's chance to catch him.
func _can_keep_retreating(delta: float) -> bool:
	if _seconds_catching_breath > 0.0:
		_seconds_catching_breath -= delta
		return false
	if _timer.state == State.RETREATING:
		_seconds_retreating += delta
		if _seconds_retreating >= max_retreat_time:
			_seconds_retreating = 0.0
			_seconds_catching_breath = catch_breath_time
			return false
	else:
		_seconds_retreating = 0.0
	return true


## Points away from the player when they're too close; zero when he's comfortable.
func _direction_away_from_player() -> Vector2:
	var player := PlayerFinder.find(self)
	if player == null:
		return Vector2.ZERO
	var from_player := global_position - player.global_position
	if from_player.length() >= comfortable_distance:
		return Vector2.ZERO
	return from_player.normalized()


func _start_summon() -> void:
	# His first summon of the fight comes with a shout.
	var battle_cry := summoner.battle_cry()
	if battle_cry != "":
		speech_bubble.say(battle_cry)
	sprite.replay_animation("summon")
	_timer.enter(State.SUMMONING, summoner.summon_duration)


func _summon() -> void:
	velocity = Vector2.ZERO
	if _timer.is_over():
		summoner.finish_summon()
		_timer.enter(State.WATCHING, 0.0)


func _start_shove() -> void:
	sprite.replay_animation("shove", "summon")
	rod_shove.start()
	_timer.enter(State.SHOVING, rod_shove.duration())


func _shove() -> void:
	velocity = Vector2.ZERO
	rod_shove.update(_timer.elapsed)
	if _timer.is_over():
		rod_shove.finish()
		_timer.enter(State.WATCHING, 0.0)


func _slow_down(delta: float) -> void:
	velocity = EnemyReactions.slowed_down(velocity, knockback_friction, delta)
	if _timer.state == State.RECOVERING and _timer.is_over():
		_timer.enter(State.WATCHING, 0.0)


## Debug (enemies passive): a summon or a slam in progress is called off and he just stands.
## Recovering from a hit and dying carry on as normal.
func _stop_acting() -> void:
	if _timer.state != State.SUMMONING and _timer.state != State.SHOVING:
		return
	charge_particles.stop_charging()
	_timer.enter(State.WATCHING, 0.0)


# --- Reactions ------------------------------------------------------------

func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _timer.state == State.DYING:
		return
	# Super armour: once the shove is winding up, hits hurt but don't interrupt it.
	# Otherwise holding attack would cancel it every time.
	if _timer.state == State.SHOVING:
		return
	velocity = EnemyReactions.knockback_velocity(self, source_position, knockback_speed)
	_timer.enter(State.RECOVERING, recover_time)


## Throws the Warden with this velocity, harder than a jab's knockback (e.g. Flame Uppercut).
## Super armour still holds: a slam that is winding up isn't pushed.
func knock_back(push_velocity: Vector2) -> void:
	if _timer.state == State.SHOVING:
		return
	velocity = push_velocity


func _on_died() -> void:
	charge_particles.stop_charging()
	_timer.enter(State.DYING, death_fade_time)
	EnemyReactions.fade_out_and_free(self, sprite, collision_shape, death_fade_time)
