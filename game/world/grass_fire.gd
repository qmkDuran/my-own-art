class_name GrassFire
extends Node3D
## Flames over a burning grass patch: rising orange sparks and a warm flicker light. Freed when the fire ends.

const SPARKS_PER_M2: float = 6.0
const SPARK_SIZE: float = 0.18
const SPARK_LIFE: float = 0.9
const RISE: float = 2.2
const LIGHT_ENERGY: float = 2.0
const LIGHT_RANGE_SHARE: float = 2.5
const FLAME: Color = Color(1.0, 0.55, 0.12)
const SPREAD_DEG: float = 15.0


func setup(radius: float) -> void:
	var sparks := CPUParticles3D.new()
	sparks.amount = maxi(8, int(PI * radius * radius * SPARKS_PER_M2))
	sparks.lifetime = SPARK_LIFE
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = radius
	sparks.direction = Vector3.UP
	sparks.spread = SPREAD_DEG
	sparks.initial_velocity_min = RISE * 0.5
	sparks.initial_velocity_max = RISE
	sparks.gravity = Vector3.ZERO
	var mesh := SphereMesh.new()
	mesh.radius = SPARK_SIZE
	mesh.height = SPARK_SIZE * 2.0
	sparks.mesh = mesh
	sparks.material_override = WoodsMaterials.glow(FLAME, 1.0)
	sparks.position.y = SPARK_SIZE
	add_child(sparks)
	var light := OmniLight3D.new()
	light.light_color = FLAME
	light.light_energy = LIGHT_ENERGY
	light.omni_range = radius * LIGHT_RANGE_SHARE
	light.position.y = 1.0
	add_child(light)
