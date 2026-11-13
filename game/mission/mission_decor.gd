class_name MissionDecor
extends Node3D
## The Gloomwood's set dressing from data/mission.json: the town gate set into the tree line (solid towers, an open
## arch), the ruins and trees, street lamps along the way (those of an encounter stay dark until it is cleared),
## stone braziers with a living flame, clusters of softly glowing mushrooms, and the Gloom King's ring of standing
## stones with violet runes.

const FLAME_SHADER: Shader = preload("res://shaders/vfx_flame.gdshader")
const STONE: Color = Color(0.24, 0.23, 0.26)
const TILT: float = 0.08
const RUNE_LIFT: float = 0.55
const RUNE_SIZE: float = 0.35
const EMBER_RISE: float = 1.2
const EMBER_SIZE: float = 0.05
const EMBERS: int = 10
const PEDESTAL_FOOT: float = 0.7
const PEDESTAL_BOX: float = 1.6

var lights: Array[OmniLight3D] = []
## Encounter id -> the lamps that light up when it is cleared.
var lamps_of: Dictionary = {}
var placed: Array[Node3D] = []
var arena_stones: Array[Node3D] = []
var _library: AssetLibrary
var _rng := RandomNumberGenerator.new()


func build(library: AssetLibrary) -> void:
	name = "MissionDecor"
	_library = library
	var spec: Dictionary = Tuning.doc("mission")
	_rng.seed = int(spec["mushrooms"]["seed"])
	_gate(spec["gate"])
	for prop: Dictionary in spec["props"]:
		_place(prop["asset"], Tuning.point(prop["at"]), deg_to_rad(float(prop["rot"])), true)
	for lamp: Dictionary in spec["lamps"]:
		_lamp(lamp)
	for brazier: Dictionary in spec["braziers"]:
		_brazier(Tuning.point(brazier["at"]), String(brazier["encounter"]), spec["brazier"])
	_mushrooms(spec["mushrooms"])
	_stones(spec["arena"])


func _place(asset: String, at: Vector3, yaw: float, collide: bool) -> Node3D:
	var node: Node3D = _library.spawn(asset, 1.0, collide)
	add_child(node)
	node.position = at
	node.rotation.y = yaw
	placed.append(node)
	return node


## The gate: the model (no box of its own), with a solid box for each tower so the arch between stays open.
func _gate(spec: Dictionary) -> void:
	var gate: Node3D = _place(spec["asset"], Tuning.point(spec["at"]), deg_to_rad(float(spec["rot"])), false)
	var size: Vector3 = _library.size_of(spec["asset"])
	var tower: float = size.x * float(spec["tower_share"])
	for side: float in [-1.0, 1.0]:
		var box := Vector3(tower, size.y, float(spec["tower_depth"]))
		var holder: Node3D = Blocks.box(gate, Vector3(side * (size.x - tower) * 0.5, size.y * 0.5, 0.0), box, null,
			true)
		holder.name = "GateTower"


func _lamp(spec: Dictionary) -> void:
	var node: Node3D = _place(spec["asset"], Tuning.point(spec["at"]), deg_to_rad(float(spec["rot"])), true)
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := LampLight.new()
	light.setup(spec["asset"])
	node.add_child(light)
	light.position = _library.anchor(spec["asset"], Tuning.doc("assets")[spec["asset"]]["lamp"])
	_register(light, String(spec["encounter"]))


func _register(light: LampLight, encounter: String) -> void:
	lights.append(light)
	if encounter.is_empty():
		return
	light.snuff()
	if not lamps_of.has(encounter):
		lamps_of[encounter] = []
	(lamps_of[encounter] as Array).append(light)


## A stone brazier: a pedestal with a living flame (the flame shader, standing up), rising embers and its light.
func _brazier(at: Vector3, encounter: String, spec: Dictionary) -> void:
	var radius: float = spec["radius"]
	var height: float = spec["height"]
	var pedestal := CylinderMesh.new()
	pedestal.top_radius = radius
	pedestal.bottom_radius = radius * PEDESTAL_FOOT
	pedestal.height = height
	pedestal.material = SurfaceMaterials.stone("bricks")
	var box := Vector3(radius, height, radius) * PEDESTAL_BOX
	var holder: Node3D = Blocks.box(self, at + Vector3.UP * height * 0.5, box, null,
		true)
	var mesh := MeshInstance3D.new()
	mesh.mesh = pedestal
	holder.add_child(mesh)
	var flame := _flame(float(spec["flame_size"]))
	add_child(flame)
	flame.position = at + Vector3.UP * float(spec["flame_height"])
	var light := LampLight.new()
	light.setup("brazier")
	flame.add_child(light)
	_register(light, encounter)
	flame.visible = encounter.is_empty()
	light.set_meta("flame", flame)


func _flame(size: float) -> Node3D:
	var root := Node3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size * 0.5
	sphere.height = size
	var material := ShaderMaterial.new()
	material.shader = FLAME_SHADER
	sphere.material = material
	var flame := MeshInstance3D.new()
	flame.mesh = sphere
	flame.rotation.x = -PI * 0.5
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flame)
	var embers: GPUParticles3D = ParticleBursts.embers(EMBERS, Tuning.look_color("brazier", "color"), EMBER_SIZE,
		EMBER_RISE * 0.5, EMBER_RISE)
	embers.one_shot = false
	embers.explosiveness = 0.0
	(embers.process_material as ParticleProcessMaterial).gravity = Vector3.UP * EMBER_RISE
	root.add_child(embers)
	return root


## Clusters of small glowing mushrooms (soft glows, no lights of their own).
func _mushrooms(spec: Dictionary) -> void:
	var colours: Array = spec["colors"]
	for index: int in int(spec["count"]):
		var spot: Array = spec["spots"][index % (spec["spots"] as Array).size()]
		var at := Vector3(float(spot[0]), 0.0, float(spot[1])) + Vector3(_rng.randf_range(-1.0, 1.0), 0.0,
			_rng.randf_range(-1.0, 1.0)) * float(spec["cluster"])
		var size: float = _rng.randf_range(float(spec["size_min"]), float(spec["size_max"]))
		var glow: Node3D = SoftGlow.make(Tuning.color(colours[index % colours.size()]), size, float(spec["energy"]))
		add_child(glow)
		glow.position = at + Vector3.UP * size * 0.5


## The ring of standing stones around the boss arena (a gap at the entrance), some carrying a violet rune light.
func _stones(spec: Dictionary) -> void:
	var centre: Vector3 = Tuning.point(spec["center"])
	var count: int = int(spec["stones"])
	var gap: float = deg_to_rad(float(spec["gap_deg"]))
	var gap_half: float = deg_to_rad(float(spec["gap_width_deg"])) * 0.5
	var lit: int = 0
	for index: int in count:
		var angle: float = gap + gap_half + (TAU - gap_half * 2.0) * (index + 0.5) / count
		var at: Vector3 = centre + Vector3(cos(angle), 0.0, sin(angle)) * float(spec["radius"])
		var size: Vector3 = Tuning.vec3(spec["stone_size"])
		var stone: Node3D = Blocks.box(self, at + Vector3.UP * size.y * 0.5, size, Outskirts.flat(STONE), true,
			centre - at)
		stone.rotation.z = _rng.randf_range(-TILT, TILT)
		arena_stones.append(stone)
		var rune: Node3D = SoftGlow.make(Tuning.color(spec["rune_color"]), RUNE_SIZE, float(spec["rune_energy"]))
		stone.add_child(rune)
		rune.position = Vector3(0.0, size.y * (RUNE_LIFT - 0.5), size.z * 0.5)
		if lit < int(spec["rune_lights"]) and index % 3 == 0:
			lit += 1
			var light := LampLight.new()
			light.setup("rune")
			rune.add_child(light)
			lights.append(light)
