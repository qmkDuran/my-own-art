class_name ArenaBarrier
extends Node3D
## The Gloom King's ring closes while he is fought: invisible walls just outside the standing stones, and across
## the entrance a curtain of violet flame rising from a glowing line, so you can see why you can't leave.

const SEGMENTS: int = 24
const HEIGHT: float = 8.0
const WIDTH: float = 0.5
const OUTSIDE: float = 1.2
const CURTAIN_EMBERS: int = 90
const CURTAIN_RISE: float = 2.2
const CURTAIN_SIZE: float = 0.14
const LINE_HEIGHT: float = 0.06
const CURTAIN_SPEED_SHARE: float = 0.3
const LINE_DEPTH: float = 4.0

var closed: bool = false


func close() -> void:
	if closed:
		return
	closed = true
	var spec: Dictionary = Tuning.doc("mission")["arena"]
	var centre: Vector3 = Tuning.point(spec["center"])
	var radius: float = float(spec["radius"]) + OUTSIDE
	for index: int in SEGMENTS:
		var a: Vector3 = centre + Vector3(cos(TAU * index / SEGMENTS), 0.0, sin(TAU * index / SEGMENTS)) * radius
		var b: Vector3 = centre + Vector3(cos(TAU * (index + 1) / SEGMENTS), 0.0, sin(TAU * (index + 1) / SEGMENTS)) * \
			radius
		Blocks.wall_between(self, a, b, HEIGHT, WIDTH, null)
	_curtain(spec, centre)


func open() -> void:
	closed = false
	for child: Node in get_children():
		child.queue_free()


## The flame curtain across the entrance gap.
func _curtain(spec: Dictionary, centre: Vector3) -> void:
	var colour: Color = Tuning.color(spec["barrier_color"])
	var gap: float = deg_to_rad(float(spec["gap_deg"]))
	var at: Vector3 = centre + Vector3(cos(gap), 0.0, sin(gap)) * float(spec["radius"])
	var across: float = 2.0 * float(spec["radius"]) * sin(deg_to_rad(float(spec["gap_width_deg"])) * 0.5)
	var embers: GPUParticles3D = ParticleBursts.embers(CURTAIN_EMBERS, colour, CURTAIN_SIZE, CURTAIN_RISE *
		CURTAIN_SPEED_SHARE,
		CURTAIN_RISE)
	embers.one_shot = false
	embers.explosiveness = 0.0
	var process: ParticleProcessMaterial = embers.process_material
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(across * 0.5, LINE_HEIGHT, LINE_HEIGHT)
	process.gravity = Vector3.UP * CURTAIN_RISE
	add_child(embers)
	embers.global_position = at
	embers.global_basis = Basis.looking_at(centre - at, Vector3.UP)
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(across, LINE_HEIGHT, LINE_HEIGHT * LINE_DEPTH)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = colour
	box.material = glow
	line.mesh = box
	add_child(line)
	line.global_position = at + Vector3.UP * LINE_HEIGHT
	line.global_basis = embers.global_basis
