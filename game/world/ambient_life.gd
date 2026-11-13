class_name AmbientLife
## Small signs of life that make the woods feel warm and alive: pollen drifting in the sunny clearings, fireflies
## glinting in the shade, and a few birds wheeling high over the canopy.

const POLLEN_AMOUNT: int = 40
const POLLEN_BOX: Vector3 = Vector3(5.0, 2.5, 5.0)
const POLLEN_SIZE: float = 0.04
const POLLEN_LIFE: float = 6.0
const FIREFLY_AMOUNT: int = 14
const FIREFLY_BOX: Vector3 = Vector3(4.0, 1.2, 4.0)
const FIREFLY_SIZE: float = 0.05
const FIREFLY_LIFE: float = 3.0
const DRIFT: float = 0.25
const FLOCKS: Array[Vector3] = [Vector3(-10, 22, 6), Vector3(18, 25, -12)]
const BIRDS_PER_FLOCK: int = 5
const FLOCK_RADIUS: float = 9.0
const FLOCK_SPEED: float = 0.25
const BIRD_SIZE: Vector3 = Vector3(0.9, 0.08, 0.35)
const ALL_AROUND: float = 180.0


static func build(parent: Node3D, woods: Woods) -> void:
	for spot: Array in Tuning.woods["light_shafts"]:
		var ground: Vector3 = woods.ground_at(Tuning.vec2(spot))
		parent.add_child(_motes(ground + Vector3.UP * POLLEN_BOX.y, POLLEN_AMOUNT, POLLEN_BOX, POLLEN_SIZE,
				POLLEN_LIFE, Tuning.palette("pollen")))
	for bush: Dictionary in Tuning.woods["bushes"]:
		var ground: Vector3 = woods.ground_at(Tuning.vec2(bush["pos"]))
		parent.add_child(_motes(ground + Vector3.UP, FIREFLY_AMOUNT, FIREFLY_BOX, FIREFLY_SIZE, FIREFLY_LIFE,
				Tuning.palette("firefly")))
	for centre: Vector3 in FLOCKS:
		parent.add_child(_flock(centre))


static func _motes(at: Vector3, amount: int, box: Vector3, size: float, life: float, color: Color) -> CPUParticles3D:
	var motes := CPUParticles3D.new()
	motes.position = at
	motes.amount = amount
	motes.lifetime = life
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = box
	motes.gravity = Vector3.ZERO
	motes.direction = Vector3.UP
	motes.spread = ALL_AROUND
	motes.initial_velocity_min = DRIFT * 0.5
	motes.initial_velocity_max = DRIFT
	var dot := SphereMesh.new()
	dot.radius = size
	dot.height = size * 2.0
	motes.mesh = dot
	motes.material_override = WoodsMaterials.glow(color, color.a)
	return motes


static func _flock(centre: Vector3) -> Node3D:
	var flock := Flock.new()
	flock.setup(centre, BIRDS_PER_FLOCK, FLOCK_RADIUS, FLOCK_SPEED, BIRD_SIZE)
	return flock
