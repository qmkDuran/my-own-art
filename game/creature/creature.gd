class_name Creature
extends CharacterBody3D
## One four-legged fighter: movement (run, sneak, dash, lunge), facing, health, stealth and four moves (bite, spit,
## dodge, snare). The player and the bot drive it through the same small intent API, so both play by the same rules.

signal hit_taken(amount: float, attacker: Creature, ambush: bool, kind: String)
signal died(creature: Creature)

const BODY_RADIUS: float = 0.45
const BODY_HEIGHT: float = 1.2
const MOUTH_FORWARD: float = 0.85
const MOUTH_HEIGHT: float = 0.75
const MOVING_SPEED: float = 0.5
const DIRECTION_EPSILON: float = 0.01

var display_name: String = ""
var opponent: Creature
var health: Health
var stealth := Stealth.new()
var bite: BiteAbility
var spit: SpitAbility
var dodge: DodgeAbility
var trap: TrapAbility
var model: CreatureModel
var yaw: float = 0.0
## Intent, written by the controller (player input or bot brain) every physics frame.
var move_intent: Vector3 = Vector3.ZERO
var sneaking: bool = false
var aim_point: Vector3 = Vector3.ZERO
var look_target: Vector3 = Vector3.ZERO
var has_look_target: bool = false
## True for the player's creature: a bush or grass it hides in turns see-through so the player can read the scene.
var see_through_cover: bool = false
## Written by the creature's senses: does it currently know where its opponent is?
var aware_of_opponent: bool = true
var _dash_velocity: Vector3 = Vector3.ZERO
var _dash_left: float = 0.0
var _lunging: bool = false
var _stagger_left: float = 0.0
var _root_left: float = 0.0
var _step_left: float = 0.0


func setup(look_key: String, spawn: Vector3, facing_yaw: float) -> void:
	var look: Dictionary = Tuning.creatures[look_key]
	display_name = look["name"]
	name = display_name
	position = spawn
	yaw = facing_yaw
	collision_layer = Layers.CREATURE
	collision_mask = Layers.CREATURE_MOVES_AGAINST
	floor_snap_length = Tuning.f("creature", "floor_snap")
	health = Health.new(Tuning.f("creature", "max_health"), Tuning.f("creature", "regen_delay"),
			Tuning.f("creature", "regen_per_second"))
	bite = BiteAbility.new(self)
	spit = SpitAbility.new(self)
	dodge = DodgeAbility.new(self)
	trap = TrapAbility.new(self)
	_add_collider()
	model = CreatureModel.new()
	add_child(model)
	model.build(look)


func abilities() -> Array[Ability]:
	return [bite, spit, dodge, trap]


func try_bite() -> bool:
	return _can_act() and bite.start()


func try_spit() -> bool:
	return _can_act() and spit.start()


func try_dodge() -> bool:
	return _can_act() and _root_left <= 0.0 and dodge.start()


func try_trap() -> bool:
	return _can_act() and trap.start()


func busy() -> bool:
	for ability: Ability in abilities():
		if ability.busy():
			return true
	return false


func is_dead() -> bool:
	return health.is_dead()


func is_staggered() -> bool:
	return _stagger_left > 0.0


func is_rooted() -> bool:
	return _root_left > 0.0


func forward() -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func chest_position() -> Vector3:
	return global_position + Vector3.UP * Tuning.f("perception", "chest_height")


func eye_position() -> Vector3:
	return global_position + Vector3.UP * Tuning.f("perception", "eye_height")


func mouth_position() -> Vector3:
	return global_position + forward() * MOUTH_FORWARD + Vector3.UP * MOUTH_HEIGHT


## An attack is an ambush when it starts while the target has not noticed us: we are hidden from it (a bush,
## tall grass, behind cover) or simply behind it. A target that watched us go into a bush is not fooled.
func ambush_ready() -> bool:
	return opponent != null and not opponent.is_dead() and not opponent.aware_of_opponent


## Attacks are loud and give away a hiding place.
func announce_attack() -> void:
	stealth.reveal()
	NoiseBus.emit_noise(self, global_position, Tuning.f("noise", "attack_radius"), "attack")


## Returns false when the hit is avoided (rolling) or the creature is already down.
func take_hit(amount: float, attacker: Creature, ambush: bool, kind: String) -> bool:
	if is_dead() or dodge.protects():
		return false
	var dealt: float = amount * (Tuning.f("stealth", "ambush_multiplier") if ambush else 1.0)
	health.hurt(dealt)
	model.flash_hit()
	if ambush:
		stagger(Tuning.f("creature", "stagger_time"))
	hit_taken.emit(dealt, attacker, ambush, kind)
	if is_dead():
		_die()
	return true


func stagger(duration: float) -> void:
	_stagger_left = maxf(_stagger_left, duration)
	for ability: Ability in [bite, spit, trap]:
		if ability.phase == Ability.Phase.WINDUP:
			ability.interrupt()


func root(duration: float) -> void:
	_root_left = maxf(_root_left, duration)


func lunge(lunge_velocity: Vector3, duration: float) -> void:
	dash(lunge_velocity, duration)
	_lunging = true


func dash(dash_velocity: Vector3, duration: float) -> void:
	if is_rooted():
		return
	_dash_velocity = dash_velocity
	_dash_left = duration
	_lunging = false


## Roll toward where we are steering; with no steering, roll backwards.
func dodge_direction() -> Vector3:
	return move_intent.normalized() if move_intent.length() > DIRECTION_EPSILON else -forward()


func _physics_process(delta: float) -> void:
	for ability: Ability in abilities():
		ability.tick(delta)
	health.tick(delta)
	stealth.tick(delta)
	_stagger_left = maxf(0.0, _stagger_left - delta)
	_root_left = maxf(0.0, _root_left - delta)
	_move(delta)
	_turn(delta)
	_footsteps(delta)
	model.animate(delta, self)


func _can_act() -> bool:
	return not is_dead() and not is_staggered() and not busy()


func _move(delta: float) -> void:
	var wanted: Vector3 = _wanted_velocity(delta)
	var accel: float = Tuning.f("creature", "acceleration") * delta
	if _dash_left > 0.0 and not is_rooted():
		velocity.x = wanted.x
		velocity.z = wanted.z
	else:
		velocity.x = move_toward(velocity.x, wanted.x, accel)
		velocity.z = move_toward(velocity.z, wanted.z, accel)
	velocity.y = 0.0 if is_on_floor() else velocity.y - Tuning.f("creature", "gravity") * delta
	move_and_slide()


func _wanted_velocity(delta: float) -> Vector3:
	if is_dead() or is_rooted() or is_staggered():
		return Vector3.ZERO
	if _dash_left > 0.0:
		_dash_left -= delta
		if _lunging and opponent != null and global_position.distance_to(opponent.global_position) \
				< Tuning.f("bite", "lunge_stop_distance") + BODY_RADIUS:
			_dash_left = 0.0
		return _dash_velocity
	var speed: float = Tuning.f("creature", "sneak_speed" if sneaking else "run_speed")
	if trap.busy():
		speed = 0.0
	elif busy():
		speed *= Tuning.f("creature", "windup_move_factor")
	return move_intent.limit_length(1.0) * speed


func _turn(delta: float) -> void:
	if is_dead() or is_staggered() or dodge.protects():
		return
	var direction: Vector3 = _facing_goal()
	if Vector2(direction.x, direction.z).length() < DIRECTION_EPSILON:
		return
	var goal: float = atan2(-direction.x, -direction.z)
	var winding_up: bool = bite.phase == Ability.Phase.WINDUP or spit.phase == Ability.Phase.WINDUP
	var rate: float = Tuning.f("creature", "attack_turn_rate" if winding_up else "turn_rate")
	yaw = rotate_toward(yaw, goal, rate * delta)


func _facing_goal() -> Vector3:
	if bite.phase == Ability.Phase.WINDUP or spit.phase == Ability.Phase.WINDUP:
		return aim_point - global_position
	if has_look_target:
		return look_target - global_position
	return move_intent


func _footsteps(delta: float) -> void:
	if horizontal_speed() < MOVING_SPEED or not is_on_floor():
		return
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = Tuning.f("noise", "step_interval")
		var radius: float = Tuning.f("noise", "sneak_radius" if sneaking else "run_radius")
		NoiseBus.emit_noise(self, global_position, radius, "step")


func _die() -> void:
	for ability: Ability in abilities():
		ability.interrupt()
	model.show_dead()
	died.emit(self)


func _add_collider() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position = Vector3.UP * BODY_HEIGHT * 0.5
	add_child(collider)
