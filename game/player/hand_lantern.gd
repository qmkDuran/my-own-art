class_name HandLantern
extends Node3D
## The small brass lantern the lamplighter carries: a code-made lantern hanging from the right hand with a glowing
## glass and a warm shadow-casting light, so the player is always a little pool of warmth in the night.

const CAP_SCALE: float = 1.4
const CAP_HEIGHT_SHARE: float = 0.18
const BRASS_METALLIC: float = 0.8
const BRASS_ROUGHNESS: float = 0.35

var light: OmniLight3D
var owner_body: Node3D


func _ready() -> void:
	name = "HandLantern"
	var drop: float = Tuning.f("lantern", "hang_drop")
	var glass: float = Tuning.f("lantern", "glass_radius")
	var height: float = Tuning.f("lantern", "glass_height")
	var holder := Node3D.new()
	holder.top_level = true
	add_child(holder)
	_add_part(_cylinder(glass, height, _glass_material()), holder, -drop)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Tuning.color(Tuning.doc("tuning")["lantern"]["frame_color"])
	brass.metallic = BRASS_METALLIC
	brass.roughness = BRASS_ROUGHNESS
	var cap_height: float = height * CAP_HEIGHT_SHARE
	_add_part(_cylinder(glass * CAP_SCALE, cap_height, brass), holder, -drop + height * 0.5)
	_add_part(_cylinder(glass * CAP_SCALE, cap_height, brass), holder, -drop - height * 0.5)
	light = OmniLight3D.new()
	light.light_color = Tuning.color(Tuning.doc("tuning")["lantern"]["color"])
	light.light_energy = Tuning.f("lantern", "energy")
	light.omni_range = Tuning.f("lantern", "range")
	light.omni_attenuation = Tuning.f("lantern", "attenuation")
	light.light_volumetric_fog_energy = Tuning.f("lantern", "fog_energy")
	light.shadow_enabled = true
	holder.add_child(light)
	light.position.y = -drop


## The lantern hangs straight down from the hand whatever the arm does: it follows the hand bone's position
## (so it swings with the walk), held a little out from the coat.
func _process(_delta: float) -> void:
	var holder: Node3D = get_child(0)
	var out := Vector3.ZERO
	if owner_body != null:
		out = owner_body.global_basis.x * Tuning.f("lantern", "hang_out")
	holder.global_position = global_position + out
	holder.global_rotation = Vector3.ZERO


func _add_part(mesh: Mesh, holder: Node3D, height: float) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position.y = height
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(part)


func _cylinder(radius: float, height: float, material: Material) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.material = material
	return mesh


func _glass_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var colour: Color = Tuning.color(Tuning.doc("tuning")["lantern"]["color"])
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = Tuning.f("lantern", "glass_energy")
	return material
