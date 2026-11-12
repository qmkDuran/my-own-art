class_name CreatureParts
## Builds a creature's body from primitives. Two body plans: the "fox" (slim, pointed ears, long bushy tail) and
## the "boar" (stocky, forward horns, a row of back spikes, stub tail), so the two fighters never look alike and
## their facing is obvious from any angle. All sizes are in metres.

const PLANS: Dictionary = {
	"fox": { "body_radius": 0.28, "body_length": 1.15, "hip_height": 0.66, "leg_radius": 0.06,
		"head_radius": 0.23, "head_at": Vector3(0, 0.24, -0.6) },
	"boar": { "body_radius": 0.36, "body_length": 1.1, "hip_height": 0.7, "leg_radius": 0.08,
		"head_radius": 0.27, "head_at": Vector3(0, 0.14, -0.62) },
}
const CHEST_SHARE: float = 0.8
const CHEST_AT: Vector3 = Vector3(0, -0.06, -0.3)
const LEG_SPREAD: Vector2 = Vector2(0.17, 0.36)
const LEG_TOP: float = -0.08
const LEG_TAPER: float = 0.8
const PAW_SHARE: float = 1.3
const PAW_SQUASH: float = 1.4
const PAW_FORWARD: float = -0.03
const SNOUT_SIZE: Vector3 = Vector3(0.16, 0.13, 0.22)
const SNOUT_DROP: float = -0.05
const SNOUT_OUT: float = 0.02
const NOSE_RADIUS: float = 0.045
const NOSE_DROP: float = -0.02
const NOSE_OUT: float = 0.13
const EYE_RADIUS: float = 0.05
const EYE_OFFSET: Vector3 = Vector3(0.11, 0.07, -0.17)
const PUPIL_RADIUS: float = 0.028
const PUPIL_OUT: float = 0.035
const GLOW_RADIUS: float = 0.13
const GLOW_OUT: float = 0.12
const EAR_SIZE: Vector3 = Vector3(0.15, 0.24, 0.06)
const EAR_OFFSET: Vector3 = Vector3(0.12, 0.22, 0.02)
const TAIL_RADIUS: float = 0.12
const TAIL_LENGTH: float = 0.85
const TAIL_LIFT: float = 0.75
const TAIL_ROOT: Vector3 = Vector3(0, 0.08, 0.45)
const TAIL_TIP_AT: float = 0.85
const HORN_RADIUS: float = 0.06
const HORN_LENGTH: float = 0.34
const HORN_OFFSET: Vector3 = Vector3(0.17, 0.08, -0.1)
const HORN_TILT: Vector2 = Vector2(-1.1, -0.5)
const SPIKES: int = 5
const SPIKE_SIZE: float = 0.13
const SPIKE_TALL: float = 1.6
const SPIKE_SHORT: float = 1.2
const SPIKE_SPAN: Vector2 = Vector2(-0.35, 0.4)
const SPIKE_LIFT: float = 0.03
const STUB_ROOT: Vector3 = Vector3(0, 0.1, 0.5)
const STUB_SHARE: float = 0.7
const PUPIL_COLOR: Color = Color(0.05, 0.04, 0.04)
const ROUGHNESS: float = 0.85


static func build(model: CreatureModel, look: Dictionary) -> void:
	var plan: Dictionary = PLANS[look["shape"]]
	model.body_material = _material(Tuning.color(look["body"]))
	model.belly_material = _material(Tuning.color(look["belly"]))
	model.accent_material = _material(Tuning.color(look["accent"]))
	model.torso = Node3D.new()
	model.torso.position.y = float(plan["hip_height"])
	model.add_child(model.torso)
	_torso(model, plan)
	_legs(model, plan)
	_head(model, plan, look)
	if look["shape"] == "fox":
		_fox_extras(model, plan)
	else:
		_boar_extras(model, plan)


static func _torso(model: CreatureModel, plan: Dictionary) -> void:
	var capsule := CapsuleMesh.new()
	capsule.radius = plan["body_radius"]
	capsule.height = plan["body_length"]
	_part(model.torso, capsule, model.body_material, Vector3.ZERO).rotation.x = PI * 0.5
	_part(model.torso, _ball(float(plan["body_radius"]) * CHEST_SHARE, 1.0), model.belly_material, CHEST_AT)


static func _legs(model: CreatureModel, plan: Dictionary) -> void:
	var length: float = float(plan["hip_height"]) + LEG_TOP
	var radius: float = plan["leg_radius"]
	for side: float in [-1.0, 1.0]:
		for end: float in [-1.0, 1.0]:
			var hip := Node3D.new()
			hip.position = Vector3(side * LEG_SPREAD.x, LEG_TOP, end * LEG_SPREAD.y)
			model.torso.add_child(hip)
			var leg := CylinderMesh.new()
			leg.top_radius = radius
			leg.bottom_radius = radius * LEG_TAPER
			leg.height = length
			_part(hip, leg, model.body_material, Vector3(0, -length * 0.5, 0))
			var paw: SphereMesh = _ball(radius * PAW_SHARE, PAW_SQUASH / 2.0)
			_part(hip, paw, model.accent_material, Vector3(0, -length, PAW_FORWARD))
			model.legs.append(hip)


static func _head(model: CreatureModel, plan: Dictionary, look: Dictionary) -> void:
	var radius: float = plan["head_radius"]
	model.head = Node3D.new()
	model.head.position = plan["head_at"]
	model.torso.add_child(model.head)
	_part(model.head, _ball(radius, 1.0), model.body_material, Vector3.ZERO)
	var snout := BoxMesh.new()
	snout.size = SNOUT_SIZE
	_part(model.head, snout, model.belly_material, Vector3(0, SNOUT_DROP, -radius - SNOUT_OUT))
	var dark: StandardMaterial3D = _material(PUPIL_COLOR)
	_part(model.head, _ball(NOSE_RADIUS, 1.0), dark, Vector3(0, NOSE_DROP, -radius - NOSE_OUT))
	var eye_material: StandardMaterial3D = _material(Tuning.color(look["eye"]))
	for side: float in [-1.0, 1.0]:
		var at := Vector3(side * EYE_OFFSET.x, EYE_OFFSET.y, EYE_OFFSET.z)
		_part(model.head, _ball(EYE_RADIUS, 1.0), eye_material, at)
		_part(model.head, _ball(PUPIL_RADIUS, 1.0), dark, at + Vector3(0, 0, -PUPIL_OUT))
	model.glow = _glow_ball(model.head, Vector3(0, SNOUT_DROP, -radius - GLOW_OUT))


static func _fox_extras(model: CreatureModel, plan: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var ear := PrismMesh.new()
		ear.size = EAR_SIZE
		_part(model.head, ear, model.body_material, Vector3(side * EAR_OFFSET.x, EAR_OFFSET.y, EAR_OFFSET.z))
	model.tail = Node3D.new()
	model.tail.position = Vector3(0, TAIL_ROOT.y, float(plan["body_length"]) * TAIL_ROOT.z)
	model.tail.rotation.x = -TAIL_LIFT
	model.torso.add_child(model.tail)
	var tail := CapsuleMesh.new()
	tail.radius = TAIL_RADIUS
	tail.height = TAIL_LENGTH
	_part(model.tail, tail, model.body_material, Vector3(0, 0, TAIL_LENGTH * 0.5)).rotation.x = PI * 0.5
	_part(model.tail, _ball(TAIL_RADIUS, 1.0), model.belly_material, Vector3(0, 0, TAIL_LENGTH * TAIL_TIP_AT))


static func _boar_extras(model: CreatureModel, plan: Dictionary) -> void:
	for side: float in [-1.0, 1.0]:
		var horn := CylinderMesh.new()
		horn.top_radius = 0.0
		horn.bottom_radius = HORN_RADIUS
		horn.height = HORN_LENGTH
		var at := Vector3(side * HORN_OFFSET.x, HORN_OFFSET.y, HORN_OFFSET.z)
		_part(model.head, horn, model.accent_material, at).rotation = Vector3(HORN_TILT.x, 0, side * HORN_TILT.y)
	for k: int in SPIKES:
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = SPIKE_SIZE * 0.5
		spike.height = SPIKE_SIZE * (SPIKE_TALL if k % 2 == 0 else SPIKE_SHORT)
		var z: float = lerpf(SPIKE_SPAN.x, SPIKE_SPAN.y, float(k) / (SPIKES - 1))
		_part(model.torso, spike, model.accent_material, Vector3(0, float(plan["body_radius"]) + SPIKE_LIFT, z))
	model.tail = Node3D.new()
	model.tail.position = Vector3(0, STUB_ROOT.y, float(plan["body_length"]) * STUB_ROOT.z)
	model.torso.add_child(model.tail)
	_part(model.tail, _ball(TAIL_RADIUS * STUB_SHARE, 1.0), model.accent_material, Vector3.ZERO)


## A sphere; squash below 1 flattens it (height = squash x diameter).
static func _ball(radius: float, squash: float) -> SphereMesh:
	var ball := SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0 * squash
	return ball


static func _glow_ball(parent: Node3D, at: Vector3) -> MeshInstance3D:
	var view: MeshInstance3D = _part(parent, _ball(GLOW_RADIUS, 1.0), WoodsMaterials.glow(Color.WHITE, 1.0), at)
	view.material_override = view.material_override.duplicate()
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.visible = false
	return view


static func _part(parent: Node3D, mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = material
	view.position = at
	parent.add_child(view)
	return view


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = ROUGHNESS
	return material
