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
##   TrainerAid      -> F: the trainer throws a healing tonic (limited charges)
##   SkillBar        -> Q/W/E/R: skills that spend Heat (e.g. E = Flame Uppercut)
##   ScreenShake     -> shakes the camera on big hits
##   Sprite          -> what to show

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := -6.0
## How fast a push (e.g. a Warden's shove) slows down, in pixels per second squared.
const PUSH_FRICTION := 600.0
## Max health gained per level (the small automatic "ding" boost).
const HEALTH_PER_LEVEL := 1

## How close to a clicked spot counts as "arrived", in pixels.
const ARRIVE_DISTANCE := 3.0

## Seconds left during which a push controls movement instead of the player.
var _push_seconds_left: float = 0.0
## Where a left-click told the creature to walk.
var _destination: Vector2 = Vector2.ZERO
var _has_destination: bool = false
## The enemy a left-click told the creature to attack (walk up to it, then jab).
var _attack_target: Node2D = null
## Whether the creature has already jabbed its attack target since it was clicked.
## Letting go of the button after that ends the order (so one click = one jab).
var _has_jabbed_attack_target: bool = false

## Effect shown where you click to move (a small ring).
@export var click_marker_scene: PackedScene
## How close (feet to feet, pixels) the creature walks to a clicked enemy before jabbing.
## The jab connects up to MeleeAttack's reach + hit_radius away, so this stops a little
## inside that and jabs at once, instead of walking into the enemy first.
@export var attack_approach_distance: float = 20.0
## How close the cursor must be to an enemy's body centre for a click to target it, in pixels.
## The nearest enemy within this distance is picked, so near-misses still count.
@export var click_target_radius: float = 12.0

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
@onready var speech_bubble: SpeechBubble = $SpeechBubble
@onready var skill_bar: SkillBar = $SkillBar


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	Progression.leveled_up.connect(_on_leveled_up)
	skill_bar.skill_used.connect(_on_skill_used)
	_apply_level_bonuses()


func _physics_process(delta: float) -> void:
	_push_seconds_left = maxf(0.0, _push_seconds_left - delta)
	_read_mouse_orders()
	if player_input.wants_trainer_aid():
		trainer_aid.use()
	_cancel_jab_recovery_to_move()
	_start_requested_action()
	# Leaping out of the way means attacks pass through you.
	health.is_invulnerable = dodge.is_dodging

	var move_direction := _chosen_move_direction()
	velocity = _next_velocity(move_direction, delta)
	move_and_slide()

	facing.look_toward(move_direction)
	animator.show_animation(_current_action(), facing)
	animator.lift(dodge.current_height() + skill_bar.cast_lift())
	fist_embers.follow(animator.view_for(facing), animator.flip_h, animator.position)


# --- Mouse orders (click to move / click to attack) -----------------------

## Left-click on the ground walks there (hold to keep following the cursor);
## left-click on an enemy walks up to it and jabs (hold to keep jabbing).
## Shift + left-click stops and jabs in place instead (PlayerInput reports it as an attack).
## Steering with the arrow keys cancels mouse orders.
func _read_mouse_orders() -> void:
	if player_input.get_move_direction() != Vector2.ZERO or player_input.is_attacking_in_place_with_move_click():
		_clear_mouse_orders()
		return

	if player_input.just_clicked_to_move():
		var enemy := _enemy_under_cursor()
		if enemy != null:
			_clear_mouse_orders()
			_attack_target = enemy
			_has_jabbed_attack_target = false
		else:
			_walk_to(player_input.get_aim_point())
			_show_click_marker(_destination)
	elif player_input.is_holding_move_click() and _attack_target == null:
		_walk_to(player_input.get_aim_point())

	if _attack_target != null and not _is_valid_target(_attack_target):
		_attack_target = null
	# A single click is a single jab; holding the button keeps jabbing.
	if _has_jabbed_attack_target and not player_input.is_holding_move_click():
		_attack_target = null


func _walk_to(point: Vector2) -> void:
	_attack_target = null
	_destination = point
	_has_destination = true


func _clear_mouse_orders() -> void:
	_has_destination = false
	_attack_target = null


## The enemy whose body centre is nearest the cursor, if any is within click_target_radius.
func _enemy_under_cursor() -> Node2D:
	var cursor := player_input.get_aim_point()
	var nearest: Node2D = null
	var nearest_distance := click_target_radius
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		var distance := cursor.distance_to(enemy.global_position + Vector2(0, BODY_HEIGHT))
		if distance <= nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _is_valid_target(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and enemy.is_in_group("enemies")


func _is_in_reach_of(enemy: Node2D) -> bool:
	return global_position.distance_to(enemy.global_position) <= attack_approach_distance


## A small ring where you clicked, so you know the order was received.
func _show_click_marker(point: Vector2) -> void:
	if click_marker_scene == null:
		return
	var marker: Shockwave = click_marker_scene.instantiate()
	get_parent().add_child(marker)
	marker.global_position = point
	marker.play(6.0, 0.25, Color(0.906, 0.835, 0.702, 0.8))


# --- Actions --------------------------------------------------------------

## Animation cancel: once the jab's hit has landed, a fresh order to move cuts the
## rest of its recovery short, so walking away after a punch feels instant.
## Not while the player is still asking to attack, so holding attack chains full jabs.
func _cancel_jab_recovery_to_move() -> void:
	if not melee_attack.can_cancel_by_moving() or not _wants_to_move():
		return
	if player_input.wants_to_attack() or _attack_target != null:
		return
	melee_attack.cancel()


func _wants_to_move() -> bool:
	return player_input.get_move_direction() != Vector2.ZERO or _has_destination


## One action at a time, with one exception: a dodge can cancel a jab mid-punch (and a
## skill during its wind-up), so the player can usually escape (like Path of Exile 2's dodge roll).
## Skills are started by the SkillBar itself (see _on_skill_used).
func _start_requested_action() -> void:
	if player_input.wants_to_dodge() and dodge.is_ready() and skill_bar.allows_dodge():
		melee_attack.cancel()
		skill_bar.cancel_cast()
		_start_dodge()
	elif _is_busy() or not melee_attack.is_ready():
		return
	elif player_input.wants_to_attack():
		_start_jab(aim_direction())
	elif _attack_target != null and _is_in_reach_of(_attack_target):
		_start_jab(_direction_to(_attack_target))
		_has_jabbed_attack_target = true


func _direction_to(enemy: Node2D) -> Vector2:
	var to_enemy := enemy.global_position - global_position
	return to_enemy.normalized() if to_enemy.length() > 0.1 else facing.as_vector()


func _start_jab(aim_direction: Vector2) -> void:
	_has_destination = false
	player_input.consume_attack_buffer()
	facing.look_toward(aim_direction)
	melee_attack.start(aim_direction)
	animator.replay_animation(melee_attack.current_animation, facing)


## Punches and skills go toward the mouse cursor, at any angle, measured from the body (not the feet).
func aim_direction() -> Vector2:
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


## Dodge where the player is steering with the arrow keys; otherwise toward the cursor.
func _dodge_direction() -> Vector2:
	var steering := player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	_clear_mouse_orders()
	return aim_direction()


func _next_velocity(move_direction: Vector2, delta: float) -> Vector2:
	if dodge.is_dodging:
		return dodge.dodge_velocity
	if _is_being_pushed():
		return velocity.move_toward(Vector2.ZERO, PUSH_FRICTION * delta)
	if melee_attack.is_attacking:
		# A quick snap forward into the punch, then planted feet.
		return melee_attack.lunge_velocity()
	if skill_bar.is_casting():
		return skill_bar.cast_velocity()
	return movement.calculate_velocity(velocity, move_direction, delta)


## The creature plants its feet while punching and can't steer mid-dodge.
## Otherwise the arrow keys steer, or it walks toward a clicked enemy or spot.
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
	return melee_attack.is_attacking or dodge.is_dodging or skill_bar.is_casting()


## The dodge is a big kangaroo hop, so it reuses the hop animation while leaping.
func _current_action() -> String:
	if skill_bar.is_casting():
		return skill_bar.cast_animation()
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
## Interrupts a jab or a skill. A dodge can still be used to escape.
func push(push_velocity: Vector2, duration: float) -> void:
	melee_attack.cancel()
	skill_bar.cancel_cast()
	velocity = push_velocity
	_push_seconds_left = duration


func _is_being_pushed() -> bool:
	return _push_seconds_left > 0.0


# --- Skills (the SkillBar decides when; the creature just acts it out) -----

## The SkillBar asks this before firing: not mid-leap and not being shoved.
## A jab in progress doesn't block a skill; the skill cuts it short.
func can_start_skill() -> bool:
	return not dodge.is_dodging and not _is_being_pushed() and not health.is_dead()


## A skill just fired: stop walking or jabbing, face the aim and play its animation.
func _on_skill_used(_slot_index: int) -> void:
	_has_destination = false
	melee_attack.cancel()
	facing.look_toward(aim_direction())
	animator.replay_animation(skill_bar.cast_animation(), facing)


# --- Levelling ------------------------------------------------------------

## Level bonuses live on Progression (which survives a restart), so re-apply them on spawn.
func _apply_level_bonuses() -> void:
	health.max_health += HEALTH_PER_LEVEL * (Progression.level - 1)
	health.current_health = health.max_health


func _on_leveled_up(_new_level: int) -> void:
	health.max_health += HEALTH_PER_LEVEL
	health.heal(HEALTH_PER_LEVEL)
	speech_bubble.say("LEVEL UP!", 1.0)
	if click_marker_scene != null:
		for ring_size in [18.0, 28.0]:
			var ring: Shockwave = click_marker_scene.instantiate()
			get_parent().add_child(ring)
			ring.global_position = global_position + Vector2(0, BODY_HEIGHT)
			ring.play(ring_size, 0.45, Color(0.91, 0.757, 0.439, 0.9))
