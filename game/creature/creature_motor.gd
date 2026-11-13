class_name CreatureMotor
extends RefCounted
## Moves a creature's body each physics step: walking and sneaking (with effects, wading and mode speeds), dashes and
## lunges, jumps with gravity and gliding, staying put on a perch, keeping burrowers in soil and swimmers in water,
## turning toward where it is going or aiming, and the footstep and landing noises.

var airborne: bool = false
var _creature: Creature
var _dash_velocity: Vector3 = Vector3.ZERO
var _dash_left: float = 0.0
var _lunging: bool = false
var _step_left: float = 0.0


func _init(owner: Creature) -> void:
	_creature = owner


func dash(dash_velocity: Vector3, duration: float, lunging: bool) -> void:
	if _creature.is_rooted():
		return
	_dash_velocity = dash_velocity
	_dash_left = duration
	_lunging = lunging


func launch(launch_velocity: Vector3) -> void:
	if _creature.is_rooted():
		return
	_creature.velocity = launch_velocity
	airborne = true
	_dash_left = 0.0


func step(delta: float) -> void:
	var body: Creature = _creature
	if body.traversal.mode == Traversal.Mode.PERCHED:
		body.velocity = Vector3.ZERO
		body.global_position = body.traversal.perch
		_turn(delta)
		return
	_move(delta)
	_turn(delta)
	_footsteps(delta)


func _move(delta: float) -> void:
	var body: Creature = _creature
	var was_airborne: bool = airborne
	if not airborne:
		var wanted: Vector3 = _wanted_velocity(delta)
		if not body.traversal.can_reach(body.global_position + wanted * delta):
			wanted = Vector3.ZERO
		var accel: float = Tuning.f("creature", "acceleration") * delta
		var instant: bool = _dash_left > 0.0
		body.velocity.x = wanted.x if instant else move_toward(body.velocity.x, wanted.x, accel)
		body.velocity.z = wanted.z if instant else move_toward(body.velocity.z, wanted.z, accel)
	_fall(delta)
	body.move_and_slide()
	if body.is_on_floor() and body.velocity.y <= 0.0:
		airborne = false
		if was_airborne:
			NoiseBus.emit_noise(body, body.global_position, Tuning.f("noise", "landing_radius"), "landing")


func _fall(delta: float) -> void:
	var body: Creature = _creature
	if body.is_on_floor() and not airborne:
		body.velocity.y = 0.0
		return
	body.velocity.y -= Tuning.f("creature", "jump_gravity") * delta
	if body.effects.has("glide"):
		body.velocity.y = maxf(body.velocity.y, -Tuning.f("creature", "glide_fall_speed"))


func _wanted_velocity(delta: float) -> Vector3:
	var body: Creature = _creature
	if body.is_dead() or body.is_rooted() or body.is_staggered():
		return Vector3.ZERO
	if _dash_left > 0.0:
		_dash_left -= delta
		var opponent: Creature = body.opponent
		if _lunging and opponent != null and body.global_position.distance_to(opponent.global_position) \
				< Tuning.f("attack_rules", "lunge_stop_distance") + Creature.BODY_RADIUS:
			_dash_left = 0.0
		return _dash_velocity
	var speed: float = Tuning.f("creature", "sneak_speed" if body.sneaking else "run_speed")
	speed *= body.effects.value("speed", 1.0) * body.effects.value("slow", 1.0) * body.traversal.speed_factor()
	for ability: Ability in body.abilities():
		if ability.phase == Ability.Phase.WINDUP and ability is Move:
			speed *= (ability as Move).windup_move_factor()
	var intent: Vector3 = body.move_intent.limit_length(1.0)
	return (-intent if body.effects.has("confused") else intent) * speed


func _turn(delta: float) -> void:
	var body: Creature = _creature
	if body.is_dead() or body.is_staggered() or body.roll.protects():
		return
	var direction: Vector3 = _facing_goal()
	if Vector2(direction.x, direction.z).length() < Creature.DIRECTION_EPSILON:
		return
	var goal: float = atan2(-direction.x, -direction.z)
	var rate: float = Tuning.f("creature", "attack_turn_rate" if _winding_up() else "turn_rate")
	body.yaw = rotate_toward(body.yaw, goal, rate * delta)


func _winding_up() -> bool:
	for move: Move in _creature.moves:
		if move.phase == Ability.Phase.WINDUP:
			return true
	return false


func _facing_goal() -> Vector3:
	var body: Creature = _creature
	if _winding_up():
		return body.aim_point - body.global_position
	if body.has_look_target:
		return body.look_target - body.global_position
	return body.move_intent


func _footsteps(delta: float) -> void:
	var body: Creature = _creature
	if body.horizontal_speed() < Creature.MOVING_SPEED or not body.is_on_floor() or body.traversal.deep():
		return
	_step_left -= delta
	if _step_left <= 0.0:
		_step_left = Tuning.f("noise", "step_interval")
		var radius: float = Tuning.f("noise", "sneak_radius" if body.sneaking else "run_radius")
		NoiseBus.emit_noise(body, body.global_position, radius * body.effects.value("loud", 1.0), "step")
