class_name Enemy
extends CharacterBody3D
## One spooky-cute enemy of the Gloomwood: a still Meshy model brought to life in code, with a role-specific brain
## (EnemyBrain) deciding where it goes and when it attacks. Every enemy is solid: it walks on the ground and slides
## along the world's walls, rocks and ruins (floaters only float their model above their body). It takes the
## player's hits (an elite's shield first), flashes, squashes and is knocked back, and dissolves into light when
## it is beaten.

signal died(enemy: Enemy)
signal damaged(enemy: Enemy, amount: float, hit: Hit)
signal shield_broken(enemy: Enemy)

const SPAWN_FROM: float = 0.05
const SLOW_SHARE: float = 0.3
const MIN_WISH: float = 0.1

var kind: String = ""
var spec: Dictionary = {}
var role: String = ""
var health: float = 0.0
var max_health: float = 0.0
var shield: float = 0.0
var max_shield: float = 0.0
var radius: float = 0.0
var roster: Roster
var brain: EnemyBrain
## The brain's wishes: a flat direction (length 0..1 of full speed) and where to look.
var wish: Vector3 = Vector3.ZERO
var look_at_point: Vector3 = Vector3.INF
## Extra lift and squash the brain can add to the model (a lunge's hop, a slam's crouch).
var pose_lift: float = 0.0
var pose_squash: float = 0.0
var invulnerable: bool = false
var spawned: bool = false
var _model: Node3D
var _meshes: Array[GeometryInstance3D] = []
var _knock: Vector3 = Vector3.ZERO
var _flash: float = 0.0
var _clock: float = 0.0
var _stuck: float = 0.0
var _detour: float = 0.0
var _detour_side: float = 1.0
var _fx: EnemyLook


func setup(enemy_kind: String, library: AssetLibrary, owner_roster: Roster) -> void:
	kind = enemy_kind
	spec = Tuning.doc("combat")["enemies"][kind]
	role = spec["role"]
	name = kind.to_pascal_case()
	roster = owner_roster
	health = float(spec["health"])
	max_health = health
	shield = float(spec.get("shield", 0.0))
	max_shield = shield
	radius = spec["radius"]
	collision_layer = Layers.ENEMY
	collision_mask = Layers.WORLD
	_add_body_shape()
	_model = library.spawn(spec["asset"], 1.0, false)
	add_child(_model)
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(node as GeometryInstance3D)
	_fx = EnemyLook.new()
	add_child(_fx)
	_fx.setup(self)
	brain = EnemyBrain.for_role(role)
	_clock = randf() * TAU
	_model.scale = Vector3.ONE * SPAWN_FROM
	var grow: Tween = create_tween()
	grow.tween_property(_model, "scale", Vector3.ONE, Tuning.number("combat", "enemy", "spawn_seconds")).set_trans(
		Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	grow.tween_callback(func() -> void: spawned = true)


func _add_body_shape() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = maxf(radius * 2.0, radius * 2.0 + float(spec["hover"]) * 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)


func model() -> Node3D:
	return _model


func look() -> EnemyLook:
	return _fx


## The middle of the visible body (where hits aim and land).
func centre() -> Vector3:
	return global_position + Vector3.UP * (float(spec["hover"]) + radius + pose_lift)


## The radius that player shots test against (a little generous, so fair-looking hits count).
func hit_radius() -> float:
	return radius * Tuning.number("combat", "aim", "assist_radius") + radius


func is_alive() -> bool:
	return health > 0.0


func is_shielded() -> bool:
	return shield > 0.0


## Applies a hit; returns the damage that landed (on the shield or the body).
func take_hit(hit: Hit) -> float:
	if not is_alive() or invulnerable:
		return 0.0
	var landed: float = _shield_hit(hit) if is_shielded() else _body_hit(hit)
	_flash = Tuning.number("combat", "enemy", "flash_seconds")
	if role != "boss" and role != "elite":
		_knock += hit.push
	damaged.emit(self, landed, hit)
	if health <= 0.0:
		died.emit(self)
	return landed


func _shield_hit(hit: Hit) -> float:
	hit.on_shield = true
	var rate: float = float(spec["shield_taken"].get(hit.kind, 1.0))
	var landed: float = minf(hit.amount * rate, shield)
	shield -= landed
	_fx.shield_struck(hit, shield / max_shield)
	if shield <= 0.0:
		_fx.shatter()
		shield_broken.emit(self)
		brain.on_shield_broken(self)
	return landed


func _body_hit(hit: Hit) -> float:
	var landed: float = minf(hit.amount, health)
	health -= landed
	brain.on_hurt(self, hit)
	return landed


func _physics_process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta, 0.0)
	if spawned and is_alive():
		brain.think(self, delta)
	_move(delta)
	_turn(delta)
	_animate()


func _move(delta: float) -> void:
	var speed: float = float(spec["speed"]) * brain.speed_scale(self)
	var flat: Vector3 = _steer(wish.limit_length(1.0)) * speed + _separation() + _knock
	var fall: float = 0.0 if is_on_floor() else velocity.y - Tuning.number("combat", "enemy", "gravity") * delta
	velocity = Vector3(flat.x, fall, flat.z)
	var before: Vector3 = global_position
	move_and_slide()
	_knock = _knock.move_toward(Vector3.ZERO, Tuning.number("combat", "enemy", "knockback_decay") * delta)
	_check_stuck(before, speed, delta)


## Slides around an obstacle it is stuck on: for a moment it heads off to one side.
func _steer(direction: Vector3) -> Vector3:
	if _detour > 0.0 and direction.length() > MIN_WISH:
		return direction.rotated(Vector3.UP, _detour_side * PI * 0.5 * SLOW_SHARE * 2.0).normalized()
	return direction


func _check_stuck(before: Vector3, speed: float, delta: float) -> void:
	_detour = maxf(_detour - delta, 0.0)
	var wanted: float = wish.length() * speed * delta
	var moved: float = Vector2(global_position.x - before.x, global_position.z - before.z).length()
	_stuck = _stuck + delta if wanted > 0.0 and moved < wanted * SLOW_SHARE else 0.0
	if _stuck > Tuning.number("combat", "enemy", "stuck_seconds"):
		_stuck = 0.0
		_detour = Tuning.number("combat", "enemy", "detour_seconds")
		_detour_side = -_detour_side


## Pushes away from enemies that are too close, so packs spread out instead of stacking.
func _separation() -> Vector3:
	var push := Vector3.ZERO
	var gap: float = Tuning.number("combat", "enemy", "separation")
	for other: Enemy in roster.within(global_position, radius + gap):
		if other == self:
			continue
		var away := Vector3(global_position.x - other.global_position.x, 0.0, global_position.z -
			other.global_position.z)
		push += away.normalized() * (1.0 - away.length() / (radius + other.radius + gap))
	return push * Tuning.number("combat", "enemy", "separation_push")


func _turn(delta: float) -> void:
	var target: Vector3 = look_at_point if look_at_point != Vector3.INF else global_position + wish
	var to := Vector3(target.x - global_position.x, 0.0, target.z - global_position.z)
	if to.length() > MIN_WISH:
		var blend: float = clampf(Tuning.number("combat", "enemy", "turn_sharpness") * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), blend)


func _animate() -> void:
	var height: float = float(spec["hover"]) + pose_lift + _gait_lift()
	_model.position.y = height
	if spawned:
		var squash: float = pose_squash + (Tuning.number("combat", "enemy", "hit_squash") if _flash > 0.0 else 0.0)
		_model.scale = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)
	var glow: float = _flash / Tuning.number("combat", "enemy", "flash_seconds")
	for mesh: GeometryInstance3D in _meshes:
		mesh.set_instance_shader_parameter("flash", glow)


func set_rim(strength: float, colour: Color) -> void:
	for mesh: GeometryInstance3D in _meshes:
		mesh.set_instance_shader_parameter("rim", strength)
		mesh.set_instance_shader_parameter("rim_color", colour)


func _gait_lift() -> float:
	var bob: float = spec["bob"]
	match String(spec["motion"]):
		"hop":
			var phase: float = fmod(_clock / Tuning.number("combat", "enemy", "hop_seconds"), 1.0)
			return absf(sin(phase * PI)) * bob * minf(velocity.length() / float(spec["speed"]), 1.0)
		"flutter":
			var speed: float = Tuning.number("combat", "enemy", "flutter_speed")
			_model.rotation.z = sin(_clock * speed) * Tuning.number("combat", "enemy", "flutter_sway")
			return sin(_clock * speed) * bob * 0.5
		_:
			return sin(_clock * Tuning.number("combat", "enemy", "bob_speed")) * bob
