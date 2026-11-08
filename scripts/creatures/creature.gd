class_name Creature
extends CharacterBody2D
## A creature the player controls through the spirit link.
##
## This script only coordinates. Each job lives in its own child component:
##   PlayerInput     -> what the player wants
##   Movement        -> how fast to move normally
##   Facing          -> which way to look
##   MeleeAttack     -> the jab
##   Dodge           -> the leap out of danger
##   AfterimageTrail -> fading copies during a dodge
##   SpeedTrail      -> a streak behind a dodge
##   SpeedLines      -> anime-style lines behind a dodge
##   Health          -> how much damage it can take (dodging makes it invulnerable)
##   HitFlash        -> flashes white when hit
##   Sprite          -> what to show

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := -6.0
## How fast a push (e.g. a Warden's shove) slows down, in pixels per second squared.
const PUSH_FRICTION := 600.0

## Seconds left during which a push controls movement instead of the player.
var _push_seconds_left: float = 0.0

@onready var player_input: PlayerInput = $PlayerInput
@onready var movement: Movement = $Movement
@onready var facing: Facing = $Facing
@onready var melee_attack: MeleeAttack = $MeleeAttack
@onready var dodge: Dodge = $Dodge
@onready var afterimage_trail: AfterimageTrail = $AfterimageTrail
@onready var speed_trail: SpeedTrail = $SpeedTrail
@onready var speed_lines: SpeedLines = $SpeedLines
@onready var health: Health = $Health
@onready var hit_flash: HitFlash = $HitFlash
@onready var animator: CreatureAnimator = $Sprite


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_push_seconds_left = maxf(0.0, _push_seconds_left - delta)
	_start_requested_action()
	# Leaping out of the way means attacks pass through you.
	health.is_invulnerable = dodge.is_dodging

	var move_direction := _chosen_move_direction()
	velocity = _next_velocity(move_direction, delta)
	move_and_slide()

	facing.look_toward(move_direction)
	animator.show_animation(_current_action(), facing)
	animator.lift(dodge.current_height())


## One action at a time, with one exception: a dodge can cancel a jab mid-punch,
## so the player can always escape (like Path of Exile 2's dodge roll).
func _start_requested_action() -> void:
	if player_input.wants_to_dodge() and dodge.is_ready():
		melee_attack.cancel()
		_start_dodge()
	elif not _is_busy() and player_input.wants_to_attack() and melee_attack.is_ready():
		_start_jab()


func _start_jab() -> void:
	var aim_direction := _aim_direction()
	facing.look_toward(aim_direction)
	melee_attack.start(aim_direction)
	animator.replay_animation(melee_attack.current_animation, facing)


## Punches go toward the mouse cursor, at any angle, measured from the body (not the feet).
func _aim_direction() -> Vector2:
	var body_center := global_position + Vector2(0, BODY_HEIGHT)
	var to_cursor := player_input.get_aim_point() - body_center
	if to_cursor.length() < 1.0:
		return facing.as_vector()
	return to_cursor.normalized()


func _start_dodge() -> void:
	var dodge_direction := _dodge_direction()
	facing.look_toward(dodge_direction)
	dodge.start(dodge_direction)
	animator.replay_animation("hop", facing)
	afterimage_trail.play_for(dodge.dodge_duration)
	speed_trail.play_for(dodge.dodge_duration)
	speed_lines.play_for(dodge.dodge_duration, dodge_direction)


## Dodge where the player is steering, or straight ahead if they aren't.
func _dodge_direction() -> Vector2:
	var steering := player_input.get_move_direction()
	if steering == Vector2.ZERO:
		return facing.as_vector()
	return steering


func _next_velocity(move_direction: Vector2, delta: float) -> Vector2:
	if dodge.is_dodging:
		return dodge.dodge_velocity
	if _is_being_pushed():
		return velocity.move_toward(Vector2.ZERO, PUSH_FRICTION * delta)
	if melee_attack.is_attacking:
		# A short step forward into the punch, then planted feet.
		return melee_attack.lunge_velocity()
	return movement.calculate_velocity(velocity, move_direction, delta)


## The creature plants its feet while punching and can't steer mid-dodge.
func _chosen_move_direction() -> Vector2:
	if _is_busy():
		return Vector2.ZERO
	return player_input.get_move_direction()


func _is_busy() -> bool:
	return melee_attack.is_attacking or dodge.is_dodging


## The dodge is a big kangaroo hop, so it reuses the hop animation while leaping.
func _current_action() -> String:
	if melee_attack.is_attacking:
		return melee_attack.current_animation
	if dodge.is_dodging or _is_moving():
		return "hop"
	return "idle"


func _is_moving() -> bool:
	return velocity.length() > STANDING_STILL_SPEED


func _on_damaged(_amount: int, _source_position: Vector2) -> void:
	hit_flash.flash()


## For the vertical slice, dying simply restarts the level.
func _on_died() -> void:
	get_tree().reload_current_scene.call_deferred()


## Shoves the creature: it slides with this velocity for a moment, without player control.
## Interrupts a jab. A dodge can still be used to escape.
func push(push_velocity: Vector2, duration: float) -> void:
	melee_attack.cancel()
	velocity = push_velocity
	_push_seconds_left = duration


func _is_being_pushed() -> bool:
	return _push_seconds_left > 0.0
