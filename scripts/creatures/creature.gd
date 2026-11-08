class_name Creature
extends CharacterBody2D
## A creature the player controls through the spirit link.
##
## This script only coordinates. Each job lives in its own child component:
##   PlayerInput     -> what the player wants
##   MouseOrders     -> click to move, click an enemy to attack it
##   Movement        -> how fast to move normally
##   Facing          -> which way to look
##   MeleeAttack     -> the jab combo: jab, jab, then the Spinning Hook (once learned)
##   SpinningHook    -> the combo's finisher: a spin that hits all around
##   CritRoll        -> critical hits (chance and multiplier) for every attack
##   SearingJab      -> once learned, jabs and the spin set enemies Burning
##   ComboPips       -> three tiny pips under the feet showing the combo chain
##   Dodge           -> the leap out of danger
##   AfterimageTrail -> fading copies during a dodge
##   SpeedTrail      -> a streak behind a dodge
##   SpeedLines      -> anime-style lines behind a dodge
##   Health          -> how much damage it can take (dodging makes it invulnerable)
##   HitFlash        -> flashes white when hit
##   FistEmbers      -> sparks rising from the fists
##   TrainerAid      -> F: the trainer throws a healing tonic (limited charges)
##   SkillBar        -> Q/W/E/R: skills that spend Heat (e.g. E = Flame Uppercut), once learned
##   ScreenShake     -> shakes the camera on big hits
##   LevelUpBoost    -> the small health boost and fanfare on each level up
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
@onready var mouse_orders: MouseOrders = $MouseOrders
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
@onready var skill_bar: SkillBar = $SkillBar


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	skill_bar.skill_used.connect(_on_skill_used)


func _physics_process(delta: float) -> void:
	_push_seconds_left = maxf(0.0, _push_seconds_left - delta)
	mouse_orders.update()
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


## Punches and skills go toward the mouse cursor, at any angle, measured from the body (not the feet).
func aim_direction() -> Vector2:
	var body_center := global_position + Vector2(0, BODY_HEIGHT)
	var to_cursor := player_input.get_aim_point() - body_center
	if to_cursor.length() < 1.0:
		return facing.as_vector()
	return to_cursor.normalized()


## Shoves the creature: it slides with this velocity for a moment, without player control.
## Interrupts a jab or a skill. A dodge can still be used to escape.
func push(push_velocity: Vector2, duration: float) -> void:
	melee_attack.cancel()
	skill_bar.cancel_cast()
	velocity = push_velocity
	_push_seconds_left = duration


## The SkillBar asks this before firing: not mid-leap and not being shoved.
## A jab in progress doesn't block a skill; the skill cuts it short.
func can_start_skill() -> bool:
	return not dodge.is_dodging and not _is_being_pushed() and not health.is_dead()


# --- Actions --------------------------------------------------------------

## Animation cancel: once the jab's hit has landed, a fresh order to move cuts the
## rest of its recovery short, so walking away after a punch feels instant.
## Not while the player is still asking to attack, so holding attack chains full jabs.
func _cancel_jab_recovery_to_move() -> void:
	if not melee_attack.can_cancel_by_moving() or not _wants_to_move():
		return
	if player_input.wants_to_attack() or mouse_orders.has_attack_target():
		return
	melee_attack.cancel()


func _wants_to_move() -> bool:
	return player_input.get_move_direction() != Vector2.ZERO or mouse_orders.has_destination()


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
	elif mouse_orders.is_attack_target_in_reach():
		_start_jab(mouse_orders.direction_to_attack_target(facing.as_vector()))
		mouse_orders.note_jabbed_attack_target()


func _start_jab(jab_direction: Vector2) -> void:
	mouse_orders.stop_walking()
	player_input.consume_attack_buffer()
	facing.look_toward(jab_direction)
	melee_attack.start(jab_direction)
	animator.replay_animation(melee_attack.current_animation, facing)


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
	mouse_orders.clear()
	return aim_direction()


# --- Moving ---------------------------------------------------------------

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
	return mouse_orders.move_direction(facing.as_vector())


func _is_busy() -> bool:
	return melee_attack.is_attacking or dodge.is_dodging or skill_bar.is_casting()


func _is_being_pushed() -> bool:
	return _push_seconds_left > 0.0


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


# --- Reactions --------------------------------------------------------------

func _on_damaged(_amount: int, _source_position: Vector2) -> void:
	hit_flash.flash()


## For the vertical slice, dying simply restarts the level.
func _on_died() -> void:
	get_tree().reload_current_scene.call_deferred()


## A skill just fired (the SkillBar decides when): stop walking or jabbing, face the aim
## and play its animation.
func _on_skill_used(_slot_index: int) -> void:
	mouse_orders.stop_walking()
	melee_attack.cancel()
	facing.look_toward(aim_direction())
	animator.replay_animation(skill_bar.cast_animation(), facing)
