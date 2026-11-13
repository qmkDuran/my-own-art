class_name Creature
extends CharacterBody3D
## One spooky-cute creature of the night, a still Meshy model brought to life in code. Floaters (ghosts, moths, the
## Gloom King) drift through walls on purpose, as spirits do; hoppers (pumpkins) are solid and slide along the town's
## walls. Each one heads for the player, or for the nearest lit lamp to snuff it, bobs, hops or flutters, flinches
## when hit, and can be knocked back and stunned.

signal died(creature: Creature)

var kind: String = ""
var spec: Dictionary = {}
var health: float = 0.0
var radius: float = 0.0
var is_boss: bool = false
var _model: Node3D
var _knock: Vector3 = Vector3.ZERO
var _stun: float = 0.0
var _hit_timer: float = 0.0
var _clock: float = 0.0
var _player: Node3D
var _lamps: LampKeeper


func setup(creature_kind: String, library: AssetLibrary, player: Node3D, lamps: LampKeeper, toughness: float) -> void:
	kind = creature_kind
	spec = Tuning.doc("defence")["creatures"][kind]
	name = kind.to_pascal_case()
	health = float(spec["health"]) * toughness
	radius = spec["radius"]
	is_boss = spec.get("boss", false)
	_player = player
	_lamps = lamps
	collision_layer = Layers.WISP
	collision_mask = Layers.WORLD if is_solid() else 0
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = radius
	shape.shape = ball
	shape.position.y = radius
	add_child(shape)
	_model = library.spawn(spec["asset"], 1.0, false)
	add_child(_model)
	if spec.has("aura_color"):
		_add_aura()
	_clock = randf() * TAU


## A coloured glow around a big creature, so its dark silhouette reads against the night.
func _add_aura() -> void:
	var aura := OmniLight3D.new()
	aura.light_color = Tuning.color(spec["aura_color"])
	aura.light_energy = float(spec["aura_energy"])
	aura.omni_range = float(spec["aura_range"])
	aura.position = Vector3(0.0, radius * 2.0, radius * 2.0)
	add_child(aura)


## Solid creatures collide with walls; floaters pass through them (a deliberate rule).
func is_solid() -> bool:
	return spec["motion"] == "hop"


func centre() -> Vector3:
	return global_position + Vector3.UP * (float(spec["hover"]) + radius)


func hurt(amount: float, push: Vector3 = Vector3.ZERO, stun: float = 0.0) -> void:
	if health <= 0.0:
		return
	health -= amount
	_hit_timer = Tuning.number("defence", "creature", "hit_seconds")
	if not is_boss:
		_knock += push
		_stun = maxf(_stun, stun)
	if health <= 0.0:
		died.emit(self)


func _physics_process(delta: float) -> void:
	_clock += delta
	_stun = maxf(_stun - delta, 0.0)
	_hit_timer = maxf(_hit_timer - delta, 0.0)
	var goal: Vector3 = _goal()
	var to: Vector3 = Vector3(goal.x - global_position.x, 0.0, goal.z - global_position.z)
	var step: Vector3 = to.normalized() * float(spec["speed"]) * _gait() if _stun == 0.0 else Vector3.ZERO
	var fall: float = velocity.y - Tuning.f("player", "gravity") * delta if is_solid() and not is_on_floor() else 0.0
	velocity = step + _knock + Vector3.UP * fall
	_knock = _knock.move_toward(Vector3.ZERO, Tuning.number("defence", "creature", "knockback_decay") * delta)
	move_and_slide()
	if not is_solid():
		global_position.y = move_toward(global_position.y, goal.y, float(spec["speed"]) * delta)
	if to.length() > 0.0:
		var blend: float = clampf(Tuning.number("defence", "creature", "turn_sharpness") * delta, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), blend)
	_animate()
	_snuff_if_close()


## Where it is heading: the player, or (for lamp-seekers) the nearest lit lamp.
func _goal() -> Vector3:
	if spec["target"] == "lamp":
		var lamp: LampLight = _lamps.nearest_lit(global_position)
		if lamp != null:
			var base: Vector3 = (lamp.get_parent() as Node3D).global_position
			return Vector3(lamp.global_position.x, base.y, lamp.global_position.z)
	return _player.global_position


func _snuff_if_close() -> void:
	if spec["target"] != "lamp":
		return
	var lamp: LampLight = _lamps.nearest_lit(global_position)
	if lamp == null:
		return
	var flat := Vector2(lamp.global_position.x - global_position.x, lamp.global_position.z - global_position.z)
	if flat.length() < Tuning.number("defence", "lamps", "snuff_reach"):
		lamp.snuff()


## Hoppers only move while in the air.
func _gait() -> float:
	if spec["motion"] != "hop":
		return 1.0
	return 1.0 if _hop_phase() < 1.0 else 0.0


func _hop_phase() -> float:
	return fmod(_clock / Tuning.number("defence", "creature", "hop_seconds"), 2.0)


func _animate() -> void:
	var bob: float = spec["bob"]
	var height: float = spec["hover"]
	match spec["motion"]:
		"hop":
			var phase: float = _hop_phase()
			height += sin(phase * PI) * bob if phase < 1.0 else 0.0
		"flutter":
			height += sin(_clock * Tuning.number("defence", "creature", "flutter_speed")) * bob * 0.5
			_model.rotation.z = sin(_clock * Tuning.number("defence", "creature", "flutter_speed")) * Tuning.number(
				"defence", "creature", "flutter_sway")
		_:
			height += sin(_clock * Tuning.number("defence", "creature", "bob_speed")) * bob
	_model.position.y = height
	var squash: float = Tuning.number("defence", "creature", "hit_squash") if _hit_timer > 0.0 else 0.0
	_model.scale = Vector3(1.0 + squash, 1.0 - squash, 1.0 + squash)
