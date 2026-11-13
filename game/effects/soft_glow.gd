class_name SoftGlow
## The one way the game makes a small light-thing glow, after the "Luigi's Mansion, not LED headlights" rule:
## a small core in the light's own saturated colour with modest energy (capped, so it never clips to white) and a
## wide, soft camera-facing halo that fades out smoothly. Used by lamp flames, fireflies, candles and bolts.

const ENERGY_CAP: float = 1.6
const HALO_SIZE: float = 4.0
const HALO_STRENGTH: float = 0.4


static func make(colour: Color, size: float, energy: float) -> Node3D:
	var root := Node3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = size * 0.5
	sphere.height = size
	var core := StandardMaterial3D.new()
	core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.albedo_color = colour
	core.emission_enabled = true
	core.emission = colour
	core.emission_energy_multiplier = minf(energy, ENERGY_CAP)
	sphere.material = core
	var centre := MeshInstance3D.new()
	centre.mesh = sphere
	centre.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(centre)
	var halo := MeshInstance3D.new()
	halo.mesh = ParticleKit.glow_quad(size * HALO_SIZE, colour, HALO_STRENGTH)
	(halo.mesh.surface_get_material(0) as BaseMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(halo)
	return root
