class_name Enemy
extends CharacterBody2D
## What every enemy has in common, so each enemy script only says what makes it different:
## its state clock, noticing the player (and alerting the pack), flashing and being knocked
## back by hits and big shoves, and fading out when it dies.
##
## An enemy script runs its own state machine on top of this and overrides:
##   _react_to_hit(source_position) -> what a hit does to its state (it has already flashed
##                                     and noticed the player; dying enemies skip this)
##   _has_super_armour()           -> while true, hits and shoves don't move it
##   _die()                        -> its death (most call _fade_out_and_free)
##   _stop_acting()                -> calls off an attack or move in progress (debug pause, respawn)
##   _on_returned_to_spawn()       -> anything else to put back after `return_to_spawn`
## and calls super._ready() from its own _ready. Each enemy's first State is its idle one
## (`return_to_spawn` goes back to it).
## Each enemy scene sets these values on its root node.

@export_group("Noticing the player")
## It wakes up once the player comes this close, in pixels (then alerts its pack).
@export var notice_distance: float = 110.0

@export_group("Getting hit")
## Speed a hit knocks it back at, in pixels per second.
@export var knockback_speed: float = 100.0
## How fast a knockback slows down, in pixels per second squared.
@export var knockback_friction: float = 500.0
## Seconds it takes to fade out after dying (enemies with a death of their own ignore it).
@export var death_fade_time: float = 0.3

var _timer := StateTimer.new()
var _awareness := PlayerAwareness.new()
var _is_dying: bool = false
## Where the zone placed it; it walks back here (in an instant) after the player falls.
var _spawn_position: Vector2

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var path_mover: PathMover = $PathMover


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	_spawn_position = global_position


## Wakes it up (e.g. a Warden just summoned it, or a packmate spotted the player).
func notice_player() -> void:
	_awareness.notice(self)


## Throws it with this velocity, harder than a jab's knockback (e.g. Flame Uppercut).
## Super armour holds. Works on an enemy that just died too, so the body flies while it fades.
func knock_back(push_velocity: Vector2) -> void:
	if not _has_super_armour():
		velocity = push_velocity


## After the player falls (see WorldReset): back on its spawn point at full health and unaware,
## as if it had never been fought. A dying enemy stays dead.
func return_to_spawn() -> void:
	if _is_dying:
		return
	_stop_acting()
	StatusEffect.clear_from(self)
	health.revive()
	global_position = _spawn_position
	velocity = Vector2.ZERO
	_awareness = PlayerAwareness.new()
	sprite.lift(0.0)
	_timer.enter(0, 0.0)
	_on_returned_to_spawn()


## True once the player has come within `notice_distance` (or it was hit, summoned or alerted).
func _is_alert() -> bool:
	return _awareness.has_noticed_player(self, notice_distance)


## Alert and allowed to act: the debug switch (DebugControls.enemies_passive) is off.
func _can_act(is_alert: bool) -> bool:
	return is_alert and not DebugControls.enemies_passive


func _knock_back_from(source_position: Vector2) -> void:
	velocity = EnemyReactions.knockback_velocity(self, source_position, knockback_speed)


func _slow_down_by(friction: float, delta: float) -> void:
	velocity = EnemyReactions.slowed_down(velocity, friction, delta)


func _fade_out_and_free() -> void:
	EnemyReactions.fade_out_and_free(self, sprite, collision_shape, death_fade_time)


## The usual death: into `dying_state` (its State.DYING) while it fades out and is freed.
func _enter_dying_and_fade(dying_state: int) -> void:
	_timer.enter(dying_state, death_fade_time)
	_fade_out_and_free()


## Slides to a stop (e.g. after a knockback); once `recovering_state` has run its time, it
## goes on to `next_state`.
func _slide_then(recovering_state: int, next_state: int, delta: float) -> void:
	_slow_down_by(knockback_friction, delta)
	if _timer.state == recovering_state and _timer.is_over():
		_timer.enter(next_state, 0.0)


func _on_damaged(_amount: int, source_position: Vector2) -> void:
	hit_flash.flash()
	if _is_dying:
		return
	notice_player()
	_react_to_hit(source_position)


func _on_died() -> void:
	_is_dying = true
	_die()


# --- For each enemy to fill in --------------------------------------------

func _react_to_hit(_source_position: Vector2) -> void:
	pass


func _has_super_armour() -> bool:
	return false


func _die() -> void:
	_fade_out_and_free()


func _stop_acting() -> void:
	pass


func _on_returned_to_spawn() -> void:
	pass
