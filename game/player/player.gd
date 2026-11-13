class_name Player
extends CharacterBody3D
## The lamplighter apprentice: a capsule body that walks or runs where its controller asks, dashes and jumps (see
## Agility), turns to face its way, plays the Meshy idle, walk, run and jump clips to match, and carries the hand
## lantern.

const MODEL_PATH: String = "res://assets/meshy/characters/player.glb"
const HAND_BONE: String = "RightHand"

var model: CharacterModel
var lantern: HandLantern
var wish: Vector3 = Vector3.ZERO
var running: bool = false
var yaw: float = 0.0
var speed_scale: float = 1.0
var agility := Agility.new()
var _landing: float = 0.0


func setup(at: Vector3, start_yaw: float) -> void:
	name = "Player"
	collision_layer = Layers.PLAYER
	collision_mask = Layers.WORLD
	floor_snap_length = Tuning.f("player", "capsule_radius")
	var capsule := CapsuleShape3D.new()
	capsule.radius = Tuning.f("player", "capsule_radius")
	capsule.height = Tuning.f("player", "capsule_height")
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	model = CharacterModel.new()
	add_child(model)
	model.setup(MODEL_PATH)
	lantern = HandLantern.new()
	model.attach_to_bone(HAND_BONE).add_child(lantern)
	lantern.owner_body = self
	_add_fill_lights()
	position = at
	yaw = start_yaw
	rotation.y = yaw
	model.play("idle", 0.0)


## The lantern's warm glow on the player: a soft front fill so the face reads and a rim from behind, lighting only
## the player's own meshes.
func _add_fill_lights() -> void:
	for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).layers |= Layers.PLAYER_VISUAL
	for part: String in ["front", "rim"]:
		var fill := OmniLight3D.new()
		fill.name = part.capitalize() + "Fill"
		fill.light_color = Tuning.color(Tuning.doc("tuning")["player_fill"]["color"])
		fill.light_energy = Tuning.f("player_fill", part + "_energy")
		fill.omni_range = Tuning.f("player_fill", part + "_range")
		fill.light_cull_mask = Layers.PLAYER_VISUAL
		fill.light_specular = 0.0
		fill.position = Tuning.vec3(Tuning.doc("tuning")["player_fill"][part + "_at"])
		add_child(fill)


## A quick dodge in the wished direction (or straight ahead), with a little dust puff; creatures can't hurt you
## mid-dash.
func dash() -> void:
	if agility.start_dash(wish if wish.length() > 0.0 else -global_basis.z):
		_puff()


func jump() -> void:
	agility.request_jump()


func is_dashing() -> bool:
	return agility.is_dashing()


func speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _physics_process(delta: float) -> void:
	var top: float = Tuning.f("player", "run_speed" if running else "walk_speed") * speed_scale
	var goal: Vector3 = wish.limit_length(1.0) * top
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(goal, Tuning.f("player", "acceleration") * delta)
	var events: Dictionary = {}
	var rise: float = agility.vertical(delta, is_on_floor(), velocity.y, events)
	if agility.is_dashing():
		flat = goal.limit_length(top) + agility.dash_velocity()
	velocity = Vector3(flat.x, rise, flat.z)
	move_and_slide()
	_landing = maxf(_landing - delta, 0.0)
	if events.get("jumped", false):
		model.play_from("jump", Tuning.f("agility", "jump_clip_takeoff"), Tuning.f("player", "blend_seconds"))
	if events.get("landed", false):
		_landing = Tuning.f("agility", "landing_seconds")
		_puff()
	if wish.length() > Tuning.f("player", "moving_threshold"):
		var goal_yaw: float = atan2(-wish.x, -wish.z)
		yaw = lerp_angle(yaw, goal_yaw, clampf(Tuning.f("player", "turn_sharpness") * delta, 0.0, 1.0))
		rotation.y = yaw
	_animate()


func _animate() -> void:
	var blend: float = Tuning.f("player", "blend_seconds")
	var moving: float = speed()
	if agility.is_airborne() or _landing > 0.0 and moving < Tuning.f("player", "walk_speed"):
		return
	if moving < Tuning.f("player", "moving_threshold"):
		model.play("idle", blend)
	elif moving > Tuning.f("player", "walk_speed") * speed_scale + Tuning.f("player", "moving_threshold"):
		model.play("run", blend, moving / model.foot_speed("run"))
	else:
		model.play("walk", blend, moving / model.foot_speed("walk"))


## A small puff of dust at the feet (dash starts, landings).
func _puff() -> void:
	var dust: GPUParticles3D = ParticleBursts.smoke(Tuning.i("agility", "dust_puffs"), Tuning.color(
		Tuning.doc("tuning")["agility"]["dust_color"]), Tuning.f("agility", "dust_size"), Tuning.f("agility",
		"dust_seconds"))
	get_tree().current_scene.add_child(dust)
	dust.global_position = global_position
