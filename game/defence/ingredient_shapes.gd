class_name IngredientShapes
## Small, icon-like shapes for the pickups, so each ingredient reads at a glance by silhouette as well as colour:
## a pumpkin-goo drop, a moth-dust star, a ghost-pepper, a moonberry cluster, a bat-wing toffee. They are lit with
## only a faint glow of their own, so they read as things to pick up, not as lights.

const STEM: Color = Color(0.25, 0.55, 0.2)
const DROP_STRETCH: float = 1.35
const STAR_TURN: float = PI
const PEPPER_TILT: float = 0.6
const PEPPER_WIDTH: float = 0.35
const STEM_SIZE: float = 0.25
const BERRY_SIZE: float = 0.5
const BERRY_SPREAD: float = 0.22
const BERRIES: Array[Vector3] = [Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 1.4, 0)]
const TOFFEE_FLAT: float = 0.45
const WING_SIZE: float = 0.55
const WING_OUT: float = 0.6
const ROUGHNESS: float = 0.4


## A pickup shape of a size (metres) in a colour, glowing at energy.
static func make(shape: String, colour: Color, size: float, energy: float) -> Node3D:
	var root := Node3D.new()
	match shape:
		"drop":
			_add(root, _sphere(size), colour, energy).scale.y = DROP_STRETCH
		"star":
			_add(root, _prism(size), colour, energy)
			_add(root, _prism(size), colour, energy).rotation.z = STAR_TURN
		"pepper":
			_pepper(root, colour, size, energy)
		"berry":
			for spot: Vector3 in BERRIES:
				_add(root, _sphere(size * BERRY_SIZE), colour, energy).position = spot * size * BERRY_SPREAD
		"toffee":
			_toffee(root, colour, size, energy)
		_:
			_add(root, _sphere(size), colour, energy)
	return root


static func _pepper(root: Node3D, colour: Color, size: float, energy: float) -> void:
	var body := CapsuleMesh.new()
	body.radius = size * PEPPER_WIDTH * 0.5
	body.height = size
	_add(root, body, colour, energy).rotation.z = PEPPER_TILT
	var stem: MeshInstance3D = _add(root, _sphere(size * STEM_SIZE), STEM, 0.0)
	stem.position = Vector3(-sin(PEPPER_TILT), cos(PEPPER_TILT), 0.0) * size * 0.5


static func _toffee(root: Node3D, colour: Color, size: float, energy: float) -> void:
	var block := BoxMesh.new()
	block.size = Vector3(size, size * TOFFEE_FLAT, size)
	_add(root, block, colour, energy)
	for side: float in [-1.0, 1.0]:
		var wing: MeshInstance3D = _add(root, _prism(size * WING_SIZE), colour.darkened(0.5), 0.0)
		wing.position.x = side * size * WING_OUT
		wing.rotation.z = side * PI * 0.5


static func _sphere(size: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = size * 0.5
	mesh.height = size
	return mesh


static func _prism(size: float) -> PrismMesh:
	var mesh := PrismMesh.new()
	mesh.size = Vector3(size, size, size * 0.5)
	return mesh


static func _add(root: Node3D, mesh: PrimitiveMesh, colour: Color, energy: float) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = ROUGHNESS
	material.emission_enabled = energy > 0.0
	material.emission = colour
	material.emission_energy_multiplier = energy
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)
	return instance
