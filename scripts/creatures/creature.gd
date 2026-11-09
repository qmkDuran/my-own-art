class_name Creature
extends PlayableCreature
## A creature the player controls through the spirit link.
##
## This script only coordinates: each frame it starts the action the player asks for
## (CreatureActions), picks the velocity and shows the right animation. Each job lives in
## its own child component (see the scene):
##   Orders:   PlayerInput (what the player wants), MouseOrders (click to move or attack, with
##             PathMover finding the way round obstacles), Movement, Facing
##   Fighting: MeleeAttack (jab, jab, then the SpinningHook finisher once learned), CritRoll,
##             SearingJab, Wildfire, CounterPunch, SkillBar (Q/W/E/R skills that spend Heat)
##   Defence:  Dodge (with AfterimageTrail, SpeedTrail, SpeedLines and EmberHop's fire),
##             Health (dodging makes it invulnerable), Unshakable (how much of a shove lands),
##             StatusResistance (which enemy status effects land), TrainerAid (F: a healing tonic)
##   Show:     Sprite (CreatureAnimator), HitFlash, FistEmbers, ComboPips, ScreenShake,
##             SpeechBubble, LevelUpBoost
##   Arriving: ZoneEntrance (the hop onto the spawn point; it drives the creature meanwhile)
## A shove it takes is a Pushback. Enemy status effects (Poisoned, Staggered, Buffeted) are
## attached to it at runtime; a stagger stops it acting for a moment.

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := -6.0

var _pushback := Pushback.new()
var _actions := CreatureActions.new(self)

@onready var movement: Movement = $Movement
@onready var facing: Facing = $Facing
@onready var melee_attack: MeleeAttack = $MeleeAttack
@onready var dodge: Dodge = $Dodge
@onready var afterimage_trail: AfterimageTrail = $AfterimageTrail
@onready var speed_trail: SpeedTrail = $SpeedTrail
@onready var speed_lines: SpeedLines = $SpeedLines
@onready var animator: CreatureAnimator = $Sprite
@onready var fist_embers: FistEmbers = $FistEmbers
@onready var trainer_aid: TrainerAid = $TrainerAid
@onready var zone_entrance: ZoneEntrance = $ZoneEntrance
@onready var unshakable: Unshakable = $Unshakable


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	skill_bar.skill_used.connect(_on_skill_used)


func _physics_process(delta: float) -> void:
	if zone_entrance.is_playing:
		return
	_pushback.count_down(delta)
	mouse_orders.update()
	var is_staggered := Staggered.is_staggering(self)
	if not is_staggered:
		if player_input.wants_trainer_aid():
			trainer_aid.use()
		_actions.update()
	# Leaping out of the way (or just being swapped in) means attacks pass through you.
	count_down_entrance_shield(delta)
	health.is_invulnerable = dodge.is_dodging or has_entrance_shield()

	var move_direction := Vector2.ZERO if is_staggered else _chosen_move_direction()
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
## Unshakable decides how much of it lands: none mid-guard (nothing is interrupted).
func push(push_velocity: Vector2, duration: float) -> void:
	var share := unshakable.share_of_push()
	if share <= 0.0:
		return
	interrupt()
	velocity = push_velocity * share
	_pushback.start(share, duration)


## Cuts off whatever it is doing: a jab or a skill (e.g. a shove or a stagger).
func interrupt() -> void:
	melee_attack.cancel()
	skill_bar.cancel_cast()


## The SkillBar asks this before firing: not mid-leap, not being shoved or staggered.
## A jab in progress doesn't block a skill; the skill cuts it short.
func can_start_skill() -> bool:
	return not dodge.is_dodging and not _pushback.is_active() and not Staggered.is_staggering(self) \
			and not health.is_dead()


# --- Moving ---------------------------------------------------------------

func _next_velocity(move_direction: Vector2, delta: float) -> Vector2:
	if dodge.is_dodging:
		return dodge.dodge_velocity
	if _pushback.is_active():
		return _pushback.slowed(velocity, delta)
	if melee_attack.is_attacking:
		# A quick snap forward into the punch, then planted feet.
		return melee_attack.lunge_velocity()
	if skill_bar.is_casting():
		return skill_bar.cast_velocity()
	return movement.calculate_velocity(velocity, move_direction, delta)


## The creature plants its feet while punching and can't steer mid-dodge.
## Otherwise the arrow keys steer, or it walks toward a clicked enemy or spot.
func _chosen_move_direction() -> Vector2:
	if _actions.is_busy():
		return Vector2.ZERO
	var steering := player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	return mouse_orders.move_direction()


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


## For the vertical slice, dying simply restarts the level (in a Party, the next creature comes in).
func _on_died() -> void:
	_on_defeated()


## A skill just fired (the SkillBar decides when): stop walking or jabbing, face the aim
## and play its animation.
func _on_skill_used(_slot_index: int) -> void:
	mouse_orders.stop_walking()
	melee_attack.cancel()
	facing.look_toward(aim_direction())
	animator.replay_animation(skill_bar.cast_animation(), facing)
