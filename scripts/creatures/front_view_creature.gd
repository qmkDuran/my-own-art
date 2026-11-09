class_name FrontViewCreature
extends PlayableCreature
## A playable Glimra drawn from the front only (it hops or floats and always faces the
## camera, like the enemies), e.g. Toxlop and Zephoot in Project B's team. Far cheaper to
## animate than Emberoo's five views: idle, move and attack sheets are enough.
##
## A thin coordinator, like Creature: each frame it starts what the player asks for, picks the
## velocity and shows the right animation. Its jobs live in child components (see the scenes):
##   Orders:   PlayerInput, MouseOrders (click to move or attack, PathMover), Movement
##   Fighting: SkillBar with exactly three abilities: slot 0 the basic attack (right mouse,
##             Shift + left mouse, a clicked enemy or Q), slot 1 the skill (W), slot 2 the
##             signature (E). Each is a SkillAction.
##   Defence:  Dodge (Space), Health
##   Show:     Sprite (SingleViewAnimator), HitFlash, ScreenShake, AllyMarker
## Its playable sheets are `<creature>_play_<action>_sheet.png`: idle, move, basic, skill,
## signature (the abilities' animations), intro and outro (team swaps) and hurt.

## Below this speed (pixels per second) the creature counts as standing still.
const STANDING_STILL_SPEED := 1.0
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := -6.0
## The SkillBar slot of the basic attack (the other two hold the skill and the signature).
const BASIC_ATTACK_SLOT := 0

## The animation shown while it moves or dodges.
@export var move_animation: String = "move"
## How high it floats above its shadow, in pixels (0 = it sits on the ground).
@export var hover_height: float = 0.0
## For a creature drawn in three-quarter side view facing right (e.g. Mossdillo): its sprite
## flips to face left when it moves or aims left. Front-view creatures leave this off.
@export var faces_sideways: bool = false
## How far a floating creature bobs up and down, in pixels, and how long one bob takes.
@export var bob_height: float = 0.0
@export var bob_period: float = 1.6

var _pushback := Pushback.new()
var _seconds_alive: float = 0.0
## While set (not zero), abilities aim this way instead of at the cursor (a clicked enemy).
var _aim_override: Vector2 = Vector2.ZERO
## A one-off pose (hurt, intro) playing over idle and moving, and the seconds it has left.
var _pose: String = ""
var _pose_left: float = 0.0

@onready var movement: Movement = $Movement
@onready var dodge: Dodge = $Dodge
@onready var animator: SingleViewAnimator = $Sprite


func _ready() -> void:
	if team_icon == null and animator.sprite_frames.has_animation("idle"):
		team_icon = animator.sprite_frames.get_frame_texture("idle", 0)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_defeated)
	skill_bar.skill_used.connect(_on_skill_used)


func _physics_process(delta: float) -> void:
	_seconds_alive += delta
	_pose_left = maxf(0.0, _pose_left - delta)
	_pushback.count_down(delta)
	mouse_orders.update()
	var is_staggered := Staggered.is_staggering(self)
	if not is_staggered and not health.is_dead():
		_start_requested_action()
	count_down_entrance_shield(delta)
	health.is_invulnerable = dodge.is_dodging or skill_bar.cast_makes_invulnerable() or has_entrance_shield()

	var move_direction := Vector2.ZERO if is_staggered or _is_busy() else _chosen_move_direction()
	velocity = _next_velocity(move_direction, delta)
	move_and_slide()

	animator.show_animation(_current_animation())
	animator.lift(_current_lift())
	if faces_sideways:
		_face_travel_or_aim()


func aim_direction() -> Vector2:
	if _aim_override != Vector2.ZERO:
		return _aim_override
	var body_center := global_position + Vector2(0, BODY_HEIGHT)
	var to_cursor := player_input.get_aim_point() - body_center
	return to_cursor.normalized() if to_cursor.length() >= 1.0 else Vector2.DOWN


func can_start_skill() -> bool:
	return not dodge.is_dodging and not _pushback.is_active() and not Staggered.is_staggering(self) \
			and not health.is_dead()


func push(push_velocity: Vector2, duration: float) -> void:
	interrupt()
	velocity = push_velocity
	_pushback.start(1.0, duration)


func interrupt() -> void:
	skill_bar.cancel_cast()


func show_exit_pose() -> void:
	if animator.sprite_frames.has_animation("outro"):
		animator.play("outro")
		animator.frame = 1


func play_entrance_pose() -> void:
	play_pose("intro")


# --- Acting -----------------------------------------------------------------

func _is_busy() -> bool:
	return dodge.is_dodging or skill_bar.is_casting()


## A dodge first (it may cut a skill's wind-up short), then the basic attack.
## The skill and the signature are started by the SkillBar itself (W, E).
func _start_requested_action() -> void:
	if player_input.wants_to_dodge() and dodge.is_ready() and skill_bar.allows_dodge():
		skill_bar.cancel_cast()
		dodge.start(_dodge_direction())
		animator.replay_animation(move_animation)
	elif _is_busy() or skill_bar.cooldown_left(BASIC_ATTACK_SLOT) > 0.0:
		return
	elif player_input.wants_to_attack():
		_use_basic_attack(Vector2.ZERO)
	elif mouse_orders.is_attack_target_in_reach():
		_use_basic_attack(mouse_orders.direction_to_attack_target(aim_direction()))
		mouse_orders.note_jabbed_attack_target()


## Fires slot 0 toward `toward` (or the cursor when zero).
func _use_basic_attack(toward: Vector2) -> void:
	_aim_override = toward
	if skill_bar.try_use(BASIC_ATTACK_SLOT):
		player_input.consume_attack_buffer()
	_aim_override = Vector2.ZERO


func _dodge_direction() -> Vector2:
	var steering := player_input.get_move_direction()
	if steering != Vector2.ZERO:
		return steering
	mouse_orders.clear()
	return aim_direction()


# --- Moving and showing ------------------------------------------------------

func _chosen_move_direction() -> Vector2:
	var steering := player_input.get_move_direction()
	return steering if steering != Vector2.ZERO else mouse_orders.move_direction()


func _next_velocity(move_direction: Vector2, delta: float) -> Vector2:
	if dodge.is_dodging:
		return dodge.dodge_velocity
	if _pushback.is_active():
		return _pushback.slowed(velocity, delta)
	if skill_bar.is_casting():
		return skill_bar.cast_velocity()
	return movement.calculate_velocity(velocity, move_direction, delta)


func _current_animation() -> String:
	if skill_bar.is_casting():
		return skill_bar.cast_animation()
	if dodge.is_dodging or velocity.length() > STANDING_STILL_SPEED:
		return move_animation
	if _pose_left > 0.0:
		return _pose
	return "idle"


## Plays a one-off animation over idle for its whole length (skills and moving win over it),
## e.g. an Intro's "submerged" then "intro".
func play_pose(pose: String) -> void:
	if not animator.sprite_frames.has_animation(pose):
		return
	_pose = pose
	_pose_left = 0.0
	for frame_index in animator.sprite_frames.get_frame_count(pose):
		_pose_left += animator.sprite_frames.get_frame_duration(pose, frame_index)
	_pose_left /= animator.sprite_frames.get_animation_speed(pose)
	animator.replay_animation(pose)


## Faces where it is moving, or where its skill aims while casting (drawn facing right).
func _face_travel_or_aim() -> void:
	var facing_x := aim_direction().x if skill_bar.is_casting() else velocity.x
	if not is_zero_approx(facing_x):
		animator.flip_h = facing_x < 0.0


func _current_lift() -> float:
	var bob := sin(TAU * _seconds_alive / bob_period) * bob_height if bob_period > 0.0 else 0.0
	return hover_height + bob + dodge.current_height() + skill_bar.cast_lift()


func _on_damaged(_amount: int, _source_position: Vector2) -> void:
	hit_flash.flash()
	if not skill_bar.is_casting():
		play_pose("hurt")


func _on_skill_used(_slot_index: int) -> void:
	mouse_orders.stop_walking()
	animator.replay_animation(skill_bar.cast_animation())
