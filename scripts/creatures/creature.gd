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
##   FistEmbers      -> sparks rising from the fists
##   TrainerAid      -> Q: the trainer throws a healing tonic (limited charges)
##   Sprite          -> what to show

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := -6.0
## How fast a push (e.g. a Warden's shove) slows down, in pixels per second squared.
const PUSH_FRICTION := 600.0

## How close (feet to feet, pixels) the creature walks to a clicked enemy before jabbing.
const ATTACK_APPROACH_DISTANCE := 16.0
## How close to a clicked spot counts as "arrived", in pixels.
const ARRIVE_DISTANCE := 3.0
## How close the cursor must be to an enemy's body for a click to target it, in pixels.
const CLICK_TARGET_RADIUS := 12.0

## Seconds left during which a push controls movement instead of the player.
var _push_seconds_left: float = 0.0
## Where a left-click told the creature to walk.
var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false
## The enemy a left-click told the creature to attack (walk up to it, then jab).
var _attack_target: Node2D = null

## Effect shown where you click to move (a small ring).
@export var click_marker_scene: PackedScene

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
@onready var fist_embers: FistEmbers = $FistEmbers
@onready var trainer_aid: TrainerAid = $TrainerAid


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_push_seconds_left = maxf(0.0, _push_seconds_left - delta)
	_read_mouse_orders()
	if player_input.wants_trainer_aid():
		trainer_aid.use()
	_start_requested_action()
	# Leaping out of the way means attacks pass through you.
	health.is_invulnerable = dodge.is_dodging

	var move_direction := _chosen_move_direction()
	velocity = _next_velocity(move_direction, delta)
	move_and_slide()

	facing.look_toward(move_direction)
	animator.show_animation(_current_action(), facing)
	animator.lift(dodge.current_height())
	fist_embers.follow(animator.view_for(facing), animator.flip_h, animator.position)


# --- Mouse orders (click to move / click to attack) -----------------------

## Left-click on the ground walks there (hold to keep following the cursor);
## left-click on an enemy walks up to it and jabs (hold to keep jabbing).
## Using WASD cancels mouse orders.
func _read_mouse_orders() -> void:
	if player_input.get_move_direction() != Vector2.ZERO:
		_clear_mouse_orders()
		return

	if player_input.just_clicked_to_move():
		var enemy := _enemy_under_cursor()
		if enemy != null:
			_clear_mouse_orders()
			_attack_target = enemy
		else:
			_walk_to(player_input.get_aim_point())
			_show_click_marker(_destination)
	elif player_input.is_holding_move_click() and _attack_target == null:
		_walk_to(player_input.get_aim_point())

	if _attack_target != null and not _is_valid_target(_attack_target):
		_attack_target = null


func _walk_to(point: Vector2) -> void:
	_attack_target = null
	_destination = point
	_has_destination = true


func _clear_mouse_orders() -> void:
	_has_destination = false
	_attack_target = null


func _enemy_under_cursor() -> Node2D:
	var cursor := player_input.get_aim_point()
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if cursor.distance_to(enemy.global_position + Vector2(0, BODY_HEIGHT)) <= CLICK_TARGET_RADIUS:
			return enemy
	return null


func _is_valid_target(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and enemy.is_in_group("enemies")


func _is_in_reach_of(enemy: Node2D) -> bool:
	return global_position.distance_to(enemy.global_position) <= ATTACK_APPROACH_DISTANCE


## A small ring where you clicked, so you know the order was received.
func _show_click_marker(point: Vector2) -> void:
	if click_marker_scene == null:
		return
	var marker: Shockwave = click_marker_scene.instantiate()
	get_parent().add_child(marker)
	marker.global_position = point
	marker.play(6.0, 0.25, Color(0.906, 0.835, 0.702, 0.8))


# --- Actions --------------------------------------------------------------

## One action at a time, with one exception: a dodge can cancel a jab mid-punch,
## so the player can always escape (like Path of Exile 2's dodge roll).
func _start_requested_action() -> void:
	if player_input.wants_to_dodge() and dodge.is_ready():
		melee_attack.cancel()
		_start_dodge()
	elif _is_busy() or not melee_attack.is_ready():
		return
	elif player_input.wants_to_attack():
		_start_jab(_aim_direction())
	elif _attack_target != null and _is_in_reach_of(_attack_target):
		_start_jab(_direction_to(_attack_target))
		# A single click is a single jab; holding the button keeps jabbing.
		if not player_input.is_holding_move_click():
			_attack_target = null


func _direction_to(enemy: Node2D) -> Vector2:
	var to_enemy := enemy.global_position - global_position
	return to_enemy.normalized() if to_enemy.length() > 0.1 else facing.as_vector()


func _start_jab(aim_direction: Vector2) -> void:
	_has_destination = false
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


## Dodge where the player is steering with WASD; otherwise toward the cursor.
func _dodge_direction() -> Vector2:
	var steering := player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	_clear_mouse_orders()
	return _aim_direction()


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
## Otherwise WASD steers, or it walks toward a clicked enemy or spot.
func _chosen_move_direction() -> Vector2:
	if _is_busy():
		return Vector2.ZERO
	var steering := player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	if _attack_target != null:
		return Vector2.ZERO if _is_in_reach_of(_attack_target) else _direction_to(_attack_target)
	if _has_destination:
		var to_destination := _destination - global_position
		if to_destination.length() <= ARRIVE_DISTANCE:
			_has_destination = false
			return Vector2.ZERO
		return to_destination.normalized()
	return Vector2.ZERO


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
