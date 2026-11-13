class_name FountainWater
extends Node3D
## The fountain's water, made in code: still pools in the basin and the top bowl (the canal water material, so
## they mirror the lamps) and a thin curtain of droplets spilling from the bowl's rim into the basin.

const DROP_MESH_SIZE: Vector2 = Vector2(0.02, 0.09)
const DROP_ROUGHNESS: float = 0.1


func _ready() -> void:
	name = "FountainWater"
	_pool(Tuning.f("fountain", "basin_y"), Tuning.f("fountain", "basin_radius"))
	_pool(Tuning.f("fountain", "bowl_y"), Tuning.f("fountain", "bowl_radius"))
	_spill()


func _pool(height: float, radius: float) -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = Tuning.f("fountain", "pool_depth")
	disc.material = SurfaceMaterials.water()
	var mesh := MeshInstance3D.new()
	mesh.mesh = disc
	mesh.position.y = height
	add_child(mesh)


func _spill() -> void:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_ring_axis = Vector3.UP
	process.emission_ring_radius = Tuning.f("fountain", "bowl_radius")
	process.emission_ring_inner_radius = Tuning.f("fountain", "bowl_radius")
	process.emission_ring_height = 0.0
	process.direction = Vector3.UP
	process.spread = Tuning.f("fountain", "spill_spread_deg")
	process.initial_velocity_min = Tuning.f("fountain", "spill_speed")
	process.initial_velocity_max = Tuning.f("fountain", "spill_speed")
	process.radial_velocity_min = Tuning.f("fountain", "spill_outward")
	process.radial_velocity_max = Tuning.f("fountain", "spill_outward")
	process.gravity = Vector3.DOWN * Tuning.f("fountain", "gravity")
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.amount = Tuning.i("fountain", "drops")
	particles.lifetime = Tuning.f("fountain", "drop_lifetime")
	particles.position.y = Tuning.f("fountain", "bowl_y")
	particles.draw_pass_1 = _drop_mesh()
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)


func _drop_mesh() -> QuadMesh:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Tuning.color(Tuning.doc("tuning")["fountain"]["drop_color"])
	material.roughness = DROP_ROUGHNESS
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale = true
	var quad := QuadMesh.new()
	quad.size = DROP_MESH_SIZE
	quad.material = material
	return quad
