class_name CliffFaces
## Makes the plateau's small cliff readable: grey stone faces all round its steep edge (not on the ramp), and a flat
## launch stone at each jump spot so you can see where a leap up will land you on top.

const FACE_STEP_DEG: float = 16.0
const FACE_WIDTH: float = 2.6
const FACE_DEPTH: float = 0.9
const FACE_EXTRA_HEIGHT: float = 0.35
const FACE_LUMP: float = 0.12
const SLAB_RADIUS: float = 0.7
const SLAB_HEIGHT: float = 0.08
const RAMP_SKIP_DEG: float = 40.0
const FULL_TURN_DEG: float = 360.0


static func build(parent: Node3D, woods: Woods, rng: RandomNumberGenerator) -> void:
	for plateau: Dictionary in Tuning.woods["terrain"].get("plateaus", []):
		_faces(parent, woods, plateau, rng)
	for jump: Dictionary in woods.features.jump_spots():
		var slab := CylinderMesh.new()
		slab.top_radius = SLAB_RADIUS
		slab.bottom_radius = SLAB_RADIUS
		slab.height = SLAB_HEIGHT
		var view := MeshInstance3D.new()
		view.mesh = slab
		view.material_override = WoodsMaterials.solid("rock")
		view.position = (jump["from"] as Vector3) + Vector3.UP * SLAB_HEIGHT * 0.5
		parent.add_child(view)


static func _faces(parent: Node3D, woods: Woods, plateau: Dictionary, rng: RandomNumberGenerator) -> void:
	var centre: Vector2 = Tuning.vec2(plateau["pos"])
	var radius: float = float(plateau["radius"])
	var height: float = float(plateau["height"]) + FACE_EXTRA_HEIGHT
	var box := BoxMesh.new()
	var ramp: float = deg_to_rad(float(plateau["ramp_deg"]))
	var angle: float = 0.0
	while angle < FULL_TURN_DEG:
		if absf(angle_difference(deg_to_rad(angle), ramp)) > deg_to_rad(RAMP_SKIP_DEG):
			var out: Vector2 = Vector2.from_angle(deg_to_rad(angle))
			var foot: Vector3 = woods.ground_at(centre + out * (radius + FACE_DEPTH * 0.5))
			var face := MeshInstance3D.new()
			face.mesh = FlatMesh.lumpy(box, rng, FACE_LUMP)
			face.material_override = WoodsMaterials.solid("rock_dark")
			face.scale = Vector3(FACE_WIDTH, height, FACE_DEPTH)
			face.position = foot + Vector3.UP * height * 0.5
			face.rotation.y = -deg_to_rad(angle) + PI * 0.5
			parent.add_child(face)
		angle += FACE_STEP_DEG
