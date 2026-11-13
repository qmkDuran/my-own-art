class_name CameraParticles
extends GPUParticles3D
## A particle box that travels with the camera: the dust motes that only show in lamplight, and the rain. The
## particles live in world space, so moving the box does not drag them along.

const ALL_DIRECTIONS_DEG: float = 180.0
const DUST_DRIFT_PER_SIZE: float = 4.0
const DUST_WANDER: float = 0.05

var _camera: Camera3D


## Dust motes floating in the air around the camera.
static func dust() -> CameraParticles:
	var particles := CameraParticles.new()
	particles.name = "DustMotes"
	var process := _box_process(Tuning.vec3(Tuning.doc("lighting")["dust"]["box"]))
	process.gravity = Vector3.ZERO
	process.spread = ALL_DIRECTIONS_DEG
	process.initial_velocity_max = Tuning.look_f("dust", "size") * DUST_DRIFT_PER_SIZE
	process.turbulence_enabled = true
	process.turbulence_influence_max = DUST_WANDER
	process.color_ramp = ParticleKit.fade_ramp()
	particles.process_material = process
	particles.amount = Tuning.i_look("dust", "amount")
	particles.lifetime = Tuning.look_f("dust", "lifetime")
	particles.draw_pass_1 = ParticleKit.lit_mote(Tuning.look_f("dust", "size"), Tuning.look_color("dust", "color"))
	return particles


## Rain streaks falling around the camera; amount_ratio scales how hard it rains.
static func rain() -> CameraParticles:
	var particles := CameraParticles.new()
	particles.name = "Rain"
	var box: Vector3 = Tuning.vec3(Tuning.doc("lighting")["rain"]["box"])
	var process := _box_process(box)
	process.direction = Vector3.DOWN
	process.spread = 2.0
	process.gravity = Vector3.ZERO
	process.initial_velocity_min = Tuning.look_f("rain", "speed")
	process.initial_velocity_max = Tuning.look_f("rain", "speed")
	particles.process_material = process
	particles.amount = Tuning.i_look("rain", "amount")
	particles.lifetime = box.y / Tuning.look_f("rain", "speed")
	particles.draw_pass_1 = _streak()
	particles.amount_ratio = 0.0
	return particles


func follow(camera: Camera3D) -> void:
	_camera = camera
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-Vector3.ONE * Tuning.f("effects", "particle_visibility"), Vector3.ONE * 2.0 *
		Tuning.f("effects", "particle_visibility"))
	preprocess = lifetime


func _process(_delta: float) -> void:
	if is_instance_valid(_camera):
		global_position = _camera.global_position


static func _box_process(box: Vector3) -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = box * 0.5
	return process


static func _streak() -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.albedo_color = Tuning.look_color("rain", "color")
	var quad := QuadMesh.new()
	quad.size = Vector2(Tuning.look_f("rain", "width"), Tuning.look_f("rain", "length"))
	quad.material = material
	return quad
