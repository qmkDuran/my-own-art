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
## and calls super._ready() from its own _ready.
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

## The state clock every enemy's own state machine runs on.
var state_timer := StateTimer.new()
var _awareness := PlayerAwareness.new()
var _is_dying: bool = false

@onready var health: Health = $Health
@onready var sprite: SingleViewAnimator = $Sprite
@onready var hit_flash: HitFlash = $HitFlash
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var path_mover: PathMover = $PathMover


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


## Wakes it up (e.g. a Warden just summoned it, or a packmate spotted the player).
func notice_player() -> void:
	_awareness.notice(self)


## Throws it with this velocity, harder than a jab's knockback (e.g. Flame Uppercut).
## Super armour holds. Works on an enemy that just died too, so the body flies while it fades.
func knock_back(push_velocity: Vector2) -> void:
	if not _has_super_armour():
		velocity = push_velocity


## True while hits can't move it or drain its poise (mid-charge, mid-slam, ...).
func is_super_armoured() -> bool:
	return _has_super_armour()


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
